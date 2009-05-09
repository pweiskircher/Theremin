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

#import "Profile.h"
#import <Security/Security.h>

const NSString *cProfileMode = @"cProfileMode";
const NSString *cProfileDescription = @"cProfileDescription";
const NSString *cProfileHostname = @"cProfileHostname";
const NSString *cProfilePort = @"cProfilePort";
const NSString *cProfileAutoreconnect = @"cProfileAutoreconnect";
const NSString *cProfilePasswordKey = @"cProfilePasswordKey";
const NSString *cProfileDefault = @"cProfileDefault";
const NSString *cProfileUser = @"cProfileUser";

const char *gKeychainServiceName = "Theremin";

@interface Profile (PrivateMethods)
- (void) setPasswordKey:(NSString *)aPasswordKey;
- (NSString *) passwordKey;
- (BOOL) generatePasswordKey;

- (void) savePasswordToKeychain:(NSString *)aPassword;
@end

@implementation Profile
+ (id) importedFromOldSettings {
	Profile *profile = [[[Profile alloc] initWithDescription:@"Imported Profile"] autorelease];
	
	NSString *hostname = [[NSUserDefaults standardUserDefaults] objectForKey:@"mpdServer"];
	if (hostname == nil || [hostname length] == 0)
		hostname = @"localhost";
	[profile setHostname:hostname];
	
	int port = [[[NSUserDefaults standardUserDefaults] objectForKey:@"mpdPort"] intValue];
	if (port == 0)
		port = 6600;
	
	[profile setPort:port];
	[profile setAutoreconnect:[[[NSUserDefaults standardUserDefaults] objectForKey:@"autoreconnect"] boolValue]];
	[profile setDefault:YES];
	[profile generatePasswordKey];
	
	return profile;
}

+ (id) fromUserDefaults:(NSDictionary *)aUserDefault {
	Profile *profile = [[Profile alloc] initWithDescription:[aUserDefault objectForKey:cProfileDescription]];
	
	[profile setMode:[[aUserDefault objectForKey:cProfileMode] intValue]];
	[profile setHostname:[aUserDefault objectForKey:cProfileHostname]];
	[profile setPort:[[aUserDefault objectForKey:cProfilePort] intValue]];
	[profile setAutoreconnect:[[aUserDefault objectForKey:cProfileAutoreconnect] boolValue]];
	[profile setPasswordKey:[aUserDefault objectForKey:cProfilePasswordKey]];
	[profile setDefault:[[aUserDefault objectForKey:cProfileDefault] boolValue]];
	[profile setUser:[aUserDefault objectForKey:cProfileUser]];
	
	return [profile autorelease];
}

- (id) initWithDescription:(NSString *)aDescription {
	self = [super init];
	if (self != nil) {
		[self setDescription:aDescription];
		[self setPort:-1];
		[self setAutoreconnect:YES];
		[self setHostname:@"localhost"];
	}
	return self;
}

- (void) dealloc
{
	[_hostname release];
	[_description release];
	[_passwordKey release];
	[_cachedPassword release];
	[_user release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
	Profile *profile = [[Profile allocWithZone:zone] initWithDescription:[self description]];
	[profile setMode:[self mode]];
	[profile setHostname:[self hostname]];
	[profile setPort:[self port]];
	[profile setAutoreconnect:[self autoreconnect]];
	[profile setDefault:[self default]];
	[profile setPasswordKey:[self passwordKey]];
	[profile setUser:[self user]];
	
	if (_cachedPasswordSet) {
		profile->_cachedPasswordSet = YES;
		profile->_cachedPassword = [_cachedPassword retain];
	}
		
	return profile;
}


- (NSDictionary *) toUserDefaults {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	if ([self description])
		[dict setObject:[self description] forKey:cProfileDescription];
	
	if ([self hostname])
		[dict setObject:[self hostname] forKey:cProfileHostname];
	[dict setObject:[NSNumber numberWithInt:[self mode]] forKey:cProfileMode];
	[dict setObject:[NSNumber numberWithInt:[self port]] forKey:cProfilePort];
	[dict setObject:[NSNumber numberWithBool:[self autoreconnect]] forKey:cProfileAutoreconnect];
	
	if ([self passwordKey])
		[dict setObject:[self passwordKey] forKey:cProfilePasswordKey];
	
	[dict setObject:[NSNumber numberWithBool:[self default]] forKey:cProfileDefault];
	
	if ([self user] != nil)
		[dict setObject:[self user] forKey:cProfileUser];
	 
	 return [NSDictionary dictionaryWithDictionary:dict];
}

- (ProfileMode) mode {
	return _mode;
}

- (void) setMode:(ProfileMode)aMode {
	_mode = aMode;
}


- (NSString *) description {
	return [[_description retain] autorelease];
}

- (void) setDescription:(NSString *)aDescription {
	[_description release];
	_description = [aDescription retain];
}


- (NSString *) hostname {
	return [[_hostname retain] autorelease];
}

- (void) setHostname:(NSString *)aHostname {
	[_hostname release];
	_hostname = [aHostname retain];
}


- (int) port {
	return _port;
}

- (void) setPort:(int)aPort {
	_port = aPort;
}


- (BOOL) autoreconnect {
	return _autoreconnect;
}

- (void) setAutoreconnect:(BOOL)aValue {
	_autoreconnect = aValue;
}


- (NSString *) password {
	if (_cachedPassword != nil)
		return [[_cachedPassword retain] autorelease];
	
	NSString *accountName = [self passwordKey];
	if (accountName == nil || [accountName length] < 1)
		return nil;
	
	void *password;
	UInt32 passwordLength;
	
	if (SecKeychainFindGenericPassword(NULL, strlen(gKeychainServiceName), gKeychainServiceName, [accountName length],
									   [accountName UTF8String], &passwordLength, &password, NULL) != noErr)
		return nil;
	
	NSString *s = [[NSMutableString alloc] initWithCString:password length:passwordLength];
	memset(password,0xFF,passwordLength);
	
	SecKeychainItemFreeContent(NULL, password);
	return [s autorelease];
}

- (void) setPassword:(NSString *)aPassword {
	_cachedPasswordSet = YES;
	
	[_cachedPassword release];
	
	if ([aPassword length] > 0)
		_cachedPassword = [aPassword retain];
	else
		_cachedPassword = nil;
}

- (void) savePasswordToKeychain:(NSString *)aPassword {
	NSString *accountName = [self passwordKey];
	if (accountName == nil || [accountName length] < 1) {
		if ([self generatePasswordKey] == NO)
			[ProfilePasswordSavingException raise:@"ProfilePasswordSavingException" format:@"Could not generate a password key"];
		accountName = [self passwordKey];
	}
		
	
	SecKeychainItemRef itemRef;
	if (SecKeychainFindGenericPassword(NULL,strlen(gKeychainServiceName),gKeychainServiceName,[accountName length],
									   [accountName UTF8String],0,NULL,&itemRef) != noErr) {
		if (aPassword && [aPassword length] > 0)
			SecKeychainAddGenericPassword(NULL,strlen(gKeychainServiceName),gKeychainServiceName,[accountName length],
										  [accountName UTF8String],[aPassword length],[aPassword UTF8String],NULL);
		return;
	}
	
	if (aPassword == nil) {
		SecKeychainItemDelete(itemRef);
		CFRelease(itemRef);
	} else {
		SecKeychainItemModifyContent(itemRef,NULL,[aPassword length],[aPassword UTF8String]);
		CFRelease(itemRef);
	}
}

- (BOOL) passwordExists {
	if (_cachedPassword != nil)
		return YES;
	
	NSString *accountName = [self passwordKey];
	if (accountName == nil || [accountName length] < 1)
		return NO;
	
	SecKeychainItemRef itemRef;
	
	if (SecKeychainFindGenericPassword(NULL,strlen(gKeychainServiceName),gKeychainServiceName,[accountName length],
									   [accountName UTF8String],0,NULL,&itemRef) == noErr)
		return YES;
	return NO;
}
	
	
- (void) setPasswordKey:(NSString *)aPasswordKey {
	[_passwordKey release];
	_passwordKey = [aPasswordKey retain];
}

- (NSString *) passwordKey {
	return [[_passwordKey retain] autorelease];
}

- (BOOL) generatePasswordKey {
	if ([self hostname] != nil && [[self hostname] length] > 0) {
		_passwordKey = [[NSString stringWithFormat:@"%@:%d", [self hostname], [self port]] retain];
		return YES;
	} else if ([self description] != nil && [[self description] length] > 0) {
		_passwordKey = [self description];
		return YES;
	}
	
	return NO;
}

- (void) savePassword {
	if (_cachedPasswordSet)
		[self savePasswordToKeychain:_cachedPassword];
	
	_cachedPasswordSet = NO;
	[_cachedPassword release], _cachedPassword = nil;
}

- (NSString *) user {
	return [[_user retain] autorelease];
}

- (void) setUser:(NSString *)aUser {
	[_user release];
	_user = [aUser retain];
}

- (BOOL) default {
	return _default;
}

- (void) setDefault:(BOOL)aValue {
	_default = aValue;
}

- (BOOL) isEqual:(id)aProfile {
	if ([aProfile isKindOfClass:[Profile class]])
		return [self isEqualToProfile:aProfile];
	return NO;
}

- (BOOL) isEqualToProfile:(Profile *)aProfile {
	return [[self description] isEqualToString:[aProfile description]] &&
		   [[self hostname] isEqualToString:[aProfile hostname]] &&
		    [self port] == [aProfile port] &&
	[self autoreconnect] == [aProfile autoreconnect];
}

@end

@implementation ProfilePasswordSavingException
@end
