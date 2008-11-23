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

#import "PWSeekSliderCell.h"


@implementation PWSeekSliderCell

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self != nil) {
		[self setFocusRingType:NSFocusRingTypeNone];
	}
	return self;
}

- (float)knobThickness
{
	if (mKnobImage == nil) return [super knobThickness];
	return [mKnobImage size].width;
}

- (void)drawKnob:(NSRect)knobRect
{	
	if (mKnobImage == nil) return [super drawKnob:knobRect];
	
	NSPoint point = NSMakePoint(knobRect.origin.x + (knobRect.size.width - [mKnobImage size].width)/2.0, knobRect.origin.y + (knobRect.size.height - [mKnobImage size].height)/2.0);
	
	[[self controlView] lockFocus];
	[mKnobImage drawAtPoint:point fromRect:NSMakeRect(0, 0, [mKnobImage size].width, [mKnobImage size].height) operation:NSCompositeSourceOver fraction:1.0];
	[[self controlView] unlockFocus];
}

- (void) setKnobImage:(NSImage *)image {
	[mKnobImage release];
	mKnobImage = [image retain];
	[mKnobImage setFlipped:YES];
}

@end
