//
//  WCEditBuildTargetWindowController.m
//  WabbitStudio
//
//  Created by William Towe on 2/12/12.
//  Copyright (c) 2012 Revolution Software. All rights reserved.
//

#import "WCEditBuildTargetWindowController.h"
#import "WCBuildTarget.h"
#import "WCProjectDocument.h"
#import "WCBuildDefine.h"
#import "WCAlertsViewController.h"
#import "RSDefines.h"
#import "NSAlert-OAExtensions.h"
#import "WCEditBuildTargetChooseInputFileViewController.h"

@implementation WCEditBuildTargetWindowController
- (void)dealloc {
#ifdef DEBUG
	NSLog(@"%@ called in %@",NSStringFromSelector(_cmd),[self className]);
#endif
	[_buildTarget release];
	[super dealloc];
}

- (NSString *)windowNibName {
	return @"WCEditBuildTargetWindow";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
	[[self definesTableView] setTarget:self];
	[[self definesTableView] setDoubleAction:@selector(_definesTableViewDoubleClick:)];
}

#pragma mark NSControlTextEditingDelegate
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
	if (control == [self nameTextField])
		return ([[fieldEditor string] length]);
	return YES;
}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
	if (control == [self definesTableView]) {
		if (commandSelector == @selector(cancelOperation:)) {
			if ([[self definesTableView] editedRow] != -1)
				return [control abortEditing];
		}
	}
	return NO;
}
#pragma mark NSTableViewDelegate

#pragma mark RSTableViewDelegate
- (void)handleDeletePressedForTableView:(RSTableView *)tableView {
	if (tableView == (RSTableView *)[self definesTableView])
		[self deleteBuildDefine:nil];
}
- (void)handleReturnPressedForTableView:(RSTableView *)tableView {
	if (tableView == (RSTableView *)[self definesTableView])
		[self newBuildDefine:nil];
}

+ (id)editBuildTargetWindowControllerWithBuildTarget:(WCBuildTarget *)buildTarget; {
	return [[[[self class] alloc] initWithBuildTarget:buildTarget] autorelease];
}
- (id)initWithBuildTarget:(WCBuildTarget *)buildTarget; {
	if (!(self = [super initWithWindowNibName:[self windowNibName]]))
		return nil;
	
	_buildTarget = [buildTarget retain];
	
	return self;
}

- (void)showEditBuildTargetWindow; {
	[self retain];
	
	[[NSApplication sharedApplication] beginSheet:[self window] modalForWindow:[[[self buildTarget] projectDocument] windowForSheet] modalDelegate:self didEndSelector:@selector(_sheetDidEnd:code:context:) contextInfo:NULL];
}

- (IBAction)ok:(id)sender; {
	[[NSApplication sharedApplication] endSheet:[self window] returnCode:NSCancelButton];
}
- (IBAction)manageBuildTargets:(id)sender; {
	[[NSApplication sharedApplication] endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)newBuildDefine:(id)sender; {
	WCBuildDefine *newBuildDefine = [WCBuildDefine buildDefine];
	NSUInteger insertIndex = [[[self definesArrayController] selectionIndexes] firstIndex];
	
	if (insertIndex == NSNotFound)
		insertIndex = [[[self definesArrayController] arrangedObjects] count];
	
	[[self definesArrayController] insertObject:newBuildDefine atArrangedObjectIndex:insertIndex];
	
	[[self definesTableView] editColumn:0 row:insertIndex withEvent:nil select:YES];
}
- (IBAction)deleteBuildDefine:(id)sender; {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:WCAlertsWarnBeforeDeletingBuildDefinesKey]) {
		NSString *message;
		if ([[[self definesArrayController] selectionIndexes] count] == 1)
			message = [NSString stringWithFormat:NSLocalizedString(@"Delete the Build Define \"%@\"?", @"delete build define alert single define message format string"),[(WCBuildDefine *)[[[self definesArrayController] selectedObjects] lastObject] name]];
		else
			message = [NSString stringWithFormat:NSLocalizedString(@"Delete %lu Build Defines?", @"delete build define alert multiple defines message format string"),[[[self definesArrayController] selectionIndexes] count]];
		
		NSAlert *deleteBuildDefinesAlert = [NSAlert alertWithMessageText:message defaultButton:LOCALIZED_STRING_DELETE alternateButton:LOCALIZED_STRING_CANCEL otherButton:nil informativeTextWithFormat:NSLocalizedString(@"This operation cannot be undone.", @"This operation cannot be undone.")];
		
		[deleteBuildDefinesAlert setShowsSuppressionButton:YES];
		
		[[deleteBuildDefinesAlert suppressionButton] bind:NSValueBinding toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:WCAlertsWarnBeforeDeletingBuildDefinesKey] options:nil];
		
		[deleteBuildDefinesAlert beginSheetModalForWindow:[self window] completionHandler:^(NSAlert *alert, NSInteger returnCode) {
			[[alert suppressionButton] unbind:NSValueBinding];
			[[alert window] orderOut:nil];
			if (returnCode == NSAlertAlternateReturn)
				return;
			
			[[self definesArrayController] removeObjectsAtArrangedObjectIndexes:[[self definesArrayController] selectionIndexes]];
		}];
	}
	else
		[[self definesArrayController] removeObjectsAtArrangedObjectIndexes:[[self definesArrayController] selectionIndexes]];
}

- (IBAction)chooseInputFile:(id)sender; {
	WCEditBuildTargetChooseInputFileViewController *viewController = [WCEditBuildTargetChooseInputFileViewController editBuildTargetChooseInputFileViewControllerWithEditBuildTargetWindowController:self];
	
	[viewController showChooseInputFileViewRelativeToRect:[[self chooseInputFileButton] bounds] ofView:[self chooseInputFileButton] preferredEdge:NSMinYEdge];
}

@synthesize nameTextField=_nameTextField;
@synthesize definesArrayController=_definesArrayController;
@synthesize definesTableView=_definesTableView;
@synthesize chooseInputFileButton=_chooseInputFileButton;

@synthesize buildTarget=_buildTarget;

- (void)_sheetDidEnd:(NSWindow *)sheet code:(NSInteger)code context:(void *)context {
	[self autorelease];
	[sheet orderOut:nil];
	
	if (code == NSCancelButton)
		return;
	
	[[[self buildTarget] projectDocument] manageBuildTargets:nil];
}

- (IBAction)_definesTableViewDoubleClick:(id)sender; {
	NSInteger clickedRow = [[self definesTableView] clickedRow];
	NSInteger clickedColumn = [[self definesTableView] clickedColumn];
	
	if (clickedRow == -1 || clickedColumn == -1) {
		[self newBuildDefine:nil];
		return;
	}
	
	[[self definesTableView] editColumn:clickedColumn row:clickedRow withEvent:nil select:YES];
}

@end
