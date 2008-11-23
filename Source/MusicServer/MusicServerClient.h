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
extern NSString *nMusicServerClientElapsedAndTotalTimeChanged;
extern NSString *nMusicServerClientShuffleOptionChanged;
extern NSString *nMusicServerClientRepeatOptionChanged;

extern NSString *nMusicServerClientFetchedDatabase;
extern NSString *nMusicServerClientFetchedPlaylist;
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

@protocol MusicServerClientInterface
- (oneway void) initialize;

#pragma mark Connection
- (BOOL) isConnected;
- (oneway void) connectToServer:(NSString *)server withPort:(int)port andPassword:(NSString *)password;
- (oneway void) disconnectWithReason:(NSString *)reason;

#pragma mark Database
- (oneway void) startFetchDatabase;
- (NSData *) databaseIdentifier;

- (bycopy) entriesInDirectory:(Directory *)aDirectory withTypes:(int)theTypes;
- (bycopy) rootDirectory;
- (oneway void) updateDirectory:(Directory *)aDirectory;

- (bycopy Song *) songInformationByUniqueIdentifier:(NSData *)aUniqueIdentifier;

#pragma mark Playlist
- (oneway void) startFetchPlaylist;
- (oneway void) removeSongsFromPlaylist:(NSArray *)songs;
- (oneway void) clearPlaylist;
- (oneway void) addSongsToPlaylistByUniqueIdentifier:(NSArray *)uniqueIdentifiers;

- (oneway void) moveSongFromPosition:(int)src toPosition:(int)dest;
- (oneway void) swapSongs:(bycopy Song *)srcSong with:(bycopy Song *)destSong;

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
- (oneway void) changePlaybackVolume:(int)diff;
- (oneway void) seek:(int)time;

#pragma mark Authentication
- (oneway void) setAuthenticationInformation:(NSDictionary *)info;

#pragma mark Various
- (oneway void) toggleShuffle;
- (oneway void) toggleRepeat;

- (oneway void) playerWindowFocused;
- (oneway void) playerWindowUnfocused;
- (oneway void) playerWindowClosed;

@end

@interface MusicServerClient : NSObject <MusicServerClientInterface> {
	NSTimer *mSeekTimer;
	int mLastSetTime;
}
+ (void) connectWithPorts:(NSDictionary *)infos;

- (void) scheduleSeek:(int)time withDelay:(NSTimeInterval)delay;
- (bycopy) entriesInDirectory:(Directory *)aDirectory;
- (oneway void) asynchronousEntriesInDirectory:(Directory *)aDirectory withTypes:(int)theTypes;
@end