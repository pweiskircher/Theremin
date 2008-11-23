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

#import "SQLiteFilter.h"

static unsigned int gBindCounter;

@implementation SQLiteFilter
+ (BOOL) applyFilters:(NSArray *)theFilters onString:(NSMutableString *)theString withValuesNeedingBinding:(NSMutableDictionary *)theBindings {
	if ([theFilters count] == 0)
		return YES;
	
	BOOL whereAdded = NO;
	int statementAdded = 0;
	SQLFilterAndOr previousFilterNextFilterAndOr = eFilterAnd;
	NSMutableArray *activeSubGroups = [NSMutableArray array];
	
	for (int i = 0; i < [theFilters count]; i++) {
		BOOL addedAndOr = NO;
		SQLiteFilter *filter = [theFilters objectAtIndex:i];
		NSString *s = [filter SQLStatementWithNeededBindings:theBindings];
		if (s && [s length] > 0) {
			if (!whereAdded) {
				[theString appendString:@" WHERE ("];
				whereAdded = YES;
			}
			
			NSString *subgroup = [filter belongsToSubGroup];
			if (subgroup) {
				if ([activeSubGroups containsObject:subgroup] == NO) {
					
					if (statementAdded != 0) {
						switch (previousFilterNextFilterAndOr) {
							case eFilterAnd:
								[theString appendString:@" AND "];
								break;
								
							case eFilterOr:
								[theString appendString:@" OR "];
								break;
						}
						
						addedAndOr = YES;
					}
					
					[activeSubGroups addObject:subgroup];
					[theString appendString:@"("];
				} else {
					if ([subgroup isEqualToString:[activeSubGroups lastObject]] == NO) {
						int index = [activeSubGroups indexOfObject:subgroup];
						for (int j = 0; j < [activeSubGroups count] - (index+1); j++)
							[theString appendString:@")"];
						[activeSubGroups removeObjectsInRange:NSMakeRange(index+1,[activeSubGroups count]-1)];
					}
				}
			} else {
				for (int j = 0; j < [activeSubGroups count]; j++)
					[theString appendString:@")"];
				[activeSubGroups removeAllObjects];
			}
			
			if (statementAdded != 0 && addedAndOr == NO) {
				switch (previousFilterNextFilterAndOr) {
					case eFilterAnd:
						[theString appendString:@" AND "];
						break;
						
					case eFilterOr:
						[theString appendString:@" OR "];
						break;
				}
			}
			
			[theString appendString:s];
			
			if (subgroup != nil && [filter isEndOfGroup] && [[activeSubGroups lastObject] isEqualToString:subgroup]) {
				[activeSubGroups removeLastObject];
				[theString appendString:@")"];
			}
			
			previousFilterNextFilterAndOr = [[theFilters objectAtIndex:i] nextFilterAndOr];
			
			statementAdded++;
		}
	}
	
	if (whereAdded)
		[theString appendString:@")"];
	
	for (int j = 0; j < [activeSubGroups count]; j++)
		[theString appendString:@")"];
	
	return YES;
}

+ (NSString *) bindName {
	gBindCounter++;
	return [NSString stringWithFormat:@":SQLFLTBND%08d", gBindCounter];
}

+ (id) filterWithKey:(NSString *)theKey andMethod:(SQLFilterMethods)theMethod usingFilter:(NSArray *)theFilter {
	return [[[SQLiteFilter alloc] initWithKey:theKey andMethod:theMethod usingFilter:theFilter] autorelease];
}

+ (id) filterWithKey:(NSString *)theKey andMethod:(SQLFilterMethods)theMethod usingSingleFilter:(NSString *)theFilter {
	return [[[SQLiteFilter alloc] initWithKey:theKey andMethod:theMethod usingFilter:[NSArray arrayWithObject:theFilter]] autorelease];
}

- (id) initWithKey:(NSString *)theKey andMethod:(SQLFilterMethods)theMethod usingFilter:(NSArray *)theFilter {
	self = [super init];
	if (self != nil) {
		mFilterKey = [theKey retain];
		mFilterMethod = theMethod;
		mFilter = [theFilter retain];
		mFilterSelector = nil;
		mAndOr = eFilterOr;
		mNextFilterAndOr = eFilterAnd;
		mIsEndOfGroup = NO;
	}
	return self;
}

- (void) dealloc {
	[mBelongsToSubGroup release], mBelongsToSubGroup = nil;
	[mFilterKey release], mFilterKey = nil;
	[mFilter release], mFilter = nil;
	[super dealloc];
}

- (void) setFilterSelector:(SEL)theSelector {
	mFilterSelector = theSelector;
}

- (void) setFilterAndOr:(SQLFilterAndOr)aValue {
	mAndOr = aValue;
}

- (void) setNextFilterAndOr:(SQLFilterAndOr)aValue {
	mNextFilterAndOr = aValue;
}

- (SQLFilterAndOr) nextFilterAndOr {
	return mNextFilterAndOr;
}

- (void) setBelongsToSubGroup:(NSString *)theSubGroup {
	[mBelongsToSubGroup release], mBelongsToSubGroup = [theSubGroup retain];
}

- (NSString *) belongsToSubGroup {
	if (!mBelongsToSubGroup) return nil;
	return [[mBelongsToSubGroup retain] autorelease];
}

- (void) setIsEndOfGroup:(BOOL)aValue {
	mIsEndOfGroup = aValue;
}

- (BOOL) isEndOfGroup {
	return mIsEndOfGroup;
}

- (id) filterObjectAtIndex:(int)index {
	id object = [mFilter objectAtIndex:index];
	if (mFilterSelector) {
		if ([object respondsToSelector:mFilterSelector] == NO)
			return nil;
		object = [object performSelector:mFilterSelector];
	}
	
	return object;
}

- (BOOL) filterObjectsAreNumbers {
	if ([mFilter count] == 0)
		return NO;
	
	if ([[self filterObjectAtIndex:0] isKindOfClass:[NSNumber class]])
		return YES;
	return NO;
}

- (NSString *) SQLStatementWithNumberAndEquals {
	NSMutableString *s = [NSMutableString string];
	
	[s appendFormat:@"(%@ ", mFilterKey];
	if (mFilterMethod == eFilterIsEqual)
		[s appendFormat:@"in "];
	else if (mFilterMethod == eFilterIsNotEqual)
		[s appendFormat:@"not in "];
	
	[s appendFormat:@"("];
	
	for (int i = 0; i < [mFilter count]; i++) {
		if (i > 0) [s appendFormat:@","];
		[s appendFormat:@"%d", [[self filterObjectAtIndex:i] intValue]];
	}
	
	[s appendFormat:@"))"];
	return s;
}

- (NSString *) SQLStatementWithNeededBindings:(NSMutableDictionary *)neededBindings {
	if ((mFilterMethod == eFilterIsEqual || mFilterMethod == eFilterIsNotEqual) && [self filterObjectsAreNumbers])
		return [self SQLStatementWithNumberAndEquals];
	
	NSMutableString *s = [NSMutableString string];
	
	[s appendString:@"("];
	for (int i = 0; i < [mFilter count]; i++) {
		if (i != 0) {
			switch (mAndOr) {
				case eFilterAnd:
					[s appendString:@" AND "];
					break;
				case eFilterOr:
					[s appendString:@" OR "];
					break;
			}
		}
		
		[s appendFormat:@"(%@ ", mFilterKey];
	
		switch (mFilterMethod) {
			case eFilterUnknown:
				return nil;
			case eFilterIsLike:
				[s appendString:@"LIKE "];
				break;
				
			case eFilterIsEqual:
				[s appendString:@"= "];
				break;
				
			case eFilterIsNotEqual:
				[s appendString:@"!= "];
				break;
				
			case eFilterIsNull:
				[s appendString:@"is null)"];
				continue;
		}
		
		
		NSString *bindName = [SQLiteFilter bindName];
		[s appendFormat:@"%@)", bindName];
		
		id object = [self filterObjectAtIndex:i];
		if (object == nil) return nil;
		
		[neededBindings setObject:object forKey:bindName];
	}
	[s appendString:@")"];
	
	return [NSString stringWithString:s];
}

@end
