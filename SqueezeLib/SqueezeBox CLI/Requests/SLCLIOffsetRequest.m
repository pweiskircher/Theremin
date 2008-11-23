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

#import "SLCLIOffsetRequest.h"


@implementation SLCLIOffsetRequest
- (void) dealloc
{
	[_results release];
	[super dealloc];
}

- (id) cloneRequest {
	return [super cloneRequest];
}

- (SLCLIRequestFinishedAction) finishedWithResponse:(NSString *)response {
	[super finishedWithResponse:response];
	
	if (!_results)
		_results = [[NSMutableArray array] retain];
	
	[_results addObjectsFromArray:[self currentResultList]];
	
	if ([_results count] == [self count]) {
		return eFinished;
	} else {
		[self setOffset:[_results count]];
		return eReschedule;
	}
}

- (NSArray *) results {
	return [[_results retain] autorelease];
}

- (void) setOffset:(int)offset {
}

- (NSArray *) currentResultList {
	return nil;
}
@end
