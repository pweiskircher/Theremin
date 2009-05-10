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

#import "LibraryArtistSubController.h"
#import "SQLController.h"
#import "LibraryIdFilter.h"
#import "LibraryBooleanFilter.h"
#import "LibraryFilterGroup.h"
#import "Artist.h"

@implementation LibraryArtistSubController
- (void) addRequiredFilters:(NSMutableArray *)filters {
	BOOL allArtistsSelected = NO;
	BOOL addArtistsFilter = YES;
	LibraryFilterGroup *group = nil;
	
	NSArray *artists = [self getSelected:&allArtistsSelected];
	
	if (allArtistsSelected == NO) {
		if ([[self libraryDataSource] supportsDataSourceCapabilities] & eLibraryDataSourceSupportsCustomCompilations) {
			BOOL compilationSelected = NO;
			
			for (int i = 0; i < [artists count]; i++) {
				Artist *artist = [artists objectAtIndex:i];
				if ([artist identifier] == CompilationSQLIdentifier) {
					compilationSelected = YES;
					break;
				}
			}
			
			if (compilationSelected && [artists count] > 1)
				group = [[[LibraryFilterGroup alloc] initWithMode:eLibraryFilterGroupOr] autorelease];
			else
				group = [[[LibraryFilterGroup alloc] initWithMode:eLibraryFilterGroupAnd] autorelease];
			[filters addObject:group];

			// if compilations are selected, we only want compilation results selected.
			[group addFilter:[[[LibraryBooleanFilter alloc] initWithType:eLibraryBooleanIsCompilation
															andIncludeTrue:compilationSelected] autorelease]];

			// if there's only one artist selected, and that one is our fake-compilation artist, we don't need a artist filter.
			if (compilationSelected == YES && [artists count] == 1)
				addArtistsFilter = NO;
		}
		
		if (addArtistsFilter && [artists count] > 0) {
			LibraryIdFilter *artistsFilter = [[[LibraryIdFilter alloc] initWithType:eLibraryIdFilterArtist andIds:artists] autorelease];
			if (group)
				[group addFilter:artistsFilter];
			else
				[filters addObject:artistsFilter];			
		}
	}
}

- (void) requestFilteredItems:(NSArray *)filters {
	[[self libraryDataSource] requestArtistsWithFilters:filters reportToTarget:self andSelector:@selector(receivedResults:)];
}

- (NSString *) getDisplayTitleOfAllItem {
	return [NSString stringWithFormat:@"All (%d Artist%s)", [mItems count], [mItems count] == 1 ? "" : "s"];
}

- (NSString *)liveSearchColumn {
	return @"Artist";
}

@end