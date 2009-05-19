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
#import "ProfileRepository.h"

NSString *cImportedOldSettings = @"cImportedOldSettings";

static PreferencesController *_sharedPreferencesController;

@implementation PreferencesController

- (id) init {
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (void) dealloc
{
	[_currentProfile release];
	[super dealloc];
}

+ (PreferencesController *) sharedInstance {
	if (_sharedPreferencesController == nil) {
		_sharedPreferencesController = [[PreferencesController alloc] init];
	}
	return _sharedPreferencesController;
}

- (void) importOldSettings {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:cImportedOldSettings])
		return;
	
	Profile *profile = [Profile importedFromOldSettings];
	
	NSMutableArray *profiles = [NSMutableArray arrayWithArray:[ProfileRepository profiles]];
	[profiles addObject:profile];
	
	[ProfileRepository saveProfiles:profiles];
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:cImportedOldSettings];
}

- (void) save {
	[[NSUserDefaultsController sharedUserDefaultsController] commitEditing];
}

- (Profile *) currentProfile {
	if (_currentProfile == nil) {
		Profile *profile = [ProfileRepository defaultProfile];
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

- (NSString *) currentServerNameWithPort {
	return [NSString stringWithFormat:@"%@:%d", [[self currentProfile] hostname], [[self currentProfile] port]];
}


// set using cocoa bindings in UI
- (BOOL) pauseOnSleep {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"pauseOnSleep"] boolValue];
}


- (void) setNoConfirmationNeededForDeletionOfPlaylist:(BOOL)aValue {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:aValue] forKey:@"NoConfirmationNeededForDeletionOfPlaylist"];
}

- (BOOL) noConfirmationNeededForDeletionOfPlaylist {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"NoConfirmationNeededForDeletionOfPlaylist"] boolValue];
}


// set using cocoa bindings in UI
- (AppleRemoteMode) appleRemoteMode {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"appleRemoteMode"] intValue];
}

// set using cocoa bindings in UI
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

- (NSString *) coverArtFetchingPropertyName {
  return @"coverArtFetchingEnabled";

}
- (BOOL) fetchingOfCoverArtEnabled {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:[self coverArtFetchingPropertyName]] boolValue];
}

- (void) setFetchingOfCoverArt:(BOOL)aValue {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:aValue] forKey:@"coverArtFetchingEnabled"];
}

- (BOOL) askedAboutCoverArt {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"wasAskedAboutCoverArt"] boolValue];
}

- (void) setAskedAboutCoverArt {
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"wasAskedAboutCoverArt"];
}

@end
