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

#import "AWSController.h"
#import "WindowController.h"
#import "PreferencesController.h"
#import "AWSRequest.h"
#import "AWSServiceRequest.h"
#import "Song.h"
#import "AWSEntry.h"

static AWSController *defaultController;

NSString *nFetchedSmallImageForSong = @"nFetchedSmallImageForSong";
NSString *nFetchedMediumImageForSong = @"nFetchedMediumImageForSong";
NSString *nFetchedLargeImageForSong = @"nFetchedLargeImageForSong";
NSString *nFetchedDetailURLForSong = @"nFetchedDetailURLForSong";

NSString *nFetchedEntryForSong = @"nFetchedEntryForSong";
NSString *nFailedToFetchEntryForSong = @"nFailedToFetchEntryForSong";

NSString *nAWSSongEntry = @"nAWSSongEntry";
NSString *nAWSErrorEntry = @"nAWSErrorEntry";
NSString *nAWSURLEntry = @"nAWSURLEntry";
NSString *nAWSImageEntry = @"nAWSImageEntry";

#define INVALIDATE_TIMER_DELAY	60*60
#define INVALIDATE_ENTRY_DELAY	60*60

@implementation AWSController
+ (id) defaultController {
	if (!defaultController) {
		defaultController = [[AWSController alloc] init];
		
		[defaultController registerAccessKeyId:@"04C63ZJQHKPMVCGN70R2"];
		[defaultController registerAssociateId:@"thempdcli-20" withLocale:eAWSUs];
		[defaultController registerAssociateId:@"theremin07-21" withLocale:eAWSUk];
		[defaultController registerAssociateId:@"theremin-21" withLocale:eAWSDe];
		[defaultController setAutosetLocale:YES];
	}
	
	return defaultController;
}

- (id) init {
	self = [super init];
	if (self != nil) {
		mRequests = [[NSMutableSet set] retain];
		mServiceRequests = [[NSMutableDictionary dictionary] retain];
		mEntries = [[NSMutableDictionary dictionary] retain];
		
		mInvalidateEntriesTimer = [NSTimer scheduledTimerWithTimeInterval:INVALIDATE_TIMER_DELAY
																   target:self
																 selector:@selector(invalidateEntries:)
																 userInfo:nil
																  repeats:YES];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mAccessKey release], mAccessKey = nil;
	[mAssociateIds release], mAssociateIds = nil;
	[mRequests release], mRequests = nil;
	[mServiceRequests release], mServiceRequests = nil;
	[mEntries release], mEntries = nil;
	
	[mInvalidateEntriesTimer invalidate];
	[mInvalidateEntriesTimer release], mInvalidateEntriesTimer = nil;
	[super dealloc];
}

- (void) invalidateEntries:(NSTimer *) theTimer {
	NSEnumerator *enumerator = [mEntries keyEnumerator];
	id key;
	NSMutableArray *keysToRemove = [NSMutableArray array];
	
	while (key = [enumerator nextObject]) {
		AWSEntry *entry = [mEntries objectForKey:key];
		if ([[entry timeCreated] timeIntervalSinceNow] < -(INVALIDATE_ENTRY_DELAY)) {
			[keysToRemove addObject:key];
		}
	}
	
	[mEntries removeObjectsForKeys:keysToRemove];
}

- (void) registerAssociateId:(NSString *)theId withLocale:(AWSLocale)theLocale {
	if (!mAssociateIds) {
		mAssociateIds = [[NSMutableDictionary dictionary] retain];
	}
	
	[mAssociateIds setObject:theId forKey:[NSNumber numberWithInt:theLocale]];
}

- (NSString *) associateIdForLocale:(AWSLocale)theLocale {
	return [mAssociateIds objectForKey:[NSNumber numberWithInt:theLocale]];
}

- (void) registerAccessKeyId:(NSString *)theAccessKey {
	mAccessKey = [theAccessKey retain];
}

- (NSString *) accessKeyId {
	return [NSString stringWithString:mAccessKey];
}

- (void) setLocale:(AWSLocale)theLocale {
	mLocale = theLocale;
}

- (AWSLocale) locale {
	return mLocale;
}

- (void) setAutosetLocale:(BOOL)aBool {
	if (aBool == YES) {
		mLocale = [self currentAppLocale];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(preferencesChanged:)
													 name:nCoverArtLocaleChanged
												   object:nil];
	} else {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nCoverArtLocaleChanged object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nCoverArtEnabledChanged object:nil];
	}
}

- (void) setEnabled:(BOOL)aValue {
	mEnabled = aValue;
}

- (BOOL) enabled {
	return mEnabled;
}

- (void) setAutosetEnabled:(BOOL)aBool {
	if (aBool == YES) {
		mEnabled = [[[WindowController instance] preferences] coverArtEnabled];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(preferencesChanged:)
													 name:nCoverArtEnabledChanged
												   object:nil];
	} else {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nCoverArtEnabledChanged object:nil];
	}
}

- (BOOL) fetchSmallImageForSong:(Song *)aSong {
	AWSRequest *request = [[[AWSRequest alloc] initRequestWithType:eSmallImage andSong:aSong andController:self] autorelease];
	[mRequests addObject:request];
	return [request execute];
}

- (BOOL) fetchMediumImageForSong:(Song *)aSong {
	AWSRequest *request = [[[AWSRequest alloc] initRequestWithType:eMediumImage andSong:aSong andController:self] autorelease];
	[mRequests addObject:request];
	return [request execute];	
}

- (BOOL) fetchLargeImageForSong:(Song *)aSong {
	AWSRequest *request = [[[AWSRequest alloc] initRequestWithType:eLargeImage andSong:aSong andController:self] autorelease];
	[mRequests addObject:request];
	return [request execute];	
}

- (BOOL) fetchDetailURLForSong:(Song *)aSong {
	AWSRequest *request = [[[AWSRequest alloc] initRequestWithType:eDetailPageUrl andSong:aSong andController:self] autorelease];
	[mRequests addObject:request];
	return [request execute];	
}

- (NSURL *) baseURLForLocale:(AWSLocale)theLocale {
	switch (theLocale) {
		case eAWSDe:
			return [NSURL URLWithString:@"http://ecs.amazonaws.de/onca/xml?Service=AWSECommerceService"];
		case eAWSFr:
			return [NSURL URLWithString:@"http://ecs.amazonaws.fr/onca/xml?Service=AWSECommerceService"];
		case eAWSJp:
			return [NSURL URLWithString:@"http://ecs.amazonaws.jp/onca/xml?Service=AWSECommerceService"];
		case eAWSUk:
			return [NSURL URLWithString:@"http://ecs.amazonaws.co.uk/onca/xml?Service=AWSECommerceService"];
		case eAWSUs:
			return [NSURL URLWithString:@"http://ecs.amazonaws.com/onca/xml?Service=AWSECommerceService"];
	}
	return nil;
}

- (NSString *) associateIdForCurrentLocale {
	return [self associateIdForLocale:[self locale]];
}

- (NSURL *) baseURLForCurrentLocale {
	return [self baseURLForLocale:[self locale]];
}

- (AWSLocale) currentAppLocale {
	NSString *locale = [[[WindowController instance] preferences] coverArtLocale];
	if ([locale isEqual:@"de"]) {
		return eAWSDe;
	} else if ([locale isEqualToString:@"fr"]) {
		return eAWSFr;
	} else if ([locale isEqualToString:@"jp"]) {
		return eAWSJp;
	} else if ([locale isEqualToString:@"uk"]) {
		return eAWSUk;
	} else if ([locale isEqualToString:@"us"]) {
		return eAWSUs;
	}
	
	return -1;
}

- (void) preferencesChanged:(NSNotification *)notification {
	if ([[notification name] isEqualTo:nCoverArtEnabledChanged]) {
		mEnabled = [[[WindowController instance] preferences] coverArtEnabled];
	} else if ([[notification name] isEqualTo:nCoverArtLocaleChanged]) {
		mLocale = [self currentAppLocale];
	}
	
	[mEntries removeAllObjects];
}

- (AWSEntry *) entryForSong:(Song *)theSong {
	return [mEntries objectForKey:[theSong albumIdentifier]];
}

- (BOOL) fetchEntryForSong:(Song *)theSong {
	AWSServiceRequest *request = [mServiceRequests objectForKey:[theSong albumIdentifier]];
	if (!request) {
		request = [[[AWSServiceRequest alloc] init] autorelease];
		
		[request setSearchIndex:eAWSMusic];
		[request setSong:theSong];
		[request setResponseGroups:eAWSImages | eAWSSmall];
		
		[mServiceRequests setObject:request forKey:[theSong albumIdentifier]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(serviceRequestFinished:)
													 name:nServiceRequestSucceeded
												   object:request];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(serviceRequestFinished:)
													 name:nServiceRequestFailed
												   object:request];
		
		[request executeRequest];
	}
	
	return YES;
}

- (void) serviceRequestFinished:(NSNotification *)aNotification {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:nil
												  object:[aNotification object]];
	Song *song = [[aNotification object] song];
	[mServiceRequests removeObjectForKey:[song albumIdentifier]];
	
	if ([[aNotification name] isEqual:nServiceRequestFailed]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:nFailedToFetchEntryForSong 
															object:self 
														  userInfo:[NSDictionary dictionaryWithObject:song forKey:nAWSSongEntry]];
		return;
	} else if ([[aNotification name] isEqual:nServiceRequestSucceeded]) {
		NSError *error = nil;
		NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:[[aNotification userInfo] objectForKey:@"XmlData"] options:NSXMLDocumentTidyXML error:&error] autorelease];
		if (error != nil) {
			[[NSNotificationCenter defaultCenter] postNotificationName:nFailedToFetchEntryForSong 
																object:self 
															  userInfo:[NSDictionary dictionaryWithObject:song forKey:nAWSSongEntry]];
			return;
		}
		
		AWSEntry *entry = [AWSEntry entryFromAmazonXML:doc];
		if (entry == nil) {
			[[NSNotificationCenter defaultCenter] postNotificationName:nFailedToFetchEntryForSong 
																object:self 
															  userInfo:[NSDictionary dictionaryWithObject:song forKey:nAWSSongEntry]];
			return;			
		}
		
		[mEntries setObject:entry forKey:[song albumIdentifier]];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:nFetchedEntryForSong
															object:self
														  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:song, nAWSSongEntry, entry, @"entry", nil]];
	}
}

- (void) requestFinished:(AWSRequest *)theRequest {
	[mRequests removeObject:theRequest];
}

@end
