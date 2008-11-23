//
//  SqueezeLibMusicServerClient.h
//  Theremin
//
//  Created by Patrik Weiskircher on 10.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MusicServerClient.h"

#import <SqueezeLib/SLSqueezeServer.h>
#import <SqueezeLib/SLServer.h>
#import <SqueezeLib/SLSqueezeEventServer.h>
#import <SqueezeLib/SLCLICredentials.h>

@interface SqueezeLibMusicServerClient : MusicServerClient <MusicServerClientInterface> {
	SLSqueezeServer *_serverConnection;
	SLSqueezeEventServer *_eventServerConnection;
	int _lastState;
	
	SLServer *_server;
	SLCLICredentials *_credentials;
	
	BOOL _connected;
	
	NSTimer *_elapsedTimeTimer;
	int _currentElapsedTime;
	
	NSArray *_currentPlayList;
}

@end
