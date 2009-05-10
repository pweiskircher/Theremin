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

#import "LibrarySongSubController.h"
#import "SQLController.h"
#import "Song.h"
#import "LibraryIdFilter.h"

@implementation LibrarySongSubController
- (void) requestFilteredItems:(NSArray *)filters {
	BOOL fetchTitles = YES;
	
	if (!([_libraryDataSource supportsDataSourceCapabilities] & eLibraryDataSourceSupportsMultipleSelection)) {
		// as the squeezecenter is pretty slow, we only show titles if we can limit them to one album or one artist.
		fetchTitles = NO;
		for (int i = 0; i < [filters count]; i++) {
			id filter = [filters objectAtIndex:i];
			
			if ([filter isKindOfClass:[LibraryIdFilter class]]) {
				LibraryIdFilter *idFilter = (LibraryIdFilter *)filter;
				if ([idFilter type] == eLibraryIdFilterAlbum ||
					[idFilter type] == eLibraryIdFilterArtist) {
					fetchTitles = YES;
					break;					
				}
			}
		}		
	}
	
	if (fetchTitles)
		[[self libraryDataSource] requestSongsWithFilters:filters reportToTarget:self andSelector:@selector(receivedResults:)];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"length"]) {
		int time = [[[mItems objectAtIndex:rowIndex] valueForKey:@"time"] intValue];
		return [NSString stringWithFormat:@"%d:%02d", time / 60, time % 60];
	} else if ([[aTableColumn identifier] isEqualToString:@"artist.name"]) {
		return [[mItems objectAtIndex:rowIndex] artist];
	} else if ([[aTableColumn identifier] isEqualToString:@"album.name"]) {
		return [[mItems objectAtIndex:rowIndex] album];
	} else if ([[aTableColumn identifier] isEqualToString:@"title"]) {
		NSString *title = [[mItems objectAtIndex:rowIndex] title];
		if (title == nil || [title length] == 0)
			return [[[mItems objectAtIndex:rowIndex] file] lastPathComponent];
		else
			return title;
	}
	
	return [[mItems objectAtIndex:rowIndex] valueForKeyPath:[aTableColumn identifier]];
}

- (NSArray *)allItems {
	return [[mItems retain] autorelease];
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	mItems = [[mItems sortedArrayUsingDescriptors:[aTableView sortDescriptors]] retain];
	[aTableView reloadData];
}

- (NSString *)liveSearchColumn {
	return @"title";
}

- (void) customTableViewSetup {
	if ([[mTableView sortDescriptors] count] == 0) {
		NSArray *array = [NSArray arrayWithObjects:
						  [[[NSSortDescriptor alloc] initWithKey:@"album" ascending:YES selector:@selector(artistCompare:)] autorelease],
						  [[[NSSortDescriptor alloc] initWithKey:@"disc" ascending:YES selector:@selector(numericCompare:)] autorelease],
						  [[[NSSortDescriptor alloc] initWithKey:@"track" ascending:YES selector:@selector(numericCompare:)] autorelease],
						  nil];
		[mTableView setSortDescriptors:array];
	}
	
	[mTableView enableCustomizableColumnsWithAutosaveName:@"SongLibraryTableInfos"];
}

- (NSArray *) sortedArray:(NSArray *)items {
	return [items sortedArrayUsingDescriptors:[mTableView sortDescriptors]];
}
@end
