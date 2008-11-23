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

#import "SLCLITitleListRequest.h"
#import "SLTitle.h"

@interface SLCLITitleListRequest (PrivateMethods)
- (NSString *) commandForOffset:(int)offset andAlbum:(SLAlbum *)album;
@end

@implementation SLCLITitleListRequest
+ (id) titleListRequestWithOffset:(int)offset andAlbum:(SLAlbum *)album {
	return [[[SLCLITitleListRequest alloc] initWithOffset:offset andAlbum:album] autorelease];
}

+ (id) titleListRequestWithOffset:(int)offset {
	return [[[SLCLITitleListRequest alloc] initWithOffset:offset andAlbum:nil] autorelease];
}

- (id) initWithOffset:(int)offset andAlbum:(SLAlbum *)album {
	self = [super init];
	if (self != nil) {
		_album = [album retain];
		[super setCommand:[self commandForOffset:offset andAlbum:album]];
	}
	return self;
}

- (void) dealloc
{
	[_album release];
	[super dealloc];
}


- (id) cloneRequest {
	return [SLCLITitleListRequest titleListRequestWithOffset:0 andAlbum:_album];
}

- (NSString *) commandForOffset:(int)offset andAlbum:(SLAlbum *)album {
	NSMutableString *cmd = [NSMutableString stringWithFormat:@"titles %d 4000 tags:dtJalsge ", offset];
	if (album != nil)
		[cmd appendFormat:@"album_id:%d", [album albumId]];
	return cmd;
}

- (NSArray *) currentResultList {
	NSMutableArray *array = [NSMutableArray arrayWithArray:[super splittedAndUnescapedResponse]];
	// remove titles 0 80 album_d: tags:dtJ
	[array removeObjectsInRange:NSMakeRange(0, 4)];
	
	return [SLTitle titlesWithSongInfoResponse:array];
}

- (SLAlbum *) album {
	return [[_album retain] autorelease];
}

- (void) setOffset:(int)offset {
	[super setCommand:[self commandForOffset:offset andAlbum:_album]];
}
@end
