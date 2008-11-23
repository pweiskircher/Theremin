//
//  SLCLIVolumeRequest.m
//  SqueezeLib
//
//  Created by Patrik Weiskircher on 12.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SLCLICurrentTitleTimeRequest.h"

@interface SLCLICurrentTitleTimeRequest (PrivateMethods)
- (NSString *) _command;
@end

@implementation SLCLICurrentTitleTimeRequest

+ (id) timeGetRequestForPlayer:(SLPlayer *)aPlayer {
	return [[[SLCLICurrentTitleTimeRequest alloc] initWithPlayer:aPlayer andMode:eCLIRequestModeGet andTime:0] autorelease];
}

+ (id) timeSetRequestForPlayer:(SLPlayer *)aPlayer andTime:(int)aTime {
	return [[[SLCLICurrentTitleTimeRequest alloc] initWithPlayer:aPlayer andMode:eCLIRequestModeSet andTime:aTime] autorelease];
}

- (id) initWithPlayer:(SLPlayer *)aPlayer andMode:(SLCLIRequestMode)aMode andTime:(int)aTime  {
	self = [super initWithPlayer:aPlayer andCommand:@""];
	if (self != nil) {
		_mode = aMode;
		_time = aTime;
		
		[self setPlayerCommand:[self _command]];
	}
	return self;
}

- (NSString *) _command {
	NSMutableString *cmd = [NSMutableString stringWithString:@"time "];
	
	switch (_mode) {
		case eCLIRequestModeGet:
			[cmd appendString:@" ?"];
			break;
		case eCLIRequestModeSet:
			[cmd appendFormat:@" %d", _time];
			break;
	}
	
	return cmd;
}

- (id) cloneRequest {
	return [[[SLCLICurrentTitleTimeRequest alloc] initWithPlayer:[self player] andMode:_mode andTime:_time] autorelease];
}

- (SLCLIRequestFinishedAction) finishedWithResponse:(NSString *)response {
	[super finishedWithResponse:response];
	
	if (_mode != eCLIRequestModeGet)
		return eFinished;
	
	NSArray *splittedResponse = [self splittedAndUnescapedResponse];
	if ([splittedResponse count] < 3) [NSException raise:NSInternalInconsistencyException format:@"time response is too short."];
	
	_result = [[splittedResponse objectAtIndex:2] intValue];
	return eFinished;
}

- (int) fetchedTime {
	return _result;
}

- (SLCLIRequestMode) mode {
	return _mode;
}
@end
