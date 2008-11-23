//
//  MpdMusicServerClient.h
//  Theremin
//
//  Created by Patrik Weiskircher on 07.02.07.
//  Copyright 2007 Patrik Weiskircher. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MusicServerClient.h"
#import "libmpd.h"

@interface MpdMusicServerClient : MusicServerClient <MusicServerClientInterface> {
	MpdObj *mConnection;
	NSTimer *mMpdTimer;
	int mCachedSeekValue;
	
	BOOL mSetPasswordCalled;
	NSString *mPassword;	
	
	int mForcedStatusUpdates;
}
- (id) init;

- (int) currentSongPosition;

- (void) mpdTimerTriggered:(NSTimer *)timer;

- (void) resetDelayForStatusUpdateTimer:(NSTimeInterval)aInterval;

- (void) callbackStatusChanged:(int)what;
- (void) callbackErrorOnIdentifier:(int)identifier withMessage:(char *)message;
- (void) callbackConnectionChanged:(int)connect;

- (void) setIncludeInNextStatus:(int)what;
@end
