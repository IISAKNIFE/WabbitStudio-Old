//
//  WCGroup.m
//  WabbitStudio
//
//  Created by William Towe on 1/13/12.
//  Copyright (c) 2012 Revolution Software.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "WCGroup.h"

static NSString *const WCGroupNameKey = @"name";

@implementation WCGroup
#pragma mark *** Subclass Overrides ***
- (void)dealloc {
	[_name release];
	[super dealloc];
}

- (NSString *)fileName {
	if ([[self name] length])
		return [self name];
	return [super fileName];
}
- (void)setFileName:(NSString *)fileName {
	[self setName:fileName];
}
- (NSImage *)fileIcon {
	return [NSImage imageNamed:@"Group"];
}

- (BOOL)isSourceFile {
	return NO;
}
#pragma mark RSPlistArchiving
- (NSDictionary *)plistRepresentation {
	NSMutableDictionary *retval = [NSMutableDictionary dictionaryWithDictionary:[super plistRepresentation]];
	
	if ([[self name] length])
		[retval setObject:[self name] forKey:WCGroupNameKey];
	
	return [[retval copy] autorelease];
}
- (id)initWithPlistRepresentation:(NSDictionary *)plistRepresentation {
	if (!(self = [super initWithPlistRepresentation:plistRepresentation]))
		return nil;
	
	_name = [[plistRepresentation objectForKey:WCGroupNameKey] copy];
	
	return self;
}
#pragma mark *** Public Methods ***
+ (id)groupWithFileURL:(NSURL *)fileURL name:(NSString *)name; {
	return [[[[self class] alloc] initWithFileURL:fileURL name:name] autorelease];
}
- (id)initWithFileURL:(NSURL *)fileURL name:(NSString *)name; {
	if (!(self = [super initWithFileURL:fileURL]))
		return nil;
	
	_name = [name copy];
	
	return self;
}
#pragma mark Properties
@synthesize name=_name;

@end
