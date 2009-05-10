/*
 Copyright (C) 2006-2008  Patrik Weiskircher
 
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

#import "CompilationDetector.h"
#import "SQLController.h"
#import "Song.h"

@implementation CompilationDetector

- (id) initWithDataSource:(id<LibraryDataSourceProtocol>)aDataSource andDelegate:(id)aDelegate {
	self = [super init];
	if (self != nil) {
		_dataSource = [aDataSource retain];
		_delegate = aDelegate;
	}
	return self;
}

- (void) dealloc
{
	[_dataSource release];
	[super dealloc];
}

+ (NSArray *) compilationSongsOfAlbumSongs:(NSArray *)songs {
	// a compilation is usually kept in one directory - so sort by directory and go from there
	
	NSArray *filenameSorted = [songs sortedArrayUsingDescriptors:[NSArray arrayWithObject:
																  [[[NSSortDescriptor alloc] initWithKey:@"file" ascending:YES] autorelease]]];
	Song *song;
	NSString *previousDirectory = nil;
	NSEnumerator *enumerator = [filenameSorted objectEnumerator];
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSMutableArray *array = [NSMutableArray array];
	NSMutableArray *result = nil;
	
	while (song = [enumerator nextObject]) {
		NSString *directory = [[song file] stringByDeletingLastPathComponent];
		if (previousDirectory != nil && [directory isEqualToString:previousDirectory] == NO) {
			// in this directory we still have more than 2 artists. mark it as a compilation
			if ([dict count] > 2) {
				if (!result) result = [NSMutableArray array];
				[result addObjectsFromArray:array];
			}
			
			[array removeAllObjects];
			[dict removeAllObjects];
			previousDirectory = nil;
		}
		
		previousDirectory = directory;
		[array addObject:song];
		
		NSNumber *number = [dict objectForKey:[song artist]];
		if (!number) [dict setObject:[NSNumber numberWithInt:1] forKey:[song artist]];
		else {
			number = [NSNumber numberWithInt:[number intValue]+1];
			[dict setObject:number forKey:[song artist]];
		}
	}
	
	if (previousDirectory != nil) {
		// in this directory we still have more than 2 artists. mark it as a compilation
		if ([dict count] > 2) {
			if (!result) result = [NSMutableArray array];
			[result addObjectsFromArray:array];
		}
		
		[array removeAllObjects];
		[dict removeAllObjects];
	}
	
	return result;
}

- (void) start {
	if (!([_dataSource supportsDataSourceCapabilities] & eLibraryDataSourceSupportsCustomCompilations))
		[NSException raise:NSInternalInconsistencyException format:@"This datasource doesn't support custom compilations."];
	[_dataSource requestSongsWithFilters:nil reportToTarget:self andSelector:@selector(dataSourceResults:)];
}

- (void) dataSourceResults:(NSArray *)results {
	NSArray *songs = [results sortedArrayUsingDescriptors:
					  [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"album" ascending:YES] autorelease]]];
	Song *song;
	NSString *previousAlbum = nil;
	NSEnumerator *enumerator = [songs objectEnumerator];
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSMutableArray *array = [NSMutableArray array];
	NSMutableArray *result = [NSMutableArray array];
	
	while (song = [enumerator nextObject]) {
		if ([song albumIsUnknown] || [song artistIsUnknown])
			continue;
		
		if (previousAlbum != nil && [[song album] isEqualToString:previousAlbum] == NO) {
			// we have more than 2 artists in that album.. do a bit more detective work on that
			if ([dict count] > 2) {
				NSArray *tmp = [CompilationDetector compilationSongsOfAlbumSongs:array];
				if (tmp) [result addObjectsFromArray:tmp];
			}
			[dict removeAllObjects];
			[array removeAllObjects];
			previousAlbum = nil;
		}
		
		previousAlbum = [song album];
		[array addObject:song];
		
		NSNumber *number = [dict objectForKey:[song artist]];
		if (!number) [dict setObject:[NSNumber numberWithInt:1] forKey:[song artist]];
		else {
			number = [NSNumber numberWithInt:[number intValue]+1];
			[dict setObject:number forKey:[song artist]];
		}
	}
	
	if (previousAlbum != nil) {
		// we have more than 2 artists in that album.. do a bit more detective work on that
		if ([dict count] > 2) {
			NSArray *tmp = [CompilationDetector compilationSongsOfAlbumSongs:array];
			if (tmp) [result addObjectsFromArray:tmp];
		}
		
		[dict removeAllObjects];
		[array removeAllObjects];
	}
	
	[_dataSource setSongsAsCompilation:result];
	[_delegate compilationDetectorFinished:self];
}

@end
