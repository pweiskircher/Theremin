/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) Adam Iser, 2005.  All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface GenericSegmentedControl : NSSegmentedControl {
	BOOL	isActiveForMainWindowOnly;
}

/* Control Properties */
- (void)setSegmentCount:(int)count;
- (int)segmentCount;
- (void)setTrackingMode:(NSSegmentSwitchTracking)trackingMode;
- (NSSegmentSwitchTracking)trackingMode;
- (void)setActiveForMainWindowOnly:(BOOL)flag;
- (BOOL)isActiveForMainWindowOnly;
- (void)setSelectedSegment:(int)selectedSegment;
- (int)selectedSegment;
- (BOOL)selectSegmentWithTag:(int)tag;

/* Segment Properties */
- (void)setWidth:(float)width forSegment:(int)segment;
- (float)widthForSegment:(int)segment;
- (void)setImage:(NSImage *)image forSegment:(int)segment;
- (NSImage *)imageForSegment:(int)segment;
- (void)setLabel:(NSString *)label forSegment:(int)segment;
- (NSString *)labelForSegment:(int)segment;
- (void)setMenu:(NSMenu *)menu forSegment:(int)segment;
- (NSMenu *)menuForSegment:(int)segment;
- (void)setToolTip:(NSString *)toolTip forSegment:(int)segment;
- (NSString *)toolTipForSegment:(int)segment;
- (void)setTag:(int)tag forSegment:(int)segment;
- (int)tagForSegment:(int)segment;
- (void)setSelected:(BOOL)selected forSegment:(int)segment;
- (BOOL)isSelectedForSegment:(int)segment;
- (void)setEnabled:(BOOL)enabled forSegment:(int)segment;
- (BOOL)isEnabledForSegment:(int)segment;
	
@end
