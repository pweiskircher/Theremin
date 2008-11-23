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

#import "PWMusicTextField.h"


@implementation PWMusicTextField

- (void) setEmptyStringMode:(EmptyStringMode)m {
	mMode = m;
}

- (void) setStringValue:(NSString *)aString {
	if (aString == nil) {
		switch(mMode) {
			case eEmptyShowNone:
				aString = TR_S_GET_INFO_NONE;
				break;
			case eEmptyShowUnknown:
				aString = TR_S_GET_INFO_UNKNOWN;
				break;
		}
	}
	[super setStringValue:aString];
}
@end
