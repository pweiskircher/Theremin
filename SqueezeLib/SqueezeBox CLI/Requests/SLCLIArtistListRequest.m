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

#import "SLCLIArtistListRequest.h"
#import "SLArtist.h"

@interface SLCLIArtistListRequest (PrivateMethods)
- (NSString *) commandForOffset:(int)offset;
@end

@implementation SLCLIArtistListRequest
+ (id) artistListRequestWithOffset:(int)offset {
	return [[[SLCLIArtistListRequest alloc] initWithOffset:offset] autorelease];
}

- (id) initWithOffset:(int)offset
{
	return [super initWithCommand:[self commandForOffset:offset]];
}

- (id) cloneRequest {
	return [SLCLIArtistListRequest artistListRequestWithOffset:0];
}

- (NSString *) commandForOffset:(int)offset {
	return [NSString stringWithFormat:@"artists %d 80", offset];
}

- (void) setOffset:(int)offset {
	[super setCommand:[self commandForOffset:offset]];
}

- (NSArray *) currentResultList {
	NSMutableArray *array = [NSMutableArray arrayWithArray:[super splittedAndUnescapedResponse]];
	// remove artist 0 80
	[array removeObjectsInRange:NSMakeRange(0, 3)];
	
	NSMutableArray *artists = [NSMutableArray array];
	NSString *name = nil, *artistId = nil;
	
	for (int i = 0; i < [array count]; i++) {
		NSString *s = [array objectAtIndex:i];	
		if ([[s cliKey] isEqualToString:@"artist"])
			name = [s cliValue];
		else if ([[s cliKey] isEqualToString:@"id"])
			artistId = [s cliValue];
		
		if (name != nil && artistId != nil) {
			[artists addObject:[SLArtist artistWithName:name andId:[artistId intValue]]];
			name = nil;
			artistId = nil;
		}
	}
	
	return [NSArray arrayWithArray:artists];
}

@end
