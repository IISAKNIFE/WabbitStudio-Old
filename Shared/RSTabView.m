//
//  RSTabView.m
//  WabbitStudio
//
//  Created by William Towe on 7/21/11.
//  Copyright 2011 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "RSTabView.h"
#import "RSEmptyContentCell.h"

@implementation RSTabView
#pragma mark *** Subclass Overrides ***
- (void)dealloc {
	[_emptyContentStringCell release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];
	
	if ([self shouldDrawEmptyContentString]) {
		[_emptyContentStringCell setEmptyContentStringStyle:[self emptyContentStringStyle]];
		[_emptyContentStringCell setStringValue:[self emptyContentString]];
		[_emptyContentStringCell drawWithFrame:[self bounds] inView:self];
	}
}
#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)decoder {
	if (!(self = [super initWithCoder:decoder]))
		return nil;
	
	_emptyContentStringCell = [[RSEmptyContentCell alloc] initTextCell:@""];
	
	return self;
}
#pragma mark *** Public Methods ***

#pragma mark Properties
@dynamic emptyContentString;
- (NSString *)emptyContentString {
	return NSLocalizedString(@"No Content", @"No Content");
}
@dynamic shouldDrawEmptyContentString;
- (BOOL)shouldDrawEmptyContentString {
	return (![self numberOfTabViewItems]);
}
@dynamic emptyContentStringStyle;
- (RSEmptyContentStringStyle)emptyContentStringStyle {
	return RSEmptyContentStringStyleNormal;
}

@end
