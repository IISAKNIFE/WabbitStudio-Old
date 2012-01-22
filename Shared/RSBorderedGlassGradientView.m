//
//  RSBorderedGlassGradientView.m
//  WabbitEdit
//
//  Created by William Towe on 12/27/11.
//  Copyright (c) 2011 Revolution Software. All rights reserved.
//

#import "RSBorderedGlassGradientView.h"

@implementation RSBorderedGlassGradientView
#pragma mark *** Subclass Overrides ***
- (BOOL)shouldDrawBottomEdge {
	return YES;
}
- (BOOL)shouldDrawTopEdge {
	return YES;
}
- (BOOL)shouldDrawLeftEdge {
	return YES;
}
- (BOOL)shouldDrawRightEdge {
	return YES;
}
@end
