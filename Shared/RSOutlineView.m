//
//  RSOutlineView.m
//  WabbitStudio
//
//  Created by William Towe on 7/20/11.
//  Copyright 2011 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "RSOutlineView.h"
#import "RSEmptyContentCell.h"
#import "NSOutlineView+RSExtensions.h"
#import "NSArray+WCExtensions.h"
#import "NSEvent+RSExtensions.h"
#import "RSDefines.h"

@implementation RSOutlineView
#pragma mark *** Subclass Overrides ***
- (void)dealloc {
	[_emptyContentStringCell release];
    [super dealloc];
}

- (void)keyDown:(NSEvent *)theEvent {
	switch ([theEvent keyCode]) {
		case KEY_CODE_DELETE:
		case KEY_CODE_DELETE_FORWARD:
			if ([[self delegate] respondsToSelector:@selector(handleDeletePressedForOutlineView:)]) {
				[(id<RSOutlineViewDelegate>)[self delegate] handleDeletePressedForOutlineView:self];
				return;
			}
			break;
		case KEY_CODE_RETURN:
		case KEY_CODE_ENTER:
			if ([[self delegate] respondsToSelector:@selector(handleReturnPressedForOutlineView:)]) {
				[(id<RSOutlineViewDelegate>)[self delegate] handleReturnPressedForOutlineView:self];
				return;
			}
			break;
		case KEY_CODE_SPACE:
			if ([[self delegate] respondsToSelector:@selector(handleSpacePressedForOutlineView:)]) {
				[(id<RSOutlineViewDelegate>)[self delegate] handleSpacePressedForOutlineView:self];
				return;
			}
			break;
		default:
			break;
	}
	[super keyDown:theEvent];
}

// expand/collapse items that have children on a double click, expand/collapse items along with their children on option + double click
- (void)mouseDown:(NSEvent *)theEvent {
	if ([theEvent type] == NSLeftMouseDown &&
		[theEvent clickCount] == 2) {
		if ([[self dataSource] isKindOfClass:[NSTreeController class]]) {
			NSTreeNode *selectedNode = [[(NSTreeController *)[self dataSource] selectedNodes] firstObject];
			if ([[selectedNode childNodes] count] >= 1) {
				if ([self isItemExpanded:selectedNode]) {
					if ([theEvent isOnlyOptionKeyPressed])
						[self collapseItem:selectedNode collapseChildren:YES];
					else
						[self collapseItem:selectedNode collapseChildren:NO];
				}
				else {
					if ([theEvent isOnlyOptionKeyPressed])
						[self expandItem:selectedNode expandChildren:YES];
					else
						[self expandItem:selectedNode expandChildren:NO];
				}
				return;
			}
		}
		else {
			id selectedItem = [self selectedItem];
			if ([[self dataSource] outlineView:self numberOfChildrenOfItem:selectedItem] >= 1) {
				if ([self isItemExpanded:selectedItem]) {
					if ([theEvent isOnlyOptionKeyPressed])
						[self collapseItem:selectedItem collapseChildren:YES];
					else
						[self collapseItem:selectedItem collapseChildren:NO];
				}
				else {
					if ([theEvent isOnlyOptionKeyPressed])
						[self expandItem:selectedItem expandChildren:YES];
					else
						[self expandItem:selectedItem expandChildren:NO];
				}
				return;
			}
		}
	}
	[super mouseDown:theEvent];
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect {
	[super drawBackgroundInClipRect:clipRect];
	
	if ([self shouldDrawEmptyContentString] &&
		[[self emptyContentString] length]) {
		
		[_emptyContentStringCell setEmptyContentStringStyle:[self emptyContentStringStyle]];
		[_emptyContentStringCell setStringValue:[self emptyContentString]];
		[_emptyContentStringCell drawWithFrame:[self bounds] inView:self];
	}
}

- (void)drawGridInClipRect:(NSRect)clipRect {
	if (![self shouldDrawEmptyContentString])
		[super drawGridInClipRect:clipRect];
}

#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)decoder {
	if (!(self = [super initWithCoder:decoder]))
		return nil;
	
	_emptyContentStringCell = [[RSEmptyContentCell alloc] initTextCell:@""];
	
	return self;
}
#pragma mark NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
	if ([anItem action] == @selector(delete:))
		return [[self delegate] respondsToSelector:@selector(handleDeletePressedForOutlineView:)];
	return [super validateUserInterfaceItem:anItem];
}
#pragma mark *** Public Methods ***
- (IBAction)delete:(id)sender; {
	if (![[self delegate] respondsToSelector:@selector(handleDeletePressedForOutlineView:)]) {
		NSBeep();
		return;
	}
	
	[(id<RSOutlineViewDelegate>)[self delegate] handleDeletePressedForOutlineView:self];
}
#pragma mark Properties
@dynamic emptyContentString;
- (NSString *)emptyContentString {
	return NSLocalizedString(@"No Content", @"No Content");
}
@dynamic shouldDrawEmptyContentString;
- (BOOL)shouldDrawEmptyContentString {
	return (![self numberOfRows]);
}
@dynamic emptyContentStringStyle;
- (RSEmptyContentStringStyle)emptyContentStringStyle {
	return ([self selectionHighlightStyle] == NSTableViewSelectionHighlightStyleSourceList)?RSEmptyContentStringStyleSourceList:RSEmptyContentStringStyleNormal;
}
@dynamic delegate;
- (id<RSOutlineViewDelegate>)delegate {
	return (id <RSOutlineViewDelegate>)[super delegate];
}
- (void)setDelegate:(id<RSOutlineViewDelegate>)delegate {
	[super setDelegate:delegate];
}

@end
