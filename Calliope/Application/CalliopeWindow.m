#import "CalliopeWindow.h"

@implementation CalliopeWindow
- (id)_initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;
{
    id ret = [super initWithContentRect:(NSRect)contentRect
                              styleMask:(unsigned int)aStyle
                                backing:(NSBackingStoreType)bufferingType
                                  defer:(BOOL)flag];
    cachedImage = nil;
    subview = [[NSView alloc] init];
    [subview allocateGState];
    return ret;
}

- (void)_dealloc
{
    if (cachedImage) [cachedImage release];
    if (subview) [subview release];
    [super dealloc];
}

- (NSRect)makeOriginLLH:(NSRect)originalRect
{
    NSRect r = originalRect;
//    NSView *aView = [NSView focusView];
//    NSRect bounds = [aView bounds];

    if ( NSWidth(r) < 0 )
    {
        r.origin.x += NSWidth(r);
        r.size.width = 0 - r.size.width;
    }

    if ( NSHeight(r) < 0 )
    {
        r.origin.y += NSHeight(r);
        r.size.height = 0 - r.size.height;
    }
    if (NSMinX(r) < 0)
      {
        r.size.width += NSMinX(r);
        r.origin.x = 0;
      }
    if (NSMinY(r) < 0)
      {
        r.size.height += NSMinY(r);
        r.origin.y = 0;
      }
/*
    if (NSMaxX(r) > NSMaxX(bounds))
      {
        r.origin.x = MIN(r.origin.x,NSMaxX(bounds));
        r.size.width = NSMaxX(bounds) - r.origin.x;
      }
    if (NSMaxY(r) > NSMaxY(bounds))
      {
        r.origin.y = MIN(r.origin.y,NSMaxY(bounds));
        r.size.height = NSMaxY(bounds) - r.origin.y;
      }
 */
    return r;
}

- (void)discardCachedImage
{
    if (cachedImage) {
        [cachedImage release];
        cachedImage = nil;
    }
}

- (void)_cacheImageInRect:(NSRect)rect /* rect is in terms of window */
{
    NSRect cRect = [self makeOriginLLH:rect];
    NSView *conview = [self contentView];
//    NSView *subview = [[NSView alloc] initWithFrame:[conview bounds]];
    if (!NSEqualRects([subview frame],[conview bounds])) {
        [subview setFrame:[conview bounds]];
        [subview allocateGState];
    }
    [self discardCachedImage];

    [subview setPostsFrameChangedNotifications:NO];

    [conview addSubview:subview];
    [subview lockFocus];
    cRect = [subview convertRect:cRect fromView:nil];/* to get rid of bottom edge of window, not in contentView] */

        cRect.origin.x = (int)cRect.origin.x;
        cRect.origin.y = (int)cRect.origin.y;

        cachedImage = [[NSBitmapImageRep alloc] initWithFocusedViewRect:cRect];
    [subview unlockFocus];
    [subview removeFromSuperview];
    [conview setNeedsDisplay:NO];


    // should use NSCopyBits(srcGstate, srcRect, toPoint)?
//    cachedImage = [[NSBitmapImageRep alloc] initWithFocusedViewRect:cRect];
    cachedRect = cRect;
}

- (void)_restoreCachedImage
{
    NSView *aView = [NSView focusView];
    if (![aView isFlipped]) [cachedImage drawInRect:cachedRect];
    else {
        NSView *conview = [self contentView];
//        NSView *subview = [[NSView alloc] initWithFrame:[conview bounds]];
//        NSPoint theOrigin = cachedRect.origin;
        if (!NSEqualRects([subview frame],[conview bounds])) {
            [subview setFrame:[conview bounds]];
            [subview allocateGState];
        }
        [subview setPostsFrameChangedNotifications:NO];
        [conview addSubview:subview];
//        [subview lockFocus];
//        [cachedImage drawAtPoint:theOrigin];
//        [subview unlockFocus];
        [subview removeFromSuperview];
        [conview setNeedsDisplay:NO];
    }

    [self flushWindowIfNeeded];
    [[NSApp context] flush];
}


@end
