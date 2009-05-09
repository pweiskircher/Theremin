/*
 Copyright (C) 2008  Patrik Weiskircher
 
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

#import "ProfileRepository.h"
#import "Profile.h"

const NSString *cProfilesUserDefaultsPath = @"cProfilesUserDefaultsPath";
const NSString *nProfileControllerUpdatedProfiles = @"nProfileControllerUpdatedProfiles";

@implementation ProfileRepository
+ (NSArray *) profiles {
	NSArray *data = [[NSUserDefaults standardUserDefaults] objectForKey:(NSString *)cProfilesUserDefaultsPath];
	NSMutableArray *profiles = [NSMutableArray array];
	for (int i = 0; i < [data count]; i++)
		[profiles addObject:[Profile fromUserDefaults:[data objectAtIndex:i]]];
	return profiles;
}

+ (Profile *) defaultProfile {
	NSArray *profiles = [self profiles];
	for (int i = 0; i < [profiles count]; i++)
		if ([[profiles objectAtIndex:i] default])
			return [profiles objectAtIndex:i];
	
	if ([profiles count] > 0)
		return [profiles objectAtIndex:0];
	
	return nil;
}

+ (void) saveProfiles:(NSArray *) someProfiles {
	NSMutableArray *profiles = [NSMutableArray array];
	
	for (int i = 0; i < [someProfiles count]; i++) {
		@try {
			[[someProfiles objectAtIndex:i] savePassword];			
		} @catch (ProfilePasswordSavingException *exception) {
			[[NSAlert alertWithMessageText:@"Could not save password."
							 defaultButton:@"OK"
						   alternateButton:nil
							   otherButton:nil
				 informativeTextWithFormat:@"Please set at least a hostname or a description before setting a password."] runModal];
		}
		
		[profiles addObject:[[someProfiles objectAtIndex:i] toUserDefaults]];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:profiles forKey:(NSString *)cProfilesUserDefaultsPath];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)nProfileControllerUpdatedProfiles object:self];
}
@end
