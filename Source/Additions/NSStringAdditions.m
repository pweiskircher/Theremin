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

#import "NSStringAdditions.h"


@implementation NSString (PWStringAdditions)
- (NSComparisonResult)numericCompare:(NSString *)aString {
	return [self compare:aString options:NSNumericSearch];
}

- (NSComparisonResult)artistCompare:(NSString *)aString {
	NSString *artist1 = self;
	NSString *artist2 = aString;
	
	if ([artist1 length] > 3 && [[artist1 substringToIndex:3] caseInsensitiveCompare:@"the "] == NSOrderedSame)
		artist1 = [artist1 substringFromIndex:4];
	
	if ([artist2 length] > 3 && [[artist2 substringToIndex:3] caseInsensitiveCompare:@"the "] == NSOrderedSame)
		artist2 = [artist2 substringFromIndex:4];
	
	return [artist1 caseInsensitiveCompare:artist2];
}

+ (NSString *)convertSecondsToTime:(int)seconds andIsValid:(BOOL *)isValid {
	if (seconds < 0) {
		if (isValid)
			*isValid = NO;
		return NSLocalizedString(@"n/a", @"Not available marker for time");
	}
	
	if (isValid)
		*isValid = YES;
	
	NSMutableString *s = [NSMutableString string];

	int format[] = { 24*60*60, 60*60, 60, 0 };
	BOOL add = NO;
	
	for (int i = 0; i < 4; i++) {
		int t;
		
		if (format[i] > 0) {
			t = seconds/format[i];
			seconds -= t*format[i];			
		} else
			t = seconds;
		
		if (t > 0 || add || i == 2) {
			add = YES;
			if ([s length] > 0)
				[s appendFormat:@":%02d", t];
			else
				[s appendFormat:@"%d", t];
		}
	}
	
	return s;
}

- (NSArray *) parseIntoTokens {
	NSMutableArray *array = [NSMutableArray array];
	NSMutableString *s = [NSMutableString string];
	
	BOOL inQuote = NO;
	
	for (int i = 0; i < [self length]; i++) {
		unichar ch = [self characterAtIndex:i];
		
		if (inQuote == NO) {
			if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:ch]) {
				if ([s length] > 0) {
					[array addObject:s];
					s = [NSMutableString string];
				}
				continue;
			}
			
			if (ch == '\"') {
				inQuote = YES;
				if ([s length] > 0) {
					[array addObject:s];
					s = [NSMutableString string];
				}
				continue;
			}
			
			[s appendString:[NSString stringWithCharacters:&ch length:1]];
		} else {
			if (ch == '\"') {
				inQuote = NO;
				if ([s length] > 0) {
					[array addObject:s];
					s = [NSMutableString string];
				}
				continue;
			}
			
			[s appendString:[NSString stringWithCharacters:&ch length:1]];
		}
	}
	
	if ([s length] > 0) {
		[array addObject:s];
	}
	
	return array;
}

- (NSArray *) parseIntoSQLSearchTokens {
	NSArray *tokens = [self parseIntoTokens];
	if ([tokens count] == 0)
		return tokens;
	
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[tokens count]];
	for (int i = 0; i < [tokens count]; i++) {
		[array addObject:[NSString stringWithFormat:@"%%%@%%", [tokens objectAtIndex:i]]];
	}
	
	return array;
}

@end
