//
//  ProfileMenuItem.h
//  Theremin
//
//  Created by Patrik Weiskircher on 13.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Profile.h"

@interface ProfileMenuItem : NSMenuItem {
	Profile *_profile;
}
- (void) setProfile:(Profile *)aProfile;
- (Profile *) profile;
@end
