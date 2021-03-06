//
//  WCEditBuildTargetWindowController.m
//  WabbitStudio
//
//  Created by William Towe on 2/12/12.
//  Copyright (c) 2012 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "WCEditBuildTargetWindowController.h"
#import "WCBuildTarget.h"
#import "WCProjectDocument.h"
#import "WCBuildDefine.h"
#import "WCAlertsViewController.h"
#import "RSDefines.h"
#import "NSAlert-OAExtensions.h"
#import "NSURL+RSExtensions.h"
#import "WCDocumentController.h"
#import "WCEditBuildTargetChooseInputFileAccessoryViewController.h"
#import "WCBuildInclude.h"

@interface WCEditBuildTargetWindowController ()
@property (readwrite,retain,nonatomic) WCEditBuildTargetChooseInputFileAccessoryViewController *chooseInputFileAccessoryViewController;
@end

@implementation WCEditBuildTargetWindowController
#pragma mark *** Subclass Overrides ***
- (void)dealloc {
#ifdef DEBUG
	NSLog(@"%@ called in %@",NSStringFromSelector(_cmd),[self className]);
#endif
	[_chooseInputFileAccessoryViewController release];
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
	
	[[[self definesSearchField] cell] setPlaceholderString:NSLocalizedString(@"Filter Defines", @"Filter Defines")];
	[[[[self definesSearchField] cell] searchButtonCell] setImage:[NSImage imageNamed:@"Filter"]];
	[[[[self definesSearchField] cell] searchButtonCell] setAlternateImage:nil];
	
	[[[self includesSearchField] cell] setPlaceholderString:NSLocalizedString(@"Filter Includes", @"Filter Includes")];
	[[[[self includesSearchField] cell] searchButtonCell] setImage:[NSImage imageNamed:@"Filter"]];
	[[[[self includesSearchField] cell] searchButtonCell] setAlternateImage:nil];
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

#pragma mark RSTableViewDelegate
- (void)handleDeletePressedForTableView:(RSTableView *)tableView {
	if (tableView == (RSTableView *)[self definesTableView])
		[self deleteBuildDefine:nil];
	else if (tableView == (RSTableView *)[self includesTableView])
		[self deleteBuildInclude:nil];
}
- (void)handleReturnPressedForTableView:(RSTableView *)tableView {
	if (tableView == (RSTableView *)[self definesTableView])
		[self newBuildDefine:nil];
	else if (tableView == (RSTableView *)[self includesTableView])
		[self newBuildInclude:nil];
}
#pragma mark NSKeyValueObserving
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == self) {
        if ([keyPath isEqualToString:@"name"] ||
            [keyPath isEqualToString:@"outputType"] ||
            [keyPath isEqualToString:@"inputFile"] ||
            [keyPath isEqualToString:@"active"] ||
            [keyPath isEqualToString:@"generateCodeListing"] ||
            [keyPath isEqualToString:@"generateLabelFile"] ||
            [keyPath isEqualToString:@"symbolsAreCaseSensitive"]) {
            
            [self.buildTarget.projectDocument updateChangeCount:NSChangeDone];
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark *** Public Methods ***
+ (id)editBuildTargetWindowControllerWithBuildTarget:(WCBuildTarget *)buildTarget; {
	return [[[[self class] alloc] initWithBuildTarget:buildTarget] autorelease];
}
- (id)initWithBuildTarget:(WCBuildTarget *)buildTarget; {
	if (!(self = [super initWithWindowNibName:[self windowNibName]]))
		return nil;
	
	_buildTarget = [buildTarget retain];
    
    [buildTarget addObserver:self forKeyPath:@"name" options:0 context:self];
    [buildTarget addObserver:self forKeyPath:@"outputType" options:0 context:self];
    [buildTarget addObserver:self forKeyPath:@"inputFile" options:0 context:self];
    [buildTarget addObserver:self forKeyPath:@"active" options:0 context:self];
    [buildTarget addObserver:self forKeyPath:@"generateCodeListing" options:0 context:self];
    [buildTarget addObserver:self forKeyPath:@"generateLabelFile" options:0 context:self];
    [buildTarget addObserver:self forKeyPath:@"symbolsAreCaseSensitive" options:0 context:self];
	
	return self;
}

- (void)showEditBuildTargetWindow; {
	[self retain];
	
	[[NSApplication sharedApplication] beginSheet:[self window] modalForWindow:[[[self buildTarget] projectDocument] windowForSheet] modalDelegate:self didEndSelector:@selector(_sheetDidEnd:code:context:) contextInfo:NULL];
}
#pragma mark IBActions
- (IBAction)ok:(id)sender; {
	[[NSApplication sharedApplication] endSheet:[self window] returnCode:NSCancelButton];
}
- (IBAction)manageBuildTargets:(id)sender; {
	[[NSApplication sharedApplication] endSheet:[self window] returnCode:NSOKButton];
}

- (void)performCleanup; {
    [self.buildTarget removeObserver:self forKeyPath:@"name" context:self];
    [self.buildTarget removeObserver:self forKeyPath:@"outputType" context:self];
    [self.buildTarget removeObserver:self forKeyPath:@"inputFile" context:self];
    [self.buildTarget removeObserver:self forKeyPath:@"active" context:self];
    [self.buildTarget removeObserver:self forKeyPath:@"generateCodeListing" context:self];
    [self.buildTarget removeObserver:self forKeyPath:@"generateLabelFile" context:self];
    [self.buildTarget removeObserver:self forKeyPath:@"symbolsAreCaseSensitive" context:self];
}

static NSString *const kNameColumnIdentifier = @"name";
static NSString *const kValueColumnIdentifier = @"value";
static NSString *const kIconColumnIdentifier = @"icon";
static NSString *const kPathColumnIdentifier = @"path";

- (IBAction)newBuildDefine:(id)sender; {
	WCBuildDefine *newBuildDefine = [WCBuildDefine buildDefine];
	NSUInteger insertIndex = [[[self definesArrayController] selectionIndexes] firstIndex];
	
	if (insertIndex == NSNotFound)
		insertIndex = [[[self definesArrayController] arrangedObjects] count];
	
	[[self definesArrayController] insertObject:newBuildDefine atArrangedObjectIndex:insertIndex];
	
	[[self definesTableView] editColumn:[[self definesTableView] columnWithIdentifier:kNameColumnIdentifier] row:[[[self definesArrayController] arrangedObjects] indexOfObjectIdenticalTo:newBuildDefine] withEvent:nil select:YES];
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
		
		[[deleteBuildDefinesAlert suppressionButton] bind:NSValueBinding toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:WCAlertsWarnBeforeDeletingBuildDefinesKey] options:[NSDictionary dictionaryWithObjectsAndKeys:NSNegateBooleanTransformerName,NSValueTransformerNameBindingOption, nil]];
		
		[deleteBuildDefinesAlert OA_beginSheetModalForWindow:[self window] completionHandler:^(NSAlert *alert, NSInteger returnCode) {
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
- (IBAction)newBuildInclude:(id)sender; {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setPrompt:LOCALIZED_STRING_ADD];
	
	[openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
		[openPanel orderOut:nil];
		if (result == NSFileHandlingPanelCancelButton)
			return;
		
		for (NSURL *directoryURL in [openPanel URLs]) {
			WCBuildInclude *include = [WCBuildInclude buildIncludeWithDirectoryURL:directoryURL];
			
			[[[self buildTarget] mutableIncludes] addObject:include];
		}
	}];
}
- (IBAction)deleteBuildInclude:(id)sender; {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:WCAlertsWarnBeforeDeletingBuildIncludesKey]) {
		NSString *message;
		if ([[[self includesArrayController] selectionIndexes] count] == 1)
			message = [NSString stringWithFormat:NSLocalizedString(@"Delete the Build Include \"%@\"?", @"delete build include alert single include message format string"),[(WCBuildInclude *)[[[self includesArrayController] selectedObjects] lastObject] name]];
		else
			message = [NSString stringWithFormat:NSLocalizedString(@"Delete %lu Build Includes?", @"delete build include alert multiple includes message format string"),[[[self includesArrayController] selectionIndexes] count]];
		
		NSAlert *deleteBuildIncludesAlert = [NSAlert alertWithMessageText:message defaultButton:LOCALIZED_STRING_DELETE alternateButton:LOCALIZED_STRING_CANCEL otherButton:nil informativeTextWithFormat:NSLocalizedString(@"This operation cannot be undone.", @"This operation cannot be undone.")];
		
		[deleteBuildIncludesAlert setShowsSuppressionButton:YES];
		
		[[deleteBuildIncludesAlert suppressionButton] bind:NSValueBinding toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:WCAlertsWarnBeforeDeletingBuildIncludesKey] options:[NSDictionary dictionaryWithObjectsAndKeys:NSNegateBooleanTransformerName,NSValueTransformerNameBindingOption, nil]];
		
		[deleteBuildIncludesAlert OA_beginSheetModalForWindow:[self window] completionHandler:^(NSAlert *alert, NSInteger returnCode) {
			[[alert suppressionButton] unbind:NSValueBinding];
			[[alert window] orderOut:nil];
			if (returnCode == NSAlertAlternateReturn)
				return;
			
			[[self includesArrayController] removeObjectsAtArrangedObjectIndexes:[[self includesArrayController] selectionIndexes]];
		}];
	}
	else
		[[self includesArrayController] removeObjectsAtArrangedObjectIndexes:[[self includesArrayController] selectionIndexes]];
}

- (IBAction)chooseInputFile:(id)sender; {	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:WCAssemblyFileUTI,WCIncludeFileUTI,WCActiveServerIncludeFileUTI,WCWabbitEditIncludeFileUTI,WCWabbitEditAssemblyFileUTI, nil]];
	[openPanel setDirectoryURL:[[[[self buildTarget] projectDocument] fileURL] parentDirectoryURL]];
	[openPanel setPrompt:LOCALIZED_STRING_CHOOSE];
	[openPanel setAccessoryView:[[self chooseInputFileAccessoryViewController] view]];
	
	[openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
		[openPanel orderOut:nil];
		[self setChooseInputFileAccessoryViewController:nil];
		if (result == NSFileHandlingPanelCancelButton)
			return;
		
		NSDictionary *filePathsToFiles = [[[self buildTarget] projectDocument] filePathsToFiles];
		WCFile *file = [filePathsToFiles objectForKey:[[[openPanel URLs] lastObject] path]];
		
		if (file)
			[[self buildTarget] setInputFile:file];
		// TODO: copy the file into the project, then set the build target's input file
		else {
			
		}
	}];
}
#pragma mark Properties
@synthesize nameTextField=_nameTextField;
@synthesize definesArrayController=_definesArrayController;
@synthesize definesTableView=_definesTableView;
@synthesize definesSearchField=_definesSearchField;
@synthesize includesTableView=_includesTableView;
@synthesize includesSearchField=_includesSearchField;
@synthesize includesArrayController=_includesArrayController;

@synthesize buildTarget=_buildTarget;
@synthesize chooseInputFileAccessoryViewController=_chooseInputFileAccessoryViewController;
- (WCEditBuildTargetChooseInputFileAccessoryViewController *)chooseInputFileAccessoryViewController {
	if (!_chooseInputFileAccessoryViewController)
		_chooseInputFileAccessoryViewController = [[WCEditBuildTargetChooseInputFileAccessoryViewController alloc] init];
	return _chooseInputFileAccessoryViewController;
}
#pragma mark *** Private Methods ***

#pragma mark Callbacks
- (void)_sheetDidEnd:(NSWindow *)sheet code:(NSInteger)code context:(void *)context {
	[self autorelease];
	[sheet orderOut:nil];
    [self performCleanup];
	
	if (code == NSCancelButton)
		return;
	
	[[[self buildTarget] projectDocument] manageBuildTargets:nil];
}
#pragma mark IBActions
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
