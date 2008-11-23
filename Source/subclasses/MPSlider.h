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

#import <Cocoa/Cocoa.h>

@interface MPSlider : NSSlider {
}

- (void) _drawStripesInRect:(NSRect)rect withKnobRect:(NSRect)knobRect;
@end
