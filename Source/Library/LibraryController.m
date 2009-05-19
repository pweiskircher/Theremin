/*
 Copyright (C) 2006-2007  Patrik Weiskircher
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
 MA 02110-1301, USA.
 */

#import "LibraryController.h"
#import "MusicServerClient.h"
#import "WindowController.h"
#import "Song.h"
#import "PWMusicSearchField.h"
#import "PlaylistController.h"
#import "PreferencesController.h"
#import "PWWindow.h"
#import "SQLController.h"
#import "LibraryImportController.h"

#import "LibraryArtistSubController.h"
#import "LibraryAlbumSubController.h"
#import "LibrarySongSubController.h"
#import "LibraryGenreSubController.h"

#import "LibrarySearchController.h"

static NSString *tAppendSongs = @"tAppendSongs";
static NSString *tGetInfoOnSongs = @"tGetInfoOnSongs";
static NSString *tSearchField = @"tSearchField";

@interface LibraryController (PrivateMethods)
- (void) clientConnected:(NSNotification *)notification;
- (void) clientDisconnected:(NSNotification *)notification;

- (void) replaceFilesInPlaylistAndStartPlayingWithSelectionFromTable:(PWTableView *)aTableView;
- (void) appendSongsWithSelectionFromTable:(PWTableView *)aTableView;

- (void) searchAction:(id)sender;
- (void) clearAndDisableViews;

- (void) showGenreView:(BOOL)show;
@end

@implementation LibraryController
- (id) init {
	self = [super init];
	if (self != nil) {		

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientConnected:)
													 name:nMusicServerClientConnected
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientDisconnected:)
													 name:nMusicServerClientDisconnected
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(libraryBeganImporting:)
													 name:nBeganLibraryImport
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(libraryFinishedImporting:)
													 name:nFinishedLibraryImport
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(profileSwitched:)
													 name:(NSString *)nProfileSwitched
												   object:nil];
		
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
																  forKeyPath:@"values.showGenreInLibrary" 
																	 options:NSKeyValueObservingOptionNew 
																	 context:NULL];

		mImportController = [[LibraryImportController alloc] init];
		mSearchController = [[LibrarySearchController alloc] init];
		[mSearchController setDelegate:self];
		
		mShowProgressPanelOnShow = NO;
		
		mToolbar = [[NSToolbar alloc] initWithIdentifier:@"LibraryToolbar"];
		[mToolbar setDelegate:self];
		[mToolbar setSizeMode:NSToolbarSizeModeSmall];
		[mToolbar setDisplayMode:NSToolbarDisplayModeDefault];
		[mToolbar setAllowsUserCustomization:YES];
		[mToolbar setAutosavesConfiguration:YES];
		
		[NSBundle loadNibNamed:@"Library" owner:self];
	}
	return self;
}

- (void) awakeFromNib {	
	_dividerImage = [[mSplitView divider] retain];
	
	[mWindow setToolbar:mToolbar];
	
	[self clientDisconnected:nil];

	[mWindow setUseGlobalHotkeys:YES];
	
	[self showGenreView:[[PreferencesController sharedInstance] showGenreInLibrary]];
	
	mArtistController = [[LibraryArtistSubController alloc] initWithTableView:mArtistView andLibraryController:self andHasAllEntry:YES];
	mAlbumController = [[LibraryAlbumSubController alloc] initWithTableView:mAlbumView andLibraryController:self andHasAllEntry:YES];
	mSongController = [[LibrarySongSubController alloc] initWithTableView:mSongView andLibraryController:self andHasAllEntry:NO];
	mGenreController = [[LibraryGenreSubController alloc] initWithTableView:mGenreView andLibraryController:self andHasAllEntry:YES];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
	
	[_dividerImage release];
	[mToolbar release];
	[mImportController release];
	[mArtistController release];
	[mAlbumController release];
	[mSongController release];
	
	
	[mSearchFieldItem release];
	[mAppendSongsItem release];
	
	[super dealloc];
}

- (void) show {
	[mWindow makeKeyAndOrderFront:self];
	
	if (mShowProgressPanelOnShow)
		[NSApp beginSheet:mProgressPanel modalForWindow:mWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

#pragma mark -
#pragma mark Menu Stuff

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem action] != @selector(setToggleIsPartOfCompilation:))
		return YES;
	
	if (_titleShown == NO)
		return NO;
	
	NSArray *songs = [mSongController getSelected:NULL];
	int state = NSOffState;
	
	for (int i = 0; i < [songs count]; i++) {
		Song *song = [songs objectAtIndex:i];
		if ([song isCompilation]) {
			state = NSOnState;
		} else {
			if (state == NSOnState) {
				state = NSMixedState;
				break;
			}
		}
	}
	
	[menuItem setState:state];
	
	return YES;
}

#pragma mark -
#pragma mark Notifications

- (void) libraryBeganImporting:(NSNotification *)notification {
	[self clearAndDisableViews];
	
	if ([mWindow isVisible])
		[NSApp beginSheet:mProgressPanel modalForWindow:mWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	else
		mShowProgressPanelOnShow = YES;
	
	[mProgressPanelIndicator startAnimation:self];
}

- (void) libraryFinishedImporting:(NSNotification *)notification {
	[self reloadAll];
	
	[[self getOrderedListOfSubControllers] makeObjectsPerformSelector:@selector(enable)];
	
	mShowProgressPanelOnShow = NO;
	[mProgressPanelIndicator stopAnimation:self];
	[mProgressPanel orderOut:self];
	[NSApp endSheet:mProgressPanel];
}

- (void) clientConnected:(NSNotification *)notification {
	id<LibraryDataSourceProtocol> dataSource = [[WindowController instance] currentLibraryDataSource];
	if (
		([dataSource supportsDataSourceCapabilities] & eLibraryDataSourceSupportsImportingSongs && [dataSource needsImport] == NO) ||
		!([dataSource supportsDataSourceCapabilities] & eLibraryDataSourceSupportsImportingSongs)) {
		[[self getOrderedListOfSubControllers] makeObjectsPerformSelector:@selector(enable)];
		[self reloadAll];
	}
}

- (void) clientDisconnected:(NSNotification *)notification {
	[self clearAndDisableViews];
}

#pragma mark -
#pragma mark Misc Functions

- (void) showGenreView:(BOOL)show {
	NSArray *scrollers;
	if (show == NO)
		scrollers = [NSArray arrayWithObjects:mArtistScroller, mAlbumScroller, nil];
	else
		scrollers = [NSArray arrayWithObjects:mGenreScroller, mArtistScroller, mAlbumScroller, nil];
	
	int width = [mWindow frame].size.width / [scrollers count];
	int height = [mArtistScroller frame].size.height;
	
	for (int i = 0; i < [scrollers count]; i++)
		[[scrollers objectAtIndex:i] setFrame:NSMakeRect(i*width, 0, width, height)];
	
	[mGenreScroller setHidden:!show];
}

- (void) showTitleView:(BOOL)show {
	_titleShown = show;
	
	if (show) {
		[mTitleSplitView expand];
		[mSplitView setDivider:_dividerImage];
	} else {
		[mTitleSplitView collapse];
		[mSplitView setDivider:nil];
	}
}

- (void) profileSwitched:(NSNotification *)aNotification {
	[self reloadAll];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"values.showGenreInLibrary"])
		[self showGenreView:[[PreferencesController sharedInstance] showGenreInLibrary]];
}

- (void) clearAndDisableViews {
	[[self getOrderedListOfSubControllers] makeObjectsPerformSelector:@selector(clearAndDisable)];
}

- (NSArray *) selectedSongsUniqueIdentifiersInTable:(NSTableView *)tableView {
	NSArray *songs;
	if (tableView == mArtistView || tableView == mAlbumView || tableView == mGenreView)
		songs = [mSongController allItems];
	else if (tableView == mSongView)
		songs = [mSongController getSelected:NULL];
	
	NSMutableArray *uniqueIds = [NSMutableArray array];
	for (int i = 0; i < [songs count]; i++)
		[uniqueIds addObject:[[songs objectAtIndex:i] uniqueIdentifier]];
	return uniqueIds;
}

- (PWTableView *) tableViewFromSender:(id)sender {
	if ([sender isKindOfClass:[NSTableView class]])
		return sender;
	if ([[mWindow firstResponder] isKindOfClass:[NSTableView class]])
		return (PWTableView*)[mWindow firstResponder];
	return nil;
}

- (BOOL) executeActionForTableView:(PWTableView *)aTableView withSender:(id)sender {
	// if we were called using our PWTableView action character stuff, let it through
	if ([aTableView characterActionInProgress] == NO)
		// if clicked row is -1, the header could have been clicked - don't continue.
		if ([aTableView clickedRow] == -1)
			// if we are called from a context menu or toolbar item, also let it through
			if ([sender isKindOfClass:[NSMenuItem class]] == NO && [sender isKindOfClass:[NSToolbarItem class]] == NO)
				return NO;
	
	return YES;
}

- (NSArray *) getOrderedListOfSubControllers {
	return [NSArray arrayWithObjects:mGenreController, mArtistController, mAlbumController, mSongController, nil];
}

- (void) reloadAll {
	[[self getOrderedListOfSubControllers] makeObjectsPerformSelector:@selector(reloadData)];
}

- (NSWindow *) window {
	return mWindow;
}

- (BOOL) isGetInfoAllowed {
	if ([mWindow firstResponder] == mSongView)
		return YES;
	return NO;
}

- (void) replaceFilesInPlaylistAndStartPlayingWithSelectionFromTable:(PWTableView *)aTableView {
	NSArray *uniqueIdentifiers = [self selectedSongsUniqueIdentifiersInTable:aTableView];
	
	[[[WindowController instance] musicClient] clearPlaylist];
	[[[WindowController instance] musicClient] addSongsToPlaylistByUniqueIdentifier:uniqueIdentifiers];
	[[[WindowController instance] musicClient] startPlayback];
	
	[[[WindowController instance] playlistController] scheduleShowCurrentSongOnNextSongChange];
	[[[WindowController instance] playlistController] scheduleSelectCurrentSongOnNextSongChange];
}

- (void) appendSongsWithSelectionFromTable:(PWTableView *)aTableView {
	[[[WindowController instance] musicClient] addSongsToPlaylistByUniqueIdentifier:[self selectedSongsUniqueIdentifiersInTable:aTableView]];
}

#pragma mark -
#pragma mark Actions

- (IBAction) replaceFilesInPlaylist:(id)sender {
	PWTableView *tableView = [self tableViewFromSender:sender];
	if (tableView == nil)
		return;

	if ([self executeActionForTableView:tableView withSender:sender])
		[self replaceFilesInPlaylistAndStartPlayingWithSelectionFromTable:tableView];
}

- (IBAction) appendSongsToPlaylist:(id)sender {
	PWTableView *tableView = [self tableViewFromSender:sender];
	if (tableView == nil)
		return;
	
	if ([self executeActionForTableView:tableView withSender:sender])
		[self appendSongsWithSelectionFromTable:tableView];
}

- (IBAction) getInfoOnSongs:(id)sender {
	[[WindowController instance] getInfoOnSongs:[mSongController getSelected:NULL]];
}

- (IBAction) setToggleIsPartOfCompilation:(id)sender {
	NSArray *songs = [mSongController getSelected:NULL];

	id<LibraryDataSourceProtocol> dataSource = [[WindowController instance] currentLibraryDataSource];
	switch ([sender state]) {
		case NSMixedState:
		case NSOffState:
			[dataSource setSongsAsCompilation:songs];
			break;
			
		case NSOnState:
			[dataSource removeSongsAsCompilation:songs];
			break;
	}
	
	[self reloadAll];
}

- (IBAction) tableAction:(id)sender {
	switch ([[PreferencesController sharedInstance] libraryDoubleClickAction]) {
		case eLibraryDoubleClickReplaces:
			[self replaceFilesInPlaylistAndStartPlayingWithSelectionFromTable:sender];
			break;
		case eLibraryDoubleClickAppends:
			[self appendSongsWithSelectionFromTable:sender];
			break;
	}
}

#pragma mark -
#pragma mark Table View Stuff

- (void)tableViewBecameFirstResponder:(NSNotification *)aNotification {
	if ([aNotification object] == mArtistView) {
		[mAppendSongsItem setLabel:NSLocalizedString(@"Append Artists", @"Library toolbar button Label")];
	} else if ([aNotification object] == mAlbumView) {
		[mAppendSongsItem setLabel:NSLocalizedString(@"Append Albums", @"Library toolbar button label")];
	} else if ([aNotification object] == mSongView) {
		[mAppendSongsItem setLabel:NSLocalizedString(@"Append Tracks", @"Library toolbar button label")];
	} else if ([aNotification object] == mGenreView) {
		[mAppendSongsItem setLabel:NSLocalizedString(@"Append Genres", @"Library toolbar button label")];
	}
}

#pragma mark -
#pragma mark Search Stuff

- (void) initiateSearch {
	[[self getOrderedListOfSubControllers] makeObjectsPerformSelector:@selector(saveSelection)];
	[self reloadAll];
	
	if ([mSongView acceptsFirstResponder])
		[mWindow makeFirstResponder:mSongView];
}

- (LibrarySearchController *)searchController {
	return [[mSearchController retain] autorelease];
}

#pragma mark -
#pragma mark Toolbar Stuff

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:tAppendSongs, tGetInfoOnSongs, NSToolbarFlexibleSpaceItemIdentifier, tSearchField, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:tAppendSongs, tGetInfoOnSongs, NSToolbarFlexibleSpaceItemIdentifier, tSearchField, nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	if ([[theItem itemIdentifier] isEqualToString:tAppendSongs]) {
		id object = [mWindow firstResponder];
		if ([object isKindOfClass:[NSTableView class]] == NO) {
			return NO;
		} else {
			if ([object selectedRow] == -1)
				return NO;
		}
	} else if ([[theItem itemIdentifier] isEqualToString:tGetInfoOnSongs]) {
		return [self isGetInfoAllowed];
	}
	
	return YES;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	if ([itemIdentifier isEqualTo:tSearchField]) {
		if (mSearchFieldItem == nil) {
			mSearchFieldItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] retain];
			
			[mSearchFieldItem setView:[mSearchController searchField]];
			
			NSRect frame = [[mSearchFieldItem view] frame];
			[mSearchFieldItem setMinSize:NSMakeSize(NSWidth(frame), NSHeight(frame))];
			[mSearchFieldItem setMaxSize:NSMakeSize(NSWidth(frame), NSHeight(frame))];
		}
		
		return mSearchFieldItem;
	} else if ([itemIdentifier isEqualTo:tAppendSongs]) {
		if (mAppendSongsItem == nil) {
			mAppendSongsItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] retain];
			
			[mAppendSongsItem setLabel:NSLocalizedString(@"Append", @"Library toolbar button label")];
			[mAppendSongsItem setTarget:self];
			[mAppendSongsItem setAction:@selector(appendSongsToPlaylist:)];
		}
		
		return mAppendSongsItem;
	} else if ([itemIdentifier isEqualTo:tGetInfoOnSongs]) {
		if (mGetInfoOnSongs == nil) {
			mGetInfoOnSongs = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] retain];
			
			[mGetInfoOnSongs setLabel:NSLocalizedString(@"Get Info", @"Library toolbar button label")];
			[mGetInfoOnSongs setTarget:self];
			[mGetInfoOnSongs setAction:@selector(getInfoOnSongs:)];			
			[mGetInfoOnSongs setImage:[NSImage imageNamed:@"info"]];
		}
		
		return mGetInfoOnSongs;
	}
	
	return nil;
}

@end
