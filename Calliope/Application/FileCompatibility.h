#import "winheaders.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/List.h>
/*
 * This first one is only used by FileCompatibility.m and gvPasteboard.m.
 * It will not be required once gvPasteboard.m is changed to use
 * property lists as Draw's new pasteboard format.
 */

@interface NSMutableArray(Compatibility)

- (id)initFromList:(id)aList;

@end
