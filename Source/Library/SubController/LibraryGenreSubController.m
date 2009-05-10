//
//  LibraryGenreSubController.m
//  Theremin
//
//  Created by Patrik Weiskircher on 02.06.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LibraryGenreSubController.h"
#import "LibraryIdFilter.h"
#import "SQLController.h"

@implementation LibraryGenreSubController
- (void) addRequiredFilters:(NSMutableArray *)filters {
	BOOL allGenresSelected = NO;
	NSArray *genres = [self getSelected:&allGenresSelected];
	
	if (allGenresSelected == NO && [genres count] > 0)
		[filters addObject:[[[LibraryIdFilter alloc] initWithType:eLibraryIdFilterGenre
														   andIds:genres] autorelease]];
}

- (void) requestFilteredItems:(NSArray *)filters {
	[[self libraryDataSource] requestGenresWithFilters:filters reportToTarget:self andSelector:@selector(receivedResults:)];
}

- (NSString *) getDisplayTitleOfAllItem {
	return [NSString stringWithFormat:@"All (%d Genre%s)", [mItems count], [mItems count] == 1 ? "" : "s"];
}

- (NSString *)liveSearchColumn {
	return @"Genre";
}
@end
