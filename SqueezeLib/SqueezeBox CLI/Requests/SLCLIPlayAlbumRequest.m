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

#import "SLCLIPlayAlbumRequest.h"

@interface SLCLIPlayAlbumRequest (PrivateMethods)
- (NSString *)_command;
@end

@implementation SLCLIPlayAlbumRequest
+ (id) playAlbumRequestWithPlayer:(SLPlayer *)player andAlbum:(SLAlbum *)album andTitleIndex:(int)titleIndex {
	return [[[SLCLIPlayAlbumRequest alloc] initWithPlayer:player andAlbum:album andTitleIndex:titleIndex] autorelease];
}

- (id) initWithPlayer:(SLPlayer *)player andAlbum:(SLAlbum *)album andTitleIndex:(int)titleIndex {
	self = [super initWithPlayer:player andCommand:@""];
	if (self != nil) {
		_album = [album retain];
		_titleIndex = titleIndex;
		
		[self setPlayerCommand:[self _command]];
	}
	return self;
}

- (void) dealloc
{
	[_album release];
	[super dealloc];
}

- (id) cloneRequest {
	return [[[SLCLIPlayAlbumRequest alloc] initWithPlayer:[self player] andAlbum:_album andTitleIndex:_titleIndex] autorelease];
}

- (NSString *)_command {
	return [NSString stringWithFormat:@"playlist loadtracks album.id=%d", [_album albumId]];
}

- (SLCLIRequestFinishedAction) finishedWithResponse:(NSString *)response {
	[super finishedWithResponse:response];

	NSString *cmd = [[self splittedAndUnescapedResponse] objectAtIndex:2];
	if ([cmd isEqualToString:@"loadtracks"]) {
		[self setPlayerCommand:[NSString stringWithFormat:@"playlist index %d", _titleIndex]];
		return eReschedule;
	}
	
	return eFinished;
}

@end
