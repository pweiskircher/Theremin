//
//  SqueezeLibMusicServerClient.m
//  Theremin
//
//  Created by Patrik Weiskircher on 10.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SqueezeLibMusicServerClient.h"
#import "NSNotificationAdditions.h"
#import "Song.h"
#import "SqueezeLibToThereminTransformer.h"
#import "NSArray+Transformations.h"

#import <SqueezeLib/SLTitle.h>

@interface SqueezeLibMusicServerClient (PrivateMethods)
- (NSArray *) trackIdsFromArray:(NSArray *)array;

- (void) startElapsedTimeTimerWithElapsedTime:(int)elapsed;
- (void) stopElapsedTimeTimer;
@end

@implementation SqueezeLibMusicServerClient
+ (unsigned int) capabilities {
	return 0;
}

- (oneway void) initialize {
	_lastState = eStateStopped;
}

- (void) dealloc
{
	[_serverConnection release];
	[_eventServerConnection release];
	[_server release];
	[_elapsedTimeTimer release];
	[_currentPlayList release];
	[super dealloc];
}


- (BOOL) isConnected {
	return _connected;
}

- (oneway void) connectToServerWithProfile:(Profile *)profile {
	[_server release];
	_server = [[SLServer alloc] init];
	[_server setServer:[profile hostname]];
	[_server setPort:[profile port]];
	
	[_credentials release];
	_credentials = [[SLCLICredentials cliCredentialsWithUsername:[profile user] andPassword:[profile password]] retain];
	
	_connected = NO;
	
	_serverConnection = [[SLSqueezeServer alloc] initWithServer:_server andCredentials:_credentials];
	[_serverConnection setDelegate:self];
	[_serverConnection requestPlayerList];
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientConnecting object:self];
}

- (oneway void) disconnectWithReason:(NSString *)reason {
	[self stopElapsedTimeTimer];
	
	[_serverConnection autorelease], _serverConnection = nil;
	[_eventServerConnection autorelease], _eventServerConnection = nil;
	
	_connected = NO;
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientDisconnected object:self userInfo:[NSDictionary dictionaryWithObject:reason forKey:dDisconnectReason]];
}

#pragma mark -
#pragma mark Playlist

- (oneway void) startFetchPlaylist {
	[_serverConnection requestCurrentPlaylist];
}

- (oneway void) removeSongsFromPlaylist:(NSArray *)songs {
	[_serverConnection requestRemovalOfTrackIds:[self trackIdsFromArray:songs]];
	[_serverConnection requestCurrentPlaylistIndex];
}

- (oneway void) clearPlaylist {
	[_serverConnection requestClearPlaylist];
}

- (oneway void) addSongsToPlaylistByUniqueIdentifier:(NSArray *)uniqueIdentifiers {
	[_serverConnection requestAddingOfTrackIds:[self trackIdsFromArray:uniqueIdentifiers]];
}

- (oneway void) moveSongFromPosition:(int)src toPosition:(int)dest {
	[_serverConnection requestMoveInCurrentPlaylistFrom:src toDest:dest];
	[_serverConnection requestCurrentPlaylistIndex];
}

- (oneway void) sendCurrentSongPosition {
	[_serverConnection requestCurrentPlaylistIndex];
}

#pragma mark -
#pragma mark Playback control

- (oneway void) startPlayback {
	[_serverConnection requestPlay];
}

- (oneway void) pausePlayback {
	[_serverConnection requestPause];	
}

- (oneway void) stopPlayback {
}

- (oneway void) next {
	[_serverConnection requestNextSong];
}

- (oneway void) previous {
	[_serverConnection requestPrevSong];
}

- (oneway void) skipToSong:(bycopy Song *)song {
	int index = [_currentPlayList indexOfObject:song];
	
	if (index == NSNotFound)
		return;
	
	[_serverConnection requestPlaySongAtIndex:index];
}

- (oneway void) seek:(int)time {
	[_serverConnection requestCurrentSongSeek:time];
	[self startElapsedTimeTimerWithElapsedTime:time];
}


#pragma mark -
#pragma mark Player Control

- (oneway void) setPlaybackVolume:(int)volume {
	[_serverConnection requestDifferentVolume:volume];
}


#pragma mark -
#pragma mark Server Connection

- (void) fetchedPlayerList:(NSArray *)players {
	_connected = YES;
	
	if (players == nil || [players count] == 0) {
		[self disconnectWithReason:@"No players found. Please check your authentication credentials."];
		return;
	}
	
	[_serverConnection setPlayer:[players objectAtIndex:0]];
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientConnected object:self];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientPlaylistChanged object:self];	
	
	[_eventServerConnection release];
	_eventServerConnection = [[SLSqueezeEventServer alloc] initWithServer:_server andPlayer:[players objectAtIndex:0] andCredentials:_credentials];
	[_eventServerConnection setDelegate:self];
	[_eventServerConnection startListening];
}

- (void) fetchedVersion:(NSString *)version {

}

- (void) fetchedPlayPauseStatus:(SLPlayPauseStatus)status {
	
}

- (void) fetchedCurrentPlaylistIndex:(int)index {
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientCurrentSongPositionChanged
																		object:self
																	  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:dSongPosition]];
}

- (void) fetchedCurrentPlaylist:(NSArray *)playlist {
	[_currentPlayList release];
	_currentPlayList = [[playlist arrayByApplyingTransformationUsingTarget:[SqueezeLibToThereminTransformer class] andSelector:@selector(slTitleToSongTransform:)] retain];
	
//	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientFetchedPlaylist
//																	    object:self
//																	  userInfo:[NSDictionary dictionaryWithObject:result forKey:dSongs]];
}

- (void) fetchedCurrentPlaylistTrack:(SLTitle *)aTitle forIndex:(int)index {
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientFetchedTitleForPlaylist
																		object:self
																	  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[SqueezeLibToThereminTransformer slTitleToSongTransform:aTitle], dSong, [NSNumber numberWithInt:index], dSongPosition, nil]];
}

- (void) fetchedCurrentPlaylistLength:(int)length {
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientFetchedPlaylistLength
																		object:self
																	  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:length], dPlaylistLength, nil]];
}

- (void) fetchedCompleteDatabase:(NSArray *)titles {
	NSMutableArray *songs = [NSMutableArray arrayWithCapacity:[titles count]];
	for (int i = 0; i < [titles count]; i++)
		[songs addObject:[SqueezeLibToThereminTransformer slTitleToSongTransform:[titles objectAtIndex:i]]];
	
	NSDictionary *infos = [NSDictionary dictionaryWithObjectsAndKeys:songs, dSongs, @"gugu", dDatabaseIdentifier, nil];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientFetchedDatabase
																		object:self
																	  userInfo:infos];
}

- (void) fetchedCurrentSong:(SLTitle *)song {
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientCurrentSongChanged
																		object:self
																	  userInfo:[NSDictionary dictionaryWithObject:[SqueezeLibToThereminTransformer slTitleToSongTransform:song] forKey:dSong]];
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientTotalTimeChanged
																		object:self
																	  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[song duration]] forKey:dTotalTime]];
}

- (void) fetchedCurrentSongElapsedTime:(int)elapsed {
	if (_lastState == eStatePlaying)
		[self startElapsedTimeTimerWithElapsedTime:elapsed];
}

- (void) serverError {
	_connected = NO;
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientDisconnected object:self userInfo:[NSDictionary dictionaryWithObject:@"..." forKey:dDisconnectReason]];
	
	[_eventServerConnection release], _eventServerConnection = nil;
}

#pragma mark -
#pragma mark Event Server

- (void) eventServer:(SLSqueezeEventServer *)server startedListeningToPlayer:(SLPlayer *)player {
}
- (void) eventServer:(SLSqueezeEventServer *)server stoppedListeningToPlayer:(SLPlayer *)player {
}

- (void) eventServer:(SLSqueezeEventServer *)server reportsConnectionError:(NSString *)error {
	[self disconnectWithReason:@"Event Server reported error"];
	[_eventServerConnection release], _eventServerConnection = nil;
}

- (void) eventServer:(SLSqueezeEventServer *)server receivedPlayPauseStatus:(SLPlayPauseStatus)status {
	int state = 0;
	switch(status) {
		case eStopped: state = eStateStopped; break;
		case ePaused: state = eStatePaused; break;
		case ePlaying: state = eStatePlaying; break;
	}
	
	if (state != eStatePlaying)
		[self stopElapsedTimeTimer];
	else
		[_serverConnection requestCurrentSongElapsedTime];
	
	_lastState = state;
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientStateChanged
																		object:self
																	  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:state] forKey:dState]];
}

- (void) eventServerReceivedPlayPauseToggle:(SLSqueezeEventServer *)server {
	int state = _lastState == eStatePlaying ? eStatePaused : eStatePlaying;
	_lastState = state;
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientStateChanged
																		object:self
																	  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:state] forKey:dState]];
	
}

- (void) eventServer:(SLSqueezeEventServer *)server receivedPlaylistIndexChanged:(int)newIndex {

	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientCurrentSongPositionChanged
																		object:self
																	  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:newIndex] forKey:dSongPosition]];
	
	[self stopElapsedTimeTimer];
	[_serverConnection requestCurrentSong];
	[_serverConnection requestCurrentSongElapsedTime];
}

- (void) eventServerReceivedPlaylistChanged:(SLSqueezeEventServer *)server {
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientPlaylistChanged
																		object:self];
}

- (void) eventServer:(SLSqueezeEventServer *)server receivedNewVolume:(int)volume {
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientVolumeChanged
																		object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:volume] forKey:dVolume]];
}

#pragma mark -
#pragma mark Named Playlists - not yet implemented

- (oneway void) loadPlaylist:(bycopy PlayListFile *)aPlayListFile {
	
}

- (oneway void) saveCurrentPlaylistAs:(NSString *)aPlayListName {
	
}

- (oneway void) deletePlaylist:(bycopy PlayListFile *)aPlayListFile {
	
}

- (BOOL) canGetPlaylistInfo {
	return NO;
}

- (oneway void) fetchNamedPlaylist:(bycopy PlayListFile *)aPlayListFile {
	
}

#pragma mark -
#pragma mark To Be Implemented

- (bycopy Song *) songInformationByUniqueIdentifier:(NSData *)aUniqueIdentifier {
	return nil;
}


- (oneway void) toggleShuffle {
	
}
- (oneway void) toggleRepeat {
	
}

- (oneway void) playerWindowFocused {
	
}
- (oneway void) playerWindowUnfocused {
	
}
- (oneway void) playerWindowClosed {
	
}

- (oneway void) setAuthenticationInformation:(NSDictionary *)info {
	
}

#pragma mark -
#pragma mark Private Stuff

- (NSArray *) trackIdsFromArray:(NSArray *)array {
	NSMutableArray *trackIds = [NSMutableArray array];
	int trackId;
	
	for (int i = 0; i < [array count]; i++) {
		id obj = [array objectAtIndex:i];
		NSData *uniqueIdentifier = [obj isKindOfClass:[NSData class]] ? obj : [obj uniqueIdentifier];
		[uniqueIdentifier getBytes:&trackId length:sizeof(trackId)];
		[trackIds addObject:[NSNumber numberWithInt:trackId]];
	}

	return trackIds;
}

- (void) startElapsedTimeTimerWithElapsedTime:(int)elapsed {
	_currentElapsedTime = elapsed;

	[self stopElapsedTimeTimer];
	_elapsedTimeTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(elapsedTimeTimerTriggered:) userInfo:nil repeats:YES] retain];
}

- (void) stopElapsedTimeTimer {
	[_elapsedTimeTimer invalidate];
	[_elapsedTimeTimer release], _elapsedTimeTimer = nil;	
}

- (void) elapsedTimeTimerTriggered:(NSTimer *)timer {
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nMusicServerClientElapsedTimeChanged
																		object:self
																	  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_currentElapsedTime] forKey:dElapsedTime]];
	_currentElapsedTime++;
	
	if ( (_currentElapsedTime % 15) == 0)
		[_serverConnection requestCurrentSongElapsedTime];
}

- (void) stop {
	[_elapsedTimeTimer invalidate];
	[_elapsedTimeTimer release], _elapsedTimeTimer = nil;
	
	[super stop];
}

@end
