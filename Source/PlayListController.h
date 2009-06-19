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

extern NSString *gMpdPlaylistPositionType;
extern NSString *gMpdUniqueIdentifierType;

@class WindowController, Song, PWMusicSearchField, PWTableView;

@interface PlayListController : NSObject {
	IBOutlet WindowController *mController;
	IBOutlet PWTableView *mTableView;
	
	// search progress dialog
	IBOutlet NSPanel *mSearchingPanel;
	IBOutlet NSProgressIndicator *mSearchingPanelProgressIndicator;
	
	// randomize progress dialog
	IBOutlet NSPanel *mRandomizePanel;
	IBOutlet NSProgressIndicator *mRandomizePanelProgressIndicator;
	
	// column selection
	IBOutlet NSTableColumn *mColumnTrackNumber;
	IBOutlet NSTableColumn *mColumnArtist;
	IBOutlet NSTableColumn *mColumnAlbum;
	IBOutlet NSTableColumn *mColumnTrackName;
	IBOutlet NSTableColumn *mColumnGenre;
	IBOutlet NSTableColumn *mColumnTime;
	IBOutlet NSTableColumn *mColumnDisc;
	
	IBOutlet NSTextField *mCurrentPlaylistInfo;
	
	NSMutableArray *mPlayList;
	NSMutableArray *mFilteredPlaylist;
	
	int mCurrentPlayingSongPosition;
	
	PWMusicSearchField *mSearchField;
	
	BOOL mScheduledShowCurrentSongOnNextSongChange;
	BOOL mScheduledSelectCurrentSongOnNextSongChange;
	
	BOOL mShownAndSelectedCurrentSongAfterConnect;
	
	BOOL mDisallowPlaylistUpdates;
}
- (void) updateCurrentSongMarker;
- (NSArray *)getSelectedSongs;
- (void) setupSearchField:(PWMusicSearchField *)field;
- (BOOL) showCurrentSong;
- (void) scheduleShowCurrentSongOnNextSongChange;
- (void) scheduleSelectCurrentSongOnNextSongChange;
- (Song *) songOfNextAlbum;
- (Song *) songOfPreviousAlbum;
- (IBAction) deleteSelectedSongs:(id)sender;
- (IBAction) randomizePlaylist:(id)sender;
@end
