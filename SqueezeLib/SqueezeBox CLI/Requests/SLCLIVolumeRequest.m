//
//  SLCLIVolumeRequest.m
//  SqueezeLib
//
//  Created by Patrik Weiskircher on 12.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SLCLIVolumeRequest.h"

@interface SLCLIVolumeRequest (PrivateMethods)
- (NSString *) _command;
@end

@implementation SLCLIVolumeRequest
+ (id) volumeGetRequestForPlayer:(SLPlayer *)aPlayer {
	return [[[SLCLIVolumeRequest alloc] initWithPlayer:aPlayer andMode:eCLIRequestModeGet andVolume:0] autorelease];
}

+ (id) volumeSetRequestForPlayer:(SLPlayer *)aPlayer andVolume:(int)aVolume {
	return [[[SLCLIVolumeRequest alloc] initWithPlayer:aPlayer andMode:eCLIRequestModeSet andVolume:aVolume] autorelease];
}

- (id) initWithPlayer:(SLPlayer *)aPlayer andMode:(SLCLIRequestMode)aMode andVolume:(int)aVolume {
	self = [super initWithPlayer:aPlayer andCommand:@""];
	if (self != nil) {
		_mode = aMode;
		_volume = aVolume;
		
		[self setPlayerCommand:[self _command]];
	}
	return self;
}

- (NSString *) _command {
	NSMutableString *cmd = [NSMutableString stringWithString:@"mixer volume"];
	
	switch (_mode) {
		case eCLIRequestModeGet:
			[cmd appendString:@" ?"];
			break;
		case eCLIRequestModeSet:
			[cmd appendFormat:@" %d", _volume];
			break;
	}
	
	return cmd;
}

- (id) cloneRequest {
	return [[[SLCLIVolumeRequest alloc] initWithPlayer:[self player] andMode:_mode andVolume:_volume] autorelease];
}

- (SLCLIRequestFinishedAction) finishedWithResponse:(NSString *)response {
	[super finishedWithResponse:response];
	
	if (_mode != eCLIRequestModeGet)
		return eFinished;
	
	NSArray *splittedResponse = [self splittedAndUnescapedResponse];
	if ([splittedResponse count] < 4) [NSException raise:NSInternalInconsistencyException format:@"Volume response is too short."];
	
	_result = [[splittedResponse objectAtIndex:3] intValue];
	return eFinished;
}

- (int) fetchedVolume {
	return _result;
}
@end
