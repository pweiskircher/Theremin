//
//  PWMusicSearchField.h
//  Theremin
//
//  Created by Patrik Weiskircher on 12.01.07.
//  Copyright 2007 Patrik Weiskircher. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	eMusicFlagsAll = 0,
	eMusicFlagsArtist,
	eMusicFlagsAlbum,
	eMusicFlagsTitle,
	eMusicFlagsLast
} MusicFlags;

@interface PWMusicSearchField : NSSearchField {
	MusicFlags mSearchState;
	NSString *mSearchFlagsAutosaveName;
}
- (id) initWithFrame:(NSRect)frame;
- (void) limitSearch:(id)sender;
- (MusicFlags) searchState;
- (int) mpdSongFlagsForSearchState;
- (void) setSearchFlagsAutosaveName:(NSString *)autosaveName;
@end
