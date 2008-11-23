/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) The Chatkit Project, 2004-2005.  All rights reserved.
 */

#import "UnifiedToolbarItem.h"
#import "UnifiedToolbarItemSegment.h"
#import "UnifiedToolbarItemView.h"

@interface NSObject (UnifiedToolbarItemAdditions)
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem segment:(int)segment;
- (NSMenuItem *)menuFormRepresentationForSegment:(int)segment;
@end

/*!
 * @class UnifiedToolbarItem
 * @abstract Toolbar item for unified toolbar windows
 * 
 * Use this subclass (along with UnifiedToolbar) in-place of NSToolbarItem for Apple-style unified toolbar buttons.
 * Items will only work correctly when inserted into a UnifiedToolbar.  Use 29x19 images for best results.
 */
@implementation UnifiedToolbarItem

/*!
 * @abstract Init
 */
- (id)initWithItemIdentifier:(NSString *)itemIdentifier
{
	return [self initWithItemIdentifier:itemIdentifier segmentCount:1];
}

/*!
 * @abstract Init
 */
- (id)initWithItemIdentifier:(NSString *)itemIdentifier segmentCount:(int)numSegments
{
	if ((self = [super initWithItemIdentifier:itemIdentifier])) {
		int i;

		//Create our segment data containers
		segments = [[NSMutableArray alloc] init];
		for (i = 0; i < numSegments; i++) {
			[segments addObject:[[[UnifiedToolbarItemSegment alloc] init] autorelease]];
		}
		
		//Init
		[self setView:[[[UnifiedToolbarItemView alloc] initWithSegmentCount:numSegments
															 forToolbarItem:self] autorelease]];
		isInPalette = YES;
	}
	
	return self;
}

/*!
 * @abstract Perform a deep copy
 */
- (id)copyWithZone:(NSZone *)zone
{
	UnifiedToolbarItem *item = [[UnifiedToolbarItem alloc] initWithItemIdentifier:[self itemIdentifier]
																	 segmentCount:[segments count]];
	
	//Mirror our segment configuration in the new copy
	NSEnumerator				*enumerator = [segments objectEnumerator];
	UnifiedToolbarItemSegment	*segment;
	int							segmentIndex = 0;
	
	while (segment = [enumerator nextObject]) {
		[item setLabel:[segment label] forSegment:segmentIndex];
		[item setPaletteLabel:[segment paletteLabel] forSegment:segmentIndex];
		[item setToolTip:[segment toolTip] forSegment:segmentIndex];
		[item setTag:[segment tag] forSegment:segmentIndex];
		[item setTarget:[segment target] forSegment:segmentIndex];
		[item setAction:[segment action] forSegment:segmentIndex];
		[item setEnabled:[segment isEnabled] forSegment:segmentIndex];
		[item setImage:[segment image] forSegment:segmentIndex];
		segmentIndex++;
	}
	
	return item;
}

/*!
 * @abstract Dealloc
 */
- (void)dealloc
{
	[segments release]; segments = nil;
	
	//Since our view hasn't retained us, we must set its toolbar item to nil
	[(UnifiedToolbarItemView *)[self view] setToolbarItem:nil];

	[super dealloc];
}

/*!
 * @abstract Let this toolbar item draw its label
 *
 * Normally, the toolbar draws the item labels.  However, returning YES from these private methods defers label drawing
 * to the toolbar item, which is necessary for grouped buttons.
 */
- (BOOL)wantsToDrawIconIntoLabelAreaInDisplayMode:(NSToolbarDisplayMode)displayMode {
	return YES;
}
- (BOOL)wantsToDrawIconInDisplayMode:(NSToolbarDisplayMode)displayMode {
	return YES;
}
- (BOOL)wantsToDrawLabelInDisplayMode:(NSToolbarDisplayMode)displayMode {
	return YES;
}
- (BOOL)wantsToDrawLabelInPalette {
	return NO;
}

/*!
 * @abstract Ensure that our view is of kind UnifiedToolbarItemView
 */
- (void)setView:(NSView *)view
{
	NSAssert([view isKindOfClass:[UnifiedToolbarItemView class]], @"View must be of kind UnifiedToolbarItemView");
	[super setView:view];
}

/*!
 * @abstract Set/Get whether this item is in the customization palette
 */
- (void)setInPalette:(BOOL)flag
{
	isInPalette = flag;
	
	//Update segment labels
	NSEnumerator				*enumerator = [segments objectEnumerator];
	UnifiedToolbarItemSegment	*segment;
	int							segmentIndex = 0;
	
	while ((segment = [enumerator nextObject])) {
		[(UnifiedToolbarItemView *)[self view] setLabel:(isInPalette ? [segment paletteLabel] : [segment label])
											 forSegment:segmentIndex];
		segmentIndex++;
	}

	//Forward to view
	[(UnifiedToolbarItemView *)[self view] setInPalette:flag];
}
- (BOOL)isInPalette {
	return isInPalette;
}

/*!
 * @abstract Configure and resize this item
 */
- (void)configureForDisplayMode:(NSToolbarDisplayMode)displayMode
{
	NSSize	desiredSize = [(UnifiedToolbarItemView *)[self view] configureForDisplayMode:displayMode];
	
	[self setMinSize:desiredSize];
	[self setMaxSize:desiredSize];		
}

/*!
 * @abstract Perform action for a segment
 */
- (void)performActionForSegment:(int)segmentIndex
{
	UnifiedToolbarItemSegment	*segment = [segments objectAtIndex:segmentIndex];
	
	[[segment target] performSelector:[segment action] withObject:self];
}

/*!
 * @abstract Validate this item
 *
 * NSToolbarItems with views do not get validated by default.
 */
- (void)validate
{
	if ([self target] && [[self target] respondsToSelector:@selector(validateToolbarItem:segment:)]) {
		int i;
		for (i = 0; i < [segments count]; i++) {
			[self setEnabled:[[self target] validateToolbarItem:self segment:i] forSegment:i];
		}
	}
}

/*!
 * @abstract Return a NSMenuItem for this item
 *
 * NSToolbarItems with views do not get a menuFormRepresentation by default.
 */
- (NSMenuItem *)menuFormRepresentation
{
	if ([segments count] == 1) {
		return [self menuFormRepresentationForSegment:0];

	}else{
		NSMenuItem	*host = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
		NSMenu 		*menu = [[NSMenu alloc] initWithTitle:@""];

		//Add a menu item for each segment
		NSEnumerator				*enumerator = [segments objectEnumerator];
		UnifiedToolbarItemSegment	*segment;
		int							segmentIndex = 0;
		
		while (segment = [enumerator nextObject]) {
			[menu addItem:[self menuFormRepresentationForSegment:segmentIndex]];
			segmentIndex++;
		}
		
		//If we return a menuItem without a title, NSToolbar will place its submenu's items directly into the main menu
		[host setSubmenu:menu];
		return host;
	}
}

/*!
 * @abstract Return the NSMenuItem representation for a segment
 */
- (NSMenuItem *)menuFormRepresentationForSegment:(int)segment
{
	NSMenuItem	*menuItem = [[NSMenuItem alloc] initWithTitle:[self labelForSegment:segment]
													   action:[self actionForSegment:segment]
												keyEquivalent:@""];
	
	[menuItem setTarget:[self targetForSegment:segment]];
	[menuItem setImage:[self imageForSegment:segment]];
	
	return [menuItem autorelease];
}


//Single segment convenience methods -----------------------------------------------------------------------------------
#pragma mark Single segment convenience methods
- (void)setLabel:(NSString *)label { [self setLabel:label forSegment:0]; }
- (NSString *)label { return [self labelForSegment:0]; }

- (void)setPaletteLabel:(NSString *)paletteLabel { [self setPaletteLabel:paletteLabel forSegment:0]; }
- (NSString *)paletteLabel { return [self paletteLabelForSegment:0]; }

- (void)setToolTip:(NSString *)toolTip { [self setToolTip:toolTip forSegment:0]; }
- (NSString *)toolTip { return [self toolTipForSegment:0]; }

- (void)setTag:(int)tag { [self setTag:tag forSegment:0]; }
- (int)tag { return [self tagForSegment:0]; }

- (void)setTarget:(id)target { [self setTarget:target forSegment:0]; }
- (id)target { return [self targetForSegment:0]; }

- (void)setAction:(SEL)action { [self setAction:action forSegment:0]; }
- (SEL)action { return [self actionForSegment:0]; }

- (void)setEnabled:(BOOL)enabled { [self setEnabled:enabled forSegment:0]; }
- (BOOL)isEnabled { return [self isEnabledForSegment:0]; }

- (void)setImage:(NSImage *)image { [self setImage:image forSegment:0]; }
- (NSImage *)image { return [self imageForSegment:0]; }


//Segment Properties ---------------------------------------------------------------------------------------------------
#pragma mark Properties
/*!
 * @abstract Set segment label
 */
- (void)setLabel:(NSString *)label forSegment:(int)segment
{
	[[segments objectAtIndex:segment] setLabel:label];
	if (![self isInPalette]) {
		[(UnifiedToolbarItemView *)[self view] setLabel:label forSegment:segment];
		[self configureForDisplayMode:[[self toolbar] displayMode]];
	}
}
- (NSString *)labelForSegment:(int)segment {
	return [[segments objectAtIndex:segment] label];
}

/*!
 * @abstract Set segment palette label
 */
- (void)setPaletteLabel:(NSString *)paletteLabel forSegment:(int)segment
{
	[[segments objectAtIndex:segment] setPaletteLabel:paletteLabel];
	if ([self isInPalette]) {
		[(UnifiedToolbarItemView *)[self view] setLabel:paletteLabel forSegment:segment];
		[self configureForDisplayMode:[[self toolbar] displayMode]];
	}
}
- (NSString *)paletteLabelForSegment:(int)segment {
	return [[segments objectAtIndex:segment] label];
}

/*!
 * @abstract Set segment tooltip
 */
- (void)setToolTip:(NSString *)toolTip forSegment:(int)segment
{
	[[segments objectAtIndex:segment] setToolTip:toolTip];
	[(UnifiedToolbarItemView *)[self view] setToolTip:toolTip forSegment:segment];
}
- (NSString *)toolTipForSegment:(int)segment {
	return [[segments objectAtIndex:segment] toolTip];
}

/*!
 * @abstract Set segment tag
 */
- (void)setTag:(int)tag forSegment:(int)segment
{
	[[segments objectAtIndex:segment] setTag:tag];
}
- (int)tagForSegment:(int)segment {
	return [[segments objectAtIndex:segment] tag];
}

/*!
 * @abstract Set segment target
 */
- (void)setTarget:(id)target forSegment:(int)segment
{
	[[segments objectAtIndex:segment] setTarget:target];
}
- (id)targetForSegment:(int)segment {
	return [[segments objectAtIndex:segment] target];
}

/*!
 * @abstract Set segment action
 */
- (void)setAction:(SEL)action forSegment:(int)segment
{
	[[segments objectAtIndex:segment] setAction:action];
}
- (SEL)actionForSegment:(int)segment {
	return [[segments objectAtIndex:segment] action];
}

/*!
 * @abstract Set segment enabled
 */
- (void)setEnabled:(BOOL)enabled forSegment:(int)segment
{
	[[segments objectAtIndex:segment] setEnabled:enabled];
	[(UnifiedToolbarItemView *)[self view] setEnabled:enabled forSegment:segment];
}
- (BOOL)isEnabledForSegment:(int)segment {
	return [[segments objectAtIndex:segment] isEnabled];
}

/*!
 * @abstract Set segment image
 */
- (void)setImage:(NSImage *)image forSegment:(int)segment
{
	[[segments objectAtIndex:segment] setImage:image];
	[(UnifiedToolbarItemView *)[self view] setImage:image forSegment:segment];
	[self configureForDisplayMode:[[self toolbar] displayMode]];
}
- (NSImage *)imageForSegment:(int)segment {
	return [[segments objectAtIndex:segment] image];
}

@end
