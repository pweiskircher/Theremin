/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) The Chatkit Project, 2004-2005.  All rights reserved.
 */

#import <Cocoa/Cocoa.h>


@class UnifiedToolbarItem, GenericSegmentedControl;

@interface UnifiedToolbarItemView : NSView {
	GenericSegmentedControl	*segmentedLabel;
	GenericSegmentedControl	*segmentedButton;
	
	UnifiedToolbarItem		*toolbarItem;
}

- (id)initWithSegmentCount:(int)numSegments forToolbarItem:(UnifiedToolbarItem *)aToolbarItem;

- (void)setToolbarItem:(id)item;
- (void)setInPalette:(BOOL)flag;
- (void)performAction:(id)sender;
- (NSSize)configureForDisplayMode:(NSToolbarDisplayMode)displayMode;
- (int)heightForDisplayMode:(NSToolbarDisplayMode)displayMode;

/* Segment Properties */
- (void)setLabel:(NSString *)label forSegment:(int)segment;
- (void)setToolTip:(NSString *)toolTip forSegment:(int)segment;
- (void)setEnabled:(BOOL)enabled forSegment:(int)segment;
- (void)setImage:(NSImage *)image forSegment:(int)segment;

@end
