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

#import "CoverViewerController.h"
#import "CoverArtView.h"
#import "Song.h"
#import "WindowController.h"
#import "PreferencesController.h"
#import "AWSController.h"

@implementation CoverViewerController
- (id) init {
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:@"CoverViewer" owner:self];
	}
	return self;
}

- (void) awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(foundBuyURL:)
												 name:nFetchedDetailURLForSong
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(coverArtEnabledChanged:)
												 name:nCoverArtEnabledChanged
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(coverArtLocaleChanged:)
												 name:nCoverArtLocaleChanged
											   object:nil];
	
	[mCoverArtView setAllowsDrag:YES];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mBuyURL release], mBuyURL = nil;
	[mSong release], mSong = nil;
	[super dealloc];
}

- (NSWindow *)window {
	return mWindow;
}

- (void) showSong:(Song *)aSong {
	[mBuyButton setEnabled:NO];
	
	[mSong release], mSong = [aSong retain];
	
	[mArtist setStringValue:[aSong artist]];
	[mAlbum setStringValue:[aSong album]];
	
	[mCoverArtView showCoverForSong:aSong];
	[[AWSController defaultController] fetchDetailURLForSong:aSong];
}

- (void) foundBuyURL:(NSNotification *)notification {
	Song *song = [[notification userInfo] objectForKey:nAWSSongEntry];
	if (mSong == nil || [[mSong albumIdentifier] isEqualTo:[song albumIdentifier]] == NO)
		return;
	
	NSURL *url = [[notification userInfo] objectForKey:nAWSURLEntry];
	if (url) {
		[mBuyButton setEnabled:YES];
		
		[mBuyURL release], mBuyURL = [url retain];
	}
}

- (void) coverArtEnabledChanged:(NSNotification *)notification {
 	if ([[[WindowController instance] preferences] coverArtEnabled] == NO)
		[mWindow orderOut:self];
}

- (void) coverArtLocaleChanged:(NSNotification *)notification {
	[mBuyButton setEnabled:NO];
	[mBuyURL release], mBuyURL = nil;
	[[AWSController defaultController] fetchDetailURLForSong:mSong];
}

- (IBAction) buy:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:mBuyURL];
}
@end
