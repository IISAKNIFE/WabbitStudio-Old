//
//  RSFindOptionsViewController.m
//  WabbitEdit
//
//  Created by William Towe on 12/29/11.
//  Copyright (c) 2011 Revolution Software. All rights reserved.
//

#import "RSFindOptionsViewController.h"

@implementation RSFindOptionsViewController
- (void)dealloc {
	_delegate = nil;
	[_popover release];
	[super dealloc];
}

- (id)init {
	if (!(self = [super initWithNibName:@"RSFindOptionsView" bundle:nil]))
		return nil;
	
	_popover = [[NSPopover alloc] init];
	[_popover setDelegate:self];
	[_popover setBehavior:NSPopoverBehaviorApplicationDefined];
	[_popover setAppearance:NSPopoverAppearanceHUD];
	
	return self;
}

- (void)popoverDidClose:(NSNotification *)notification {
	[_popover setContentViewController:nil];
	
	if ([[self delegate] respondsToSelector:@selector(findOptionsViewControllerDidClose:)])
		[[self delegate] findOptionsViewControllerDidClose:self];
}

- (void)showFindOptionsViewRelativeToRect:(NSRect)rect ofView:(NSView *)view preferredEdge:(NSRectEdge)preferredEdge {
	[_popover setContentViewController:self];
	[_popover showRelativeToRect:rect ofView:view preferredEdge:preferredEdge];
}

- (void)hideFindOptionsView; {
	[_popover performClose:nil];
}

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
	
	NSSize contentSize = [_popover contentSize];
	if (_findStyle == RSFindOptionsFindStyleTextual) {
		contentSize.height -= 40.0;
	}
	else {
		contentSize.height += 40.0;
	}
	[_popover setContentSize:contentSize];
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
@dynamic findOptionsVisible;
- (BOOL)areFindOptionsVisible {
	return ([_popover isShown]);
}
@end