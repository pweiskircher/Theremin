/*
 Copyright (C) 2009  Patrik Weiskircher
 
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

#import "LibraryOperation.h"


@implementation LibraryOperation
+ (id) libraryOperationUsingType:(PWDatabaseQueryEntityType)aType andFilters:(NSArray *)someFilters andTarget:(id)aTarget andSelector:(SEL)aSel {
	return [[[LibraryOperation alloc] initWithType:aType andFilters:someFilters andTarget:aTarget andSelector:aSel] autorelease];
}

- (id) initWithType:(PWDatabaseQueryEntityType)aType andFilters:(NSArray *)someFilters andTarget:(id)aTarget andSelector:(SEL)aSel {
	self = [super init];
	if (self != nil) {
		_type = aType;
		_target = [aTarget retain];
		_sel = aSel;
		_filter = [someFilters retain];
	}
	return self;
}

- (void) dealloc
{
	[_target release];
	[_filter release];
	[super dealloc];
}

- (PWDatabaseQueryEntityType) type {
	return _type;
}

- (NSArray *) filters {
	return [[_filter retain] autorelease];
}


- (void) reportResult:(id)aResult {
	[_target performSelector:_sel withObject:aResult];
}
@end
