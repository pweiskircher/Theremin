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

#import "SongInfoController.h"
#import "Song.h"
#import "WindowController.h"
#import "MusicServerClient.h"
#import "PWMusicTextField.h"
#import "NSStringAdditions.h"

@implementation SongInfoController
- (id) init {
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:@"InfoPanel" owner:self];
		mCurrentIndex = 0;
		[mComment setEmptyStringMode:eEmptyShowNone];
	}
	return self;
}

- (void) dealloc {
	[mSongs release], mSongs = nil;
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	[self autorelease];
}

- (void) awakeFromNib {
}

- (void) showSongIndex:(int)index {
	id object = [mSongs objectAtIndex:index];
	Song *song;
	
	if ([object isKindOfClass:[NSManagedObject class]]) {
		song = [[[WindowController instance] musicClient] songInformationByUniqueIdentifier:[object valueForKey:@"uniqueIdentifier"]];
		if (!song) {
			NSBeep();
			return;
		}
	} else if ([object isKindOfClass:[Song class]]) {
		song = object;
	} else {
		NSBeep();
		return;
	}
	
	[mAlbum setStringValue:[song album]];
	[mArtist setStringValue:[song artist]];
	[mComment setStringValue:[song comment]];
	[mComposer setStringValue:[song composer]];
	[mDate setStringValue:[song date]];
	[mDisc setStringValue:[song disc]];
	[mFilename setStringValue:[song file]];
	[mGenre setStringValue:[song genre]];
	[mTitle setStringValue:[NSString stringWithFormat:@"%@ (%@)", [song title] == nil ? TR_S_GET_INFO_UNKNOWN : [song title], 
		[NSString convertSecondsToTime:[song time] andIsValid:NULL]]];
	[mTrackNumber setStringValue:[song track]];
}

- (void) showSongs:(NSArray *)theSongs {
	[mSongs release];
	mSongs = [theSongs retain];
	mCurrentIndex = 0;
	[self showSongIndex:0];
	
	if ([mSongs count] > 1) {
		[mPreviousButton setHidden:NO];
		[mNextButton setHidden:NO];
	} else {
		[mPreviousButton setHidden:YES];
		[mNextButton setHidden:YES];
	}
	
	[mPanel makeKeyAndOrderFront:self];
}

- (IBAction) close:(id)sender {
	[mSongs release], mSongs = nil;
	[mPanel orderOut:self];
}

- (IBAction) nextSong:(id)sender {
	if (!mSongs)
		return;
	
	mCurrentIndex++;
	if (mCurrentIndex >= [mSongs count])
		mCurrentIndex = 0;
	
	[self showSongIndex:mCurrentIndex];
}

- (IBAction) previousSong:(id)sender {
	if (!mSongs)
		return;
	
	mCurrentIndex--;
	if (mCurrentIndex < 0)
		mCurrentIndex = [mSongs count]-1;
	
	[self showSongIndex:mCurrentIndex];	
}

@end
