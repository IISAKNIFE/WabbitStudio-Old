//
//  WCCompletionWindowController.m
//  WabbitEdit
//
//  Created by William Towe on 12/24/11.
//  Copyright (c) 2011 Revolution Software. All rights reserved.
//

#import "WCCompletionWindowController.h"
#import "WCSourceTextView.h"
#import "NDTrie.h"
#import "WCCompletionChoice.h"
#import "WCSourceScanner.h"
#import "RSDefines.h"
#import "WCArgumentPlaceholderCell.h"
#import "WCSourceToken.h"
#import "NSArray+WCExtensions.h"

@interface WCCompletionWindowController ()
@property (readwrite,assign,nonatomic) WCSourceTextView *textView;
@property (readonly,nonatomic) NSMutableArray *mutableCompletions;

- (void)_closeCompletionWindowControllerAndInsertCompletion:(BOOL)insertCompletion;
- (BOOL)_updateCompletions;
- (void)_setupCompletionsWithDictionaryURL:(NSURL *)dictURL completionsTrie:(NDMutableTrie *)trie completionType:(WCSourceTokenType)type;
- (void)_addStaticCompletionsFromCompletionsTrie:(NDTrie *)trie toArray:(NSMutableArray *)array forPrefix:(NSString *)prefix;
@end

@implementation WCCompletionWindowController

- (id)init {
	if (!(self = [super initWithWindowNibName:[self windowNibName]]))
		return nil;
	
	_completions = [[NSMutableArray alloc] initWithCapacity:0];
	_mneumonicCompletions = [[NDMutableTrie alloc] init];
	[self _setupCompletionsWithDictionaryURL:[[NSBundle mainBundle] URLForResource:@"MneumonicCompletions" withExtension:@"plist"] completionsTrie:_mneumonicCompletions completionType:WCSourceTokenTypeMneumonic];
	_preProcessorCompletions = [[NDMutableTrie alloc] init];
	[self _setupCompletionsWithDictionaryURL:[[NSBundle mainBundle] URLForResource:@"PreProcessorCompletions" withExtension:@"plist"] completionsTrie:_preProcessorCompletions completionType:WCSourceTokenTypePreProcessor];
	_registerCompletions = [[NDMutableTrie alloc] init];
	[self _setupCompletionsWithDictionaryURL:[[NSBundle mainBundle] URLForResource:@"RegisterCompletions" withExtension:@"plist"] completionsTrie:_registerCompletions completionType:WCSourceTokenTypeRegister];
	_conditionalCompletions = [[NDMutableTrie alloc] init];
	[self _setupCompletionsWithDictionaryURL:[[NSBundle mainBundle] URLForResource:@"ConditionalCompletions" withExtension:@"plist"] completionsTrie:_conditionalCompletions completionType:WCSourceTokenTypeConditional];
	_directiveCompletions = [[NDMutableTrie alloc] init];
	[self _setupCompletionsWithDictionaryURL:[[NSBundle mainBundle] URLForResource:@"DirectiveCompletions" withExtension:@"plist"] completionsTrie:_directiveCompletions completionType:WCSourceTokenTypeDirective];
	
	return self;
}

- (NSString *)windowNibName {
	return @"WCCompletionWindow";
}

- (void)windowDidLoad {
	[super windowDidLoad];
	
	[[self tableView] setTarget:self];
	[[self tableView] setDoubleAction:@selector(_tableViewDoubleClick:)];
}

- (void)handleReturnPressedForTableView:(RSTableView *)tableView {
	if ([[[self arrayController] selectedObjects] count])
		[self _closeCompletionWindowControllerAndInsertCompletion:YES];
}

+ (WCCompletionWindowController *)sharedWindowController; {
	static id sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[[self class] alloc] init];
	});
	return sharedInstance;
}
- (void)showCompletionWindowControllerForSourceTextView:(WCSourceTextView *)textView; {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[[self window] setAnimationBehavior:NSWindowAnimationBehaviorUtilityWindow];
	});
	
	if ([self textView])
		return;
	
	[self setTextView:textView];
	
	_eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask|NSKeyDownMask|NSScrollWheelMask  handler:^NSEvent* (NSEvent *event) {
		switch ([event type]) {
			case NSLeftMouseDown:
			case NSRightMouseDown:
			case NSScrollWheel:
				if ([event window] != [self window])
					[self _closeCompletionWindowControllerAndInsertCompletion:NO];
				break;
			case NSKeyDown:
				switch ([event keyCode]) {
					case KEY_CODE_ESCAPE:
						[self _closeCompletionWindowControllerAndInsertCompletion:NO];
						return nil;
					case KEY_CODE_LEFT_ARROW:
					case KEY_CODE_RIGHT_ARROW:
					case KEY_CODE_SPACE:
						[self _closeCompletionWindowControllerAndInsertCompletion:NO];
						break;
					case KEY_CODE_RETURN:
					case KEY_CODE_ENTER:
					case KEY_CODE_TAB:
						[self _closeCompletionWindowControllerAndInsertCompletion:YES];
						return nil;
					case KEY_CODE_UP_ARROW:
					case KEY_CODE_DOWN_ARROW:
						[[self tableView] keyDown:event];
						return nil;
					case KEY_CODE_DELETE:
					case KEY_CODE_DELETE_FORWARD:
						[[self textView] keyDown:event];
						[self _updateCompletions];
						return nil;
					default: {
						static NSCharacterSet *legalChars;
						static dispatch_once_t onceToken;
						dispatch_once(&onceToken, ^{
							NSMutableCharacterSet *charSet = [[[NSCharacterSet letterCharacterSet] mutableCopy] autorelease];
							[charSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
							[charSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"#._!?"]];
							legalChars = [charSet copy];
						});
						
						NSString *chars = [event charactersIgnoringModifiers];
						NSRange range = [chars rangeOfCharacterFromSet:legalChars];
						
						if (range.location == NSNotFound) {
							[[self textView] keyDown:event];
							[self _closeCompletionWindowControllerAndInsertCompletion:NO];
						}
						else {
							[[self textView] keyDown:event];
							[self _updateCompletions];
						}
					}
						return nil;
				}
				break;
			default:
				break;
		}
		return event;
	}];
	
	_applicationDidResignActiveObservingToken = [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidResignActiveNotification object:[NSApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note) {
		[self _closeCompletionWindowControllerAndInsertCompletion:NO];
	}];
	
	if ([self _updateCompletions])
		[[self window] makeKeyAndOrderFront:nil];
	else
		[self _closeCompletionWindowControllerAndInsertCompletion:NO];
}

@synthesize tableView=_tableView;
@synthesize arrayController=_arrayController;
@synthesize textView=_textView;
@synthesize completions=_completions;
@dynamic mutableCompletions;
- (NSMutableArray *)mutableCompletions {
	return [self mutableArrayValueForKey:@"completions"];
}
- (NSUInteger)countOfCompletions {
	return [_completions count];
}
- (id)objectInCompletionsAtIndex:(NSUInteger)index {
	return [_completions objectAtIndex:index];
}
- (void)insertObject:(id <WCCompletionItem>)object inCompletionsAtIndex:(NSUInteger)index {
	[_completions insertObject:object atIndex:index];
}
- (void)insertCompletions:(NSArray *)completions atIndexes:(NSIndexSet *)indexes {
	[_completions insertObjects:completions atIndexes:indexes];
}
- (void)removeObjectFromCompletionsAtIndex:(NSUInteger)index {
	[_completions removeObjectAtIndex:index];
}
- (void)removeCompletionsAtIndexes:(NSIndexSet *)indexes {
	[_completions removeObjectsAtIndexes:indexes];
}
- (void)replaceObjectInCompletionsAtIndex:(NSUInteger)index withObject:(id)object {
	[_completions replaceObjectAtIndex:index withObject:object];
}
- (void)replaceCompletionsAtIndexes:(NSIndexSet *)indexes withCompletions:(NSArray *)completions {
	[_completions replaceObjectsAtIndexes:indexes withObjects:completions];
}

- (void)_closeCompletionWindowControllerAndInsertCompletion:(BOOL)insertCompletion; {
	[[self window] close];
	
	if (insertCompletion) {
		id <WCCompletionItem> itemToInsert = [[[self arrayController] selectedObjects] lastObject];
		NSRange completionRange = [[self textView] rangeForUserCompletion];
		if (completionRange.location == NSNotFound)
			completionRange = [[self textView] selectedRange];
		
		if ([itemToInsert respondsToSelector:@selector(completionArguments)]) {
			NSDictionary *defaultAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[[self textView] font],NSFontAttributeName, nil];
			NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithString:[itemToInsert completionInsertionName] attributes:defaultAttributes] autorelease];
			
			// add the opening paren
			[attributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"(" attributes:defaultAttributes] autorelease]];
			
			// add an argument placeholder cell for each argument
			for (NSString *argument in [itemToInsert completionArguments]) {
				NSTextAttachment *attachment = [[[NSTextAttachment alloc] initWithFileWrapper:nil] autorelease];
				WCArgumentPlaceholderCell *cell = [[[WCArgumentPlaceholderCell alloc] initTextCell:argument] autorelease];
				
				[attachment setAttachmentCell:cell];
				[attributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
				
				// add the comma
				[attributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"," attributes:defaultAttributes] autorelease]];
			}
			
			// delete the trailing comma
			[attributedString deleteCharactersInRange:NSMakeRange([attributedString length]-1, 1)];
			
			// add the closing paren
			[attributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:@")" attributes:defaultAttributes] autorelease]];
			
			if ([[self textView] shouldChangeTextInRange:completionRange replacementString:[attributedString string]]) {
				[[[self textView] textStorage] replaceCharactersInRange:completionRange withAttributedString:attributedString];
				[[self textView] didChangeText];
			}
		}
		else if ([itemToInsert respondsToSelector:@selector(completionDictionary)]) {
			NSDictionary *defaultAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[[self textView] font],NSFontAttributeName, nil];
			NSMutableAttributedString *attributedString;
			
			if ([[itemToInsert completionDictionary] objectForKey:WCCompletionItemArgumentsKey]) {
				attributedString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",[itemToInsert completionInsertionName]] attributes:defaultAttributes] autorelease];
				
				for (NSDictionary *argumentDict in [[itemToInsert completionDictionary] objectForKey:WCCompletionItemArgumentsKey]) {
					if ([argumentDict objectForKey:WCCompletionItemSubArgumentsKey]) {
						for (NSDictionary *subArgumentDict in [argumentDict objectForKey:WCCompletionItemSubArgumentsKey]) {
							if ([[subArgumentDict objectForKey:WCCompletionItemArgumentIsPlaceholderKey] boolValue]) {
								NSTextAttachment *attachment = [[[NSTextAttachment alloc] initWithFileWrapper:nil] autorelease];
								WCArgumentPlaceholderCell *cell = [[[WCArgumentPlaceholderCell alloc] initTextCell:[subArgumentDict objectForKey:WCCompletionItemArgumentNameKey]] autorelease];
								
								[attachment setAttachmentCell:cell];
								[attributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
							}
							else {
								[attributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:[subArgumentDict objectForKey:WCCompletionItemArgumentNameKey] attributes:defaultAttributes] autorelease]];
							}
							
							if ([[subArgumentDict objectForKey:WCCompletionItemRequiresTrailingNewlineKey] boolValue])
								[attributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
						}
					}
					else {
						if ([[argumentDict objectForKey:WCCompletionItemArgumentIsPlaceholderKey] boolValue]) {
							NSTextAttachment *attachment = [[[NSTextAttachment alloc] initWithFileWrapper:nil] autorelease];
							WCArgumentPlaceholderCell *cell = [[[WCArgumentPlaceholderCell alloc] initTextCell:[argumentDict objectForKey:WCCompletionItemArgumentNameKey]] autorelease];
							
							[attachment setAttachmentCell:cell];
							[attributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
						}
						else {
							[attributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:[argumentDict objectForKey:WCCompletionItemArgumentNameKey] attributes:defaultAttributes] autorelease]];
						}
						
						// add the comma
						[attributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"," attributes:defaultAttributes] autorelease]];
					}
				}
				
				// delete the trailing comma
				if (![[[[itemToInsert completionDictionary] objectForKey:WCCompletionItemArgumentsKey] lastObject] objectForKey:WCCompletionItemSubArgumentsKey])
					[attributedString deleteCharactersInRange:NSMakeRange([attributedString length]-1, 1)];
			}
			else {
				attributedString = [[[NSMutableAttributedString alloc] initWithString:[itemToInsert completionInsertionName] attributes:defaultAttributes] autorelease];
			}
			
			if ([[self textView] shouldChangeTextInRange:completionRange replacementString:[attributedString string]]) {
				[[[self textView] textStorage] replaceCharactersInRange:completionRange withAttributedString:attributedString];
				[[self textView] didChangeText];
			}
		}
		else {
			if ([[self textView] shouldChangeTextInRange:completionRange replacementString:[itemToInsert completionInsertionName]]) {
				[[self textView] replaceCharactersInRange:completionRange withString:[itemToInsert completionInsertionName]];
				[[self textView] didChangeText];
			}
		}
	}
			  
	[self setTextView:nil];
	[[self mutableCompletions] removeAllObjects];
	[NSEvent removeMonitor:_eventMonitor];
	[[NSNotificationCenter defaultCenter] removeObserver:_applicationDidResignActiveObservingToken];
}

- (BOOL)_updateCompletions; {
	NSRange completionRange = [[self textView] rangeForUserCompletion];
	WCSourceScanner *sourceScanner = [[[self textView] delegate] sourceScannerForSourceTextView:[self textView]];
	NSMutableArray *staticCompletions = [NSMutableArray arrayWithCapacity:0];
	
	if (completionRange.location == NSNotFound) {
		// can we provide context specific matches
		completionRange = [[self textView] selectedRange];
		
		NSRange lineRange = [[[self textView] string] lineRangeForRange:completionRange];
		
		// we are at the beginning of a line, preProcessor and directives only
		if (completionRange.location == lineRange.location) {
			[self _addStaticCompletionsFromCompletionsTrie:_directiveCompletions toArray:staticCompletions forPrefix:nil];
			[self _addStaticCompletionsFromCompletionsTrie:_preProcessorCompletions toArray:staticCompletions forPrefix:nil];
		}
		// we are in column 1, mneumonics only
		else if (completionRange.location == lineRange.location+1) {
			[self _addStaticCompletionsFromCompletionsTrie:_mneumonicCompletions toArray:staticCompletions forPrefix:nil];
		}
		else {
			WCSourceToken *token = [[sourceScanner tokens] sourceTokenForRange:completionRange];
			if ([token type] == WCSourceTokenTypeMneumonic ||
				[token type] == WCSourceTokenTypeRegister) {
				
				[self _addStaticCompletionsFromCompletionsTrie:_conditionalCompletions toArray:staticCompletions forPrefix:nil];
				[self _addStaticCompletionsFromCompletionsTrie:_registerCompletions toArray:staticCompletions forPrefix:nil];
			}
		}
		
		[[self mutableCompletions] setArray:staticCompletions];
	}
	else {
		NSString *completionString = [[[[self textView] string] substringWithRange:completionRange] lowercaseString];
		
		[self _addStaticCompletionsFromCompletionsTrie:_mneumonicCompletions toArray:staticCompletions forPrefix:completionString];
		[self _addStaticCompletionsFromCompletionsTrie:_preProcessorCompletions toArray:staticCompletions forPrefix:completionString];
		[self _addStaticCompletionsFromCompletionsTrie:_registerCompletions toArray:staticCompletions forPrefix:completionString];
		[self _addStaticCompletionsFromCompletionsTrie:_conditionalCompletions toArray:staticCompletions forPrefix:completionString];
		[self _addStaticCompletionsFromCompletionsTrie:_directiveCompletions toArray:staticCompletions forPrefix:completionString];
		
		[[self mutableCompletions] setArray:staticCompletions];
		[[self mutableCompletions] addObjectsFromArray:[[sourceScanner completions] everyObjectForKeyWithPrefix:completionString]];
	}
	
	if (![[self completions] count])
		return NO;
	
	static NSTextFieldCell *stringSizeCell;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		stringSizeCell = [[NSTextFieldCell alloc] initTextCell:@""];
		[stringSizeCell setAlignment:NSLeftTextAlignment];
		[stringSizeCell setBackgroundStyle:NSBackgroundStyleLowered];
		[stringSizeCell setControlSize:NSSmallControlSize];
		[stringSizeCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	});
	
	CGFloat requiredWidth = ([[self completions] count])?0.0:125.0;
	CGFloat scrollerWidth = ([NSScroller scrollerWidthForControlSize:NSSmallControlSize scrollerStyle:NSScrollerStyleOverlay]*2);
	
	for (id <WCCompletionItem> item in [self completions]) {
		[stringSizeCell setStringValue:[item completionName]];
		NSSize stringSize = [stringSizeCell cellSizeForBounds:NSMakeRect(0.0, 0.0, CGFLOAT_MAX, CGFLOAT_MAX)];
		if (stringSize.width+scrollerWidth > requiredWidth)
			requiredWidth = stringSize.width+scrollerWidth;
	}
	
	CGFloat maxWidth = NSWidth([[self textView] bounds]);
	static const CGFloat maxHeight = 100.0;
	CGFloat requiredHeight = ([[self completions] count] == 0)?35.0:[[self completions] count] * ([[self tableView] rowHeight]+[[self tableView] intercellSpacing].height);
	NSSize newSize = [NSScrollView frameSizeForContentSize:NSMakeSize((requiredWidth < maxWidth)?requiredWidth:maxWidth, (requiredHeight < maxHeight)?requiredHeight:maxHeight) hasHorizontalScroller:[[[self tableView] enclosingScrollView] hasHorizontalScroller] hasVerticalScroller:[[[self tableView] enclosingScrollView] hasVerticalScroller] borderType:[[[self tableView] enclosingScrollView] borderType]];
	
	NSRect newFrame = [[self window] frameRectForContentRect:NSMakeRect(NSMinX([[self window] frame]), NSMinY([[self window] frame]), newSize.width, newSize.height)];
	
	if (NSHeight([[self window] frame]) < NSHeight(newFrame))
		newFrame.origin.y -= (NSHeight(newFrame) - NSHeight([[self window] frame]));
	else if (NSHeight([[self window] frame]) > NSHeight(newFrame))
		newFrame.origin.y += (NSHeight([[self window] frame]) - NSHeight(newFrame));
	
	[[self window] setFrame:newFrame display:YES];
	
	NSUInteger glyphIndex = [[[self textView] layoutManager] glyphIndexForCharacterAtIndex:completionRange.location];
	NSRect lineRect = [[[self textView] layoutManager] lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL];
	NSPoint selectedPoint = [[[self textView] layoutManager] locationForGlyphAtIndex:glyphIndex];
	
	lineRect.origin.y += lineRect.size.height;
	lineRect.origin.x += selectedPoint.x;
	
	[[self window] setFrameTopLeftPoint:[[[self textView] window] convertBaseToScreen:[[self textView] convertPointToBase:lineRect.origin]]];
	
	return YES;
}

- (void)_setupCompletionsWithDictionaryURL:(NSURL *)dictURL completionsTrie:(NDMutableTrie *)trie completionType:(WCSourceTokenType)type; {
	NSDictionary *completions = [NSDictionary dictionaryWithContentsOfURL:dictURL];
	
	[completions enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *plist, BOOL *stop) {
		if ([plist objectForKey:WCCompletionItemVariantsKey]) {
			NSMutableArray *variants = [NSMutableArray arrayWithCapacity:0];
			
			for (NSDictionary *variant in [plist objectForKey:WCCompletionItemVariantsKey]) {
				[variants addObject:[WCCompletionChoice completionChoiceOfType:type name:key dictionary:variant]];
			}
			
			if ([variants count])
				[trie setObject:[[variants copy] autorelease] forKey:key];
		}
		else {
			[trie setObject:[WCCompletionChoice completionChoiceOfType:type name:key dictionary:plist] forKey:key];
		}
	}];
}

- (void)_addStaticCompletionsFromCompletionsTrie:(NDTrie *)trie toArray:(NSMutableArray *)array forPrefix:(NSString *)prefix; {
	NSArray *completions = ([prefix length])?[trie everyObjectForKeyWithPrefix:prefix]:[trie everyObject];
	for (id variants in completions) {
		if ([variants isKindOfClass:[NSArray class]])
			[array addObjectsFromArray:variants];
		else
			[array addObject:variants];
	}
}

- (void)_tableViewDoubleClick:(id)sender {
	if ([[[self arrayController] selectedObjects] count])
		[self _closeCompletionWindowControllerAndInsertCompletion:YES];
}
@end