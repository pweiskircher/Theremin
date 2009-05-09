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

NSString *nCoverArtLocaleChanged = @"nCoverArtLocaleChanged";
NSString *nCoverArtEnabledChanged = @"nCoverArtEnabledChanged";

NSString *cImportedOldSettings = @"cImportedOldSettings";

@implementation PreferencesController

- (id) initWithSparkleUpdater:(SUUpdater *)aSparkleUpdater {
	self = [super init];
	if (self != nil) {
		mUpdater = [aSparkleUpdater retain];
		
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																  forKeyPath:@"values.enableCoverArt"
																	 options:NSKeyValueObservingOptionNew
																	 context:NULL];		
	}
	return self;
}

- (void) dealloc
{
	[mUpdater release];
	[_currentProfile release];
	[super dealloc];
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

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"values.enableCoverArt"]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:nCoverArtEnabledChanged
															object:self];
	}
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


- (PWPreferencesCoverArtProvider) coverArtProvider {
	NSString *coverArtLocale = [self coverArtLocale];
	if ([coverArtLocale isEqualToString:@"de"])
		return CoverArtProviderAmazonDe;
	else if ([coverArtLocale isEqualToString:@"fr"])
		return CoverArtProviderAmazonFr;
	else if ([coverArtLocale isEqualToString:@"jp"])
		return CoverArtProviderAmazonJp;
	else if ([coverArtLocale isEqualToString:@"uk"])
		return CoverArtProviderAmazonUk;
	else if ([coverArtLocale isEqualToString:@"us"])
		return CoverArtProviderAmazonUs;
	
	[NSException raise:NSInternalInconsistencyException format:@"Unknown cover art provider %@", coverArtLocale];
	return -1;
}

- (void) setCoverArtProvider:(PWPreferencesCoverArtProvider) aCoverArtProvider {
	NSString *setting;
	switch (aCoverArtProvider) {
		case CoverArtProviderAmazonDe:
			setting = @"de";
			break;
			
		case CoverArtProviderAmazonFr:
			setting = @"fr";
			break;
			
		case CoverArtProviderAmazonJp:
			setting = @"jp";
			break;
			
		case CoverArtProviderAmazonUk:
			setting = @"uk";
			break;
			
		case CoverArtProviderAmazonUs:
			setting = @"us";
			break;
	}
	
	[[NSUserDefaults standardUserDefaults] setValue:setting forKey:@"coverArtLocale"];
}

- (PWPreferencesUpdateInterval) updateInterval {
	int checkInterval = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SUScheduledCheckInterval"] intValue];
	BOOL checkAtStartup = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SUCheckAtStartup"] boolValue];
	
	if (checkAtStartup) {
		return UpdateIntervalOnlyAtStartup;
	} else if (checkInterval == 0) {
		return UpdateIntervalNever;
	} else if (checkInterval == 24*60*60) {
		return UpdateIntervalOnceADay;
	} else if (checkInterval == 7*24*60*60) {
		return UpdateIntervalOnceAWeek;
	}
	
	return UpdateIntervalNever;
}

- (void) setUpdateInterval:(PWPreferencesUpdateInterval) aUpdateInterval {
	switch (aUpdateInterval) {
		case UpdateIntervalNever:
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SUScheduledCheckInterval"];
			[mUpdater scheduleCheckWithInterval:0.0];
			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"SUCheckAtStartup"];
			break;
			
		case UpdateIntervalOnceADay:
			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:24*60*60] forKey:@"SUScheduledCheckInterval"];
			[mUpdater scheduleCheckWithInterval:24*60*60];
			break;
			
		case UpdateIntervalOnceAWeek:
			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:7*24*60*60] forKey:@"SUScheduledCheckInterval"];
			[mUpdater scheduleCheckWithInterval:7*24*60*60];
			break;
			
		case UpdateIntervalOnlyAtStartup:
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SUScheduledCheckInterval"];
			[mUpdater scheduleCheckWithInterval:0.0];
			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"SUCheckAtStartup"];			
			break;
	}
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

@end
