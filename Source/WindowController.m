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

#import "WindowController.h"
#import "InfoAreaController.h"

#import "MpdMusicServerClient.h"
#import "SqueezeLibMusicServerClient.h"

#import "PreferencesController.h"
#import "Song.h"
#import "PlayListController.h"
#import "PWWindow.h"
#import "LicenseController.h"
#import "PWVolumeSlider.h"
#import "LibraryController.h"
#import "PWTableView.h"
#import "PWMusicSearchField.h"
#import "PlayListFilesController.h"
#import "UpdateDatabaseController.h"
#import "AppGlobalHotkey.h"
#import "AppGlobalHotkeyController.h"

#import "UnifiedToolbar.h"
#import "UnifiedToolbarItem.h"

#import "SongInfoController.h"

#import "SQLController.h"

#import "MultiClickRemoteBehavior.h"
#import "RemoteControlContainer.h"
#import "RemoteControl.h"

#import "CompilationDetector.h"

#import "ProfileMenuItem.h"
#import "ProfileRepository.h"
#import "PreferencesWindowController.h"

WindowController *globalWindowController = nil;

NSString *tPlayControlItemIdentifier = @"tPlayControlItemIdentifier";
NSString *tStopItemIdentifier = @"tStopItemIdentifier";
NSString *tVolumeSlider = @"tVolumeSlider";
NSString *tSearchField = @"tSearchField";

#define TR_S_TOOLBAR_LABEL_PREV		NSLocalizedString(@"Previous", @"Main Window toolbar items label")
#define TR_S_TOOLBAR_LABEL_PLAY		NSLocalizedString(@"Play", @"Main Window toolbar items label")
#define TR_S_TOOLBAR_LABEL_NEXT		NSLocalizedString(@"Next", @"Main Window toolbar items label")
#define TR_S_TOOLBAR_LABEL_PAUSE	NSLocalizedString(@"Pause", @"Main Window toolbar items label")
#define TR_S_TOOLBAR_LABEL_STOP		NSLocalizedString(@"Stop", @"Main Window toolbar items label")

const NSString *nProfileSwitched = @"nProfileSwitched";
const NSString *dProfile = @"dProfile";

@interface WindowController (PrivateMethods)
- (PWMusicSearchField *)musicSearchField;
- (RemoteControl *)appleRemote;
- (void) setupNotificationObservers;
- (void) setupProfilesMenu;

// callback when profiles in settings changed.
- (void) profilesChanged:(NSNotification *)aNotification;

// callback when we switched profile
- (void) switchedProfile;

- (NSMenuItem *) profilesMenuItem;
- (NSMenu *) newProfilesMenu;
@end

@implementation WindowController

#pragma mark Initializations 

+ (void) initialize {
	NSString *userDefaultsPath = [[NSBundle mainBundle] pathForResource:@"at.justp.theremin.userDefaults" ofType:@"plist"];
	if ([userDefaultsPath length] > 0) {
		NSDictionary *userDefaults = [NSDictionary dictionaryWithContentsOfFile:userDefaultsPath];
		if (userDefaults != nil) {
			[[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
		}
	}
}

+ (id) instance {
	return globalWindowController;
}

- (id<LibraryDataSourceProtocol>) currentLibraryDataSource {
	return [LibraryDataSource libraryDataSourceForProfile:[[self preferences] currentProfile]];
}

- (void) setupConnectionWithMusicClient {
	NSPort *port1, *port2;
	
	port1 = [NSPort port];
	port2 = [NSPort port];
	
	[(MusicServerClient*)mClient stop];
	[mClient release];
	mClient = nil;
	
	[mConnectionToMpdClient release];
	
	mConnectionToMpdClient = [[NSConnection alloc] initWithReceivePort:port1 sendPort:port2];
	[mConnectionToMpdClient setRootObject:self];

	
	NSString *musicClientClass = NSStringFromClass([MusicServerClient musicServerClientClassForProfile:[[self preferences] currentProfile]]);

	NSDictionary *infos = [NSDictionary dictionaryWithObjectsAndKeys:port2, nMusicServerClientPort0,
																	port1, nMusicServerClientPort1,
																	musicClientClass, nMusicServerClientClass,
						   nil];
	[NSThread detachNewThreadSelector:@selector(connectWithPorts:)
							 toTarget:[MusicServerClient class]
						   withObject:infos];
	
	[self switchedProfile];
}

- (void) setupNotificationObservers {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientConnected:) name:nMusicServerClientConnected object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientDisconnected:) name:nMusicServerClientDisconnected object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientRequiredAuthentication:) name:nMusicServerClientRequiresAuthentication object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientStateChanged:) name:nMusicServerClientStateChanged object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeSliderChanged:) name:nVolumeSliderUpdated object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientShuffleChanged:) name:nMusicServerClientShuffleOptionChanged object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientRepeatChanged:) name:nMusicServerClientRepeatOptionChanged object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(elapsedTimeChanged:) name:nMusicServerClientElapsedTimeChanged object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(totalTimeChanged:) name:nMusicServerClientTotalTimeChanged object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profilesChanged:) name:(NSString *)nProfileControllerUpdatedProfiles object:nil];
}

- (void) setupToolbar {
	mToolbarItems = [[NSMutableDictionary alloc] init];
	mToolbar = [[UnifiedToolbar alloc] initWithIdentifier:@"mpdToolbar"];
	[mToolbar setDelegate:self];
	[mToolbar setDisplayMode:NSToolbarDisplayModeIconOnly];	
	[mToolbar setAllowsUserCustomization:YES];
	[mToolbar setAutosavesConfiguration:YES];
}

- (void) setKeyEquivalentForMenuItemWithSelector:(SEL)selector toKey:(int)key {
	NSMenu *controlMenu = [[[[NSApplication sharedApplication] mainMenu] itemWithTag:1] submenu];
	int index;
	NSMenuItem *item;
	unichar ch = key;
	
	index = [controlMenu indexOfItemWithTarget:self andAction:selector];
	if (index != -1) {
		item = [controlMenu itemAtIndex:index];
		[item setKeyEquivalent:[NSString stringWithCharacters:&ch length:1]];
	}
}

- (void) setupMenuShortcuts {
	[self setKeyEquivalentForMenuItemWithSelector:@selector(nextSong:) toKey:NSRightArrowFunctionKey];
	[self setKeyEquivalentForMenuItemWithSelector:@selector(previousSong:) toKey:NSLeftArrowFunctionKey];
	[self setKeyEquivalentForMenuItemWithSelector:@selector(prevAlbum:) toKey:NSLeftArrowFunctionKey];
	[self setKeyEquivalentForMenuItemWithSelector:@selector(nextAlbum:) toKey:NSRightArrowFunctionKey];
	[self setKeyEquivalentForMenuItemWithSelector:@selector(increaseVolume:) toKey:NSUpArrowFunctionKey];
	[self setKeyEquivalentForMenuItemWithSelector:@selector(decreaseVolume:) toKey:NSDownArrowFunctionKey];
	
	NSArray *commonTypesToIgnore = [NSArray arrayWithObjects:[NSButton class], [NSTextView class], [NSSlider class], nil];
	
	AppGlobalHotkey *hk = [[[AppGlobalHotkey alloc] initWithTarget:self andAction:@selector(togglePlayPause:)
												 withKeyEquivalent:@" "] autorelease];
	[hk excludeFirstResponderClasses:commonTypesToIgnore];
	[[AppGlobalHotkeyController instance] addHotkey:hk];
	
	NSArray *allowedTypes = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSKeyUp], 
							 [NSNumber numberWithUnsignedInt:NSKeyDown],
							 nil];
	
	hk = [[[AppGlobalHotkey alloc] initWithTarget:self andAction:@selector(previousSong:)
								withKey:NSLeftArrowFunctionKey] autorelease];
	[hk excludeFirstResponderClasses:commonTypesToIgnore];
	[hk setAllowedTypes:allowedTypes];
	[hk setIgnoreTypes:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:NSKeyDown]]];
	[hk excludeModifierKeys:NSCommandKeyMask|NSAlternateKeyMask];
	[[AppGlobalHotkeyController instance] addHotkey:hk];

	hk = [[[AppGlobalHotkey alloc] initWithTarget:self andAction:@selector(nextSong:)
								withKey:NSRightArrowFunctionKey] autorelease];
	[hk excludeFirstResponderClasses:commonTypesToIgnore];
	[hk setAllowedTypes:allowedTypes];
	[hk setIgnoreTypes:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:NSKeyDown]]];
	[hk excludeModifierKeys:NSCommandKeyMask|NSAlternateKeyMask];
	[[AppGlobalHotkeyController instance] addHotkey:hk];
	
	[mWindow setUseGlobalHotkeys:YES];
}

- (id) init {	
	self = [super init];
	if (self != nil) {
		globalWindowController = self;
		
		mPreferencesController = [[PreferencesController alloc] initWithSparkleUpdater:mUpdater];

		[NSApp setDelegate:self];
	
		[self setupNotificationObservers];
		[self setupToolbar];
		
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.appleRemoteMode" options:NSKeyValueObservingOptionNew context:NULL];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(appActiveChanged:)
													 name:NSApplicationDidResignActiveNotification
												   object:NSApp];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(appActiveChanged:)
													 name:NSApplicationDidBecomeActiveNotification
												   object:NSApp];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(systemWillSleep:)
													 name:NSWorkspaceWillSleepNotification
												   object:[NSWorkspace sharedWorkspace]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(systemDidWake:)
													 name:NSWorkspaceDidWakeNotification
												   object:[NSWorkspace sharedWorkspace]];
		mDisableAutoreconnectOnce = NO;
		mPausedOnSleep = NO;
	}
	
	return self;
}

- (void) awakeFromNib {
	[[self preferences] importOldSettings];
	[self setupProfilesMenu];
	
	[mWindow setToolbar:mToolbar];
	[mPlaylistController setupSearchField:[self musicSearchField]];
	[self setupMenuShortcuts];
	
	mPlayListFilesController = [[PlayListFilesController alloc] init];
	mLibraryController = [[LibraryController alloc] init];
	mUpdateDatabaseController = [[UpdateDatabaseController alloc] init];
	
	[self setupConnectionWithMusicClient];
	
	if ([[self preferences] appleRemoteMode] == eAppleRemoteModeAlways)
		[[self appleRemote] startListening:self];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	[mClient release];
	[mToolbarItems release];
	[mToolbar release];
	[mConnectionToMpdClient release];
	[mLibraryController release];
	[mMusicSearch release];
	[mUpdateDatabaseController release];
	[mPlayListFilesController release], mPlayListFilesController = nil;
	[mPreferencesController release];
	
	[[self appleRemote] stopListening:self];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Profiles

- (void) setupProfilesMenu {
	NSMenuItem *profilesMenu = [self profilesMenuItem];

	[_profileChooser setMenu:[self newProfilesMenu]];
	[profilesMenu setSubmenu:[self newProfilesMenu]];
}

- (NSMenu *) newProfilesMenu {
	NSMenu *subMenu = [[[NSMenu alloc] initWithTitle:@"Profiles"] autorelease];
	
	NSArray *profiles = [ProfileRepository profiles];
	for (int i = 0; i < [profiles count]; i++) {
		Profile *profile = [profiles objectAtIndex:i];
		ProfileMenuItem *item = [[[ProfileMenuItem alloc] initWithTitle:[profile description]
																 action:@selector(selectProfile:)
														  keyEquivalent:@""] autorelease];
		[item setProfile:profile];
		[subMenu addItem:item];
	}

	return subMenu;
}

- (NSMenuItem *) profilesMenuItem {
	return [_fileMenu itemWithTag:9999];
}

- (void) profilesChanged:(NSNotification *)aNotification {
	int profilesCount = [[ProfileRepository profiles] count];
	[_profileChooser setHidden:profilesCount == 1];
	[self setupProfilesMenu];
	[self switchedProfile];
}

- (IBAction) selectProfile:(id)sender {
	[[self preferences] setCurrentProfile:[(ProfileMenuItem *)sender profile]];
	[self setupConnectionWithMusicClient];
}

- (void) switchedProfile {
	NSMenu *profilesMenu = [[self profilesMenuItem] submenu];
	Profile *currentProfile = [[self preferences] currentProfile];

	for (int i = 0; i < [[profilesMenu itemArray] count]; i++) {
		ProfileMenuItem *item = [profilesMenu itemAtIndex:i];
		if ([[item profile] isEqualToProfile:currentProfile])
			[item setState:NSOnState];
		else
			[item setState:NSOffState];
	}
	
	for (int i = 0; i < [[[_profileChooser menu] itemArray] count]; i++) {
		ProfileMenuItem *item = [[_profileChooser menu] itemAtIndex:i];
		if ([[item profile] isEqualToProfile:currentProfile]) {
			[_profileChooser selectItem:item];
			break;
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)nProfileSwitched 
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:currentProfile forKey:dProfile]];
}

#pragma mark -

- (void)setMusicClient:(id)inClient {
	[inClient setProtocolForProxy:@protocol(MusicServerClientInterface)];
	mClient = [inClient retain];

	[mInfoAreaController scheduleUpdate];
	[mClient initialize];
	
	[mClient connectToServerWithProfile:[[self preferences] currentProfile]];
}

- (id)musicClient {
	return mClient;
}

- (int) currentPlayerState {
	return mCurrentState;
}

- (PreferencesController *) preferences {
	return mPreferencesController;
}

- (PlayListController *) playlistController {
	return mPlaylistController;
}

- (NSWindow *)window {
	return mWindow;
}

- (void) appActiveChanged:(NSNotification *)aNotification {
	if ([[aNotification name] isEqualTo:NSApplicationDidResignActiveNotification]) {
		[mClient playerWindowUnfocused];
	} else if ([[aNotification name] isEqualTo:NSApplicationDidBecomeActiveNotification]) {
		[mClient playerWindowFocused];
	}
}

- (void) systemWillSleep:(NSNotification *) notification {
	if ([[self preferences] pauseOnSleep] && [self currentPlayerState] == eStatePlaying) {
		[mClient pausePlayback];
		mPausedOnSleep = YES;
	}
}

- (void) systemDidWake:(NSNotification *) notification {
	if ([[self preferences] pauseOnSleep] && mPausedOnSleep)
		[mClient play];
	mPausedOnSleep = NO;
}

- (NSString *)applicationSupportFolder {	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Theremin"];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[mWindow makeKeyAndOrderFront:self];
	
	return NO;
}

#pragma mark Configuration Stuff
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"values.appleRemoteMode"]) {
		switch ([[self preferences] appleRemoteMode]) {
			case eAppleRemoteModeAlways:
				[[self appleRemote] startListening:self];
				break;
				
			case eAppleRemoteModeNever:
				[[self appleRemote] stopListening:self];
				break;
				
			case eAppleRemoteModeWhenFocused:
				if ([NSApp isActive])
					[[self appleRemote] startListening:self];
				break;
		}
	}
}

- (void) autoreconnectTimerTriggered:(NSTimer *)timer {
	mAutoreconnectTimer = nil;
	[mClient connectToServerWithProfile:[[self preferences] currentProfile]];
}

- (void) volumeSliderChanged:(NSNotification *)notification {
	int volume = [[[notification userInfo] objectForKey:dVolume] intValue];
	[mClient setPlaybackVolume:volume];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	BOOL connected = [[self musicClient] isConnected];
	
	if ([item action] == @selector(connect:)) return !connected;
	else if ([item action] == @selector(disconnect:) ||
		     [item action] == @selector(saveCurrentPlaylist:) ||
			 [item action] == @selector(scrollToCurrentSong:) ||
			 [item action] == @selector(deleteSelectedSongs:) ||
			 [item action] == @selector(togglePlayPause:) ||
			 [item action] == @selector(stop:) ||
			 [item action] == @selector(nextSong:) ||
			 [item action] == @selector(previousSong:) ||
			 [item action] == @selector(nextAlbum:) ||
			 [item action] == @selector(prevAlbum:) ||
			 [item action] == @selector(toggleShuffle:) ||
			 [item action] == @selector(toggleRepeat:) ||
			 [item action] == @selector(increaseVolume:) ||
			 [item action] == @selector(decreaseVolume:) ||
			 [item action] == @selector(find:))
		return connected;

	if ([item action] == @selector(getInfoOnKeyWindow:)) {
		if ([NSApp keyWindow] == mWindow && [mWindow firstResponder] == mPlaylist)
			return connected;
		else if ([NSApp keyWindow] == [mLibraryController window] && [mLibraryController isGetInfoAllowed])
			return connected;
		return NO;
	}
	
	if ([item action] == @selector(updateCompleteDatabase:) ||
		[item action] == @selector(showUpdateDatabase:))
		return connected && [[self currentLibraryDataSource] supportsDataSourceCapabilities] & eLibraryDataSourceSupportsImportingSongs;
	else if ([item action] == @selector(detectCompilations:))
		return connected && [[self currentLibraryDataSource] supportsDataSourceCapabilities] & eLibraryDataSourceSupportsCustomCompilations;
	else if ([item action] == @selector(randomizePlaylist:))
		return connected && [[MusicServerClient musicServerClientClassForProfile:[[self preferences] currentProfile]] capabilities] == eMusicClientCapabilitiesRandomizePlaylist;
	
	return [item isEnabled];
}

#pragma mark MusicClient notification handlers

- (void) clientConnected:(NSNotification *)notification {
	[mPlayerItem setEnabled:YES forSegment:0];
	[mPlayerItem setEnabled:YES forSegment:1];
	[mPlayerItem setEnabled:YES forSegment:2];
	
	[mStopItem setEnabled:YES];
	[mVolumeSlider setEnabled:YES];
	[[self musicSearchField] setEnabled:YES];	
}

- (void) clientDisconnected:(NSNotification *)notification {
	[mPlayerItem setEnabled:NO forSegment:0];
	[mPlayerItem setEnabled:NO forSegment:1];
	[mPlayerItem setEnabled:NO forSegment:2];
	[mStopItem setEnabled:NO];
	[mVolumeSlider setEnabled:NO];
	[[self musicSearchField] setEnabled:NO];

	if ([[[self preferences] currentProfile] autoreconnect] == YES) {
		if (mDisableAutoreconnectOnce == YES) {
			mDisableAutoreconnectOnce = NO;
		} else {
			[mAutoreconnectTimer invalidate];
		
			mAutoreconnectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(autoreconnectTimerTriggered:) userInfo:nil repeats:NO];
		}
	}
}

- (void) clientRequiredAuthentication:(NSNotification *)notification {
	NSString *server = [[notification userInfo] objectForKey:@"server"];
	int port = [[[notification userInfo] objectForKey:@"port"] intValue];
	[mAuthenticationDescription setStringValue:[NSString stringWithFormat:@"%@:%d", server, port]];
	[mAuthenticationSavePassword setState:NSOffState];
	[NSApp runModalForWindow:mAuthenticationPanel];

}

- (void) clientStateChanged:(NSNotification *)notification {
	int state = [[[notification userInfo] objectForKey:dState] intValue];

	mCurrentState = state;
	
	[mPlayerItem setEnabled:YES forSegment:0];
	[mPlayerItem setEnabled:YES forSegment:1];
	[mPlayerItem setEnabled:YES forSegment:2];
	
	switch (mCurrentState) {
		case eStatePaused:
			[mPlayerItem setImage:[NSImage imageNamed:@"playSong"] forSegment:1];
			[mPlayerItem setLabel:TR_S_TOOLBAR_LABEL_PLAY forSegment:1];
			[mStopItem setEnabled:YES];
			break;
			
		case eStatePlaying:
			[mPlayerItem setImage:[NSImage imageNamed:@"pauseSong"] forSegment:1];
			[mPlayerItem setLabel:TR_S_TOOLBAR_LABEL_PAUSE forSegment:1];
			[mStopItem setEnabled:YES];
			break;
			
		case eStateStopped:
			[mPlayerItem setImage:[NSImage imageNamed:@"playSong"] forSegment:1];
			[mPlayerItem setLabel:TR_S_TOOLBAR_LABEL_PLAY forSegment:1];
			[mStopItem setEnabled:NO];
			break;
	}
	
	[mInfoAreaController scheduleUpdate];
	[mPlaylistController updateCurrentSongMarker];
}

- (void) elapsedTimeChanged:(NSNotification *)aNotification {
	if ([[[NSRunLoop currentRunLoop] currentMode] isEqualTo:NSEventTrackingRunLoopMode] == YES) {
		return;
	}

	int elapsed = [[[aNotification userInfo] objectForKey:dElapsedTime] intValue];
	[mInfoAreaController updateSeekBarWithElapsedTime:elapsed];
}

- (void) totalTimeChanged:(NSNotification *)aNotification {
	int total = [[[aNotification userInfo] objectForKey:dTotalTime] intValue];
	[mInfoAreaController updateSeekBarWithTotalTime:total];
}

- (void) clientShuffleChanged:(NSNotification *)notification {
	BOOL shuffleEnabled = [[[notification userInfo] objectForKey:@"shuffleState"] boolValue];
	if (shuffleEnabled) {
		[mShuffleItem setState:NSOnState];
	} else {
		[mShuffleItem setState:NSOffState];
	}
}

- (void) clientRepeatChanged:(NSNotification *)notification {
	BOOL repeatEnabled = [[[notification userInfo] objectForKey:@"repeatState"] boolValue];
	if (repeatEnabled) {
		[mRepeatItem setState:NSOnState];
	} else {
		[mRepeatItem setState:NSOffState];
	}
}

#pragma mark Actions.

- (IBAction) preferencesClicked:(id)sender {
	[[[PreferencesWindowController alloc] initWithPreferencesController:[self preferences]] showPreferences];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	if ([mToolbarItems objectForKey:itemIdentifier] != nil)
		return [mToolbarItems objectForKey:itemIdentifier];
	
	NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	
	if ([itemIdentifier isEqualToString:tPlayControlItemIdentifier]) {
		UnifiedToolbarItem *uitem = [[[UnifiedToolbarItem alloc] initWithItemIdentifier:itemIdentifier segmentCount:3] autorelease];
		
		[uitem setImage:[NSImage imageNamed:@"prevSong"] forSegment:0];
		[uitem setImage:[NSImage imageNamed:@"playSong"] forSegment:1];
		[uitem setImage:[NSImage imageNamed:@"nextSong"] forSegment:2];
		
		[uitem setLabel:TR_S_TOOLBAR_LABEL_PREV forSegment:0];
		[uitem setLabel:TR_S_TOOLBAR_LABEL_PLAY forSegment:1];
		[uitem setLabel:TR_S_TOOLBAR_LABEL_NEXT forSegment:2];
		
		[uitem setTarget:self forSegment:0];
		[uitem setAction:@selector(previousSong:) forSegment:0];
		
		[uitem setTarget:self forSegment:1];
		[uitem setAction:@selector(togglePlayPause:) forSegment:1];
		
		[uitem setTarget:self forSegment:2];
		[uitem setAction:@selector(nextSong:) forSegment:2];

		[mToolbarItems setObject:uitem forKey:itemIdentifier];
		item = uitem;
		mPlayerItem = uitem;
	} else if ([itemIdentifier isEqualToString:tStopItemIdentifier]) {
		UnifiedToolbarItem *uitem = [[[UnifiedToolbarItem alloc] initWithItemIdentifier:itemIdentifier segmentCount:1] autorelease];
		
		[uitem setImage:[NSImage imageNamed:@"stopSong"]];
		[uitem setTarget:self];
		[uitem setAction:@selector(stop:)];
		[uitem setLabel:TR_S_TOOLBAR_LABEL_STOP];
		
		[mToolbarItems setObject:uitem forKey:itemIdentifier];
		item = uitem;
		mStopItem = uitem;
	} else if ([itemIdentifier isEqualToString:tVolumeSlider]) {
		mVolumeSlider = [[PWVolumeSlider alloc] initWithFrame:NSMakeRect(0,0,0,0)];
		[mVolumeSlider setFrame:NSMakeRect(0, 0, [mVolumeSlider size].width, [mVolumeSlider size].height)];
		
		[item setView:mVolumeSlider];
		[item setMinSize:NSMakeSize(NSWidth([mVolumeSlider frame]), NSHeight([mVolumeSlider frame]))];
		[item setMaxSize:NSMakeSize(NSWidth([mVolumeSlider frame]), NSHeight([mVolumeSlider frame]))];

		[mToolbarItems setObject:item forKey:itemIdentifier];
	} else if ([itemIdentifier isEqualToString:tSearchField]) {
		[item setView:[self musicSearchField]];
		[item setMinSize:NSMakeSize(NSWidth([[self musicSearchField] frame]), NSHeight([[self musicSearchField] frame]))];
		[item setMaxSize:NSMakeSize(NSWidth([[self musicSearchField] frame]), NSHeight([[self musicSearchField] frame]))];
		
		[mToolbarItems setObject:item forKey:itemIdentifier];
	}
	
	return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:tPlayControlItemIdentifier, tStopItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, tVolumeSlider, tSearchField, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:tPlayControlItemIdentifier, tStopItemIdentifier, tVolumeSlider, NSToolbarFlexibleSpaceItemIdentifier, tSearchField, nil];
}

- (PWMusicSearchField *)musicSearchField {
	if (!mMusicSearch) {
		NSRect frame = NSMakeRect(0,0,150,30);
		mMusicSearch = [[PWMusicSearchField alloc] initWithFrame:frame];
	}
	return mMusicSearch;
}

- (void) getInfoOnSongs:(NSArray *)theSongs {
	SongInfoController *songInfoController = [[SongInfoController alloc] init];
	[songInfoController showSongs:theSongs];
}

#pragma mark Authentication stuff
- (IBAction) authenticationButtonPressed:(id)sender {
	switch ([sender tag]) {
		case 0: // cancel
			[mClient setAuthenticationInformation:[NSDictionary dictionary]];
			break;
			
		case 1: // authenticate
			if ([mAuthenticationSavePassword state] == NSOnState) {
				[[[self preferences] currentProfile] setPassword:[mAuthenticationPassword stringValue]];
				[[[self preferences] currentProfile] savePassword];
			}
			[mClient setAuthenticationInformation:[NSDictionary dictionaryWithObject:[mAuthenticationPassword stringValue] forKey:@"password"]];
			break;
	}
	
	[mAuthenticationPassword setStringValue:@""];
	[mAuthenticationPanel orderOut:self];
	[NSApp stopModal];
}

#pragma mark Apple Remote stuff
- (RemoteControl*) appleRemote 
{
	if (mAppleRemote == nil) {
		MultiClickRemoteBehavior *behavior = [[MultiClickRemoteBehavior alloc] init];
		[behavior setDelegate:self];
		[behavior setSimulateHoldEvent:YES];
		RemoteControlContainer *container = [[RemoteControlContainer alloc] initWithDelegate:behavior];

		[container instantiateAndAddRemoteControlDeviceWithClass:[AppleRemote class]];
		
		mAppleRemote = container;
	}
	return mAppleRemote;
}

- (void) applicationDidBecomeActive:(NSNotification *)aNotification
{
	if ([[self preferences] appleRemoteMode] == eAppleRemoteModeWhenFocused) {
		[[self appleRemote] startListening: self];
	}
}

- (void) applicationDidResignActive:(NSNotification *)aNotification
{
	if ([[self preferences] appleRemoteMode] == eAppleRemoteModeWhenFocused) {
		[[self appleRemote] stopListening: self];
	}
}

- (void) appleRemoteButtonHeldDownWithButton:(NSNumber *)theButton {
	if (mAppleRemoteButtonHeld) {
		switch ([theButton intValue]) {
			case kRemoteButtonMinus_Hold:
				[self decreaseVolume:self];
				break;
			case kRemoteButtonPlus_Hold:
				[self increaseVolume:self];
				break;
		}
		
		if (mAppleRemoteButtonHeld) {
			[self performSelector:@selector(appleRemoteButtonHeldDownWithButton:)
					   withObject:theButton
					   afterDelay:0.25];
		}
	}
}

- (void) remoteButton: (RemoteControlEventIdentifier)buttonIdentifier pressedDown: (BOOL) pressedDown clickCount: (unsigned int)clickCount
{
	if ([[self musicClient] isConnected] == NO)
		return;
	
	if (buttonIdentifier == kRemoteButtonPlus_Hold ||
		buttonIdentifier == kRemoteButtonMinus_Hold) {
		mAppleRemoteButtonHeld = pressedDown;
		if (pressedDown)
			[self appleRemoteButtonHeldDownWithButton:[NSNumber numberWithInt:buttonIdentifier]];
	}
	
	if (pressedDown == NO)
		return;
	
	switch (buttonIdentifier) {
		case kRemoteButtonPlus:
			[self increaseVolume:self];
			break;
		case kRemoteButtonMinus:
			[self decreaseVolume:self];
			break;
		case kRemoteButtonPlay:
			[self togglePlayPause:self];
			break;
		case kRemoteButtonLeft:
			[mClient previous];
			break;
		case kRemoteButtonRight:
			[mClient next];
			break;
	}
}

#pragma mark toolbar actions

- (IBAction) togglePlayPause:(id)sender {
	if ([[[mPlayerItem imageForSegment:1] name] isEqual:@"pauseSong"] == YES) {
		[mClient pausePlayback];
	} else {
		[mClient startPlayback];
	}
}

- (IBAction) nextSong:(id)sender {
	[mClient next];
	[mPlaylistController scheduleShowCurrentSongOnNextSongChange];
}

- (IBAction) previousSong:(id)sender {
	[mClient previous];
	[mPlaylistController scheduleShowCurrentSongOnNextSongChange];
}

- (IBAction) nextAlbum:(id)sender {
	Song *song = [mPlaylistController songOfNextAlbum];
	if (song != nil) {
		[mClient skipToSong:song];
		[mPlaylistController scheduleShowCurrentSongOnNextSongChange];
		[mPlaylistController scheduleSelectCurrentSongOnNextSongChange];
	}
}

- (IBAction) prevAlbum:(id)sender {
	Song *song = [mPlaylistController songOfPreviousAlbum];
	if (song != nil) {
		[mClient skipToSong:song];
		[mPlaylistController scheduleShowCurrentSongOnNextSongChange];
		[mPlaylistController scheduleSelectCurrentSongOnNextSongChange];
	}
}

- (IBAction) stop:(id)sender {
	[mClient stopPlayback];
}

- (IBAction) showPlayerWindow:(id)sender {
	if ([[NSApp keyWindow] isEqualTo:mWindow])
		[mClient playerWindowFocused];
	
	[mWindow makeKeyAndOrderFront:self];
}

- (IBAction) showLicense:(id)sender {
	[[[LicenseController alloc] init] show];
}

- (IBAction) showLibrary:(id)sender {
	[mLibraryController show];
}

- (IBAction) showUpdateDatabase:(id)sender {
	[mUpdateDatabaseController show];
}

- (IBAction) updateCompleteDatabase:(id)sender {
	[mUpdateDatabaseController updateCompleteDatabase];
}

- (IBAction) deleteSelectedSongs:(id)sender {
	[mPlaylistController deleteSelectedSongs:self];
}

- (IBAction) seekSliderChanged:(id)sender {
	[mInfoAreaController updateSeekBarWithTotalTime:[sender maxValue]];
	[mInfoAreaController updateSeekBarWithElapsedTime:[sender intValue]];

	[mClient scheduleSeek:[sender intValue] withDelay:0.1];
}

- (IBAction) connect:(id)sender {
	[mAutoreconnectTimer invalidate], mAutoreconnectTimer = nil;
	[mClient connectToServerWithProfile:[[self preferences] currentProfile]];
}

- (IBAction) disconnect:(id)sender {
	mDisableAutoreconnectOnce = YES;
	[mClient disconnectWithReason:@""];
}

- (IBAction) toggleShuffle:(id)sender {
	[mClient toggleShuffle];
}

- (IBAction) toggleRepeat:(id)sender {
	[mClient toggleRepeat];
}

- (IBAction) find:(id)sender {
	NSWindow *window = [NSApp keyWindow];
	if (window == nil) {
		return;
	}
	
	id search = [[[window delegate] toolbar:[window toolbar] itemForItemIdentifier:tSearchField willBeInsertedIntoToolbar:NO] view];
	if (search != nil && [search acceptsFirstResponder])
		[window makeFirstResponder:search];
}

- (IBAction) scrollToCurrentSong:(id)sender {
	[mPlaylistController showCurrentSong];
}

- (IBAction) toggleDrawer:(id)sender {
	[mPlayListFilesController toggleDrawer];
}

- (IBAction) saveCurrentPlaylist:(id)sender {
	[mPlayListFilesController saveCurrentPlaylist];
}

- (IBAction) randomizePlaylist:(id)sender {
	[mPlaylistController randomizePlaylist:self];
}

- (IBAction) increaseVolume:(id)sender {
	[mClient setPlaybackVolume:([mVolumeSlider intValue]+5)];
}

- (IBAction) decreaseVolume:(id)sender {
	[mClient setPlaybackVolume:([mVolumeSlider intValue]-5)];
}

- (IBAction) getInfo:(id)sender {
	NSArray *array = [[self playlistController] getSelectedSongs];
	if ([array count] == 0) {
		NSBeep();
		return;
	}
	[self getInfoOnSongs:array];
}

- (IBAction) getInfoOnKeyWindow:(id)sender {
	if ([NSApp keyWindow] == mWindow)
		return [self getInfo:sender];
	else if ([NSApp keyWindow] == [mLibraryController window])
		return [mLibraryController getInfoOnSongs:self];
}

- (IBAction) detectCompilations:(id)sender {
	[CompilationDetector detectCompilationsUsingDataSource:[self currentLibraryDataSource]];
	[mLibraryController reloadAll];
}

- (void)getSystemVersionMajor:(unsigned *)major minor:(unsigned *)minor bugFix:(unsigned *)bugFix
{
    OSErr err;
    SInt32 systemVersion, versionMajor, versionMinor, versionBugFix;
    if ((err = Gestalt(gestaltSystemVersion, &systemVersion)) != noErr) goto fail;
    if (systemVersion < 0x1040)
    {
        if (major) *major = ((systemVersion & 0xF000) >> 12) * 10 +
            ((systemVersion & 0x0F00) >> 8);
        if (minor) *minor = (systemVersion & 0x00F0) >> 4;
        if (bugFix) *bugFix = (systemVersion & 0x000F);
    }
    else
    {
        if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr) goto fail;
        if (major) *major = versionMajor;
        if (minor) *minor = versionMinor;
        if (bugFix) *bugFix = versionBugFix;
    }
    
    return;
    
fail:
    NSLog(@"Unable to obtain system version: %ld", (long)err);
    if (major) *major = 10;
    if (minor) *minor = 0;
    if (bugFix) *bugFix = 0;
}

@end
