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

@class Song, AWSEntry, AWSRequest;

// see PreferencesController.h
typedef enum {
	eAWSDe = 0,
	eAWSUs = 4,
	eAWSFr = 1,
	eAWSJp = 2,
	eAWSUk = 3
} AWSLocale;

extern NSString *nFetchedSmallImageForSong;
extern NSString *nFetchedMediumImageForSong;
extern NSString *nFetchedLargeImageForSong;
extern NSString *nFetchedDetailURLForSong;

extern NSString *nFetchedEntryForSong;
extern NSString *nFailedToFetchEntryForSong;

extern NSString *nAWSSongEntry;
extern NSString *nAWSErrorEntry;
extern NSString *nAWSURLEntry;
extern NSString *nAWSImageEntry;

@interface AWSController : NSObject {
	AWSLocale mLocale;
	NSMutableSet *mRequests;
	NSMutableDictionary *mServiceRequests;
	NSMutableDictionary *mAssociateIds;
	NSMutableDictionary *mEntries;
	NSString *mAccessKey;
	BOOL mEnabled;
	
	NSTimer *mInvalidateEntriesTimer;
}
+ (id) defaultController;

- (id) init;
- (void) dealloc;

- (void) registerAssociateId:(NSString *)theId withLocale:(AWSLocale)theLocale;
- (NSString *) associateIdForLocale:(AWSLocale)theLocale;

- (void) registerAccessKeyId:(NSString *)theAccessKey;
- (NSString *) accessKeyId;

- (void) setEnabled:(BOOL)aValue;
- (BOOL) enabled;
- (void) setAutosetEnabled:(BOOL)aBool;

- (void) setLocale:(AWSLocale)theLocale;
- (AWSLocale) locale;
- (void) setAutosetLocale:(BOOL)aBool;

- (BOOL) fetchSmallImageForSong:(Song *)aSong;
- (BOOL) fetchMediumImageForSong:(Song *)aSong;
- (BOOL) fetchLargeImageForSong:(Song *)aSong;
- (BOOL) fetchDetailURLForSong:(Song *)aSong;

- (NSURL *) baseURLForLocale:(AWSLocale)theLocale;
- (NSString *) associateIdForCurrentLocale;
- (NSURL *) baseURLForCurrentLocale;
@end

@interface AWSController (PrivateMethods)
- (AWSLocale) currentAppLocale;
- (AWSEntry *) entryForSong:(Song *)theSong;
- (BOOL) fetchEntryForSong:(Song *)theSong;
- (void) requestFinished:(AWSRequest *)theRequest;
@end
