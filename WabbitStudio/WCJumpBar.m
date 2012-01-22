//
//  WCJumpBar.m
//  WabbitEdit
//
//  Created by William Towe on 12/25/11.
//  Copyright (c) 2011 Revolution Software. All rights reserved.
//

#import "WCJumpBar.h"
#import "WCJumpBarCell.h"

@interface WCJumpBar ()
- (void)_commonInit;
@end

@implementation WCJumpBar
#pragma mark *** Subclass Overrides ***
+ (Class)cellClass {
	return [WCJumpBarCell class];
}

- (id)initWithFrame:(NSRect)frameRect {
	if (!(self = [super initWithFrame:frameRect]))
		return nil;
	
	[self _commonInit];
	
	return self;
}
#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)coder {
	if (!(self = [super initWithCoder:coder]))
		return nil;
	
	[self _commonInit];
	
	return self;
}
#pragma mark *** Private Methods ***
- (void)_commonInit; {
	[self setRefusesFirstResponder:YES];
	[self setBackgroundColor:[NSColor clearColor]];
	[self setPathStyle:NSPathStyleStandard];
}
@end
