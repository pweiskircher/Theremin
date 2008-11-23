//
//  PWMusicSearchField.m
//  Theremin
//
//  Created by Patrik Weiskircher on 12.01.07.
//  Copyright 2007 Patrik Weiskircher. All rights reserved.
//

#import "PWMusicSearchField.h"
#import "Song.h"

@implementation PWMusicSearchField
- (id) initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self != nil) {
		[[self cell] setSendsWholeSearchString:YES];
		
		NSMenu *searchMenu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Search Menu", @"Search Field Menu Title")] autorelease];
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"All", @"Search Field Menu Item") action:@selector(limitSearch:) keyEquivalent:@""] autorelease];
		[item setTag:eMusicFlagsAll];
		[item setState:NSOnState];
		[item setTarget:self];
		[searchMenu insertItem:item atIndex:0];
		
		item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Artist", @"Search Field Menu Item") action:@selector(limitSearch:) keyEquivalent:@""] autorelease];
		[item setTag:eMusicFlagsArtist];
		[item setTarget:self];
		[searchMenu insertItem:item atIndex:1];
		
		item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Album", @"Search Field Menu Item") action:@selector(limitSearch:) keyEquivalent:@""] autorelease];
		[item setTag:eMusicFlagsAlbum];
		[item setTarget:self];
		[searchMenu insertItem:item atIndex:2];
		
		item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Title", @"Search Field Menu Item") action:@selector(limitSearch:) keyEquivalent:@""] autorelease];
		[item setTag:eMusicFlagsTitle];
		[item setTarget:self];
		[searchMenu insertItem:item atIndex:3];
		
		[[self cell] setSearchMenuTemplate:searchMenu];
		
		mSearchState = eMusicFlagsAll;
	}
	return self;
}

- (void) limitSearch:(id)sender {
	int tag = [sender tag];
	NSMenu *menu = [sender menu];
	for (int i = eMusicFlagsAll; i < eMusicFlagsLast; i++) {
		NSMenuItem *item = [menu itemWithTag:i];
		if (i == tag) {
			[item setState:NSOnState];
		} else {
			[item setState:NSOffState];
		}
	}
	
	mSearchState = tag;
	if ([self target] != nil && [self action] != nil)
		[[self target] performSelector:[self action] withObject:self];
	
	if (mSearchFlagsAutosaveName != nil) {
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:mSearchState] forKey:mSearchFlagsAutosaveName];
	}
}

- (MusicFlags) searchState {
	return mSearchState;
}

- (int) mpdSongFlagsForSearchState {
	switch ([self searchState]) {
		case eMusicFlagsAll:
			return eArtist | eAlbum | eTitle;
			break;
			
		case eMusicFlagsArtist:
			return eArtist;
			break;
			
		case eMusicFlagsAlbum:
			return eAlbum;
			break;
			
		case eMusicFlagsTitle:
			return eTitle;
			break;
	}
	return 0;
}

- (void) setSearchFlagsAutosaveName:(NSString *)autosaveName {
	[mSearchFlagsAutosaveName release], mSearchFlagsAutosaveName = nil;
	
	if (autosaveName != nil) {
		mSearchFlagsAutosaveName = [autosaveName retain];
		
		// FIXME: this is ugly.
		mSearchState = [[[NSUserDefaults standardUserDefaults] objectForKey:mSearchFlagsAutosaveName] intValue];
		[self limitSearch:[[[self cell] searchMenuTemplate] itemWithTag:mSearchState]];
		[[self cell] setSearchMenuTemplate:[[self cell] searchMenuTemplate]];
	}
}

@end
