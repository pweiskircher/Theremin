/*
 Copyright (C) 2009  Patrik Weiskircher
 
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

#import "AppleRemoteController.h"
#import "WindowController.h"

#import "MultiClickRemoteBehavior.h"
#import "RemoteControlContainer.h"

#import "PreferencesController.h"

#import "AppleRemote.h"

@interface AppleRemoteController (PrivateMethods)
- (RemoteControl *)appleRemote;
- (AppleRemoteMode) appleRemoteMode;
@end

@implementation AppleRemoteController
- (id) init {
	self = [super init];
	if (self != nil) {
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																  forKeyPath:@"values.appleRemoteMode"
																	 options:NSKeyValueObservingOptionNew 
																	 context:NULL];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationDidBecomeActive:)
													 name:NSApplicationDidBecomeActiveNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationDidResignActive:)
													 name:NSApplicationDidResignActiveNotification
												   object:nil];
		
		if ([[PreferencesController sharedInstance] appleRemoteMode] == eAppleRemoteModeAlways)
			[[self appleRemote] startListening:self];
	}
	return self;
}

- (void) dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[self appleRemote] stopListening:self];
	[_appleRemote release];
	[super dealloc];
}

- (AppleRemoteMode) appleRemoteMode {
	return [[PreferencesController sharedInstance] appleRemoteMode];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"values.appleRemoteMode"]) {
		switch ([self appleRemoteMode]) {
			case eAppleRemoteModeAlways:
				[[self appleRemote] startListening:self];
				break;
				
			case eAppleRemoteModeNever:
				[[self appleRemote] stopListening:self];
				break;
				
			case eAppleRemoteModeWhenFocused:
				if ([NSApp isActive])
					[[self appleRemote] startListening:self];
				break;
		}
	}
}

- (RemoteControl*) appleRemote 
{
	if (_appleRemote == nil) {
		MultiClickRemoteBehavior *behavior = [[[MultiClickRemoteBehavior alloc] init] autorelease];
		[behavior setDelegate:self];
		[behavior setSimulateHoldEvent:YES];
		RemoteControlContainer *container = [[RemoteControlContainer alloc] initWithDelegate:behavior];
		
		[container instantiateAndAddRemoteControlDeviceWithClass:[AppleRemote class]];
		
		_appleRemote = container;
	}
	return _appleRemote;
}

- (void) applicationDidBecomeActive:(NSNotification *)aNotification
{
	if ([self appleRemoteMode] == eAppleRemoteModeWhenFocused) {
		[[self appleRemote] startListening: self];
	}
}

- (void) applicationDidResignActive:(NSNotification *)aNotification
{
	if ([self appleRemoteMode] == eAppleRemoteModeWhenFocused) {
		[[self appleRemote] stopListening: self];
	}
}

- (void) appleRemoteButtonHeldDownWithButton:(NSNumber *)theButton {
	if (_appleRemoteButtonHeld) {
		switch ([theButton intValue]) {
			case kRemoteButtonMinus_Hold:
				[[WindowController instance] decreaseVolume:self];
				break;
			case kRemoteButtonPlus_Hold:
				[[WindowController instance] increaseVolume:self];
				break;
		}
		
		if (_appleRemoteButtonHeld) {
			[self performSelector:@selector(appleRemoteButtonHeldDownWithButton:)
					   withObject:theButton
					   afterDelay:0.25];
		}
	}
}

- (void) remoteButton: (RemoteControlEventIdentifier)buttonIdentifier pressedDown: (BOOL) pressedDown clickCount: (unsigned int)clickCount
{
	if ([[[WindowController instance] musicClient] isConnected] == NO)
		return;
	
	if (buttonIdentifier == kRemoteButtonPlus_Hold ||
		buttonIdentifier == kRemoteButtonMinus_Hold) {
		_appleRemoteButtonHeld = pressedDown;
		if (pressedDown)
			[self appleRemoteButtonHeldDownWithButton:[NSNumber numberWithInt:buttonIdentifier]];
	}
	
	if (pressedDown == NO)
		return;
	
	switch (buttonIdentifier) {
		case kRemoteButtonPlus:
			[[WindowController instance] increaseVolume:self];
			break;
		case kRemoteButtonMinus:
			[[WindowController instance] decreaseVolume:self];
			break;
		case kRemoteButtonPlay:
			[[WindowController instance] togglePlayPause:self];
			break;
		case kRemoteButtonLeft:
			[[WindowController instance] previousSong:self];
			break;
		case kRemoteButtonRight:
			[[WindowController instance] nextSong:self];
			break;
	}
}


@end
