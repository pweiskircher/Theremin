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

#import "PWSeekSlider.h"
#import "PWSeekSliderCell.h"

@implementation PWSeekSlider
- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self != nil) {
		[self setCell:[[PWSeekSliderCell alloc] init]];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	BOOL shouldUseSetClass = NO;
	BOOL shouldUseDecodeClassName = NO;
	if ([decoder respondsToSelector:@selector(setClass:forClassName:)]) {
		shouldUseSetClass = YES;
		[(NSKeyedUnarchiver *)decoder setClass:[PWSeekSliderCell class] forClassName:@"NSSliderCell"];
		
	} else if ([decoder respondsToSelector:@selector(decodeClassName:asClassName:)]) {
		shouldUseDecodeClassName = YES;
		[(NSUnarchiver *)decoder decodeClassName:@"NSSliderCell" asClassName:@"PWSeekSliderCell"];
	}
	
	self = [super initWithCoder:decoder];
	
	if (shouldUseSetClass) {
		[(NSKeyedUnarchiver *)decoder setClass:[NSSliderCell class] forClassName:@"NSSliderCell"];
	} else if (shouldUseDecodeClassName) {
		[(NSUnarchiver *)decoder decodeClassName:@"NSSliderCell" asClassName:@"NSSliderCell"];
	}
	
	return self;
}

@end
