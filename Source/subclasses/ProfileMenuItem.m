//
//  ProfileMenuItem.m
//  Theremin
//
//  Created by Patrik Weiskircher on 13.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ProfileMenuItem.h"


@implementation ProfileMenuItem
- (void) dealloc
{
	[_profile release];
	[super dealloc];
}

- (void) setProfile:(Profile *)aProfile {
	[_profile release];
	_profile = [aProfile retain];
}

- (Profile *) profile {
	return [[_profile retain] autorelease];
}
@end
