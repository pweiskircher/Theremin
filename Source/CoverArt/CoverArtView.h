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

#import <Cocoa/Cocoa.h>

#import "CoverViewerController.h"

extern NSString *nCoverArtViewFoundBuyURL;

typedef enum {
	eCoverArtSmall,
	eCoverArtMedium,
	eCoverArtLarge
} CoverArtSize;

@class Song;

@interface CoverArtView : NSView {
	NSImage *mCoverImage;
	NSImage *mNoCoverAvailableImage;
	NSSize mImageSize;
	
	Song *mSong;
	
	CoverArtSize mCoverArtSize;
	CoverViewerController *mCoverViewerController;
	
	BOOL mClickable;
	BOOL mAllowDrag;
	
	NSURL *mBuyURL;
	
	NSProgressIndicator *mIndicator;
}
- (id) initWithFrame:(NSRect)aFrame;
- (void) dealloc;

- (void) setIsClickable:(BOOL)aValue;
- (void) setAllowsDrag:(BOOL)aValue;

- (void) showCoverForSong:(Song *)aSong;

// this isn't nice ... optimal solution is one object who fetches information from
// amazon for a song and another one who fetches the image, ... I'm too lazy.
- (NSURL *) buyURL;

@end
