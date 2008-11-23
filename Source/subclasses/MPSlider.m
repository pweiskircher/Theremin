/*****************************************************************************
 * misc.m: code not specific to vlc
 *****************************************************************************
 * Copyright (C) 2003-2005 the VideoLAN team
 * $Id: misc.m 18340 2006-12-09 19:57:48Z fkuehne $
 *
 * Authors: Jon Lech Johansen <jon-vl@nanocrew.net>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "MPSlider.h"

/*****************************************************************************
 * MPSlider
 *****************************************************************************/
@implementation MPSlider

void _drawKnobInRect(NSRect knobRect)
{
    // Center knob in given rect
    knobRect.origin.x += (int)((float)(knobRect.size.width - 7)/2.0);
    knobRect.origin.y += (int)((float)(knobRect.size.height - 7)/2.0);
    
    // Draw diamond
    NSRectFillUsingOperation(NSMakeRect(knobRect.origin.x + 3, knobRect.origin.y + 6, 1, 1), NSCompositeSourceOver);
    NSRectFillUsingOperation(NSMakeRect(knobRect.origin.x + 2, knobRect.origin.y + 5, 3, 1), NSCompositeSourceOver);
    NSRectFillUsingOperation(NSMakeRect(knobRect.origin.x + 1, knobRect.origin.y + 4, 5, 1), NSCompositeSourceOver);
    NSRectFillUsingOperation(NSMakeRect(knobRect.origin.x + 0, knobRect.origin.y + 3, 7, 1), NSCompositeSourceOver);
    NSRectFillUsingOperation(NSMakeRect(knobRect.origin.x + 1, knobRect.origin.y + 2, 5, 1), NSCompositeSourceOver);
    NSRectFillUsingOperation(NSMakeRect(knobRect.origin.x + 2, knobRect.origin.y + 1, 3, 1), NSCompositeSourceOver);
    NSRectFillUsingOperation(NSMakeRect(knobRect.origin.x + 3, knobRect.origin.y + 0, 1, 1), NSCompositeSourceOver);
}

void _drawFrameInRect(NSRect frameRect)
{
    // Draw frame
    NSRectFillUsingOperation(NSMakeRect(frameRect.origin.x, frameRect.origin.y, frameRect.size.width, 1), NSCompositeSourceOver);
    NSRectFillUsingOperation(NSMakeRect(frameRect.origin.x, frameRect.origin.y + frameRect.size.height-1, frameRect.size.width, 1), NSCompositeSourceOver);
    NSRectFillUsingOperation(NSMakeRect(frameRect.origin.x, frameRect.origin.y, 1, frameRect.size.height), NSCompositeSourceOver);
    NSRectFillUsingOperation(NSMakeRect(frameRect.origin.x+frameRect.size.width-1, frameRect.origin.y, 1, frameRect.size.height), NSCompositeSourceOver);
}

- (void) _drawStripesInRect:(NSRect)rect withKnobRect:(NSRect)knobRect {
	if (knobRect.origin.x < 2)
		return;
	
	NSImage *stripe = [NSImage imageNamed:@"seekbar_stripes"];
	NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(knobRect.origin.x-1,[stripe size].height)] autorelease];
	
	[image lockFocus];
	for (int i = 0; i < [image size].width; i += [stripe size].width) {
		[stripe compositeToPoint:NSMakePoint(i,0) operation:NSCompositeSourceOver];
	}
	[image unlockFocus];
	
	[self lockFocus];
	[image compositeToPoint:NSMakePoint(rect.origin.x+1, rect.origin.y + 7) operation:NSCompositeSourceOver];
	[self unlockFocus];
	[self setNeedsDisplayInRect:NSMakeRect(rect.origin.x+1, rect.origin.y + 7, rect.size.width, rect.size.height)];
}

- (void)drawRect:(NSRect)rect
{
    // Draw default to make sure the slider behaves correctly
    [[NSGraphicsContext currentContext] saveGraphicsState];
    NSRectClip(NSZeroRect);
    [super drawRect:rect];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
    // Full size
    rect = [self bounds];
    int diff = (int)(([[self cell] knobThickness] - 7.0)/2.0) - 1;
    rect.origin.x += diff+4;
    rect.origin.y += diff;
    rect.size.width -= 2*diff+4+4;
    rect.size.height -= 2*diff;
	
	[[[NSColor whiteColor] colorWithAlphaComponent:1.0] set];
	NSRectFillUsingOperation(rect,NSCompositeSourceOver);
    
    // Draw dark
    NSRect knobRect = [[self cell] knobRectFlipped:NO];
    [[[NSColor blackColor] colorWithAlphaComponent:1.0] set];
    _drawFrameInRect(rect);
	//[self _drawStripesInRect:rect withKnobRect:knobRect];
    _drawKnobInRect(knobRect);
   
	if ([[self window] firstResponder] == self) {
		[NSGraphicsContext saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);

		NSBezierPath *bp = [NSBezierPath bezierPathWithRect:rect];
		[bp setLineWidth:0.1];
		[bp fill];
		
		[NSGraphicsContext restoreGraphicsState];
	}
	
#if 0
    // Draw shadow
    [[[NSColor blackColor] colorWithAlphaComponent:0.1] set];
    rect.origin.x++;
    rect.origin.y++;
    knobRect.origin.x++;
    knobRect.origin.y++;
    _drawFrameInRect(rect);

    _drawKnobInRect(knobRect);
#endif
}

@end

