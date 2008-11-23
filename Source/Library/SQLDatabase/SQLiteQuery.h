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
#import "SQLiteDatabase.h"

@class SQLiteResultEnumerator;

typedef enum _SQLiteQueryState {
	eSQLiteQueryStateInvalid,
	eSQLiteQueryStateHasStatement,
	eSQLiteQueryStatePrepared,
	eSQLiteQueryStateHasData,
} SQLiteQueryState;

@interface SQLiteQuery : NSObject {
	SQLiteDatabase *mDatabase;
	NSString *mSQLStatement;
	sqlite3_stmt *mStatement;
	int mError;
	
	SQLiteQueryState mState;
	
	NSMutableDictionary *mBoundValues;
	BOOL mUsingFilters;
}
- (id) initWithDatabase:(SQLiteDatabase *)theDatabase andQuery:(NSString *)theQuery;
- (void) dealloc;

- (BOOL) bindInteger:(int)aInteger toName:(NSString *)theName;
- (BOOL) bindString:(NSString *)aString toName:(NSString *)theName;
- (BOOL) bindData:(NSData *)aData toName:(NSString *)theName;

- (BOOL) prepare;
- (BOOL) prepareWithFilters:(NSArray *)theFilters;

- (BOOL) exec;
- (BOOL) execWithFilters:(NSArray *)theFilters;

- (void) invalidate;

- (int) lastError;
- (void) setError:(int)theError;

- (SQLiteQueryState) state;
- (void) setState:(SQLiteQueryState)theState;

- (BOOL) next;
- (int) intFromColumnIndex:(int)index;
- (NSString *) stringFromColumnIndex:(int)index;
- (NSData *) dataFromColumnIndex:(int)index;

- (void) reset;


- (int) columnCount;
- (NSString *) nameOfResultColumn:(int)index;
- (id) appropriateCocoaResultTypeForColumn:(int)column;

@end
