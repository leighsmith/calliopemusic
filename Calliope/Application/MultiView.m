/* $Id$ */
#import "MultiView.h"

@implementation MultiView

- replaceView:newView
{
    NSPoint center;
    NSRect  rect;

    [optionView retain];//sb: because next command releases it!
    [optionView removeFromSuperview];    
    optionView = newView;
    [self addSubview:optionView];
    
    rect = [optionView frame];
    center.x = NSMinX([self bounds])+(NSWidth([self bounds])-NSWidth(rect))/2.0;
    center.y = NSMinY([self bounds])+(NSHeight([self bounds])-NSHeight(rect))/2.0;

    [optionView setFrameOrigin:center];

    [self setNeedsDisplay:YES];
    
    return self;
}

- (void) drawRect: (NSRect) rect
{
    NSEraseRect(rect);
    
    [[NSColor lightGrayColor] set];
    NSRectFill([self bounds]);
}

@end
