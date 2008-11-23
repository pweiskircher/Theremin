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

#import "UpdateDatabaseController.h"
#import "MusicServerClient.h"
#import "Directory.h"
#import "WindowController.h"

@implementation UpdateDatabaseController
- (id) init {
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:@"UpdateDatabase" owner:self];
		
		mDirectories = [[NSMutableArray array] retain];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientConnectionStatusChanged:)
													 name:nMusicServerClientConnected
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clientConnectionStatusChanged:)
													 name:nMusicServerClientDisconnected
												   object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mDirectories release];
	
	[super dealloc];
}

- (void) show {
	[mWindow makeKeyAndOrderFront:self];
}

- (void) clientConnectionStatusChanged:(NSNotification *)notification {
	if (!([[[WindowController instance] currentLibraryDataSource] supportsDataSourceCapabilities] & eLibraryDataSourceSupportsImportingSongs))
		return;
	
	BOOL enableControls = NO;
	
	if ([[notification name] isEqualTo:nMusicServerClientConnected]) {
		enableControls = YES;
		
		Directory *rootDir = [[[WindowController instance] musicClient] rootDirectory];
		[mTreeController setContent:rootDir];
		[mTreeController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
		
		[mBrowser bind:@"content" toObject:mTreeController withKeyPath:@"arrangedObjects" options:nil];
		[mBrowser bind:@"contentValues" toObject:mTreeController withKeyPath:@"arrangedObjects.lastPathComponent" options:nil];
		[mBrowser bind:@"selectionIndexPaths" toObject:mTreeController withKeyPath:@"selectionIndexPaths" options:nil];
	} else if ([[notification name] isEqualTo:nMusicServerClientDisconnected]) {
		enableControls = NO;
		
		[mBrowser unbind:@"content"];
		[mBrowser unbind:@"contentValues"];
		[mBrowser unbind:@"selectionIndexPaths"];
		[mTreeController setContent:[[[Directory alloc] init] autorelease]];
	} else {
		return;
	}	
	
	[mBrowser setEnabled:enableControls];
	[mUpdateButton setEnabled:enableControls];
}

- (IBAction) buttonClicked:(id)sender {
	NSArray *selectedObjects = [mTreeController selectedObjects];
	if ([selectedObjects count] != 1) {
		NSBeep();
		return;
	}
	
	[[[WindowController instance] musicClient] updateDirectory:[selectedObjects objectAtIndex:0]];
	[mWindow orderOut:self];
}

- (void) updateCompleteDatabase {
	[[[WindowController instance] musicClient] updateDirectory:[[[WindowController instance] musicClient] rootDirectory]];
}

@end
