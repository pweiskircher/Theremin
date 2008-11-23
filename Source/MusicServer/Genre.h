//
//  Genre.h
//  Theremin
//
//  Created by Patrik Weiskircher on 02.06.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *gUnknownGenreName;
#define TR_S_UNKNOWN_GENRE	NSLocalizedString(@"Unknown Genre", @"Unknown Genre")

@interface Genre : NSObject {
	NSString *mName;
	int mSQLIdentifier;
}
- (id) init;
- (void) dealloc;

- (NSString *) description;

- (NSString *) name;
- (int) SQLIdentifier;
- (NSNumber *) CocoaSQLIdentifier;

- (void) setName:(NSString *)aName;
- (void) setSQLIdentifier:(int)aInteger;
@end
