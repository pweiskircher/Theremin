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

#import "GrowlMessenger.h"
#import "Song.h"

NSString *nGrowlNotificationPlaying = @"Song Changed Notification";

@interface GrowlMessenger (PrivateMethods)
- (void) sendGrowlInfo:(NSTimer *)aTimer;
@end

@implementation GrowlMessenger
- (id) initWithDelegate:(id)aDelegate {
	self = [super init];
	if (self != nil) {
		_delegate = aDelegate;
		[GrowlApplicationBridge setGrowlDelegate:self];
	}
	return self;
}

- (void) dealloc
{
	[_currentSong release];
	[_lastSongIdentifier release];
	[_lastSongTitle release];
	[_growlDictionary release];
	[super dealloc];
}


- (NSDictionary *) registrationDictionaryForGrowl {
	if (!_growlDictionary) {
		_growlDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:nGrowlNotificationPlaying], GROWL_NOTIFICATIONS_ALL, [NSArray arrayWithObject:nGrowlNotificationPlaying], GROWL_NOTIFICATIONS_DEFAULT, nil] retain];
	}
	return _growlDictionary;
}

- (void) growlNotificationWasClicked:(id)clickContext {
	if ([clickContext isEqualTo:nGrowlNotificationPlaying]) {
		[_delegate growlMessengerNotificationWasClicked:self];
	}
}

- (void) currentSongChanged:(Song *)theCurrentSong {
	[_currentSong release];
	_currentSong = [theCurrentSong retain];
	
	// this is FUBAR
	if ((![[_currentSong uniqueIdentifier] isEqualTo:_lastSongIdentifier]) || ((_currentSong.title != _lastSongTitle) && ( ! [_currentSong.title isEqualToString:_lastSongTitle]))) {
		[_lastSongIdentifier release], _lastSongIdentifier = nil;
		[_lastSongTitle release];
		_lastSongTitle = nil;
		
		[self sendGrowlInfo:nil];
		
		_lastSongIdentifier = [[_currentSong uniqueIdentifier] copy];
		_lastSongTitle = [_currentSong.title copy];
	}
}

- (void) sendGrowlInfo:(NSTimer *)aTimer {	
	NSMutableArray *notableTags = [NSMutableArray array];
	
	if (_currentSong.title) {
		[notableTags addObject:_currentSong.title];
	}
	
	if (_currentSong.name) {
		// Name is usually not set for files, but is used for streams
		[notableTags addObject:_currentSong.name];
	}
	
	if (( ! notableTags.count) && _currentSong.file) {
		// Last resort for untagged files
		[notableTags addObject:_currentSong.file];
	}
	
	if (_currentSong.album) {
		[notableTags addObject:_currentSong.album];
	}
	
	if (_currentSong.artist) {
		[notableTags addObject:_currentSong.artist];
	}
	if (_currentSong.composer) {
		[notableTags addObject:_currentSong.composer];
	}
	
	NSString *notificationTitle = [notableTags objectAtIndex:0];
	[notableTags removeObject:notificationTitle];
	
	NSString *notificationDescription = [notableTags componentsJoinedByString:@"\n"];
	
	[GrowlApplicationBridge notifyWithTitle:notificationTitle
								description:notificationDescription
						   notificationName:nGrowlNotificationPlaying
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nGrowlNotificationPlaying];
}

@end
