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

#import "PreferencesController.h"
#import <Security/Security.h>
#import "WindowController.h"
#import "MusicServerClient.h"
#import "ProfileController.h"

NSString *nCoverArtLocaleChanged = @"nCoverArtLocaleChanged";
NSString *nCoverArtEnabledChanged = @"nCoverArtEnabledChanged";

NSString *cImportedOldSettings = @"cImportedOldSettings";

@implementation PreferencesController

- (ProfileController *) profileController {
	return [[mProfileController retain] autorelease];
}

- (Profile *) currentProfile {
	if (_currentProfile == nil) {
		Profile *profile = [[self profileController] defaultProfile];
		if (profile == nil) {
			profile = [[[Profile alloc] initWithDescription:@"Local MPD"] autorelease];
			[profile setHostname:@"localhost"];
			[profile setPort:6600];
			[profile setAutoreconnect:NO];
			[profile setMode:eModeMPD];
		}
		
		return profile;
	}
		
	return [[_currentProfile retain] autorelease];
}

- (void) setCurrentProfile:(Profile *)aProfile {
	[_currentProfile release];
	_currentProfile = [aProfile retain];
}

- (void) importOldSettings {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:cImportedOldSettings])
		return;

	Profile *profile = [Profile importedFromOldSettings];
	
	[[self profileController] addObject:profile];
	[[self profileController] saveProfiles];
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:cImportedOldSettings];
}

- (void) dealloc
{
	[_currentProfile release];
	[super dealloc];
}


- (void) awakeFromNib {
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:@"values.enableCoverArt"
																 options:NSKeyValueObservingOptionNew
																 context:NULL];
}

- (void)showPreferences {
	int checkInterval = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SUScheduledCheckInterval"] intValue];
	BOOL checkAtStartup = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SUCheckAtStartup"] boolValue];
	
	if (checkAtStartup) {
		[mUpdatePopup selectItemWithTag:UPDATE_ONLY_AT_STARTUP];
	} else if (checkInterval == 0) {
		[mUpdatePopup selectItemWithTag:UPDATE_NEVER];
	} else if (checkInterval == 24*60*60) {
		[mUpdatePopup selectItemWithTag:UPDATE_ONCE_A_DAY];
	} else if (checkInterval == 7*24*60*60) {
		[mUpdatePopup selectItemWithTag:UPDATE_ONCE_A_WEEK];
	} else {
		[mUpdatePopup selectItemWithTag:UPDATE_NEVER];
	}
	
	[mPreferencesWindow makeKeyAndOrderFront:self];

	NSString *coverArtLocale = [[NSUserDefaults standardUserDefaults] objectForKey:@"coverArtLocale"];
	if ([coverArtLocale isEqual:@"de"]) {
		[mCoverArtPopup selectItemWithTag:COVER_ART_AMAZON_DE];
	} else if ([coverArtLocale isEqualToString:@"fr"]) {
		[mCoverArtPopup selectItemWithTag:COVER_ART_AMAZON_FR];
	} else if ([coverArtLocale isEqualToString:@"jp"]) {
		[mCoverArtPopup selectItemWithTag:COVER_ART_AMAZON_JP];
	} else if ([coverArtLocale isEqualToString:@"uk"]) {
		[mCoverArtPopup selectItemWithTag:COVER_ART_AMAZON_UK];
	} else if ([coverArtLocale isEqualToString:@"us"]) {
		[mCoverArtPopup selectItemWithTag:COVER_ART_AMAZON_US];
	}
}

- (void)windowDidResignKey:(NSNotification *)aNotification {
	[mProfileController saveProfiles];
	[[NSUserDefaultsController sharedUserDefaultsController] commitEditing];
}

- (IBAction) updatePopupMenuChanged:(id)sender {
	int tag = [[sender selectedItem] tag];
	
	switch (tag) {
		case UPDATE_NEVER:
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SUScheduledCheckInterval"];
			[mUpdater scheduleCheckWithInterval:0.0];
			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"SUCheckAtStartup"];
			break;
			
		case UPDATE_ONCE_A_DAY:
			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:24*60*60] forKey:@"SUScheduledCheckInterval"];
			[mUpdater scheduleCheckWithInterval:24*60*60];
			break;
			
		case UPDATE_ONCE_A_WEEK:
			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:7*24*60*60] forKey:@"SUScheduledCheckInterval"];
			[mUpdater scheduleCheckWithInterval:7*24*60*60];
			break;
			
		case UPDATE_ONLY_AT_STARTUP:
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SUScheduledCheckInterval"];
			[mUpdater scheduleCheckWithInterval:0.0];
			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"SUCheckAtStartup"];			
			break;
	}
}

- (IBAction) coverArtPopupMenuChanged:(id)sender {
	int tag = [[sender selectedItem] tag];
	
	NSString *setting;
	switch (tag) {
		case COVER_ART_AMAZON_DE:
			setting = @"de";
			break;
			
		case COVER_ART_AMAZON_FR:
			setting = @"fr";
			break;
			
		case COVER_ART_AMAZON_JP:
			setting = @"jp";
			break;
			
		case COVER_ART_AMAZON_UK:
			setting = @"uk";
			break;
			
		case COVER_ART_AMAZON_US:
			setting = @"us";
			break;
	}
	
	[[NSUserDefaults standardUserDefaults] setValue:setting forKey:@"coverArtLocale"];
	
	// we have to clear the cache manually as otherwise we don't know if the CoverArtView or the CoverArtCache notification
	// will be recevied at first..
	//[[CoverArtCache defaultCache] invalidateCache];
	[[NSNotificationCenter defaultCenter] postNotificationName:nCoverArtLocaleChanged object:self];
}

- (NSString *) coverArtLocale {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"coverArtLocale"];
}

- (BOOL) coverArtEnabled {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"enableCoverArt"] boolValue];
}

- (void) setCoverArtEnabled:(BOOL)aValue {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:aValue] forKey:@"enableCoverArt"];
}


- (NSString *) currentServerNameWithPort {
	return [NSString stringWithFormat:@"%@:%d", [[self currentProfile] hostname], [[self currentProfile] port]];
}

- (BOOL) askedAboutCoverArt {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"askedCoverArt"] boolValue];
}

- (void) setAskedAboutCoverArt {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"askedCoverArt"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"values.enableCoverArt"]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:nCoverArtEnabledChanged
															object:self];
	}
}

- (BOOL) pauseOnSleep {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"pauseOnSleep"] boolValue];
}


- (void) setNoConfirmationNeededForDeletionOfPlaylist:(BOOL)aValue {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:aValue] forKey:@"NoConfirmationNeededForDeletionOfPlaylist"];
}

- (BOOL) noConfirmationNeededForDeletionOfPlaylist {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"NoConfirmationNeededForDeletionOfPlaylist"] boolValue];
}

- (AppleRemoteMode) appleRemoteMode {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"appleRemoteMode"] intValue];
}

- (LibraryDoubleClickMode) libraryDoubleClickAction {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"libraryDoubleClickAction"] intValue];
}


- (void) setPlaylistDrawerOpen:(BOOL)theValue {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:theValue] forKey:@"playlistDrawerOpen"];
}

- (BOOL) playlistDrawerOpen {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"playlistDrawerOpen"] boolValue];
}

- (void) setPlaylistDrawerWidth:(float)theWidth {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:theWidth] forKey:@"playlistDrawerWidth"];
}

- (float) playlistDrawerWidth {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"playlistDrawerWidth"] floatValue]; 
}

- (BOOL) showGenreInLibrary {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"showGenreInLibrary"] boolValue];
}

- (void) setShowGenreInLibrary:(BOOL)aValue {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:aValue] forKey:@"showGenreInLibrary"];
}

@end
