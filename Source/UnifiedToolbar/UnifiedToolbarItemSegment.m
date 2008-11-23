/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) The Chatkit Project, 2004-2005.  All rights reserved.
 */

#import "UnifiedToolbarItemSegment.h"

/*!
 * @class UnifiedToolbarItemSegment
 * @abstract Internal data container for UnifiedToolbarItem
 */
@implementation UnifiedToolbarItemSegment

/*!
 * @abstract Init
 */
- (id)init
{
	if ((self = [super init])) {
		label = nil;
		paletteLabel = nil;
		toolTip = nil;
		image = nil;
		
		target = nil;
		action = nil;
		
		isEnabled = YES;
		tag = 0;
	}
	
	return self;
}

/*!
 * @abstract Dealloc
 */
- (void)dealloc
{
	[label release]; label = nil;
	[paletteLabel release]; paletteLabel = nil;
	[toolTip release]; toolTip = nil;
	[image release]; image = nil;
	
	[super dealloc];
}

/*!
 * @abstract Set label
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
 * @abstract Set palette label
 */
- (void)setPaletteLabel:(NSString *)newLabel
{
	if (paletteLabel != newLabel) {
		[paletteLabel release];
		paletteLabel = [newLabel retain];
	}
}
- (NSString *)paletteLabel {
	return paletteLabel;
}

/*!
 * @abstract Set tooltip
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
 * @abstract Set tag
 */
- (void)setTag:(int)newTag {
	tag = newTag;
}
- (int)tag {
	return tag;
}

/*!
 * @abstract Set target
 */
- (void)setTarget:(id)newTarget {
	target = newTarget;
}
- (id)target {
	return target;
}

/*!
 * @abstract Set action
 */
- (void)setAction:(SEL)newAction {
	action = newAction;
}
- (SEL)action {
	return action;
}

/*!
 * @abstract Set enabled
 */
- (void)setEnabled:(BOOL)flag {
	isEnabled = flag;
}
- (BOOL)isEnabled {
	return isEnabled;
}

/*!
 * @abstract Set image
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

@end
