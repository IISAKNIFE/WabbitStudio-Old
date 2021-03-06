//
//  WCIssueNavigatorViewController.m
//  WabbitStudio
//
//  Created by William Towe on 2/15/12.
//  Copyright (c) 2012 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "WCIssueNavigatorViewController.h"
#import "WCProjectDocument.h"
#import "WCIssueContainer.h"
#import "WCBuildIssue.h"
#import "WCBuildIssueContainer.h"
#import "WCProjectContainer.h"
#import "WCProject.h"
#import "NSTreeController+RSExtensions.h"
#import "WCBuildController.h"
#import "WCProjectWindowController.h"
#import "RSNavigatorControl.h"
#import "WCSourceFileSeparateWindowController.h"
#import "WCSourceTextViewController.h"
#import "WCSourceTextView.h"
#import "WCTabViewController.h"
#import "RSOutlineView.h"
#import "NSEvent+RSExtensions.h"
#import "WCFilesViewController.h"
#import "NSUserDefaults+RSExtensions.h"

@interface WCIssueNavigatorViewController ()
@property (readwrite,retain,nonatomic) WCIssueContainer *filteredIssueContainer;

- (void)_updateIssues;
- (void)_openIssuesForObjects:(NSArray *)objects;
@end

@implementation WCIssueNavigatorViewController
#pragma mark *** Subclass Overrides ***
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_projectDocument = nil;
	[_filteredIssueContainer release];
	[_issueContainer release];
	[super dealloc];
}

- (NSString *)nibName {
	return @"WCIssueNavigatorView";
}

- (void)loadView {
	[super loadView];
	
	[[[self searchField] cell] setPlaceholderString:NSLocalizedString(@"Filter Issues", @"Filter Issues")];
	[[[[self searchField] cell] searchButtonCell] setImage:[NSImage imageNamed:@"Filter"]];
	[[[[self searchField] cell] searchButtonCell] setAlternateImage:nil];
	
	[[self outlineView] setTarget:self];
	[[self outlineView] setDoubleAction:@selector(_outlineViewDoubleClick:)];
	[[self outlineView] setAction:@selector(_outlineViewSingleClick:)];
	
	[self _updateIssues];
}
#pragma mark NSOutlineViewDelegate
static NSString *const kProjectCellIdentifier = @"ProjectCell";
static NSString *const kMainCellIdentifier = @"MainCell";

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	id object = [[item representedObject] representedObject];
	
	if ([object isKindOfClass:[WCFile class]])
		return [outlineView makeViewWithIdentifier:kProjectCellIdentifier owner:self];
	return [outlineView makeViewWithIdentifier:kMainCellIdentifier owner:self];
}

static const CGFloat kProjectCellHeight = 30.0;
static const CGFloat kMainCellHeight = 20.0;
- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
	id object = [[item representedObject] representedObject];
	
	if ([object isKindOfClass:[WCFile class]])
		return kProjectCellHeight;
	return kMainCellHeight;
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
	if ([rowView respondsToSelector:@selector(setOutlineView:)])
		[(id)rowView setOutlineView:outlineView];
}
- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
	if ([rowView respondsToSelector:@selector(setOutlineView:)])
		[(id)rowView setOutlineView:nil];
}
#pragma mark RSOutlineViewDelegate
- (void)handleReturnPressedForOutlineView:(RSOutlineView *)outlineView {
	if ([[NSUserDefaults standardUserDefaults] intForKey:WCFilesOpenFilesWithKey] == WCFilesOpenFilesWithDoubleClick)
		[[self outlineView] sendAction:[[self outlineView] doubleAction] to:[[self outlineView] target]];
	else
		[[self outlineView] sendAction:[[self outlineView] action] to:[[self outlineView] target]];
}

#pragma mark WCNavigatorModule
- (NSArray *)selectedObjects {
	NSMutableArray *retval = [NSMutableArray arrayWithCapacity:0];
	NSInteger clickedRow = [[self outlineView] clickedRow];
	if (clickedRow == -1 || [[[self outlineView] selectedRowIndexes] containsIndex:clickedRow])
		[retval addObjectsFromArray:[[self treeController] selectedRepresentedObjects]];
	else
		[retval addObject:[[[self outlineView] itemAtRow:clickedRow] representedObject]];
	
	return [[retval copy] autorelease];
}
- (void)setSelectedObjects:(NSArray *)objects {
	[[self treeController] setSelectedRepresentedObjects:objects];
}

- (NSArray *)selectedModelObjects {
	return [[self selectedObjects] valueForKey:@"representedObject"];
}
- (void)setSelectedModelObjects:(NSArray *)modelObjects {
	[[self treeController] setSelectedModelObjects:modelObjects];
}

- (NSArray *)selectedObjectsAndClickedObject:(id *)clickedObject; {
	NSInteger clickedRow = [[self outlineView] clickedRow];
	
	if (clickedRow != -1 && clickedObject)
		*clickedObject = [[[self outlineView] itemAtRow:clickedRow] representedObject];
	
	return [self selectedObjects];
}

- (NSArray *)selectedModelObjectsAndClickedObject:(id *)clickedObject; {
	NSInteger clickedRow = [[self outlineView] clickedRow];
	
	if (clickedRow != -1 && clickedObject)
		*clickedObject = [[[[self outlineView] itemAtRow:clickedRow] representedObject] representedObject];
	
	return [self selectedModelObjects];
}

- (NSResponder *)initialFirstResponder; {
	return [self outlineView];
}
#pragma mark *** Public Methods ***
- (id)initWithProjectDocument:(WCProjectDocument *)projectDocument; {
	if (!(self = [super initWithNibName:[self nibName] bundle:nil]))
		return nil;
	
	_projectDocument = projectDocument;
	_issueContainer = [[WCIssueContainer alloc] initWithFile:[[projectDocument projectContainer] representedObject]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_buildControllerDidFinishBuilding:) name:WCBuildControllerDidFinishBuildingNotification object:[projectDocument buildController]];
	
	return self;
}
#pragma mark Properties
@synthesize outlineView=_outlineView;
@synthesize treeController=_treeController;
@synthesize searchField=_searchField;

@synthesize projectDocument=_projectDocument;
@synthesize issueContainer=_issueContainer;
@synthesize filteredIssueContainer=_filteredIssueContainer;

#pragma mark *** Private Methods ***
- (void)_updateIssues {
	[[[self issueContainer] mutableChildNodes] removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[[self issueContainer] childNodes] count])]];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextStorageDidProcessEditingNotification object:nil];
	
	WCBuildController *buildController = [[self projectDocument] buildController];
	
	[[self issueContainer] willChangeValueForKey:@"statusString"];
	
	for (WCFile *file in [buildController filesWithBuildIssuesSortedByName]) {
		WCIssueContainer *issueContainer = [WCIssueContainer issueContainerWithFile:file];
		
		for (WCBuildIssue *buildIssue in [[buildController filesToBuildIssuesSortedByLocation] objectForKey:file]) {
			WCBuildIssueContainer *buildIssueContainer = [WCBuildIssueContainer buildIssueContainerWithBuildIssue:buildIssue];
			
			[[issueContainer mutableChildNodes] addObject:buildIssueContainer];
		}
		
		[[[self issueContainer] mutableChildNodes] addObject:issueContainer];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_textStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:[[[[self projectDocument] filesToSourceFileDocuments] objectForKey:file] textStorage]];
	}
	
	[[self issueContainer] didChangeValueForKey:@"statusString"];
	
	[[self outlineView] expandItem:nil expandChildren:YES];
	
	[[[[self projectDocument] projectWindowController] navigatorControl] setSelectedItemIdentifier:@"issue"];
}
- (void)_openIssuesForObjects:(NSArray *)objects; {
	BOOL isOnlyOptionKeyPressed = [NSEvent isOnlyOptionKeyPressed];
	
	for (id container in objects) {
		id result = [container representedObject];
		
		if (![result isKindOfClass:[WCBuildIssue class]])
			continue;
		
		if (isOnlyOptionKeyPressed) {
			WCFile *file = [[container parentNode] representedObject];
			WCSourceFileSeparateWindowController *windowController = [[self projectDocument] openSeparateEditorForFile:file];
			WCSourceTextViewController *stvController = [[[[[windowController tabViewController] sourceFileDocumentsToSourceTextViewControllers] objectEnumerator] allObjects] lastObject];
			
			[[stvController textView] setSelectedRange:[result range]];
			[[stvController textView] scrollRangeToVisible:[result range]];
		}
		else {
			WCFile *file = [[container parentNode] representedObject];
			WCSourceTextViewController *stvController = [[self projectDocument] openTabForFile:file tabViewContext:nil];
			
			[[stvController textView] setSelectedRange:[result range]];
			[[stvController textView] scrollRangeToVisible:[result range]];
		}
	}
}
#pragma mark IBActions
- (IBAction)_outlineViewSingleClick:(id)sender; {
	if ([[NSUserDefaults standardUserDefaults] intForKey:WCFilesOpenFilesWithKey] != WCFilesOpenFilesWithSingleClick)
		return;
	
	[self _openIssuesForObjects:[self selectedObjects]];
}
- (IBAction)_outlineViewDoubleClick:(id)sender; {
	if ([[NSUserDefaults standardUserDefaults] intForKey:WCFilesOpenFilesWithKey] != WCFilesOpenFilesWithDoubleClick)
		return;
	
	[self _openIssuesForObjects:[self selectedObjects]];
}

#pragma mark Notifications
- (void)_buildControllerDidFinishBuilding:(NSNotification *)note {	
	[self _updateIssues];
}
- (void)_textStorageDidProcessEditing:(NSNotification *)note {
	NSTextStorage *textStorage = [note object];
	
	if (([textStorage editedMask] & NSTextStorageEditedCharacters) == 0)
		return;
	
	for (WCIssueContainer *container in [[self issueContainer] childNodes]) {
		WCSourceFileDocument *sfDocument = [[[self projectDocument] filesToSourceFileDocuments] objectForKey:[container representedObject]];
		
		if (textStorage == [sfDocument textStorage]) {
			NSMutableArray *issuesToRemove = [NSMutableArray arrayWithCapacity:0];
			NSRange editedRange = [textStorage editedRange];
			NSInteger changeInLength = [textStorage changeInLength];
			
			for (WCBuildIssueContainer *buildIssueContainer in [container childNodes]) {
				NSRange resultRange = [[buildIssueContainer representedObject] range];
				
				if (changeInLength < -1 &&
					NSLocationInRange(resultRange.location, NSMakeRange(editedRange.location, ABS(changeInLength))))
					[issuesToRemove addObject:buildIssueContainer];
				else if (NSMaxRange(editedRange) < resultRange.location) {
					resultRange.location += changeInLength;
					[[buildIssueContainer representedObject] setRange:resultRange];
				}
			}
			
			if ([issuesToRemove count]) {
				[container willChangeValueForKey:@"statusString"];
				[[container mutableChildNodes] removeObjectsInArray:issuesToRemove];
				[container didChangeValueForKey:@"statusString"];
			}
			
			break;
		}
	}
}
@end
