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

#import <Cocoa/Cocoa.h>
#import <RBSplitView/RBSplitView.h>
#import <RBSplitView/RBSplitSubview.h>

@class LibraryImportController, PWTableView, PWMusicSearchField, PWWindow;
@class LibraryArtistSubController, LibraryAlbumSubController, LibrarySongSubController;
@class LibrarySearchController, LibraryGenreSubController;

@interface LibraryController : NSObject {
	IBOutlet PWWindow *mWindow;
	
	LibraryArtistSubController *mArtistController;
	IBOutlet PWTableView *mArtistView;
	
	LibraryAlbumSubController *mAlbumController;
	IBOutlet PWTableView *mAlbumView;
	
	LibrarySongSubController *mSongController;
	IBOutlet PWTableView *mSongView;
	
	LibraryGenreSubController *mGenreController;
	IBOutlet PWTableView *mGenreView;
	
	IBOutlet NSScrollView *mGenreScroller;
	IBOutlet NSScrollView *mArtistScroller;
	IBOutlet NSScrollView *mAlbumScroller;
	
	IBOutlet RBSplitSubview *mTitleSplitView;
	IBOutlet RBSplitView *mSplitView;
	BOOL _titleShown;
	
	IBOutlet NSPanel *mProgressPanel;
	IBOutlet NSProgressIndicator *mProgressPanelIndicator;
	BOOL mShowProgressPanelOnShow;
	
	NSToolbar *mToolbar;
	NSToolbarItem *mAppendSongsItem;
	
	NSToolbarItem *mSearchFieldItem;
	NSToolbarItem *mGetInfoOnSongs;
	
	LibraryImportController *mImportController;
	LibrarySearchController *mSearchController;
	
	BOOL mIgnoreSelectionChanged;
	
	NSImage *_dividerImage;
}
- (id) init;
- (void) dealloc;

- (void) show;
- (NSWindow *) window;

- (NSArray *) selectedSongsUniqueIdentifiersInTable:(NSTableView *)tableView;
- (NSArray *) getOrderedListOfSubControllers;

- (LibrarySearchController *)searchController;
- (void) initiateSearch;

- (BOOL) isGetInfoAllowed;
- (void) reloadAll;

- (IBAction) replaceFilesInPlaylist:(id)sender;
- (IBAction) appendSongsToPlaylist:(id)sender;
- (IBAction) getInfoOnSongs:(id)sender;
- (IBAction) setToggleIsPartOfCompilation:(id)sender;
- (IBAction) tableAction:(id)sender;

@end
