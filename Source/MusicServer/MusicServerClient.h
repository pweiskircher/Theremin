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
#import "Profile.h"

@class Song, Directory, PlayListFile;

extern NSString *nMusicServerClientConnecting;
extern NSString *nMusicServerClientConnected;
extern NSString *nMusicServerClientDisconnected;
extern NSString *nMusicServerClientRequiresAuthentication;

// FIXME: this can be called very, very often on randomizing the playlist
//        in the one class where its used already, we stop doing stuff
//        while randomizing ... need a better solution for that
extern NSString *nMusicServerClientPlaylistChanged;
extern NSString *nMusicServerClientCurrentSongPositionChanged;
extern NSString *nMusicServerClientCurrentSongChanged;
extern NSString *nMusicServerClientStateChanged;
extern NSString *nMusicServerClientVolumeChanged;
extern NSString *nMusicServerClientElapsedTimeChanged;
extern NSString *nMusicServerClientTotalTimeChanged;
extern NSString *nMusicServerClientShuffleOptionChanged;
extern NSString *nMusicServerClientRepeatOptionChanged;

extern NSString *nMusicServerClientFetchedDatabase;
extern NSString *nMusicServerClientFetchedPlaylist;
extern NSString *nMusicServerClientFetchedPlaylistLength;
extern NSString *nMusicServerClientFetchedTitleForPlaylist;
extern NSString *nMusicServerClientDatabaseUpdated;
extern NSString *nMusicServerClientFetchedNamedPlaylist;

extern NSString *nMusicServerClientFoundPlaylists;
extern NSString *nMusicServerClientNumberOfPlaylistsChanged;



extern NSString *nMusicServerClientPort0;
extern NSString *nMusicServerClientPort1;
extern NSString *nMusicServerClientClass;


extern NSString *dDisconnectReason;
extern NSString *dSongs;
extern NSString *dSongPosition;
extern NSString *dDatabaseIdentifier;
extern NSString *dState;
extern NSString *dVolume;
extern NSString *dSong;
extern NSString *dTotalTime;
extern NSString *dElapsedTime;
extern NSString *dPlaylistLength;

extern NSString *dId;
extern NSString *dName;
extern NSString *dEnabled;

typedef enum {
	eStatePaused,
	eStateStopped,
	eStatePlaying
} MusicServerState;

typedef enum {
	eSongType			= 0x0001,
	eDirectoryType		= 0x0002,
	ePlayListFileType	= 0x0004
} DataTypes;

typedef enum {
	eMusicClientCapabilitiesRandomizePlaylist = 0x0001,
	eMusicClientCapabilitiesOutputDevices = 0x0002
} MusicClientCapabilities;

@protocol MusicServerClientInterface
- (oneway void) initialize;
+ (unsigned int) capabilities;

#pragma mark Connection
- (BOOL) isConnected;
- (oneway void) connectToServerWithProfile:(Profile *)profile;
- (oneway void) disconnectWithReason:(NSString *)reason;

#pragma mark Database
- (bycopy Song *) songInformationByUniqueIdentifier:(NSData *)aUniqueIdentifier;

#pragma mark Playlist
- (oneway void) startFetchPlaylist;
- (oneway void) removeSongsFromPlaylist:(NSArray *)songs;
- (oneway void) clearPlaylist;
- (oneway void) addSongsToPlaylistByUniqueIdentifier:(NSArray *)uniqueIdentifiers;

- (oneway void) moveSongFromPosition:(int)src toPosition:(int)dest;

- (oneway void) loadPlaylist:(bycopy PlayListFile *)aPlayListFile;
- (oneway void) saveCurrentPlaylistAs:(NSString *)aPlayListName;
- (oneway void) deletePlaylist:(bycopy PlayListFile *)aPlayListFile;

- (BOOL) canGetPlaylistInfo;
- (oneway void) fetchNamedPlaylist:(bycopy PlayListFile *)aPlayListFile;

- (oneway void) sendCurrentSongPosition;

#pragma mark Player Controll
- (oneway void) startPlayback;
- (oneway void) pausePlayback;
- (oneway void) stopPlayback;

- (oneway void) next;
- (oneway void) previous;
- (oneway void) skipToSong:(Song *)song;

- (oneway void) setPlaybackVolume:(int)volume;
- (oneway void) seek:(int)time;

#pragma mark Authentication
- (oneway void) setAuthenticationInformation:(NSDictionary *)info;

#pragma mark Various
- (oneway void) toggleShuffle;
- (oneway void) toggleRepeat;

- (oneway void) playerWindowFocused;
- (oneway void) playerWindowUnfocused;
- (oneway void) playerWindowClosed;

@optional
// needed for importing
- (oneway void) startFetchDatabase;
- (NSData *) databaseIdentifier;

- (bycopy) entriesInDirectory:(Directory *)aDirectory withTypes:(int)theTypes;
- (bycopy) rootDirectory;
- (oneway void) updateDirectory:(Directory *)aDirectory;

// needed for randomzing
- (oneway void) swapSongs:(bycopy Song *)srcSong with:(bycopy Song *)destSong;

- (bycopy NSArray*) getOutputDevices;
- (void) setOutputDeviceWithId:(int)theId toEnabled:(BOOL)enabled;
@end

@interface MusicServerClient : NSObject <MusicServerClientInterface> {
	NSTimer *mSeekTimer;
	int mLastSetTime;
	BOOL _stop;
}
+ (void) connectWithPorts:(NSDictionary *)infos;
+ (Class) musicServerClientClassForProfile:(Profile *)aProfile;

- (void) scheduleSeek:(int)time withDelay:(NSTimeInterval)delay;
- (bycopy) entriesInDirectory:(Directory *)aDirectory;
- (oneway void) asynchronousEntriesInDirectory:(Directory *)aDirectory withTypes:(int)theTypes;

- (BOOL) shouldStop;
- (void) stop;

@end