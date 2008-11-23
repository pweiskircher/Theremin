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

#import "CoverArtView.h"
#import "AWSController.h"

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
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(coverArtEnabledChanged:)
													 name:nCoverArtEnabledChanged
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fetchedImageForGrowl:)
													 name:nFetchedSmallImageForSong
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
	
	if ([[[WindowController instance] preferences] askedAboutCoverArt] == NO) {
		[[[WindowController instance] preferences] setAskedAboutCoverArt];
		
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Display Album Artwork.", @"First startup dialog asking about enabling of cover art: Title")
										 defaultButton:NSLocalizedString(@"Enable Album Artwork", @"First startup dialog asking about enabling of cover art: Default Button")
									   alternateButton:NSLocalizedString(@"Disable Album Artwork", @"First startup dialog asking about enabling of cover art: Alternate Button")
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"Theremin can automatically show album artwork. Theremin needs to submit information about the currently playing album to Amazon to show the album artwork.", @"First startup dialog asking about enabling of cover art: Informative Text")];
		int result = [alert runModal];
		if (result == NSAlertDefaultReturn) {
			[[[WindowController instance] preferences] setCoverArtEnabled:YES];
		} else if (result == NSAlertAlternateReturn) {
			[[[WindowController instance] preferences] setCoverArtEnabled:NO];
		}
	}
	
	if ([[[WindowController instance] preferences] coverArtEnabled] == NO)
		[self enableCoverArt:NO];
	
	[mCoverArtView setIsClickable:YES];
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

- (void) coverArtEnabledChanged:(NSNotification *)notification {
	if ([[[WindowController instance] preferences] coverArtEnabled] == NO)
		[self enableCoverArt:NO];
	else {
		[self enableCoverArt:YES];
		[self scheduleUpdate];
	}
}

- (void) enableCoverArt:(BOOL)aValue {
	if (aValue == NO) {
		[mCoverArtView setHidden:YES];
		
		NSPoint point = [mTitle frame].origin;
		point.x = [mCoverArtView frame].origin.x;
		[mTitle setFrameOrigin:point];
		
		point = [mArtist frame].origin;
		point.x = [mCoverArtView frame].origin.x;
		[mArtist setFrameOrigin:point];
		
		point = [mProgressLabel frame].origin;
		point.x = [mCoverArtView frame].origin.x;
		[mProgressLabel setFrameOrigin:point];
	} else {
		[mCoverArtView setHidden:NO];
		
		[mTitle setFrameOrigin:mOriginalOriginTitle];
		[mArtist setFrameOrigin:mOriginalOriginArtist];
		[mProgressLabel setFrameOrigin:mOriginalOriginProgressLabel];
		
		[[mTitle window] display];
	}
	
	[mTitle setNeedsDisplay];
	[mArtist setNeedsDisplay];
	[mProgressLabel setNeedsDisplay];
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
			[self updateSeekBarWithSongLength:0 andElapsedTime:0];
			
			[mCoverArtView showCoverForSong:nil];
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
			
			[mCoverArtView showCoverForSong:mCurrentSong];
		} else {
			[mTitle setStringValue:@""];
			[mArtist setStringValue:@""];
			[mAlbum setStringValue:@""];
			
			[mCoverArtView showCoverForSong:nil];
		}
	} else {
		[mTitle setStringValue:NSLocalizedString(@"Not connected.", @"Info Area Status Text")];
		[mArtist setStringValue:@""];
		[mAlbum setStringValue:@""];
		[self updateSeekBarWithSongLength:0 andElapsedTime:0];
		
		[mCoverArtView showCoverForSong:nil];
	}
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
	mCurrentSong = [[[notification userInfo] objectForKey:@"song"] retain];	
	
	[self scheduleUpdate];
	
	if ([[WindowController instance] currentPlayerState] == eStatePlaying) {
		if (![[mCurrentSong uniqueIdentifier] isEqualTo:mLastNotifiedSongIdentifier]) {
			[mGrowlTimer invalidate];
			[mGrowlTimer release], mGrowlTimer = nil;
			[mGrowlImage release], mGrowlImage = nil;
			[mLastNotifiedSongIdentifier release], mLastNotifiedSongIdentifier = nil;
		
			if ([[[WindowController instance] preferences] coverArtEnabled]) {
				[[AWSController defaultController] fetchSmallImageForSong:mCurrentSong];
		
				mGrowlTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendGrowlInfo:)
																userInfo:nil repeats:NO] retain];
			} else {
				[self sendGrowlInfo:nil];
			}

			mLastNotifiedSongIdentifier = [[mCurrentSong uniqueIdentifier] copy];
		}
	}
}

- (void) fetchedImageForGrowl:(NSNotification *)notification {
	// we are too late
	if (mGrowlTimer == nil) return;
	
	if ([[[[notification userInfo] objectForKey:nAWSSongEntry] albumIdentifier] isEqualTo:[mCurrentSong albumIdentifier]]) {
		[mGrowlImage release], mGrowlImage = [[[notification userInfo] objectForKey:nAWSImageEntry] retain];
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
	[mProgressLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Connecting to %@", @"Info Area Status Indicator"), [[[WindowController instance] preferences] mpdServer]]];
	[mProgressIndicator startAnimation:self];
}

@end
