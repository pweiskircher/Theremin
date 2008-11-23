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

#import "NSString+CLI.h"

typedef enum {
	eFinished,
	eReschedule,
	eKeepAlive
} SLCLIRequestFinishedAction;

typedef enum {
	eCLIRequestModeGet,
	eCLIRequestModeSet
} SLCLIRequestMode;

@interface SLCLIRequest : NSObject {
	NSString *_command;
	NSString *_response;
	
	id _userInfo;
}
+ (id) cliRequestWithCommand:(NSString *)command;
- (id) initWithCommand:(NSString *)command;

#pragma mark -
#pragma mark Properties

- (NSString *) command;
- (void) setCommand:(NSString *)aCommand;

- (NSString *) escapedCommand;
- (NSString *) response;
- (NSArray *) splittedAndUnescapedResponse;

- (id) userInfo;
- (void) setUserInfo:(id)aUserInfo;

- (int) count;

#pragma mark -

- (id) cloneRequest;
- (SLCLIRequestFinishedAction) finishedWithResponse:(NSString *)response;
- (BOOL) isEqual:(id)object;
- (BOOL) isEqualToCliRequest:(SLCLIRequest *)request;
- (NSArray *) results;

- (id) currentPartialResult;
- (BOOL) canReportPartial;

@end
