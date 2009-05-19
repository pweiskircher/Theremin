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

#import "CoverArtAsker.h"
#import "PreferencesController.h"

@implementation CoverArtAsker
- (void) ask {
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Display Album Artwork.", @"First startup dialog asking about enabling of cover art: Title") 
									 defaultButton:NSLocalizedString(@"Enable Album Artwork", @"First startup dialog asking about enabling of cover art: Default Button") 
								   alternateButton:NSLocalizedString(@"Disable Album Artwork", @"First startup dialog asking about enabling of cover art: Alternate Button") 
									   otherButton:nil 
						 informativeTextWithFormat:NSLocalizedString(@"Theremin can automatically show cover art for your music. To do this, it needs to submit the artist and the album of the currently playing song to Last.fm.", @"First startup dialog asking about enabling of cover art: Informative Text")]; 
	
	int result = [alert runModal]; 
	if (result == NSAlertDefaultReturn) { 
		[[PreferencesController sharedInstance] setFetchingOfCoverArt:YES]; 
	} else if (result == NSAlertAlternateReturn) { 
		[[PreferencesController sharedInstance] setFetchingOfCoverArt:NO]; 
	} 
	
}
@end
