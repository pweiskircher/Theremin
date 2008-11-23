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

#import <Cocoa/Cocoa.h>

@class Song, SQLiteDatabase, SQLiteQuery, SQLiteFilter;

#define TR_S_COMPILATION	NSLocalizedString(@"Compilations", @"Compilations")
extern int CompilationSQLIdentifier;

@interface SQLController : NSObject {
	SQLiteDatabase *mDatabase;
	
	NSMutableDictionary *mIdSelectQueries;
	NSMutableDictionary *mIdInsertQueries;
	
	SQLiteQuery *mSongInsertQuery;
}
+ (id) defaultController;

- (id) initWithFile:(NSString *)filename;
- (void) dealloc;

- (void) startup;
- (BOOL) createTables;

- (NSArray *) albumsWithFilters:(NSArray *)theFilters;
- (NSArray *) songsWithFilters:(NSArray *)theFilters;
- (NSArray *) artistsWithFilters:(NSArray *)theFilters;
- (NSArray *) genresWithFilters:(NSArray *)theFilters;

- (BOOL) insertSong:(Song *)aSong;
- (BOOL) insertSongs:(NSArray *)aArray;

- (BOOL) setSongsAsCompilation:(NSArray *)aArray;
- (BOOL) setSongAsCompilation:(Song *)aSong;

- (void) clearCompilations;

- (BOOL) removeSongsAsCompilation:(NSArray *)aArray;
- (BOOL) removeSongAsCompilation:(Song *)aSong;

- (NSArray *) compilationUniqueIdentifiers;
- (BOOL) setCompilationByUniqueIdentifiers:(NSArray *)uniqueIdentifiers;

- (void) clear;

- (NSDictionary *) metaData;
- (BOOL) setMetaData:(NSDictionary *)theMetaData;

@end
