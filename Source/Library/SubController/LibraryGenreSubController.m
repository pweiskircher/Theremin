//
//  LibraryGenreSubController.m
//  Theremin
//
//  Created by Patrik Weiskircher on 02.06.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LibraryGenreSubController.h"
#import "SQLiteFilter.h"
#import "SQLController.h"

@implementation LibraryGenreSubController
- (void) addRequiredFilters:(NSMutableArray *)filters {
	BOOL allGenresSelected = NO;
	NSArray *genres = [self getSelected:&allGenresSelected];
	
	if (allGenresSelected == NO && [genres count] > 0) {
		SQLiteFilter *filter = [SQLiteFilter filterWithKey:@"songs.genre" andMethod:eFilterIsEqual usingFilter:genres];
		[filter setFilterAndOr:eFilterOr];
		[filter setFilterSelector:@selector(CocoaSQLIdentifier)];
		
		[filters addObject:filter];		
	}
}

- (NSArray *) getFilteredItems:(NSArray *)filters {
	return [[SQLController defaultController] genresWithFilters:filters];
}

- (NSString *) getDisplayTitleOfAllItem {
	return [NSString stringWithFormat:@"All (%d Genre%s)", [mItems count], [mItems count] == 1 ? "" : "s"];
}

- (NSString *)liveSearchColumn {
	return @"Genre";
}
@end
