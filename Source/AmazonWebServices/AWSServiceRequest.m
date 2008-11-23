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

#import "AWSServiceRequest.h"
#import "AWSController.h"
#import "Song.h"

static NSString *iKeywords = @"iKeywords";
static NSString *iSearchIndex = @"iSearchIndex";
static NSString *iTitle = @"iTitle";
static NSString *iArtist = @"iArtist";
static NSString *iResponseGroups = @"iResponseGroups";

NSString *nServiceRequestSucceeded = @"nServiceRequestSucceeded";
NSString *nServiceRequestFailed = @"nServiceRequestFailed";

@implementation AWSServiceRequest
- (id) init {
	self = [super init];
	if (self != nil) {
		mValues = [[NSMutableDictionary dictionary] retain];
		mData = nil;
		mConnection = nil;
		mSong = nil;
	}
	return self;
}

- (void) dealloc {
	[mValues release], mValues = nil;
	[mSong release], mSong = nil;
	[mConnection release], mConnection = nil;
	[mData release], mData = nil;
	[super dealloc];
}

- (void) setKeywords:(NSString *)theKeywords {
	[mValues setObject:theKeywords forKey:iKeywords];
}

- (NSString *) keywords {
	NSString *s = [mValues objectForKey:iKeywords];
	if (s)
		return [NSString stringWithString:s];
	return nil;
}


- (void) setSearchIndex:(AWSSearchIndex)theIndex {
	[mValues setObject:[NSNumber numberWithUnsignedInt:theIndex] forKey:iSearchIndex];
}

- (AWSSearchIndex) searchIndex {
	NSNumber *n = [mValues objectForKey:iSearchIndex];
	if (n)
		return [n unsignedIntValue];
	return -1;
}


- (void) setTitle:(NSString *)theTitle {
	[mValues setObject:theTitle forKey:iTitle];
}

- (NSString *) title {
	NSString *s = [mValues objectForKey:iTitle];
	if (s)
		return [NSString stringWithString:s];
	return nil;
}


- (void) setArtist:(NSString *)theArtist {
	[mValues setObject:theArtist forKey:iArtist];
}

- (NSString *) artist {
	NSString *s = [mValues objectForKey:iArtist];
	if (s)
		return [NSString stringWithString:s];
	return nil;
}

- (void) setSong:(Song *)theSong {
	mSong = [theSong retain];
	[self setTitle:[theSong album]];
	[self setArtist:[theSong artist]];
}

- (Song *) song {
	return mSong;
}

- (void) setResponseGroups:(int)theResponseGroups {
	[mValues setObject:[NSNumber numberWithInt:theResponseGroups] forKey:iResponseGroups];
}

- (int) responseGroups {
	NSNumber *n = [mValues objectForKey:iResponseGroups];
	if (n)
		return [n intValue];
	return -1;
}


- (void) executeRequest {
	NSURL *baseURL = [[self controller] baseURLForCurrentLocale];
	if (!baseURL) {
		[NSException raise:NSInternalInconsistencyException format:@"Could not get base url for current locale"];
	}
	
	NSMutableString *url = [NSMutableString stringWithString:[baseURL absoluteString]];
	
	NSString *accessKeyId = [[self controller] accessKeyId];
	if (!accessKeyId) {
		[NSException raise:NSInternalInconsistencyException format:@"No access ID set."];
	}
	[url appendFormat:@"&AWSAccessKeyId=%@", [accessKeyId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *associateId = [[self controller] associateIdForCurrentLocale];
	if (associateId)
		[url appendFormat:@"&AssociateTag=%@", [associateId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	[url appendString:@"&Operation=ItemSearch"];
	[url appendFormat:@"&SearchIndex=%@", [[self searchIndexToString:[self searchIndex]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[url appendFormat:@"&ResponseGroup=%@", [[self responseGroupToString:[self responseGroups]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

	NSString *s;
#define ADD_ONE_VALUE_TO_URL(methodName, format) \
	s = [self methodName]; \
	if (s) [url appendFormat:format, [s stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	ADD_ONE_VALUE_TO_URL(keywords, @"&Keywords=%@");
	ADD_ONE_VALUE_TO_URL(title, @"&Title=%@");
	ADD_ONE_VALUE_TO_URL(artist, @"&Artist=%@");
	
#undef ADD_ONE_VALUE_TO_URL
	
	mConnection = [[NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] 
												 delegate:self] retain];
}

- (AWSController *) controller {
	return [AWSController defaultController];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:nServiceRequestFailed object:self userInfo:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (!mData) mData = [[NSMutableData data] retain];
	
	[mData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSString *xml = [[[NSString alloc] initWithData:mData encoding:NSUTF8StringEncoding] autorelease];
	[mData release], mData = nil;

	if (xml) {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:xml, @"XmlData", nil];
	
		[[NSNotificationCenter defaultCenter] postNotificationName:nServiceRequestSucceeded object:self userInfo:dict];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:nServiceRequestFailed object:self userInfo:nil];
	}
}


- (NSString *) responseGroupToString:(int)responseGroup {
	NSMutableString *s = [NSMutableString string];
	if (responseGroup & eAWSImages)
		[s appendString:@"Images"];
	
	if (responseGroup & eAWSSmall) {
		if ([s length])
			[s appendString:@","];
		[s appendString:@"Small"];
	}
	
	return [NSString stringWithString:s];
}

- (NSString *) searchIndexToString:(int)searchIndex {
	if (searchIndex == eAWSMusic)
		return @"Music";
	return nil;
}

@end
