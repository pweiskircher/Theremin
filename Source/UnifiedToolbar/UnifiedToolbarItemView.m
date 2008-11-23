/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) The Chatkit Project, 2004-2005.  All rights reserved.
 */

#import "UnifiedToolbarItemView.h"
#import "GenericSegmentedControl.h"
#import "UnifiedToolbarLabelCell.h"
#import "UnifiedToolbarButtonCell.h"
#import "UnifiedToolbarItem.h"
#import "UnifiedToolbar.h"

//Toolbar item padding
#define BUTTON_PADDING			10
#define LABEL_PADDING			2
#define LABEL_ONLY_PADDING		14

//Segmented control placement
#define BUTTON_HEIGHT 					23
#define BUTTON_ONLY_OFFSET				0
#define BUTTON_ABOVE_LABEL_OFFSET		14
#define LABEL_HEIGHT					13
#define LABEL_OFFSET					-1

/*!
 * @class UnifiedToolbarItemView
 * @abstract View class for UnifiedToolbarItem
 *
 * This view is a simple wrapper around two segmented controls for use with UnifiedToolbarItem.
 */
@implementation UnifiedToolbarItemView

/*!
 * @abstract Init
 */
- (id)initWithSegmentCount:(int)numSegments forToolbarItem:(UnifiedToolbarItem *)aToolbarItem
{
	if ((self = [super initWithFrame:NSZeroRect])) {
		toolbarItem = aToolbarItem;
		
		//Create our segmented controls
		segmentedLabel = [[GenericSegmentedControl alloc] initWithFrame:NSZeroRect];
		[segmentedLabel setCell:[[[UnifiedToolbarLabelCell alloc] init] autorelease]];
		[segmentedLabel setSegmentCount:numSegments];
		[segmentedLabel setTrackingMode:NSSegmentSwitchTrackingMomentary];
		[segmentedLabel setTarget:self];
		[segmentedLabel setAction:@selector(performAction:)];
		[self addSubview:segmentedLabel];

		segmentedButton = [[GenericSegmentedControl alloc] initWithFrame:NSZeroRect];
		[segmentedButton setCell:[[[UnifiedToolbarButtonCell alloc] init] autorelease]];
		[segmentedButton setSegmentCount:numSegments];
		[segmentedButton setTrackingMode:NSSegmentSwitchTrackingMomentary];
		[segmentedButton setTarget:self];
		[segmentedButton setAction:@selector(performAction:)];
		[self addSubview:segmentedButton];
		
		//Set all our segments to flexible width
		int i;
		for(i = 0; i < numSegments; i++){
			[segmentedLabel setWidth:0 forSegment:i];
			[segmentedButton setWidth:0 forSegment:i];
		}
	}
	
	return self;
}

/*!
 * @abstract Dealloc
 */
- (void)dealloc
{
	[segmentedLabel release]; segmentedLabel = nil;
	[segmentedButton release]; segmentedButton = nil;

	[super dealloc];
}

/*!
 * @abstract Set the toolbar item associated with this view
 */
- (void)setToolbarItem:(id)item
{
	toolbarItem = item;
}

/*!
 * @abstract Set whether this item is in the customization palette
 *
 * Toolbar items in the palette shouldn't rollover or de-activate
 */
- (void)setInPalette:(BOOL)flag
{
	[segmentedButton setActiveForMainWindowOnly:!flag];
	[[segmentedButton cell] setShowRollover:!flag];
}

/*!
 * @abstract Perform action for one of our segmented controls
 */
- (void)performAction:(id)sender
{
	[toolbarItem performActionForSegment:[sender selectedSegment]];
}

/*!
 * @abstract Configure view dimensions for displayMode
 *
 * @return Desired size of this toolbar item
 */
- (NSSize)configureForDisplayMode:(NSToolbarDisplayMode)displayMode
{
	float 	largestLabel = 0, largestImage = 0;
	int 	i;

	//Update visibility of buttons and labels
	[segmentedLabel setHidden:(displayMode == NSToolbarDisplayModeIconOnly)];
	[segmentedButton setHidden:(displayMode == NSToolbarDisplayModeLabelOnly)];
	
	//Determine widest label
	if(![segmentedLabel isHidden]){
		for (i = 0; i < [segmentedLabel segmentCount]; i++) {
			float width = [[segmentedLabel cell] autosizeWidthForSegment:i];
			if (width > largestLabel) largestLabel = width;
		}
	}
	
	//Determine widest button
	if(![segmentedButton isHidden]){
		for (i = 0; i < [segmentedButton segmentCount]; i++) {
			float width = [[segmentedButton cell] autosizeWidthForSegment:i];
			if (width > largestImage) largestImage = width;
		}
	}
	
	//Update the widths of our segments
	if ([segmentedButton segmentCount] > 1){
		//If we have a multiple segments, set them all to the largest width
		int largestWidth = (largestLabel > largestImage ? largestLabel : largestImage);
		
		for (i = 0; i < [segmentedLabel segmentCount]; i++) {
			[segmentedLabel setWidth:largestWidth forSegment:i];
			[segmentedButton setWidth:largestWidth forSegment:i];
		}
		
	}else{
		//If we have a single segment, ensure that it is large enough to display both the label and button
		if (largestImage > largestLabel) {
			[segmentedLabel setWidth:largestImage forSegment:0];
		}else{
			[segmentedLabel setWidth:0 forSegment:0];
		}
	}

	//Let our segmented controls adjust their frames to the new segment widths
	[segmentedLabel sizeToFit];
	[segmentedButton sizeToFit];
	
	//Determine the width of our widest segmented control (plus some padding to keep items neatly spaced)
	int width = 0;	
	switch(displayMode){
		case NSToolbarDisplayModeDefault:
		case NSToolbarDisplayModeIconAndLabel:{
			int buttonWidth = [segmentedButton frame].size.width + BUTTON_PADDING;
			int labelWidth = [segmentedLabel frame].size.width + LABEL_PADDING;
			width = (labelWidth > buttonWidth ? labelWidth : buttonWidth);
		}break;
		case NSToolbarDisplayModeIconOnly:
			width = [segmentedButton frame].size.width + BUTTON_PADDING;
		break;
		case NSToolbarDisplayModeLabelOnly:
			width = [segmentedLabel frame].size.width + LABEL_ONLY_PADDING;
		break;
	}
	
	return NSMakeSize(width, [self heightForDisplayMode:displayMode]);
}

/*!
 * @abstract Returns the desired view height for displayMode
 */
- (int)heightForDisplayMode:(NSToolbarDisplayMode)displayMode
{
	switch(displayMode){
		case NSToolbarDisplayModeDefault:
		case NSToolbarDisplayModeIconAndLabel:
			return TOOLBAR_ICON_AND_LABEL_HEIGHT;
		break;
		case NSToolbarDisplayModeIconOnly:
			return TOOLBAR_ICON_ONLY_HEIGHT;
		break;
		case NSToolbarDisplayModeLabelOnly:
			return TOOLBAR_LABEL_ONLY_HEIGHT;
		break;
		default: return 0; break;
	}
}

/*!
 * @abstract Perform custom subview resizing to keep our segmented controls in place
 */
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect frame = [self frame];
	NSRect buttonFrame = [segmentedButton frame];
	NSRect labelFrame = [segmentedLabel frame];

	//Position our segmented controls within the view, centered horizontally
	[segmentedButton setFrame:NSMakeRect((int)(frame.origin.x + (frame.size.width - buttonFrame.size.width) / 2),
										 (int)(frame.origin.y + ([segmentedLabel isHidden] ? BUTTON_ONLY_OFFSET : BUTTON_ABOVE_LABEL_OFFSET)),
										 (int)(buttonFrame.size.width),
										 (int)(BUTTON_HEIGHT))];

	[segmentedLabel setFrame:NSMakeRect((int)(frame.origin.x + (frame.size.width - labelFrame.size.width) / 2),
										(int)(frame.origin.y + LABEL_OFFSET),
										(int)(labelFrame.size.width),
										(int)(LABEL_HEIGHT))];
}
	
/*!
 * @abstract Reset cursor tracking
 */
- (void)resetCursorRects
{
	[segmentedLabel resetCursorRects];
	[segmentedButton resetCursorRects];
}

/*!
 * @abstract Fix a graphical glitch when hiding toolbars
 *
 * Whan a toolbar is hidden, its buttons are moved to an offscreen window.  Since this window is not main, our
 * segmented button re-draws itself as inactive - causing a graphical glitch where the toolbar buttons become
 * inactive during the toolbar hiding animation.
 *
 * To fix this, we'll disable window activity tracking while the toolbar is hiding, and re-enable it when the
 * hide is complete.  We detect that the toolbar is in the process of hiding using its isVisible method.
 */
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (![[toolbarItem toolbar] isVisible]){
		[segmentedLabel setActiveForMainWindowOnly:NO];
		[segmentedButton setActiveForMainWindowOnly:NO];
	}
}	
- (void)viewDidMoveToWindow
{
	[segmentedLabel setActiveForMainWindowOnly:YES];
	[segmentedButton setActiveForMainWindowOnly:YES];
}


//Segment Properties ---------------------------------------------------------------------------------------------------
#pragma mark Segment Properties
/*!
 * @abstract Set segment label 
 */
- (void)setLabel:(NSString *)label forSegment:(int)segment
{
	[segmentedLabel setLabel:label forSegment:segment];
	[self setNeedsDisplay:YES];
}

/*!
 * @abstract Set segment tooltip 
 */
- (void)setToolTip:(NSString *)toolTip forSegment:(int)segment
{
	[segmentedLabel setToolTip:toolTip forSegment:segment];
	[segmentedButton setToolTip:toolTip forSegment:segment];
}

/*!
 * @abstract Set segment enabled 
 */
- (void)setEnabled:(BOOL)enabled forSegment:(int)segment
{
	[segmentedLabel setEnabled:enabled forSegment:segment];
	[segmentedButton setEnabled:enabled forSegment:segment];
	[self setNeedsDisplay:YES];
}

/*!
 * @abstract Set segment image 
 */
- (void)setImage:(NSImage *)image forSegment:(int)segment
{
	[segmentedButton setImage:image forSegment:segment];
	[self setNeedsDisplay:YES];
}

@end
