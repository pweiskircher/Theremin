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

#import "LastFmCoverArtDataSource.h"
#import "Song.h"
#import "ImageDownloader.h"

const NSString const *lastFmApiKey = @"473c630aee2cc135384d921854c2e2b5";
const NSString const *lastFmBaseMethodCall = @"http://ws.audioscrobbler.com/2.0/?method=album.getinfo";

@interface LastFmCoverArtDataSource (PrivateMethods)
- (NSURLRequest *) createUrlRequestForRequestWithSong:(Song *)aSong;
- (NSURL *) findImageUrlInXmlDocument:(NSXMLDocument *)aDocument;
@end

@implementation LastFmCoverArtDataSource

- (void) dealloc
{
	[_data release];
	[_song release];
	[super dealloc];
}


- (void) requestImageForSong:(Song *)aSong withSize:(CoverArtSize)aSize forDelegate:(id<CoverArtDataSourceDelegateProtocol>)aDelegate {
	if (_used)
		[NSException raise:NSInternalInconsistencyException format:@"LastFmCoverArtDataSource is single-use."];
	
	_used = YES;
	
	_size = aSize;
	_delegate = aDelegate;
	_data = [[NSMutableData data] retain];
	_song = [aSong retain];	
	
	if ([_song artist] == nil || [[_song artist] length] == 0 ||
		[_song album] == nil || [[_song album] length] == 0) {
		[_delegate dataSourceFailedToGetImage:self];
		return;
	}
	
	NSURLRequest *request = [self createUrlRequestForRequestWithSong:aSong];
	[[NSURLConnection connectionWithRequest:request delegate:self] retain];
}
@end

@implementation LastFmCoverArtDataSource (NSUrlConnectionDelegate)
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[connection autorelease];
	
	NSError *error;
	NSXMLDocument *xmlDocument = [[[NSXMLDocument alloc] initWithData:_data options:0 error:&error] autorelease];
	if (xmlDocument == nil) {
		NSLog(@"Couldn't fetch XML from Last.FM: %@", error);
		[_delegate dataSourceFailedToGetImage:self];
		return;
	}
	
	NSURL *imageUrl = [self findImageUrlInXmlDocument:xmlDocument];
	if (!imageUrl) {
		[_delegate dataSourceFailedToGetImage:self];
		return;
	}
	
	[[ImageDownloader imageDownloaderWithUrl:imageUrl andDelegate:self] retain];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[_delegate dataSourceFailedToGetImage:self];
	[connection autorelease];
}
@end

@implementation LastFmCoverArtDataSource (ImageDownloader)
- (void) imageDownloader:(ImageDownloader *)theImageDownloader receivedImage:(NSImage *)theImage {
	[_delegate dataSource:self foundImage:theImage forSong:_song withSize:_size];
	[theImageDownloader autorelease];
}

- (void) imageDownloaderFailed:(ImageDownloader *)theImageDownloader {
	[_delegate dataSourceFailedToGetImage:self];
	[theImageDownloader autorelease];
}
@end

@implementation LastFmCoverArtDataSource (PrivateMethods)
- (NSURLRequest *) createUrlRequestForRequestWithSong:(Song *)aSong {
	NSMutableString *url = [NSMutableString stringWithString:(NSString *)lastFmBaseMethodCall];
	
	[url appendFormat:@"&api_key=%@", lastFmApiKey];
	[url appendFormat:@"&album=%@", [[aSong album] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[url appendFormat:@"&artist=%@", [[aSong artist] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	return [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
}

- (NSURL *) findImageUrlInXmlDocument:(NSXMLDocument *)aDocument {
	NSArray *albumTags = [[aDocument rootElement] elementsForName:@"album"];
	if ([albumTags count] != 1) {
		NSLog(@"No album found from Last.FM");
		return nil;
	}
	
	NSArray *imageTags = [[albumTags objectAtIndex:0] elementsForName:@"image"];
	NSXMLElement *wantedImageTag = nil;
	for (int i = 0; i < [imageTags count]; i++) {
		NSXMLElement *element = [imageTags objectAtIndex:i];
		switch (_size) {
			case CoverArtSizeSmall:
				if ([[[element attributeForName:@"size"] stringValue] isEqualToString:@"small"])
					wantedImageTag = element;
				break;
				
			case CoverArtSizeRegular:
				if ([[[element attributeForName:@"size"] stringValue] isEqualToString:@"large"])
					wantedImageTag = element;
				break;
		}
		
		if (wantedImageTag != nil)
			break;
	}
	
	if (wantedImageTag == nil) {
		NSLog(@"No image found from Last.FM");
		return nil;
	}
	
	return [NSURL URLWithString:[wantedImageTag stringValue]];
}
@end