#import "winheaders.h"
#import <Foundation/Foundation.h>
#import <AppKit/NSWindow.h>
#import <AppKit/AppKit.h>

@interface CalliopeWindow : NSWindow
{
    NSBitmapImageRep *cachedImage;
    NSRect cachedRect;
    id subview;
}
- (NSRect)makeOriginLLH:(NSRect)originalRect;
@end
