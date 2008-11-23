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

#import "SLCLIAlbumListRequest.h"
#import "SLAlbum.h"
#import "SLArtist.h"

@interface SLCLIAlbumListRequest (PrivateMethods)
- (NSString *) commandForOffset:(int)offset andArtist:(SLArtist *)artist;
@end

@implementation SLCLIAlbumListRequest
+ (id) albumListRequestWithOffset:(int)offset andArtist:(SLArtist *)artist {
	return [[[SLCLIAlbumListRequest alloc] initWithOffset:offset andArtist:artist] autorelease];
}

- (id) initWithOffset:(int)offset andArtist:(SLArtist *)artist {
	self = [super init];
	if (self != nil) {
		_artist = [artist retain];
		[super setCommand:[self commandForOffset:offset andArtist:artist]];
	}
	return self;
}

- (NSString *) commandForOffset:(int)offset andArtist:(SLArtist *)artist {
	return [NSString stringWithFormat:@"albums %d 80 tags:l,j %@",
			offset, artist == nil ? @"" : [NSString stringWithFormat:@"artist_id:%d", [artist artistId]]];
}

- (void) dealloc
{
	[_artist release];
	[super dealloc];
}

- (id) cloneRequest {
	return [SLCLIAlbumListRequest albumListRequestWithOffset:0 andArtist:_artist];
}

- (void) setOffset:(int)offset {
	[super setCommand:[self commandForOffset:offset andArtist:_artist]];
}

- (NSArray *) currentResultList {
	NSMutableArray *array = [NSMutableArray arrayWithArray:[super splittedAndUnescapedResponse]];
	// remove albums 0 80 tags:l,j
	[array removeObjectsInRange:NSMakeRange(0, 4)];
	
	NSMutableArray *albums = [NSMutableArray array];
	NSString *name = nil, *albumId = nil;
	SLAlbum *currentAlbum = nil;
	for (int i = 0; i < [array count]; i++) {
		NSString *s = [array objectAtIndex:i];
		
		if ([[s cliKey] isEqualToString:@"album"])
			name = [s cliValue];
		else if ([[s cliKey] isEqualToString:@"id"])
			albumId = [s cliValue];
		else if ([[s cliKey] isEqualToString:@"artwork_track_id"] && currentAlbum)
			[currentAlbum setArtId:[[s cliValue] intValue]];
		
		if (name != nil && albumId != nil) {
			currentAlbum = [SLAlbum albumWithName:name andId:[albumId intValue]];
			[albums addObject:currentAlbum];
			name = nil;
			albumId = nil;
		}
	}
	
	return [NSArray arrayWithArray:albums];
}

- (SLArtist *) artist {
	return [[_artist retain] autorelease];
}

@end
