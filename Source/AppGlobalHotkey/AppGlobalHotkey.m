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

#import "AppGlobalHotkey.h"


@implementation AppGlobalHotkey
- (id) initWithTarget:(id)aTarget
			andAction:(SEL)aAction
	withKeyEquivalent:(NSString *)aKeyEq {
	self = [super init];
	if (self != nil) {
		[self setTarget:aTarget];
		[self setAction:aAction];
		[self setKeyEquivalent:aKeyEq];
	}
	return self;
}

- (id) initWithTarget:(id)aTarget
			andAction:(SEL)aAction
			  withKey:(int)key {
	unichar ch = key;
	return [self initWithTarget:aTarget andAction:aAction withKeyEquivalent:[NSString stringWithCharacters:&ch length:1]];
}


- (void) dealloc {
	[mKeyEquivalent release];
	[super dealloc];
}

- (NSString *) keyEquivalent {
	return [[mKeyEquivalent retain] autorelease];
}

- (void) setKeyEquivalent:(NSString *)aKeyEq {
	if (mKeyEquivalent != aKeyEq) {
		[mKeyEquivalent release];
		mKeyEquivalent = [aKeyEq retain];
	}
}


- (id) target {
	return mTarget;
}

- (SEL) action {
	return mAction;
}

- (void) setTarget:(id)aTarget {
	mTarget = aTarget;
}

- (void) setAction:(SEL)aAction {
	mAction = aAction;
}

- (void) setAllowedTypes:(NSArray *)theTypes {
	[mAllowedTypes release];
	mAllowedTypes = [theTypes retain];
}

- (void) setIgnoreTypes:(NSArray *)theTypes {
	[mIgnoredTypes release];
	mIgnoredTypes = [theTypes retain];
}

- (void) excludeFirstResponderClasses:(NSArray *)theArray {
	[mExcludeFirstResponderClasses release];
	mExcludeFirstResponderClasses = [theArray retain];
}

- (void) excludeModifierKeys:(unsigned int)flags {
	mExcludedModifierKeys = flags;
}

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent onWindow:(NSWindow *)aWindow {
	if (mKeyEquivalent == nil || mAction == nil || mTarget == nil)
		return NO;

	if (mAllowedTypes && [mAllowedTypes containsObject:[NSNumber numberWithUnsignedInt:[anEvent type]]] == NO)
		return NO;
	
	if ([[anEvent characters] isEqualTo:mKeyEquivalent]) {
		if (mExcludeFirstResponderClasses) {
			for (int i = 0; i < [mExcludeFirstResponderClasses count]; i++) {
				if ([[aWindow firstResponder] isKindOfClass:[mExcludeFirstResponderClasses objectAtIndex:i]])
					return NO;
			}
		}
		
		if (mExcludedModifierKeys) {
			if ([anEvent modifierFlags] & mExcludedModifierKeys)
				return NO;
		}
		
		if (mIgnoredTypes && [mIgnoredTypes containsObject:[NSNumber numberWithUnsignedInt:[anEvent type]]] == YES)
			return YES;
		
		if ([mTarget respondsToSelector:mAction]) {
			[mTarget performSelector:mAction withObject:self];
			return YES;
		}
	}
	
	return NO;
}

@end
