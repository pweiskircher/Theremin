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

#import "SLCLIRequest.h"
#import "NSString+CLI.h"

@implementation SLCLIRequest
+ (id) cliRequestWithCommand:(NSString *)cmd {
	return [[[SLCLIRequest alloc] initWithCommand:cmd] autorelease];
}

- (id) initWithCommand:(NSString *)cmd {
	self = [super init];
	if (self != nil) {
		[self setCommand:cmd];
	}
	return self;
}

- (void) dealloc
{
	[_userInfo release];
	[_command release];
	[_response release];
	[super dealloc];
}

- (id) cloneRequest {
	return [SLCLIRequest cliRequestWithCommand:_command];
}

- (NSString *) command {
	return [[_command retain] autorelease];
}

- (void) setCommand:(NSString *)aCommand {
	[_command release];
	_command = [aCommand retain];
}

- (NSString *) response {
	return [[_response retain] autorelease];
}

- (id) userInfo {
	return [[_userInfo retain] autorelease];
}

- (void) setUserInfo:(id)aUserInfo {
	[_userInfo release];
	_userInfo = [aUserInfo retain];
}

- (NSString *) escapedCommand {
	// TODO: leaks?
	NSString *escaped, *ptr;
	escaped = ptr = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[self command], (CFStringRef)@" ", NULL, kCFStringEncodingUTF8);
	if ([escaped characterAtIndex:[escaped length]-1] != '\n')
		escaped = [escaped stringByAppendingString:@"\n"];
	[ptr release];
	return escaped;
}


- (SLCLIRequestFinishedAction) finishedWithResponse:(NSString *)response {
	[_response release];
	_response = [response retain];
	return eFinished;
}

- (NSArray *) splittedAndUnescapedResponse {
	NSArray *splitted = [[self response] componentsSeparatedByString:@" "];
	NSMutableArray *result = [NSMutableArray array];
	for (int i = 0; i < [splitted count]; i++) {
		NSString *s = [splitted objectAtIndex:i];
		[result addObject:[s stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
	return [NSArray arrayWithArray:result];
}

- (NSArray *) results {
	return nil;
}

- (BOOL) isEqual:(id)object {
	if ([object isKindOfClass:[SLCLIRequest class]])
		return [self isEqualToCliRequest:object];
	return NO;
}

- (BOOL) isEqualToCliRequest:(SLCLIRequest *)request {
	if ([[request command] isEqualToString:[self command]])
		return YES;
	return NO;
}

- (int) count {
	NSArray *splittedResponse = [self splittedAndUnescapedResponse];
	for (int i = 0; i < [splittedResponse count]; i++) {
		NSString *s = [splittedResponse objectAtIndex:i];
		if ([[s cliKey] isEqualToString:@"count"])
			return [[s cliValue] intValue];
	}
	return -1;
}

- (id) currentPartialResult {
	return nil;
}

- (BOOL) canReportPartial {
	return NO;
}
@end
