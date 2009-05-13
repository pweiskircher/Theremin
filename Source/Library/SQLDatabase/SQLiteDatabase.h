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
#include "sqlite3.h"

@class SQLiteQuery;

@interface SQLiteDatabase : NSObject {
	NSString *mFilename;
	sqlite3 *mDatabase;
	
	int mSQLiteError;
	NSMutableSet *mQuerySet;
	
	NSLock *mQueryLock;
}
+ (id) databaseWithFilename:(NSString *)theFilename;
- (id) initWithFilename:(NSString *)theFilename;

- (void) dealloc;

- (BOOL) open;
- (void) close;

- (BOOL) execSimpleQuery:(NSString *)theQuery;
- (SQLiteQuery *) query:(NSString *)theQuery;

- (void) setError:(int)error;
- (int) lastError;

- (void) registerQuery:(SQLiteQuery *)theQuery;
- (void) unregisterQuery:(SQLiteQuery *)theQuery;

- (sqlite3 *) database;
- (int) lastInsertedRowId;

- (BOOL) startTransaction;
- (BOOL) commitTransaction;
- (BOOL) rollbackTransaction;

- (NSString *) filename;

- (void) lockQueryLock;
- (void) unlockQueryLock;
@end
