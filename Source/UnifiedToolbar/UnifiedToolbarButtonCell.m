/*
 * This file is part of ChatKit - http://www.chatkit.net
 * Copyright (c) The Chatkit Project, 2004-2005.  All rights reserved.
 */

#import "UnifiedToolbarButtonCell.h"

//Button sizing
#define BUTTON_SINGLE_WIDTH		41
#define BUTTON_GROUP_WIDTH		40

//Dimensions for drawing our cell's icon
#define IMAGE_SIZE_X			29
#define IMAGE_SIZE_Y			19

//Fraction to draw icon when enabled, disabled
#define ENABLED_ICON_FRACTION		1.0
#define DISABLED_ICON_FRACTION		0.4

typedef enum {
	LeftCap = 0,
	InnerLeft,
	Middle,
	InnerRight,
	RightCap
} UnifiedButtonSegment;

typedef enum {
	Normal = 0,
	Inactive,
	Pressed,
	Hovered
} UnifiedButtonState;

//Shared images
static NSSize	imageSize = {15, 32}; 	//Dimensions of segment images
static NSImage 	*images[5][4];
static BOOL		imagesLoaded = NO;

/*!
 * @class UnifiedToolbarButtonCell
 * @abstract Custom GenericSegmentedCell which draws unified toolbar buttons
 */
@implementation UnifiedToolbarButtonCell

/*!
 * @abstract Init
 */
- (id)init
{
	if ((self = [super init])) {
		if (!imagesLoaded) {
			images[LeftCap   ][Normal  ] = [NSImage imageNamed:@"TB_Segment_LeftCap.tiff"];
			images[LeftCap   ][Inactive] = [NSImage imageNamed:@"TB_Segment_LeftCapInactive.tiff"];
			images[LeftCap   ][Pressed ] = [NSImage imageNamed:@"TB_Segment_LeftCapPress.tiff"];
			images[LeftCap   ][Hovered ] = [NSImage imageNamed:@"TB_Segment_LeftCapRoll.tiff"];
			images[InnerLeft ][Normal  ] = [NSImage imageNamed:@"TB_Segment_InnerRight.tiff"];
			images[InnerLeft ][Inactive] = [NSImage imageNamed:@"TB_Segment_InnerRightInactive.tiff"];
			images[InnerLeft ][Pressed ] = [NSImage imageNamed:@"TB_Segment_InnerRightPress.tiff"];
			images[InnerLeft ][Hovered ] = [NSImage imageNamed:@"TB_Segment_InnerRightRoll.tiff"];
			images[Middle    ][Normal  ] = [NSImage imageNamed:@"TB_Single_Middle.tiff"];
			images[Middle    ][Inactive] = [NSImage imageNamed:@"TB_Single_MiddleInactive.tiff"];
			images[Middle    ][Pressed ] = [NSImage imageNamed:@"TB_Single_MiddlePress.tiff"];
			images[Middle    ][Hovered ] = [NSImage imageNamed:@"TB_Single_MiddleRoll.tiff"];			
			images[InnerRight][Normal  ] = [NSImage imageNamed:@"TB_Segment_InnerLeft.tiff"];
			images[InnerRight][Inactive] = [NSImage imageNamed:@"TB_Segment_InnerLeftInactive.tiff"];
			images[InnerRight][Pressed ] = [NSImage imageNamed:@"TB_Segment_InnerLeftPress.tiff"];
			images[InnerRight][Hovered ] = [NSImage imageNamed:@"TB_Segment_InnerLeftRoll.tiff"];
			images[RightCap  ][Normal  ] = [NSImage imageNamed:@"TB_Segment_RightCap.tiff"];
			images[RightCap  ][Inactive] = [NSImage imageNamed:@"TB_Segment_RightCapInactive.tiff"];
			images[RightCap  ][Pressed ] = [NSImage imageNamed:@"TB_Segment_RightCapPress.tiff"];
			images[RightCap  ][Hovered ] = [NSImage imageNamed:@"TB_Segment_RightCapRoll.tiff"];
				 
			imagesLoaded = YES;
		}
	}
	
	return self;
}

/*!
 * @abstract Calculate and return the desired width of a segment
 */
- (float)autosizeWidthForSegment:(int)segment
{
	if ([self segmentCount] == 1) {
		return BUTTON_SINGLE_WIDTH;
	}else{
		return BUTTON_GROUP_WIDTH;
	}
}

/*!
 * @abstract Calculate and return the mininum allowed width of a segment
 */
- (float)minimumWidthForSegment:(int)segment
{
	return imageSize.width * 2;
}

- (id) _setMenuShouldBeUniquedAgainstMainMenu:(id)a {
		return 0;
}


/*!
 * @abstract Draw background of a segment
 */
- (void)drawBackgroundForSegment:(int)segment inFrame:(NSRect)cellFrame withView:(NSView *)controlView
{
	UnifiedButtonSegment leftSegment, middleSegment, rightSegment;
	UnifiedButtonState	 state;
	int	 				 numSegments = [self segmentCount];

	//Determine images
	leftSegment = (segment == 0 ? LeftCap : InnerLeft);
	middleSegment = Middle;
	rightSegment = (segment == numSegments-1 ? RightCap : InnerRight);

	//Determine state
	if ([self pressedSegment] == segment) {
		state = Pressed;
	}else if ([self hoveredSegment] == segment) {
		state = Hovered;
	}else if (![self isActive]) {
		state = Inactive;
	}else{
		state = Normal;
	}
	
	//Draw Left segment
	[images[leftSegment][state] drawInRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, imageSize.width, imageSize.height)
								   fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
								  operation:NSCompositeSourceOver
								   fraction:1.0];
	cellFrame.origin.x += imageSize.width;
	cellFrame.size.width -= imageSize.width;
	
	//Draw Middle segment
	while (cellFrame.size.width > imageSize.width) {
		int width;
		
		//Crop the segment when not enough space remains
		if (cellFrame.size.width - imageSize.width > imageSize.width) {
			width = imageSize.width;
		} else {
			width = cellFrame.size.width - imageSize.width;
		}
		
		[images[middleSegment][state] drawInRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, width, imageSize.height)
										 fromRect:NSMakeRect(0, 0, width, imageSize.height)
										operation:NSCompositeSourceOver
										 fraction:1.0];
		cellFrame.origin.x += width;
		cellFrame.size.width -= width;
	}
	
	//Draw Right segment
	[images[rightSegment][state] drawInRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, imageSize.width, imageSize.height)
									fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
								   operation:NSCompositeSourceOver
									fraction:1.0];
	cellFrame.origin.x += imageSize.width;
	cellFrame.size.width -= imageSize.width;
}

/*!
 * @abstract Draw content of a segment
 */
- (void)drawSegment:(int)segment inFrame:(NSRect)frame withView:(NSView *)controlView
{
	NSImage		*image = [self imageForSegment:segment];
	NSRect		imageRect = NSMakeRect(frame.origin.x + (frame.size.width - IMAGE_SIZE_X) / 2,
									   frame.origin.y + 2,
									   IMAGE_SIZE_X,
									   IMAGE_SIZE_Y);
	
	[image drawInRect:imageRect
			 fromRect:NSMakeRect(0, 0, IMAGE_SIZE_X, IMAGE_SIZE_Y)
			operation:NSCompositeSourceOver
			 fraction:([self isEnabledForSegment:segment] ? ENABLED_ICON_FRACTION : DISABLED_ICON_FRACTION)];
}

- (BOOL) acceptsFirstResponder {
	return NO;
}

@end
