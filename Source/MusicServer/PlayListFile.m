/*
 Copyright (C) 2006-2007  Patrik Weiskircher
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
 MA 02110-1301, USA.
 */

#import "PlayListFile.h"

NSString *gPlayListFilePropertyFilePath = @"gPlayListFilePropertyFilePath";

@implementation PlayListFile
+ (id)listWithFilePath:(NSString *)aPath {
	return [[[PlayListFile alloc] initWithFilePath:aPath] autorelease];
}

- (id)initWithFilePath:(NSString *)aPath {
	self = [super init];
	if (self != nil) {
		mValues = [[NSMutableDictionary dictionary] retain];
		if (aPath != nil) {
			[mValues setObject:aPath forKey:gPlayListFilePropertyFilePath];
			mValid = YES;
		} else {
			mValid = NO;
		}
	}
	return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"PlayListFile <0x%08x> Path: %@", self, [self filePath]];
}

- (void) dealloc {
	[mValues release];
	[super dealloc];
}

- (BOOL) valid {
	return mValid;
}

- (NSString *) filePath {
	if ([mValues objectForKey:gPlayListFilePropertyFilePath] != nil)
		return [NSString stringWithString:[mValues objectForKey:gPlayListFilePropertyFilePath]];
	return nil;
}

- (void) setPath:(NSString *)aFilePath {
	[mValues setObject:aFilePath forKey:gPlayListFilePropertyFilePath];
}

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    if ([encoder isBycopy]) return self;
    return [super replacementObjectForPortCoder:encoder];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:mValues];
	[encoder encodeBytes:&mValid length:sizeof(mValid)];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	mValues = [[decoder decodeObject] retain];
	
	unsigned length;
	memcpy(&mValid, [decoder decodeBytesWithReturnedLength:&length], sizeof(mValid));
	
	return self;
}

@end
