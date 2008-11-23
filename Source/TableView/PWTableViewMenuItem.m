//
//  PWTableViewMenuItem.m
//  Theremin
//
//  Created by Patrik Weiskircher on 07.06.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PWTableViewMenuItem.h"


@implementation PWTableViewMenuItem
- (void) dealloc
{
	[mTableColumn release];
	[super dealloc];
}

- (void) setTableColumn:(NSTableColumn *)aColumn {
	[mTableColumn release];
	
	mTableColumn = [aColumn retain];
}

- (NSTableColumn *) tableColumn {
	return [[mTableColumn retain] autorelease];
}
@end
