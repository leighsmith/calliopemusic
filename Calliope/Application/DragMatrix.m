/*
*/
#import <AppKit/AppKit.h>
#import "DragMatrix.h"
#import "FlippedView.h"

@implementation DragMatrix


/* #defines stolen from Draw */

#define startTimer(timer) if (!timer) { [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.01]; timer = TRUE; }

#define stopTimer(timer) if (timer) { \
    [NSEvent stopPeriodicEvents]; \
    timer = FALSE; \
}

#define MOVE_MASK NSLeftMouseUpMask|NSLeftMouseDraggedMask

- init
{
    activeCell = matrixCache = cellCache = matrixCacheImage = cellCacheImage = nil;
    [self setupCacheWindows];
    return [super init];
}

- (void)dealloc
{
    [matrixCache release];
    [cellCache release];
    [matrixCacheImage release];
    [cellCacheImage release];
  [super dealloc];
  return;
}


- (void)mouseDown:(NSEvent *)theEvent 
{
    NSPoint		mouseDownLocation, mouseUpLocation, mouseLocation, alternateLocation;
    int			/*eventMask,*/ row, column, newRow;
    NSRect		visibleRect, cellCacheBounds, cellFrame,origCellFrame;
    id			aCell;
    float		dy;
    NSEvent *event, *peek=nil;
    BOOL timer=FALSE;
    BOOL		scrolled = NO;
    BOOL wasTimerEvent = FALSE;
    
  /* if the Control key isn't down, show normal behavior */
    if (!([theEvent modifierFlags] & NSControlKeyMask)) {
	[super mouseDown:theEvent];
	return;
    }
    
  /* prepare the cell and matrix cache windows */
    [self setupCacheWindows];
    
  /* we're now interested in mouse dragged events */

  /* find the cell that got clicked on and select it */
    mouseDownLocation = [theEvent locationInWindow];
    mouseDownLocation = [self convertPoint:mouseDownLocation fromView:nil];
    [self getRow:&row column:&column forPoint:mouseDownLocation];
    activeCell = [[self cellAtRow:row column:column] retain];//sb: retain because the old position will get released when moving
    [self selectCell:activeCell];
    origCellFrame = cellFrame = [self cellFrameAtRow:row column:column];
    
  /* do whatever's required for a single-click */
    [self sendAction];

    printf("ActiveCell %p\n",activeCell);
    
  /* draw a "well" in place of the selected cell (see drawSelf::) */
//    [self displayRect:cellFrame];
    
  /* copy what's currently visible into the matrix cache */
//    matrixCacheContentView = [matrixCache contentView];
    [matrixCacheImage lockFocus];//sb;
        [self drawRect:[self visibleRect]];
//    visibleRect = [self visibleRect];
//    visibleRect = [self convertRect:visibleRect toView:nil];
//    PScomposite(NSMinX(visibleRect), NSMinY(visibleRect),
//    		NSWidth(visibleRect), NSHeight(visibleRect),
//		[[self window] gState], 0.0, NSHeight(visibleRect), NSCompositeCopy);
//    [matrixCacheContentView unlockFocus];
        [matrixCacheImage unlockFocus];//sb;

#if 0
            /* image the cell into its cache */
//    cellCacheContentView = [cellCache contentView];
//    [cellCacheContentView lockFocus];
    [cellCache lockFocus];
//    cellCacheBounds = [cellCacheContentView bounds];
    cellCacheBounds = [cellCache bounds];
//    [activeCell drawWithFrame:cellCacheBounds inView:cellCacheContentView];
    [activeCell drawWithFrame:cellCacheBounds inView:cellCache];
//    [cellCacheContentView unlockFocus];
    [cellCache unlockFocus];
#endif
  /* save the mouse's location relative to the cell's origin */
    dy = mouseDownLocation.y - cellFrame.origin.y;
    
  /* from now on we'll be drawing into ourself */
    [self lockFocus];
    
    event = theEvent;
    while ([event type] != NSLeftMouseUp) {
      
      /* erase the active cell using the image in the matrix cache */
	visibleRect = [self visibleRect];
//	PScomposite(NSMinX(cellFrame), NSHeight(visibleRect) -
//		    NSMinY(cellFrame) + NSMinY(visibleRect) -
//		    NSHeight(cellFrame), NSWidth(cellFrame),
//		    NSHeight(cellFrame), [matrixCache gState],
//		    NSMinX(cellFrame), NSMinY(cellFrame) + NSHeight(cellFrame),
//		    NSCompositeCopy);
	
        printf("matrixCacheImage before blatting on moving cell: %g %g %g %g visRectHeight %g\n", cellFrame.origin.x,cellFrame.origin.y,NSWidth(cellFrame),NSHeight(cellFrame),NSHeight(visibleRect));
#if 0
        [matrixCacheImage compositeToPoint:NSMakePoint(NSMinX(cellFrame), NSMinY(cellFrame) + NSHeight(cellFrame))
                                   fromRect:NSMakeRect(NSMinX(cellFrame), NSHeight(visibleRect) -
                                                       NSMinY(cellFrame) + NSMinY(visibleRect) - NSHeight(cellFrame),
                                                       NSWidth(cellFrame),NSHeight(cellFrame))
                                                       operation:NSCompositeCopy];
        [matrixCacheImage compositeToPoint:NSMakePoint(NSMinX(cellFrame)+10, 10+NSMinY(cellFrame) + NSHeight(cellFrame))
                                  fromRect:NSMakeRect(NSMinX(cellFrame), NSHeight(visibleRect) - NSHeight(cellFrame)
                                                      - NSMinY(cellFrame),
                                                      NSWidth(cellFrame),NSHeight(cellFrame))
                                                       operation:NSCompositeCopy];

#endif
        [matrixCacheImage compositeToPoint:NSMakePoint(NSMinX(cellFrame)+5, NSHeight(visibleRect))
                                  fromRect:NSMakeRect(0, 0,
                                                      NSWidth(visibleRect),50)
                                                       operation:NSCompositeCopy];

        /* move the active cell */
	mouseLocation = [event locationInWindow];
	mouseLocation = [self convertPoint:mouseLocation fromView:nil];
	cellFrame.origin.y = mouseLocation.y - dy;
	
      /* constrain the cell's location to our bounds */
	if (NSMinY(cellFrame) < NSMinX([self bounds]) ) {
	    cellFrame.origin.y = NSMinX([self bounds]);
	} else if (NSMaxY(cellFrame) > NSMaxY([self bounds])) {
	    cellFrame.origin.y = NSHeight([self bounds]) - NSHeight(cellFrame);
	}

      /*
       * make sure the cell will be entirely visible in its new location (if
       * we're in a scrollView, it may not be)
       */
	if (!NSContainsRect(visibleRect , cellFrame) && [self isAutoscroll]) {	
	  /*
	   * the cell won't be entirely visible, so scroll, dood, scroll, but
	   * don't display on-screen yet
	   */
	    [[self window] disableFlushWindow];
	    [self scrollRectToVisible:cellFrame];
	    [[self window] enableFlushWindow];
	    
	  /* copy the new image to the matrix cache */
#if 0
            [matrixCacheImage lockFocus];
	    visibleRect = [self visibleRect];
            visibleRect = [self convertRect:visibleRect fromView:[self superview]];
            visibleRect = [self convertRect:visibleRect toView:nil];
	    PScomposite(NSMinX(visibleRect), NSMinY(visibleRect),
			NSWidth(visibleRect), NSHeight(visibleRect),
			[[self window] gState], 0.0, NSHeight(visibleRect),
			NSCompositeCopy);
	    [matrixCacheImage unlockFocus];
#endif
	  /*
	   * note that we scrolled and start generating timer events for
	   * autoscrolling
	   */
	    scrolled = YES;
	    startTimer(timer);
	} else {
	  /* no scrolling, so stop any timer */
	    stopTimer(timer);
	}
      
      /* composite the active cell's image on top of ourself */
//	PScomposite(0.0, 0.0, NSWidth(cellFrame), NSHeight(cellFrame),
//		    [cellCache gState], NSMinX(cellFrame),
//		    NSMinY(cellFrame) + NSHeight(cellFrame), NSCompositeCopy);
        printf("CellFrame before blatting on moving cell: %g %g %g %g\n", cellFrame.origin.x,cellFrame.origin.y,cellFrame.size.width,cellFrame.size.height);
//        [cellCacheImage compositeToPoint:NSMakePoint(NSMinX(cellFrame), NSMinY(cellFrame) + NSHeight(cellFrame))
//                                   fromRect:NSMakeRect(0.0, 0.0,
//                                                       NSWidth(cellFrame),NSHeight(cellFrame))
//                                                       operation:NSCompositeCopy];
	
      /* now show what we've done */
	[[self window] flushWindow];
	
      /*
       * if we autoscrolled, flush any lingering window server events to make
       * the scrolling smooth
       */
	if (scrolled) {
	    PSWait();
	    scrolled = NO;
	}
	
      /* save the current mouse location, just in case we need it again */
	mouseLocation = [event locationInWindow];
        if (!(peek = [NSApp nextEventMatchingMask:MOVE_MASK untilDate:[NSDate date] inMode:NSEventTrackingRunLoopMode dequeue:NO])) {
	  /*
	   * no mouseMoved or mouseUp event immediately available, so take
	   * mouseMoved, mouseUp, or timer
	   */
	    event = [[self window] nextEventMatchingMask:MOVE_MASK|NSPeriodicMask];
	} else {
	  /* get the mouseMoved or mouseUp event in the queue */
	    event = [[self window] nextEventMatchingMask:MOVE_MASK];
	}
	
      /* if a timer event, mouse location isn't valid, so we'll set it */
	if ([event type] == NSPeriodic) {
            wasTimerEvent = YES;
            alternateLocation = mouseLocation;
        } else wasTimerEvent = NO;
    }
    
  /* mouseUp, so stop any timer and unlock focus */
    stopTimer(timer);
    [self unlockFocus];
    
  /* find the cell under the mouse's location */
    if (wasTimerEvent) mouseUpLocation = alternateLocation;
    else mouseUpLocation = [event locationInWindow];
    mouseUpLocation = [self convertPoint:mouseUpLocation fromView:nil];
    if (![self getRow:&newRow column:&column forPoint:mouseUpLocation]) {
      /* mouse is out of bounds, so find the cell the active cell covers */
	[self getRow:&newRow column:&column forPoint:(cellFrame.origin)];
    }
    
  /* we need to shuffle cells if the active cell's going to a new location */
    if (newRow != row) {
      /* no autodisplay while we move cells around */
	if (newRow > row) {
	  /* adjust selected row if before new active cell location */
	    if ([self selectedRow] <= newRow) {
                [self selectCellAtRow:([self selectedRow] -1) column:[self selectedColumn]];
	    }
	
	  /*
	   * push all cells above the active cell's new location up one row so
	   * that we fill the vacant spot
	   */
	    while (row++ < newRow) {
		aCell = [self cellAtRow:row column:0];
		[self putCell:aCell atRow:(row - 1) column:0];
	    }
	  /* now place the active cell in its new home */
	    [self putCell:activeCell atRow:newRow column:0];
	} else if (newRow < row) {
          /* adjust selected row if after new active cell location */
	    if ([self selectedRow] >= newRow) {
                [self selectCellAtRow:([self selectedRow] + 1) column:[self selectedColumn]];
	    }
	
	  /*
	   * push all cells below the active cell's new location down one row
	   * so that we fill the vacant spot
	   */
	    while (row-- > newRow) {
                aCell = [self cellAtRow:row column:0];
                [self putCell:aCell atRow:(row + 1) column:0];
	    }
	  /* now place the active cell in its new home */
	    [self putCell:activeCell atRow:newRow column:0];
	}
      
      /* if the active cell is selected, note its new row */
	if ([activeCell state]) {
            [self selectCellAtRow: newRow column:0];
	}
      
      /* make sure the active cell's visible if we're autoscrolling */
	if ([self isAutoscroll]) {
	    [self scrollCellToVisibleAtRow:newRow column:0];
	}
      
      /* no longer dragging the cell */
	activeCell = 0;
    
      /* size to cells after all this shuffling and turn autodisplay back on */
        [self sizeToCells];
    } else {
      /* no longer dragging the cell */
        [activeCell release];//sb: there was no need to have retained it, if it wasn't moved
	activeCell = 0;
    }
    
  /* now redraw ourself */
//    [self display];
}


- (void)drawRect:(NSRect)rect
{
    int		row, col;
    NSRect	cellBorder;
    NSRectEdge 	sides[] = {NSMinXEdge, NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge,
    			   NSMinYEdge};
    float	grays[] = {NSDarkGray, NSDarkGray, NSWhite, NSWhite, NSBlack,
			   NSBlack};
			   
  /* do the regular drawing */
    [super drawRect:rect];
#if 0 
  /* draw a "well" if the user's dragging a cell */
    if (activeCell) { printf("found active and drawing well\n");
      /* get the cell's frame */
	[self getRow:&row column:&col ofCell:activeCell];
	cellBorder = [self cellFrameAtRow:row column:col];
      
      /* draw the well */
	if (!NSIsEmptyRect(NSIntersectionRect(cellBorder , rect))) {
	    cellBorder  = NSDrawTiledRects(cellBorder , NSZeroRect , sides, grays, 6);
	    PSsetgray(0.17);
	    NSRectFill(cellBorder);
	}
    }
#endif
}


- setupCacheWindows
{
    NSRect	visibleRect;

  /* create the matrix cache window */
    visibleRect = [self visibleRect];
    matrixCache = [self sizeCacheWindow:&matrixCacheImage to:visibleRect.size];
    
  /* create the cell cache window */
    cellCache = [self sizeCacheWindow:&cellCacheImage to:[self cellSize]];

    return self;
}


- sizeCacheWindow:(id *)cachingImage to:(NSSize)windowSize
{
    NSRect	cacheFrame;
    id cachingView;/*sb: retained, but not instance variable */

        if (!*cachingImage) {
      /* create the cache window if it doesn't exist */
	cacheFrame.origin.x = cacheFrame.origin.y = 0.0;
	cacheFrame.size = windowSize;


        *cachingImage = [[NSImage allocWithZone:[self zone]] initWithSize:cacheFrame.size];
        [*cachingImage lockFocus];
        [*cachingImage unlockFocus];
        cachingView = [[FlippedView allocWithZone:[self zone]] initWithFrame:cacheFrame];
        [[[[*cachingImage representations] objectAtIndex:0] window] setContentView:cachingView];
        
//	cacheWindow = [[NSWindow alloc] initWithContentRect:cacheFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreRetained defer:NO];
      /* flip the contentView since we are flipped */
//        [(NSWindow *)cacheWindow setContentView:[[[FlippedView alloc] initWithFrame:cacheFrame] autorelease]];
    } else {
        cachingView = [(NSWindow *)[[[*cachingImage representations] objectAtIndex:0] window] contentView];
      /* make sure the cache window's the right size */
        cacheFrame = [cachingView frame];
	if (cacheFrame.size.width != windowSize.width ||
      	    cacheFrame.size.height != windowSize.height) {
            [*cachingImage setSize:NSMakeSize(windowSize.width, windowSize.height)];
            [(NSWindow *)[cachingView window] setContentSize:NSMakeSize(windowSize.width, windowSize.height)];
	}
    }

    return cachingView;
}

@end