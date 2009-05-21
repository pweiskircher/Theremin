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

#import "LibraryImportController.h"
#import "Song.h"
#import "NSNotificationAdditions.h"
#import "SQLController.h"
#import "WindowController.h"
#import "PreferencesController.h"
#import "MusicServerClient.h"

NSString *nBeganLibraryImport = @"nBeganLibraryImport";
NSString *nFinishedLibraryImport = @"nFinishedLibraryImport";

const NSString *gDatabaseIdentifierKey = @"gDatabaseIdentifierKey";

@interface LibraryImportThread : NSObject {
}
- (void) startThread:(NSDictionary *)arguments;
@end

@implementation LibraryImportController
- (id) init {
	self = [super init];
	if (self != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientConnected:)
													 name:nMusicServerClientConnected
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(remoteDatabaseUpdated:)
													 name:nMusicServerClientDatabaseUpdated
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fetchedRemoteDatabase:)
													 name:nMusicServerClientFetchedDatabase
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(threadFinished:)
													 name:nFinishedLibraryImport
												   object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[mCurrentDatabaseIdentifier release], mCurrentDatabaseIdentifier = nil;
	[mCurrentServerAndPort release], mCurrentServerAndPort = nil;
	[mCurrentSongs release], mCurrentSongs = nil;
	
	[mQueuedDatabaseIdentifier release], mQueuedDatabaseIdentifier = nil;
	[mQueuedServerAndPort release], mQueuedServerAndPort = nil;
	[mQueuedSongs release], mQueuedSongs = nil;
	
	[mImporterThread release], mImporterThread = nil;
	
	[super dealloc];
}

- (void) clientConnected:(NSNotification *)notification {
	if ([[[WindowController instance] currentLibraryDataSource] supportsDataSourceCapabilities] & eLibraryDataSourceSupportsImportingSongs &&
		[[[WindowController instance] currentLibraryDataSource] needsImport]) {
		[[[WindowController instance] musicClient] startFetchDatabase];
	}	
}

- (void) remoteDatabaseUpdated:(NSNotification *)notification {
	if ([[[WindowController instance] currentLibraryDataSource] supportsDataSourceCapabilities] & eLibraryDataSourceSupportsImportingSongs)
		[[[WindowController instance] musicClient] startFetchDatabase];	
}

- (void) startImportThreadWithSongs:(NSArray *)theSongs {
	[mImporterThread release];
	mImporterThread = [[LibraryImportThread alloc] init];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:theSongs, dSongs,
		mCurrentDatabaseIdentifier, gDatabaseIdentifierKey, nil];
	//[mImporterThread startThread:dict];
	[NSThread detachNewThreadSelector:@selector(startThread:) toTarget:mImporterThread withObject:dict];
}

- (void) fetchedRemoteDatabase:(NSNotification *)notification {
	NSArray *allSongs = [[notification userInfo] objectForKey:dSongs];
	NSData *databaseIdentifier = [[notification userInfo] objectForKey:dDatabaseIdentifier];
	NSString *currentServerAndPort = [[PreferencesController sharedInstance] currentServerNameWithPort];
	
	if (mImporterThread) {
		[mQueuedDatabaseIdentifier release], mQueuedDatabaseIdentifier = nil;
		[mQueuedServerAndPort release], mQueuedServerAndPort = nil;
		[mQueuedSongs release], mQueuedSongs = nil;
		
		mQueuedSongs = [allSongs retain];
		mQueuedDatabaseIdentifier = [databaseIdentifier retain];
		mQueuedServerAndPort = [currentServerAndPort retain];
	} else {
		[mCurrentDatabaseIdentifier release], mCurrentDatabaseIdentifier = nil;
		[mCurrentServerAndPort release], mCurrentServerAndPort = nil;
		[mCurrentSongs release], mCurrentSongs = nil;
		
		mCurrentSongs = [allSongs retain];
		mCurrentDatabaseIdentifier = [databaseIdentifier retain];
		mCurrentServerAndPort = [currentServerAndPort retain];
		
		[self startImportThreadWithSongs:mCurrentSongs];
	}
}

- (void) threadFinished:(NSNotification *)notification {
	[mCurrentDatabaseIdentifier release], mCurrentDatabaseIdentifier = nil;
	[mCurrentServerAndPort release], mCurrentServerAndPort = nil;
	[mCurrentSongs release], mCurrentSongs = nil;
	
	if (mQueuedSongs && mQueuedServerAndPort && mQueuedDatabaseIdentifier) {
		mCurrentSongs = [mQueuedSongs retain];
		mCurrentServerAndPort = [mQueuedServerAndPort retain];
		mCurrentDatabaseIdentifier = [mQueuedDatabaseIdentifier retain];
		
		[mQueuedDatabaseIdentifier release], mQueuedDatabaseIdentifier = nil;
		[mQueuedServerAndPort release], mQueuedServerAndPort = nil;
		[mQueuedSongs release], mQueuedSongs = nil;
		
		[self startImportThreadWithSongs:mCurrentSongs];
		return;
	}
	
	[mImporterThread release], mImporterThread = nil;
}

@end

@implementation LibraryImportThread

- (NSString *) compilationBackupFilenameWithServerAndPort:(Profile *)aProfile {
	return [NSString stringWithFormat:@"%@/Compilation%@-%d.dat", [[WindowController instance] applicationSupportFolder], [aProfile hostname], [aProfile port]];
}

- (void) startThread:(NSDictionary *)arguments {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nBeganLibraryImport object:self];
	
	id<LibraryDataSourceProtocol> dataSource = [[WindowController instance] currentLibraryDataSource];
	
	BOOL supportsCompilations = [dataSource supportsDataSourceCapabilities] & eLibraryDataSourceSupportsCustomCompilations;
	
	NSString *compilationBackupFilename;
	if (supportsCompilations) {
		compilationBackupFilename = [self compilationBackupFilenameWithServerAndPort:[[PreferencesController sharedInstance] currentProfile]];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:compilationBackupFilename] == NO) {
			NSArray *array = [dataSource compilationUniqueIdentifiers];
			if (![NSArchiver archiveRootObject:array toFile:compilationBackupFilename]) {
				NSLog(@"Couldn't save compilation data. Continuing anyway.");
			}
		}		
	}
	
	[dataSource clear];
	
	NSLog(@"started importing ...");
	
	NSArray *allSongs = [arguments objectForKey:dSongs];
	[dataSource insertSongs:allSongs withDatabaseIdentifier:[arguments objectForKey:gDatabaseIdentifierKey]];

	NSLog(@"finished.");
	
	if (supportsCompilations) {
		NSArray *array = [NSUnarchiver unarchiveObjectWithFile:compilationBackupFilename];
		[dataSource setCompilationByUniqueIdentifiers:array];
		[[NSFileManager defaultManager] removeFileAtPath:compilationBackupFilename handler:NULL];		
	}

	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:nFinishedLibraryImport object:self userInfo:nil waitUntilDone:YES];
	
	[pool release];
}

@end
