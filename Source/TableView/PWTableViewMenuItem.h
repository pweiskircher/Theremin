//
//  PWTableViewMenuItem.h
//  Theremin
//
//  Created by Patrik Weiskircher on 07.06.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PWTableViewMenuItem : NSMenuItem {
	NSTableColumn *mTableColumn;
}
- (void) setTableColumn:(NSTableColumn *)aColumn;
- (NSTableColumn *) tableColumn;
@end
