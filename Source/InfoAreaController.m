//
//  InfoAreaController.m
//  Theremin
//
//  Created by Patrik Weiskircher on 10.02.07.
//  Copyright 2007 Patrik Weiskircher. All rights reserved.
//

#import "InfoAreaController.h"
#import "WindowController.h"
#import "MusicServerClient.h"
#import "PreferencesController.h"
#import "Song.h"
#import "NSStringAdditions.h"


NSString *nGrowlNotificationPlaying = @"Song Changed Notification";

@implementation InfoAreaController
- (id) init {
	self = [super init];
	if (self != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientCurrentSongChanged:)
													 name:nMusicServerClientCurrentSongChanged
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientConnecting:)
													 name:nMusicServerClientConnecting
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientConnected:)
													 name:nMusicServerClientConnected
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientDisconnected:)
													 name:nMusicServerClientDisconnected
												   object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib {
	[GrowlApplicationBridge setGrowlDelegate:self];
	
	mOriginalOriginTitle = [mTitle frame].origin;
	mOriginalOriginArtist = [mArtist frame].origin;
	mOriginalOriginProgressLabel = [mProgressLabel frame].origin;
}

- (void) growlNotificationWasClicked:(id)clickContext {
	if ([clickContext isEqualTo:nGrowlNotificationPlaying]) {
		[NSApp activateIgnoringOtherApps:YES];
		[[WindowController instance] showPlayerWindow:self];
	}
}

- (NSDictionary *) registrationDictionaryForGrowl {
	if (!mGrowlDictionary) {
		mGrowlDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:nGrowlNotificationPlaying], GROWL_NOTIFICATIONS_ALL, [NSArray arrayWithObject:nGrowlNotificationPlaying], GROWL_NOTIFICATIONS_DEFAULT, nil] retain];
	}
	return mGrowlDictionary;
}

- (void) updateWithTimer:(NSTimer *)timer {
	[timer release];
	mInfoAreaUpdateTimer = nil;
	[self update];
}

- (void) scheduleUpdate {
	if (mInfoAreaUpdateTimer) {
		[mInfoAreaUpdateTimer invalidate];
		[mInfoAreaUpdateTimer release];
	}
	mInfoAreaUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateWithTimer:) userInfo:nil repeats:NO] retain];
}

- (void) update {
	WindowController *wc = [WindowController instance];
	if ([[wc musicClient] isConnected] == YES) {
		if ([wc currentPlayerState] == eStateStopped) {
			[mTitle setStringValue:NSLocalizedString(@"Not playing.", @"Info Area Status Text")];
			[mArtist setStringValue:@""];
			[mAlbum setStringValue:@""];
			[self updateSeekBarWithTotalTime:0];
			[self updateSeekBarWithElapsedTime:0];
			[mLastNotifiedSongIdentifier release], mLastNotifiedSongIdentifier = nil;
		} else if ([mCurrentSong valid]) {
			if ([mCurrentSong title] == nil || [[mCurrentSong title] length] == 0) {
				if ([mCurrentSong file] && [[mCurrentSong file] length])
					[mTitle setStringValue:[[mCurrentSong file] lastPathComponent]];
				else
					[mTitle setStringValue:@""];
			} else {
				[mTitle setStringValue:[mCurrentSong title]];
			}
			
			if ([mCurrentSong artist])
				[mArtist setStringValue:[mCurrentSong artist]];
			else
				[mArtist setStringValue:@""];
			
			if ([mCurrentSong album])
				[mAlbum setStringValue:[mCurrentSong album]];
			else
				[mAlbum setStringValue:@""];

		} else {
			[mTitle setStringValue:@""];
			[mArtist setStringValue:@""];
			[mAlbum setStringValue:@""];
		}
	} else {
		[mTitle setStringValue:NSLocalizedString(@"Not connected.", @"Info Area Status Text")];
		[mArtist setStringValue:@""];
		[mAlbum setStringValue:@""];

		[self updateSeekBarWithTotalTime:0];
		[self updateSeekBarWithElapsedTime:0];
	}
}

- (void) updateSeekBarWithTotalTime:(int)total {
	_total = total;
	[mSeekSlider setMinValue:0];
	[mSeekSlider setMaxValue:total];
}

- (void) updateSeekBarWithElapsedTime:(int)elapsed {
	int remaining = _total - elapsed;
	
	[mElapsedTime setStringValue:[NSString convertSecondsToTime:elapsed andIsValid:NULL]];
	
	BOOL isValid = NO;
	NSString *tmp = [NSString convertSecondsToTime:remaining andIsValid:&isValid];
	[mRemainingTime setStringValue:[NSString stringWithFormat:@"%c%@", isValid == YES ? '-' : ' ', tmp]];
	
	[mSeekSlider setIntValue:elapsed];
}

- (void) updateSeekBarWithSongLength:(int)songLength andElapsedTime:(int)elapsed {
	int remaining = songLength - elapsed;
	
	[mElapsedTime setStringValue:[NSString convertSecondsToTime:elapsed andIsValid:NULL]];
	
	BOOL isValid = NO;
	NSString *tmp = [NSString convertSecondsToTime:remaining andIsValid:&isValid];
	[mRemainingTime setStringValue:[NSString stringWithFormat:@"%c%@", isValid == YES ? '-' : ' ', tmp]];
	
	[mSeekSlider setMinValue:0];
	[mSeekSlider setMaxValue:songLength];
	[mSeekSlider setIntValue:elapsed];
}

- (void) sendGrowlInfo:(NSTimer *)aTimer {
	[mGrowlTimer release], mGrowlTimer = nil;
	
	NSData *icon = nil;
	if (mGrowlImage) {
		icon = [mGrowlImage TIFFRepresentation];
		[mGrowlImage release], mGrowlImage = nil;
	}
	
	BOOL gotSomething = NO;
	NSString *title = [mCurrentSong title];
	if (!title)
		title = @"Unknown Title";
	else
		gotSomething = YES;
	
	NSString *album = [mCurrentSong album];
	if (!album)
		album = @"Unknown Album";
	else
		gotSomething = YES;
	
	NSString *artist = [mCurrentSong artist];
	if (!artist)
		artist = @"Unknown Artist";
	else
		gotSomething = YES;
	
	if (gotSomething) {
		[GrowlApplicationBridge notifyWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Playing: %@", @"Growl Notification Title"), title]
									description:[NSString stringWithFormat:@"%@\n%@", album, artist]
							   notificationName:nGrowlNotificationPlaying
									   iconData:icon
									   priority:0
									   isSticky:NO
								   clickContext:nGrowlNotificationPlaying];	
	}
}

- (void) clientCurrentSongChanged:(NSNotification *)notification {
	[mCurrentSong release];
	mCurrentSong = [[[notification userInfo] objectForKey:dSong] retain];	
	
	[self scheduleUpdate];
	
	if ([[WindowController instance] currentPlayerState] == eStatePlaying) {
		if (![[mCurrentSong uniqueIdentifier] isEqualTo:mLastNotifiedSongIdentifier]) {
			[mGrowlTimer invalidate];
			[mGrowlTimer release], mGrowlTimer = nil;
			[mGrowlImage release], mGrowlImage = nil;
			[mLastNotifiedSongIdentifier release], mLastNotifiedSongIdentifier = nil;
			[self sendGrowlInfo:nil];

			mLastNotifiedSongIdentifier = [[mCurrentSong uniqueIdentifier] copy];
		}
	}
}

- (void) clientConnecting:(NSNotification *)notification {
	// if it takes longer than 0.5 seconds to connect, show that we are trying to connect
	mProgressIndicatorStartTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
																	 target:self
																   selector:@selector(progressIndicatorStartTimerTriggered:)
																   userInfo:nil
																	repeats:NO] retain];
}

- (void) clientConnected:(NSNotification *)notification {
	if (mProgressIndicatorStartTimer != nil) {
		[mProgressIndicatorStartTimer invalidate];
		[mProgressIndicatorStartTimer release];
		mProgressIndicatorStartTimer = nil;
	}
	[mProgressIndicator stopAnimation:self];
	[mProgressLabel setStringValue:@""];
	[self scheduleUpdate];
}

- (void) clientDisconnected:(NSNotification *)notification {
	if (mProgressIndicatorStartTimer != nil) {
		[mProgressIndicatorStartTimer invalidate];
		[mProgressIndicatorStartTimer release];
		mProgressIndicatorStartTimer = nil;
	}
	[mProgressIndicator stopAnimation:self];
	[mProgressLabel setStringValue:[[notification userInfo] objectForKey:dDisconnectReason]];	
	[self scheduleUpdate];
}


- (void) progressIndicatorStartTimerTriggered:(NSTimer *)timer {
	// the timer is released in the connect/disconnect notification
	[mProgressLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Connecting to %@", @"Info Area Status Indicator"), [[[[WindowController instance] preferences] currentProfile] hostname]]];
	[mProgressIndicator startAnimation:self];
}

@end
