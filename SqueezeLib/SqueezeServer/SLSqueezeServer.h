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

#import "SLCLIConnection.h"
#import "SLServer.h"
#import "SLPlayer.h"

typedef enum {
	eStopped,
	ePaused,
	ePlaying,
} SLPlayPauseStatus;

@class SLTitle, SLCLICredentials, SLCLIRequest;

@protocol SLSqueezeServerDelegate
- (void) fetchedPlayerList:(NSArray *)players;
- (void) fetchedVersion:(NSString *)version;
- (void) fetchedPlayPauseStatus:(SLPlayPauseStatus)status;
- (void) fetchedCurrentPlaylistIndex:(int)index;
- (void) fetchedCurrentPlaylist:(NSArray *)playlist;
- (void) fetchedCurrentPlaylistTrack:(SLTitle *)aTitle forIndex:(int)index;
- (void) fetchedCurrentPlaylistLength:(int)length;
- (void) fetchedCurrentSong:(SLTitle *)song;
- (void) fetchedCurrentSongElapsedTime:(int)elapsed;
- (void) fetchedCompleteDatabase:(NSArray *)songs;

- (void) fetchedAllArtists:(NSArray *)artists;

- (void) serverError;
@end

@interface SLSqueezeServer : NSObject {
	SLServer *_server;
	SLPlayer *_player;
	SLCLIConnection *_conn;
	SLCLICredentials *_credentials;
	
	SLCLIRequest *_currentPlaylistRequest;
	
	id _delegate;
}
- (id) initWithServer:(SLServer *)server andCredentials:(SLCLICredentials *)someCredentials;

- (void) setPlayer:(SLPlayer *)player;
- (void) setDelegate:(id)delegate;
- (SLServer *) server;

#pragma mark -
#pragma mark Information Requests
- (void) requestVersion;
- (void) requestPlayerList;

#pragma mark -
#pragma mark Playlist Control Requests
- (void) requestNextSong;
- (void) requestPrevSong;
- (void) requestPause;
- (void) requestPlay;
- (void) requestPlayPauseStatus;
- (void) requestPlaySongAtIndex:(int)index;

- (void) requestRemovalOfTrackIds:(NSIndexSet *)trackIds;
- (void) requestClearPlaylist;

- (void) requestAddingOfTrackIds:(NSIndexSet *)trackIds;
- (void) requestMoveInCurrentPlaylistFrom:(int)src toDest:(int)dest;

- (void) requestCurrentPlaylistIndex;
- (void) requestCurrentPlaylist;
- (void) requestCurrentSong;
- (void) requestCurrentSongElapsedTime;
- (void) requestCurrentSongSeek:(int)aTime;

#pragma mark -
#pragma mark Player Requests
- (void) requestDifferentVolume:(int)aVolume;

#pragma mark -
#pragma mark Database Requests
- (void) requestCompleteDatabase;
- (void) requestAllArtists;
@end
