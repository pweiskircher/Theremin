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

#import "SLServer.h"
#import "SLPlayer.h"
#import "SLCLIConnection.h"
#import "SLSqueezeServer.h"

@class SLSqueezeEventServer;

@protocol SLSqueezeEventServerDelegateProtocol
- (void) eventServer:(SLSqueezeEventServer *)server startedListeningToPlayer:(SLPlayer *)player;
- (void) eventServer:(SLSqueezeEventServer *)server stoppedListeningToPlayer:(SLPlayer *)player;
- (void) eventServer:(SLSqueezeEventServer *)server reportsConnectionError:(NSString *)error;

- (void) eventServer:(SLSqueezeEventServer *)server receivedPlayPauseStatus:(SLPlayPauseStatus)status;
- (void) eventServerReceivedPlayPauseToggle:(SLSqueezeEventServer *)server;
- (void) eventServer:(SLSqueezeEventServer *)server receivedPlaylistIndexChanged:(int)newIndex;
- (void) eventServerReceivedPlaylistChanged:(SLSqueezeEventServer *)server;
- (void) eventServer:(SLSqueezeEventServer *)server receivedNewVolume:(int)volume;
@end

@interface SLSqueezeEventServer : NSObject {
	SLServer *_server;
	SLPlayer *_player;
	SLCLICredentials *_credentials;
	
	SLCLIConnection *_conn;
	
	id _delegate;
	
	BOOL _inInitialQuery;
}
- (id) initWithServer:(SLServer *)server andPlayer:(SLPlayer *)player andCredentials:(SLCLICredentials *)someCredentials;

- (void) setDelegate:(id)delegate;

- (void) startListening;
- (void) stopListening;
@end
