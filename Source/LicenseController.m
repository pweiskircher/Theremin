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

#import "LicenseController.h"


@implementation LicenseController
- (id) init {
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:@"LicenseWindow" owner:self];		
	}
	return self;
}

- (void)windowWillClose:(NSNotification *)notification {
	[self release];
}

- (void) dealloc
{
	[super dealloc];
}


- (void) show {
	if (mLoaded == NO) {
		NSString *filename = [[NSBundle mainBundle] pathForResource:@"COPYING" ofType:@""];
		if (filename != nil) {
			NSString *license = [NSString stringWithContentsOfFile:filename];
			[mTextField setString:license];
		} else {
			[mTextField setString:@"License file not found. Please see http://www.gnu.org/licenses/gpl.txt"];
		}
		
		mLoaded = YES;
	}
	
	[mWindow makeKeyAndOrderFront:self];
}
@end
