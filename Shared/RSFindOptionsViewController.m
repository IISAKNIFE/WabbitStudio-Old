//
//  RSFindOptionsViewController.m
//  WabbitEdit
//
//  Created by William Towe on 12/29/11.
//  Copyright (c) 2011 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "RSFindOptionsViewController.h"

@implementation RSFindOptionsViewController
#pragma mark *** Subclass Overrides ***
- (void)dealloc {
	_delegate = nil;
	[_popover release];
	[super dealloc];
}

- (NSString *)nibName {
	return @"RSFindOptionsView";
}

- (id)init {
	if (!(self = [super initWithNibName:[self nibName] bundle:nil]))
		return nil;
	
	_popover = [[NSPopover alloc] init];
	[_popover setDelegate:self];
	[_popover setBehavior:NSPopoverBehaviorApplicationDefined];
	[_popover setAppearance:NSPopoverAppearanceHUD];
	_findFlags.wrapAround = YES;
	_findFlags.wrapAroundEnabled = YES;
	_findFlags.regexOptionsEnabled = YES;
	
	return self;
}
#pragma mark NSPopoverDelegate
- (void)popoverDidClose:(NSNotification *)notification {
	[_popover setContentViewController:nil];
	
	if ([[self delegate] respondsToSelector:@selector(findOptionsViewControllerDidClose:)])
		[[self delegate] findOptionsViewControllerDidClose:self];
}
#pragma mark *** Public Methods ***
- (void)showFindOptionsViewRelativeToRect:(NSRect)rect ofView:(NSView *)view preferredEdge:(NSRectEdge)preferredEdge {
	[_popover setContentViewController:self];
	[_popover showRelativeToRect:rect ofView:view preferredEdge:preferredEdge];
}

- (void)hideFindOptionsView; {
	[_popover performClose:nil];
}
#pragma mark Properties
@synthesize delegate=_delegate;
@dynamic findStyle;
- (RSFindOptionsFindStyle)findStyle {
	return _findStyle;
}
- (void)setFindStyle:(RSFindOptionsFindStyle)findStyle {
	if (_findStyle == findStyle)
		return;
	
	_findStyle = findStyle;
	
	if ([[self delegate] respondsToSelector:@selector(findOptionsViewControllerDidChangeFindOptions:)])
		[[self delegate] findOptionsViewControllerDidChangeFindOptions:self];
	
	if ([self regexOptionsEnabled]) {
		NSSize contentSize = [_popover contentSize];
		if ([self findStyle] == RSFindOptionsFindStyleTextual) {
			contentSize.height -= 40.0;
		}
		else {
			contentSize.height += 40.0;
		}
		[_popover setContentSize:contentSize];
	}
}
@dynamic matchStyle;
- (RSFindOptionsMatchStyle)matchStyle {
	return _matchStyle;
}
- (void)setMatchStyle:(RSFindOptionsMatchStyle)matchStyle {
	if (_matchStyle == matchStyle)
		return;
	
	_matchStyle = matchStyle;
	
	if ([[self delegate] respondsToSelector:@selector(findOptionsViewControllerDidChangeFindOptions:)])
		[[self delegate] findOptionsViewControllerDidChangeFindOptions:self];
}
@dynamic matchCase;
- (BOOL)matchCase {
	return _findFlags.matchCase;
}
- (void)setMatchCase:(BOOL)matchCase {
	_findFlags.matchCase = matchCase;
	
	if ([[self delegate] respondsToSelector:@selector(findOptionsViewControllerDidChangeFindOptions:)])
		[[self delegate] findOptionsViewControllerDidChangeFindOptions:self];
}
@dynamic anchorsMatchLines;
- (BOOL)anchorsMatchLines {
	return _findFlags.anchorsMatchLines;
}
- (void)setAnchorsMatchLines:(BOOL)anchorsMatchLines {
	_findFlags.anchorsMatchLines = anchorsMatchLines;
	
	if ([[self delegate] respondsToSelector:@selector(findOptionsViewControllerDidChangeFindOptions:)])
		[[self delegate] findOptionsViewControllerDidChangeFindOptions:self];
}
@dynamic dotMatchesNewlines;
- (BOOL)dotMatchesNewlines {
	return _findFlags.dotMatchesNewlines;
}
- (void)setDotMatchesNewlines:(BOOL)dotMatchesNewlines {
	_findFlags.dotMatchesNewlines = dotMatchesNewlines;
	
	if ([[self delegate] respondsToSelector:@selector(findOptionsViewControllerDidChangeFindOptions:)])
		[[self delegate] findOptionsViewControllerDidChangeFindOptions:self];
}
@dynamic wrapAround;
- (BOOL)wrapAround {
	return _findFlags.wrapAround;
}
- (void)setWrapAround:(BOOL)wrapAround {
	_findFlags.wrapAround = wrapAround;
}
@dynamic wrapAroundEnabled;
- (BOOL)wrapAroundEnabled {
	return _findFlags.wrapAroundEnabled;
}
- (void)setWrapAroundEnabled:(BOOL)wrapAroundEnabled {
	_findFlags.wrapAroundEnabled = wrapAroundEnabled;
}
@dynamic findOptionsVisible;
- (BOOL)areFindOptionsVisible {
	return ([_popover isShown]);
}
@dynamic regexOptionsEnabled;
- (BOOL)regexOptionsEnabled {
	return _findFlags.regexOptionsEnabled;
}
- (void)setRegexOptionsEnabled:(BOOL)regexOptionsEnabled {
	_findFlags.regexOptionsEnabled = regexOptionsEnabled;
}
@end
