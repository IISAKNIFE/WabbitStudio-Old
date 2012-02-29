//
//  WCSourceTextStorage.h
//  WabbitEdit
//
//  Created by William Towe on 12/26/11.
//  Copyright (c) 2011 Revolution Software. All rights reserved.
//

#import <AppKit/NSTextStorage.h>
#import "WCSourceTextStorageDelegate.h"

extern NSString *const WCSourceTextStorageDidAddBookmarkNotification;
extern NSString *const WCSourceTextStorageDidRemoveBookmarkNotification;
extern NSString *const WCSourceTextStorageDidRemoveAllBookmarksNotification;

extern NSString *const WCSourceTextStorageDidFoldNotification;
extern NSString *const WCSourceTextStorageDidUnfoldNotification;
extern NSString *const WCSourceTextStorageFoldRangeUserInfoKey;

@class RSBookmark;

@interface WCSourceTextStorage : NSTextStorage {
	__weak id <WCSourceTextStorageDelegate> _delegate;
	NSMutableAttributedString *_attributedString;
	NSMutableArray *_lineStartIndexes;
	NSMutableArray *_bookmarks;
	struct {
		unsigned int lineFoldingEnabled:1;
		unsigned int RESERVED:31;
	} _textStorageFlags;
}
@property (readonly,nonatomic) NSArray *lineStartIndexes;
@property (readwrite,assign,nonatomic) id <WCSourceTextStorageDelegate> delegate;
@property (readonly,nonatomic) NSParagraphStyle *paragraphStyle;
@property (readonly,nonatomic) NSArray *bookmarks;
@property (readwrite,assign,nonatomic) BOOL lineFoldingEnabled;

+ (NSParagraphStyle *)defaultParagraphStyle;

- (void)addBookmark:(RSBookmark *)bookmark;
- (void)removeBookmark:(RSBookmark *)bookmark;
- (void)removeAllBookmarks;
- (RSBookmark *)bookmarkAtLineNumber:(NSUInteger)lineNumber;
- (NSArray *)bookmarksForRange:(NSRange)range;

- (void)foldRange:(NSRange)range;
- (BOOL)unfoldRange:(NSRange)range effectiveRange:(NSRangePointer)effectiveRange;
- (NSRange)foldRangeForRange:(NSRange)range;
@end