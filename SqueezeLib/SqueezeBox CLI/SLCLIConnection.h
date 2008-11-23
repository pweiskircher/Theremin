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

#if !defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE 
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

@class SLCLIRequest, SLCLICredentials;

@protocol CLIConnectionDelegate
- (void) requestCompleted:(SLCLIRequest *)request;
- (void) request:(SLCLIRequest *)aRequest partialResult:(id)result;
- (void) connectionError;
@end

@interface SLCLIConnection : NSObject {
	NSString *_server;
	int _port;
	
	NSInputStream *_input;
	NSOutputStream *_output;
	
	id _delegate;
	
	NSTimer *_connectTimer;
	
	NSMutableString *_data;
	NSMutableArray *_scheduledRequests;
	NSMutableArray *_sentRequests;
	
	SLCLICredentials *_credentials;
}
- (id) initWithServer:(NSString *)server andPort:(int)port andCredentials:(SLCLICredentials *)someCredentials;

- (void) setDelegate:(id)aDelegate;
- (id) delegate;

- (void) scheduleRequest:(SLCLIRequest *)request;
@end
