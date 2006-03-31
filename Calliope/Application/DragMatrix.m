#import <AppKit/AppKit.h>
#import "DragMatrix.h"
#import "FlippedView.h"
#import "SysInspector.h"

@implementation DragMatrix


/* #defines stolen from Draw */

#define MOVE_MASK NSLeftMouseUpMask|NSLeftMouseDraggedMask

- init
{
    activeCell = matrixCache = cellCache = matrixCacheImage = cellCacheImage = nil;
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

- setDeleg:sender
{
    deleg = sender;
    return self;
}

- (void)mouseDown:(NSEvent *)theEvent 
{
    NSPoint	mouseDownLocation, mouseUpLocation, mouseLocation, alternateLocation;
    int		row, column, newRow;
    NSRect	visibleRect, cellFrame,origCellFrame,cellCacheBounds;
    id		aCell;
    float	dy;
    NSEvent 	*event, *peek=nil;
    BOOL	scrolled = NO;
    BOOL	wasTimerEvent = FALSE;
    
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
    [self display];
    origCellFrame = cellFrame = [self cellFrameAtRow:row column:column];
    
  /* do whatever's required for a single-click */
    [self sendAction];
    
  /* draw a "well" in place of the selected cell (see drawSelf::) */
//    [self displayRect:cellFrame];
    
  /* copy what's currently visible into the matrix cache */
    [matrixCache lockFocus];
    [self drawRect:[self visibleRect]];//sb: visibleRect
    [matrixCache unlockFocus];


    /* image the cell into its cache */
    [cellCache lockFocus];
    cellCacheBounds = [cellCache bounds];
    [activeCell drawWithFrame:cellCacheBounds inView:cellCache];
    [cellCache unlockFocus];

  /* save the mouse's location relative to the cell's origin */
    dy = mouseDownLocation.y - cellFrame.origin.y;
    
  /* from now on we'll be drawing into ourself */
    [self lockFocus];
    
    event = theEvent;
    while ([event type] != NSLeftMouseUp) {
      
      /* erase the active cell using the image in the matrix cache */
	visibleRect = [self visibleRect];

        [matrixCacheImage compositeToPoint:NSMakePoint(NSMinX(cellFrame),  NSMinY(cellFrame) + NSHeight(cellFrame))
                                  fromRect:NSMakeRect(NSMinX(cellFrame), NSHeight([self bounds]) - NSHeight(cellFrame)
                                                      - NSMinY(cellFrame),
                                                      NSWidth(cellFrame),NSHeight(cellFrame))
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
        visibleRect.size.width = ceil(visibleRect.size.width);
        visibleRect.size.height = ceil(visibleRect.size.height);
        [[self window] disableFlushWindow];
	if (!NSContainsRect(visibleRect , cellFrame) && [self isAutoscroll]) {	
	  /*
	   * the cell won't be entirely visible, so scroll, dood, scroll, but
	   * don't display on-screen yet
	   */
            visibleRect = [self visibleRect];
            
	    [self scrollRectToVisible:cellFrame];

	  /* copy the new image to the matrix cache */
            /* copy what's currently visible into the matrix cache */
              [matrixCache lockFocus];
              [self drawRect:[self visibleRect]];
              [matrixCache unlockFocus];

              /*
	   * note that we scrolled and start generating timer events for
	   * autoscrolling
	   */
	    scrolled = YES;
	}

        
      /* composite the active cell's image on top of ourself */        
        [cellCacheImage compositeToPoint:NSMakePoint(NSMinX(cellFrame), NSMinY(cellFrame) + NSHeight(cellFrame))
                                fromRect:NSMakeRect(0.0, 0.0, NSWidth(cellFrame),NSHeight(cellFrame))
                               operation:NSCompositeCopy];
	
      /* now show what we've done */
        [[self window] enableFlushWindow];
	[[self window] flushWindow];
	
      /*
       * if we autoscrolled, flush any lingering window server events to make
       * the scrolling smooth
       */
	if (scrolled) {
	    // PSWait();
	    scrolled = NO;
	}
	
      /* save the current mouse location, just in case we need it again */
	mouseLocation = [event locationInWindow];
        [self setNeedsDisplay:NO];
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
    [self unlockFocus];
    
  /* find the cell under the mouse's location */
    if (wasTimerEvent) mouseUpLocation = alternateLocation;
    else mouseUpLocation = [event locationInWindow];
    mouseUpLocation = [self convertPoint:mouseUpLocation fromView:nil];
    if (cellFrame.origin.y <= 0) {newRow = -1;column = 0;}
    else
	[self getRow:&newRow column:&column forPoint:(cellFrame.origin)];
  /* we need to shuffle cells if the active cell's going to a new location */
        if (newRow < row) newRow++;
    if (newRow != row) {
      /* no autodisplay while we move cells around */
	if (newRow > row) {
	
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

        if (deleg) [deleg matrixDidReorder:self];
    } else {
      /* no longer dragging the cell */
        [activeCell release];//sb: there was no need to have retained it, if it wasn't moved
	activeCell = 0;
    }
    
  /* now redraw ourself */
    [self setNeedsDisplay:YES];
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
  /* draw a "well" if the user's dragging a cell */
    if (activeCell) {
        /* get the cell's frame */
	[self getRow:&row column:&col ofCell:activeCell];
	cellBorder = [self cellFrameAtRow:row column:col];
      
      /* draw the well */
	if (!NSIsEmptyRect(NSIntersectionRect(cellBorder , rect))) {
	    cellBorder  = NSDrawTiledRects(cellBorder , NSZeroRect , sides, grays, 6);
	    [[NSColor darkGrayColor] set]; 
	    NSRectFill(cellBorder);
	}
    }
}


- setupCacheWindows
{
  /* create the matrix cache window */
    [self sizeCacheWindow:&matrixCacheImage :&matrixCache to:[self frame].size];
    
  /* create the cell cache window */
    [self sizeCacheWindow:&cellCacheImage :&cellCache to:[self cellSize]];

    return self;
}


- sizeCacheWindow:(id *)cachingImage :(id *) cachingView to:(NSSize)windowSize
{
    NSRect	cacheFrame,cacheFrame2;

        if (!*cachingImage) {
      /* create the cache window if it doesn't exist */
	cacheFrame.origin.x = cacheFrame.origin.y = 0.0;
	cacheFrame.size = windowSize;

        *cachingImage = [[NSImage allocWithZone:[self zone]] initWithSize:windowSize];
        [*cachingImage lockFocus];
        [*cachingImage unlockFocus];
        *cachingView = [[FlippedView allocWithZone:[self zone]] initWithFrame:cacheFrame];
        [[[[[*cachingImage representations] objectAtIndex:0] window] contentView] addSubview:*cachingView];
        [*cachingView setBoundsSize:windowSize];
        [*cachingView setFrame:[[[*cachingImage representations] objectAtIndex:0] rect]];
        
    } else {
      /* make sure the cache window's the right size */
        cacheFrame = [*cachingView frame];
        cacheFrame2.origin.x = cacheFrame2.origin.y = 0.0;
        cacheFrame2.size = windowSize;
	if (cacheFrame.size.width != windowSize.width ||
      	    cacheFrame.size.height != windowSize.height) {
            [*cachingView removeFromSuperview];
            [*cachingImage release];

            *cachingImage = [[NSImage allocWithZone:[self zone]] initWithSize:windowSize];
            [*cachingImage lockFocus];
            [*cachingImage unlockFocus];
            *cachingView = [[FlippedView allocWithZone:[self zone]] initWithFrame:cacheFrame2];
            [[[[[*cachingImage representations] objectAtIndex:0] window] contentView] addSubview:*cachingView];
            [*cachingView setBoundsSize:windowSize];
            [*cachingView setFrame:[[[*cachingImage representations] objectAtIndex:0] rect]];
	}
    }

    return self;
}

@end