/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) The Chatkit Project, 2004-2005.  All rights reserved.
 */

#import "UnifiedToolbarLabelCell.h"

//Padding around label text
#define LABEL_PADDING		5

/*!
 * @class UnifiedToolbarLabelCell
 * @abstract Custom GenericSegmentedCell which draws unified toolbar labels
 */
@implementation UnifiedToolbarLabelCell

/*!
 * @abstract Returns attribute dictionary for drawing our label
 */
- (NSDictionary *)labelAttributesWithColor:(NSColor *)color
{
	if(!color) color = [NSColor controlTextColor];
	
	NSMutableParagraphStyle	*style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setAlignment:NSCenterTextAlignment];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont labelFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
		style, NSParagraphStyleAttributeName,
		color, NSForegroundColorAttributeName,
		nil];
}

/*!
 * @abstract Calculate and return the desired width of a segment
 */
- (float)autosizeWidthForSegment:(int)segment
{
	return [[self labelForSegment:segment] sizeWithAttributes:[self labelAttributesWithColor:nil]].width + LABEL_PADDING;
}

/*!
 * @abstract Calculate and return the mininum allowed width of a segment
 */
- (float)minimumWidthForSegment:(int)segment
{
	return 0; //No minimum size
}

/*!
 * @abstract Draw background of a segment
 */
- (void)_drawBackgroundWithFrame:(NSRect)frame inView:(NSView *)view
{
	//No background
}

/*!
 * @abstract Draw content of a segment
 */
- (void)drawSegment:(int)segment inFrame:(NSRect)frame withView:(NSView *)controlView
{
	//When the label is pressed, draw a shadow label beneath it
	if ([self pressedSegment] == segment) {
		[[self labelForSegment:segment] drawInRect:NSOffsetRect(frame, 0 , -1)
									withAttributes:[self labelAttributesWithColor:[NSColor darkGrayColor]]];
	}
	
	NSColor *color = ([self isEnabledForSegment:segment] ?
					  [NSColor controlTextColor] :
					  [NSColor disabledControlTextColor]);
	
	[[self labelForSegment:segment] drawInRect:frame
								withAttributes:[self labelAttributesWithColor:color]];
}

@end
