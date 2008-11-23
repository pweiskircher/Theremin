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

extern NSString *nBecameFirstResponder;
extern NSString *PWCustomizableColumnsColumn;
extern NSString *PWCustomizableColumnsMenuLabel;

#define SELECT_ALL_SELECTS_ALL_ROWS	-1

@interface PWTableView : NSTableView {
	NSMutableString *mKeysTyped;
	NSString *mColumnToSearchIdentifier;
	BOOL mLiveSearchEnabled;
	NSTimer *mLiveSearchTimer;
	
	NSMutableArray *mActionCharacters;
	BOOL mCharacterActionInProgress;
	
	NSMenu *mCustomizableTableColumnsMenu;
	
	int mSelectAllSelectsRow;
}
- (void) awakeFromNib;
- (void) dealloc;

- (BOOL) liveSearchEnabled;
- (void) setLiveSearchEnabled:(BOOL)value;

- (void)setColumnIdentifierToSearch:(NSString *)identifier;
- (NSString*) columnIdentifierToSearch;

- (void)keyDown:(NSEvent *)theEvent;
- (void)keyDownTimeoutTriggered:(NSTimer *)timer;

- (void) setActionForCharacters:(NSCharacterSet *)characterset onTarget:(id)target usingSelector:(SEL)selector;
- (void) setActionForCharacters:(NSCharacterSet *)characterset withModifiers:(unsigned int)modifiers onTarget:(id)target usingSelector:(SEL)selector;

- (BOOL) characterActionInProgress;

- (void) enableCustomizableColumnsWithAutosaveName:(NSString *)autosaveName;

- (void) selectAllSelectsRow:(int)theRow;

@end
