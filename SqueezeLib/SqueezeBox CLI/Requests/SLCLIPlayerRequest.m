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

#import "SLCLIPlayerRequest.h"


@implementation SLCLIPlayerRequest
+ (id) playerRequestWithPlayer:(SLPlayer *)player andCommand:(NSString *)command {
	return [[[SLCLIPlayerRequest alloc] initWithPlayer:player andCommand:command] autorelease];
}

- (id) initWithPlayer:(SLPlayer *)player andCommand:(NSString *)command {
	self = [super initWithCommand:[NSString stringWithFormat:@"%@ %@", [player playerId], command]];
	if (self != nil) {
		_player = [player retain];
	}
	return self;
}

- (void) dealloc
{
	[_player release];
	[super dealloc];
}


- (void) setPlayerCommand:(NSString *)command {
	[super setCommand:[NSString stringWithFormat:@"%@ %@", [_player playerId], command]];
}

- (SLPlayer *) player {
	return [[_player retain] autorelease];
}
@end
