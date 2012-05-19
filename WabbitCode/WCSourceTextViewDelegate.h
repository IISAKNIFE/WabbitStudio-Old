//
//  WCSourceTextViewDelegate.h
//  WabbitEdit
//
//  Created by William Towe on 12/23/11.
//  Copyright (c) 2011 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <AppKit/NSTextView.h>

@class WCSourceTextView,WCSourceScanner,WCSourceHighlighter,WCSourceSymbol,WCFile,WCProjectDocument,WCSourceFileDocument;

@protocol WCSourceTextViewDelegate <NSTextViewDelegate>
@required
- (NSArray *)sourceTokensForSourceTextView:(WCSourceTextView *)textView;
- (NSArray *)sourceSymbolsForSourceTextView:(WCSourceTextView *)textView;
- (NSArray *)macrosForSourceTextView:(WCSourceTextView *)textView;

- (NSArray *)sourceTextView:(WCSourceTextView *)textView sourceSymbolsForSymbolName:(NSString *)name;

- (NSArray *)buildIssuesForSourceTextView:(WCSourceTextView *)textView;

- (NSArray *)fileBreakpointsForSourceTextView:(WCSourceTextView *)textView;
- (WCFile *)fileForSourceTextView:(WCSourceTextView *)textView;

- (WCSourceScanner *)sourceScannerForSourceTextView:(WCSourceTextView *)textView;

- (WCSourceHighlighter *)sourceHighlighterForSourceTextView:(WCSourceTextView *)textView;

- (WCProjectDocument *)projectDocumentForSourceTextView:(WCSourceTextView *)textView;
- (WCSourceFileDocument *)sourceFileDocumentForSourceTextView:(WCSourceTextView *)textView;

- (void)handleJumpToDefinitionForSourceTextView:(WCSourceTextView *)textView sourceSymbol:(WCSourceSymbol *)symbol;
- (void)handleJumpToDefinitionForSourceTextView:(WCSourceTextView *)textView file:(WCFile *)file;
@end
