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

#import "PlayListController.h"
#import "WindowController.h"
#import "MusicServerClient.h"
#import "Song.h"
#import "PWMusicSearchField.h"
#import "PWTableView.h"
#import "NSStringAdditions.h"

NSString *gMpdPlaylistPositionType = @"gMpdPlaylistPositionType";
NSString *gMpdUniqueIdentifierType = @"gMpdUniqueIdentifierType";

@interface PlayListController (PrivateMethods)
- (NSString *) songString:(int)playlistCount;
- (void) updateAfterNewSongs:(BOOL)needsCompleteReload;
- (void) updateStatusBar;
- (void) clientPlaylistChanged:(NSNotification *)notification;
- (int) currentSongRow;
- (void) clientCurrentSongPositionChanged:(NSNotification *)notification;
- (void)playSelectedSong:(id)sender;
- (Song *) songAtRow:(int)row;
- (void) searchAction:(id)sender;
- (BOOL) selectCurrentSong;
- (IBAction) cancelSearch:(id)sender;
- (Song *) beginningOfAlbumWithPosition:(int)position;
- (IBAction) cancelRandomize:(id)sender;
@end

@implementation PlayListController
- (id) init {
	self = [super init];
	if (self != nil) {
		mCurrentPlayingSongPosition = -1;
		mDisallowPlaylistUpdates = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(clientPlaylistChanged:)
													 name:nMusicServerClientPlaylistChanged 
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientCurrentSongPositionChanged:) 
													 name:nMusicServerClientCurrentSongPositionChanged 
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientDisconnected:)
													 name:nMusicServerClientDisconnected
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientCurrentSongPositionChanged:) 
													 name:nMusicServerClientCurrentSongChanged
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientFetchedPlaylist:)
													 name:nMusicServerClientFetchedPlaylist
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fetchedPlaylistLength:)
													 name:nMusicServerClientFetchedPlaylistLength
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fetchedOnePlaylistTitle:)
													 name:nMusicServerClientFetchedTitleForPlaylist
												   object:nil];
	}
	return self;
}

- (void) awakeFromNib {
	[mTableView setDataSource:self];
	[mTableView registerForDraggedTypes:[NSArray arrayWithObjects:gMpdPlaylistPositionType, gMpdUniqueIdentifierType, nil]];
	
	unichar actionCharacters[] = { NSBackspaceCharacter, NSDeleteCharacter };
	NSString *ac = [NSString stringWithCharacters:actionCharacters length:2];
	NSMutableCharacterSet *mcs = [[[NSMutableCharacterSet alloc] init] autorelease];
	[mcs addCharactersInString:ac];
	[mcs addCharactersInRange:NSMakeRange(NSDeleteFunctionKey,1)];
	[mTableView setActionForCharacters:mcs onTarget:mController usingSelector:@selector(deleteSelectedSongs:)];
	
	[mTableView setTarget:self];
	[mTableView setDoubleAction:@selector(playSelectedSong:)];
	
	unichar returnActionKeys[] = { NSCarriageReturnCharacter };
	NSCharacterSet *returnCharacterSet = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithCharacters:returnActionKeys length:1]];
	[mTableView setActionForCharacters:returnCharacterSet onTarget:self usingSelector:@selector(playSelectedSong:)];
	
	unichar escapeActionKeys[] = { 0x1b };
	NSCharacterSet *escapeCharacterSet = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithCharacters:escapeActionKeys length:1]];
	[mTableView setActionForCharacters:escapeCharacterSet onTarget:self usingSelector:@selector(stopSearch:)];
	
	[mTableView setColumnIdentifierToSearch:@"track"];
	[mTableView setLiveSearchEnabled:YES];
	
	[mTableView enableCustomizableColumnsWithAutosaveName:@"playlistTableInfos"];
}

- (void) dealloc {
	[mSearchField release];
	[mPlayList release];
	[super dealloc];
}

- (void) clientDisconnected:(NSNotification *)notification {
	mShownAndSelectedCurrentSongAfterConnect = NO;
	[self clientPlaylistChanged:notification];
}

- (void) clientPlaylistChanged:(NSNotification *)notification {
	if (mDisallowPlaylistUpdates == YES)
		return;
	
	if ([[mController musicClient] isConnected] == NO) {
		[mPlayList release], mPlayList = nil;
		[mTableView reloadData];
		return;
	}
	
	[mCurrentPlaylistInfo setStringValue:NSLocalizedString(@"Loading playlist ...", "Playlist is currently loading")];
	[mCurrentPlaylistInfo setHidden:NO];
	[[mController musicClient] startFetchPlaylist];
	
	[mTableView reloadData];
}

- (void) clientFetchedPlaylist:(NSNotification *)notification {
	if (mDisallowPlaylistUpdates == YES)
		return;
	
	NSArray *songs = [[notification userInfo] objectForKey:dSongs];
	[mPlayList release];
	mPlayList = [songs retain];
	
	[self updateAfterNewSongs:YES];
}

- (void) updateStatusBar {
	NSArray *currentPlaylist = mPlayList;
	int seconds = 0;
	for (int i = 0; i < [currentPlaylist count]; i++) 
		seconds += [[currentPlaylist objectAtIndex:i] time];
	
	if (seconds > 0) {
		BOOL isValid;
		NSString *formattedSeconds = [NSString convertSecondsToTime:seconds andIsValid:&isValid];
		[mCurrentPlaylistInfo setStringValue:
		 [NSString stringWithFormat:NSLocalizedString(@"%d %@, %@ total time.", "Current playlist information"), [currentPlaylist count], [self songString:[currentPlaylist count]], formattedSeconds]];
		[mCurrentPlaylistInfo setHidden:NO];
	} else
		[mCurrentPlaylistInfo setStringValue:@""];
}

- (void) updateAfterNewSongs:(BOOL)needsCompleteReload {
	if (mFilteredPlaylist) {
		[self searchAction:mSearchField];
	} else if (needsCompleteReload) {
		[mTableView reloadData];
	}
	
	[self updateStatusBar];
	
	if (!mShownAndSelectedCurrentSongAfterConnect) {
		if ([self showCurrentSong] && [self selectCurrentSong])
			mShownAndSelectedCurrentSongAfterConnect = YES;
	}	
}

- (void) fetchedPlaylistLength:(NSNotification *)aNotification {
	int length = [[[aNotification userInfo] objectForKey:dPlaylistLength] intValue];
	
	NSMutableArray *dummyPlaylist = [NSMutableArray arrayWithCapacity:length];
	for (int i = 0; i < length; i++) {
		Song *dummySong = [[[Song alloc] init] autorelease];
		[dummySong setTitle:@"Loading ..."];
		[dummyPlaylist addObject:dummySong];
	}
	
	[mPlayList release];
	mPlayList = [dummyPlaylist retain];
	
	[self updateAfterNewSongs:YES];
}

- (void) fetchedOnePlaylistTitle:(NSNotification *)aNotification {
	int position = [[[aNotification userInfo] objectForKey:dSongPosition] intValue];
	Song *song = [[aNotification userInfo] objectForKey:dSong];
	
	[mPlayList replaceObjectAtIndex:position withObject:song];
	
	NSRect rect = [mTableView rectOfRow:position];
	if (rect.size.width != 0 && rect.size.height != 0)
		[mTableView setNeedsDisplayInRect:rect];
	
	[self updateAfterNewSongs:NO];
}

- (NSString *) songString:(int)playlistCount {
	if (playlistCount > 1)
		return NSLocalizedString(@"songs", "Plural of songs for playlist information");
	return NSLocalizedString(@"song", "Singular of sogns for playlist information");
}

- (int) currentSongRow {
	int row = -1;
	if (mFilteredPlaylist) {
		for (int i = 0; i < [mFilteredPlaylist count]; i++) {
			NSDictionary *dict = [mFilteredPlaylist objectAtIndex:i];
			
			if ([[dict objectForKey:@"playlistPosition"] intValue] == mCurrentPlayingSongPosition) {
				row = i;
				break;
			}
		}
	} else {
		if (!mPlayList || [mPlayList count] < 0)
			return -1;
		
		row = mCurrentPlayingSongPosition;
	}

	return row;
}

- (void) clientCurrentSongPositionChanged:(NSNotification *)notification {				
	if (mCurrentPlayingSongPosition != -1) {
		[self updateCurrentSongMarker];
	}
	
	NSDictionary *dict = [notification userInfo];
	if ([dict objectForKey:dSongPosition] == nil)
		return;
	
	int position = [[dict objectForKey:dSongPosition] intValue];
	
	mCurrentPlayingSongPosition = position;
	[self updateCurrentSongMarker];
	
	if (mScheduledShowCurrentSongOnNextSongChange) {
		mScheduledShowCurrentSongOnNextSongChange = NO;
		[self showCurrentSong];
	}
	
	if (mScheduledSelectCurrentSongOnNextSongChange) {
		mScheduledSelectCurrentSongOnNextSongChange = NO;
		[self selectCurrentSong];
	}

	if (!mShownAndSelectedCurrentSongAfterConnect) {
		if ([self showCurrentSong] && [self selectCurrentSong])
			mShownAndSelectedCurrentSongAfterConnect = YES;
	}
}

- (void) updateCurrentSongMarker {
	int row = [self currentSongRow];
	
	if (row != -1)
		[mTableView setNeedsDisplayInRect:[mTableView rectOfRow:row]];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	if (mFilteredPlaylist != nil)
		return [mFilteredPlaylist count];
	return [mPlayList count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	Song *song;
	int playlistPosition;
	
	if (mFilteredPlaylist) {
		NSDictionary *dict = [mFilteredPlaylist objectAtIndex:rowIndex];
		song = [dict objectForKey:dSong];
		playlistPosition = [[dict objectForKey:@"playlistPosition"] intValue];
	} else {
		song = [self songAtRow:rowIndex];
		playlistPosition = rowIndex;
	}
	
	if ([[aTableColumn identifier] isEqualToString:@"time"]) {
		return [NSString convertSecondsToTime:[song time] andIsValid:NULL];
	} else if ([[aTableColumn identifier] isEqualToString:@"isPlaying"]) {
		if (mCurrentPlayingSongPosition == playlistPosition) {
			if ([mController currentPlayerState] == eStatePlaying) {
				return [NSImage imageNamed:@"isPlaying"];
			} else {
				return [NSImage imageNamed:@"isCurrent"];
			}
		} else {
			NSImage *image = [NSImage imageNamed:@"playlistNotPlaying"];
			if (image == nil) {
				image = [[[NSImage alloc] initWithSize:NSMakeSize(5,5)] autorelease];
				[image setName:@"playlistNotPlaying"];
			}
			return image;
		}
	} else {
		NSString *key;
		if ([[aTableColumn identifier] isEqualToString:@"trackNumber"])
			key = @"track";
		else if ([[aTableColumn identifier] isEqualToString:@"track"])
			key = @"title";
		else
			key = [aTableColumn identifier];
		
		if ([key isEqualToString:@"title"]) {
			NSString *title = [song title];
			if (title == nil || [title length] == 0)
				return [[song file] lastPathComponent];
			else
				return title;
		}
		
		return [song valueForKey:key];
	}
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
	if (mFilteredPlaylist)
		return NO;
	
	unsigned last_index = -1;
	unsigned current_index = [rowIndexes firstIndex];
	while (current_index != NSNotFound) {
		if (last_index != -1 && current_index - last_index != 1)
			return NO;
		
		last_index = current_index;
		current_index = [rowIndexes indexGreaterThanIndex:current_index];
	}
	
	if ([rowIndexes count] == 1)
		[aTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[rowIndexes firstIndex]] byExtendingSelection:NO];
	
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pboard declareTypes:[NSArray arrayWithObject:gMpdPlaylistPositionType] owner:self];
	[pboard setData:data forType:gMpdPlaylistPositionType];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	if (op == NSTableViewDropOn)
		return NSDragOperationNone;
	return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard *pboard = [info draggingPasteboard];
	
	if ([[pboard types] containsObject:gMpdPlaylistPositionType]) {
		NSData *data = [pboard dataForType:gMpdPlaylistPositionType];
		NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		
		BOOL expandSelection = NO;
		int dest = row;
		unsigned current_index = [rowIndexes firstIndex];
		if (current_index > row) {
			while (current_index != NSNotFound)
			{
				[[mController musicClient] moveSongFromPosition:current_index toPosition:dest];
				[aTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:dest] byExtendingSelection:expandSelection];
				expandSelection = YES;
				dest++;
				current_index = [rowIndexes indexGreaterThanIndex: current_index];
			}
		} else {
			current_index = [rowIndexes lastIndex];
			while (current_index != NSNotFound)
			{
				dest--;
				[[mController musicClient] moveSongFromPosition:current_index toPosition:dest];
				[aTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:dest] byExtendingSelection:expandSelection];
				expandSelection = YES;
				current_index = [rowIndexes indexLessThanIndex: current_index];
			}		
		}
		return YES;
	} else if ([[pboard types] containsObject:gMpdUniqueIdentifierType]) {
		NSData *data = [pboard dataForType:gMpdUniqueIdentifierType];
		NSArray *uniqueIdentifiers = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		
		int oldsize = [mPlayList count];
		[[mController musicClient] addSongsToPlaylistByUniqueIdentifier:uniqueIdentifiers];
		
		for (int i = oldsize; i < oldsize + [uniqueIdentifiers count]; i++) {
			[[mController musicClient] moveSongFromPosition:i toPosition:row];
			row++;
		}
		return YES;
	}
	
	return NO;
}

- (void)playSelectedSong:(id)sender {
	// don't do anything if we click a table column header..
	if ([[sender class] isEqualTo:[PWTableView class]]) {
		if ([sender characterActionInProgress] == NO)
			if ([sender clickedRow] == -1)
				return;
	}
	
	int selectedRow = [sender selectedRow];
	Song *song;
	
	if (mFilteredPlaylist) {
		song = [[mFilteredPlaylist objectAtIndex:selectedRow] objectForKey:dSong];
	} else {
		song = [self songAtRow:selectedRow];
	}
	
	[[mController musicClient] skipToSong:song];
}

- (Song *) songAtRow:(int)row {
	return [Song songWithSong:[mPlayList objectAtIndex:row]];
}

- (NSArray *)getSelectedSongs {
	NSIndexSet *songSelection = [mTableView selectedRowIndexes];
	unsigned int indexes[20];
	NSRange range = NSMakeRange(0, [mPlayList count]);
	unsigned int returnValue;
	
	NSMutableArray *selectedSongs = [NSMutableArray array];
	while ( (returnValue = [songSelection getIndexes:indexes maxCount:20 inIndexRange:&range])) {
		for (int i = 0; i < returnValue; i++) {
			if (mFilteredPlaylist) {
				[selectedSongs addObject:[Song songWithSong:[[mFilteredPlaylist objectAtIndex:indexes[i]] objectForKey:dSong]]];
			} else {
				[selectedSongs addObject:[Song songWithSong:[self songAtRow:indexes[i]]]];
			}
		}
		if (returnValue < 20)
			break;
	}
	
	return selectedSongs;
}

- (void) searchAction:(id)sender {
	if ([[sender stringValue] length] == 0) {
		[mFilteredPlaylist release], mFilteredPlaylist = nil;
		[mTableView reloadData];
	} else {
		NSString *searchString = [sender stringValue];
		
		[mFilteredPlaylist release];
		mFilteredPlaylist = [[NSMutableArray array] retain];
		
		int flags = [mSearchField mpdSongFlagsForSearchState];
		NSDate *startDate = [NSDate date];
		BOOL panelShown = NO;
		NSModalSession modalSession;
		NSArray *tokens = [searchString parseIntoTokens];
		for (int i = 0; i < [mPlayList count]; i++) {
			Song *song = [self songAtRow:i];
			if ([song valid] && [song foundTokens:tokens onFields:flags]) {
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:song, dSong, [NSNumber numberWithInt:i], @"playlistPosition", nil];
				[mFilteredPlaylist addObject:dict];
			}
			
			if (panelShown == NO && [[NSDate date] timeIntervalSinceDate:startDate] > 0.5) {
				modalSession = [NSApp beginModalSessionForWindow:mSearchingPanel];
				[mSearchingPanelProgressIndicator setMinValue:0];
				[mSearchingPanelProgressIndicator setMaxValue:[mPlayList count]];
				[mSearchingPanelProgressIndicator setDoubleValue:i];
				[mSearchingPanelProgressIndicator startAnimation:self];
				panelShown = YES;
			} else if (panelShown == YES) {
				[mSearchingPanelProgressIndicator incrementBy:1];
				
				int ret = [NSApp runModalSession:modalSession];
				if (ret != NSRunContinuesResponse) {
					[mFilteredPlaylist release], mFilteredPlaylist = nil;
					[sender setStringValue:@""];
					[mController find:self];
					break;
				}
			}
		}
		
		if (panelShown) {
			[NSApp endModalSession:modalSession];
			[mSearchingPanelProgressIndicator stopAnimation:self];
			[mSearchingPanel orderOut:self];
		}
		
		[mTableView reloadData];
		
		if ([mTableView acceptsFirstResponder])
			[[mController window] makeFirstResponder:mTableView];
		[mTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
}

- (void) stopSearch:(id)sender {
	[mSearchField setStringValue:@""];
	[self searchAction:mSearchField];
}

- (void) setupSearchField:(PWMusicSearchField *)field {
	mSearchField = [field retain];
	
	[field setTarget:self];
	[field setAction:@selector(searchAction:)];
	[field setSearchFlagsAutosaveName:@"playlistSearchField"];
}

- (BOOL) showCurrentSong {
	int row = [self currentSongRow];
	if (row != -1) {
		[mTableView scrollRowToVisible:row];
		return YES;
	}
	return NO;
}

- (BOOL) selectCurrentSong {
	int row = [self currentSongRow];
	if (row != -1) {
		[mTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		return YES;
	}
	return NO;
}

- (void) scheduleShowCurrentSongOnNextSongChange {
	mScheduledShowCurrentSongOnNextSongChange = YES;
}

- (void) scheduleSelectCurrentSongOnNextSongChange {
	mScheduledSelectCurrentSongOnNextSongChange = YES;
}

- (IBAction) cancelSearch:(id)sender {
	[NSApp stopModal];
	[mSearchingPanel orderOut:self];
}

- (Song *) songOfNextAlbum {
	NSString *currentAlbum = [[self songAtRow:mCurrentPlayingSongPosition] album];
	if (currentAlbum == nil)
		return nil;

	for (int i = mCurrentPlayingSongPosition; i < [mPlayList count]; i++) {
		if ([currentAlbum isEqualToString:[[self songAtRow:i] album]] == NO) {
			return [Song songWithSong:[self songAtRow:i]];
		}
	}
	
	for (int i = 0; i < mCurrentPlayingSongPosition; i++) {
		if ([currentAlbum isEqualToString:[[self songAtRow:i] album]] == NO) {
			return [Song songWithSong:[self songAtRow:i]];
		}
	}
	
	return [Song songWithSong:[self songAtRow:0]];
}

- (Song *) beginningOfAlbumWithPosition:(int)position {
	if (position == 0) {
		return [Song songWithSong:[self songAtRow:position]];
	}
	
	NSString *album = [[self songAtRow:position] album];
	if (album == nil)
		return nil;
	
	for (int i = position - 1; i >= 0; i--) {
		if ([album isEqualTo:[[self songAtRow:i] album]] == NO)
			return [Song songWithSong:[self songAtRow:i+1]];
	}
	
	// if this is the first album (the previous for loop didn't find another album) and the last
	// song's album isn't ours, the album begins at song 0
	if ([album isEqualToString:[[self songAtRow:[mPlayList count]-1] album]] == NO)
		return [Song songWithSong:[self songAtRow:0]];
	
	return nil;
}

- (Song *) songOfPreviousAlbum {
	NSString *currentAlbum = [[self songAtRow:mCurrentPlayingSongPosition] album];
	if (currentAlbum == nil)
		return nil;
	
	for (int i = mCurrentPlayingSongPosition; i >= 0; i--) {
		if ([currentAlbum isEqualToString:[[self songAtRow:i] album]] == NO) {
			Song *song = [self beginningOfAlbumWithPosition:i];
			if (song == nil)
				return nil;
			return [Song songWithSong:song];
		}
	}
	
	for (int i = [mPlayList count]-1; i > mCurrentPlayingSongPosition; i--) {
		if ([currentAlbum isEqualToString:[[self songAtRow:i] album]] == NO) {
			Song *song = [self beginningOfAlbumWithPosition:i];
			if (song == nil)
				return nil;
			return [Song songWithSong:song];
		}
	}
	
	return [Song songWithSong:[self songAtRow:0]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	if ([item action] == @selector(selectAllSongs:)) {
		if ([[mController window] firstResponder] != mTableView)
			return NO;
	} else if ([item action] == @selector(deleteSelectedSongs:)) {
		if ([[mController window] firstResponder] != mTableView)
			return NO;
	}
	return YES;
}

- (IBAction) deleteSelectedSongs:(id)sender {
	BOOL selectLastRow = NO;
	
	if ([mTableView numberOfSelectedRows] == 1 && [mTableView isRowSelected:[mTableView numberOfRows]-1])
		selectLastRow = YES;
	
	NSArray *array = [self getSelectedSongs];
	[[mController musicClient] removeSongsFromPlaylist:array];
	
	if (selectLastRow)
		[mTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[mTableView numberOfRows]-2] byExtendingSelection:NO];
	else {
		NSIndexSet *selection = [mTableView selectedRowIndexes];
		if ([selection count] > 0)
			[mTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[selection firstIndex]] byExtendingSelection:NO];
	}
}

- (IBAction) randomizePlaylist:(id)sender {
	NSDate *startDate = [NSDate date];
	BOOL panelShown = NO;
	NSModalSession modalSession;
	NSMutableArray *tmp = [NSMutableArray arrayWithArray:mPlayList];
	int len = [tmp count];

	mDisallowPlaylistUpdates = YES;
	
	for (int i = 0; i < len - 1; i++) {
		if (panelShown == NO && [[NSDate date] timeIntervalSinceDate:startDate] > 0.5) {
			modalSession = [NSApp beginModalSessionForWindow:mRandomizePanel];
			[mRandomizePanelProgressIndicator setMinValue:0];
			[mRandomizePanelProgressIndicator setMaxValue:len];
			[mRandomizePanelProgressIndicator setDoubleValue:i];
			[mRandomizePanelProgressIndicator startAnimation:self];
			panelShown = YES;
		} else if (panelShown == YES) {
			[mRandomizePanelProgressIndicator incrementBy:1];
			
			int ret = [NSApp runModalSession:modalSession];
			if (ret != NSRunContinuesResponse)
				break;
		}
		
		int j = i + rand() / (RAND_MAX / (len - i) + 1);
		id obj = [tmp objectAtIndex:j];
		
		[[[WindowController instance] musicClient] swapSongs:[tmp objectAtIndex:i] with:[tmp objectAtIndex:j]];
		
		[tmp replaceObjectAtIndex:j withObject:[tmp objectAtIndex:i]];
		[tmp replaceObjectAtIndex:i withObject:obj];
	}
	
	mDisallowPlaylistUpdates = NO;

	if (panelShown) {
		[NSApp endModalSession:modalSession];
		[mRandomizePanelProgressIndicator stopAnimation:self];
		[mRandomizePanel orderOut:self];
	}
	
	[self clientPlaylistChanged:nil];

	
	// TODO: this can still race ... although it works quite good for me now
	[[mController musicClient] sendCurrentSongPosition];
	[self scheduleShowCurrentSongOnNextSongChange];
	[self scheduleSelectCurrentSongOnNextSongChange];
}

- (IBAction) cancelRandomize:(id)sender {
	[NSApp stopModal];
	[mRandomizePanel orderOut:self];
}


@end
