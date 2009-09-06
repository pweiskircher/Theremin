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

#import "PWTableView.h"
#import "WindowController.h"
#import "PWTableViewMenuItem.h"
#import "SystemInformation.h"

NSString *nBecameFirstResponder = @"nBecameFirstResponder";

@interface PWTableView (PrivateMethods)
- (NSString *) customizableColumnsUserDefaultsName;
- (void) saveTableColumnsState;
- (void) updateTableColumnsState;
- (PWTableViewMenuItem *) tableViewMenuItemWithTableColumnIdentifier:(NSString *)identifier;
@end

@implementation PWTableView

- (void) awakeFromNib {
	[mKeysTyped release];
	mKeysTyped = [[NSMutableString string] retain];
	mLiveSearchEnabled = NO;
	mLiveSearchTimer = nil;
	mSelectAllSelectsRow = SELECT_ALL_SELECTS_ALL_ROWS;
}

- (void) dealloc {
	[mActionCharacters release];
	[mKeysTyped release];
	[mLiveSearchTimer invalidate];
	[mColumnToSearchIdentifier release];
	[mCustomizableTableColumnsMenu release];
	[super dealloc];
}

- (BOOL) liveSearchEnabled {
	return mLiveSearchEnabled;
}

- (void) setLiveSearchEnabled:(BOOL)value {
	unsigned major, minor, bugfix;
	[SystemInformation getSystemVersionMajor:&major minor:&minor bugFix:&bugfix];
	
	// if we are on >= 5, we don't use the code below.
	if (minor < 5)
		mLiveSearchEnabled = value;
}

- (void)setColumnIdentifierToSearch:(NSString *)identifier {
	mColumnToSearchIdentifier = [identifier retain];
}

- (NSString*) columnIdentifierToSearch {
	return [NSString stringWithString:mColumnToSearchIdentifier];
}

- (void)keyDown:(NSEvent *)theEvent {
	NSString *str = [theEvent characters];
	unichar key = [str length] ? [str characterAtIndex:0] : '\0';
	
	if (mLiveSearchEnabled == YES) {
		if (key == ' ' && mLiveSearchTimer == nil) {
			return [super keyDown:theEvent];
		}
		
		// some stuff taken from Cyberduck
		if ( ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:key] || [[NSCharacterSet whitespaceCharacterSet] characterIsMember:key]) &&
			(![[NSCharacterSet controlCharacterSet] characterIsMember:key])) {
			[mKeysTyped appendString:[theEvent characters]];
			[mLiveSearchTimer invalidate];
			mLiveSearchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
													   target:self 
													 selector:@selector(keyDownTimeoutTriggered:) 
													 userInfo:nil 
													  repeats:NO];
			return;
		}
	}
	
	for (int i = 0; i < [mActionCharacters count]; i++) {
		NSDictionary *dict = [mActionCharacters objectAtIndex:i];
		NSCharacterSet *characterSet = [dict objectForKey:@"characters"];
		unsigned int modifierflags = [[dict objectForKey:@"modifiers"] unsignedIntValue];
		
		if ([characterSet characterIsMember:key]) {
			
			if (modifierflags == 0 || [theEvent modifierFlags] & modifierflags) {
				id target = [dict objectForKey:@"target"];
				SEL selector = NSSelectorFromString([dict objectForKey:@"selector"]);
				
				mCharacterActionInProgress = YES;
				if ([target respondsToSelector:selector])
					[target performSelector:selector withObject:self];
				mCharacterActionInProgress = NO;
				
				return;
			}
		}
	}
	
	[super keyDown:theEvent];
}

- (void) selectLiveSearchRow:(NSString *)searchString {
	NSString *compare = [searchString lowercaseString];
	int numberOfRows = [[self dataSource] numberOfRowsInTableView:self];
	int row = -1;
	int to_index = 0;
	int smallest_difference = -1;
	
	NSTableColumn *column = [self tableColumnWithIdentifier:mColumnToSearchIdentifier];
	if (column == nil) {
		NSLog(@"Wrong table column identifier ...");
		return;
	}
	
	for (int i = 0; i < numberOfRows; i++) {
		NSString *object = [[[self dataSource] tableView:self objectValueForTableColumn:column row:i] lowercaseString];
		
		if (to_index < [object length] && to_index < [compare length] + 1) {
			if (object && [[object substringToIndex:to_index] isEqualToString:[compare substringToIndex:to_index]]) {
				char one = [compare characterAtIndex:to_index];
				char two = (to_index == [object length]) ? ' ' : [object characterAtIndex:to_index];
				
				int difference = abs(one - two);
				if (difference == 0) {
					while (difference == 0) {
						to_index++;
						if (to_index == [compare length] || to_index == [object length] + 1)
							break;
						
						one = [compare characterAtIndex:to_index];
						two = (to_index == [object length]) ? ' ' : [object characterAtIndex:to_index];
						difference = abs(one - two);
					}
					smallest_difference = -1;
					row = i;
					if (to_index == [compare length] || to_index == [object length] + 1) {
						break;
					} else if (smallest_difference == -1 || difference < smallest_difference) {
						smallest_difference = difference;
						row = i;
					}
				}
			}
		}
	}
	if (row != -1) {
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		[self scrollRowToVisible:row];
	}
}

- (void)keyDownTimeoutTriggered:(NSTimer *)timer {
	mLiveSearchTimer = nil;
	
	[self selectLiveSearchRow:mKeysTyped];
	
	[mKeysTyped release], mKeysTyped = [[NSMutableString string] retain];
}

- (void) setActionForCharacters:(NSCharacterSet *)characterset onTarget:(id)target usingSelector:(SEL)selector {
	[self setActionForCharacters:characterset withModifiers:0 onTarget:target usingSelector:selector];
}

- (void) setActionForCharacters:(NSCharacterSet *)characterset withModifiers:(unsigned int)modifiers onTarget:(id)target usingSelector:(SEL)selector {
	if (!mActionCharacters) {
		mActionCharacters = [[NSMutableArray array] retain];
	}

	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:characterset, @"characters", [NSNumber numberWithUnsignedInt:modifiers], @"modifiers", target, @"target", NSStringFromSelector(selector), @"selector", nil];
	[mActionCharacters addObject:dict];
}

- (BOOL) characterActionInProgress {
	return mCharacterActionInProgress;
}

// taken from http://www.cocoadev.com/index.pl?RightClickSelectInTableView
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	// get the current selections for the outline view. 
	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	
	// select the row that was clicked before showing the menu for the event
	NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	int row = [self rowAtPoint:mousePoint];
	
	// figure out if the row that was just clicked on is currently selected
	if ([selectedRowIndexes containsIndex:row] == NO)
	{
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	}
	// else that row is currently selected, so don't change anything.
	
	return [super menuForEvent:theEvent];
}

- (BOOL)becomeFirstResponder {
	BOOL result = [super becomeFirstResponder];
	if (result == YES) {
		[[NSNotificationCenter defaultCenter] postNotificationName:nBecameFirstResponder object:self];
	}
	return result;
}

- (void) updateTableColumnsState {
	NSArray *data = [[NSUserDefaults standardUserDefaults] objectForKey:[self customizableColumnsUserDefaultsName]];
	
	NSEnumerator *enumerator = [data objectEnumerator];
	NSDictionary *dictionary;
	while (dictionary = [enumerator nextObject]) {
		BOOL hide = [[dictionary objectForKey:@"state"] intValue] == NSOffState;
		if (hide == YES)
			hide = [[dictionary objectForKey:@"dState"] intValue] == NSOffState;
		
		if (hide) {
			NSString *identifier = [dictionary objectForKey:@"identifier"];			
			NSTableColumn *column = [self tableColumnWithIdentifier:identifier];
			[self removeTableColumn:column];
			
			[[self tableViewMenuItemWithTableColumnIdentifier:identifier] setState:NSOffState];
		}
	}
}

- (void) saveTableColumnsState {
	NSEnumerator *enumerator = [[mCustomizableTableColumnsMenu itemArray] objectEnumerator];
	
	NSMutableArray *data = [NSMutableArray array];
	PWTableViewMenuItem *item;
	while (item = [enumerator nextObject]) {
		[data addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[item state]], @"state",
						  [[item tableColumn] identifier], @"identifier", nil]];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:data forKey:[self customizableColumnsUserDefaultsName]];
}

- (PWTableViewMenuItem *) tableViewMenuItemWithTableColumnIdentifier:(NSString *)identifier {
	for (int i = 0; i < [[mCustomizableTableColumnsMenu itemArray] count]; i++) {
		PWTableViewMenuItem *item = [mCustomizableTableColumnsMenu itemAtIndex:i];
		if ([[[item tableColumn] identifier] isEqualToString:identifier])
			return item;
	}
	return nil;
}

- (NSString *) customizableColumnsUserDefaultsName {
	return [NSString stringWithFormat:@"%@ Customizable Columns", [self autosaveName]];
}

- (void) enableCustomizableColumnsWithAutosaveName:(NSString *)autosaveName {
	[mCustomizableTableColumnsMenu release], mCustomizableTableColumnsMenu = nil;
	[[self headerView] setMenu:nil];

	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	NSArray *tableColumns = [self tableColumns];
	
	for (int i = 0; i < [tableColumns count]; i++) {
		NSTableColumn *column = [tableColumns objectAtIndex:i];
		
		PWTableViewMenuItem *item = [[[PWTableViewMenuItem alloc] init] autorelease];
		[item setTableColumn:column];
		[item setTarget:self];
		[item setAction:@selector(toggleColumn:)];
		[item setTitle:[[column headerCell] title]];
		[item setState:NSOnState];
		
		[menu addItem:item];
	}
	
	mCustomizableTableColumnsMenu = [menu retain];
	
	[[self headerView] setMenu:mCustomizableTableColumnsMenu];
	
	[self setAutosaveName:autosaveName];
	[self updateTableColumnsState];
}

- (void) toggleColumn:(id)sender {
	PWTableViewMenuItem *item = sender;

	NSTableColumn *column = [item tableColumn];
	if ([sender state] == NSOnState) {
		[sender setState:NSOffState];
		[self removeTableColumn:column];
	} else {
		[sender setState:NSOnState];
		[self addTableColumn:column];
	}

	[self saveTableColumnsState];
}

- (void) selectAllSelectsRow:(int)theRow {
	mSelectAllSelectsRow = theRow;
}

- (void) selectAll:(id)sender {
	if (mSelectAllSelectsRow == SELECT_ALL_SELECTS_ALL_ROWS)
		[super selectAll:sender];
	else {
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:mSelectAllSelectsRow] byExtendingSelection:NO];
		[self scrollRowToVisible:mSelectAllSelectsRow];
	}
}

@end
