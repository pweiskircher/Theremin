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

#import "SqueezeLibToThereminTransformer.h"
#import "NSArray+Transformations.h"

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
	}
	return self;
}

- (void) dealloc
{
	[_profile release];
	[_server release];
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
	if ([query type] == PWDatabaseQueryEntityTypeArtist) {
		NSArray *artists = [result arrayByApplyingTransformationUsingTarget:[SqueezeLibToThereminTransformer class] andSelector:@selector(slArtistToArtistTransform:)];
		[[NSNotificationCenter defaultCenter] postNotificationName:nLibraryDataSourceReceivedArtists
															object:nil
														  userInfo:[NSDictionary dictionaryWithObject:artists forKey:gLibraryResults]];		
	} else if ([query type] == PWDatabaseQueryEntityTypeAlbum) {
		NSArray *albums = [result arrayByApplyingTransformationUsingTarget:[SqueezeLibToThereminTransformer class] andSelector:@selector(slAlbumToAlbumTransform:)];
		[[NSNotificationCenter defaultCenter] postNotificationName:nLibraryDataSourceReceivedAlbums
															object:nil
														  userInfo:[NSDictionary dictionaryWithObject:albums forKey:gLibraryResults]];				
	} else if ([query type] == PWDatabaseQueryEntityTypeGenre) {
		NSArray *genres = [result arrayByApplyingTransformationUsingTarget:[SqueezeLibToThereminTransformer class] andSelector:@selector(slGenreToGenreTransform:)];
		[[NSNotificationCenter defaultCenter] postNotificationName:nLibraryDataSourceReceivedGenres
															object:nil
														  userInfo:[NSDictionary dictionaryWithObject:genres forKey:gLibraryResults]];						
	} else if ([query type] == PWDatabaseQueryEntityTypeTitle) {
		NSArray *titles = [result arrayByApplyingTransformationUsingTarget:[SqueezeLibToThereminTransformer class] andSelector:@selector(slTitleToSongTransform:)];
		[[NSNotificationCenter defaultCenter] postNotificationName:nLibraryDataSourceReceivedSongs
															object:nil
														  userInfo:[NSDictionary dictionaryWithObject:titles forKey:gLibraryResults]];
	}
}

- (void) requestAlbumsWithFilters:(NSArray *)theFilters {
	[_server executeDatabaseQueryForType:PWDatabaseQueryEntityTypeAlbum usingFilters:[ThereminFilterToPWDatabaseQueryFilter transformFilters:theFilters]];
}

- (void) requestArtistsWithFilters:(NSArray *)theFilters {
	[_server executeDatabaseQueryForType:PWDatabaseQueryEntityTypeArtist usingFilters:[ThereminFilterToPWDatabaseQueryFilter transformFilters:theFilters]];
}

- (void) requestGenresWithFilters:(NSArray *)theFilters {
	[_server executeDatabaseQueryForType:PWDatabaseQueryEntityTypeGenre usingFilters:[ThereminFilterToPWDatabaseQueryFilter transformFilters:theFilters]];
}

- (void) requestSongsWithFilters:(NSArray *)theFilters {
	[_server executeDatabaseQueryForType:PWDatabaseQueryEntityTypeTitle usingFilters:[ThereminFilterToPWDatabaseQueryFilter transformFilters:theFilters]];
}

- (int) supportsDataSourceCapabilities {
	return 0;
}
@end
