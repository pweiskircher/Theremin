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
#import "LastFmCoverArtDataSource.h"
#import "CoverArtAsker.h"

@interface InfoAreaController (CoverArt)
- (void) enableCoverArt:(BOOL)enabled;
@end


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
		
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																  forKeyPath:@"values.coverArtFetchingEnabled" 
																	 options:NSKeyValueObservingOptionNew 
																	 context:NULL];   
		
		_growlMessenger = [[GrowlMessenger alloc] initWithDelegate:self];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_growlMessenger release];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib {
	_originTitle = [mTitle frame].origin;
	_originArtist = [mArtist frame].origin;
	_originProgressLabel = [mProgressLabel frame].origin;
	
	[_coverArtImageView setFallbackImage:[NSImage imageNamed:@"FallbackCover"]];
	[_coverArtImageView setRequestImageSize:CoverArtSizeSmall];
	
	if ([[PreferencesController sharedInstance] askedAboutCoverArt] == NO) { 
		[[PreferencesController sharedInstance] setAskedAboutCoverArt]; 
		
		CoverArtAsker *asker = [[[CoverArtAsker alloc] init] autorelease];
		[asker ask];
	}
	
	[self enableCoverArt:[[PreferencesController sharedInstance] fetchingOfCoverArtEnabled]];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context { 
	if ([keyPath isEqualToString:@"values.coverArtFetchingEnabled"]) { 
		[self enableCoverArt:[[PreferencesController sharedInstance] fetchingOfCoverArtEnabled]];
	} 
} 

- (void) enableCoverArt:(BOOL)enabled {
	if (enabled) {
		[_coverArtImageView setHidden:NO]; 
		[_coverArtImageView setDataSourceClass:[LastFmCoverArtDataSource class]];
		
		[mTitle setFrameOrigin:_originTitle]; 
		[mArtist setFrameOrigin:_originArtist]; 
		[mProgressLabel setFrameOrigin:_originProgressLabel]; 
			 	                 
		[[mTitle window] display];
		
	} else {
		[_coverArtImageView setHidden:YES]; 
		[_coverArtImageView setDataSourceClass:nil];

		NSPoint point = [mTitle frame].origin; 
		point.x = [_coverArtImageView frame].origin.x; 
		[mTitle setFrameOrigin:point]; 
		                 
		point = [mArtist frame].origin; 
		point.x = [_coverArtImageView frame].origin.x; 
		[mArtist setFrameOrigin:point]; 
			 	                 
		point = [mProgressLabel frame].origin; 
		point.x = [_coverArtImageView frame].origin.x; 
		[mProgressLabel setFrameOrigin:point]; 
	}
	
	[mTitle setNeedsDisplay]; 
	[mArtist setNeedsDisplay]; 
	[mProgressLabel setNeedsDisplay];
}


- (void) growlMessengerNotificationWasClicked:(GrowlMessenger *)aGrowlMessenger {
	[NSApp activateIgnoringOtherApps:YES];
	[[WindowController instance] showPlayerWindow:self];
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
	
	NSString *title = @"";
	NSString *artist = @"";
	NSString *album = @"";
	
	if ([[wc musicClient] isConnected] == YES) {
		if ([wc currentPlayerState] == eStateStopped) {
			title = NSLocalizedString(@"Not playing.", @"Info Area Status Text");
			[mLastNotifiedSongIdentifier release], mLastNotifiedSongIdentifier = nil;

			[self updateSeekBarWithTotalTime:0];
			[self updateSeekBarWithElapsedTime:0];			
		} else if ([mCurrentSong valid]) {
			if ([mCurrentSong title] == nil || [[mCurrentSong title] length] == 0) {
				if ([mCurrentSong file] && [[mCurrentSong file] length])
					title = [[mCurrentSong file] lastPathComponent];
			} else {
				title = [mCurrentSong title];
			}
			
			if ([mCurrentSong artist])
				artist = [mCurrentSong artist];
			
			if ([mCurrentSong album])
				album = [mCurrentSong album];
		}
		
		[_coverArtImageView updateWithSong:mCurrentSong];
	} else {
		title = NSLocalizedString(@"Not connected.", @"Info Area Status Text");

		[self updateSeekBarWithTotalTime:0];
		[self updateSeekBarWithElapsedTime:0];
		
		[_coverArtImageView clear];
	}
	
	[mTitle setStringValue:title];
	[mAlbum setStringValue:album];
	[mArtist setStringValue:artist];
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

- (void) clientCurrentSongChanged:(NSNotification *)notification {
	[mCurrentSong release];
	mCurrentSong = [[[notification userInfo] objectForKey:dSong] retain];	
	
	[self scheduleUpdate];
	
	if ([[WindowController instance] currentPlayerState] == eStatePlaying) {
		[_growlMessenger currentSongChanged:mCurrentSong];
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
	[mProgressLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Connecting to %@", @"Info Area Status Indicator"), [[[PreferencesController sharedInstance] currentProfile] hostname]]];
	[mProgressIndicator startAnimation:self];
}

@end
