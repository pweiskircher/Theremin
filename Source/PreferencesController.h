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
#import <Sparkle/SUUpdater.h>

#define UPDATE_ONCE_A_DAY		1
#define UPDATE_ONCE_A_WEEK		2
#define UPDATE_ONLY_AT_STARTUP	3
#define UPDATE_NEVER			4

#define COVER_ART_AMAZON_DE		0
#define COVER_ART_AMAZON_FR		1
#define COVER_ART_AMAZON_JP		2
#define COVER_ART_AMAZON_UK		3
#define COVER_ART_AMAZON_US		4

typedef enum {
	eAppleRemoteModeAlways		= 0,
	eAppleRemoteModeWhenFocused = 1,
	eAppleRemoteModeNever		= 2
} AppleRemoteMode;

typedef enum {
	eLibraryDoubleClickReplaces = 0,
	eLibraryDoubleClickAppends = 1,
} LibraryDoubleClickMode;

extern NSString *nCoverArtLocaleChanged;
extern NSString *nCoverArtEnabledChanged;

@interface PreferencesController : NSObject {
	IBOutlet NSWindow *mPreferencesWindow;
	IBOutlet NSPopUpButton *mUpdatePopup;
	IBOutlet NSPopUpButton *mCoverArtPopup;
	IBOutlet SUUpdater *mUpdater;
	IBOutlet NSTextField *mPassword;
}
- (void)showPreferences;
- (void)windowDidResignKey:(NSNotification *)aNotification;

- (void) setMpdPassword:(NSString *)aPassword;

- (IBAction) updatePopupMenuChanged:(id)sender;
- (IBAction) coverArtPopupMenuChanged:(id)sender;

- (void) setNoConfirmationNeededForDeletionOfPlaylist:(BOOL)aValue;
- (BOOL) noConfirmationNeededForDeletionOfPlaylist;

- (NSString *) mpdPassword;
- (BOOL) mpdPasswordExists;
- (NSString *) mpdServer;
- (int) mpdPort;
- (BOOL) autoreconnectEnabled;
- (NSString *) coverArtLocale;

- (LibraryDoubleClickMode) libraryDoubleClickAction;

- (BOOL) coverArtEnabled;
- (void) setCoverArtEnabled:(BOOL)aValue;

- (BOOL) askedAboutCoverArt;
- (void) setAskedAboutCoverArt;

- (BOOL) pauseOnSleep;

- (NSString *) currentServerNameWithPort;

- (AppleRemoteMode) appleRemoteMode;

- (void) setPlaylistDrawerOpen:(BOOL)theValue;
- (BOOL) playlistDrawerOpen;

- (void) setPlaylistDrawerWidth:(float)theSize;
- (float) playlistDrawerWidth;

- (NSString *) lastDatabaseFetchedFromServer;
- (void) setLastDatabaseFetchedFromServer:(NSString *)aString;

- (NSData *) databaseIdentifier;
- (void) setDatabaseIdentifier:(NSData *)theDatabaseIdentifier;

- (BOOL) showGenreInLibrary;
- (void) setShowGenreInLibrary:(BOOL)aValue;

- (BOOL) isLibraryOutdated;

@end
