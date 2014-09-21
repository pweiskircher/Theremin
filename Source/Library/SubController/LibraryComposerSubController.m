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

#import "LibraryComposerSubController.h"
#import "SQLController.h"
#import "LibraryIdFilter.h"
#import "LibraryBooleanFilter.h"
#import "LibraryFilterGroup.h"
#import "Composer.h"

@implementation LibraryComposerSubController
- (void) addRequiredFilters:(NSMutableArray *)filters {
	BOOL allComposersSelected = NO;
	BOOL addComposersFilter = YES;
	LibraryFilterGroup *group = nil;
	
	NSArray *composers = [self getSelected:&allComposersSelected];
	
	if (allComposersSelected == NO) {
		if ([[self libraryDataSource] supportsDataSourceCapabilities] & eLibraryDataSourceSupportsCustomCompilations) {
			BOOL compilationSelected = NO;
			
			for (int i = 0; i < [composers count]; i++) {
				Composer *composer = [composers objectAtIndex:i];
				if ([composer identifier] == CompilationSQLIdentifier) {
					compilationSelected = YES;
					break;
				}
			}
			
			if (compilationSelected && [composers count] > 1)
				group = [[[LibraryFilterGroup alloc] initWithMode:eLibraryFilterGroupOr] autorelease];
			else
				group = [[[LibraryFilterGroup alloc] initWithMode:eLibraryFilterGroupAnd] autorelease];
			[filters addObject:group];

			// if compilations are selected, we only want compilation results selected.
			[group addFilter:[[[LibraryBooleanFilter alloc] initWithType:eLibraryBooleanIsCompilation
															andIncludeTrue:compilationSelected] autorelease]];

			// if there's only one composer selected, and that one is our fake-compilation artist, we don't need a artist filter.
			if (compilationSelected == YES && [composers count] == 1)
				addComposersFilter = NO;
		}
		
		if (addComposersFilter && [composers count] > 0) {
			LibraryIdFilter *composersFilter = [[[LibraryIdFilter alloc] initWithType:eLibraryIdFilterComposer andIds:composers] autorelease];
			if (group)
				[group addFilter:composersFilter];
			else
				[filters addObject:composersFilter];
		}
	}
}

- (void) requestFilteredItems:(NSArray *)filters {
	[[self libraryDataSource] requestComposersWithFilters:filters reportToTarget:self andSelector:@selector(receivedResults:)];
}

- (NSString *) getDisplayTitleOfAllItem {
	return [NSString stringWithFormat:@"All (%@ Composer%s)", [NSNumber numberWithUnsignedInteger:[mItems count]], [mItems count] == 1 ? "" : "s"];
}

- (NSString *)liveSearchColumn {
	return @"Composer";
}

@end