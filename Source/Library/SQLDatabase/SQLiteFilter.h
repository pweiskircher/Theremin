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

typedef enum {
	eFilterUnknown,
	eFilterIsEqual,
	eFilterIsLike,
	eFilterIsNotEqual,
	eFilterIsNull
} SQLFilterMethods;

typedef enum {
	eFilterAnd,
	eFilterOr
} SQLFilterAndOr;

@interface SQLiteFilter : NSObject {
	NSString *mFilterKey;
	SQLFilterMethods mFilterMethod;
	NSArray *mFilter;
	SEL mFilterSelector;
	SQLFilterAndOr mAndOr;
	SQLFilterAndOr mNextFilterAndOr;
	NSString *mBelongsToSubGroup;
	BOOL mIsEndOfGroup;
}
+ (BOOL) applyFilters:(NSArray *)theFilters onString:(NSMutableString *)theString withValuesNeedingBinding:(NSMutableDictionary *)theBindings;
+ (NSString *) bindName;

+ (id) filterWithKey:(NSString *)theKey andMethod:(SQLFilterMethods)theMethod usingFilter:(NSArray *)theFilter;
+ (id) filterWithKey:(NSString *)theKey andMethod:(SQLFilterMethods)theMethod usingSingleFilter:(NSString *)theFilter;

- (id) initWithKey:(NSString *)theKey andMethod:(SQLFilterMethods)theMethod usingFilter:(NSArray *)theFilter;

- (void) dealloc;

- (void) setFilterSelector:(SEL)theSelector;
- (void) setFilterAndOr:(SQLFilterAndOr)aValue;

- (void) setBelongsToSubGroup:(NSString *)theSubGroup;
- (NSString *) belongsToSubGroup;

- (void) setIsEndOfGroup:(BOOL)aValue;
- (BOOL) isEndOfGroup;

- (void) setNextFilterAndOr:(SQLFilterAndOr)aValue;
- (SQLFilterAndOr) nextFilterAndOr;

- (NSString *) SQLStatementWithNeededBindings:(NSMutableDictionary *)neededBindings;

@end
