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

#import <Cocoa/Cocoa.h>


@interface AppGlobalHotkey : NSObject {
	NSString *mKeyEquivalent;
	
	id mTarget;
	SEL mAction;
	
	NSArray *mExcludeFirstResponderClasses;
	NSArray *mAllowedTypes;
	NSArray *mIgnoredTypes;
	unsigned int mExcludedModifierKeys;
}
- (id) initWithTarget:(id)aTarget
			andAction:(SEL)aAction
	withKeyEquivalent:(NSString *)aKeyEq;

- (id) initWithTarget:(id)aTarget
			andAction:(SEL)aAction
			  withKey:(int)key;

- (NSString *) keyEquivalent;

- (void) setKeyEquivalent:(NSString *)aKeyEq;


- (id) target;
- (SEL) action;

- (void) setTarget:(id)aTarget;
- (void) setAction:(SEL)aAction;

- (void) setAllowedTypes:(NSArray *)theTypes;
- (void) setIgnoreTypes:(NSArray *)theTypes;
- (void) excludeFirstResponderClasses:(NSArray *)theArray;

// if these flags are present, ignore the key press
- (void) excludeModifierKeys:(unsigned int)flags;

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent onWindow:(NSWindow *)aWindow;
@end
