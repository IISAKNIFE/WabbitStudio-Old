//
//  RSStackViewController.m
//  WabbitStudio
//
//  Created by William Towe on 3/13/12.
//  Copyright (c) 2012 Revolution Software. All rights reserved.
//

#import "RSStackViewController.h"
#import "RSCalculator.h"
#import "RSHexadecimalFormatter.h"

@interface RSStackViewController ()
@property (readwrite,assign,nonatomic) NSUInteger rowCount;

- (void)_updateNumberOfRows;
@end

@implementation RSStackViewController

- (void)dealloc {
#ifdef DEBUG
	NSLog(@"%@ called in %@",NSStringFromSelector(_cmd),[self className]);
#endif
	[_calculator removeObserver:self forKeyPath:@"debugging" context:self];
	[_calculator removeObserver:self forKeyPath:@"stackPointer" context:self];
	[_calculator release];
	[super dealloc];
}

- (NSString *)nibName {
	return @"RSStackView";
}

- (void)loadView {
	[self _updateNumberOfRows];
	
	[super loadView];
	
	[[self stackAddressFormatter] setHexadecimalFormat:RSHexadecimalFormatUnsignedShort];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == self) {
		if ([keyPath isEqualToString:@"stackPointer"])
			[self _updateNumberOfRows];
		else if ([keyPath isEqualToString:@"debugging"])
			[self _updateNumberOfRows];
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self rowCount];
}

static NSString *const kAddressColumnIdentifier = @"address";
static NSString *const kStackColumnIdentifier = @"stack";

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	uint16_t stackPointer = [[self calculator] stackPointer];
	uint16_t address = stackPointer + row;
	
	if ([[tableColumn identifier] isEqualToString:kAddressColumnIdentifier])
		return [NSNumber numberWithUnsignedShort:address];
	
	waddr_t wideAddress = addr_to_waddr(&([[self calculator] calculator]->mem_c), address);
	uint16_t data = wmem_read16(&([[self calculator] calculator]->mem_c), wideAddress);
	
	return [NSNumber numberWithUnsignedShort:data];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	uint16_t stackPointer = [[self calculator] stackPointer];
	uint16_t address = stackPointer + row;
	uint16_t data = [object unsignedShortValue];
	waddr_t wideAddress = addr_to_waddr(&([[self calculator] calculator]->mem_c), address);
	
	mem_write(&([[self calculator] calculator]->mem_c), wideAddress.addr, (data & 0xFF));
	mem_write(&([[self calculator] calculator]->mem_c), ++(wideAddress.addr), ((data >> 8) & 0xFF));
}

- (id)initWithCalculator:(RSCalculator *)calculator; {
	if (!(self = [super initWithNibName:[self nibName] bundle:nil]))
		return nil;
	
	_calculator = [calculator retain];
	
	[_calculator addObserver:self forKeyPath:@"stackPointer" options:0 context:self];
	[_calculator addObserver:self forKeyPath:@"debugging" options:0 context:self];
	
	return self;
}

@synthesize tableView=_tableView;
@synthesize stackAddressFormatter=_stackAddressFormatter;

@synthesize calculator=_calculator;
@synthesize rowCount=_rowCount;
- (void)setRowCount:(NSUInteger)rowCount {
	_rowCount = rowCount;
	
	[[self tableView] reloadData];
}

- (void)_updateNumberOfRows; {
	NSUInteger numberOfRows = 0;
	
	if ([[self calculator] isDebugging]) {
		uint16_t stackPointer = [[self calculator] stackPointer];
		
		while (stackPointer++ < UINT16_MAX)
			numberOfRows++;
		
		[self setRowCount:++numberOfRows];
	}
	else
		[self setRowCount:numberOfRows];
}

@end
