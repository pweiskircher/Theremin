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
		_identifier = -1;
	}
	return self;
}

- (void) dealloc {
	[mName release];
	[super dealloc];
}

- (NSString *) description {
	return [NSString stringWithFormat:@"Genre <0x%08x> Name: %@ SQLIdentifier: %d", self, [self name], [self identifier]];
}

- (NSString *) name {
	return [[mName retain] autorelease];
}

- (int) identifier {
	return _identifier;
}

- (void) setName:(NSString *)aName {
	[mName release];
	
	if ([aName isEqualToString:gUnknownGenreName])
		mName = [TR_S_UNKNOWN_GENRE retain];
	else
		mName = [aName retain];
}

- (void) setIdentifier:(int)aInteger {
	_identifier = aInteger;
}


- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    if ([encoder isBycopy]) return self;
    return [super replacementObjectForPortCoder:encoder];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:mName];
	[encoder encodeBytes:&_identifier length:sizeof(_identifier)];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	mName = [[decoder decodeObject] retain];
	
	unsigned length;
	memcpy(&_identifier, [decoder decodeBytesWithReturnedLength:&length], sizeof(_identifier));
	
	return self;
}
@end
