/*
 Copyright (C) 2008  Patrik Weiskircher
 
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

#import "PreferencesWindowController.h"
#import "PreferencesController.h"
#import "ProfileController.h"

@implementation PreferencesWindowController
- (id) initWithPreferencesController:(PreferencesController *)aPreferencesController {
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:@"Preferences" owner:self];
		_preferencesController = [aPreferencesController retain];
	}
	return self;
}

- (void) dealloc
{
	[_preferencesController release];
	[_profileController release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification {
	[self autorelease];
}

- (void)showPreferences {
	[mUpdatePopup selectItemWithTag:[_preferencesController updateInterval]];
	[mCoverArtPopup selectItemWithTag:[_preferencesController coverArtProvider]];
	
	[mPreferencesWindow makeKeyAndOrderFront:self];
}

- (void)windowDidResignKey:(NSNotification *)aNotification {
	[_profileController saveProfiles];
	[_preferencesController save];
}

- (IBAction) updatePopupMenuChanged:(id)sender {
	int tag = [[sender selectedItem] tag];
	
	[_preferencesController setUpdateInterval:tag];
}

- (IBAction) coverArtPopupMenuChanged:(id)sender {
	int tag = [[sender selectedItem] tag];
	
	[_preferencesController setCoverArtProvider:tag];
	
	// we have to clear the cache manually as otherwise we don't know if the CoverArtView or the CoverArtCache notification
	// will be recevied at first..
	//[[CoverArtCache defaultCache] invalidateCache];
	[[NSNotificationCenter defaultCenter] postNotificationName:nCoverArtLocaleChanged object:self];
}

@end
