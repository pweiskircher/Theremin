//
//  SLCLICredentials.m
//  SqueezeLib
//
//  Created by Patrik Weiskircher on 14.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SLCLICredentials.h"


@implementation SLCLICredentials
+ (id) cliCredentialsWithUsername:(NSString *)aUsername andPassword:(NSString *)aPassword {
	return [[[SLCLICredentials alloc] initWithUsername:aUsername andPassword:aPassword] autorelease];
}

- (id) initWithUsername:(NSString *)aUsername andPassword:(NSString *)aPassword {
	self = [super init];
	if (self != nil) {
		_username = [aUsername retain];
		_password = [aPassword retain];
	}
	return self;
}

- (void) dealloc
{
	[_username release];
	[_password release];
	[super dealloc];
}


- (NSString *) username {
	return [[_username retain] autorelease];
}

- (NSString *) password {
	return [[_password retain] autorelease];
}
@end
