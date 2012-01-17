//
//  WCOpenQuicklyWindowController.h
//  WabbitStudio
//
//  Created by William Towe on 1/17/12.
//  Copyright (c) 2012 Revolution Software. All rights reserved.
//

#import <AppKit/NSWindowController.h>
#import "WCOpenQuicklyDataSource.h"

@interface WCOpenQuicklyWindowController : NSWindowController {
	__weak id <WCOpenQuicklyDataSource> _dataSource;
	NSArray *_items;
	NSMutableArray *_matches;
	NSString *_searchString;
	NSString *_statusString;
	NSOperationQueue *_operationQueue;
	struct {
		unsigned int searching:1;
		unsigned int RESERVED:31;
	} _openQuicklyFlags;
}
@property (readwrite,assign,nonatomic) IBOutlet NSArrayController *arrayController;
@property (readwrite,assign,nonatomic) IBOutlet NSButton *openButton;
@property (readwrite,assign,nonatomic) IBOutlet NSButton *cancelButton;
@property (readwrite,assign,nonatomic) IBOutlet NSSearchField *searchField;
@property (readwrite,assign,nonatomic) IBOutlet NSTableView *tableView;

@property (readwrite,copy,nonatomic) NSString *searchString;
@property (readwrite,copy,nonatomic) NSString *statusString;
@property (readonly,copy,nonatomic) NSArray *items;
@property (readonly,nonatomic) NSArray *matches;
@property (readonly,nonatomic) NSMutableArray *mutableMatches;
@property (readwrite,assign,nonatomic,getter = isSearching) BOOL searching; 

+ (WCOpenQuicklyWindowController *)sharedWindowController;

- (void)showOpenQuicklyWindowWithDataSource:(id <WCOpenQuicklyDataSource>)dataSource;

- (IBAction)open:(id)sender;
- (IBAction)cancel:(id)sender;

- (IBAction)search:(id)sender;
@end