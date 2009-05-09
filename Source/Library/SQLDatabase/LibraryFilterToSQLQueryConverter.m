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

#import "LibraryFilterToSQLQueryConverter.h"

#import "LibraryIdFilter.h"
#import "LibraryStringFilter.h"
#import "LibraryBooleanFilter.h"
#import "LibraryFilterGroup.h"
#import "SQLUniqueIdentifiersFilter.h"

#import "Artist.h"

const NSString *cNotProcessedException = @"cNotProcessedException";
static unsigned int gBindCounter;

@interface LibraryFilterToSQLQueryConverter (PrivateMethods)
- (NSString *) processFilters:(NSArray *)someFilters usingConcatinator:(NSString *)aConcatinator;

- (NSString *) processIdFilter:(LibraryIdFilter *)aFilter;
- (NSString *) processStringFilter:(LibraryStringFilter *)aFilter;
- (NSString *) processBooleanFilter:(LibraryBooleanFilter *)aFilter;
- (NSString *) processUniqueIdentifiersFilter:(SQLUniqueIdentifiersFilter *)aFilter;

- (NSString *) bindWildcardedString:(NSString *)string;
- (NSString *) bindData:(NSData *)data;

+ (NSString *) bindName;
@end

@implementation LibraryFilterToSQLQueryConverter
+ (NSString *) bindName {
	gBindCounter++;
	return [NSString stringWithFormat:@":SQLFLTBND%08d", gBindCounter];
}

- (id) initWithLibraryFilters:(NSArray *)someFilters {
	self = [super init];
	if (self != nil) {
		_libraryFilters = [someFilters retain];
		_boundValues = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (void) dealloc
{
	[_libraryFilters release];
	[_whereClause release];
	[_boundValues release];
	[super dealloc];
}

- (void) process {
	[_boundValues removeAllObjects];
	
	[_whereClause release];
	_whereClause = [[self processFilters:_libraryFilters usingConcatinator:@" AND "] retain];
	_processed = YES;
}

- (NSString *) processFilters:(NSArray *)someFilters usingConcatinator:(NSString *)aConcatinator {
	NSMutableString *whereClause = [NSMutableString stringWithString:@"("];
	
	for (int i = 0; i < [someFilters count]; i++) {
		id filter = [someFilters objectAtIndex:i];
		
		NSString *token;
		if ([filter isKindOfClass:[LibraryIdFilter class]]) {
			token = [self processIdFilter:filter];
		} else if ([filter isKindOfClass:[LibraryStringFilter class]]) {
			token = [self processStringFilter:filter];
		} else if ([filter isKindOfClass:[LibraryBooleanFilter class]]) {
			token = [self processBooleanFilter:filter];
		} else if ([filter isKindOfClass:[LibraryFilterGroup class]]) {
			LibraryFilterGroup *group = filter;
			NSString *concat = [group mode] == eLibraryFilterGroupAnd ? @" AND " : @" OR ";
			token = [self processFilters:[group filters] usingConcatinator:concat];
		} else if ([filter isKindOfClass:[SQLUniqueIdentifiersFilter class]]) {
			token = [self processUniqueIdentifiersFilter:filter];
		}
		
		if (i > 0) [whereClause appendString:aConcatinator];
		[whereClause appendString:token];
	}
	
	[whereClause appendString:@")"];
	
	return whereClause;
}

- (NSString *) whereClause {
	if (!_processed) [LibraryFilterToSQLQueryConverterException raise:(NSString *)cNotProcessedException format:@"Filters not processed yet"];
	return [[_whereClause retain] autorelease];
}

- (NSDictionary *) boundValues {
	if (!_processed) [LibraryFilterToSQLQueryConverterException raise:(NSString *)cNotProcessedException format:@"Filters not processed yet"];
	return [NSDictionary dictionaryWithDictionary:_boundValues];
}



- (NSString *) processIdFilter:(LibraryIdFilter *)aFilter {
	NSMutableString *whereClause = [NSMutableString stringWithString:@"("];

	switch ([aFilter type]) {
		case eLibraryIdFilterArtist: [whereClause appendString:@"songs.artist"]; break;
		case eLibraryIdFilterAlbum:  [whereClause appendString:@"songs.album"]; break;
		case eLibraryIdFilterGenre:  [whereClause appendString:@"songs.genre"]; break;
	}
	
	[whereClause appendString:@" IN ("];
	
	NSArray *ids = [aFilter ids];
	for (int i = 0; i < [ids count]; i++) {
		if (i > 0) [whereClause appendString:@","];
		[whereClause appendFormat:@"%d", [[ids objectAtIndex:i] identifier]];
	}
	
	[whereClause appendFormat:@") )"];
	return whereClause;
}

- (NSString *) processStringFilter:(LibraryStringFilter *)aFilter {
	NSMutableString *whereClause = [NSMutableString stringWithString:@"("];

	// if no title, search filename.
	if ([aFilter type] == eLibraryStringFilterSong) {
		NSArray *tokens = [aFilter strings];
		for (int i = 0; i < [tokens count]; i++) {
			if (i > 0) [whereClause appendString:@" AND "];
			
			NSString *bindName = [self bindWildcardedString:[tokens objectAtIndex:i]];
			[whereClause appendFormat:
			 @"(songs.title LIKE %@ OR ", bindName];
			
			[whereClause appendFormat:
			 @"(songs.title IS NULL AND songs.file LIKE %@) ) ", bindName];
		}
	} else {
		NSString *source;
		if ([aFilter type] == eLibraryStringFilterArtist)
			source = @"artists.name";
		else if ([aFilter type] == eLibraryStringFilterAlbum)
			source = @"albums.name";
		
		NSArray *tokens = [aFilter strings];
		for (int i = 0; i < [tokens count]; i++) {
			if (i > 0) [whereClause appendString:@" AND "];

			[whereClause appendFormat:
			 @"(%@ LIKE %@)", source, [self bindWildcardedString:[tokens objectAtIndex:i]]];
		}
	}
	
	[whereClause appendString:@")"];
	return whereClause;
}

- (NSString *) processBooleanFilter:(LibraryBooleanFilter *)aFilter {
	NSMutableString *whereClause = [NSMutableString stringWithString:@"("];
	
	switch ([aFilter type]) {
		case eLibraryBooleanIsCompilation: [whereClause appendString:@"songs.isCompilation"]; break;
	}
	
	if ([aFilter mode])
		[whereClause appendString:@" = 1"];
	else
		[whereClause appendString:@" != 1"];
	
	[whereClause appendString:@")"];
	
	return whereClause;
}

- (NSString *) processUniqueIdentifiersFilter:(SQLUniqueIdentifiersFilter *)aFilter {
	NSMutableString *whereClause = [NSMutableString stringWithString:@"("];
	
	for (int i = 0; i < [[aFilter uniqueIdentifiers] count]; i++) {
		if (i > 0) [whereClause appendString:@" OR "];
		[whereClause appendFormat:@"songs.uniqueIdentifier = %@", [self bindData:[[aFilter uniqueIdentifiers] objectAtIndex:i]]];
	}
	
	[whereClause appendString:@")"];
	return whereClause;
}

- (NSString *) bindWildcardedString:(NSString *)string {
	NSString *bindName = [LibraryFilterToSQLQueryConverter bindName];
	[_boundValues setObject:[NSString stringWithFormat:@"%%%@%%%", string] forKey:bindName];
	return bindName;
}

- (NSString *) bindData:(NSData *)data {
	NSString *bindName = [LibraryFilterToSQLQueryConverter bindName];
	[_boundValues setObject:data forKey:bindName];
	return bindName;
}

@end

@implementation LibraryFilterToSQLQueryConverterException
@end
