/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) Adam Iser, 2005.  All rights reserved.
 */

#import <Cocoa/Cocoa.h>


@interface GenericSegment : NSObject {
	NSTrackingRectTag trackingTag;

	NSString	*label;
	NSString	*toolTip;
	NSImage		*image;
	NSMenu		*menu;
	
	BOOL		isEnabled;
	BOOL		isSelected;
	int			tag;
	float		width;
	NSRect		frame;
}

- (void)setWidth:(float)newWidth;
- (float)width;
- (void)setLabel:(NSString *)newLabel;
- (NSString *)label;
- (void)setToolTip:(NSString *)newToolTip;
- (NSString *)toolTip;
- (void)setTag:(int)newTag;
- (int)tag;
- (void)setEnabled:(BOOL)flag;
- (BOOL)isEnabled;
- (void)setSelected:(BOOL)flag;
- (BOOL)isSelected;
- (void)setImage:(NSImage *)newImage;
- (NSImage *)image;
- (void)setFrame:(NSRect)newFrame;
- (NSRect)frame;
- (void)setTrackingTag:(NSTrackingRectTag)newTag;
- (NSTrackingRectTag)trackingTag;
- (void)setMenu:(NSMenu *)inMenu;
- (NSMenu *)menu;
@end
