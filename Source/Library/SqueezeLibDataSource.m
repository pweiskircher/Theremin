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

#import "SqueezeLibDataSource.h"

#import <SqueezeLib/SLServer.h>
#import <SqueezeLib/SLCLICredentials.h>
#import <SqueezeLib/PWDatabaseQuery.h>

#import "Profile.h"

#import "ThereminFilterToPWDatabaseQueryFilter.h"


@implementation SqueezeLibDataSource
- (id) initWithProfile:(Profile *)aProfile {
	self = [super init];
	if (self != nil) {
		_profile = [aProfile retain];
		
		SLServer *server = [[[SLServer alloc] init] autorelease];
		[server setServer:[aProfile hostname]];
		[server setPort:[aProfile port]];
		
		SLCLICredentials *credentials = [[[SLCLICredentials alloc] initWithUsername:[aProfile user] andPassword:[aProfile password]] autorelease];
		
		_server = [[SLSqueezeServer alloc] initWithServer:server andCredentials:credentials];
		[_server setDelegate:self];
		[_server requestPlayerList];
		
		_operationQueue = [[LibraryOperationQueue alloc] initWithServer:_server];
	}
	return self;
}

- (void) dealloc
{
	[_profile release];
	[_server release];
	[_operationQueue release];
	[super dealloc];
}

- (void) serverError {
	
}

- (Profile *) profile {
	return [[_profile retain] autorelease];
}

- (void) fetchedPlayerList:(NSArray *)players {
	[_server setPlayer:[players objectAtIndex:0]];
}

- (void) databaseQuery:(PWDatabaseQuery *)query finished:(NSArray *)result {
	[_operationQueue databaseQuery:query finished:result];
}

- (void) requestAlbumsWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector {
	[_operationQueue queueOperationWithType:PWDatabaseQueryEntityTypeAlbum andFilters:[ThereminFilterToPWDatabaseQueryFilter transformFilters:theFilters] usingTarget:aTarget andSelector:aSelector];
}

- (void) requestArtistsWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector {
	[_operationQueue queueOperationWithType:PWDatabaseQueryEntityTypeArtist andFilters:[ThereminFilterToPWDatabaseQueryFilter transformFilters:theFilters] usingTarget:aTarget andSelector:aSelector];
}

- (void) requestGenresWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector {
	[_operationQueue queueOperationWithType:PWDatabaseQueryEntityTypeGenre andFilters:[ThereminFilterToPWDatabaseQueryFilter transformFilters:theFilters] usingTarget:aTarget andSelector:aSelector];
}

- (void) requestSongsWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector {
	[_operationQueue queueOperationWithType:PWDatabaseQueryEntityTypeTitle andFilters:[ThereminFilterToPWDatabaseQueryFilter transformFilters:theFilters] usingTarget:aTarget andSelector:aSelector];
}

- (int) supportsDataSourceCapabilities {
	return 0;
}
@end
