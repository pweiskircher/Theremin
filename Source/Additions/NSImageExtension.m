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

#import "NSImageExtension.h"


@implementation NSImage (PWImageExtension)
- (void) compositeToPoint:(NSPoint)aPoint operation:(NSCompositingOperation)op scaledTo:(NSSize)size {
	NSImage *tmp = [[[NSImage alloc] initWithSize:[self size]] autorelease];
	[tmp lockFocus];
	[self compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
	[tmp unlockFocus];
	
	[tmp setScalesWhenResized:YES];
	[tmp setSize:size];
	
	[tmp compositeToPoint:aPoint operation:op];
}

- (void) prependImage:(NSImage *)image {
	NSImage *tmp = [[[NSImage alloc] initWithSize:NSMakeSize([self size].width + [image size].width, [self size].height)] autorelease];
	[tmp lockFocus];
	[image compositeToPoint:NSMakePoint(0,0) operation:NSCompositeCopy];
	[self compositeToPoint:NSMakePoint([image size].width, 0) operation:NSCompositeCopy];
	[tmp unlockFocus];
	
	[self setSize:[tmp size]];
	[self lockFocus];
	[tmp compositeToPoint:NSMakePoint(0,0) operation:NSCompositeCopy];
	[self unlockFocus];
}

- (void) appendImage:(NSImage *)image {
	NSImage *tmp = [[[NSImage alloc] initWithSize:NSMakeSize([self size].width + [image size].width, [self size].height)] autorelease];
	[tmp lockFocus];
	[self compositeToPoint:NSMakePoint(0,0) operation:NSCompositeCopy];
	[image compositeToPoint:NSMakePoint([self size].width,0) operation:NSCompositeCopy];
	[tmp unlockFocus];
	
	[self setSize:[tmp size]];
	[self lockFocus];
	[tmp compositeToPoint:NSMakePoint(0,0) operation:NSCompositeCopy];
	[self unlockFocus];
}

@end
