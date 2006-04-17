/* $Id$ */
#import "PageScrollView.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVCommands.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSForm.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSText.h>


/*
 * Any View that responds to these messages can be a "ruler".
 */

@interface NSView(Ruler)
- hidePosition;				/* hide any positioning markers */
- showPosition: (float)p : (float)q;	/* positioning markers at p and q */
@end

// TODO should be determined from the NIB button frame height.
#define GADGET_HEIGHT		16.0 

@implementation PageScrollView

- (void) initialiseControls
{
    // Assuming all IB outlets will be connected up before this class is initialised.
    [self addSubview: pageLabel];
    [self addSubview: pageForm];
    [self addSubview: zoomPopUpList];
    [self addSubview: pageFirstButton];
    [self addSubview: pageUpButton];
    [self addSubview: pageDownButton];
    [self addSubview: pageLastButton];
    
    //sb additions:
    //    [[NSNotificationCenter defaultCenter] addObserver: self
    //                                             selector:@selector(descendantFrameChanged: )
    //                                                 name: NSViewFrameDidChangeNotification object: nil];    
}


/* Needs to be smaller than IB will allow to fit into the scroller. */


static void reSize(id p, float dh)
{
    NSRect r;
    r = [p frame];
    r.size.height = GADGET_HEIGHT + dh;
    [p setFrame: r];
}


- setZoomPopUpList: sender
{
    zoomPopUpList = sender;
    reSize(sender, 0.0);
    return self;
}


- setPageForm: sender
{
    pageForm = sender;
    reSize(sender, 4.0);
    return self;
}


- setPageLabel: sender
{
    pageLabel = sender;
    reSize(sender, 4.0);
    return self;
}

- setScale: sender
{	
    float i;
    i = [[sender selectedCell] tag];
    if (i == 127) i = 127.778;
    [pageLabel setStringValue: @""];
    [[[[self contentView] documentView] viewWithTag: 1] scaleTo: i];
    [[NSRunLoop currentRunLoop]  performSelector: @selector(makeFirstResponder:)
                                          target: [self window]
                                        argument: [[[self contentView] documentView] viewWithTag: 1]
                                           order: 0
                                           modes: [NSArray  arrayWithObject: NSDefaultRunLoopMode]];
    return self;
}


- pageTo: sender
{
    int n=0;
    n = [[[[self contentView] documentView] viewWithTag: 1] gotoPage: [[sender cellAtIndex:0] intValue]];
    if (n >= 0) [[pageForm cellAtIndex: 0] setIntValue: n];
    [[NSRunLoop currentRunLoop]  performSelector: @selector(makeFirstResponder:)
					  target: [self window]
					argument: [[[self contentView] documentView] viewWithTag: 1]
                                           order: 0
                                           modes: [NSArray  arrayWithObject: NSDefaultRunLoopMode]];
    return self;
}


- (void) setPageNumber: (int) p
{
    [[pageForm cellAtIndex: 0] setIntValue: p];
}


- setScaleNum: (int) i
{
    int c;
    
    if (i == 127) c = [zoomPopUpList indexOfItemWithTitle: @"127.778%"];
    else c = [zoomPopUpList indexOfItemWithTitle: [NSString stringWithFormat: @"%d%",i]];
    if (c == -1)
    {
        [zoomPopUpList setTitle:@"Other: "];
        [pageLabel setIntValue: i];
    }
    else
    {
	[zoomPopUpList selectItemAtIndex: c];
	[zoomPopUpList synchronizeTitleAndSelectedItem];
	[pageLabel setStringValue: @""];
    }
    return self;
}


- (void) setMessage: (NSString *) s
{
    [pageLabel setStringValue: s];
}


- setRulerClass: factoryId
{
    rulerClass = factoryId;
    return self;
}

- (BOOL) bothRulersAreVisible
{
    return verticalRulerIsVisible && horizontalRulerIsVisible;
}

- (BOOL) eitherRulerIsVisible
{
    return verticalRulerIsVisible || horizontalRulerIsVisible;
}

- (BOOL) verticalRulerIsVisible
{
    return verticalRulerIsVisible;
}

- (BOOL) horizontalRulerIsVisible
{
    return horizontalRulerIsVisible;
}


/*
 * This makes the rulers.
 * We do this lazily in case the user never asks for the rulers.
 */

- makeRulers
{
    GraphicView *v = [[[self contentView] documentView] viewWithTag: 1];
    
    //    if (!rulerClass || (!horizontalRulerWidth && !verticalRulerWidth)) return nil;
    [self setHasHorizontalRuler: YES];
    [self setHasVerticalRuler: YES];
    hRuler = [self horizontalRulerView];
    [hRuler setReservedThicknessForMarkers: 0.0];
    vRuler = [self verticalRulerView];
    [hRuler setClientView: v];
    [vRuler setClientView: v];
    //    [self setRulersVisible: YES];
    
    rulersMade = YES;
    
    return self;
}

- (void) drawRulerlinesWithRect: (NSRect) aRect
{
    NSRect convRect;
    id gv = [[self documentView] viewWithTag: 1];
    
    if (hRuler) {
        convRect = [gv convertRect: aRect toView: hRuler];
	
        [hRuler moveRulerlineFromLocation: -1.0
			       toLocation: NSMinX(convRect)];
        [hRuler moveRulerlineFromLocation: -1.0
			       toLocation: NSMaxX(convRect)];
    }
    if (vRuler) {
        convRect = [gv convertRect: aRect toView: vRuler];
	
        [vRuler moveRulerlineFromLocation: -1.0
			       toLocation: NSMinY(convRect)];
        [vRuler moveRulerlineFromLocation: -1.0
			       toLocation: NSMaxY(convRect)];
    }
}

- (void) updateRulerlinesWithOldRect: (NSRect) oldRect newRect: (NSRect) newRect
{
    NSRect convOldRect, convNewRect;
    id gv = [[self documentView] viewWithTag: 1];
    
    if (hRuler) {
        convOldRect = [gv convertRect: oldRect toView: hRuler];
        convNewRect = [gv convertRect: newRect toView: hRuler];
        [hRuler moveRulerlineFromLocation: NSMinX(convOldRect)
			       toLocation: NSMinX(convNewRect)];
        [hRuler moveRulerlineFromLocation: NSMaxX(convOldRect)
			       toLocation: NSMaxX(convNewRect)];
    }
    if (vRuler) {
        convOldRect = [gv convertRect: oldRect toView: vRuler];
        convNewRect = [gv convertRect: newRect toView: vRuler];
        [vRuler moveRulerlineFromLocation: NSMinY(convOldRect)
			       toLocation: NSMinY(convNewRect)];
        [vRuler moveRulerlineFromLocation: NSMaxY(convOldRect)
			       toLocation: NSMaxY(convNewRect)];
    }
}

- (void) eraseRulerlines
{
    if (hRuler) {
        [hRuler setNeedsDisplay: YES]; /* gets rid of instance drawing (highlighting of Rulerlines) */
    }
    if (vRuler) {
        [vRuler setNeedsDisplay: YES];
    }
    return;
}

- updateRulers: (const NSRect *) rect
{
    // NSLog(@"update rulers\n");
    if ([self rulersVisible]) {
	if (!rect)
	{
	    if (rulerlineRect.origin.x != -1) {
		[self eraseRulerlines];
		rulerlineRect.origin.x = rulerlineRect.origin.y = -1;
	    }
	}
	else
	{
	    if (rulerlineRect.origin.x == -1)
		[self drawRulerlinesWithRect: (NSRect)*rect];
	    else [self updateRulerlinesWithOldRect: (NSRect)rulerlineRect newRect: (NSRect)*rect];
	    rulerlineRect = *rect;
	}
    }
    return self;
}

- (void) updateRuler
{
    NSLog(@"update ruler\n");
    return;
}


/*
 * Adds or removes a ruler from the view hierarchy.
 * Returns whether or not it succeeded in doing so.
 */
- (BOOL) showRuler: (BOOL) showIt isHorizontal: (BOOL) isHorizontal
{
    if (showIt && !rulersMade && ![self makeRulers]) return NO;
    return YES;
}


- adjustSizes
{
    id windelegate;
    NSRect winFrame;
    NSWindow *window = [self window];
    NSLog(@"adjustSizes\n");
    windelegate = [window delegate];
    if ([windelegate respondsToSelector:@selector(windowWillResize:toSize: )])
    {
        winFrame = [window frame];
        winFrame.size = [windelegate windowWillResize: window toSize: winFrame.size];
        [window setFrame: winFrame display: NO];
    }
    
    [self resizeSubviewsWithOldSize: NSZeroSize];
    return self;
}

/*
 * If both rulers are visible, they are both hidden.
 * Otherwise, both rulers are made visible.
 */
- (void) showHideRulers: sender
{
    if (!rulersMade) [self makeRulers];
    [self setRulersVisible: ![self rulersVisible]];
}


/* ScrollView-specific stuff */


/*
 * We only reflect scroll in the contentView, not the rulers.
 */
- (void) reflectScrolledClipView: (NSClipView *)cView
{
    if (cView != hRuler && cView != vRuler) [super reflectScrolledClipView: cView];
}


- (void) tileHorizontalScroller
{
    NSRect aRect, cRect;
    float zoom_width, page_label_width, page_cell_width;

    /* take the zoom popup list & page display into account on the horizontal scroller */
    aRect = [[self horizontalScroller] frame];
    cRect = [zoomPopUpList frame];
    zoom_width = cRect.size.width;
    cRect = [pageLabel frame];
    page_label_width = cRect.size.width;
    cRect = [pageForm frame];
    page_cell_width = cRect.size.width;
    aRect.size.width -= zoom_width + page_label_width + page_cell_width;
    [[self horizontalScroller] setFrame: aRect];
    
    /* position the zoom popup list in the correct place */
    aRect.origin.x += aRect.size.width;
    aRect.size.width = zoom_width;
    horzScrollerArea = aRect;
    horzScrollerArea.size.width += page_label_width + page_cell_width;
    [zoomPopUpList setFrameOrigin: NSMakePoint(aRect.origin.x, aRect.origin.y + 1.0)];
    
    /* position the page display after the popuplist in the horizontal scroller */
    aRect.origin.x += zoom_width;
    aRect.size.width = page_cell_width;
    [pageForm setFrameOrigin: NSMakePoint(aRect.origin.x, aRect.origin.y)];
    aRect.origin.x += page_cell_width;
    aRect.origin.y += 3.0;
    aRect.size.width = page_label_width;
    [pageLabel setFrameOrigin: NSMakePoint(aRect.origin.x, aRect.origin.y)];    
}

- (void) tileVerticalScroller
{
    NSRect verticalScrollerFrame;
    
    /* take the page up/down buttons into account on the vertical scroller */
    verticalScrollerFrame = [[self verticalScroller] frame];
    verticalScrollerFrame.size.height -= (4.0 * GADGET_HEIGHT) + 4.0;
    [[self verticalScroller] setFrame: verticalScrollerFrame];
    
    /* position the buttons in the correct place */
    verticalScrollerFrame.origin.y += verticalScrollerFrame.size.height;
    vertScrollerArea = verticalScrollerFrame;
    verticalScrollerFrame.size.height = (4.0 * GADGET_HEIGHT) + 4.0;
    
    [pageFirstButton setFrameOrigin: NSMakePoint(verticalScrollerFrame.origin.x, verticalScrollerFrame.origin.y)];
    [pageUpButton    setFrameOrigin: NSMakePoint(verticalScrollerFrame.origin.x, verticalScrollerFrame.origin.y + GADGET_HEIGHT + 1.0)];
    [pageDownButton  setFrameOrigin: NSMakePoint(verticalScrollerFrame.origin.x, verticalScrollerFrame.origin.y + (2.0 * GADGET_HEIGHT) + 2.0)];
    [pageLastButton  setFrameOrigin: NSMakePoint(verticalScrollerFrame.origin.x, verticalScrollerFrame.origin.y + (3.0 * GADGET_HEIGHT) + 3.0)];    
}

/*
 * Here is where we lay out the subviews of the NSScrollView.
 * Note the use of NSDivideRect() to "slice off" a section of
 * a rectangle.  This is useful since the two scrollers each
 * result in slicing a section off the contentView of the
 * NSScrollView.
 */
- (void) tile
{
    
    NSLog(@"tile");
    [super tile];
    
    [self tileHorizontalScroller];
    [self tileVerticalScroller];
    
#if 0
    if (horizontalRulerIsVisible || verticalRulerIsVisible) {
	NSRect aRect = [[self contentView] frame];
	NSRect cRect = [[[self documentView] viewWithTag: 1] frame];
	
	if (horizontalRulerIsVisible && hRuler)	{
	    NSDivideRect(aRect, &bRect, &aRect, horizontalRulerWidth, NSMinYEdge);
	    [hRuler setFrame: bRect];
	    [[hRuler documentView] setFrameSize: NSMakeSize(cRect.size.width+verticalRulerWidth, bRect.size.height)];
	}
	if (verticalRulerIsVisible && vRuler) {
	    NSDivideRect(aRect, &bRect, &aRect, verticalRulerWidth, NSMinXEdge);
	    [vRuler setFrame: bRect];
	    [[vRuler documentView] setFrameSize: NSMakeSize(bRect.size.width, cRect.size.height)];
	}
	[[self contentView] setFrame: aRect];
    }
#endif
}


/*
 * This is sent to us instead of rawScroll:.
 * We scroll the two rulers, then the clipView itself.
 */

- (void) scrollClipView: (NSClipView *)aClipView toPoint: (NSPoint)aPoint
{
    id fr;
    id window = [self window];
    
#ifdef DEBUG
    NSLog(@"scroll to vertical?: %g\n",aPoint.y);
#endif
    if (aClipView != [self contentView]) return;
#ifdef DEBUG
    NSLog(@"scroll to vertical OK: %g\n",aPoint.y);
#endif
    [window disableFlushWindow];
#if 0
    
    if (horizontalRulerIsVisible && hRuler)
    {
        rRect = [hRuler bounds];
        rRect.origin.x = aPoint.x;
        [hRuler scrollToPoint: (rRect.origin)];
    }
    if (verticalRulerIsVisible && vRuler)
    {
        rRect = [vRuler bounds];
        rRect.origin.y = aPoint.y;
        [vRuler scrollToPoint: (rRect.origin)];
    }
#endif
    
    [aClipView scrollToPoint: aPoint];
    
    fr = [[self window] firstResponder];
    if ([fr respondsToSelector: @selector(isRulerVisible)] && [fr isRulerVisible]) [fr updateRuler]; // keeps Text ruler up-to-date
    
    [window enableFlushWindow];
    [window flushWindow];
    
}


/*
 * Any time the docView is resized, this method is
 * called to update the size of the rulers to be equal to
 * the size of the docView.
 */
//- (void)descendantFrameChanged: (NSNotification *)notification
- (void) viewFrameChanged: (NSNotification *) notification
{
    NSRect aRect, bRect, cRect;
    NSView *changedView = [notification object];
    
    NSLog(@"descendantFrameChanged\n");
    if (changedView == [[[self documentView] viewWithTag: 1] superview]) {
        NSLog(@"(the one we wanted)\n");
	
        if (horizontalRulerIsVisible || verticalRulerIsVisible) {
            aRect = [[self contentView] frame];
            cRect = [[[self documentView] viewWithTag: 1] frame];
            if (horizontalRulerIsVisible && hRuler) {
                NSDivideRect(aRect, &bRect, &aRect, horizontalRulerWidth, NSMinYEdge);
                [[hRuler documentView] setFrameSize: NSMakeSize(cRect.size.width+verticalRulerWidth, bRect.size.height)];
	    }
            if (verticalRulerIsVisible && vRuler) {
                NSDivideRect(aRect, &bRect, &aRect, verticalRulerWidth, NSMinXEdge);
                [[vRuler documentView] setFrameSize: NSMakeSize(bRect.size.width, cRect.size.height)];
	    }
        }
    }
}

/*
 We need to override drawRect: to make the background behind the new gadgets 
 grey instead of the default white
 */
- (void) drawRect: (NSRect) rect
{
#ifdef DEBUG
    // NSLog(@"PageScrollView drawRect\n");
#endif
    [[NSColor lightGrayColor] set];
    NSRectFill(vertScrollerArea);
    NSRectFill(horzScrollerArea);
    [super drawRect: rect];
}

@end
