#import "SyncScrollView.h"
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
#import <AppKit/psops.h>


/*
 * Any View that responds to these messages can be a "ruler".
 */

@interface NSView(Ruler)
- hidePosition;				/* hide any positioning markers */
- showPosition:(float)p :(float)q;	/* positioning markers at p and q */
@end

#define GADGET_HEIGHT		16.0

@implementation SyncScrollView


- initWithFrame:(NSRect)frameRect
{
    id oldWindow;
    [super initWithFrame:frameRect];
    [NSBundle loadNibNamed:@"ScrollerGadgets.nib" owner:self];
    oldWindow = [pageUpButton window];
    [self addSubview:pageUpButton];
    [self addSubview:pageDownButton];
    [self addSubview:pageLabel];
    [self addSubview:pageForm];
    [self addSubview: zoomPopUpList];
    [self addSubview: pageFirstButton];
    [self addSubview: pageLastButton];
    [oldWindow release];
  //sb additions:
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(descendantFrameChanged:)
//                                                 name:NSViewFrameDidChangeNotification object:nil];

  return self;
}


/* Needs to be smaller than IB will allow to fit into the scroller. */


static void reSize(id p, float dh)
{
    NSRect r;
    r = [p frame];
    r.size.height = GADGET_HEIGHT + dh;
    [p setFrame:r];
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


/* messages from controls */

- prevPage: sender
{
    [[[[self contentView] documentView] viewWithTag:1] prevPage: sender];
    [[NSRunLoop currentRunLoop]  performSelector:@selector(makeFirstResponder:)
                                          target:[self window]
                                        argument:[[[self contentView] documentView] viewWithTag:1]
                                           order:0
                                           modes:[NSArray  arrayWithObject:NSDefaultRunLoopMode]];
    return self;
}


- nextPage: sender
{
    [[[[self contentView] documentView] viewWithTag:1] nextPage: sender];
    [[NSRunLoop currentRunLoop]  performSelector:@selector(makeFirstResponder:)
                                          target:[self window]
                                        argument:[[[self contentView] documentView] viewWithTag:1]
                                           order:0
                                           modes:[NSArray  arrayWithObject:NSDefaultRunLoopMode]];
    return self;
}


- firstPage: sender
{
    [[[[self contentView] documentView] viewWithTag:1] firstPage: sender];
    [[NSRunLoop currentRunLoop]  performSelector:@selector(makeFirstResponder:)
                                          target:[self window]
                                        argument:[[[self contentView] documentView] viewWithTag:1]
                                           order:0
                                           modes:[NSArray  arrayWithObject:NSDefaultRunLoopMode]];
    return self;
}


- lastPage: sender
{
    [[[[self contentView] documentView] viewWithTag:1] lastPage: sender];
    [[NSRunLoop currentRunLoop]  performSelector:@selector(makeFirstResponder:)
                                          target:[self window]
                                        argument:[[[self contentView] documentView] viewWithTag:1]
                                           order:0
                                           modes:[NSArray  arrayWithObject:NSDefaultRunLoopMode]];
    return self;
}


extern NSSize paperSize;

- setScale: sender
{	
    float i;
    i = [[sender selectedCell] tag];
    if (i == 127) i = 127.778;
    [pageLabel setStringValue:@""];
    [[[[self contentView] documentView] viewWithTag:1] scaleTo: i];
    [[NSRunLoop currentRunLoop]  performSelector:@selector(makeFirstResponder:)
                                          target:[self window]
                                        argument:[[[self contentView] documentView] viewWithTag:1]
                                           order:0
                                           modes:[NSArray  arrayWithObject:NSDefaultRunLoopMode]];
    return self;
}


- pageTo: sender
{
    int n=0;
    n = [[[[self contentView] documentView] viewWithTag:1] gotoPage: [[sender cellAtIndex:0] intValue]];
    if (n >= 0) [[pageForm cellAtIndex:0] setIntValue:n];
    [[NSRunLoop currentRunLoop]  performSelector:@selector(makeFirstResponder:)
                                        target:[self window]
                                      argument:[[[self contentView] documentView] viewWithTag:1]
                                           order:0
                                           modes:[NSArray  arrayWithObject:NSDefaultRunLoopMode]];
  return self;
}


- setPageNum: (int) p
{
    [[pageForm cellAtIndex:0] setIntValue:p];
    return [pageForm cellAtIndex:0];
}


- setScaleNum: (int) i
{
    int c;
    if (i == 127) c = [zoomPopUpList indexOfItemWithTitle:@"127.778%"];
    else c = [zoomPopUpList indexOfItemWithTitle:[NSString stringWithFormat:@"%d%",i]];
    if (c == -1)
      {
        [zoomPopUpList setTitle:@"Other:"];
        [pageLabel setIntValue:i];
      }
  else
    {
      [zoomPopUpList selectItemAtIndex:c];
      [zoomPopUpList synchronizeTitleAndSelectedItem];
      [pageLabel setStringValue:@""];
    }
    return self;
}


- setMessage: (NSString *) s
{
    [pageLabel setStringValue:s];
    return pageLabel;
}


- setRulerClass:factoryId
{
    rulerClass = factoryId;
    return self;
}

- setRulerWidths:(float)horizontal :(float)vertical
{
    horizontalRulerWidth = horizontal;
    verticalRulerWidth = vertical;
    return self;
}

- (BOOL)bothRulersAreVisible
{
    return verticalRulerIsVisible && horizontalRulerIsVisible;
}

- (BOOL)eitherRulerIsVisible
{
    return verticalRulerIsVisible || horizontalRulerIsVisible;
}

- (BOOL)verticalRulerIsVisible
{
    return verticalRulerIsVisible;
}

- (BOOL)horizontalRulerIsVisible
{
    return horizontalRulerIsVisible;
}


/*
 * This makes the rulers.
 * We do this lazily in case the user never asks for the rulers.
 */
 
- makeRulers
{
    id ruler;
    NSRect aRect, bRect;
    GraphicView *v = [[[self contentView] documentView] viewWithTag:1];

//    if (!rulerClass || (!horizontalRulerWidth && !verticalRulerWidth)) return nil;
    [self setHasHorizontalRuler:YES];
    [self setHasVerticalRuler:YES];
    hClipRuler = [self horizontalRulerView];
    vClipRuler = [self verticalRulerView];
    [hClipRuler setClientView:v];
    [vClipRuler setClientView:v];
    [self setRulersVisible:YES];

#if 0
    if (horizontalRulerWidth) {
	aRect = [v frame];
	NSDivideRect(aRect , &bRect , &aRect , horizontalRulerWidth, NSMinYEdge);
	hClipRuler = [[NSClipView allocWithZone:[self zone]] init];
	ruler = [[rulerClass allocWithZone:[self zone]] initWithFrame:bRect];
	[hClipRuler setDocumentView:ruler];
    }
    if (verticalRulerWidth) {
	aRect = [v frame];
	NSDivideRect(aRect , &bRect , &aRect , verticalRulerWidth, NSMinXEdge);
	vClipRuler = [[NSClipView allocWithZone:[self zone]] init];
	ruler = [[rulerClass allocWithZone:[self zone]] initWithFrame:bRect];
	[vClipRuler setDocumentView:ruler];
    }
#endif
    rulersMade = YES;

    return self;
}


- updateRulers:(const NSRect *)rect
{
    printf("update rulers\n");
    if (!rect)
      {
        if (verticalRulerIsVisible) [[vClipRuler documentView] hidePosition];
        if (horizontalRulerIsVisible) [[hClipRuler documentView] hidePosition];
      }
    else
      {
        /* this should flip and scale the point: */
        id gv = [[self documentView] viewWithTag:1];
        float maxY = NSMaxY([gv bounds]);
        float scaler = [gv rulerScale];
        if (verticalRulerIsVisible)
            [[vClipRuler documentView] showPosition:(maxY - (rect->origin.y + rect->size.height))/scaler
                                                   :(maxY - rect->origin.y)/scaler];
        if (horizontalRulerIsVisible)
            [[hClipRuler documentView] showPosition:rect->origin.x/scaler
                                                   :(rect->origin.x + rect->size.width) /scaler];
      }
    return self;
}

- (void)updateRuler
{
    NSRect aRect, bRect;
    printf("update ruler\n");
    if (horizontalRulerIsVisible) {
        aRect = [[[self documentView] viewWithTag:1] frame];
	NSDivideRect(aRect , &bRect , &aRect , horizontalRulerWidth, NSMinYEdge);
	bRect.size.width += verticalRulerWidth;
	[[hClipRuler documentView] setFrame:bRect];
        [hClipRuler setNeedsDisplay:YES];
    }
    if (verticalRulerIsVisible) {
        aRect = [[[self documentView] viewWithTag:1] frame];
	NSDivideRect(aRect , &bRect , &aRect , verticalRulerWidth, NSMinXEdge);
	[[vClipRuler documentView] setFrame:bRect];
        [vClipRuler setNeedsDisplay:YES];
    }

    return;
}


/*
 * Adds or removes a ruler from the view hierarchy.
 * Returns whether or not it succeeded in doing so.
 */
 
- (BOOL)showRuler:(BOOL)showIt isHorizontal:(BOOL)isHorizontal
{
    id ruler;
    BOOL isVisible;
    NSRect cRect, rRect;

    isVisible = isHorizontal ? horizontalRulerIsVisible : verticalRulerIsVisible;
    if ((showIt && isVisible) || (!showIt && !isVisible)) return NO;
    if (showIt && !rulersMade && ![self makeRulers]) return NO;
    ruler = isHorizontal ? hClipRuler : vClipRuler;

    if (!showIt && isVisible) {
	[ruler removeFromSuperview];
	if (isHorizontal) {
	    horizontalRulerIsVisible = NO;
	} else {
	    verticalRulerIsVisible = NO;
	}
    } else if (showIt && !isVisible && ruler) {
	[self addSubview:ruler];
        cRect = [[self contentView] bounds];
	rRect = [hClipRuler bounds];
	[hClipRuler setBoundsOrigin:NSMakePoint(cRect.origin.x, rRect.origin.y)];
	rRect = [vClipRuler bounds];
	[vClipRuler setBoundsOrigin:NSMakePoint(rRect.origin.x, cRect.origin.y)];
	if (isHorizontal) {
	    horizontalRulerIsVisible = YES;
	} else {
	    verticalRulerIsVisible = YES;
	}
    }

    return YES;
}


- adjustSizes
{
    id windelegate;
    NSRect winFrame;
    NSWindow *window = [self window];
    printf("adjustSizes\n");
    windelegate = [window delegate];
    if ([windelegate respondsToSelector:@selector(windowWillResize:toSize:)])
      {
        winFrame = [window frame];
        winFrame.size = [windelegate windowWillResize:window toSize:winFrame.size];
        [window setFrame:winFrame display:NO];
      }

    [self resizeSubviewsWithOldSize:NSZeroSize];
    return self;
}


- (void)showHorizontalRuler:(BOOL)flag
{
    if ([self showRuler:flag isHorizontal:YES]) [self adjustSizes];
}


- (void)showVerticalRuler:(BOOL)flag
{
    if ([self showRuler:flag isHorizontal:NO]) [self adjustSizes];
}


/*
 * If both rulers are visible, they are both hidden.
 * Otherwise, both rulers are made visible.
 */

- (void)showHideRulers:sender
{
    BOOL resize = NO;

    if (verticalRulerIsVisible && horizontalRulerIsVisible) {
	resize = [self showRuler:NO isHorizontal:YES];
	resize = [self showRuler:NO isHorizontal:NO] || resize;
    } else {
	if (!horizontalRulerIsVisible) resize = [self showRuler:YES isHorizontal:YES];
	if (!verticalRulerIsVisible) resize = [self showRuler:YES isHorizontal:NO] || resize;
    }
    if (resize) [self adjustSizes];
}



/* ScrollView-specific stuff */


- (void)dealloc
{
    if (!horizontalRulerIsVisible) [hClipRuler release];
    if (!verticalRulerIsVisible) [vClipRuler release];
    { [super dealloc]; return; };    
}


/*
 * We only reflect scroll in the contentView, not the rulers.
*/

- (void)reflectScrolledClipView:(NSClipView *)cView
{
    if (cView != hClipRuler && cView != vClipRuler) [super reflectScrolledClipView:cView];
}


/*
 * Here is where we lay out the subviews of the ScrollView.
 * Note the use of NXDivideRect() to "slice off" a section of
 * a rectangle.  This is useful since the two scrollers each
 * result in slicing a section off the contentView of the
 * ScrollView.
 */

- (void)tile
{
    NSRect aRect, bRect, cRect;
    float zoom_width, page_label_width, page_cell_width;
    float y;
    printf("tile\n");
    [super tile];
	/* take the zoom popup list & page display into account on the horizontal scroller */
	aRect = [[self horizontalScroller] frame];
	cRect = [zoomPopUpList frame];
	zoom_width = cRect.size.width;
	cRect = [pageLabel frame];
	page_label_width = cRect.size.width;
	cRect = [pageForm frame];
	page_cell_width = cRect.size.width;
	aRect.size.width -= zoom_width + page_label_width + page_cell_width;
	[[self horizontalScroller] setFrame:aRect];
	/* position the zoom popup list in the correct place */
	aRect.origin.x += aRect.size.width;
	aRect.size.width = zoom_width;
	horzScrollerArea = aRect;
	horzScrollerArea.size.width += page_label_width + page_cell_width;
	[zoomPopUpList setFrameOrigin:NSMakePoint(aRect.origin.x, aRect.origin.y +1.0)];
	/* position the page display after the popuplist in the horizontal scroller */
	aRect.origin.x += zoom_width;
	aRect.size.width = page_cell_width;
	[pageForm setFrameOrigin:NSMakePoint(aRect.origin.x, aRect.origin.y)];
	aRect.origin.x += page_cell_width;
	aRect.origin.y += 3.0;
	aRect.size.width = page_label_width;
	[pageLabel setFrameOrigin:NSMakePoint(aRect.origin.x, aRect.origin.y)];
	/* take the page up/down buttons into account on the vertical scroller */
	aRect = [[self verticalScroller] frame];
	aRect.size.height -= (4.0 * GADGET_HEIGHT) + 4.0;
	[[self verticalScroller] setFrame:aRect];
	/* position the buttons in the correct place */
	aRect.origin.y += aRect.size.height;
	vertScrollerArea = aRect;
	aRect.size.height = (4.0 * GADGET_HEIGHT) + 4.0;
	y = aRect.origin.y;
	[pageFirstButton setFrameOrigin:NSMakePoint(1.0, y)];
	[pageUpButton setFrameOrigin:NSMakePoint(1.0, y + GADGET_HEIGHT + 1.0)];
	[pageDownButton setFrameOrigin:NSMakePoint(1.0, y + (2.0 * GADGET_HEIGHT) + 2.0)];
	[pageLastButton setFrameOrigin:NSMakePoint(1.0, y + (3.0 * GADGET_HEIGHT) + 3.0)];
  if (horizontalRulerIsVisible || verticalRulerIsVisible)
  {
      aRect = [[self contentView] frame];
      cRect = [[[self documentView] viewWithTag:1] frame];
    if (horizontalRulerIsVisible && hClipRuler)
    {
      NSDivideRect(aRect , &bRect , &aRect , horizontalRulerWidth, NSMinYEdge);
      [hClipRuler setFrame:bRect];
      [[hClipRuler documentView] setFrameSize:NSMakeSize(cRect.size.width+verticalRulerWidth, bRect.size.height)];
    }
    if (verticalRulerIsVisible && vClipRuler)
    {
      NSDivideRect(aRect , &bRect , &aRect , verticalRulerWidth, NSMinXEdge);
      [vClipRuler setFrame:bRect];
      [[vClipRuler documentView] setFrameSize:NSMakeSize(bRect.size.width, cRect.size.height)];
    }
    [[self contentView] setFrame:aRect];
  }
}


/*
 * This is sent to us instead of rawScroll:.
 * We scroll the two rulers, then the clipView itself.
 */
 
- (void)scrollClipView:(NSClipView *)aClipView toPoint:(NSPoint)aPoint
{
    id fr;
    NSRect rRect;
    id window = [self window];
#ifdef DEBUG
    printf("scroll to vertical?: %g\n",aPoint.y);
#endif
    if (aClipView != [self contentView]) return;
#ifdef DEBUG
    printf("scroll to vertical OK: %g\n",aPoint.y);
#endif
    [window disableFlushWindow];
    if (horizontalRulerIsVisible && hClipRuler)
      {
        rRect = [hClipRuler bounds];
        rRect.origin.x = aPoint.x;
        [hClipRuler scrollToPoint:(rRect.origin)];
      }
    if (verticalRulerIsVisible && vClipRuler)
      {
        rRect = [vClipRuler bounds];
        rRect.origin.y = aPoint.y;
        [vClipRuler scrollToPoint:(rRect.origin)];
      }
    [aClipView scrollToPoint:aPoint];

    fr = [[self window] firstResponder];
    if ([fr respondsToSelector:@selector(isRulerVisible)] && [fr isRulerVisible]) [fr updateRuler]; // keeps Text ruler up-to-date

    [window enableFlushWindow];
    [window flushWindow];

}


/*
 * Any time the docView is resized, this method is
 * called to update the size of the rulers to be equal to
 * the size of the docView.
 */
 
//- (void)descendantFrameChanged:(NSNotification *)notification
- (void)viewFrameChanged:(NSNotification *)notification
{
    NSRect aRect, bRect, cRect;
    NSView *changedView = [notification object];
    printf("descendantFrameChanged\n");
    if (changedView == [[[self documentView] viewWithTag:1] superview]) {
        printf("(the one we wanted)\n");

        if (horizontalRulerIsVisible || verticalRulerIsVisible) {
            aRect = [[self contentView] frame];
            cRect = [[[self documentView] viewWithTag:1] frame];
            if (horizontalRulerIsVisible && hClipRuler) {
                NSDivideRect(aRect , &bRect , &aRect , horizontalRulerWidth, NSMinYEdge);
                [[hClipRuler documentView] setFrameSize:NSMakeSize(cRect.size.width+verticalRulerWidth, bRect.size.height)];
                }
            if (verticalRulerIsVisible && vClipRuler) {
                NSDivideRect(aRect , &bRect , &aRect , verticalRulerWidth, NSMinXEdge);
                [[vClipRuler documentView] setFrameSize:NSMakeSize(bRect.size.width, cRect.size.height)];
                }
        }
    }
}

/*
  We need to override drawSelf to make the background behind the new gadgets 
  grey instead of the default white
*/

- (void)drawRect:(NSRect)rect
{
#ifdef DEBUG
//    printf("SyncScrollView drawRect\n");
#endif
    PSsetgray(NSLightGray);
    NSRectFill(vertScrollerArea);
    NSRectFill(horzScrollerArea);
    [super drawRect:rect];
}

@end
