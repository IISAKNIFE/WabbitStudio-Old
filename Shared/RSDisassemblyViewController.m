//
//  RSDisassemblyViewController.m
//  WabbitStudio
//
//  Created by William Towe on 3/7/12.
//  Copyright (c) 2012 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "RSDisassemblyViewController.h"
#import "RSCalculator.h"
#import "RSTableView.h"

@interface RSDisassemblyViewController ()
- (void)_reloadDisassemblyInfos;
@end

@implementation RSDisassemblyViewController
- (void)dealloc {
#ifdef DEBUG
	NSLog(@"%@ called in %@",NSStringFromSelector(_cmd),[self className]);
#endif
	[_calculator removeObserver:self forKeyPath:@"programCounter" context:self];
	[_calculator removeObserver:self forKeyPath:@"debugging" context:self];
	
	free(_z80_info);
	[_calculator release];
	[super dealloc];
}

- (NSString *)nibName {
	return @"RSDisassemblyView";
}

- (void)loadView {
	[self _reloadDisassemblyInfos];
	
	[super loadView];
	
	[self jumpToProgramCounter:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == self) {
		if ([keyPath isEqualToString:@"programCounter"]) {
			[self _reloadDisassemblyInfos];
			[self jumpToProgramCounter:nil];
		}
		else if ([keyPath isEqualToString:@"debugging"]) {
			[[self tableView] reloadData];
		}
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

static NSString *const kAddressColumnIdentifier = @"address";
static NSString *const kDataColumnIdentifier = @"data";
static NSString *const kDisassemblyColumnIdentifier = @"disassembly";
static NSString *const kSizeColumnIdentifier = @"size";
static NSString *const kBreakpointColumnIdentifier = @"breakpoint";

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return ([[self calculator] isDebugging])?UINT16_MAX:0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:kAddressColumnIdentifier]) {
		Z80_info_t info = _z80_info[row];
		
		return [NSNumber numberWithUnsignedShort:info.waddr.addr];
	}
	else if ([[tableColumn identifier] isEqualToString:kDataColumnIdentifier]) {
		Z80_info_t info = _z80_info[row];
		uint32_t offset, total = 0;
		
		for (offset=0; offset<info.size; offset++) {
			total += mem_read(&([[self calculator] calculator]->mem_c), info.waddr.addr+offset);
			total <<= 8;
		}
		
		return [NSNumber numberWithInt:total];
	}
	else if ([[tableColumn identifier] isEqualToString:kDisassemblyColumnIdentifier]) {
		Z80_info_t info = _z80_info[row];
		
		return [NSString stringWithCString:info.expanded encoding:NSUTF8StringEncoding];
	}
	else if ([[tableColumn identifier] isEqualToString:kSizeColumnIdentifier]) {
		Z80_info_t info = _z80_info[row];
		
		return [NSNumber numberWithInt:info.size];
	}
	else if ([[tableColumn identifier] isEqualToString:kBreakpointColumnIdentifier]) {
		Z80_info_t info = _z80_info[row];
		
		if (check_break(&([[self calculator] calculator]->mem_c), info.waddr))
			return [NSImage imageNamed:NSImageNameStatusUnavailable];
		else if (check_mem_read_break(&([[self calculator] calculator]->mem_c), info.waddr))
			return [NSImage imageNamed:NSImageNameStatusAvailable];
		else if (check_mem_write_break(&([[self calculator] calculator]->mem_c), info.waddr))
			return [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
	}
	return nil;
}

- (void)jumpToMemoryAddress:(uint16_t)memoryAddress {
	NSUInteger infoIndex;
	
	for (infoIndex=0; infoIndex<UINT16_MAX; infoIndex++) {
		Z80_info_t info = _z80_info[infoIndex];
		
		if (info.waddr.addr >= memoryAddress) {
			[[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:infoIndex] byExtendingSelection:NO];
			[[self tableView] scrollRowToVisible:infoIndex];
			return;
		}
	}
	
	NSBeep();
}

- (id)initWithCalculator:(RSCalculator *)calculator; {
	if (!(self = [super initWithNibName:[self nibName] bundle:nil]))
		return nil;
	
	_calculator = [calculator retain];
	
	[calculator addObserver:self forKeyPath:@"programCounter" options:0 context:self];
	[calculator addObserver:self forKeyPath:@"debugging" options:0 context:self];
	
	return self;
}

- (IBAction)jumpToAddress:(id)sender; {
	
}
- (IBAction)jumpToProgramCounter:(id)sender; {
	[self jumpToMemoryAddress:[[self calculator] programCounter]];
}

@synthesize tableView=_tableView;

@synthesize calculator=_calculator;
@synthesize Z80_infos=_z80_info;

- (void)_reloadDisassemblyInfos; {
	if (_z80_info)
		free(_z80_info);
	
	_z80_info = calloc(sizeof(Z80_info_t), UINT16_MAX);
	
	disassemble([[self calculator] calculator], REGULAR, addr_to_waddr(&([[self calculator] calculator]->mem_c), 0), UINT16_MAX, _z80_info);
	
	[[self tableView] reloadData];
}

@end
