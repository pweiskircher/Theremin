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

#import "AWSEntry.h"


@implementation AWSEntry

+ (NSURL *) imageURLFromImageNode:(NSXMLNode *)imageNode {
	NSURL *url = nil;
	int height = -1, width = -1;
	
	for (int i = 0; i < [imageNode childCount]; i++) {
		NSXMLNode *child = [imageNode childAtIndex:i];
		if ([[child name] isEqualToString:@"URL"]) {
			url = [NSURL URLWithString:[child stringValue]];
		} else if ([[child name] isEqualToString:@"Height"]) {
			height = [[child stringValue] intValue];
		} else if ([[child name] isEqualToString:@"Width"]) {
			width = [[child stringValue] intValue];
		}
	}
	
	if (height <= 1 && width <= 1)
		return nil;
	return url;
}

+ (id) entryFromAmazonXML:(NSXMLDocument *)aXmlDocument {
	AWSEntry *entry = [[[AWSEntry alloc] init] autorelease];

	NSArray *firstItems = [aXmlDocument nodesForXPath:@"//Items/Item[1]" error:NULL];
	if (firstItems == nil || [firstItems count] <= 0)
		return entry;
	
	NSXMLNode *firstItem = [firstItems objectAtIndex:0];
	
	for (int i = 0; i < [firstItem childCount]; i++) {
		NSXMLNode *child = [firstItem childAtIndex:i];
		if ([[child name] isEqualToString:@"DetailPageURL"]) {
			[entry setDetailPageURL:[NSURL URLWithString:[child stringValue]]];
		} else if ([[child name] isEqualToString:@"SmallImage"]) {
			NSURL *url = [AWSEntry imageURLFromImageNode:child];
			if (url) [entry setSmallImageURL:url];
		} else if ([[child name] isEqualToString:@"MediumImage"]) {
			NSURL *url = [AWSEntry imageURLFromImageNode:child];
			if (url) [entry setMediumImageURL:url];
		} else if ([[child name] isEqualToString:@"LargeImage"]) {
			NSURL *url = [AWSEntry imageURLFromImageNode:child];
			if (url) [entry setLargeImageURL:url];
		}
	}
	
	return entry;
}

- (id) init {
	self = [super init];
	if (self != nil) {
		mTimeCreated = [[NSDate date] retain];
	}
	return self;
}

- (void) dealloc {
	//NSLog(@"entry dealloc");
	
	[mTimeCreated release], mTimeCreated = nil;
	
	[mSmallImageURL release], mSmallImageURL = nil;
	[mMediumImageURL release], mMediumImageURL = nil;
	[mLargeImageURL release], mLargeImageURL = nil;
	[mDetailPageURL release], mDetailPageURL = nil;
	
	[mSmallImage release], mSmallImage = nil;
	[mMediumImage release], mMediumImage = nil;
	[mLargeImage release], mLargeImage = nil;
	
	[super dealloc];
}

- (NSDate *) timeCreated {
	return [[mTimeCreated retain] autorelease];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"AWSENTRY <0x%08x>. SmallImageURL: %@ MediumImageURL: %@ LargeImageURL: %@ DetailPage: %@",
		self, [self smallImageURL], [self mediumImageURL], [self largeImageURL], [self detailPageURL]];
}

- (void) setSmallImageURL:(NSURL *)aURL {
	[mSmallImageURL release];
	mSmallImageURL = [aURL retain];
}

- (void) setMediumImageURL:(NSURL *)aURL {
	[mMediumImageURL release];
	mMediumImageURL = [aURL retain];
}

- (void) setLargeImageURL:(NSURL *)aURL {
	[mLargeImageURL release];
	mLargeImageURL = [aURL retain];
}

- (void) setDetailPageURL:(NSURL *)aURL {
	[mDetailPageURL release];
	mDetailPageURL = [aURL retain];
}


- (NSURL *) smallImageURL {
	return [[mSmallImageURL retain] autorelease];
}

- (NSURL *) mediumImageURL {
	return [[mMediumImageURL retain] autorelease];
}

- (NSURL *) largeImageURL {
	return [[mLargeImageURL retain] autorelease];
}

- (NSURL *) detailPageURL {
	return [[mDetailPageURL retain] autorelease];
}


- (NSImage *) smallImage {
	return [[mSmallImage retain] autorelease];
}

- (NSImage *) mediumImage {
	return [[mMediumImage retain] autorelease];
}

- (NSImage *) largeImage {
	return [[mLargeImage retain] autorelease];
}


- (void) setSmallImage:(NSImage *)theImage {
	[mSmallImage release], mSmallImage = [theImage retain];
}

- (void) setMediumImage:(NSImage *)theImage {
	[mMediumImage release], mMediumImage = [theImage retain];
}

- (void) setLargeImage:(NSImage *)theImage {
	[mLargeImage release], mLargeImage = [theImage retain];
}

@end
