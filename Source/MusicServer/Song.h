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
#import "ThereminEntity.h"
#include <libmpdclient.h>

extern NSString *gSongPropertyFile;
extern NSString *gSongPropertyArtist;
extern NSString *gSongPropertyTitle;
extern NSString *gSongPropertyAlbum;
extern NSString *gSongPropertyTrack;
extern NSString *gSongPropertyName;
extern NSString *gSongPropertyDate;
extern NSString *gSongPropertyGenre;
extern NSString *gSongPropertyComposer;
extern NSString *gSongPropertyDisc;
extern NSString *gSongPropertyComment;
extern NSString *gSongPropertyTime;
extern NSString *gSongPropertyIdentifier;
extern NSString *gSongPropertyUniqueIdentifier;
extern NSString *gSongPropertySqlIdentifier;

typedef enum {
	eFile		= 0x00000001,
	eArtist		= 0x00000002,
	eTitle		= 0x00000004,
	eAlbum		= 0x00000008,
	eTrack		= 0x00000010,
	eName		= 0x00000020,
	eDate		= 0x00000040,
	eGenre		= 0x00000080,
	eComposer	= 0x00000100,
	eDisc		= 0x00000200,
	eComment	= 0x00000400,
	eTime		= 0x00000800,
	ePosition	= 0x00001000,
	eIdentifier	= 0x00002000,
	eUniqueIdentifier = 0x00004000,
} fieldFlags;

@interface Song : NSObject <ThereminEntity> {	
	NSMutableDictionary *mValues;
	BOOL mValid;
}
+ (id)songWithMpd_Song:(mpd_Song *)song;
+ (id)songWithSong:(Song *)song;
- (id)initWithMpd_Song:(mpd_Song *)song;
- (id)initWithSong:(Song *)song;

- (NSString *)description;

- (void) dealloc;

- (BOOL) valid;
- (void) setValid:(BOOL)aValue;

- (BOOL) foundString:(NSString *)string onFields:(int)fields;
- (BOOL) foundTokens:(NSArray *)tokens onFields:(int)fields;

- (NSString *) file;
- (NSString *) artist;
- (BOOL) artistIsUnknown;
- (NSString *) title;
- (NSString *) album;
- (BOOL) albumIsUnknown;
- (NSString *) track;
- (NSString *) name;
- (NSString *) date;
- (NSString *) genre;
- (NSString *) composer;
- (NSString *) disc;
- (NSString *) comment;
- (int) time;
- (int) remoteIdentifier;
- (NSData *) uniqueIdentifier;
- (int) identifier;
- (BOOL) isCompilation;
- (NSString *) albumIdentifier;

- (void) setFile:(NSString *)aString;
- (void) setArtist:(NSString *)aString;
- (void) setTitle:(NSString *)aString;
- (void) setAlbum:(NSString *)aString;
- (void) setTrack:(NSString *)aString;
- (void) setName:(NSString *)aString;
- (void) setDate:(NSString *)aString;
- (void) setGenre:(NSString *)aString;
- (void) setComposer:(NSString *)aString;
- (void) setDisc:(NSString *)aString;
- (void) setComment:(NSString *)aString;
- (void) setTime:(int)aInteger;
- (void) setRemoteIdentifier:(int)aInteger;
- (void) setUniqueIdentifier:(NSData *)aData;
- (void) setIdentifier:(int)aInteger;
- (void) setIsCompilation:(BOOL)aBool;

- (BOOL)isEqualToSong:(Song *)aSong;
@end
