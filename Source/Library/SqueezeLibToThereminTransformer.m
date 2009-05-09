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

#import "SqueezeLibToThereminTransformer.h"
#import <SqueezeLib/SLArtist.h>
#import <SqueezeLib/SLAlbum.h>
#import <SqueezeLib/SLGenre.h>
#import <SqueezeLib/SLTitle.h>
#import "Artist.h"
#import "Profile.h"
#import "Album.h"
#import "Genre.h"
#import "Song.h"

@implementation SqueezeLibToThereminTransformer
+ (Artist *) slArtistToArtistTransform:(SLArtist *)aArtist {
	Artist *artist = [[[Artist alloc] init] autorelease];
	
	[artist setName:[aArtist title]];
	[artist setIdentifier:[aArtist artistId]];
	
	return artist;
}

+ (Album *) slAlbumToAlbumTransform:(SLAlbum *)aAlbum {
	Album *album = [[[Album alloc] init] autorelease];
	
	[album setName:[aAlbum title]];
	[album setIdentifier:[aAlbum albumId]];
	
	return album;
}

+ (Genre *) slGenreToGenreTransform:(SLGenre *)aGenre {
	Genre *genre = [[[Genre alloc] init] autorelease];

	[genre setName:[aGenre title]];
	[genre setIdentifier:[aGenre genreId]];	
	
	return genre;
}

+ (Song *) slTitleToSongTransform:(SLTitle *)aTitle {
	Song *song = [[[Song alloc] init] autorelease];
	
	[song setTitle:[aTitle title]];
	
	int titleId = [aTitle titleId];
	[song setUniqueIdentifier:[NSData dataWithBytes:&titleId length:sizeof(titleId)]];
	
	if ([aTitle artist])
		[song setArtist:[[aTitle artist] title]];
	if ([aTitle album])
		[song setAlbum:[[aTitle album] title]];
	if ([aTitle trackNumber] >= 0)
		[song setTrack:[NSString stringWithFormat:@"%d", [aTitle trackNumber]]];
	if ([aTitle genre])
		[song setGenre:[aTitle genre]];
	if ([aTitle duration] >= 0)
		[song setTime:[aTitle duration]];
	
	[song setValid:YES];
	
	return song;
}

@end
