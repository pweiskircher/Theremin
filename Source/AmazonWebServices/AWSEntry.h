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

#import <Cocoa/Cocoa.h>
#import "AWSController.h"

@interface AWSEntry : NSObject {
	NSDate *mTimeCreated;
	
	NSURL *mSmallImageURL, *mMediumImageURL, *mLargeImageURL, *mDetailPageURL;
	NSImage *mSmallImage, *mMediumImage, *mLargeImage;
}
+ (id) entryFromAmazonXML:(NSXMLDocument *)aXmlDocument;
- (id) init;
- (void) dealloc;

- (NSDate *) timeCreated;

- (NSURL *) smallImageURL;
- (NSURL *) mediumImageURL;
- (NSURL *) largeImageURL;
- (NSURL *) detailPageURL;

- (NSImage *) smallImage;
- (NSImage *) mediumImage;
- (NSImage *) largeImage;

@end

@interface AWSEntry (PrivateMethods)
- (void) setSmallImageURL:(NSURL *)aURL;
- (void) setMediumImageURL:(NSURL *)aURL;
- (void) setLargeImageURL:(NSURL *)aURL;
- (void) setDetailPageURL:(NSURL *)aURL;

- (void) setSmallImage:(NSImage *)theImage;
- (void) setMediumImage:(NSImage *)theImage;
- (void) setLargeImage:(NSImage *)theImage;
@end
