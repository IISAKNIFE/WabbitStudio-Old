//
//  WCIssueNavigatorOutlineView.m
//  WabbitStudio
//
//  Created by William Towe on 2/16/12.
//  Copyright (c) 2012 Revolution Software. All rights reserved.
//

#import "WCIssueNavigatorOutlineView.h"

@implementation WCIssueNavigatorOutlineView
- (NSString *)emptyContentString {
	return NSLocalizedString(@"No Issues", @"No Issues");
}
- (BOOL)shouldDrawEmptyContentString {
	if ([self numberOfRows] == 1) {
		if ([[self dataSource] isKindOfClass:[NSTreeController class]]) {
			return (![[[self itemAtRow:0] childNodes] count]);
		}
		else {
			return (![[self dataSource] outlineView:self numberOfChildrenOfItem:[self itemAtRow:0]]);
		}
	}
	else if (![self numberOfRows])
		return YES;
	return NO;
}
@end
