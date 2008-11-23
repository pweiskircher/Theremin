/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) The Chatkit Project, 2004-2005.  All rights reserved.
 */

#import "UnifiedToolbar.h"
#import "UnifiedToolbarItem.h"

@interface NSToolbar (PrivateMethods)
- (void)_moveItemFromIndex:(int)fp8 toIndex:(int)fp12 notifyDelegate:(BOOL)fp16 notifyView:(BOOL)fp20 notifyFamilyAndUpdateDefaults:(BOOL)fp24;
- (void)_setCurrentItemsToItemIdentifiers:(id)fp8 notifyDelegate:(BOOL)fp12 notifyView:(BOOL)fp16 notifyFamilyAndUpdateDefaults:(BOOL)fp20;
@end

@interface UnifiedToolbar (PRIVATE)
- (void)configureItemsForDisplayMode:(NSToolbarDisplayMode)displayMode;
- (void)resetItemCursorRects;
@end

/*!
 * @class UnifiedToolbar
 * @abstract Toolbar for unified toolbar windows
 * 
 * Use this subclass (along with UnifiedToolbarItem) in-place of NSToolbar for Apple-style unified toolbar buttons.
 * This subclass is necessary to work around several limitations in NSToolbar.
 */
@implementation UnifiedToolbar

/*!
 * @abstract Init
 */
- (id)initWithIdentifier:(NSString *)identifier
{
	if ((self = [super initWithIdentifier:identifier])) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(toolbarWillAddItem:)
													 name:NSToolbarWillAddItemNotification
												   object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(toolbarDidRemoveItem:)
													 name:NSToolbarDidRemoveItemNotification
												   object:self];
	}
		
	return self;
}

/*!
 * @abstract Dealloc
 */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
		
	[super dealloc];
}

/*!
 * @abstract Force the toolbar to configure items and update tracking when adding new items 
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem *item = [[notification userInfo] objectForKey:@"item"];

	if ([item isKindOfClass:[UnifiedToolbarItem class]]) {
		[(UnifiedToolbarItem *)item setInPalette:([notification object] == NULL)];
		[(UnifiedToolbarItem *)item configureForDisplayMode:[self displayMode]];
	}

	[self performSelector:@selector(resetItemCursorRects) withObject:nil afterDelay:0.00001];
}

/*!
 * @abstract Force the toolbar to update cursor tracking after removing an item
 */
- (void)toolbarDidRemoveItem:(NSNotification *)notification
{
	[self performSelector:@selector(resetItemCursorRects) withObject:nil afterDelay:0.00001];
}

/*!
 * @abstract Force the toolbar to update cursor tracking after moving an item
 *
 * Unfortunately we must rely on a private method to know when this occurs
 */
- (void)_moveItemFromIndex:(int)fp8 toIndex:(int)fp12 notifyDelegate:(BOOL)fp16 notifyView:(BOOL)fp20 notifyFamilyAndUpdateDefaults:(BOOL)fp24
{
	[super _moveItemFromIndex:fp8 toIndex:fp12 notifyDelegate:fp16 notifyView:fp20 notifyFamilyAndUpdateDefaults:fp24];
	[self resetItemCursorRects];
}

/*!
 * @abstract Reset cursor rects of all toolbar items
 */
- (void)resetItemCursorRects
{
	NSEnumerator	*enumerator = [[self items] objectEnumerator];
	NSToolbarItem	*item;
	
	while (item = [enumerator nextObject]) {
		[[item view] resetCursorRects];
	}
}

/*!
 * @abstract Configure toolbar items for display mode changes
 *
 * Our custom toolbar items require a re-size and update in response to display mode changes.
 */
- (void)setDisplayMode:(NSToolbarDisplayMode)displayMode
{
	[self configureItemsForDisplayMode:displayMode];
	[super setDisplayMode:displayMode];
}

/*!
 * @abstract Configure items as they are added to the toolbar
 *
 * This private method is a good place to configure our new toolbar items
 */
- (void)_setCurrentItemsToItemIdentifiers:(id)fp8 notifyDelegate:(BOOL)fp12 notifyView:(BOOL)fp16 notifyFamilyAndUpdateDefaults:(BOOL)fp20;
{
	[super _setCurrentItemsToItemIdentifiers:fp8 notifyDelegate:fp12 notifyView:fp16 notifyFamilyAndUpdateDefaults:fp20];
	[self configureItemsForDisplayMode:[self displayMode]];
}

/*!
 * @abstract Configure all toolbar items for the passed display mode
 */
- (void)configureItemsForDisplayMode:(NSToolbarDisplayMode)displayMode
{
	NSEnumerator	*enumerator = [[self items] objectEnumerator];
	NSToolbarItem	*item;
	
	while (item = [enumerator nextObject]) {
		if ([item isKindOfClass:[UnifiedToolbarItem class]]) {
			[(UnifiedToolbarItem *)item configureForDisplayMode:displayMode];
		}
	}
}

/*!
 * @abstract Disallow non-regular toolbar sizes
 *
 * Returning NO from this private method removes the 'Use small icons' checkbox and menu item.
 */
- (BOOL)_allowsSizeMode:(NSControlSize)size
{
	return (size == NSRegularControlSize);
}

@end
