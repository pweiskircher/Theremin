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

#import "SLArtist.h"

@implementation SLArtist

+ (NSString *) singularName {
	return @"Artist";
}

+ (NSString *) pluralName {
	return @"Artists";
}

+ (id) artistWithName:(NSString *)name andId:(int)artistId {
	return [[[SLArtist alloc] initWithName:name andId:artistId] autorelease];
}

- (id) initWithName:(NSString *)name andId:(int)artistId {
	self = [super init];
	if (self != nil) {
		_name = [name copy];
		_id = artistId;
	}
	return self;
}

- (void) dealloc
{
	[_name release];
	[super dealloc];
}

- (NSString *) description {
	return [NSString stringWithFormat:@"Artist <%d> %@", [self artistId], [self title]];
}

- (int) artistId {
	return _id;
}

- (NSString *) title {
	return [[_name retain] autorelease];
}

- (NSString *) sortTitle {
	NSRange r = [[self title] rangeOfString:@"the " options:NSCaseInsensitiveSearch];
	if (r.location == 0) {
		return [[self title] substringFromIndex:r.length];
	}
	
	return [self title];
}

- (NSComparisonResult)caseInsensitiveCompare:(SLArtist *)artist {
	return [[self sortTitle] caseInsensitiveCompare:[artist sortTitle]];
}

@end
