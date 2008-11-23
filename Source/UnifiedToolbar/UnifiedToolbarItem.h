/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) The Chatkit Project, 2004-2005.  All rights reserved.
 */

#import <Cocoa/Cocoa.h>


@interface UnifiedToolbarItem : NSToolbarItem {
	NSMutableArray	*segments;
	BOOL			isInPalette;
}

- (id)initWithItemIdentifier:(NSString *)itemIdentifier;
- (id)initWithItemIdentifier:(NSString *)itemIdentifier segmentCount:(int)numSegments;

- (void)setInPalette:(BOOL)flag;
- (void)configureForDisplayMode:(NSToolbarDisplayMode)displayMode;
- (void)performActionForSegment:(int)segmentIndex;

//Segment Properties
- (void)setLabel:(NSString *)label forSegment:(int)segment;
- (NSString *)labelForSegment:(int)segment;
- (void)setPaletteLabel:(NSString *)paletteLabel forSegment:(int)segment;
- (NSString *)paletteLabelForSegment:(int)segment;
- (void)setToolTip:(NSString *)toolTip forSegment:(int)segment;
- (NSString *)toolTipForSegment:(int)segment;
- (void)setTag:(int)tag forSegment:(int)segment;
- (int)tagForSegment:(int)segment;
- (void)setTarget:(id)target forSegment:(int)segment;
- (id)targetForSegment:(int)segment;
- (void)setAction:(SEL)action forSegment:(int)segment;
- (SEL)actionForSegment:(int)segment;
- (void)setEnabled:(BOOL)enabled forSegment:(int)segment;
- (BOOL)isEnabledForSegment:(int)segment;
- (void)setImage:(NSImage *)image forSegment:(int)segment;
- (NSImage *)imageForSegment:(int)segment;

@end
