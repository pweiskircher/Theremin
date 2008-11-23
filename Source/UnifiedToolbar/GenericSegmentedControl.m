/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) Adam Iser, 2005.  All rights reserved.
 */

#import "GenericSegmentedControl.h"
#import "GenericSegmentedCell.h"

@interface GenericSegmentedControl (PRIVATE)
- (void)_init;
@end

/*!
 * @class GenericSegmentedControl
 * @abstract A recreation of NSSegmentedControl with greater capability for customization.
 *
 * This control/cell combination assists with the creation of NSSegmentedControls with a customized appearance.
 *
 * Note: The default cell class GenericSegmentedCell for this control performs NO drawing or autosizing.  You will
 *       need to create a custom GenericSegmentedCell subclass and provide your custom drawing and sizing code.
 *
 * Possible improvements:
 *  - Support vertical fitting with sizeToFit and custom cell's autosize method
 *  - Support all tracking modes (Currently this control only supports NSSegmentSwitchTrackingMomentary)
 */
@implementation GenericSegmentedControl

/*!
 * @abstract Init
 */
- (id)init
{
	if ((self = [super init])) {
		[self _init];
	}
	
	return self;
}

/*!
 * @abstract Init with frame
 */
- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self _init];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)inCoder
{
	if ((self = [super initWithCoder:inCoder])) {
		[self _init];
	}
	
	return self;	
}

/*!
 * @abstract Common init
 */
- (void)_init
{
	isActiveForMainWindowOnly = NO;
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
 * @abstract Override the default cell class
 */
+ (Class)cellClass
{
    return [GenericSegmentedCell class];
}

- (void)awakeFromNib
{
	[self setCell:[[[[[self class] cellClass] alloc] init] autorelease]];
}

/*!
 * @brief Set the cell for the segmented control
 *
 * Copy the segment count, labels, and images currently set on our control to the new cell setup.
 * This lets us work with configuration done in Interface Builder.
 */
- (void)setCell:(NSCell *)inCell
{
	NSMutableArray *labelArray = [NSMutableArray array];
	NSMutableArray *imageArray = [NSMutableArray array];
	SEL action = [self action];
	id target = [[self target] retain];

	int segmentCount = [self segmentCount];
	int i;

	for (i = 0; i < segmentCount; i++) {
		NSString *label = [self labelForSegment:i];
		NSImage *image = [self imageForSegment:i];
		[labelArray addObject:(label ? (id)label : (id)[NSNull null])];
		[imageArray addObject:(image ? (id)image : (id)[NSNull null])];
	}
	
	[super setCell:inCell];
	
	//Now restore the segment count and its characteristics
	[self setSegmentCount:segmentCount];
	
	for (i = 0; i < segmentCount; i++) {
		NSString *label = [labelArray objectAtIndex:i];
		NSImage *image = [imageArray objectAtIndex:i];
		if (![label isKindOfClass:[NSNull class]]) {
			[self setLabel:label forSegment:i];
		}
		if (![image isKindOfClass:[NSNull class]]) {
			[self setImage:image forSegment:i];
		}
	}
	
	[self setAction:action];
	[self setTarget:target];
	[target release];
}


//Global Properties ----------------------------------------------------------------------------------------------------
#pragma mark Forwarded to cell
/*!
 * @abstract Set/Get segment count
 *
 * All segment properties must be reset after changing the segment count.
 */
- (void)setSegmentCount:(int)count {
	[[self cell] setSegmentCount:count];
}
- (int)segmentCount {
	return [[self cell] segmentCount];
}

/*!
 * @abstract Set/Get tracking mode
 */
- (void)setTrackingMode:(NSSegmentSwitchTracking)trackingMode {
	[[self cell] setTrackingMode:trackingMode];
}
- (NSSegmentSwitchTracking)trackingMode {
	return [[self cell] trackingMode];
}

/*!
 * @abstract Set/Get selected segment
 */
- (void)setSelectedSegment:(int)selectedSegment {
	[[self cell] setSelectedSegment:selectedSegment];
}
- (int)selectedSegment {
	return [[self cell] selectedSegment];
}
- (BOOL)selectSegmentWithTag:(int)tag {
	return [[self cell] selectSegmentWithTag:tag];
}

/*!
 * @abstract Set/Get active for main window only
 *
 * When 'activeForMainWindowOnly' is enabled, the control will take on an inactive appearance for background windows.
 */
- (void)setActiveForMainWindowOnly:(BOOL)flag {
	isActiveForMainWindowOnly = flag;
}
- (BOOL)isActiveForMainWindowOnly {
	return isActiveForMainWindowOnly;
}


//Segment properties ---------------------------------------------------------------------------------------------------
#pragma mark Segment properties
/*!
 * @abstract Set/Get segment width
 */
- (void)setWidth:(float)width forSegment:(int)segment {
	[[self cell] setWidth:width forSegment:segment];
	[self setNeedsDisplay:YES];
}
- (float)widthForSegment:(int)segment {
	return [[self cell] widthForSegment:segment];
}

/*!
 * @abstract Set/Get segment image
 */
- (void)setImage:(NSImage *)image forSegment:(int)segment {
	[[self cell] setImage:image forSegment:segment];
	[self setNeedsDisplay:YES];
}
- (NSImage *)imageForSegment:(int)segment {
	return [[self cell] imageForSegment:segment];
}

/*!
 * @abstract Set/Get segment label
 */
- (void)setLabel:(NSString *)label forSegment:(int)segment {
	[[self cell] setLabel:label forSegment:segment];
	[self setNeedsDisplay:YES];
}
- (NSString *)labelForSegment:(int)segment {
	return [[self cell] labelForSegment:segment];
}

/*!
 * @abstract Set/Get segment menu
 */
- (void)setMenu:(NSMenu *)menu forSegment:(int)segment {
	[[self cell] setMenu:menu forSegment:segment];
}
- (NSMenu *)menuForSegment:(int)segment {
	return [[self cell] menuForSegment:segment];
}

/*!
 * @abstract Set/Get segment tooltip
 */
- (void)setToolTip:(NSString *)toolTip forSegment:(int)segment {
	[[self cell] setToolTip:toolTip forSegment:segment];
}
- (NSString *)toolTipForSegment:(int)segment {
	return [[self cell] toolTipForSegment:segment];
}

/*!
 * @abstract Set/Get segment tag
 */
- (void)setTag:(int)tag forSegment:(int)segment {
	[[self cell] setTag:tag forSegment:segment];
}
- (int)tagForSegment:(int)segment {
	return [[self cell] tagForSegment:segment];
}

/*!
 * @abstract Set/Get segment selected
 */
- (void)setSelected:(BOOL)selected forSegment:(int)segment {
	[[self cell] setSelected:selected forSegment:segment];
	[self setNeedsDisplay:YES];
}
- (BOOL)isSelectedForSegment:(int)segment {
	return [[self cell] isSelectedForSegment:segment];
}

/*!
 * @abstract Set/Get segment enabled
 */
- (void)setEnabled:(BOOL)enabled forSegment:(int)segment {
	[[self cell] setEnabled:enabled forSegment:segment];
	[self setNeedsDisplay:YES];
}
- (BOOL)isEnabledForSegment:(int)segment {
	return [[self cell] isEnabledForSegment:segment];
}


//Cursor Tracking ------------------------------------------------------------------------------------------------------
#pragma mark Cursor Tracking
/*!
 * @abstract Mouse down
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	[[self cell] trackMouse:theEvent inRect:[self bounds] ofView:self untilMouseUp:YES];
}

/*!
 * @abstract Reset cursor tracking
 */
- (void)resetCursorRects
{
	[[self cell] resetCursorRect:[self bounds] inView:self];
}

/*!
 * @abstract Remove cursor tracking
 */
- (void)removeCursorRects
{
	if ([[self cell] respondsToSelector:@selector(removeCursorRects)]) {
		[[self cell] removeCursorRects];
	}
}

//Window Main Tracking -------------------------------------------------------------------------------------------------
#pragma mark Window Main Tracking
/*!
 * @abstract View has moved to a new window
 */
- (void)viewDidMoveToWindow
{
	if([self window]){
		//Monitor the window's status to allow dimming of buttons when it's in the background
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowDidBecomeMain:)
													 name:NSWindowDidBecomeMainNotification
												   object:[self window]];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowDidResignMain:)
													 name:NSWindowDidResignMainNotification
												   object:[self window]];
		
		//Set the correct initial state
		if ([[self window] isMainWindow]) {
			[self windowDidBecomeMain:nil];
		}else{
			[self windowDidResignMain:nil];
		}
	}
}

/*!
 * @abstract View is moving to a new window
 */
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if ([self window]) {		
		//Stop monitoring the window's status before it removes us
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSWindowDidBecomeMainNotification
													  object:[self window]];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSWindowDidResignMainNotification
													  object:[self window]];
		
		//Stop cursor tracking
		[self removeCursorRects];
	}
}

/*!
 * @abstract Window did become main, enable our button
 */
- (void)windowDidBecomeMain:(NSNotification *)notification
{	
	[[self cell] setActive:YES];
}

/*!
 * @abstract Window did resign main, dim our button
 */
- (void)windowDidResignMain:(NSNotification *)notification
{
	if ([self isActiveForMainWindowOnly]){
		[[self cell] setActive:NO];
	}
}


//Drawing & Sizing -----------------------------------------------------------------------------------------------------
#pragma mark Drawing & Sizing
/*!
 * @abstract Draw
 */
- (void)drawRect:(NSRect)inRect
{
	[[self cell] drawWithFrame:[self bounds] inView:self];
}

/*!
 * @abstract Redisplay a cell
 */
- (void)updateCell:(NSCell *)aCell
{
	if (aCell == [self cell]) {
		[self setNeedsDisplay:YES];
	}
}

/*!
 * @abstract Size this control to best fit its content
 */
- (void)sizeToFit
{
	[self setFrameSize:[[self cell] cellSizeForBounds:NSMakeRect(0, 0, 10000, [self frame].size.height)]];
}

@end
