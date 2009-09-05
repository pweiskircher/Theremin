//
//  ProfileController.h
//  Theremin
//
//  Created by Patrik Weiskircher on 13.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Profile;

@interface ProfileController : NSArrayController {
	IBOutlet NSTableView *_tableView;
	
	IBOutlet NSPopUpButton *_type;
	IBOutlet NSTextField *_description;
	IBOutlet NSTextField *_hostname;
	IBOutlet NSTextField *_port;
	IBOutlet NSTextField *_password;
	IBOutlet NSTextField *_user;
	IBOutlet NSButton *_autoreconnect;
	
	IBOutlet NSButton *_defaultButton;
	
	Profile *_lastProfile;
}
- (void) opened;
- (void) saveProfiles;
- (BOOL) currentSelectionIsDefault;
- (IBAction) typeChanged:(id)sender;
- (IBAction) setCurrentSelectionAsDefault:(id)sender;
- (IBAction) removeCurrentlySelectedProfile:(id)sender;
@end
