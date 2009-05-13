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

#import "SQLiteDatabase.h"
#import "SQLiteQuery.h"

void sqlitetrace(void *gna, const char *s) {
	NSLog(@"%s", s);
}

@implementation SQLiteDatabase
+ (id) databaseWithFilename:(NSString *)theFilename {
	return [[[SQLiteDatabase alloc] initWithFilename:theFilename] autorelease];
}

- (id) initWithFilename:(NSString *)theFilename {
	self = [super init];
	if (self != nil) {
		mFilename = [theFilename retain];
		mDatabase = NULL;
		mSQLiteError = SQLITE_OK;
		mQuerySet = [[NSMutableSet set] retain];
		mQueryLock = [[NSLock alloc] init];
	}
	return self;
}

- (void) dealloc {
	[mFilename release], mFilename = nil;
	
	if (mDatabase)
		[self close];
	
	[mQuerySet release], mQuerySet = nil;
	[mQueryLock release], mQueryLock = nil;
	
	[super dealloc];
}

- (BOOL) open {
	NSString *directory = [mFilename stringByDeletingLastPathComponent];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory attributes:nil];
	
	int result = sqlite3_open([mFilename UTF8String], &mDatabase);
	if (result != SQLITE_OK) {
		sqlite3_close(mDatabase);
		[self setError:result];
		return NO;
	}
//	sqlite3_trace(mDatabase, sqlitetrace, NULL);
//	sqlite3_extended_result_codes(mDatabase,1);
	return YES;
}

- (void) close {
	// we have to finalize every query - otherwise we can't close the database
	NSEnumerator *enumerator = [mQuerySet objectEnumerator];
	SQLiteQuery *query;
	
	while (query = [enumerator nextObject])
		[query invalidate];
	
	[mQuerySet removeAllObjects];
	
	int result = sqlite3_close(mDatabase);
	[self setError:result];
	if (result != SQLITE_OK) {
		[NSException raise:NSInternalInconsistencyException format:@"Couldn't close database: %d", result];
		return;
	}
	return;
}

- (BOOL) execSimpleQuery:(NSString *)theQuery {
	SQLiteQuery *query = [self query:theQuery];
	return [query exec];
}

- (SQLiteQuery *) query:(NSString *)theQuery {
	SQLiteQuery *query = [[[SQLiteQuery alloc] initWithDatabase:self andQuery:theQuery] autorelease];
	return query;
}

- (void) setError:(int)error {	
	mSQLiteError = error;
}

- (int) lastError {
	return mSQLiteError;
}

- (void) registerQuery:(SQLiteQuery *)theQuery {
	[mQuerySet addObject:theQuery];
}

- (void) unregisterQuery:(SQLiteQuery *)theQuery {
	[mQuerySet removeObject:theQuery];
}

- (sqlite3 *) database {
	return mDatabase;
}

- (int) lastInsertedRowId {
	return sqlite3_last_insert_rowid(mDatabase);
}

- (BOOL) startTransaction {
	return [self execSimpleQuery:@"BEGIN TRANSACTION"];
}

- (BOOL) commitTransaction {
	return [self execSimpleQuery:@"COMMIT TRANSACTION"];
}

- (BOOL) rollbackTransaction {
	return [self execSimpleQuery:@"ROLLBACK TRANSACTION"];
}

- (NSString *) filename {
	return [[mFilename retain] autorelease];
}

- (void) lockQueryLock {
	[mQueryLock lock];
}

- (void) unlockQueryLock {
	[mQueryLock unlock];
}

@end
