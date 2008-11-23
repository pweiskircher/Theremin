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

#import "AWSRequest.h"
#import "AWSController.h"
#import "Song.h"
#import "AWSEntry.h"
#import "WindowController.h"
#import "PreferencesController.h"

@implementation AWSRequest
- (id) initRequestWithType:(AWSRequestType)theType andSong:(Song *)theSong andController:(AWSController *)controller {
	self = [super init];
	if (self != nil) {
		mType = theType;
		mSong = [theSong retain];
		mController = controller;
	}
	return self;
}

- (void) dealloc {
	[mSong release], mSong = nil;
	[mConnection release], mConnection = nil;
	[mData release], mData = nil;
	[mEntry release], mEntry = nil;
	[super dealloc];
}

- (NSString *) notificationForType:(AWSRequestType)type {
	switch (type) {
		case eSmallImage:
			return nFetchedSmallImageForSong;
		case eMediumImage:
			return nFetchedMediumImageForSong;
		case eLargeImage:
			return nFetchedLargeImageForSong;
		case eDetailPageUrl:
			return nFetchedDetailURLForSong;
	}
	
	return nil;
}

- (void) sendErrorWithMessage:(NSString *)errorMessage {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:mSong forKey:nAWSSongEntry];
	[dict setObject:errorMessage forKey:nAWSErrorEntry];
	[[NSNotificationCenter defaultCenter] postNotificationName:[self notificationForType:mType]
														object:mController
													  userInfo:dict];
	[mController requestFinished:self];
}

- (BOOL) execute {
	if ([mSong artistIsUnknown] || [mSong albumIsUnknown] || [mSong artist] == nil || [mSong album] == nil) {
		[self sendErrorWithMessage:NSLocalizedString(@"Artist or Album is unknown, can't fetch anything.", @"")];
		return NO;
	}
	
	if ([[[WindowController instance] preferences] coverArtEnabled] == NO) {
		[self sendErrorWithMessage:NSLocalizedString(@"Cover Art disabled.", @"")];
		return NO;
	}
	
	AWSEntry *entry = [mController entryForSong:mSong];
	if (!entry) {
		//NSLog(@"requesting entry");
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fetchedEntry:)
													 name:nFetchedEntryForSong
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fetchedEntry:)
													 name:nFailedToFetchEntryForSong
												   object:nil];
		
		return [mController fetchEntryForSong:mSong];
	}
	
	//NSLog(@"found entry");
	
	NSURL *download = nil;
	NSImage *image = nil;
	switch (mType) {
		case eSmallImage:
			image = [entry smallImage];
			download = [entry smallImageURL];
			break;
			
		case eMediumImage:
			image = [entry mediumImage];
			download = [entry mediumImageURL];
			break;
			
		case eLargeImage:
			image = [entry largeImage];
			download = [entry largeImageURL];
			break;
			
		case eDetailPageUrl:
		{
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			
			[dict setObject:mSong forKey:nAWSSongEntry];
			
			NSURL *detailPageURL = [entry detailPageURL];
			if (detailPageURL) {
				[dict setObject:detailPageURL forKey:nAWSURLEntry];
			} else {
				[dict setObject:NSLocalizedString(@"No Detail Page available.", @"Error message if no detail page was found.") forKey:nAWSErrorEntry];
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName:nFetchedDetailURLForSong
																object:mController
															  userInfo:dict];
			[mController requestFinished:self];
			return YES;
		}
	}
	
	if (image) {
		//NSLog(@"found image.");
		
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:mSong forKey:nAWSSongEntry];
		[dict setObject:image forKey:nAWSImageEntry];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:[self notificationForType:mType]
															object:mController
														  userInfo:dict];
		[mController requestFinished:self];
	} else if (download) {
		//NSLog(@"fetching image %@", download);
		mEntry = [entry retain];
		mConnection = [[NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:download] delegate:self] retain];
	} else {
		[self sendErrorWithMessage:NSLocalizedString(@"No image available.", @"")];
		return NO;
	}
	
	return YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self sendErrorWithMessage:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Could not fetch data:", @"Error message if unable to fetch stuff from amazon"),
		[error localizedDescription]]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (!mData) mData = [[NSMutableData data] retain];
	[mData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:mSong forKey:nAWSSongEntry];

	NSImage *image = [[[NSImage alloc] initWithData:mData] autorelease];
	if (image) {
		[dict setObject:image forKey:nAWSImageEntry];

		if (mEntry) {
			switch (mType) {
				case eSmallImage:
					[mEntry setSmallImage:image];
					break;
					
				case eMediumImage:
					[mEntry setMediumImage:image];
					break;
					
				case eLargeImage:
					[mEntry setLargeImage:image];
					break;
			}
		}
		
	} else {
		[dict setObject:NSLocalizedString(@"Could not get image.", @"Error message if unable to make image from data") forKey:nAWSErrorEntry];			
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:[self notificationForType:mType]
														object:mController
													  userInfo:dict];
	[mController requestFinished:self];
}

- (void) fetchedEntry:(NSNotification *)aNotification {
	Song *song = [[aNotification userInfo] objectForKey:nAWSSongEntry];
	if ([[song uniqueIdentifier] isEqualTo:[mSong uniqueIdentifier]]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[self execute];
		return;
	}
}

@end
