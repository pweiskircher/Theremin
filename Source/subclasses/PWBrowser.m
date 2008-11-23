//
//  NSBrowserBugWorkarounds.m
//  NSBrowserBugWorkarounds
//
//  Created by Hamish on 11/01/2006.
//  Copyright 2006 Hamish Allan. All rights reserved.
//

#import "PWBrowser.h"
#import "PWDirectoryCell.h"

#define SelectionChangedContext ((void *)0x10011)

@implementation PWBrowser

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder]))
		[self setCellClass:[PWDirectoryCell class]];
	return self;
}

- (void)dealloc
{
	[_selectionController removeObserver:self forKeyPath:@"selectedObjects"];
	[super dealloc];
}

- (void)awakeFromNib
{
	[_selectionController addObserver:self forKeyPath:@"selectedObjects"
							  options:0 context:SelectionChangedContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context
{
	if (context == SelectionChangedContext)
	{
		NSArray *selectedObjects = [_selectionController selectedObjects];
		if ([selectedObjects count] > 0)
		{
			NSArray *indexPaths = [[selectedObjects objectAtIndex:0] indexPaths];
			NSIndexPath *indexPath = [indexPaths objectAtIndex:0];
			
			int column = [indexPath length] - 1;
			int i;
			for (i = 0; i < column; ++i)
			{
				int row = [indexPath indexAtPosition:i];
				NSMatrix *matrix = [self matrixInColumn:i];
				if (matrix == nil)
				{
					[self addColumn];
					matrix = [self matrixInColumn:i];
				}
				[matrix setSelectionFrom:row to:row anchor:row highlight:YES];
			}
			
			NSMatrix *matrix = [self matrixInColumn:column];
			if (matrix == nil)
			{
				[self addColumn];
				matrix = [self matrixInColumn:column];
			}
			
			[self scrollColumnToVisible:0];
			[self scrollColumnToVisible:column];
			[matrix deselectAllCells];
			
			NSEnumerator *e = [indexPaths objectEnumerator];
			while ((indexPath = [e nextObject]))
			{
				int row = [indexPath indexAtPosition:column];
				[matrix setSelectionFrom:row to:row anchor:row highlight:YES];
			}
		}
	}
	else
		[super observeValueForKeyPath:keyPath
							 ofObject:object change:change context:context];
}

@end