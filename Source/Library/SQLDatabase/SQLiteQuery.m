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

#import "SQLiteQuery.h"
#import "LibraryFilterToSQLQueryConverter.h"

@implementation SQLiteQuery
- (id) initWithDatabase:(SQLiteDatabase *)theDatabase andQuery:(NSString *)theQuery {
	self = [super init];
	if (self != nil) {
		mDatabase = [theDatabase retain];
		mSQLStatement = [theQuery retain];
		mStatement = NULL;
		[self setState:eSQLiteQueryStateHasStatement];
		mUsingFilters = NO;
	}
	return self;
}

- (void) dealloc {
	[mSQLStatement release], mSQLStatement = nil;
	[mBoundValues release], mBoundValues = nil;
	[self invalidate];
	[mDatabase release];
	[super dealloc];
}

- (BOOL) prepare {
	return [self prepareWithFilters:nil];
}

- (BOOL) prepareWithFilters:(NSArray *)theFilters {
	const char *query;
	
	if ([theFilters count] > 0) {
		
		LibraryFilterToSQLQueryConverter *converter = [[[LibraryFilterToSQLQueryConverter alloc] initWithLibraryFilters:theFilters] autorelease];
		[converter process];
		query = [[NSString stringWithFormat:@"%@ WHERE %@", mSQLStatement, [converter whereClause]] UTF8String];
		
		if (mBoundValues) {
			[mBoundValues addEntriesFromDictionary:[converter boundValues]];
		} else {
			mBoundValues = [[converter boundValues] retain];
		}
	} else {
		query = [mSQLStatement UTF8String];
	}
	const char *tail;
	
#ifdef SQL_DEBUG
	NSLog(@"%s", query);
#endif

	[mDatabase lockQueryLock];
	int result = sqlite3_prepare_v2([mDatabase database],
									query,
									-1,
									&mStatement,
									&tail);
	[mDatabase unlockQueryLock];
	[self setError:result];
	if (result != SQLITE_OK) {
		[NSException raise:NSInternalInconsistencyException format:@"SQL Query %s can't be prepared: %s",
			query, sqlite3_errmsg([mDatabase database])];
		
		// TODO: do we need to finalize it anyway?
		mStatement = NULL;
		[self setState:eSQLiteQueryStateInvalid];
		[mBoundValues release], mBoundValues = nil;
		return NO;
	}
	
	[self setState:eSQLiteQueryStatePrepared];
	
	if ([mBoundValues count]) {
		NSEnumerator *enumerator = [mBoundValues keyEnumerator];
		NSString *key;
		
		while (key = [enumerator nextObject]) {
			id object = [mBoundValues objectForKey:key];
			if ([object isKindOfClass:[NSNumber class]])
				[self bindInteger:[object intValue] toName:key];
			else if ([object isKindOfClass:[NSString class]])
				[self bindString:object toName:key];
			else if ([object isKindOfClass:[NSData class]])
				[self bindData:object toName:key];
		}
		
		[mBoundValues release], mBoundValues = nil;
	}

	return YES;
}

- (BOOL) bindInteger:(int)aInteger toName:(NSString *)theName {
	if (mStatement == NULL || [self state] != eSQLiteQueryStatePrepared) {
		if (!mBoundValues) mBoundValues = [[NSMutableDictionary dictionary] retain];
		[mBoundValues setObject:[NSNumber numberWithInt:aInteger] forKey:theName];
		return YES;
	}
	
	int index = sqlite3_bind_parameter_index(mStatement, [theName UTF8String]);
	if (index < 1) {
		NSLog(@"Couldn't find parameter '%@' for bind.", theName);
		return NO;
	}
	
	int result = sqlite3_bind_int(mStatement, index, aInteger);
	[self setError:result];
	if (result != SQLITE_OK)
		return NO;
	
	return YES;
}

- (BOOL) bindString:(NSString *)aString toName:(NSString *)theName {
	if (!aString)
		return NO;
	
	if (mStatement == NULL || [self state] != eSQLiteQueryStatePrepared) {
		if (!mBoundValues) mBoundValues = [[NSMutableDictionary dictionary] retain];
		[mBoundValues setObject:aString forKey:theName];
		return YES;
	}
	
	int index = sqlite3_bind_parameter_index(mStatement, [theName UTF8String]);
	if (index < 1) {
		NSLog(@"Couldn't find parameter '%@' for bind.", theName);
		return NO;
	}
	
	int result = sqlite3_bind_text(mStatement, index, [aString UTF8String], -1, SQLITE_STATIC);
	[self setError:result];
	if (result != SQLITE_OK)
		return NO;
	
	return YES;
}

- (BOOL) bindData:(NSData *)aData toName:(NSString *)theName {
	if (!aData)
		return NO;
	
	if (mStatement == NULL || [self state] != eSQLiteQueryStatePrepared) {
		if (!mBoundValues) mBoundValues = [[NSMutableDictionary dictionary] retain];
		[mBoundValues setObject:aData forKey:theName];
		return YES;
	}
	
	int index = sqlite3_bind_parameter_index(mStatement, [theName UTF8String]);
	if (index < 1) {
		NSLog(@"Couldn't find parameter '%@' for bind.", theName);
		return NO;
	}
	
	int result = sqlite3_bind_blob(mStatement, index, [aData bytes], [aData length], SQLITE_STATIC);
	[self setError:result];
	if (result != SQLITE_OK)
		return NO;
	
	return YES;
}

- (BOOL) execInternal {
	if (mStatement == NULL || [self state] != eSQLiteQueryStatePrepared)
		return NO;
	
	[mDatabase lockQueryLock];
	int result = sqlite3_step(mStatement);
	[mDatabase unlockQueryLock];
	
	[self setError:result];
	
	if (result == SQLITE_DONE) {
		[self reset];
		[self setState:eSQLiteQueryStatePrepared];
		return YES;
	} else if (result == SQLITE_ROW) {
		[self setState:eSQLiteQueryStateHasData];
		return YES;
	} else if (result == SQLITE_BUSY)
		return NO;
	
	[self reset];
	return NO;
}


- (BOOL) exec {
	if (mUsingFilters) {
		[self invalidate];
		
		if ([self state] == eSQLiteQueryStateInvalid) {
			[NSException raise:NSInternalInconsistencyException format:@"Can't exec if you were using filters before and now you don't and no SQL statement set (shouldn't happen!)."];
			return NO;
		}
		
		mUsingFilters = NO;
	}
	
	if ([self state] == eSQLiteQueryStateHasStatement)
		[self prepare];
	
	while (1) {
		if ([self execInternal] == YES)
			return YES;
		
		if ([self lastError] != SQLITE_BUSY) {
			NSLog(@"Error on executing SQL Query '%@': %d/%s", mSQLStatement, [self lastError], sqlite3_errmsg([mDatabase database]));
			return NO;
		}
	}
}

- (BOOL) execWithFilters:(NSArray *)theFilters {
	if ([self state] != eSQLiteQueryStateHasStatement) {
		if (!mSQLStatement) {
			[NSException raise:NSInternalInconsistencyException format:@"Can't apply filter with a already prepared query without the SQL statement set (shouldn't happen!)."];
			return NO;
		}
		
		[self invalidate];
	}
	
	if ([self prepareWithFilters:theFilters] == NO)
		return NO;
	
	while (1) {
		if ([self execInternal] == YES)
			return YES;
		
		if ([self lastError] != SQLITE_BUSY)
			return NO;
	}
}

- (void) invalidate {
	if (mStatement) {
		[mDatabase lockQueryLock];
		sqlite3_finalize(mStatement);
		[mDatabase unlockQueryLock];
		mStatement = NULL;
		
		if (mSQLStatement) {
			[self setState:eSQLiteQueryStateHasStatement];
		} else {
			[self setState:eSQLiteQueryStateInvalid];
		}
	}
}

- (int) lastError {
	return mError;
}

- (void) setError:(int)theError {
	mError = theError;
}

- (SQLiteQueryState) state {
	return mState;
}

- (void) setState:(SQLiteQueryState)theState {
	mState = theState;
}

- (BOOL) next {
	if (mStatement == NULL)
		return NO;
	
	if ([self state] != eSQLiteQueryStateHasData) {
		[NSException raise:NSInternalInconsistencyException format:@"Calling next is only allowed in HasData state"];
		return NO;
	}
	
	[mDatabase lockQueryLock];
	int result = sqlite3_step(mStatement);
	[mDatabase unlockQueryLock];
	
	if (result == SQLITE_DONE) {
		[self reset];
		[self setState:eSQLiteQueryStatePrepared];
		return NO;
	} else if (result == SQLITE_ROW) {
		return YES;
	} else {
		[self setError:result];
		return NO;
	}
}

- (int) intFromColumnIndex:(int)index {
	if ([self state] != eSQLiteQueryStateHasData) {
		[NSException raise:NSInternalInconsistencyException format:@"Calling intFromColumn is only allowed in HasData state"];
		return NO;
	}
	
	return sqlite3_column_int(mStatement, index);
}

- (NSString *) stringFromColumnIndex:(int)index {
	if ([self state] != eSQLiteQueryStateHasData) {
		[NSException raise:NSInternalInconsistencyException format:@"Calling stringFromColumn is only allowed in HasData state"];
		return NO;
	}	
	
	const unsigned char *text = sqlite3_column_text(mStatement, index);
	if (text) {
		return [NSString stringWithUTF8String:(const char *)text];
	}
	
	return nil;
}

- (NSData *) dataFromColumnIndex:(int)index {
	if ([self state] != eSQLiteQueryStateHasData) {
		[NSException raise:NSInternalInconsistencyException format:@"Calling stringFromColumn is only allowed in HasData state"];
		return NO;
	}	
	
	const void *data = sqlite3_column_blob(mStatement, index);
	if (data) {
		int length = sqlite3_column_bytes(mStatement, index);
		return [NSData dataWithBytes:data length:length];
	}
	
	return nil;
}

- (void) reset {
	if (mStatement) {
		[mDatabase lockQueryLock];
		sqlite3_reset(mStatement);
		sqlite3_clear_bindings(mStatement);
		[mDatabase unlockQueryLock];
		
		[self setState:eSQLiteQueryStatePrepared];
	}
}

- (int) columnCount {
	if ([self state] != eSQLiteQueryStateHasData) {
		[NSException raise:NSInternalInconsistencyException format:@"Calling columnCount is only allowed in HasData state"];
		return NO;
	}	
	
	return sqlite3_column_count(mStatement);
}

- (NSString *) nameOfResultColumn:(int)index {
	if ([self state] != eSQLiteQueryStateHasData) {
		[NSException raise:NSInternalInconsistencyException format:@"Calling nameOfResultColumn is only allowed in HasData state"];
		return NO;
	}
	
	const char *name = sqlite3_column_name(mStatement, index);
	if (name)
		return [NSString stringWithUTF8String:name];
	return nil;
}

- (id) appropriateCocoaResultTypeForColumn:(int)column {
	if ([self state] != eSQLiteQueryStateHasData) {
		[NSException raise:NSInternalInconsistencyException format:@"Calling appropriateCocoaResultTypeForColumn is only allowed in HasData state"];
		return NO;
	}
	
	const char *columnType = sqlite3_column_decltype(mStatement, column);
	if (columnType == NULL)
		return nil;
	
	if (!strcasecmp("TEXT", columnType)) {
		const unsigned char *result = sqlite3_column_text(mStatement, column);
		if (result != NULL)
			return [NSString stringWithUTF8String:(const char *)result];
		return nil;
	} else if (!strcasecmp("INTEGER", columnType))
		return [NSNumber numberWithInt:sqlite3_column_int(mStatement, column)];
	else if (!strcasecmp("BOOL", columnType))
		return [NSNumber numberWithBool:sqlite3_column_int(mStatement, column) == 1];
	else if (!strcasestr("BLOB", columnType)) {
		const void *data = sqlite3_column_blob(mStatement, column);
		if (data != NULL)
			return [NSData dataWithBytes:data length:sqlite3_column_bytes(mStatement, column)];
	}
	
	return nil;
}

@end
