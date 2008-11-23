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

#import "SLCLIPlayerPlaylistControlTrackIdRequest.h"

@interface SLCLIPlayerPlaylistControlTrackIdRequest (PrivateMethods)
- (NSString *) _command;
@end

@implementation SLCLIPlayerPlaylistControlTrackIdRequest
+ (id) playerPlaylistControlTrackIdRequestWithPlayer:(SLPlayer *)player andMode:(SLCliPlayerPlaylistControlMode)mode andTrackIds:(NSIndexSet *)trackIds {
	return [[[SLCLIPlayerPlaylistControlTrackIdRequest alloc] initWithPlayer:player andMode:mode andTrackIds:trackIds] autorelease];
}

- (id) initWithPlayer:(SLPlayer *)player andMode:(SLCliPlayerPlaylistControlMode)mode andTrackIds:(NSIndexSet *)trackIds {
	self = [super initWithPlayer:player andCommand:@""];
	if (self != nil) {
		_mode = mode;
		_trackIds = [trackIds retain];
		[self setPlayerCommand:[self _command]];
	}
	return self;
}

- (void) dealloc
{
	[_trackIds release];
	[super dealloc];
}

- (NSString *) _command {
	NSMutableString *cmd = [NSMutableString stringWithFormat:@"playlistcontrol cmd:%s track_id:", _mode == SLCliPlayerPlaylistControlModeAdd ? "add" : "delete"];
	
	int trackId = [_trackIds firstIndex];
	BOOL first = YES;
	do {
		if (!first) [cmd appendFormat:@","];
		[cmd appendFormat:@"%d", trackId];		
		
		first = NO;
	} while ( (trackId = [_trackIds indexGreaterThanIndex:trackId]) != NSNotFound);
	
	return cmd;
}

- (id) cloneRequest {
	return [[[SLCLIPlayerPlaylistControlTrackIdRequest alloc] initWithPlayer:[self player] andMode:_mode andTrackIds:_trackIds] autorelease];
}

@end
