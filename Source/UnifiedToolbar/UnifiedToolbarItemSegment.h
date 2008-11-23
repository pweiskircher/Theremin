/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) The Chatkit Project, 2004-2005.  All rights reserved.
 */

#import <Cocoa/Cocoa.h>


@interface UnifiedToolbarItemSegment : NSObject {
	NSString	*label;
	NSString	*paletteLabel;
	NSString	*toolTip;
	NSImage		*image;
	
	id			target;
	SEL			action;
	
	BOOL		isEnabled;
	int			tag;
}

- (void)setLabel:(NSString *)newLabel;
- (NSString *)label;
- (void)setPaletteLabel:(NSString *)newLabel;
- (NSString *)paletteLabel;
- (void)setToolTip:(NSString *)newToolTip;
- (NSString *)toolTip;
- (void)setTag:(int)newTag;
- (int)tag;
- (void)setTarget:(id)newTarget;
- (id)target;
- (void)setAction:(SEL)newAction;
- (SEL)action;
- (void)setEnabled:(BOOL)flag;
- (BOOL)isEnabled;
- (void)setImage:(NSImage *)newImage;
- (NSImage *)image;

@end
