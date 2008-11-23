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
#import "SQLiteFilter.h"
#import "SQLController.h"
#import "Artist.h"

@implementation LibraryArtistSubController
- (void) addRequiredFilters:(NSMutableArray *)filters {
	BOOL allArtistsSelected = NO;
	NSArray *artists = [self getSelected:&allArtistsSelected];
	
	if (allArtistsSelected == NO) {
		SQLiteFilter *filter;
		BOOL addArtistFilter = YES;
		BOOL compilationSelected = NO;
		
		for (int i = 0; i < [artists count]; i++) {
			Artist *artist = [artists objectAtIndex:i];
			if ([artist SQLIdentifier] == CompilationSQLIdentifier) {
				compilationSelected = YES;
				break;
			}
		}
		
		if (compilationSelected == NO) {
			filter = [SQLiteFilter filterWithKey:@"songs.isCompilation" andMethod:eFilterIsNotEqual usingFilter:
					  [NSArray arrayWithObject:[NSNumber numberWithInt:1]]];
			[filter setBelongsToSubGroup:@"COMPILATIONFILTER"];
			[filters addObject:filter];
		} else {
			// only compilations selected
			if ([artists count] == 1) {
				filter = [SQLiteFilter filterWithKey:@"songs.isCompilation" andMethod:eFilterIsEqual usingFilter:
						  [NSArray arrayWithObject:[NSNumber numberWithInt:1]]];
				[filter setBelongsToSubGroup:@"COMPILATIONFILTER"];
				[filters addObject:filter];
				addArtistFilter = NO;
			} else {
				filter = [SQLiteFilter filterWithKey:@"songs.isCompilation" andMethod:eFilterIsEqual usingFilter:
						  [NSArray arrayWithObject:[NSNumber numberWithInt:1]]];
				[filter setBelongsToSubGroup:@"COMPILATIONFILTER"];
				[filter setNextFilterAndOr:eFilterOr];
				[filters addObject:filter];
			}
		}
		
		if (addArtistFilter) {
			filter = [SQLiteFilter filterWithKey:@"songs.artist" andMethod:eFilterIsEqual usingFilter:artists];
			[filter setFilterAndOr:eFilterOr];
			[filter setFilterSelector:@selector(CocoaSQLIdentifier)];
			[filter setBelongsToSubGroup:@"ARTISTFILTER"];
			
			[filters addObject:filter];
		}
	}
}

- (NSArray *) getFilteredItems:(NSArray *)filters {
	return [[SQLController defaultController] artistsWithFilters:filters];
}

- (NSString *) getDisplayTitleOfAllItem {
	return [NSString stringWithFormat:@"All (%d Artist%s)", [mItems count], [mItems count] == 1 ? "" : "s"];
}

- (NSString *)liveSearchColumn {
	return @"Artist";
}

@end