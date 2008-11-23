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

#if !defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE 
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

@class SLArtist, SLAlbum;

@interface SLTitle : NSObject {
	NSString *_name;
	int _id;
	
	int _albumArtId;
	int _duration;
	int _trackNumber;
	
	SLArtist *_artist;
	SLAlbum *_album;
	NSString *_genre;
}
+ (NSArray *) titlesWithSongInfoResponse:(NSArray *)array;
+ (id) titleWithName:(NSString *)name andId:(int)albumId;
- (id) initWithName:(NSString *)name andId:(int)albumId;

- (NSString *) title;
- (NSString *) sortTitle;
- (NSString *) formattedDuration;
- (NSString *) formattedTrackNumber;

- (int) artId;
- (int) duration;
- (int) trackNumber;

- (int) titleId;

- (void) setArtId:(int)aArtId;
- (void) setDuration:(int)aDuration;
- (void) setTrackNumber:(int)aTrackNumber;

- (void) setAlbum:(SLAlbum *)aAlbum;
- (void) setArtist:(SLArtist *)aArtist;
- (void) setGenre:(NSString *)aGenre;

- (SLAlbum *)album;
- (SLArtist *)artist;
- (NSString *)genre;

@end
