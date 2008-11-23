/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) Adam Iser, 2005.  All rights reserved.
 */

#import "GenericSegment.h"

/*!
 * @class GenericSegment
 * @abstract Internal data container for GenericSegmentedControl
 */
@implementation GenericSegment

/*!
 * @abstract Init
 */
- (id)init
{
	if ((self = [super init])) {
		label = nil;
		toolTip = nil;
		image = nil;
		
		trackingTag = 0;
		isEnabled = YES;
		isSelected = NO;
		
		tag = 0;
		width = 0;
		frame = NSZeroRect;
	}
	
	return self;
}

/*!
 * @abstract Dealloc
 */
- (void)dealloc
{
	[label release]; label = nil;
	[toolTip release]; toolTip = nil;
	[image release]; image = nil;
	[menu release]; menu = nil;

	[super dealloc];
}

/*!
 * @abstract Set/Get width
 */
- (void)setWidth:(float)newWidth {
	width = newWidth;
}
- (float)width {
	return width;
}

/*!
 * @abstract Set/Get Label
 */
- (void)setLabel:(NSString *)newLabel
{
	if (label != newLabel) {
		[label release];
		label = [newLabel retain];
	}
}
- (NSString *)label {
	return label;
}

/*!
 * @abstract Set/Get Tooltip
 */
- (void)setToolTip:(NSString *)newToolTip
{
	if (toolTip != newToolTip) {
		[toolTip release];
		toolTip = [newToolTip retain];
	}
}
- (NSString *)toolTip {
	return toolTip;
}

/*!
 * @abstract Set/Get Tag
 */
- (void)setTag:(int)newTag {
	tag = newTag;
}
- (int)tag {
	return tag;
}

/*!
 * @abstract Set/Get Enabled
 */
- (void)setEnabled:(BOOL)flag {
	isEnabled = flag;
}
- (BOOL)isEnabled {
	return isEnabled;
}

/*!
 * @abstract Set/Get Selected
 */
- (void)setSelected:(BOOL)flag {
	isSelected = flag;
}
- (BOOL)isSelected {
	return isSelected;
}

/*!
 * @abstract Set/Get Image
 */
- (void)setImage:(NSImage *)newImage
{
	if (image != newImage) {
		[image release];
		image = [newImage retain];
	}
}
- (NSImage *)image {
	return image;
}

/*!
 * @abstract Set/Get Frame
 */
- (void)setFrame:(NSRect)newFrame {
	frame = newFrame;
}
- (NSRect)frame {
	return frame;
}


/*!
 * @abstract Set/Get Tracking Tag
 */
- (void)setTrackingTag:(NSTrackingRectTag)newTag {
	trackingTag = newTag;
}
- (NSTrackingRectTag)trackingTag {
	return trackingTag;
}

- (void)setMenu:(NSMenu *)inMenu {
	if (menu != inMenu) {
		[menu release];
		menu = [inMenu retain];
	}
}
- (NSMenu *)menu {
	return menu;
}

@end
