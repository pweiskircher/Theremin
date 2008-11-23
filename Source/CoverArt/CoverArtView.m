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

#import "CoverArtView.h"
#import "Song.h"
#import "PreferencesController.h"
#import "AWSController.h"

NSString *nCoverArtViewFoundBuyURL = @"nCoverArtViewFoundBuyURL";

@implementation CoverArtView
- (id) initWithFrame:(NSRect)aFrame {
	self = [super initWithFrame:aFrame];
	if (self != nil) {
		mImageSize = NSMakeSize(aFrame.size.width - 2, aFrame.size.height - 2);
		
		mNoCoverAvailableImage = [[NSImage imageNamed:@"FallbackCover"] copyWithZone:nil];
		[mNoCoverAvailableImage setScalesWhenResized:YES];
		[mNoCoverAvailableImage setSize:mImageSize];
		
		if (aFrame.size.width <= 70)
			mCoverArtSize = eCoverArtSmall;
		else if (aFrame.size.width <= 160)
			mCoverArtSize = eCoverArtMedium;
		else
			mCoverArtSize = eCoverArtLarge;
		
		mClickable = NO;
		mAllowDrag = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(localeChanged:)
													 name:nCoverArtLocaleChanged
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fetchedImage:)
													 name:nFetchedSmallImageForSong
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fetchedImage:)
													 name:nFetchedMediumImageForSong
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fetchedImage:)
													 name:nFetchedLargeImageForSong
												   object:nil];
		
		NSRect indicatorSize;
		if (aFrame.size.width > 70) {
			if (aFrame.size.width <= 160) {
				indicatorSize = NSMakeRect((aFrame.size.width/2)-16,(aFrame.size.width/2)-16,32,32);
			} else
				indicatorSize = NSMakeRect(5,5,32,32);
			
			NSProgressIndicator *indicator = [[[NSProgressIndicator alloc] initWithFrame:indicatorSize] autorelease];
			[indicator setStyle:NSProgressIndicatorSpinningStyle];
			[self addSubview:indicator];
			[indicator setIndeterminate:YES];
			[indicator setDisplayedWhenStopped:NO];
			
			mIndicator = indicator;
		} else
			mIndicator = nil;
	}
	return self;
}

- (void) dealloc {
	[mCoverImage release];
	[mNoCoverAvailableImage release];
	[mSong release];
	[mCoverViewerController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void) localeChanged:(NSNotification *)aNotification {
	if (mSong && [[self window] isVisible]) {
		[self showCoverForSong:[Song songWithSong:mSong]];
	}
}

- (void) setIsClickable:(BOOL)aValue {
	mClickable = aValue;
	
	if (mClickable)
		[[self window] invalidateCursorRectsForView:self];
}

- (void) setAllowsDrag:(BOOL)aValue {
	mAllowDrag = aValue;
}

- (void)drawRect:(NSRect)aRect {
	NSImage *image;
	if (mCoverImage) {
		image = mCoverImage;
	} else {
		image = mNoCoverAvailableImage;
	}
	
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	
	[context setCompositingOperation:NSCompositeSourceOver];
	[context setShouldAntialias:NO];
	
	[[NSColor colorWithDeviceRed:0.28 green:0.28 blue:0.28 alpha:1.0] setStroke];
	[NSBezierPath strokeRect:NSMakeRect(0,0,[super frame].size.width-0.5,[super frame].size.height-0.5)];
	[context restoreGraphicsState];

	[image drawAtPoint:NSMakePoint(1,1)
			  fromRect:NSMakeRect(0,0,[image size].width, [image size].height)
			 operation:NSCompositeSourceOver
			  fraction:1.0];
}

- (void) showCoverForSong:(Song *)aSong {
	[mCoverImage release], mCoverImage = nil;
	[self setNeedsDisplay:YES];
	
	[mSong release];
	mSong = [aSong retain];
	
	if (mClickable) {
		[[self window] invalidateCursorRectsForView:self];
		
		if (mCoverViewerController != nil &&
			[[mCoverViewerController window] isVisible])
			[mCoverViewerController showSong:mSong];
	}
	
	if (aSong == nil) {
		return;
	}
	
	[mIndicator startAnimation:nil];

	switch (mCoverArtSize) {
		case eCoverArtLarge:
			[[AWSController defaultController] fetchLargeImageForSong:mSong];
			break;
			
		case eCoverArtMedium:
			[[AWSController defaultController] fetchMediumImageForSong:mSong];
			break;
						
		case eCoverArtSmall:
			[[AWSController defaultController] fetchSmallImageForSong:mSong];
			break;
	}
}

- (void) fetchedImage:(NSNotification *)aNotification {
	NSDictionary *userinfo = [aNotification userInfo];
	if ([[[userinfo objectForKey:nAWSSongEntry] albumIdentifier] isEqualTo:[mSong albumIdentifier]] == NO)
		return;
	
	[mIndicator stopAnimation:nil];	
	[mCoverImage release], mCoverImage = [userinfo objectForKey:nAWSImageEntry];
	
	if (mCoverImage) {
		mCoverImage = [mCoverImage copy];
		[mCoverImage setScalesWhenResized:YES];
		[mCoverImage setSize:mImageSize];
	}
	
	[self setNeedsDisplay:YES];

	if (mClickable)
		[[self window] invalidateCursorRectsForView:self];
}

- (void) resetCursorRects {
	if (mClickable == NO || mSong == nil)
		return;
	
	[self addCursorRect:NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height)
				 cursor:[NSCursor pointingHandCursor]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if (mClickable == NO || mSong == nil)
		return;
	
    BOOL keepOn = YES;
    BOOL isInside = YES;
    NSPoint mouseLoc;
	
    while (keepOn) {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask];
        mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        isInside = [self mouse:mouseLoc inRect:[self bounds]];
		
        switch ([theEvent type]) {
            case NSLeftMouseUp:
				if (isInside) {
					if (!mCoverViewerController) {
						mCoverViewerController = [[CoverViewerController alloc] init];
					}
					[mCoverViewerController showSong:mSong];
					[[mCoverViewerController window] makeKeyAndOrderFront:self];
				}
				
				keepOn = NO;
				break;
				
            default:
				/* Ignore any other kind of event. */
				break;
        }
		
    };
	
    return;
}

- (void) coverArtFetcherFoundBuyURL:(NSURL *)aURL forSong:(Song *)aSong {
	[mBuyURL release];
	mBuyURL = [aURL retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:nCoverArtViewFoundBuyURL
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSURL URLWithString:[mBuyURL absoluteString]]
																						   forKey:@"URL"]];
}

- (NSURL *) buyURL {
	if (mBuyURL == nil)
		return nil;
	
	return [NSURL URLWithString:[mBuyURL absoluteString]];
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	if (mAllowDrag)
		return NSDragOperationCopy;
	return 0;
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (mAllowDrag == NO)
		return;
	
	if (!mCoverImage)
		return;
	
	NSSize dragOffset = NSMakeSize(0.0, 0.0);
	NSPasteboard *pboard;
	NSImage *image = [[[NSImage alloc] initWithSize:[mCoverImage size]] autorelease];
	[image lockFocus];
	[mCoverImage dissolveToPoint:NSMakePoint(0,0) fraction:0.7];
	[image unlockFocus];
		
	pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType]  owner:self];
	[pboard setData:[mCoverImage TIFFRepresentation] forType:NSTIFFPboardType];
		
	[self dragImage:image at:NSMakePoint(0,0) offset:dragOffset 
			event:theEvent pasteboard:pboard source:self slideBack:YES];
}

@end
