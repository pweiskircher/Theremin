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

#import "Song.h"
#import "Album.h"
#import "Artist.h"
#import "Genre.h"

NSString *gSongPropertyFile = @"gSongPropertyFile";
NSString *gSongPropertyArtist = @"gSongPropertyArtist";
NSString *gSongPropertyArtistIsUnknown = @"gSongPropertyArtistIsUnknown";
NSString *gSongPropertyTitle = @"gSongPropertyTitle";
NSString *gSongPropertyAlbum = @"gSongPropertyAlbum";
NSString *gSongPropertyAlbumIsUnknown = @"gSongPropertyAlbumIsUnknown";
NSString *gSongPropertyTrack = @"gSongPropertyTrack";
NSString *gSongPropertyName = @"gSongPropertyName";
NSString *gSongPropertyDate = @"gSongPropertyDate";
NSString *gSongPropertyGenre = @"gSongPropertyGenre";
NSString *gSongPropertyGenreIsUnknown = @"gSongPropertyGenreIsUnknown";
NSString *gSongPropertyComposer = @"gSongPropertyComposer";
NSString *gSongPropertyDisc = @"gSongPropertyDisc";
NSString *gSongPropertyComment = @"gSongPropertyComment";
NSString *gSongPropertyTime = @"gSongPropertyTime";
NSString *gSongPropertyIdentifier = @"gSongPropertyIdentifier";
NSString *gSongPropertyUniqueIdentifier = @"gSongPropertyUniqueIdentifier";
NSString *gSongPropertySqlIdentifier = @"gSongPropertySqlIdentifier";
NSString *gSongPropertyIsCompilation = @"gSongPropertyIsCompilation";

#warning FIXME: remove libmpdclient dependency.

@interface Song (PrivateMethods)
- (NSDictionary *) values;
@end

@implementation Song
+ (id)songWithMpd_Song:(mpd_Song *)song {
	return [[[Song alloc] initWithMpd_Song:song] autorelease];
}

+ (id)songWithSong:(Song *)song {
	return [[[Song alloc] initWithSong:song] autorelease];
}

- (id)initWithMpd_Song:(mpd_Song *)song {
	self = [super init];
	if (self != nil) {
		mValues = [[NSMutableDictionary dictionary] retain];
		if (song) {
			if (song->file) {
				[self setFile:[NSString stringWithUTF8String:song->file]];
				// also include the 0 byte at the end.
				[self setUniqueIdentifier:[NSData dataWithBytes:song->file length:strlen(song->file)+1]];
			}
			
			if (song->artist) {
				[self setArtist:[NSString stringWithUTF8String:song->artist]];
			}
			
			if (song->title) {
				[self setTitle:[NSString stringWithUTF8String:song->title]];
			}
			
			if (song->album) {
				[self setAlbum:[NSString stringWithUTF8String:song->album]];
			}
			
			if (song->track) {
				[self setTrack:[NSString stringWithUTF8String:song->track]];
			}
			
			if (song->name) {
				[self setName:[NSString stringWithUTF8String:song->name]];
			}
			
			if (song->date) {
				[self setDate:[NSString stringWithUTF8String:song->date]];
			}
			
			if (song->genre) {
				[self setGenre:[NSString stringWithUTF8String:song->genre]];
			}
			
			if (song->composer) {
				[self setComposer:[NSString stringWithUTF8String:song->composer]];
			}
			
			if (song->disc) {
				[self setDisc:[NSString stringWithUTF8String:song->disc]];
			}
			
			if (song->comment) {
				[self setComment:[NSString stringWithUTF8String:song->comment]];
			}
			
			[self setTime:song->time];
			[self setRemoteIdentifier:song->id];
			
			mValid = YES;
		} else {
			mValid = NO;
		}
	}
	return self;
}

- (id)initWithSong:(Song *)song {
	self = [super init];
	if (self != nil) {
		mValid = song->mValid;
		mValues = [[NSMutableDictionary dictionaryWithDictionary:song->mValues] retain];
	}
	return self;
}

- (id) init {
	self = [super init];
	if (self != nil) {
		mValid = NO;
		mValues = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (NSString *)description {
	NSString *str = [NSString stringWithFormat:@"Song <0x%08x>. Name: %@ Artist: %@ Album: %@ Filename: %@", self, 
		[self name], [self artist], [self album], [self file]];
	return str;
}

- (void) dealloc {
	[mValues release];
	
	[super dealloc];
}

- (BOOL) valid {
	return mValid;
}

- (void) setValid:(BOOL)aValue {
	mValid = aValue;
}

- (BOOL) foundString:(NSString *)string onFields:(int)fields {
	if (fields & eArtist && [mValues objectForKey:gSongPropertyArtist] && [[self artist] rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound)
		return YES;
	
	if (fields & eArtist && [mValues objectForKey:gSongPropertyArtist] == nil) {
		if ([[[self file] lastPathComponent] rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound)
			return YES;
	}
	
	if (fields & eAlbum && [mValues objectForKey:gSongPropertyAlbum] && [[self album] rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound)
		return YES;
	if (fields & eTitle && [mValues objectForKey:gSongPropertyTitle] && [[self title] rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound)
		return YES;
	
	return NO;
}

- (BOOL) foundTokens:(NSArray *)tokens onFields:(int)fields {
	for (int i = 0; i < [tokens count]; i++) {
		if ([self foundString:[tokens objectAtIndex:i] onFields:fields] == NO)
			return NO;
	}
	
	return YES;
}

- (NSString *) file {
	if ([mValues objectForKey:gSongPropertyFile])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyFile]];
	return nil;
}

- (NSString *) artist {
	if ([mValues objectForKey:gSongPropertyArtist])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyArtist]];
	return nil;
}

- (BOOL) artistIsUnknown {
	if ([mValues objectForKey:gSongPropertyArtistIsUnknown])
		return [[mValues objectForKey:gSongPropertyArtistIsUnknown] boolValue];
	return NO;
}

- (NSString *) title {
	if ([mValues objectForKey:gSongPropertyTitle])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyTitle]];
	return nil;
}

- (NSString *) album {
	if ([mValues objectForKey:gSongPropertyAlbum])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyAlbum]];
	return nil;
}

- (BOOL) albumIsUnknown {
	if ([mValues objectForKey:gSongPropertyAlbumIsUnknown])
		return [[mValues objectForKey:gSongPropertyAlbumIsUnknown] boolValue];
	return NO;
}

- (NSString *) track {
	if ([mValues objectForKey:gSongPropertyTrack])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyTrack]];
	return nil;
}

- (NSString *) name {
	if ([mValues objectForKey:gSongPropertyName])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyName]];
	return nil;
}

- (NSString *) date {
	if ([mValues objectForKey:gSongPropertyDate])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyDate]];
	return nil;
}

- (NSString *) genre {
	if ([mValues objectForKey:gSongPropertyGenre])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyGenre]];
	return nil;
}

- (NSString *) composer {
	if ([mValues objectForKey:gSongPropertyComposer])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyComposer]];
	return nil;
}

- (NSString *) disc {
	if ([mValues objectForKey:gSongPropertyDisc])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyDisc]];
	return nil;
}

- (NSString *) comment {
	if ([mValues objectForKey:gSongPropertyComment])
		return [NSString stringWithString:[mValues objectForKey:gSongPropertyComment]];
	return nil;
}

- (int) time {
	if ([mValues objectForKey:gSongPropertyTime])
		return [[mValues objectForKey:gSongPropertyTime] intValue];
	return -1;
}

- (int) remoteIdentifier {
	if ([mValues objectForKey:gSongPropertyIdentifier])
		return [[mValues objectForKey:gSongPropertyIdentifier] intValue];
	return -1;
}

- (NSData *) uniqueIdentifier {
	if ([mValues objectForKey:gSongPropertyUniqueIdentifier])
		return [NSData dataWithData:[mValues objectForKey:gSongPropertyUniqueIdentifier]];
	return nil;
}

- (int) identifier {
	if ([mValues objectForKey:gSongPropertySqlIdentifier])
		return [[mValues objectForKey:gSongPropertySqlIdentifier] intValue];
	return -1;
}

- (BOOL) isCompilation {
	if ([mValues objectForKey:gSongPropertyIsCompilation])
		return [[mValues objectForKey:gSongPropertyIsCompilation] boolValue];
	return NO;
}

- (NSString *) albumIdentifier {
	if ([self artistIsUnknown] || [self albumIsUnknown])
		return NSLocalizedString(@"Unknown Album", @"");
	
	NSString *artist = [self artist];
	NSString *album = [self album];
	return [NSString stringWithFormat:@"%@ %@", artist, album];
}

- (void) setFile:(NSString *)aString {
	if (!aString) return;
	[mValues setObject:aString forKey:gSongPropertyFile];
}

- (void) setArtist:(NSString *)aString {
	if (!aString) return;
	
	if ([aString isEqualToString:gUnknownArtistName]) {
		[mValues setObject:TR_S_UNKNOWN_ARTIST forKey:gSongPropertyArtist];
		[mValues setObject:[NSNumber numberWithBool:YES] forKey:gSongPropertyArtistIsUnknown];
	} else {
		[mValues setObject:aString forKey:gSongPropertyArtist];
		[mValues removeObjectForKey:gSongPropertyArtistIsUnknown];
	}
}

- (void) setTitle:(NSString *)aString {
	if (!aString) return;
	[mValues setObject:aString forKey:gSongPropertyTitle];
}

- (void) setAlbum:(NSString *)aString {
	if (!aString) return;
	if ([aString isEqualToString:gUnknownAlbumName]) {
		[mValues setObject:TR_S_UNKNOWN_ALBUM forKey:gSongPropertyAlbum];
		[mValues setObject:[NSNumber numberWithBool:YES] forKey:gSongPropertyAlbumIsUnknown];
	} else {
		[mValues setObject:aString forKey:gSongPropertyAlbum];
		[mValues removeObjectForKey:gSongPropertyAlbumIsUnknown];
	}
}

- (void) setTrack:(NSString *)aString {
	if (!aString) return;
	[mValues setObject:aString forKey:gSongPropertyTrack];
}

- (void) setName:(NSString *)aString {
	if (!aString) return;
	[mValues setObject:aString forKey:gSongPropertyName];
}

- (void) setDate:(NSString *)aString {
	if (!aString) return;
	[mValues setObject:aString forKey:gSongPropertyDate];
}

- (void) setGenre:(NSString *)aString {
	if (!aString) return;
	if ([aString isEqualToString:gUnknownGenreName]) {
		[mValues setObject:TR_S_UNKNOWN_GENRE forKey:gSongPropertyGenre];
		[mValues setObject:[NSNumber numberWithBool:YES] forKey:gSongPropertyGenreIsUnknown];
	} else {
		[mValues setObject:aString forKey:gSongPropertyGenre];
		[mValues removeObjectForKey:gSongPropertyGenreIsUnknown];
	}
}

- (void) setComposer:(NSString *)aString {
	if (!aString) return;
	[mValues setObject:aString forKey:gSongPropertyComposer];
}

- (void) setDisc:(NSString *)aString {
	if (!aString) return;
	[mValues setObject:aString forKey:gSongPropertyDisc];
}

- (void) setComment:(NSString *)aString {
	if (!aString) return;
	[mValues setObject:aString forKey:gSongPropertyComment];
}

- (void) setTime:(int)aInteger {
	[mValues setObject:[NSNumber numberWithInt:aInteger] forKey:gSongPropertyTime];
}

- (void) setRemoteIdentifier:(int)aInteger {
	[mValues setObject:[NSNumber numberWithInt:aInteger] forKey:gSongPropertyIdentifier];
}

- (void) setUniqueIdentifier:(NSData *)aData {
	if (!aData) return;
	[mValues setObject:aData forKey:gSongPropertyUniqueIdentifier];
}

- (void) setIdentifier:(int)aInteger {
	[mValues setObject:[NSNumber numberWithInt:aInteger] forKey:gSongPropertySqlIdentifier];
}

- (void) setIsCompilation:(BOOL)aBool {
	[mValues setObject:[NSNumber numberWithBool:aBool] forKey:gSongPropertyIsCompilation];
}

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    if ([encoder isBycopy]) return self;
    return [super replacementObjectForPortCoder:encoder];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:mValues];
	[encoder encodeBytes:&mValid length:sizeof(mValid)];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	mValues = [[decoder decodeObject] retain];
	
	unsigned length;
	memcpy(&mValid, [decoder decodeBytesWithReturnedLength:&length], sizeof(mValid));
	
	return self;
}

- (BOOL)isEqual:(id)anObject {
	if ([anObject isKindOfClass:[self class]])
		return [self isEqualToSong:anObject];
	return NO;
}

- (NSDictionary *) values {
	return [[mValues retain] autorelease];
}

- (BOOL)isEqualToSong:(Song *)aSong {
	return [mValues isEqualToDictionary:[aSong values]];
}

@end
