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

#import "SLCLICurrentPlaylistListRequest.h"

@interface SLCLICurrentPlaylistListRequest (PrivateMethods)
- (BOOL) fetchNextPath;
@end

@implementation SLCLICurrentPlaylistListRequest
+ (id) currentPlaylistListRequestWithPlayer:(SLPlayer *)player {
	return [[[SLCLICurrentPlaylistListRequest alloc] initWithPlayer:player] autorelease];
}

- (id) initWithPlayer:(SLPlayer *)player
{
	self = [super initWithPlayer:player andCommand:@"playlist tracks ?"];
	return self;
}

- (void) dealloc
{
	[_paths release];
	[super dealloc];
}


- (id) cloneRequest {
	return [SLCLICurrentPlaylistListRequest currentPlaylistListRequestWithPlayer:[self player]];
}

- (NSArray *)results {
	return [[_paths retain] autorelease];
}

- (SLCLIRequestFinishedAction) finishedWithResponse:(NSString *)response {
	[super finishedWithResponse:response];
	
	NSString *cmd = [[self splittedAndUnescapedResponse] objectAtIndex:2];
	if ([cmd isEqualToString:@"tracks"]) {
		[_paths release];
		_paths = [[NSMutableArray array] retain];
		
		_currentTrack = 0;
		_tracks = [[[self splittedAndUnescapedResponse] objectAtIndex:3] intValue];
	} else if ([cmd isEqualToString:@"path"]) {
		[_paths addObject:[[self splittedAndUnescapedResponse] objectAtIndex:4]];
	}
	
	
	if ([self fetchNextPath] == YES)
		return eReschedule;
	
	return eFinished;
}

- (BOOL) fetchNextPath {
	if (_currentTrack >= _tracks)
		return NO;
	
	[self setPlayerCommand:[NSString stringWithFormat:@"playlist path %d ?", _currentTrack]];
	_currentTrack++;
	return YES;
}
@end
