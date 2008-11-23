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
#import "LibraryDataSource.h"

@class Song, SQLiteDatabase, SQLiteQuery, SQLiteFilter;

#define TR_S_COMPILATION	NSLocalizedString(@"Compilations", @"Compilations")
extern int CompilationSQLIdentifier;

@interface SQLController : NSObject <LibraryDataSourceProtocol> {
	SQLiteDatabase *mDatabase;
	
	NSMutableDictionary *mIdSelectQueries;
	NSMutableDictionary *mIdInsertQueries;
	
	SQLiteQuery *mSongInsertQuery;
	
	BOOL _needImport;
	
	Profile *_profile;
}
@end
