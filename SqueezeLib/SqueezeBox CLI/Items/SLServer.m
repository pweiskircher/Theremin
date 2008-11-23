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

#import "SLServer.h"

static NSString *kServersServer = @"kServersServer";
static NSString *kServersPort = @"kServersPort";

@implementation SLServer
+ (SLServer *) serverFromUserDefaults:(NSDictionary *)udserver {
	SLServer *server = [[[SLServer alloc] init] autorelease];
	[server setServer:[udserver objectForKey:kServersServer]];
	[server setPort:[[udserver objectForKey:kServersPort] intValue]];
	return server;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		[self setPort:9090];
	}
	return self;
}

- (void) dealloc
{
	[_server release];
	[super dealloc];
}

- (NSDictionary *) userDefaults {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[self server], kServersServer,
		[NSNumber numberWithInt:[self port]], kServersPort,
			nil];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"Server %@:%d", [self server], [self port]];
}


- (NSString *) server {
	return [[_server retain] autorelease];
}

- (void) setServer:(NSString *)aServer {
	[_server release];
	_server = [aServer retain];
}


- (int) port {
	return _port;
}

- (void) setPort:(int)aPort {
	_port = aPort;
}


- (NSString *)title {
	return [NSString stringWithFormat:@"%@:%d", [self server], [self port]];
}

@end
