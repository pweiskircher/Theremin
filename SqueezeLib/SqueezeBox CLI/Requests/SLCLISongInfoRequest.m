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

#import "SLCLISongInfoRequest.h"
#import "SLTitle.h"

@interface SLCLISongInfoRequest (PrivateMethods)
- (NSString *) commandForPath:(NSString *)path;
@end

@implementation SLCLISongInfoRequest
+ (id) songInfoRequestWithPathList:(NSArray *)pathList {
	return [[[SLCLISongInfoRequest alloc] initWithPathList:pathList] autorelease];
}

- (id) initWithPathList:(NSArray *)pathList {
	self = [super initWithCommand:[self commandForPath:[pathList objectAtIndex:_index]]];
	if (self != nil) {
		_index++;
		_pathList = [pathList retain];
		_songs = [[NSMutableArray array] retain];
	}
	return self;
}

- (void) dealloc
{
	[_currentPartialResult release];
	[_pathList release];
	[_songs release];
	[super dealloc];
}


- (NSString *) commandForPath:(NSString *)path {
	return [NSString stringWithFormat:@"songinfo 0 20 url:%@ tags:dtJalsge", path];
}

- (NSArray *) results {
	return [[_songs retain] autorelease];
}

- (SLCLIRequestFinishedAction) finishedWithResponse:(NSString *)response {
	_currentPartialIndex++;
	
	[super finishedWithResponse:response];
	
	NSArray *infos = [[self splittedAndUnescapedResponse] subarrayWithRange:NSMakeRange(5, [[self splittedAndUnescapedResponse] count] - 5)];
	
	[_currentPartialResult release];
	_currentPartialResult = [[[SLTitle titlesWithSongInfoResponse:infos] objectAtIndex:0] retain];
	
	[_songs addObject:_currentPartialResult];
	
	if (_index >= [_pathList count])
		return eFinished;
	
	[super setCommand:[self commandForPath:[_pathList objectAtIndex:_index]]];
	 _index++;
	 
	return eReschedule;
}

- (id) currentPartialResult {
	return [[_currentPartialResult retain] autorelease];
}

- (int) index {
	return _currentPartialIndex - 1;
}

- (BOOL) canReportPartial {
	return YES;
}
@end
