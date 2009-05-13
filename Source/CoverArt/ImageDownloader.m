/*
 Copyright (C) 2009  Patrik Weiskircher
 
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

#import "ImageDownloader.h"

@interface ImageDownloader (PrivateMethods)
- (void) startDownload:(NSURL *)aUrl;
@end

@implementation ImageDownloader
+ (id) imageDownloaderWithUrl:(NSURL *)aUrl andDelegate:(id)aDelegate {
	return [[[ImageDownloader alloc] initWithUrl:aUrl andDelegate:aDelegate] autorelease];
}

- (id) initWithUrl:(NSURL *)aUrl andDelegate:(id)aDelegate {
	self = [super init];
	if (self != nil) {
		_delegate = aDelegate;
		_data = [[NSMutableData data] retain];
		[self startDownload:aUrl];
	}
	return self;
}

- (void) dealloc
{
	[_data release];
	[super dealloc];
}

@end

@implementation ImageDownloader (PrivateMethods)
- (void) startDownload:(NSURL *)aUrl {
	NSURLRequest *request = [NSURLRequest requestWithURL:aUrl];
	[[NSURLConnection connectionWithRequest:request delegate:self] retain];
}
@end

@implementation ImageDownloader (URLConnectionDelegate)
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[connection autorelease];
	
	NSImage *image = [[[NSImage alloc] initWithData:_data] autorelease];
	if (image == nil) {
		[_delegate imageDownloaderFailed:self];
		return;
	}
	
	[_delegate imageDownloader:self receivedImage:image];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[_delegate imageDownloaderFailed:self];
	[connection autorelease];
}
@end
