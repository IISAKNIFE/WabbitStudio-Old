//
//  WCKeyBindingCommandPair.m
//  WabbitStudio
//
//  Created by William Towe on 1/11/12.
//  Copyright (c) 2012 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "WCKeyBindingCommandPair.h"
#import "WCKeyBindingCommandSet.h"
#import "RSDefines.h"
#import "NDKeyboardLayout.h"

NSString *const WCKeyBindingCommandPairKeyCodeKey = @"keyCode";
NSString *const WCKeyBindingCommandPairModifierFlagsKey = @"modifierFlags";
NSString *const WCKeyBindingCommandPairTagsKey = @"tags";
NSString *const WCKeyBindingCommandPairCommandModifierMaskKey = @"command";
NSString *const WCKeyBindingCommandPairOptionModifierMaskKey = @"option";
NSString *const WCKeyBindingCommandPairControlModifierMaskKey = @"control";
NSString *const WCKeyBindingCommandPairShiftModifierMaskKey = @"shift";

@interface WCKeyBindingCommandPair ()
- (NSMenuItem *)_menuItemMatchingSelector:(SEL)action inMenu:(NSMenu *)menu;
@end

@implementation WCKeyBindingCommandPair
#pragma mark *** Subclass Overrides ***

- (id)initWithRepresentedObject:(id)representedObject {
	if (!(self = [super initWithRepresentedObject:representedObject]))
		return nil;
	
	_keyCombo = WCKeyBindingCommandPairEmptyKeyCombo();
	
	return self;
}
#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	WCKeyBindingCommandPair *copy = [super copyWithZone:zone];
	
	copy->_action = _action;
	copy->_keyCombo = _keyCombo;
	
	return copy;
}
#pragma mark NSMutableCopying
- (id)mutableCopyWithZone:(NSZone *)zone {
	WCKeyBindingCommandPair *copy = [super mutableCopyWithZone:zone];
	
	copy->_action = _action;
	copy->_keyCombo = _keyCombo;
	
	return copy;
}
#pragma mark RSPlistArchiving
- (NSDictionary *)plistRepresentation {
	NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithCapacity:0];
	
	[plist setObject:[NSNumber numberWithInteger:_keyCombo.code] forKey:WCKeyBindingCommandPairKeyCodeKey];
	
	NSMutableDictionary *modifiers = [NSMutableDictionary dictionaryWithCapacity:0];
	if ((_keyCombo.flags & NSCommandKeyMask))
		[modifiers setObject:[NSNumber numberWithBool:YES] forKey:WCKeyBindingCommandPairCommandModifierMaskKey];
	if ((_keyCombo.flags & NSAlternateKeyMask))
		[modifiers setObject:[NSNumber numberWithBool:YES] forKey:WCKeyBindingCommandPairOptionModifierMaskKey];
	if ((_keyCombo.flags & NSControlKeyMask))
		[modifiers setObject:[NSNumber numberWithBool:YES] forKey:WCKeyBindingCommandPairControlModifierMaskKey];
	if ((_keyCombo.flags & NSShiftKeyMask))
		[modifiers setObject:[NSNumber numberWithBool:YES] forKey:WCKeyBindingCommandPairShiftModifierMaskKey];
	
	if ([modifiers count])
		[plist setObject:modifiers forKey:WCKeyBindingCommandPairModifierFlagsKey];
	
	return [[plist copy] autorelease];
}
#pragma mark *** Public Methods ***
+ (WCKeyBindingCommandPair *)keyBindingCommandPairForAction:(SEL)action keyCombo:(KeyCombo)keyCombo; {
	return [[[[self class] alloc] initWithAction:action keyCombo:keyCombo] autorelease];
}
- (id)initWithAction:(SEL)action keyCombo:(KeyCombo)keyCombo; {
	if (!(self = [super initWithRepresentedObject:nil]))
		return nil;
	
	_action = action;
	_keyCombo = keyCombo;
	
	return self;
}

- (void)updateMenuItemWithCurrentKeyCode; {
	if (WCKeyBindingCommandPairIsEmptyKeyCombo(_keyCombo)) {
		[[self menuItem] setKeyEquivalent:@""];
		[[self menuItem] setKeyEquivalentModifierMask:0];
		return;
	}
	
	unichar character = [[NDKeyboardLayout keyboardLayout] characterForKeyCode:(UInt16)_keyCombo.code];
	NSString *string = [NSString stringWithFormat:@"%C",character];
	
	string = SRCharacterForKeyCodeAndCocoaFlags(_keyCombo.code, _keyCombo.flags);
	
	[[self menuItem] setKeyEquivalent:string];
	[[self menuItem] setKeyEquivalentModifierMask:_keyCombo.flags];
}
#pragma mark Properties
@dynamic name;
- (NSString *)name {
	if ([[self menuItem] isAlternate])
		return [NSString stringWithFormat:@"\t%@",[[self menuItem] title]];
	else if ([[self menuItem] menu] == [[NSApplication sharedApplication] mainMenu] ||
		[[[self menuItem] parentItem] menu] == [[NSApplication sharedApplication] mainMenu])
		return [[self menuItem] title];
	else if ([[self menuItem] menu] == [[[self menuItem] parentItem] submenu])
		return [NSString stringWithFormat:@"%@ \u2192 %@",[[[self menuItem] parentItem] title],[[self menuItem] title]];
	return [[self menuItem] title];
}
@dynamic key;
- (NSString *)key {
	if (WCKeyBindingCommandPairIsEmptyKeyCombo(_keyCombo))
		return nil;
	return SRStringForCocoaModifierFlagsAndKeyCode(_keyCombo.flags, _keyCombo.code);
}
+ (NSSet *)keyPathsForValuesAffectingKey {
	return [NSSet setWithObjects:@"keyCombo", nil];
}

@dynamic menuItem;
- (NSMenuItem *)menuItem {
	if (![self representedObject]) {
		[self setRepresentedObject:[self _menuItemMatchingSelector:_action inMenu:[[NSApplication sharedApplication] mainMenu]]];
	}
	return [self representedObject];
}
@dynamic keyCombo;
- (KeyCombo)keyCombo {
	return _keyCombo;
}
- (void)setKeyCombo:(KeyCombo)keyCombo {
	if (_keyCombo.code == keyCombo.code && _keyCombo.flags == keyCombo.flags)
		return;
	
	_keyCombo = keyCombo;
	
	[self updateMenuItemWithCurrentKeyCode];
}
@dynamic commandSet;
- (WCKeyBindingCommandSet *)commandSet {
	if ([[self parentNode] isKindOfClass:[WCKeyBindingCommandSet class]])
		return [self parentNode];
	return [[self parentNode] commandSet];
}
#pragma mark *** Private Methods ***
- (NSMenuItem *)_menuItemMatchingSelector:(SEL)action inMenu:(NSMenu *)menu; {
	NSMenuItem *retval = nil;
	for (NSMenuItem *item in [menu itemArray]) {
		if ([item action] == action) {
			retval = item;
			break;
		}
		else if ([item hasSubmenu] && (retval = [self _menuItemMatchingSelector:action inMenu:[item submenu]]))
			break;
	}
	return retval;
}

@end
