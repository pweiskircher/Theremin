//
//  CustomBrowserCell.m
//  NSBrowserBugWorkarounds
//
//  Created by Hamish on 03/12/2005.
//  Copyright 2005 Hamish Allan. All rights reserved.
//

#import "PWDirectoryCell.h"

@implementation PWDirectoryCell

- (void)setObjectValue:(id)value
{
	[self setImage:[NSImage imageNamed:@"folder"]];
	[super setObjectValue:value];
}

@end