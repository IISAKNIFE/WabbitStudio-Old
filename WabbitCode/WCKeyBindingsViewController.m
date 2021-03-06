//
//  WCKeyBindingsViewController.m
//  WabbitStudio
//
//  Created by William Towe on 1/11/12.
//  Copyright (c) 2012 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "WCKeyBindingsViewController.h"
#import "MGScopeBar.h"
#import "WCKeyBindingCommandSetManager.h"
#import "WCKeyBindingCommandPair.h"
#import "WCKeyBindingsEditCommandPairWindowController.h"
#import "WCKeyBindingCommandSet.h"
#import "RSDefines.h"
#import "RSOutlineView.h"
#import "RSTableView.h"
#import "NSTreeController+RSExtensions.h"
#import "WCAlertsViewController.h"
#import "NSAlert-OAExtensions.h"

NSString *const WCKeyBindingsCurrentCommandSetIdentifierKey = @"WCKeyBindingsCurrentCommandSetIdentifierKey";
NSString *const WCKeyBindingsUserCommandSetIdentifiersKey = @"WCKeyBindingsUserCommandSetIdentifiersKey";

@interface WCKeyBindingsViewController ()
@property (readwrite,copy,nonatomic) NSString *searchString;
@property (readwrite,copy,nonatomic) NSString *defaultShortcutString;
@property (readwrite,copy,nonatomic) NSArray *previousSelectionIndexPaths;
@end

@implementation WCKeyBindingsViewController

#pragma mark *** Subclass Overrides ***
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_scopeBarItemIdentifiersToTitles release];
	[_scopeBarItemTitles release];
	[_defaultShortcutString release];
	[_searchString release];
	[_previousSelectionIndexPaths release];
	[super dealloc];
}

- (id)init {
	if (!(self = [super initWithNibName:[self nibName] bundle:nil]))
		return nil;
	
	_scopeBarItemTitles = [[NSArray alloc] initWithObjects:NSLocalizedString(@"All", @"All"),NSLocalizedString(@"Customized", @"Customized"), nil];
	
	NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithCapacity:[_scopeBarItemTitles count]];
	for (NSString *title in _scopeBarItemTitles)
		[temp setObject:title forKey:title];
	_scopeBarItemIdentifiersToTitles = [temp copy];
	
	return self;
}

- (NSString *)nibName {
	return @"WCKeyBindingsView";
}

- (void)loadView {
	[super loadView];
	
	[[self arrayController] bind:NSContentArrayBinding toObject:[WCKeyBindingCommandSetManager sharedManager] withKeyPath:@"commandSets" options:nil];
	
	[[self arrayController] setSelectedObjects:[NSArray arrayWithObject:[[WCKeyBindingCommandSetManager sharedManager] currentCommandSet]]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tableViewSelectionIsChanging:) name:NSTableViewSelectionIsChangingNotification object:[self tableView]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:[self tableView]];
	
	[[self outlineView] setTarget:self];
	[[self outlineView] setDoubleAction:@selector(_outlineViewDoubleClick:)];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_outlineViewSelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:[self outlineView]];
	
	[[self outlineView] expandItem:nil expandChildren:YES];
	[[self outlineView] selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
}
#pragma mark RSPreferencesModule
- (NSString *)identifier {
	return @"org.revsoft.wabbitcode.keybindings";
}

- (NSString *)label {
	return NSLocalizedString(@"Key Bindings", @"Key Bindings");
}

- (NSImage *)image {
	return [NSImage imageNamed:@"KeyBindings"];
}
#pragma mark RSUserDefaultsProvider
+ (NSDictionary *)userDefaults {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"org.revsoft.wabbitstudio.keybindingcommandset.default",WCKeyBindingsCurrentCommandSetIdentifierKey, nil];
}
#pragma mark MGScopeBarDelegate
static const NSInteger kNumberOfScopeBarGroups = 1;
- (NSInteger)numberOfGroupsInScopeBar:(MGScopeBar *)theScopeBar {
	return kNumberOfScopeBarGroups;
}
- (NSArray *)scopeBar:(MGScopeBar *)theScopeBar itemIdentifiersForGroup:(NSInteger)groupNumber {
	return _scopeBarItemTitles;
}
- (MGScopeBarGroupSelectionMode)scopeBar:(MGScopeBar *)theScopeBar selectionModeForGroup:(NSInteger)groupNumber {
	return MGRadioSelectionMode;
}
- (NSString *)scopeBar:(MGScopeBar *)theScopeBar labelForGroup:(NSInteger)groupNumber; {
	return nil;
}
- (NSString *)scopeBar:(MGScopeBar *)theScopeBar titleOfItem:(NSString *)identifier inGroup:(NSInteger)groupNumber {
	return [_scopeBarItemIdentifiersToTitles objectForKey:identifier];
}
- (NSView *)accessoryViewForScopeBar:(MGScopeBar *)theScopeBar {
	return [self searchField];
}

- (void)scopeBar:(MGScopeBar *)theScopeBar selectedStateChanged:(BOOL)selected forItem:(NSString *)identifier inGroup:(NSInteger)groupNumber {
	if ([identifier isEqualToString:@"Customized"]) {
		[[self treeController] bind:NSContentArrayBinding toObject:[self arrayController] withKeyPath:@"selection.customizedCommandPairs" options:nil];
		[[self searchArrayController] bind:NSContentArrayBinding toObject:[self arrayController] withKeyPath:@"selection.customizedCommandPairs" options:nil];
	}
	else {
		[[self treeController] bind:NSContentArrayBinding toObject:[self arrayController] withKeyPath:@"selection.commandPairs" options:nil];
		[[self searchArrayController] bind:NSContentArrayBinding toObject:[self arrayController] withKeyPath:@"selection.flattenedCommandPairs" options:nil];
		
		[[self outlineView] expandItem:nil expandChildren:YES];
		[[self outlineView] selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
	}
}
#pragma mark NSMenuValidation
- (BOOL)validateMenuItem:(NSMenuItem *)item {
	if ([item action] == @selector(duplicateCommandSet:)) {
		WCKeyBindingCommandSet *commandSet = [[[self arrayController] selectedObjects] lastObject];
		
		[item setTitle:[NSString stringWithFormat:NSLocalizedString(@"Duplicate \"%@\"", @"duplicate command set format string"),[commandSet name]]];
	}
	return YES;
}
#pragma mark NSMenuDelegate
- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu {
	return [[[WCKeyBindingCommandSetManager sharedManager] defaultCommandSets] count];
}
- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel {
	WCKeyBindingCommandSet *commandSet = [[[WCKeyBindingCommandSetManager sharedManager] defaultCommandSets] objectAtIndex:index];
	
	[item setTitle:[commandSet name]];
	[item setTarget:self];
	[item setAction:@selector(_newFromTemplateClicked:)];
	[item setRepresentedObject:commandSet];
	
	return YES;
}
#pragma mark NSControlTextEditingDelegate
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
	return ([[fieldEditor string] length]);
}

#pragma mark NSOutlineViewDelegate
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {	
	return ([[[item representedObject] menuItem] menu] == [[NSApplication sharedApplication] mainMenu]);
}
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	return ([[[item representedObject] menuItem] menu] != [[NSApplication sharedApplication] mainMenu]);
}
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([[[item representedObject] menuItem] isAlternate]) {
		NSMutableAttributedString *attributedString = [[[cell attributedStringValue] mutableCopy] autorelease];
		
		[attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor disabledControlTextColor],NSForegroundColorAttributeName, nil] range:NSMakeRange(0, [attributedString length])];
		
		[cell setAttributedStringValue:attributedString];
	}
}
- (NSString *)outlineView:(NSOutlineView *)outlineView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
	BOOL isGroupItem = [self outlineView:outlineView isGroupItem:item];
	if (isGroupItem)
		return nil;
	NSString *key = [[WCKeyBindingCommandSetManager sharedManager] defaultKeyForMenuItem:[[item representedObject] menuItem]];
	return [NSString stringWithFormat:NSLocalizedString(@"Default shortcut: %@", @"default shortcut format string"),([key length])?key:NSLocalizedString(@"None", @"None")];
}
#pragma mark RSTableViewDelegate
- (void)handleDeletePressedForTableView:(RSTableView *)tableView {
	[self deleteCommandSet:nil];
}
#pragma mark RSOutlineViewDelegate
- (void)handleReturnPressedForOutlineView:(RSOutlineView *)outlineView {
	[[WCKeyBindingsEditCommandPairWindowController sharedWindowController] showEditCommandPairSheetForCommandPair:[[[self outlineView] itemAtRow:[[self outlineView] selectedRow]] representedObject]];
}
- (void)handleDeletePressedForOutlineView:(RSOutlineView *)outlineView {
	WCKeyBindingCommandPair *pair = [[[self treeController] selectedRepresentedObjects] lastObject];
	
	if ([pair isLeafNode])
		[pair setKeyCombo:WCKeyBindingCommandPairEmptyKeyCombo()];
}
- (void)handleSpacePressedForOutlineView:(RSOutlineView *)outlineView {
	WCKeyBindingCommandPair *pair = [[[self treeController] selectedRepresentedObjects] lastObject];
	
	if ([pair isLeafNode]) {
		WCKeyBindingCommandPair *defaultPair = [[WCKeyBindingCommandSetManager sharedManager] defaultCommandPairForMenuItem:[pair menuItem]];
		
		[pair setKeyCombo:[defaultPair keyCombo]];
	}
}
#pragma mark *** Public Methods ***

#pragma mark IBActions
- (IBAction)search:(id)sender; {
	if ([[self searchString] length]) {
		[[self treeController] bind:NSContentArrayBinding toObject:[self searchArrayController] withKeyPath:@"arrangedObjects" options:nil];
	}
	else {
		[[self treeController] bind:NSContentArrayBinding toObject:[self arrayController] withKeyPath:@"selection.commandPairs" options:nil];
		[[self outlineView] expandItem:nil expandChildren:YES];
	}
}

- (IBAction)deleteCommandSet:(id)sender; {
	if ([[[self arrayController] arrangedObjects] count] == 1) {
		NSBeep();
		return;
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:WCAlertsWarnBeforeDeletingKeyBindingCommandSetsKey]) {
		NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Delete the Command Set \"%@\"?", @"delete key binding command set alert message format string"),[(WCKeyBindingCommandSet *)[[[self arrayController] selectedObjects] lastObject] name]];
		NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:LOCALIZED_STRING_DELETE alternateButton:LOCALIZED_STRING_CANCEL otherButton:nil informativeTextWithFormat:NSLocalizedString(@"This operation cannot be undone.", @"This operation cannot be undone.")];
		
		[alert setShowsSuppressionButton:YES];
		
		[[alert suppressionButton] bind:NSValueBinding toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.alertsWarnBeforeDeletingKeyBindingCommandSets" options:[NSDictionary dictionaryWithObjectsAndKeys:NSNegateBooleanTransformerName,NSValueTransformerNameBindingOption, nil]];
		
		[alert OA_beginSheetModalForWindow:[[self view] window] completionHandler:^(NSAlert *alert, NSInteger returnCode) {
			[[alert suppressionButton] unbind:NSValueBinding];
			[[alert window] orderOut:nil];
			if (returnCode == NSAlertAlternateReturn)
				return;
			
			[[self arrayController] removeObjectsAtArrangedObjectIndexes:[[self arrayController] selectionIndexes]];
		}];
	}
	else
		[[self arrayController] removeObjectsAtArrangedObjectIndexes:[[self arrayController] selectionIndexes]];
}
- (IBAction)duplicateCommandSet:(id)sender; {
	WCKeyBindingCommandSet *newCommandSet = [[[[[self arrayController] selectedObjects] lastObject] mutableCopy] autorelease];
	
	if ([[WCKeyBindingCommandSetManager sharedManager] containsCommandSet:newCommandSet]) {
		NSBeep();
		return;
	}
	
	[[self arrayController] addObject:newCommandSet];
	
	[self performSelector:@selector(_editSelectedCommandSetsTableViewRow) withObject:nil afterDelay:0.0];
}
#pragma mark Properties
@synthesize scopeBar=_scopeBar;
@synthesize searchField=_searchField;
@synthesize arrayController=_arrayController;
@synthesize outlineView=_outlineView;
@synthesize initialFirstResponder=_initialFirstResponder;
@synthesize searchArrayController=_searchArrayController;
@synthesize searchString=_searchString;
@synthesize treeController=_treeController;
@synthesize tableView=_tableView;
@synthesize defaultShortcutString=_defaultShortcutString;
@synthesize previousSelectionIndexPaths=_previousSelectionIndexPaths;
#pragma mark *** Private Methods ***
- (void)_editSelectedCommandSetsTableViewRow; {
	[[self tableView] editColumn:0 row:[[self tableView] selectedRow] withEvent:nil select:YES];
}
#pragma mark IBActions
- (IBAction)_outlineViewDoubleClick:(id)sender; {
	NSInteger clickedRow = [[self outlineView] clickedRow];
	if (clickedRow == -1) {
		NSBeep();
		return;
	}
	NSInteger selectedRow = [[self outlineView] selectedRow];
	if (selectedRow == -1 || selectedRow != clickedRow) {
		NSBeep();
		return;
	}
	
	[[WCKeyBindingsEditCommandPairWindowController sharedWindowController] showEditCommandPairSheetForCommandPair:[[[self outlineView] itemAtRow:clickedRow] representedObject]];
}

- (IBAction)_newFromTemplateClicked:(id)sender; {
	WCKeyBindingCommandSet *newCommandSet = [[[sender representedObject] mutableCopy] autorelease];
	
	if ([[WCKeyBindingCommandSetManager sharedManager] containsCommandSet:newCommandSet]) {
		NSBeep();
		return;
	}
	
	[[self arrayController] addObject:newCommandSet];
	
	[self performSelector:@selector(_editSelectedCommandSetsTableViewRow) withObject:nil afterDelay:0.0];
}
#pragma mark Notifications
- (void)_tableViewSelectionIsChanging:(NSNotification *)note {
	[self setPreviousSelectionIndexPaths:[[self treeController] selectionIndexPaths]];
}
- (void)_tableViewSelectionDidChange:(NSNotification *)note {
	[[WCKeyBindingCommandSetManager sharedManager] setCurrentCommandSet:[[[self arrayController] selectedObjects] lastObject]];
	
	[[self outlineView] expandItem:nil expandChildren:YES];
	//[[self treeController] setSelectionIndexPaths:[self previousSelectionIndexPaths]];
}
- (void)_outlineViewSelectionDidChange:(NSNotification *)note {
	WCKeyBindingCommandPair *pair = [[self treeController] selectedRepresentedObject];
	
	if (pair) {
		NSString *key = [[WCKeyBindingCommandSetManager sharedManager] defaultKeyForMenuItem:[pair menuItem]];
		
		[self setDefaultShortcutString:[NSString stringWithFormat:NSLocalizedString(@"Default shortcut: %@", @"default shortcut format string"),([key length])?key:NSLocalizedString(@"None", @"None")]];
	}
	else
		[self setDefaultShortcutString:nil];
}

@end
