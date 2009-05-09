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

#import <Cocoa/Cocoa.h>

typedef enum {
	eModeMPD = 0,
	eModeSqueezeCenter = 1
} ProfileMode;

@interface Profile : NSObject {
	ProfileMode _mode;
	
	NSString *_description;
	NSString *_hostname;
	int _port;
	BOOL _autoreconnect;
	BOOL _default;
	
	NSString *_passwordKey;
	NSString *_cachedPassword;
	BOOL _cachedPasswordSet;
	
	NSString *_user;
}
+ (id) importedFromOldSettings;
+ (id) fromUserDefaults:(NSDictionary *)aUserDefault;
- (id) initWithDescription:(NSString *)aDescription;
- (NSDictionary *) toUserDefaults;

- (id)copyWithZone:(NSZone *)zone;

- (ProfileMode) mode;
- (void) setMode:(ProfileMode)aMode;

- (NSString *) description;
- (void) setDescription:(NSString *)aDescription;

- (NSString *) hostname;
- (void) setHostname:(NSString *)aHostname;

- (int) port;
- (void) setPort:(int)aPort;

- (BOOL) autoreconnect;
- (void) setAutoreconnect:(BOOL)aValue;

- (NSString *) password;
- (void) setPassword:(NSString *)aPassword;
- (BOOL) passwordExists;

- (NSString *) user;
- (void) setUser:(NSString *)aUser;

- (BOOL) default;
- (void) setDefault:(BOOL)aValue;

// This only saves the cached password into the keychain.
- (void) savePassword;

- (BOOL) isEqualToProfile:(Profile *)aProfile;
@end

@interface ProfilePasswordSavingException : NSException {
	
}
@end
