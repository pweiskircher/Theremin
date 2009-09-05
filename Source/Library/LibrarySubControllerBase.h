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

#import <Cocoa/Cocoa.h>

@class LibraryController;

#import "PWTableView.h"
#import "LibraryDataSource.h"

@interface LibrarySubControllerBase : NSObject {
	IBOutlet PWTableView *mTableView;
	IBOutlet LibraryController *mLibraryController;
	
	BOOL mHasAllEntry;
	BOOL mIgnoreSelectionChanged;
	BOOL mInvalidateCurrentSelection;
	
	id mSelectionData;
	
	NSArray *mItems;
	
	id<LibraryDataSourceProtocol> _libraryDataSource;
}
- (id) initWithTableView:(PWTableView *)aTableView
	andLibraryController:(LibraryController *)aLibraryController
		  andHasAllEntry:(BOOL)allEntry;

- (NSArray *) getSelected:(BOOL*)allSelected;
- (void) reloadData;

- (void) clearAndDisable;
- (void) enable;

- (void) addRequiredFilters:(NSMutableArray *)filters;
- (void) requestFilteredItems:(NSArray *)filters;
- (NSString *) getDisplayTitleOfAllItem;
- (NSArray *) sortedArray:(NSArray *)items;

- (id<LibraryDataSourceProtocol>) libraryDataSource;

- (void) receivedResults:(NSArray *)items;
@end

