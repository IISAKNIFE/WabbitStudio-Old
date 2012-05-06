//
//  WCCalculatorWindowController.m
//  WabbitStudio
//
//  Created by William Towe on 3/15/12.
//  Copyright (c) 2012 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "WCCalculatorWindowController.h"
#import "RSCalculator.h"
#import "RSLCDView.h"
#import "RSLCDViewManager.h"
#import "RSSkinView.h"
#import "RSDefines.h"

@interface WCCalculatorWindowController ()
@property (readwrite,assign,nonatomic) RSLCDView *LCDView;
@property (readwrite,copy,nonatomic) NSString *statusString;
@end

@implementation WCCalculatorWindowController
#pragma mark *** Subclass Overrides ***
- (void)dealloc {
#ifdef DEBUG
	NSLog(@"%@ called in %@",NSStringFromSelector(_cmd),[self className]);
#endif
	_LCDView = nil;
	[_statusString release];
	[_calculator release];
	[super dealloc];
}

- (NSString *)windowNibName {
	return @"WCCalculatorWindow";
}

- (void)windowDidLoad {
	[super windowDidLoad];
	
	NSRect windowFrame = [[self window] frame];
	NSView *contentView = [[self window] contentView];
	NSRect contentViewFrame = [contentView frame];
	RSCalculator *calculator = [self calculator];
	NSSize skinSize = [[calculator skinImage] size];
	RSSkinView *skinView = [[[RSSkinView alloc] initWithFrame:NSMakeRect(contentViewFrame.origin.x, contentViewFrame.origin.y, skinSize.width, skinSize.height) calculator:calculator] autorelease];
	NSRect newWindowFrame = [[self window] frameRectForContentRect:NSMakeRect(NSMinX(windowFrame), NSMinY(windowFrame)+(NSHeight(contentViewFrame)-skinSize.height), skinSize.width, skinSize.height+[[self window] contentBorderThicknessForEdge:NSMinYEdge])];
	
	[[self window] setFrame:newWindowFrame display:YES];
	
	[contentView addSubview:skinView];
	
	NSRect skinViewFrame = [skinView frame];
	
	skinViewFrame.origin.y += [[self window] contentBorderThicknessForEdge:NSMinYEdge];
	
	[skinView setFrame:skinViewFrame];
	
	RSLCDView *lcdView = [[[RSLCDView alloc] initWithFrame:NSMakeRect(0, 0, 192, 128) calculator:calculator] autorelease];
	
	[skinView addSubview:lcdView];
	
	NSBitmapImageRep *bitmap = (NSBitmapImageRep *)[[calculator keymapImage] bestRepresentationForRect:NSZeroRect context:nil hints:nil];
	
	NSSize size = [bitmap size];
	NSUInteger width = size.width, height = size.height;
	NSUInteger i, j;
	NSUInteger pixels[4];
	NSPoint point = NSZeroPoint;
	NSPoint endPoint = NSZeroPoint;
	
	for (i = 0; i < width; i++) {
		for (j = 0; j < height; j++) {
			[bitmap getPixel:pixels atX:i y:j];
			
			// red marks the start of the area for the lcd
			if (pixels[0] == 255 && pixels[1] == 0 && pixels[2] == 0) {
				point.x = i;
				point.y = j;
				
				while (pixels[0] == 255 && pixels[1] == 0 && pixels[2] == 0)
					[bitmap getPixel:pixels atX:i++ y:j];
				
				endPoint.x = i;
				i = point.x;
				
				[bitmap getPixel:pixels atX:i y:j];
				
				while (pixels[0] == 255 && pixels[1] == 0 && pixels[2] == 0)
					[bitmap getPixel:pixels atX:i y:j++];
				
				endPoint.y = j;
				break;
			}
		}
		
		if (!NSEqualPoints(point, NSZeroPoint))
			break;
	}
	
	[lcdView setFrame:NSMakeRect(point.x, point.y, endPoint.x-point.x, endPoint.y-point.y)];
	
	[[RSLCDViewManager sharedManager] addLCDView:lcdView];
	
	[self setLCDView:lcdView];
	
	_FPSTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_FPSTimerCallback:) userInfo:nil repeats:YES];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
	return [NSString stringWithFormat:NSLocalizedString(@"%@ - Run", @"calculator window title format string"),displayName];
}
#pragma mark NSWindowDelegate
- (BOOL)windowShouldClose:(id)sender {
	NSString *message = NSLocalizedString(@"End Debug Session?", @"End Debug Session");
	NSString *informative = NSLocalizedString(@"Do you want to end the current debug session?", @"Do you want to end the current debug session?");
	NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:NSLocalizedString(@"End Debug Session", @"End Debug Session") alternateButton:LOCALIZED_STRING_CANCEL otherButton:nil informativeTextWithFormat:informative];
	
	NSInteger result = [alert runModal];
	
	return (result == NSAlertDefaultReturn);
}

- (void)windowWillClose:(NSNotification *)notification {
	[_FPSTimer invalidate];
	_FPSTimer = nil;
	
	[[RSLCDViewManager sharedManager] removeLCDView:[self LCDView]];
}
#pragma mark *** Public Methods ***
- (id)initWithCalculator:(RSCalculator *)calculator; {
	if (!(self = [super initWithWindowNibName:[self windowNibName]]))
		return nil;
	
	_calculator = [calculator retain];
	_statusString = [[NSString stringWithFormat:NSLocalizedString(@"%@, FPS: 0.00", @"initial calculator status format string"),[calculator modelString]] copy];
	
	return self;
}
#pragma mark Properties
@synthesize calculator=_calculator;
@synthesize LCDView=_LCDView;
@synthesize statusString=_statusString;
#pragma mark *** Private Methods ***

#pragma mark Callbacks
- (void)_FPSTimerCallback:(NSTimer *)timer {
	RSCalculator *calculator = [self calculator];
	
	if ([calculator isActive] && [calculator isRunning])
		[self setStatusString:[NSString stringWithFormat:NSLocalizedString(@"%@, FPS: %.2f", @"calculator status format string"),[calculator modelString],[calculator calculator]->cpu.pio.lcd->ufps]];
}

@end
