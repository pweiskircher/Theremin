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

#import "MusicServerClient.h"
#import "NSNotificationAdditions.h"
#import "WindowController.h"

NSString *nMusicServerClientConnecting = @"nMusicServerClientConnecting";
NSString *nMusicServerClientConnected = @"nMusicServerClientConnected";
NSString *nMusicServerClientDisconnected = @"nMusicServerClientDisconnected";
NSString *nMusicServerClientRequiresAuthentication = @"nMusicServerClientRequiresAuthentication";

NSString *nMusicServerClientPlaylistChanged = @"nMusicServerClientPlaylistChanged";
NSString *nMusicServerClientCurrentSongPositionChanged = @"nMusicServerClientCurrentSongPositionChanged";
NSString *nMusicServerClientCurrentSongChanged = @"nMusicServerClientCurrentSongChanged";
NSString *nMusicServerClientStateChanged = @"nMusicServerClientStateChanged";
NSString *nMusicServerClientVolumeChanged = @"nMusicServerClientVolumeChanged";
NSString *nMusicServerClientElapsedAndTotalTimeChanged = @"nMusicServerClientElapsedAndTotalTimeChanged";
NSString *nMusicServerClientShuffleOptionChanged = @"nMusicServerClientShuffleOptionChanged";
NSString *nMusicServerClientRepeatOptionChanged = @"nMusicServerClientRepeatOptionChanged";

NSString *nMusicServerClientFetchedDatabase = @"nMusicServerClientFetchedDatabase";
NSString *nMusicServerClientFetchedPlaylist = @"nMusicServerClientFetchedPlaylist";
NSString *nMusicServerClientDatabaseUpdated = @"nMusicServerClientDatabaseUpdated";
NSString *nMusicServerClientFetchedNamedPlaylist = @"nMusicServerClientFetchedNamedPlaylist";

NSString *nMusicServerClientFoundPlaylists = @"nMusicServerClientFoundPlaylists";
NSString *nMusicServerClientNumberOfPlaylistsChanged = @"nMusicServerClientNumberOfPlaylistsChanged";

NSString *nMusicServerClientPort0 = @"nMusicServerClientPort0";
NSString *nMusicServerClientPort1 = @"nMusicServerClientPort1";
NSString *nMusicServerClientClass = @"nMusicServerClientClass";

NSString *dDisconnectReason = @"dDisconnectReason";
NSString *dSongs = @"dSongs";
NSString *dSongPosition = @"dSongPosition";
NSString *dDatabaseIdentifier = @"dDatabaseIdentifier";

@implementation MusicServerClient
+ (void) connectWithPorts:(NSDictionary *) infos {
	NSAutoreleasePool *pool;
	NSConnection *connectionToController;
	id client;
	
	pool = [[NSAutoreleasePool alloc] init];
	
	connectionToController = [NSConnection connectionWithReceivePort:[infos objectForKey:nMusicServerClientPort0]
															sendPort:[infos objectForKey:nMusicServerClientPort1]];
	
	client = [[NSClassFromString([infos objectForKey:nMusicServerClientClass]) alloc] init];
	WindowController *wc = (WindowController *)[connectionToController rootProxy];
	[wc setMusicClient:client];
	
	[client release];

	BOOL done = NO;
	while (!done) {
		pool = [[NSAutoreleasePool alloc] init];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
		[pool release];
	}
}

- (id) init {
	self = [super init];
	if (self != nil) {
		mLastSetTime = -1;
	}
	return self;
}

- (oneway void) scheduleSeek:(int)time withDelay:(NSTimeInterval)delay {
	if (mSeekTimer != nil) {
		[mSeekTimer invalidate];
		[mSeekTimer release];
	}
	
	mSeekTimer = [[NSTimer scheduledTimerWithTimeInterval:delay
												  target:self
												selector:@selector(seekTimerTriggered:)
												userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:time] forKey:@"time"]
												 repeats:NO] retain];
}

- (void) seekTimerTriggered:(NSTimer *)aTimer {
	int time = [[[aTimer userInfo] objectForKey:@"time"] intValue];
	
	[mSeekTimer invalidate];
	[mSeekTimer release];
	mSeekTimer = nil;
	
	// this isn't really optimal. if the user seeks twice to the exact same spot in two different songs, it doesn't 
	// seek the second time.. we can't really listen to the songchanged notification as thats posted on the mainthread..
	if (time == mLastSetTime)
		return;
	mLastSetTime = time;
	
	[self seek:time];
	
	[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(resetLastSetTime:) userInfo:nil repeats:NO];
}

- (void) resetLastSetTime:(NSTimer *)aTimer {
	mLastSetTime = -1;
}


- (oneway void) initialize {
}

#pragma mark Connection
- (BOOL) isConnected {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the isConnected method."];
	return NO;
}

- (oneway void) connectToServer:(NSString *)server withPort:(int)port andPassword:(NSString *)password {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the connectToServer:withPort:andPassword method."];
}

- (oneway void) disconnectWithReason:(NSString *)reason {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the disconnectWithReason: method."];
}

#pragma mark Database
- (oneway void) startFetchDatabase {
}

- (NSData *) databaseIdentifier {
	return nil;
}

- (bycopy) entriesInDirectory:(Directory *)aDirectory withTypes:(int)theTypes {
	return nil;
}

- (bycopy) rootDirectory {
	return nil;
}

- (oneway void) updateDirectory:(Directory *)aDirectory {
}

- (bycopy Song *) songInformationByUniqueIdentifier:(NSData *)aUniqueIdentifier {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the songInformationByUniqueIdentifier: method."];
	return nil;
}

#pragma mark Playlist
- (oneway void) startFetchPlaylist {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the startFetchPlaylist method."];
}

- (oneway void) removeSongsFromPlaylist:(NSArray *)songs {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the removeSongsFromPlaylist: method."];
}

- (oneway void) clearPlaylist {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the clearPlaylist method."];
}

- (oneway void) addSongsToPlaylistByUniqueIdentifier:(NSArray *)uniqueIdentifiers {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the addSongsToPlaylistByUniqueIdentifier: method."];
}

- (oneway void) moveSongFromPosition:(int)src toPosition:(int)dest {
}

- (oneway void) swapSongs:(bycopy Song *)srcSong with:(bycopy Song *)destSong {
}

- (oneway void) loadPlaylist:(PlayListFile *)aPlayListFile {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the loadPlaylist: method."];
}

- (oneway void) saveCurrentPlaylistAs:(NSString *)aPlayListName {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the saveCurrentPlaylistAs: method."];
}

- (oneway void) deletePlaylist:(bycopy PlayListFile *)aPlayListFile {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the deletePlaylist: method."];
}

- (BOOL) canGetPlaylistInfo {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the canGetPlaylistInfo method."];
	return NO;
}

- (oneway void) fetchNamedPlaylist:(bycopy PlayListFile *)aPlayListFile {
}

- (oneway void) sendCurrentSongPosition {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the sendCurrentSongPosition method."];
}

#pragma mark Player Controll
- (oneway void) startPlayback {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the startPlayback method."];
}

- (oneway void) pausePlayback {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the pausePlayback method."];
}

- (oneway void) stopPlayback {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the stopPlayback method."];
}

- (oneway void) next {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the next method."];
}

- (oneway void) previous {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the previous method."];
}

- (oneway void) skipToSong:(Song *)song {
	[NSException raise:NSInternalInconsistencyException format:@"You need to overwrite the skipToSong: method."];
}

- (oneway void) setPlaybackVolume:(int)volume {
}
- (oneway void) changePlaybackVolume:(int)diff {
}

- (oneway void) seek:(int)time {
}

#pragma mark Authentication
- (oneway void) setAuthenticationInformation:(NSDictionary *)info {
}

#pragma mark Various
- (oneway void) toggleShuffle {
}

- (oneway void) toggleRepeat {
}

- (oneway void) playerWindowClosed {
}

- (oneway void) playerWindowUnfocused {
}

- (oneway void) playerWindowFocused {
}

- (bycopy) entriesInDirectory:(Directory *)aDirectory {
	return [self entriesInDirectory:aDirectory withTypes:0];
}

- (oneway void) asynchronousEntriesInDirectory:(Directory *)aDirectory withTypes:(int)theTypes {
	NSArray *entries = [self entriesInDirectory:aDirectory withTypes:theTypes];

	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:aDirectory, @"Directory", 
		[NSNumber numberWithInt:theTypes], @"Types", 
		entries, @"Entries", nil];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientFoundPlaylists 
																		object:self 
																	  userInfo:dict];
}

@end
