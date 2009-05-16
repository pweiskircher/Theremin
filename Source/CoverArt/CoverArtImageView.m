/*
 Copyright (C) 2009  Patrik Weiskircher
 
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

#import "CoverArtImageView.h"
#import "Song.h"

@implementation CoverArtImageView
- (void) setDataSourceClass:(Class)theDataSourceClass {
	_dataSourceClass = theDataSourceClass;
}

- (void) setFallbackImage:(NSImage *)theFallbackImage {
	[_fallbackImage release];
	_fallbackImage = [theFallbackImage retain];
	
	[self setImage:_fallbackImage];
}

- (void) setRequestImageSize:(CoverArtSize)aSize {
	_size = aSize;
}

- (void) updateWithSong:(Song *)aSong {
	if (_dataSourceClass == nil)
		return;
	
	[_currentSong release];
	_currentSong = [aSong retain];
	
	id<CoverArtDataSourceProtocol> dataSource = [[_dataSourceClass alloc] init];
	[dataSource requestImageForSong:aSong withSize:CoverArtSizeSmall forDelegate:self];
}

- (void) dataSource:(id<CoverArtDataSourceProtocol>)theDataSource foundImage:(NSImage *)theImage forSong:(Song *)theSong withSize:(CoverArtSize)theSize {
	[theDataSource autorelease];
	if ([_currentSong isEqual:theSong])
		[self setImage:theImage];
}

- (void) dataSourceFailedToGetImage:(id<CoverArtDataSourceProtocol>)theDataSource {
	[theDataSource autorelease];
	[self setImage:_fallbackImage];
}

- (void) clear {
	[self setImage:[NSImage imageNamed:@"empty"]];
}
@end
