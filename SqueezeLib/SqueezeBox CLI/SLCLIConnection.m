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

#import "SLCLIConnection.h"
#import "SLCLIRequest.h"
#import "SLCLILoginRequest.h"

@interface SLCLIConnection (PrivateMethods)
- (void) reportResult:(NSString *)escapedResult;
- (void) trySplittingDataIntoResponsesAndReportThem;
- (void) sendRequestAndRecord:(SLCLIRequest *)request;

- (void) connect;
- (void) disconnect;
- (BOOL) isConnected;

- (void) handleError:(NSString *)msg;
@end

@implementation SLCLIConnection

- (id) initWithServer:(NSString *)server andPort:(int)port andCredentials:(SLCLICredentials *)someCredentials {
	self = [super init];
	if (self != nil) {
		_server = [server copy];
		_port = port;
		_sentRequests = [[NSMutableArray array] retain];
		_credentials = [someCredentials retain];
	}
	return self;
}

- (void) dealloc
{
	[self disconnect];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_data release];
	[_scheduledRequests release];
	[_sentRequests release];
	
	[_server release];
	[_connectTimer release];
	[_credentials release];
	
	[super dealloc];
}

- (void) connect {
	NSHost *host = [NSHost hostWithName:_server];
	[NSStream getStreamsToHost:host port:_port inputStream:&_input outputStream:&_output];
	if (_input == nil || _output == nil) {
		[self handleError:@"Couldn't connect to server (getStreamsToHost returns nil streams.)"];
		return;
	}
	
	[_input retain];
	[_output retain];
	
	[_input setDelegate:self];
	[_input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

	[_output setDelegate:self];
	[_output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	
	[_input open];
	[_output open];
	
	_connectTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(connectTimerFires:) userInfo:nil repeats:NO] retain];
	
	if (_credentials != nil)
		[self scheduleRequest:[SLCLILoginRequest loginRequestWithCredentials:_credentials]];
}

- (void) disconnect {
	if (_input && _output) {
		[_input close];
		[_output close];

		[_input removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_output removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];		
		
		[_input release];
		[_output release];
	}
	
	_input = nil;
	_output = nil;
}

- (BOOL) isConnected {
	return _input != nil && _output != nil;
}

- (void) connectTimerFires:(NSTimer *)timer {
	[_connectTimer invalidate];
	[_connectTimer release];
	_connectTimer = nil;
	
	[self handleError:@"Couldn't open connection in time."];
}


- (void) scheduleRequest:(SLCLIRequest *)request {
	if (![self isConnected])
		[self connect];

	if ([_output streamStatus] != NSStreamStatusOpening) {
		[self sendRequestAndRecord:request];
	} else {
		if (!_scheduledRequests)
			_scheduledRequests = [[NSMutableArray array] retain];
		[_scheduledRequests addObject:request];
	}
}

- (void) reportResult:(NSString *)escapedResult {
	if ([_sentRequests count] == 0)
		return;
	
	SLCLIRequest *request = [_sentRequests objectAtIndex:0];
	
	SLCLIRequestFinishedAction action = [request finishedWithResponse:escapedResult];

	if (_delegate && [request canReportPartial])
		if ([_delegate respondsToSelector:@selector(request:partialResult:)])
			[_delegate request:request partialResult:[request currentPartialResult]];
	
	if (_delegate && (action == eFinished || action == eKeepAlive))
		[_delegate requestCompleted:request];
	
	if (action == eReschedule)
		[self sendRequestAndRecord:request];
	else if (action == eKeepAlive)
		return;
	
	[_sentRequests removeObjectAtIndex:0];
	
	if ([_sentRequests count] == 0)
		[self disconnect];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
	switch (streamEvent) {
		case NSStreamEventOpenCompleted:
			[_connectTimer invalidate];
			[_connectTimer release];
			_connectTimer = nil;
			return;
			
		case NSStreamEventEndEncountered:
			[self handleError:@"End encountered on stream ... disconnecting."];
			return;
			
		case NSStreamEventErrorOccurred:
			[self handleError:@"Error on stream ... disconnecting."];
			return;
			
		case NSStreamEventNone:
		case NSStreamEventHasBytesAvailable:
		case NSStreamEventHasSpaceAvailable:
			break;
	}
	
	if (theStream == _input) {
		if (streamEvent != NSStreamEventHasBytesAvailable) {
			[self handleError:[NSString stringWithFormat:@"_input streamEvent is %d instead of %d.", streamEvent, NSStreamEventHasSpaceAvailable]];
			return;
		}
			
		if (!_data)
			_data = [[NSMutableString string] retain];
		
		uint8_t buf[1024];
		unsigned int len = 0;
		len = [_input read:buf maxLength:sizeof(buf)];
		if (len > 0) {
			NSString *new = [[NSString alloc] initWithBytes:buf length:len encoding:NSUTF8StringEncoding];
			if (new == nil) {
				[self handleError:[NSString stringWithFormat:@"returned buffer is nil after decoding with NSUTF8StringEncoding"]];
				return;
			}
			
			//NSLog(@"%@", new);
			
			[_data appendString:new];
			[new release];
		}
		else {
			[self handleError:[NSString stringWithFormat:@"_input stream returned %d for read.", len]];
			return;
		}

		[self trySplittingDataIntoResponsesAndReportThem];
	} else if (theStream == _output) {
		if (streamEvent != NSStreamEventHasSpaceAvailable) {
			[self handleError:[NSString stringWithFormat:@"_output streamEvent is %d instead of %d.", streamEvent, NSStreamEventHasSpaceAvailable]];
			return;
		}

		if (_scheduledRequests != nil) {
			for (int i = 0; i < [_scheduledRequests count]; i++) {
				SLCLIRequest *r = [_scheduledRequests objectAtIndex:i];
				[self sendRequestAndRecord:r];
			}
			[_scheduledRequests release];
			_scheduledRequests = nil;
		}
	}
}

- (void) handleError:(NSString *)msg {
	NSLog(msg);
	[self disconnect];
	
	if (_delegate) [_delegate connectionError];
}

- (void) trySplittingDataIntoResponsesAndReportThem {
	NSArray *components = [_data componentsSeparatedByString:@"\n"];
	if ([components count] > 0) {
		for (int i = 0; i < [components count] - 1; i++) {
			[self reportResult:[components objectAtIndex:i]];
		}
		[_data release];
		_data = [[NSMutableString stringWithString:[components lastObject]] retain];
	}
}

- (void) sendRequestAndRecord:(SLCLIRequest *)request {
	[_output write:(const uint8_t *)[[request escapedCommand] UTF8String] maxLength:strlen([[request escapedCommand] UTF8String])];
	[_sentRequests addObject:request];
}

- (void) setDelegate:(id)aDelegate {
	_delegate = aDelegate;
}

- (id) delegate {
	return _delegate;
}

@end

