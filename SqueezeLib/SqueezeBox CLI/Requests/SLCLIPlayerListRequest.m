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

#import "SLCLIPlayerListRequest.h"
#import "SLPlayer.h"

@implementation SLCLIPlayerListRequest
+ (id) playerListRequest {
	return [[[SLCLIPlayerListRequest alloc] init] autorelease];
}
			  
- (id) init
{
	return [super initWithCommand:@"players 0 20"];
}

- (id) cloneRequest {
	return [SLCLIPlayerListRequest playerListRequest];
}

- (NSArray *) results {
	NSMutableArray *array = [NSMutableArray arrayWithArray:[super splittedAndUnescapedResponse]];
	if ([array count] < 4)
		return nil;
	// remove players 0 20 count%3A1
	[array removeObjectsInRange:NSMakeRange(0, 4)];
	
	NSMutableArray *players = [NSMutableArray array];
	NSString *playerId = nil, *name = nil;
	for (int i = 0; i < [array count]; i++) {
		NSString *s = [array objectAtIndex:i];
		
		if ([[s cliKey] isEqualToString:@"playerid"])
			playerId = [s cliValue];
		else if ([[s cliKey] isEqualToString:@"name"])
			name = [s cliValue];
		
		if (playerId != nil && name != nil) {
			[players addObject:[[[SLPlayer alloc] initPlayerWithId:playerId andName:name] autorelease]];
			playerId = nil;
			name = nil;
		}
	}
	
	return [NSArray arrayWithArray:players];
}

@end
