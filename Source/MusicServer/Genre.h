//
//  Genre.h
//  Theremin
//
//  Created by Patrik Weiskircher on 02.06.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ThereminEntity.h"

extern NSString *gUnknownGenreName;
#define TR_S_UNKNOWN_GENRE	NSLocalizedString(@"Unknown Genre", @"Unknown Genre")

@interface Genre : NSObject <ThereminEntity> {
	NSString *mName;
	int _identifier;
}
- (id) init;
- (void) dealloc;

- (NSString *) description;

- (NSString *) name;
- (int) identifier;

- (void) setName:(NSString *)aName;
- (void) setIdentifier:(int)aInteger;
@end
