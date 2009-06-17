//
//  OutputDeviceHandler.m
//  Theremin
//
//  Created by Patrik Weiskircher on 18.05.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OutputDeviceHandler.h"
#import "WindowController.h"
#import "PreferencesController.h"

@interface OutputDeviceHandler (PrivateMethods)
- (void) discoverOutputDevices;
- (void) removeMenuItems;
@end

const static int menuTagOutputDevices = 123411;
const static int menuTagOutputSeperator = 123412;

@implementation OutputDeviceHandler
- (id) initWithMenu:(NSMenu *)theMenu {
	self = [super init];
	if (self != nil) {
		_menu = [theMenu retain];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(connected:)
													 name:(NSString *)nMusicServerClientConnected
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(disconnected:)
													 name:(NSString *)nMusicServerClientDisconnected
												   object:nil];
		
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_menu release];
	[super dealloc];
}

- (void) connected:(NSNotification *)theNotification {
	if (!([[MusicServerClient musicServerClientClassForProfile:[[PreferencesController sharedInstance] currentProfile]] capabilities] & eMusicClientCapabilitiesOutputDevices)) {
		[self removeMenuItems];
	} else {		
		[self discoverOutputDevices];
	}
}

- (void) disconnected:(NSNotification *)theNotification {
	[self removeMenuItems];
}

- (void) removeMenuItems {
	NSMenuItem *item = [_menu itemWithTag:menuTagOutputDevices];
	if (item != nil)
		[_menu removeItemAtIndex:[_menu indexOfItem:item]];
	
	item = [_menu itemWithTag:menuTagOutputSeperator];
	if (item != nil)
		[_menu removeItemAtIndex:[_menu indexOfItem:item]];
}

- (void) discoverOutputDevices {
	[self removeMenuItems];
	
	NSArray *outputDevices = [[[WindowController instance] musicClient] getOutputDevices];
	if ([outputDevices count] == 0)
		return;
	
	NSMenuItem *seperatorItem = [NSMenuItem separatorItem];
	[seperatorItem setTag:menuTagOutputSeperator];
	[_menu addItem:seperatorItem];
	
	NSMenuItem *outputDeviceItem = [[[NSMenuItem alloc] initWithTitle:@"Output Devices" action:nil keyEquivalent:@""] autorelease];
	[outputDeviceItem setSubmenu:[[[NSMenu alloc] init] autorelease]];
	[outputDeviceItem setTag:menuTagOutputDevices];
	[_menu addItem:outputDeviceItem];
	
	for (int i = 0; i < [outputDevices count]; i++) {
		NSDictionary *outputDevice = [outputDevices objectAtIndex:i];
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:[outputDevice objectForKey:dName]
													  action:@selector(toggleOutputDevice:)
											   keyEquivalent:@""] autorelease];
		[item setTarget:self];
		[item setTag:[[outputDevice objectForKey:dId] intValue]];
		[item setState:[[outputDevice objectForKey:dEnabled] boolValue] == YES ? NSOnState : NSOffState];
		
		[[outputDeviceItem submenu] addItem:item];
	}
}

- (void) toggleOutputDevice:(NSMenuItem *)sender {
	BOOL toggleValue = [sender state] == NSOnState ? NO : YES;
	
	[[[WindowController instance] musicClient] setOutputDeviceWithId:[sender tag] toEnabled:toggleValue];
	
	[sender setState:toggleValue == YES ? NSOnState : NSOffState];
}

@end
