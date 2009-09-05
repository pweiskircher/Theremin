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

#import "MpdMusicServerClient.h"
#import "WindowController.h"
#import "NSNotificationAdditions.h"
#import "Song.h"
#import "Directory.h"
#import "PlayListFile.h"

static void MpdClientStatusChangedCallback(MpdObj *mi, ChangedStatusType what, void *userdata) {
	MpdMusicServerClient *client = (MpdMusicServerClient *)userdata;
	[client callbackStatusChanged:what];
}

static int MpdClientErrorCallback(MpdObj *mi, int identifier, char *msg, void *userdata) {
	MpdMusicServerClient *client = (MpdMusicServerClient *)userdata;
	[client callbackErrorOnIdentifier:identifier withMessage:msg];
	return 0;
}

static void MpdClientConnectionChangedCallback(MpdObj *mi, int connect, void *userdata) {
	MpdMusicServerClient *client = (MpdMusicServerClient *)userdata;
	[client callbackConnectionChanged:connect];
}

@implementation MpdMusicServerClient
+ (unsigned int) capabilities {
		return eMusicClientCapabilitiesRandomizePlaylist | eMusicClientCapabilitiesOutputDevices;
}

- (id) init {
	self = [super init];
	if (self != nil) {
		mConnection = mpd_new_default();
		
		mpd_signal_connect_connection_changed(mConnection,MpdClientConnectionChangedCallback,self);
		mpd_signal_connect_error(mConnection,MpdClientErrorCallback,self);
		mpd_signal_connect_status_changed(mConnection,MpdClientStatusChangedCallback,self);
		mPassword = nil;
		
		mpd_set_connection_timeout(mConnection, 60);
	}
	return self;
}

- (void) dealloc
{
	[mMpdTimer invalidate];
	[mMpdTimer release];
	[mPassword release];
	
	mpd_free(mConnection), mConnection = NULL;
	
	[super dealloc];
}


- (void) resetDelayForStatusUpdateTimer:(NSTimeInterval)aInterval {
	if (!mMpdTimer)
		return;
	
	[mMpdTimer invalidate];
	[mMpdTimer release];
	
	mMpdTimer = [[NSTimer scheduledTimerWithTimeInterval:aInterval
												 target:self 
											   selector:@selector(mpdTimerTriggered:) 
											   userInfo:nil 
												repeats:YES] retain];
}

- (int) currentSongPosition {
	if ([self isConnected] == NO) return -1;
	mpd_Song *s = mpd_playlist_get_current_song(mConnection);
	if (s)
		return s->pos;
	
	return -1;
}

- (void) mpdTimerTriggered:(NSTimer *)timer {
	mpd_status_update(mConnection);
	if (mpd_check_connected(mConnection) != TRUE) {
		[self disconnectWithReason:NSLocalizedString(@"Lost connection with server.", @"Happens when libmpd loses connection with MPD Server")];
	}
}

- (void) callbackStatusChanged:(int)what {
	what |= mForcedStatusUpdates;
	
	if (what & MPD_CST_STATE) {
		int state = 0;
		
		switch (mpd_player_get_state(mConnection)) {
			case MPD_PLAYER_UNKNOWN:
			case MPD_PLAYER_PAUSE:
				state = eStatePaused;
				break;
				
			case MPD_PLAYER_STOP:
				state = eStateStopped;
				break;
				
			case MPD_PLAYER_PLAY:
				state = eStatePlaying;
				break;
		}
		
		NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:state] forKey:dState];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientStateChanged 
																			object:self
																		  userInfo:dict];
	}
	
	if (what & MPD_CST_PLAYLIST) {
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientPlaylistChanged
																			object:self];
	}
	
	if (what & MPD_CST_SONGPOS) {
		NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[self currentSongPosition]]
														 forKey:dSongPosition];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientCurrentSongPositionChanged
																			object:self
																		  userInfo:dict];
	}
	
	if (what & MPD_CST_SONGID) {
		mpd_Song *song = mpd_playlist_get_current_song(mConnection);
		Song *mpdsong = [Song songWithMpd_Song:song];
		
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:mpdsong, dSong,
			[NSNumber numberWithInt:[self currentSongPosition]], dSongPosition, nil];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientCurrentSongChanged
																			object:self
																		  userInfo:dict];
	}
	
	if (what & MPD_CST_DATABASE) {
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientDatabaseUpdated
																			object:self
																		  userInfo:nil];
	}
	
	if (what & MPD_CST_UPDATING) {
		//NSLog(@"updating changed");
	}
	
	if (what & MPD_CST_VOLUME) {
		NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:mpd_status_get_volume(mConnection)]
														 forKey:dVolume];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientVolumeChanged
																			object:self
																		  userInfo:dict];
	}
	
	if (what & MPD_CST_TOTAL_TIME) {
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientTotalTimeChanged
																			object:self
																		  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:mpd_status_get_total_song_time(mConnection)] forKey:dTotalTime]];
	}
	
	if (what & MPD_CST_ELAPSED_TIME) {
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientElapsedTimeChanged
																			object:self
																		  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:mpd_status_get_elapsed_song_time(mConnection)] forKey:dElapsedTime]];
	}
	
	if (what & MPD_CST_CROSSFADE) {
		//NSLog(@"crossfade changed");
	}
	
	if (what & MPD_CST_RANDOM) {
		int shuffle = mpd_player_get_random(mConnection);
		NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:shuffle == 1 ? YES : NO] forKey:@"shuffleState"];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientShuffleOptionChanged
																			object:self
																		  userInfo:dict];
	}
	
	if (what & MPD_CST_REPEAT) {
		int shuffle = mpd_player_get_repeat(mConnection);
		NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:shuffle == 1 ? YES : NO] forKey:@"repeatState"];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientRepeatOptionChanged
																			object:self
																		  userInfo:dict];
	}
	
	if (what & MPD_CST_AUDIO) {
		//NSLog(@"audio changed");
	}
	
	if (what & MPD_CST_PERMISSION) {
		//NSLog(@"permission changed");
	}
	
	if (what & MPD_CST_BITRATE) {
		//NSLog(@"bitrate changed");
	}
	
	if (what & MPD_CST_AUDIOFORMAT) {
		//NSLog(@"audioformat changed");
	}
	
	mForcedStatusUpdates = 0;
}

- (void) callbackErrorOnIdentifier:(int)identifier withMessage:(char *)message {
}

- (void) callbackConnectionChanged:(int)connect {
}

- (void) stop {
	[mMpdTimer invalidate];
	[mMpdTimer release], mMpdTimer = nil;
	
	[super stop];
}

#pragma mark Protocol Implementation
- (oneway void) initialize {
}

#pragma mark Connection
- (BOOL) isConnected {
	return mpd_check_connected(mConnection) == TRUE ? YES : NO;
}

- (oneway void) connectToServerWithProfile:(Profile *)profile {
	if ([self isConnected]) {
		//NSLog(@"Already connected ...");
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientConnecting object:self];
	
	mpd_set_hostname(mConnection, (char *)[[profile hostname] UTF8String]);
	mpd_set_port(mConnection, [profile port]);
	mpd_set_connection_timeout(mConnection, 5.0);
	
	NSString *password = nil;
	if ([profile passwordExists])
		password = [profile password];
	
	if (password != nil)
		mpd_set_password(mConnection, (char *)[password UTF8String]);
	
	int result = mpd_connect(mConnection);
	if (result == MPD_OK) {
		if (password != nil)
			mpd_send_password(mConnection);
		
		while (mpd_server_check_command_allowed(mConnection,"status") != MPD_SERVER_COMMAND_ALLOWED) {
			NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[profile hostname], @"server",
				[NSNumber numberWithInt:[profile port]], @"port",
				nil];
			mSetPasswordCalled = NO;
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientRequiresAuthentication object:self
																			  userInfo:dictionary waitUntilDone:NO];
			while (mSetPasswordCalled == NO) {
				[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
			}
			
			if (mPassword == nil) {
				[self disconnectWithReason:NSLocalizedString(@"User canceled authentication request.", @"Happens when the user presses cancel on request for a password")];
				return;
			} else {
				mpd_set_password(mConnection, (char *)[mPassword UTF8String]);
				[mPassword release], mPassword = nil;
				mpd_send_password(mConnection);
			}
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientConnected object:self];
		
		mMpdTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 
													 target:self 
												   selector:@selector(mpdTimerTriggered:) 
												   userInfo:nil 
													repeats:YES] retain];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientDisconnected object:self userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Could not connect to %@", [profile hostname]] forKey:dDisconnectReason]];
	}
}

- (oneway void) disconnectWithReason:(NSString *)reason {
	mpd_disconnect(mConnection);
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientDisconnected
																		object:self
																	  userInfo:[NSDictionary dictionaryWithObject:reason forKey:dDisconnectReason]];
	
	[mMpdTimer invalidate];
	[mMpdTimer release];
	mMpdTimer = nil;
}

#pragma mark Database
- (oneway void) startFetchDatabase {
	MpdData *data;
	data = mpd_database_get_complete(mConnection);
	NSMutableArray *array = [NSMutableArray array];
	for (; data != NULL; data = mpd_data_get_next(data)) {
		[array addObject:[Song songWithMpd_Song:data->song]];
	}
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:array, dSongs, [self databaseIdentifier], dDatabaseIdentifier, nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientFetchedDatabase
																		object:self
																	  userInfo:dict];
}

- (NSData *) databaseIdentifier {
	NSString *string = [NSString stringWithFormat:@"%08d", mpd_server_get_database_update_time(mConnection)];
	return [string dataUsingEncoding:NSUTF8StringEncoding];
}


- (bycopy) entriesInDirectory:(Directory *)aDirectory withTypes:(int)theTypes {
	MpdData *data = mpd_database_get_directory(mConnection,(char *)[[aDirectory path] UTF8String]);
	
	NSMutableArray *array = [NSMutableArray array];
	for (; data != NULL; data = mpd_data_get_next(data)) {
		if (data->type == MPD_DATA_TYPE_DIRECTORY && (theTypes == 0 || theTypes & eDirectoryType)) {
			[array addObject:[Directory directoryWithPath:[NSString stringWithUTF8String:data->directory]]];
		} else if (data->type == MPD_DATA_TYPE_PLAYLIST && (theTypes == 0 || theTypes & ePlayListFileType)) {
			[array addObject:[PlayListFile listWithFilePath:[NSString stringWithUTF8String:data->playlist->path]]];
		} else if (data->type == MPD_DATA_TYPE_SONG && (theTypes == 0 || theTypes & eSongType)) {
			[array addObject:[Song songWithMpd_Song:data->song]];
		}
	}	
	
	return array;
}

- (bycopy) rootDirectory {
	return [Directory directoryWithPath:@"/"];
}

- (oneway void) updateDirectory:(Directory *)aDirectory {
	mpd_database_update_dir(mConnection,(char *)[[aDirectory path] UTF8String]);
}

- (bycopy Song *) songInformationByUniqueIdentifier:(NSData *)aUniqueIdentifier {
	mpd_Song *song = mpd_database_get_fileinfo(mConnection,(char *)[aUniqueIdentifier bytes]);
	if (!song) return nil;
	return [Song songWithMpd_Song:song];
}

#pragma mark Playlist
- (oneway void) startFetchPlaylist {
	MpdData *data;
	data = mpd_playlist_get_changes(mConnection,-1);
	NSMutableArray *array = [NSMutableArray array];
	for (; data != NULL; data = mpd_data_get_next(data)) {
		[array addObject:[Song songWithMpd_Song:data->song]];
	}
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:array, dSongs, nil];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientFetchedPlaylist
																		object:self
																	  userInfo:dict];
}

- (oneway void) removeSongsFromPlaylist:(NSArray *)songs {
	for (int i = 0; i < [songs count]; i++) {
		mpd_playlist_queue_delete_id(mConnection,[(Song *)[songs objectAtIndex:i] remoteIdentifier]);
	}
	mpd_playlist_queue_commit(mConnection);
}

- (oneway void) clearPlaylist {
	mpd_playlist_clear(mConnection);
}

- (oneway void) addSongsToPlaylistByUniqueIdentifier:(NSArray *)uniqueIdentifiers {
	for (int i = 0; i < [uniqueIdentifiers count]; i++) {
		char *filename = (char *)[[uniqueIdentifiers objectAtIndex:i] bytes];
		mpd_playlist_queue_add(mConnection, filename);
	}
	mpd_playlist_queue_commit(mConnection);
}

- (oneway void) moveSongFromPosition:(int)src toPosition:(int)dest {
	mpd_playlist_move_pos(mConnection,src,dest);
}

- (oneway void) swapSongs:(bycopy Song *)srcSong with:(bycopy Song *)destSong {
	mpd_playlist_swap_id(mConnection,[srcSong remoteIdentifier],[destSong remoteIdentifier]);
}

- (oneway void) loadPlaylist:(bycopy PlayListFile *)aPlayListFile {
	mpd_playlist_clear(mConnection);
	mpd_playlist_queue_load(mConnection, [[aPlayListFile filePath] UTF8String]);
	mpd_playlist_queue_commit(mConnection);
}

- (oneway void) saveCurrentPlaylistAs:(NSString *)aPlayListName {
	mpd_database_save_playlist(mConnection, [aPlayListName UTF8String]);
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientNumberOfPlaylistsChanged object:self];
}

- (oneway void) deletePlaylist:(bycopy PlayListFile *)aPlayListFile {
	mpd_database_delete_playlist(mConnection, [[aPlayListFile filePath] UTF8String]);
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientNumberOfPlaylistsChanged object:self];
}

- (BOOL) canGetPlaylistInfo {
	if (mpd_server_check_command_allowed(mConnection, "listPlaylistInfo"))
		return YES;
	return NO;
}

- (oneway void) fetchNamedPlaylist:(bycopy PlayListFile *)aPlayListFile {
	MpdData *data = mpd_database_get_playlist_content(mConnection, (char *)[[aPlayListFile filePath] UTF8String]);
	NSMutableArray *array = [NSMutableArray array];
	for (; data != NULL; data = mpd_data_get_next(data)) {
		[array addObject:[Song songWithMpd_Song:data->song]];
	}
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:array, dSongs, aPlayListFile, @"PlayListFile", nil];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientFetchedNamedPlaylist
																		object:self
																	  userInfo:dict];
}

- (oneway void) sendCurrentSongPosition {
	if ([self isConnected] == NO) return;
	[self setIncludeInNextStatus:MPD_CST_SONGPOS];
}

- (void) setIncludeInNextStatus:(int)what {
	mForcedStatusUpdates |= what;
}

#pragma mark Player Controll
- (oneway void) startPlayback {
	mpd_player_play(mConnection);
}

- (oneway void) pausePlayback {
	mpd_player_pause(mConnection);
}

- (oneway void) stopPlayback {
	mpd_player_stop(mConnection);
}

- (oneway void) next {
	mpd_player_next(mConnection);
}

- (oneway void) previous {
	mpd_player_prev(mConnection);
}

- (oneway void) skipToSong:(Song *)song {
	mpd_player_play_id(mConnection,[song remoteIdentifier]);
}

- (oneway void) setPlaybackVolume:(int)volume {
	mpd_status_set_volume(mConnection,volume);
}

- (oneway void) seek:(int)time {
	mpd_player_seek(mConnection,time);
}

#pragma mark Authentication
- (oneway void) setAuthenticationInformation:(NSDictionary *)info {
	[mPassword release];
	
	if ([info objectForKey:@"password"] != nil)
		mPassword = [[info objectForKey:@"password"] retain];
	else
		mPassword = nil;
	
	mSetPasswordCalled = YES;
}

#pragma mark Various
- (oneway void) toggleShuffle {
	mpd_player_set_random(mConnection, !mpd_player_get_random(mConnection));
}

- (oneway void) toggleRepeat {
	mpd_player_set_repeat(mConnection, !mpd_player_get_repeat(mConnection));
}

- (oneway void) playerWindowFocused {
	[self resetDelayForStatusUpdateTimer:0.5];
}

- (oneway void) playerWindowUnfocused {
	[self resetDelayForStatusUpdateTimer:1.2];
}

- (oneway void) playerWindowClosed {
	[self resetDelayForStatusUpdateTimer:5];
}

- (bycopy NSArray*) getOutputDevices {
	if (!mpd_server_check_version(mConnection, 0, 13, 0))
		return [NSArray array];
	
	MpdData *data = mpd_server_get_output_devices(mConnection);
	NSMutableArray *results = [NSMutableArray array];
	for (; data != NULL; data = mpd_data_get_next(data)) {
		[results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithBool:data->output_dev->enabled == 1 ? YES : NO], dEnabled,
							[NSString stringWithUTF8String:data->output_dev->name], dName,
							[NSNumber numberWithInt:data->output_dev->id], dId, nil]];
	}
	
	return results;
}

- (void) setOutputDeviceWithId:(int)theId toEnabled:(BOOL)enabled {
	mpd_server_set_output_device(mConnection, theId, enabled == YES ? 1 : 0);
}

@end
