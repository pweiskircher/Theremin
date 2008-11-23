/*
 Copyright (C) 2008  Patrik Weiskircher
 
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

#import "SLSqueezeEventServer.h"
#import "SLCLIListenRequest.h"
#import "SLCLIPlayerRequest.h"
#import "SLCLIVolumeRequest.h"

@interface SLSqueezeEventServer (PrivateMethods)
- (void) initialQuery;
- (void) startListeningForReal;
- (void) handleInitialQueryResults:(NSArray *)results forRequest:(SLCLIRequest *)request;
@end

@implementation SLSqueezeEventServer
- (id) initWithServer:(SLServer *)server andPlayer:(SLPlayer *)player andCredentials:(SLCLICredentials *)someCredentials {
	self = [super init];
	if (self != nil) {
		_server = [server retain];
		_player = [player retain];
		_credentials = [someCredentials retain];
	}
	return self;
}

- (void) dealloc
{
	[_conn release];
	[_server release];
	[_player release];
	[_credentials release];
	[super dealloc];
}

- (void) setDelegate:(id)delegate {
	_delegate = delegate;
}

- (void) startListening {
	_conn = [[SLCLIConnection alloc] initWithServer:[_server server] andPort:[_server port] andCredentials:_credentials];
	[_conn setDelegate:self];
	
	[self initialQuery];
}

- (void) initialQuery {
	_inInitialQuery = YES;
	
	[_conn scheduleRequest:[SLCLIVolumeRequest volumeGetRequestForPlayer:_player]];
	[_conn scheduleRequest:[SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:@"playlist index ?"]];
	[_conn scheduleRequest:[SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:@"mode ?"]];
}

- (void) handleInitialQueryResults:(NSArray *)results forRequest:(SLCLIRequest *)request {
	if ([request isKindOfClass:[SLCLIVolumeRequest class]])
		[_delegate eventServer:self receivedNewVolume:[(SLCLIVolumeRequest *)request fetchedVolume]];
	else if ([[results objectAtIndex:1] isEqualToString:@"playlist"])
		[_delegate eventServer:self receivedPlaylistIndexChanged:[[results objectAtIndex:3] intValue]];
	else if ([[results objectAtIndex:1] isEqualToString:@"mode"]) {
		NSString *mode = [results objectAtIndex:2];
		
		SLPlayPauseStatus status = eStopped;
		if ([mode isEqualToString:@"play"])       status = ePlaying;
		else if ([mode isEqualToString:@"pause"]) status = ePaused;
		
		[_delegate eventServer:self receivedPlayPauseStatus:status];
		
		_inInitialQuery = NO;
		[self startListeningForReal];
	}
}

- (void) startListeningForReal {
	[_conn scheduleRequest:[SLCLIListenRequest listenRequest]];
	
	if (_delegate && [_delegate respondsToSelector:@selector(eventServer:startedListeningToPlayer:)]) 
		[_delegate eventServer:self startedListeningToPlayer:_player];
}

- (void) stopListening {
	[_conn release];
	_conn = nil;

	if (_delegate && [_delegate respondsToSelector:@selector(eventServer:stoppedListeningToPlayer:)]) 
		[_delegate eventServer:self stoppedListeningToPlayer:_player];
}

- (void) requestCompleted:(SLCLIRequest *)request {
	if (!_delegate) return;
	
	NSArray *result = [request splittedAndUnescapedResponse];
	
	if ([[result objectAtIndex:0] isEqualToString:@"subscribe"])
		return;
	if ([[result objectAtIndex:0] isEqualToString:[_player playerId]] == NO)
		return;
	
	if (_inInitialQuery) {
		[self handleInitialQueryResults:result forRequest:request];
		return;
	}
	
	if ([[result objectAtIndex:1] isEqualToString:@"pause"]) {
		if ([result count] == 2)
			[_delegate eventServerReceivedPlayPauseToggle:self];
		else
			[_delegate eventServer:self receivedPlayPauseStatus:[[result objectAtIndex:2] isEqualToString:@"0"] ? ePlaying : ePaused];
	} else if ([[result objectAtIndex:1] isEqualToString:@"stop"])
		[_delegate eventServer:self receivedPlayPauseStatus:eStopped];
	else if ([[result objectAtIndex:1] isEqualToString:@"play"])
		[_delegate eventServer:self receivedPlayPauseStatus:ePlaying];
	else if ([[result objectAtIndex:1] isEqualToString:@"playlist"]) {
		if ([result count] <= 2)
			return;
		
		if ([[result objectAtIndex:2] isEqualToString:@"newsong"] && [result count] == 5)
			[_delegate eventServer:self receivedPlaylistIndexChanged:[[result objectAtIndex:4] intValue]];
		else if ([[result objectAtIndex:2] isEqualToString:@"loadtracks"] ||
			     [[result objectAtIndex:2] isEqualToString:@"deletetracks"] ||
			     [[result objectAtIndex:2] isEqualToString:@"move"] ||
				 [[result objectAtIndex:2] isEqualToString:@"addtracks"])
			[_delegate eventServerReceivedPlaylistChanged:self];
		else if ([[result objectAtIndex:2] isEqualToString:@"index"])
			[_delegate eventServer:self receivedPlayPauseStatus:ePlaying];
	} else if ([[result objectAtIndex:1] isEqualToString:@"prefset"]) {
		if ([result count] < 5)
			return;
		
		if ([[result objectAtIndex:3] isEqualToString:@"volume"])
			[_delegate eventServer:self receivedNewVolume:[[result objectAtIndex:4] intValue]];
	}
}

- (void) connectionError {
	[self stopListening];
	[_delegate eventServer:self reportsConnectionError:@"Connection error."];
}

@end
