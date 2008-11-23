//
//  Genre.m
//  Theremin
//
//  Created by Patrik Weiskircher on 02.06.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Genre.h"

NSString *gUnknownGenreName = @"gUnknownGenreName";

@implementation Genre
- (id) init {
	self = [super init];
	if (self != nil) {
		mName = nil;
		mSQLIdentifier = -1;
	}
	return self;
}

- (void) dealloc {
	[mName release];
	[super dealloc];
}

- (NSString *) description {
	return [NSString stringWithFormat:@"Genre <0x%08x> Name: %@ SQLIdentifier: %d", self, [self name], [self SQLIdentifier]];
}

- (NSString *) name {
	return [[mName retain] autorelease];
}

- (int) SQLIdentifier {
	return mSQLIdentifier;
}

- (NSNumber *) CocoaSQLIdentifier {
	return [NSNumber numberWithInt:mSQLIdentifier];
}


- (void) setName:(NSString *)aName {
	[mName release];
	
	if ([aName isEqualToString:gUnknownGenreName])
		mName = [TR_S_UNKNOWN_GENRE retain];
	else
		mName = [aName retain];
}

- (void) setSQLIdentifier:(int)aInteger {
	mSQLIdentifier = aInteger;
}


- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    if ([encoder isBycopy]) return self;
    return [super replacementObjectForPortCoder:encoder];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:mName];
	[encoder encodeBytes:&mSQLIdentifier length:sizeof(mSQLIdentifier)];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	mName = [[decoder decodeObject] retain];
	
	unsigned length;
	memcpy(&mSQLIdentifier, [decoder decodeBytesWithReturnedLength:&length], sizeof(mSQLIdentifier));
	
	return self;
}
@end
