/*
 Copyright (C) 2006-2007  Patrik Weiskircher
 
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

#import "SQLController.h"
#import "WindowController.h"
#import "PreferencesController.h"
#import "SQLiteDatabase.h"
#import "SQLiteQuery.h"
#import "Song.h"
#import "Artist.h"
#import "Album.h"
#import "Genre.h"
#import "SQLUniqueIdentifiersFilter.h"

#import "Profile.h"

#define THEREMIN_DATABASE_FILENAME "theremin.db"
#define THEREMIN_SQLITE_DATABASE_VERSION	6

int CompilationSQLIdentifier = -54551;

const NSString *gDatabaseIdentifier = @"gDatabaseIdentifier";

@interface SQLController (PrivateMethods)
- (BOOL) _setCompilationByUniqueIdentifiers:(NSArray *)array;
- (void) needImport;

- (void) startup;
- (BOOL) createTables;

- (BOOL) setSongAsCompilation:(Song *)aSong;
- (BOOL) removeSongAsCompilation:(Song *)aSong;

- (NSMutableDictionary *) metaData;
@end

@implementation SQLController
- (id) initWithProfile:(Profile *)aProfile {
	self = [super init];
	if (self != nil) {
		NSString *filename = [NSString stringWithFormat:@"%@/%@-%d.db", 
				  [[WindowController instance] applicationSupportFolder],
							  [aProfile hostname], [aProfile port]];
		
		mDatabase = [[SQLiteDatabase databaseWithFilename:filename] retain];
		mIdInsertQueries = [[NSMutableDictionary dictionary] retain];
		mIdSelectQueries = [[NSMutableDictionary dictionary] retain];
		
		_profile = [aProfile retain];
		
		[self startup];
	}
	return self;
}

- (void) dealloc {
	[_profile release];
	
	[mSongInsertQuery release], mSongInsertQuery = nil;
	[mIdInsertQueries release], mIdInsertQueries = nil;
	[mIdSelectQueries release], mIdSelectQueries = nil;
	
	[mDatabase release], mDatabase = nil;
	[super dealloc];
}

- (int) supportsDataSourceCapabilities {
	return eLibraryDataSourceSupportsCustomCompilations |
		   eLibraryDataSourceSupportsImportingSongs | 
		   eLibraryDataSourceSupportsMultipleSelection;
}

- (Profile *) profile {
	return [[_profile retain] autorelease];
}

- (NSMutableDictionary *) metaData {
	SQLiteQuery *query = [mDatabase query:@"SELECT metaData FROM metaData ORDER BY id"];
	if (query && [query exec] && [query state] == eSQLiteQueryStateHasData) {
		NSData *data = [query dataFromColumnIndex:0];
		[query invalidate];
		
		return [NSMutableDictionary dictionaryWithDictionary:[NSPropertyListSerialization propertyListFromData:data 
												mutabilityOption:NSPropertyListImmutable 
														  format:NULL 
												errorDescription:NULL]];
	}
	
	return nil;
}

- (BOOL) setMetaData:(NSDictionary *)theMetaData {
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:theMetaData format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL];

	[mDatabase execSimpleQuery:@"DELETE FROM metaData"];
	
	SQLiteQuery *query = [mDatabase query:@"INSERT INTO metaData (metaData) VALUES(:data)"];
	[query bindData:data toName:@":data"];
	return [query exec];
}

- (void) needImport {
	_needImport = YES;
}

- (BOOL) needsImport {
	if (_needImport)
		return YES;
	
	NSData *databaseIdentifier = [[self metaData] objectForKey:gDatabaseIdentifier];
	if ([databaseIdentifier isEqualToData:[[[WindowController instance] musicClient] databaseIdentifier]] == NO)
		return YES;
	
	return NO;
}

- (void) startup {
	if ([[NSFileManager defaultManager] fileExistsAtPath:[mDatabase filename]] == NO) {
		// if the database doesn't exist, force a import on next connect
		[self needImport];
	}
	
	if ([mDatabase open] != YES) {
		// TODO: error reporting
		NSLog(@"Could not open database.");
		[mDatabase release];
		mDatabase = nil;
		return;
	}
	
	[mDatabase execSimpleQuery:@"CREATE TABLE IF NOT EXISTS metaData(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
		                       @"metaData BLOB(1024));"];
	
	NSDictionary *dict = [self metaData];
	if (dict) {
		int version = [[dict objectForKey:@"DB_VERSION"] intValue];
		if (version < THEREMIN_SQLITE_DATABASE_VERSION) {
			NSLog(@"upgrading database ...");
			[mDatabase close];
			[[NSFileManager defaultManager] removeFileAtPath:[mDatabase filename] handler:NULL];
			[self startup];
			return;
		}
	} else {
		dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:THEREMIN_SQLITE_DATABASE_VERSION] forKey:@"DB_VERSION"];
		[self setMetaData:dict];
	}
	
	if ([self createTables] == NO) {
		// TODO: error reporting
	}
}

- (BOOL) createTables {
	if ([mDatabase execSimpleQuery:@"CREATE TABLE IF NOT EXISTS "
								   @"artists(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT);"] == NO)
        return NO;
	if ([mDatabase execSimpleQuery:@"CREATE UNIQUE INDEX IF NOT EXISTS artist_key_name ON artists(name);"] == NO)
		return NO;
	
    if ([mDatabase execSimpleQuery:@"CREATE TABLE IF NOT EXISTS "
								   @"albums(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT);"] == NO)
        return NO;
    if ([mDatabase execSimpleQuery:@"CREATE UNIQUE INDEX IF NOT EXISTS album_key_name ON albums(name);"] == NO)
        return NO;
	
	if ([mDatabase execSimpleQuery:@"CREATE TABLE IF NOT EXISTS "
								   @"genres(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT);"] == NO)
		return NO;
	if ([mDatabase execSimpleQuery:@"CREATE UNIQUE INDEX IF NOT EXISTS genre_key_name ON genres(name);"] == NO)
		return NO;
	
    if ([mDatabase execSimpleQuery:@"CREATE TABLE IF NOT EXISTS songs("
		                           @"id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
								   @"file TEXT, artist INTEGER DEFAULT NULL, "
								   @"album INTEGER DEFAULT NULL, "
								   @"genre INTEGER DEFAULT NULL, "
		                           @"title TEXT, "
								   @"track TEXT, "
		                           @"name TEXT, "
		                           @"date TEXT, "
		                           @"composer TEXT, "
		                           @"disc TEXT, "
		                           @"comment TEXT, "
		                           @"time INTEGER, "
		                           @"uniqueIdentifier BLOB(64), "
								   @"isCompilation BOOL DEFAULT 0"
		                           @");"] == NO)
        return NO;
    if ([mDatabase execSimpleQuery:@"CREATE UNIQUE INDEX IF NOT EXISTS track_id ON songs(id);"] == NO)
        return NO;
	
    return YES;	
}

- (NSArray *) resultFromQueryUsingClass:(Class)class andQuery:(SQLiteQuery *)theQuery {
	if ([theQuery state] != eSQLiteQueryStateHasData)
		return nil;

	NSMutableArray *array = [NSMutableArray array];
	do {
		id item = [[[class alloc] init] autorelease];
		for (int i = 0; i < [theQuery columnCount]; i++) {
			[item setValue:[theQuery appropriateCocoaResultTypeForColumn:i] forKey:[theQuery nameOfResultColumn:i]];
		//	NSLog(@"%@: %@", [theQuery appropriateCocoaResultTypeForColumn:i], [theQuery nameOfResultColumn:i]);
		}
			
		[array addObject:item];
	} while ([theQuery next]);
	
	return array;
}

- (NSArray *) artistsFromQuery:(SQLiteQuery *)theQuery {
	if ([theQuery state] != eSQLiteQueryStateHasData)
		return nil;
	
	BOOL includesCompilations = NO;
	
	NSMutableArray *array = [NSMutableArray array];
	do {
		Artist *artist = [[[Artist alloc] init] autorelease];
		[artist setName:[theQuery stringFromColumnIndex:0]];
		[artist setIdentifier:[theQuery intFromColumnIndex:1]];
		
		if ([theQuery intFromColumnIndex:2] == 1)
			includesCompilations = YES;
		else
			[array addObject:artist];		
	} while ([theQuery next]);
	
	if (includesCompilations) {
		Artist *artist = [[[Artist alloc] init] autorelease];
		[artist setName:TR_S_COMPILATION];
		[artist setIdentifier:CompilationSQLIdentifier];
		[array addObject:artist];
	}
	
	return array;
}

- (void) requestGenresWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector {
	NSMutableString *sql = [NSMutableString stringWithString:@"SELECT DISTINCT genres.name AS name, songs.genre AS identifier FROM songs LEFT JOIN genres ON songs.genre = genres.id LEFT JOIN albums ON songs.album = albums.id LEFT JOIN artists ON songs.artist = artists.id "];
	
	SQLiteQuery *query = [mDatabase query:sql];
	if ([query execWithFilters:theFilters] == NO)
		[NSException raise:NSGenericException format:@"Couldn't get genres."];
	
	NSArray *results = [self resultFromQueryUsingClass:[Genre class] andQuery:query];
	[aTarget performSelector:aSelector withObject:results];
}

- (void) requestAlbumsWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector {
	NSMutableString *sql = [NSMutableString stringWithString:@"SELECT DISTINCT albums.name AS name, songs.album AS identifier FROM songs LEFT JOIN albums ON songs.album = albums.id LEFT JOIN artists ON songs.artist = artists.id "];
	
	SQLiteQuery *query = [mDatabase query:sql];
	if ([query execWithFilters:theFilters] == NO)
		[NSException raise:NSGenericException format:@"Couldn't get albums."];
	
	NSArray *results = [self resultFromQueryUsingClass:[Album class] andQuery:query];
	[aTarget performSelector:aSelector withObject:results];	
}

- (void) requestSongsWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector {
	NSMutableString *sql = [NSMutableString stringWithString:@"SELECT songs.file AS file, songs.title AS title, songs.track AS track,"
							@"songs.name AS name, songs.date AS date, songs.composer AS composer, songs.disc AS disc,"
							@"songs.comment AS comment, songs.time AS time, songs.uniqueIdentifier AS uniqueIdentifier,"
							@"artists.name AS artist, albums.name AS album, songs.id AS identifier, "
							@"songs.isCompilation AS isCompilation, genres.name AS genre "
							@"FROM songs LEFT JOIN artists ON songs.artist = artists.id LEFT JOIN albums ON songs.album = albums.id LEFT JOIN genres ON songs.genre = genres.id"];

	SQLiteQuery *query = [mDatabase query:sql];
	if ([query execWithFilters:theFilters] == NO)
		[NSException raise:NSGenericException format:@"Couldn't get songs."];
	
	NSArray *results = [self resultFromQueryUsingClass:[Song class] andQuery:query];
	[aTarget performSelector:aSelector withObject:results];	
}

- (void) requestArtistsWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector {
	NSMutableString *sql = [NSMutableString stringWithString:@"SELECT DISTINCT artists.name AS name, songs.artist AS identifier, songs.isCompilation FROM songs "
		                                                     @"LEFT JOIN artists ON songs.artist = artists.id "
		                                                     @"LEFT JOIN albums ON songs.album = albums.id"];
	
	SQLiteQuery *query = [mDatabase query:sql];
	if ([query execWithFilters:theFilters] == NO)
		[NSException raise:NSGenericException format:@"Couldn't get artists."];
	
	NSArray *results = [self artistsFromQuery:query];
	[aTarget performSelector:aSelector withObject:results];	
}

- (int) getIdFromTable:(NSString *)table forItem:(id)item usingKey:(NSString *)key andFallbackIfKeyUnknown:(NSString *)fallback {
	SQLiteQuery *mSelectQuery = [mIdSelectQueries objectForKey:table];
	if (!mSelectQuery) {
		mSelectQuery = [mDatabase query:[NSString stringWithFormat:@"SELECT id FROM %@ WHERE name = :NAME;", table]];
		[mIdSelectQueries setObject:mSelectQuery forKey:table];
	}
	
	NSString *name = [item valueForKey:key];
	if (name == nil)
		if (fallback != nil) name = fallback;
		else return -1;
	
	if (![mSelectQuery bindString:name toName:@":NAME"])
		return -1;
	
	if ([mSelectQuery exec] && [mSelectQuery state] == eSQLiteQueryStateHasData) {
		int theId = [mSelectQuery intFromColumnIndex:0];
		[mSelectQuery reset];
		return theId;
	}
	
	SQLiteQuery *insertQuery = [mIdInsertQueries objectForKey:table];
	if (!insertQuery) {
		insertQuery = [mDatabase query:[NSString stringWithFormat:@"INSERT INTO %@ (name) VALUES(:NAME);", table]];
		[mIdInsertQueries setObject:insertQuery forKey:table];
	}
	
	// we don't have the item in the table - create a new one.
	if (![insertQuery bindString:name toName:@":NAME"] || ![insertQuery exec])
		return -1;

	return [mDatabase lastInsertedRowId];
}

- (int) artistId:(Song *)aSong {
	return [self getIdFromTable:@"artists" forItem:aSong usingKey:@"artist" andFallbackIfKeyUnknown:gUnknownArtistName];
}

- (int) genreId:(Song *)aSong {
	return [self getIdFromTable:@"genres" forItem:aSong usingKey:@"genre" andFallbackIfKeyUnknown:gUnknownGenreName];
}

- (int) albumId:(Song *)aSong {
	return [self getIdFromTable:@"albums" forItem:aSong usingKey:@"album" andFallbackIfKeyUnknown:gUnknownAlbumName];
}

- (BOOL) insertSong:(Song *)aSong {
	int artistId = [self artistId:aSong];
	int albumId = [self albumId:aSong];
	int genreId = [self genreId:aSong];

	if (!mSongInsertQuery) {
		mSongInsertQuery = [[mDatabase query:@"INSERT INTO songs (file, artist, album, title, track, name, date, genre, composer, disc, comment, time, uniqueIdentifier) VALUES(:FILE, :ARTIST, :ALBUM, :TITLE, :TRACK, :NAME, :DATE, :GENRE, :COMPOSER, :DISC, :COMMENT, :TIME, :UNIQUEIDENTIFIER);"] retain];
	}

	[mSongInsertQuery bindString:[aSong file] toName:@":FILE"];
	
	if (artistId != -1)
		[mSongInsertQuery bindInteger:artistId toName:@":ARTIST"];
	if (albumId != -1)
		[mSongInsertQuery bindInteger:albumId toName:@":ALBUM"];
	if (genreId != -1)
		[mSongInsertQuery bindInteger:genreId toName:@":GENRE"];
	
	[mSongInsertQuery bindString:[aSong title] toName:@":TITLE"];
	[mSongInsertQuery bindString:[aSong track] toName:@":TRACK"];
	[mSongInsertQuery bindString:[aSong name] toName:@":NAME"];
	[mSongInsertQuery bindString:[aSong date] toName:@":DATE"];
	[mSongInsertQuery bindString:[aSong composer] toName:@":COMPOSER"];
	[mSongInsertQuery bindString:[aSong disc] toName:@":DISC"];
	[mSongInsertQuery bindString:[aSong comment] toName:@":COMMENT"];
	[mSongInsertQuery bindInteger:[aSong time] toName:@":TIME"];
	[mSongInsertQuery bindData:[aSong uniqueIdentifier] toName:@":UNIQUEIDENTIFIER"];
	
	return [mSongInsertQuery exec];
}

- (BOOL) insertSongs:(NSArray *)aArray withDatabaseIdentifier:(NSData *)aIdentifier {
	NSEnumerator *songenum = [aArray objectEnumerator];
	Song *song;
	
	[mDatabase startTransaction];
	while (song = [songenum nextObject]) {
		if (![self insertSong:song]) {
			[mDatabase rollbackTransaction];
			return NO;
		}
	}

	NSMutableDictionary *metaData = [self metaData];
	[metaData setObject:aIdentifier forKey:gDatabaseIdentifier];
	[self setMetaData:metaData];
	return [mDatabase commitTransaction];
}


- (BOOL) setSongsAsCompilation:(NSArray *)aArray {
	NSEnumerator *songenum = [aArray objectEnumerator];
	Song *song;
	
	[mDatabase startTransaction];
	while (song = [songenum nextObject]) {
		if (![self setSongAsCompilation:song]) {
			[mDatabase rollbackTransaction];
			return NO;
		}
	}
	
	return [mDatabase commitTransaction];
}

- (BOOL) setSongAsCompilation:(Song *)aSong {
	SQLiteQuery *query = [mDatabase query:@"UPDATE songs SET isCompilation = 1 WHERE songs.id = :ID"];
	[query bindInteger:[aSong identifier] toName:@":ID"];
	return [query exec];
}

- (void) clearCompilations {
	SQLiteQuery *query = [mDatabase query:@"UPDATE songs SET isCompilation = 0;"];
	[query exec];
}

- (BOOL) removeSongsAsCompilation:(NSArray *)aArray {
	NSEnumerator *songenum = [aArray objectEnumerator];
	Song *song;
	
	[mDatabase startTransaction];
	while (song = [songenum nextObject]) {
		if (![self removeSongAsCompilation:song]) {
			[mDatabase rollbackTransaction];
			return NO;
		}
	}
	
	return [mDatabase commitTransaction];
}

- (BOOL) removeSongAsCompilation:(Song *)aSong {
	SQLiteQuery *query = [mDatabase query:@"UPDATE songs SET isCompilation = 0 WHERE songs.id = :ID"];
	[query bindInteger:[aSong identifier] toName:@":ID"];
	return [query exec];
}

- (NSArray *) compilationUniqueIdentifiers {
	SQLiteQuery *query = [mDatabase query:@"SELECT uniqueIdentifier FROM songs WHERE isCompilation = 1"];
	if ([query exec] && [query state] == eSQLiteQueryStateHasData) {
		NSMutableArray *array = [NSMutableArray array];
		do {
			[array addObject:[query dataFromColumnIndex:0]];
		} while ([query next]);
		
		return array;
	}
	
	return nil;
}

- (BOOL) setCompilationByUniqueIdentifiers:(NSArray *)uniqueIdentifiers {
	if ([uniqueIdentifiers count] <= 0)
		return YES;

	NSEnumerator *enumerator = [uniqueIdentifiers objectEnumerator];
	NSData *uniqueIdentifier;
	NSMutableArray *batch = [NSMutableArray array];
	while (uniqueIdentifier = [enumerator nextObject]) {
		[batch addObject:uniqueIdentifier];
		
		if ([batch count] > 500) {
			if (![self _setCompilationByUniqueIdentifiers:batch])
				return NO;
			[batch removeAllObjects];
		}
	}

	if ([batch count] > 0)
		if (![self _setCompilationByUniqueIdentifiers:batch])
			return NO;
	return YES;
}

- (BOOL) _setCompilationByUniqueIdentifiers:(NSArray *)array {
	SQLiteQuery *query = [mDatabase query:@"UPDATE songs SET isCompilation = 1"];
	return [query execWithFilters:
				[NSArray arrayWithObject:[[[SQLUniqueIdentifiersFilter alloc] initWithUniqueIdentifiers:array] autorelease]]];
}

- (void) clear {
	[mDatabase startTransaction];
	[mDatabase execSimpleQuery:@"DELETE FROM songs;"];
	[mDatabase execSimpleQuery:@"DELETE FROM artists;"];
	[mDatabase execSimpleQuery:@"DELETE FROM albums;"];
	[mDatabase execSimpleQuery:@"DELETE FROM genres;"];
	[mDatabase commitTransaction];
}
@end
