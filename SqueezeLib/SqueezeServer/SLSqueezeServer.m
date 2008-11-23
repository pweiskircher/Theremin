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


#import "SLSqueezeServer.h"

#import "SLCLIPlayerListRequest.h"
#import "SLCLIRequest.h"
#import "SLCLIPlayerRequest.h"
#import "SLCLICurrentPlaylistListRequest.h"
#import "SLCLISongInfoRequest.h"
#import "SLCLIPlayerPlaylistControlTrackIdRequest.h"
#import "SLCLITitleListRequest.h"
#import "SLCLIVolumeRequest.h"
#import "SLCLICurrentTitleTimeRequest.h"
#import "SLCLIArtistListRequest.h"

NSString *_userInfoVersionRequest = @"_userInfoVersionRequest";
NSString *_userInfoModeRequest = @"_userInfoModeRequest";
NSString *_userInfoCurrentIndex = @"_userInfoCurrentIndex";
NSString *_userInfoCurrentSong = @"_userInfoCurrentSong";

@interface SLSqueezeServer (PrivateMethods)
- (SLPlayPauseStatus) playPauseStatusStringToEnum:(NSString *)string;
@end

@implementation SLSqueezeServer
- (id) initWithServer:(SLServer *)server andCredentials:(SLCLICredentials *)someCredentials {
	self = [super init];
	if (self != nil) {
		_server = [server retain];
		_credentials = [someCredentials retain];
		
		_conn = [[SLCLIConnection alloc] initWithServer:[_server server] andPort:[_server port] andCredentials:_credentials];
		[_conn setDelegate:self];
	}
	return self;
}

- (void) dealloc
{
	[_credentials release];
	[_conn release];
	[_server release];
	[_player release];
	[super dealloc];
}

- (void) connectionError {
	if (_delegate)
		[_delegate serverError];
}

- (void) setPlayer:(SLPlayer *)player {
	[_player release];
	_player = [player retain];
}

- (void) setDelegate:(id)delegate {
	_delegate = delegate;
}

- (SLServer *) server {
	return [[_server retain] autorelease];
}

- (void) requestVersion {
	SLCLIRequest *request = [SLCLIRequest cliRequestWithCommand:@"version ?"];
	[request setUserInfo:_userInfoVersionRequest];
	[_conn scheduleRequest:request];
}

- (void) requestPlayerList {
	[_conn scheduleRequest:[SLCLIPlayerListRequest playerListRequest]];
}

- (void) requestNextSong {
	[_conn scheduleRequest:[SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:@"playlist index +1"]];	
}

- (void) requestPrevSong {
	[_conn scheduleRequest:[SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:@"playlist index -1"]];
}

- (void) requestPlaySongAtIndex:(int)index {
	[_conn scheduleRequest:[SLCLIPlayerRequest playerRequestWithPlayer:_player
														  andCommand:[NSString stringWithFormat:@"playlist index %d", index]]];
}

- (void) requestPause {
	[_conn scheduleRequest:[SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:@"pause 1"]];
}

- (void) requestPlay {
	[_conn scheduleRequest:[SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:@"pause 0"]];	
}

- (void) requestPlayPauseStatus {
	SLCLIPlayerRequest *request = [SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:@"mode ?"];
	[request setUserInfo:_userInfoModeRequest];
	[_conn scheduleRequest:request];
}

- (void) requestCurrentPlaylist {
	[_currentPlaylistRequest release];
	_currentPlaylistRequest = [[SLCLICurrentPlaylistListRequest currentPlaylistListRequestWithPlayer:_player] retain];
	[_conn scheduleRequest:_currentPlaylistRequest];
}

- (void) requestCurrentPlaylistIndex {
	SLCLIPlayerRequest *request = [SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:@"playlist index ?"];
	[request setUserInfo:_userInfoCurrentIndex];
	[_conn scheduleRequest:request];
}

- (void) requestRemovalOfTrackIds:(NSIndexSet *)trackIds {
	[_conn scheduleRequest:[SLCLIPlayerPlaylistControlTrackIdRequest playerPlaylistControlTrackIdRequestWithPlayer:_player andMode:SLCliPlayerPlaylistControlModeRemove andTrackIds:trackIds]];
}

- (void) requestClearPlaylist {
	[_conn scheduleRequest:[SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:@"playlistcontrol cmd:delete"]];
}

- (void) requestAddingOfTrackIds:(NSIndexSet *)trackIds {
	[_conn scheduleRequest:[SLCLIPlayerPlaylistControlTrackIdRequest playerPlaylistControlTrackIdRequestWithPlayer:_player andMode:SLCliPlayerPlaylistControlModeAdd andTrackIds:trackIds]];
}

- (void) requestMoveInCurrentPlaylistFrom:(int)src toDest:(int)dest {
	[_conn scheduleRequest:[SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:[NSString stringWithFormat:@"playlist move %d %d", src, dest]]];
}

- (void) requestCompleteDatabase {
	[_conn scheduleRequest:[SLCLITitleListRequest titleListRequestWithOffset:0]];
}

- (void) requestCurrentSong {
	SLCLIRequest *req = [SLCLIPlayerRequest playerRequestWithPlayer:_player andCommand:@"path ?"];
	[req setUserInfo:_userInfoCurrentSong];
	[_conn scheduleRequest:req];
}

- (void) requestCurrentSongElapsedTime {
	[_conn scheduleRequest:[SLCLICurrentTitleTimeRequest timeGetRequestForPlayer:_player]];
}

- (void) requestCurrentSongSeek:(int)aTime {
	[_conn scheduleRequest:[SLCLICurrentTitleTimeRequest timeSetRequestForPlayer:_player andTime:aTime]];
}

- (void) requestDifferentVolume:(int)aVolume {
	[_conn scheduleRequest:[SLCLIVolumeRequest volumeSetRequestForPlayer:_player andVolume:aVolume]];
}

- (void) requestAllArtists {
	[_conn scheduleRequest:[SLCLIArtistListRequest artistListRequestWithOffset:0]];
}

- (void) requestCompleted:(SLCLIRequest *)request {
	if (_delegate == nil)
		return;
	
	if ([request isKindOfClass:[SLCLIPlayerListRequest class]])
		[_delegate fetchedPlayerList:[(SLCLIPlayerListRequest *)request results]];
	else if ([request isKindOfClass:[SLCLICurrentPlaylistListRequest class]]) {
		SLCLIRequest *songInfoReq = [SLCLISongInfoRequest songInfoRequestWithPathList:[request results]];
		[songInfoReq setUserInfo:request];
		[_conn scheduleRequest:songInfoReq];
		[_delegate fetchedCurrentPlaylistLength:[[request results] count]];
	}
	else if ([request isKindOfClass:[SLCLISongInfoRequest class]] && [[request userInfo] isEqualTo:_currentPlaylistRequest]) {
		[_currentPlaylistRequest release], _currentPlaylistRequest = nil;
		[_delegate fetchedCurrentPlaylist:[request results]];
	}
	else if ([request isKindOfClass:[SLCLITitleListRequest class]])
		[_delegate fetchedCompleteDatabase:[request results]];
	else if ([[request userInfo] isEqualToString:_userInfoVersionRequest])
		[_delegate fetchedVersion:[[request splittedAndUnescapedResponse] objectAtIndex:1]];
	else if ([[request userInfo] isEqualToString:_userInfoModeRequest])
		[_delegate fetchedPlayPauseStatus:[self playPauseStatusStringToEnum:[[request splittedAndUnescapedResponse] objectAtIndex:2]]];
	else if ([[request userInfo] isEqualToString:_userInfoCurrentIndex])
		[_delegate fetchedCurrentPlaylistIndex:[[[request splittedAndUnescapedResponse] objectAtIndex:3] intValue]];
	else if ([[request userInfo] isEqualToString:_userInfoCurrentSong]) {
		NSArray *response = [request splittedAndUnescapedResponse];
		
		if ([[response objectAtIndex:1] isEqualToString:@"path"]) {
			SLCLIRequest *req = [SLCLISongInfoRequest songInfoRequestWithPathList:[NSArray arrayWithObject:[response objectAtIndex:2]]];
			[req setUserInfo:_userInfoCurrentSong];			
			[_conn scheduleRequest:req];
		} else {
			[_delegate fetchedCurrentSong:[[request results] objectAtIndex:0]];
		}
	} else if ([request isKindOfClass:[SLCLICurrentTitleTimeRequest class]]) {
		SLCLICurrentTitleTimeRequest *treq = (SLCLICurrentTitleTimeRequest*)request;
		if ([treq mode] == eCLIRequestModeGet)
			[_delegate fetchedCurrentSongElapsedTime:[(SLCLICurrentTitleTimeRequest*)request fetchedTime]];
	} else if ([request isKindOfClass:[SLCLIArtistListRequest class]])
		[_delegate fetchedAllArtists:[request results]];
}

- (void) request:(SLCLIRequest *)aRequest partialResult:(id)result {
	if ([aRequest isKindOfClass:[SLCLISongInfoRequest class]] && [[aRequest userInfo] isEqualTo:_currentPlaylistRequest])
		[_delegate fetchedCurrentPlaylistTrack:result forIndex:[(SLCLISongInfoRequest *)aRequest index]];
}

- (SLPlayPauseStatus) playPauseStatusStringToEnum:(NSString *)string {
	if ([string isEqualToString:@"play"])
		return ePlaying;
	else if ([string isEqualToString:@"stop"])
		return eStopped;
	else if ([string isEqualToString:@"pause"])
		return ePaused;
	
	[NSException raise:NSInternalInconsistencyException format:@"Received unknown playpause status."];
	
	// shutup, compiler.
	return eStopped;
}

@end
