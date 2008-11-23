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

#import "LibrarySearchController.h"
#import "LibraryStringFilter.h"
#import "LibraryFilterGroup.h"
#import "PWMusicSearchField.h"
#import "NSStringAdditions.h"

@implementation LibrarySearchController

- (id) init
{
	self = [super init];
	if (self != nil) {
		NSRect frame = NSMakeRect(0,0,150,30);
		
		mSearchField = [[PWMusicSearchField alloc] initWithFrame:frame];
		[mSearchField setTarget:self];
		[mSearchField setAction:@selector(searchAction:)];
		[mSearchField setSearchFlagsAutosaveName:@"librarySearchField"];		
	}
	return self;
}

- (void) dealloc
{
	[mSearchField release];
	[mSearchString release];
	[super dealloc];
}

- (NSMutableArray *) musicSearchFilters {
	NSMutableArray *filters = [NSMutableArray array];
	
	if (mSearchString == nil || [mSearchString length] == 0)
		return nil;
	
	NSArray *tokens = [mSearchString parseIntoTokens];
	if ([tokens count] == 0)
		return nil;
	
	LibraryFilterGroup *group = [[[LibraryFilterGroup alloc] initWithMode:eLibraryFilterGroupOr] autorelease];
	[filters addObject:group];
	
	MusicFlags state = [mSearchField searchState];
		
	if (state == eMusicFlagsAll || state == eMusicFlagsAlbum)
		[group addFilter:[[[LibraryStringFilter alloc] initWithType:eLibraryStringFilterAlbum
														 andStrings:tokens] autorelease]];
		 
	if (state == eMusicFlagsAll || state == eMusicFlagsTitle)
		[group addFilter:[[[LibraryStringFilter alloc] initWithType:eLibraryStringFilterSong
														 andStrings:tokens] autorelease]];

	if (state == eMusicFlagsAll || state == eMusicFlagsArtist)
		 [group addFilter:[[[LibraryStringFilter alloc] initWithType:eLibraryStringFilterArtist
														  andStrings:tokens] autorelease]];
	
	return filters;
}

- (void) setDelegate:(id)delegate {
	mDelegate = delegate;
}

- (void) searchAction:(id)sender {
	if ([[sender stringValue] length] > 0) {
		[mSearchString release], mSearchString = [[sender stringValue] retain];
	} else {
		[mSearchString release], mSearchString = nil;
	}
	
	[mDelegate initiateSearch];
}

- (void) stopSearch:(id)sender {
	[mSearchField setStringValue:@""];
	[self searchAction:mSearchField];
}

- (PWMusicSearchField *) searchField {
	return [[mSearchField retain] autorelease];
}

@end
