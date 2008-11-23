//
//  NSBrowserBugWorkarounds.h
//  NSBrowserBugWorkarounds
//
//  Created by Hamish on 11/01/2006.
//  Copyright 2006 Hamish Allan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PWBrowser : NSBrowser
{
	IBOutlet id _selectionController;
}

- (id)initWithCoder:(NSCoder *)decoder;

@end

@protocol PWBrowser
- (NSArray *)indexPaths;
@end
