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

#import <Cocoa/Cocoa.h>
#import "GrowlMessenger.h"
#import "CoverArtImageView.h"

@class WindowController, Song;

@interface InfoAreaController : NSObject {
	IBOutlet NSTextField *mTitle;
	IBOutlet NSTextField *mArtist;
	IBOutlet NSTextField *mAlbum;
	
	IBOutlet NSTextField *mElapsedTime;
	IBOutlet NSTextField *mRemainingTime;
	IBOutlet NSSlider *mSeekSlider;
	
	IBOutlet NSProgressIndicator *mProgressIndicator;
	IBOutlet NSTextField *mProgressLabel;
	
	IBOutlet CoverArtImageView *_coverArtImageView;
	
	NSPoint _originTitle;
	NSPoint _originArtist;
	NSPoint _originProgressLabel;
	
	NSTimer *mProgressIndicatorStartTimer;	
	NSTimer *mInfoAreaUpdateTimer;
	
	Song *mCurrentSong;
	NSData *mLastNotifiedSongIdentifier;
	
	GrowlMessenger *_growlMessenger;
	
	int _total;
}
- (id) init;
- (void) dealloc;

- (void) scheduleUpdate;
- (void) update;

- (void) updateSeekBarWithTotalTime:(int)total;
- (void) updateSeekBarWithElapsedTime:(int)elapsed;
@end
