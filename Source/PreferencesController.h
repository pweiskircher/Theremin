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
#import "Profile.h"

typedef enum {
	eAppleRemoteModeAlways		= 0,
	eAppleRemoteModeWhenFocused = 1,
	eAppleRemoteModeNever		= 2
} AppleRemoteMode;

typedef enum {
	eLibraryDoubleClickReplaces = 0,
	eLibraryDoubleClickAppends = 1,
} LibraryDoubleClickMode;

@interface PreferencesController : NSObject {	
	Profile *_currentProfile;
}

+ (PreferencesController *) sharedInstance;

- (Profile *) currentProfile;
- (void) setCurrentProfile:(Profile *)aProfile;
- (void) importOldSettings;
- (void) save;

// settings getters ( / setters )

- (void) setNoConfirmationNeededForDeletionOfPlaylist:(BOOL)aValue;
- (BOOL) noConfirmationNeededForDeletionOfPlaylist;

- (LibraryDoubleClickMode) libraryDoubleClickAction;

- (BOOL) pauseOnSleep;

- (NSString *) currentServerNameWithPort;

- (AppleRemoteMode) appleRemoteMode;

- (void) setPlaylistDrawerOpen:(BOOL)theValue;
- (BOOL) playlistDrawerOpen;

- (void) setPlaylistDrawerWidth:(float)theSize;
- (float) playlistDrawerWidth;

- (BOOL) showGenreInLibrary;
- (void) setShowGenreInLibrary:(BOOL)aValue;

- (BOOL) fetchingOfCoverArtEnabled;
- (void) setFetchingOfCoverArt:(BOOL)aValue;

- (BOOL) askedAboutCoverArt;
- (void) setAskedAboutCoverArt;

@end
