/* $Id$ */
#import <AppKit/AppKit.h>
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVPerform.h"
#import "GVSelection.h"
#import "GVCommands.h"
#import "GVPasteboard.h"
#import "Staff.h"
#import "StaffObj.h"
#import "System.h"
#import "SysCommands.h"
#import "SysInspector.h"
#import "SysAdjust.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "ImageGraphic.h"
#import "TextGraphic.h"
#import "Hanger.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "GNote.h"
#import "GNChord.h"
#import "Beam.h"
#import "Margin.h"
#import "Tablature.h"
#import "Bracket.h"
#import "Rest.h"
#import "Clef.h"
#import "KeySig.h"
#import "Barline.h"
#import "TimeSig.h"
#import "Range.h"
#import "Neume.h"
#import "Verse.h"
#import "Accent.h"
#import "Page.h"
#import "Runner.h"
#import "CallPart.h"
#import "Channel.h"
// #import "FlippedView.h"
#import "FileCompatibility.h"

extern NSString * DrawPasteType(NSArray *types);
extern NSSize paperSize;
extern int escapedTool;
extern BOOL cvFlag;		/* whether in a copyVerseFrom mode */
extern int numPastes;
//sb: following was const char *
NSString *DrawPboardType = @"Calliope Graphic List Type";

BOOL dragflag;			/* whether we are dragging */
BOOL moveFlag;			/* whether any staffobjs in selection */

NSColor * backShade;
NSColor * selShade;
NSColor * markShade;
NSColor * inkShade;

int selMode = 7;		/* this is a display mode, not a shade */

@implementation GraphicView

static float KeyMotionDeltaDefault = 0.0;

char grabflag = 0;	/* whether we are in grab mode 1=EPS, 2=TIFF */
id grabCursor = nil;
float *seloffx, *seloffy; /* arrays of selected obj offsets for moving */
id lastHit = nil;		/* object last hit (used for moving noteheads, etc) */



extern void getRegion(NSRect *region, const NSPoint *p1, const NSPoint *p2);
extern NSEvent *periodicEventWithLocationSetToPoint(NSEvent *oldEvent, NSPoint point)
{
    return [NSEvent otherEventWithType:[oldEvent type] location:point modifierFlags:[oldEvent modifierFlags]
                             timestamp:[oldEvent timestamp] windowNumber:[oldEvent windowNumber] context:[oldEvent context]
                               subtype:[oldEvent subtype] data1:[oldEvent data1] data2:[oldEvent data2]];
}

/* Factory methods. */
+ (void) initialize
{
    if (self == [GraphicView class]) {
	[GraphicView setVersion: 7]; /* SB set this to 6 for List conversion, set to 7 now we move to XML property lists. */
	DrawInit();
    }
}


/* Creation methods. */

- makeChanlist
{
  int max = 16;
    Channel *newChannel;
  NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:16];
  max = 16;
  while (max--) {
      newChannel = [Channel alloc];
      [newChannel init];
      [a addObject: newChannel];
      [newChannel release]; /* single retain is held in array */
  }
  return [a autorelease];
}

-(int)tag
{ return 1;}

- initClassVars
{
    void initScratchlist();
    void initChanlist();
    void initScrStylelist();
    static BOOL registered = NO;
    NSArray *sendTypes, *returnTypes;
    NSArray *dragTypes;
    
    if (!KeyMotionDeltaDefault) {
	const char *value = [[[NSUserDefaults standardUserDefaults] objectForKey: @"KeyMotionDelta"] UTF8String];
	if (value) 
	    KeyMotionDeltaDefault = atof(value);
	KeyMotionDeltaDefault = MAX(KeyMotionDeltaDefault, 1.0);
    }
    if (!registered) {
	registered = YES;
	sendTypes = [NSArray arrayWithObjects: NSPostScriptPboardType,NSTIFFPboardType,DrawPboardType,nil];
	returnTypes = [NSArray arrayWithObjects: NSPostScriptPboardType,NSTIFFPboardType,DrawPboardType,nil];
	[NSApp registerServicesMenuSendTypes: sendTypes returnTypes:returnTypes];
	dragTypes = [NSArray arrayWithObjects: NSFilenamesPboardType,NSPostScriptPboardType,NSTIFFPboardType,nil];
	[self registerForDraggedTypes: dragTypes];
    }
    //  paperSize = [[NSPrintInfo sharedPrintInfo] paperSize];
    /*sb: not quite sure what purpose of previous line is. If the printinfo object is archived individually,
	* there's no need to grab it from the archived graphicview like this.
	*/
    if (slist) 
	[slist autorelease];//sb: added cos might be done twice */
    slist = [[NSMutableArray allocWithZone: [self zone]] init];
    if (chanlist == nil) 
	chanlist = [[self makeChanlist] retain];
    if (partlist == nil) {
	partlist = [scratchlist retain];
	initScratchlist();
    }
    if (stylelist == nil) {
	stylelist = [scrstylelist retain];
	initScrStylelist();
    }
    scrolling = NO;
    return self;
}


/*
  Initializes the view's instance variables.
  This view is considered important enough to allocate it a gstate.
  Page vars are set so that Runners can be viewed.
 */
 
- initWithFrame: (NSRect) frameRect
{
    self = [super initWithFrame: frameRect];
    if(self != nil) {
	[self allocateGState];
	slist = [[NSMutableArray allocWithZone: [self zone]] init];
	currentSystem = nil;
	currentPage = nil;
	currentScale = 1.0;  // no zoom.
	syslist = [[NSMutableArray allocWithZone: [self zone]] init];
	partlist = nil;
	chanlist = nil;
	showMargins = NO;
	staffScale = 1.0;   // just initialise the staffScale to a useful value.

	[self initClassVars];	
    }
    return self;
}

/*
 Kludge to get the model aspects of a GraphicView into another one.
 Strictly speaking this isn't full initialisation.
 It should become a NotationScore method, however.
*/
- initWithGraphicView: (GraphicView *) v
{
    // TODO Problem could be we are releasing already released ivars?
    
    // [syslist release];
    syslist       = [v->syslist retain]; // Retain this since System hasn't implemented copyWithZone:
    // [pagelist release];
    pagelist      = [v->pagelist copy];
    // [partlist release];
    partlist      = [v->partlist copy];
    // [chanlist release];
    chanlist      = [v->chanlist copy];
    // [stylelist release];
    stylelist     = [v->stylelist copy];
    // [currentSystem release];
    currentSystem = [v->currentSystem retain];   // Retain this since System hasn't implemented copyWithZone:

    // [currentPage release];
    currentPage   = [v->currentPage copy];
    
    staffScale = [v staffScale];

    // TODO perhaps [self initClassVars];
    return self;
}

/* sb: added this to replace [self setFlipped:YES], above 
 We therefore draw with the assumption that the origin is at the top-left of the view.
 */
- (BOOL) isFlipped
{
    return YES;
}

- setBackground: sender
{
    [self setNeedsDisplay: YES];
    return self;
}

- (void) setFrameSize: (NSSize) newSize
/*
 * Overrides View's sizeTo:: so that the cacheImage is resized when
 * the View is resized.
 */
{
    NSRect frame = [self frame];

    if (newSize.width != frame.size.width || newSize.height != frame.size.height) {
        [super setFrameSize: newSize];
//        [self setNeedsDisplay:NO];
//        [[self superview] setFrameSize:newSize];
    }
}

- (void)setBoundsSize:(NSSize)newSize
{
    NSRect bounds = [self bounds];

    if (newSize.width != bounds.size.width || newSize.height != bounds.size.height) {
        [super setBoundsSize:newSize];
        bounds = [self bounds];
        [self cache:bounds];
    }
}

- (void)setBounds:(NSRect)newRect
{
    NSRect bounds = [self bounds];

    if (newRect.size.width != bounds.size.width || newRect.size.height != bounds.size.height) {
        [super setBounds:newRect];
        [self cache:newRect];
    }
}

- (void) dealloc
{
    [cacheImage release];
    cacheImage = nil;

    [currentSystem release];
    currentSystem = nil;
    [currentPage release];
    currentPage = nil;
    [currentFont release];
    currentFont = nil;

    [slist release];
    slist = nil;
    
    // All the following are NotationScore ivars in need of dealloc.
    [stylelist release];
    stylelist = nil;
    [chanlist release];
    chanlist = nil;
    [partlist release];
    partlist = nil;
    [pagelist release];
    pagelist = nil;
    [syslist release];
    syslist = nil;
    [super dealloc];
}


- setupGrabCursor: (int) grabFormat
{    
    grabflag = grabFormat;
    if (!grabCursor) {
	NSPoint p = { 7.0, 7.0 };

	grabCursor = [[NSCursor alloc] initWithImage: [NSImage imageNamed: @"cross.tiff"] hotSpot: p];
    }
    [[[self window] contentView] setDocumentCursor: grabCursor];
    return self;
}


- (BOOL) isEmpty
{
  return currentSystem == nil;
}


- currentSystem
{
    return currentSystem;
}


/* pass back BB of selection (and hangers and verses) with or without handles. */

- selectionBBox:(NSRect *)bbox
{
  graphicListBBox(bbox, slist);
  return self;
}


- selectionHandBBox: (NSRect *)bbox
{
  graphicHandListBBox(bbox, slist);
  return self;
}


/*
  BBox of things not selected, but affected if anything in selection moves.
  Ideally, each object should be interrogated, but this hack is just
  to find the common special case: any Chords under a Beam and their hangers.
*/

static void noteAndHangBB(NSArray *l, NSRect *bbox)
{
  int nl;
  NSRect b;
  StaffObj *g;
  if (l != nil && (nl = [l count]))
  {
    while (nl--)
    {
      g = [l objectAtIndex:nl];
      if (ISASTAFFOBJ(g))
      {
        *bbox  = NSUnionRect((g->bounds) , *bbox);
        listBBox(&b, g->hangers);
        *bbox  = NSUnionRect(b , *bbox);
      }
    }
  }
}


- affectedBBox:(NSRect *)bbox
{
  int k, nh;
  id h;
  NSMutableArray *p;
  StaffObj *g;
  k = [slist count];
  while (k--)
  {
    g = [slist objectAtIndex:k];
    if (ISASTAFFOBJ(g))
    {
      p = g->hangers;
      if (p != nil && (nh = [p count]))
      {
	while (nh--)
	{
	  h = [p objectAtIndex:nh];
	  if ([h graphicType] == BEAM) 
	      noteAndHangBB([(Beam *)h clients], bbox);
	}
      }
    }
    else if ([g graphicType] == BEAM) 
	noteAndHangBB([(Beam *)g clients], bbox);
  }
  return self;
}


/* for moving, refresh the selection quickly without doing through drawSelf */

- drawSelectionInstance
{
  int i, k;
  id p;
  NSRect mybb;
  BOOL first = YES;
  id window = [self window];
  NSRect selectionBlat = NSZeroRect;
  NSRect cachedRect;
  // PSWait();
  if (cached)
      [window restoreCachedImage];
  k = [slist count];
  for (i = 0; i < k; i++) /*first pass -- find the bb */
  {
    p = [slist objectAtIndex:i];
    graphicBBox(&mybb,p);
    if (first) {
        selectionBlat = mybb;
        first = NO;
    }
    else selectionBlat = NSUnionRect(selectionBlat,mybb);
  }
//  NSLog(@"selectionblat %g %g %g %g\n",selectionBlat.origin.x,selectionBlat.origin.y,selectionBlat.size.width,selectionBlat.size.height);

  cachedRect = NSInsetRect([self convertRect:selectionBlat toView:nil],-2,-2);
  cachedRect.origin.x = (int)cachedRect.origin.x;
  cachedRect.origin.y = (int)cachedRect.origin.y;
  cachedRect.size.width = ceil(cachedRect.size.width);
  cachedRect.size.height = ceil(cachedRect.size.height);

  [window cacheImageInRect:cachedRect];

  cached = YES;
  for (i = 0; i < k; i++)/*second pass -- draw the objects */
  {
      [[slist objectAtIndex:i] draw: NSZeroRect nonSelectedOnly: NO];
  }
  for (i = 0; i < k; i++)
      [[slist objectAtIndex:i] drawHangers: NSZeroRect nonSelectedOnly: NO];

  [window flushWindow];
  return self;
}


/*
  The selection is about to be moved relative to obj.
  Decide what kind of move it is.
  Set up a vector of offsets.
*/

- setuplist: (StaffObj *) obj : (NSPoint *) p
{
  float fx, fy;
  int i, k, s;
  StaffObj *o;
  k = [slist count];
  if (k)
  {
    s = 2 * k * sizeof(float);
    seloffx = (seloffx == NULL) ? malloc(s) : realloc(seloffx, s);
    seloffy = seloffx + k;
    moveFlag = 0;
    if (obj == nil)
    {
      fx = p->x;
      fy = p->y;
    }
    else [obj getXY: &fx : &fy];
    i = k;
    while (i--)
    {
      o = [slist objectAtIndex:i];
      if (!moveFlag && ISASTAFFOBJ(o)) moveFlag = 1;
      if ([o getXY: &(seloffx[i]) : &(seloffy[i])])
      {
        seloffx[i] -= fx;
        seloffy[i] -= fy;
      }
    }
  }
  return self;
}
    

/*
  move the selection.  If a StaffObj or Beam is moved, there are knock-on
  effects for hangers associated with these objects.
  if moveFlag = 1, move only the StaffObjs.
  To prevent redundant setting, StaffObjs and Beams mark hangers in first pass
  during move:, and set in second (clearing marks) using 'moveFinished'.
  A hanger is marked only if actually moved.
  A hanger is set only if actually marked.
  Responsible for finding splits and joins.
 */
 
extern char *typename[NUMTYPES];

- (BOOL) moveSelection:  (NSPoint) p : (int) alt
{
  int i, k;
  StaffObj *o;
  System *s;
  BOOL m = NO;
  k = [slist count];
// if (k > 1) NSLog(@"move sel to pt: %f %f\n", p.x, p.y);
  for (i = 0; i < k; i++)
  {
    o = [slist objectAtIndex:i];
    if (ISASTAFFOBJ(o) || !moveFlag)
    {
// if (k > 1) fprintf(stderr,"  %s offset: %f %f\n", typename[[o graphicType]], seloffx[i], seloffy[i]);
      s = [self findSys: (float) (seloffy[i] + p.y)];
      m |= [o move: (float) seloffx[i]: (float) seloffy[i] : p : s : alt];
    }
  }
  if (m)
  {
    for (i = 0; i < k; i++)
    {
      o = [slist objectAtIndex:i];
      if (ISASTAFFOBJ(o) || !moveFlag) [o moveFinished: self];
    }
  }
  return m;
}


/*
  Check selection for split hangers.
  mark systems on which the selection landed, then
  check these systems for joins
*/

- terminateMove
{
  int i, k, hk;
  StaffObj *o;
  System *s;
  Hanger *h;
  NSMutableArray *hl, *hsl;
  k = [slist count];
  for (i = 0; i < k; i++)
  {
    o = [slist objectAtIndex:i];
    if (ISASTAFFOBJ(o))
    {
      hl = o->hangers;
      hk = [hl count];
      while (hk--)
      {
        h = [hl objectAtIndex:hk];
        if ([h canSplit] && (hsl = [h willSplit]))
        {
          [self splitSelect: h : hsl];
          [h removeObj];
          [hsl autorelease];
        }
      }
      s = [o mySystem];
      s->gFlags.morphed = 1;
    }
  }
  for (i = 0; i < k; i++)
  {
    o = [slist objectAtIndex:i];
    if (ISASTAFFOBJ(o))
    {
      s = [o mySystem];
      if (s->gFlags.morphed)
      {
        s->gFlags.morphed = 0;
	[s findJoins];
      }
    }
  }
  return self;
}


#define MOVE_MASK NSLeftMouseUpMask|NSLeftMouseDraggedMask

- (BOOL)isWithinBounds:(NSRect) rect
{
    NSRect bounds = [self bounds];
    return (NSMinX(rect) >= 0 && NSMinY(rect) >= 0 && NSMaxX(rect) <= NSMaxX(bounds) && NSMaxY(rect) <= NSMaxY(bounds));
}

/*
 * Moves the selection.
 */

- (BOOL)move:(NSEvent *)event : (id) obj : (int) alt
{
  float dx, dy;
  NSPoint p, last;
  NSRect sbounds, mybb, visrect,cachedRect;
  NSEvent *peek = nil;
  BOOL timer = NO;
  BOOL tracking = YES, alternate, m, first, canscroll;
  id window = [self window];
  alternate = alt;
  alternate |= ([event modifierFlags] & NSAlternateKeyMask) ? 1 : 0;
  alternate |= ([event modifierFlags] & NSControlKeyMask) ? 2 : 0;
  event = [window nextEventMatchingMask:MOVE_MASK];
  if ([event type] == NSLeftMouseUp) return NO;
  visrect = [self visibleRect];
  canscroll = !NSEqualRects(visrect , [self bounds]);
  // canscroll = NO;
  last = [event locationInWindow];
  last = [self convertPoint:last fromView:nil];
  [self dirty];
  [self selectionHandBBox: &sbounds];
  [self setuplist: nil : &last];
  event = [window nextEventMatchingMask:MOVE_MASK];
  dragflag = YES;
  [self lockFocus];

  // [self drawRect: sbounds nonSelectedOnly: YES]; //sb: this should blat the selection OFF the screen
  cachedRect = NSInsetRect([self convertRect:sbounds toView:nil],-4,-4);
  cachedRect.origin.x = (int)cachedRect.origin.x;
  cachedRect.origin.y = (int)cachedRect.origin.y;
  cachedRect.size.width = ceil(cachedRect.size.width);
  cachedRect.size.height = ceil(cachedRect.size.height);

  [window cacheImageInRect:cachedRect];
  /* store away "empty" image */
  cached = YES;
  [self drawSelectionInstance];
  mybb = NSZeroRect;
  [self affectedBBox: &mybb];
  first = YES;
  while (tracking)
  {
    p = [event locationInWindow];
    p = [self convertPoint:p fromView:nil];
    dx = p.x - last.x;
    dy = p.y - last.y;
    if (dx || dy)
    {
      m = [self moveSelection: p : alternate];
      if (m || first)
      {
        [self tryToPerform:@selector(updateRulers:) with:(void *) nil];
	if (!canscroll || NSContainsRect(visrect , sbounds))
	{
          [self drawSelectionInstance];
          if (timer != NO) [NSEvent stopPeriodicEvents];
          timer = NO;
	}
	first = NO;
        last = p;
      }
    }
    tracking = ([event type] != NSLeftMouseUp);
    if (tracking)
    {
      [self selectionHandBBox: &sbounds];
      [self affectedBBox: &mybb];
      sbounds  = NSUnionRect(mybb , sbounds);
      [window disableFlushWindow];

      /****** do we need to scroll? ******/
      if (canscroll && !NSContainsRect(visrect , sbounds) && [self isWithinBounds:sbounds])
      {
          if (cached) [window restoreCachedImage];//sb: this should blat the selection OFF the screen
          else
              NSLog(@"huh?\n");
          cached = NO; /* so restoreCachedImage doesn't try to restore image after scroll */
          scrolling = YES;
          [self scrollPointToVisible: p];
          scrolling = NO;
          [self drawSelectionInstance];
          if (!timer) { [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1]; timer = YES; }
      }
      /****** end of scrolling code ******/
      
      visrect = [self visibleRect];
      [window enableFlushWindow];
      [window flushWindow];
//      [self drawSelectionInstance];
      p = [event locationInWindow];

      if (!(peek = [NSApp nextEventMatchingMask:MOVE_MASK untilDate:[NSDate date] inMode:NSEventTrackingRunLoopMode dequeue:NO])) {
          event = [window nextEventMatchingMask:MOVE_MASK|NSPeriodicMask];
      }
      else {
          event = [window nextEventMatchingMask:MOVE_MASK];
        }
      if ([event type] == NSPeriodic) event = periodicEventWithLocationSetToPoint(event, p);
    }
  }
  
  /******* move has ended. Now clean up. *******/
  if (canscroll && timer != NO) [NSEvent stopPeriodicEvents];
  timer = NO;
  [self terminateMove];

  [self selectionHandBBox: &sbounds];
  [self affectedBBox: &mybb];
  sbounds  = NSUnionRect(mybb , sbounds);
//  [self drawRect:sbounds];
  [self cache:sbounds];
  [self tryToPerform:@selector(updateRulers:) with:nil];
  [window flushWindow];
  [self unlockFocus];
  dragflag = NO;
  return YES;
}


/* Public interface methods. */
// These should be moved into OpusDocument.
- dirty
{
  if (!dirtyflag)
  {
    dirtyflag = YES;
    [[self window] setDocumentEdited:YES];
  }
  return self;
}


- (BOOL)isDirty
{
    return dirtyflag;
}


/*
 * Draws all the Graphics intersected by rect
*/

- cache:(NSRect)rect
{    
  if ([self canDraw])
  {
    [self lockFocus];
    [self drawRect:rect];
    [self unlockFocus];
  }
  return self;
}

/* redraw an object (used in some unusual cases) */

- reDraw: g
{
  NSRect b;
  graphicBBox(&b, g);
  [self cache: b];
  [[self window] flushWindow];
  return self;
}


/* reshape and redraw */

- reShapeAndRedraw: g
{
  NSRect b, nb;
  graphicBBox(&b, g);
  [g reShape];
  graphicBBox(&nb, g);
  nb  = NSUnionRect(b , nb);
  [self cache: nb];
  [[self window] flushWindow];
  return self;
  
}


/*
  Used for 'selbit' objects that change their drawing when they are hit.
  Caller updates internal state of object but no recalc.  Then we
  find BB, recalc, union in new BB, and redraw.
  Uses graphicBB because verses need this treatment.
*/ 

- tallyAndRedraw: g
{
  NSRect b, nb;
  graphicBBox(&b, g);
  [g recalc];
  graphicBBox(&nb, g);
  nb  = NSUnionRect(b , nb);
  [self cache: nb];
  [[self window] flushWindow];
  return self;
}


/* redraw the selected area unioned with b */

- drawSelectionWith: (NSRect *) b
{
  NSRect nb;
  [self selectionHandBBox: &nb];
  if (b != NULL) nb  = NSUnionRect(*b , nb);
  [self cache: nb];
  [[self window] flushWindow];
  return self;
}
 
 
/*
  Search through objects on the page to find one nearest p.
*/

- searchFor: (NSPoint) p;
{
    NSMutableArray *l = [[NSMutableArray alloc] init];
    int k;
    id q, r;
    float d = MAXFLOAT, dmin = 0.0;
    int systemIndex = [currentPage topSystemNumber];
    int theCount = [syslist count];
    
    while (systemIndex <= [currentPage bottomSystemNumber] && (systemIndex <= theCount)) {
	System *sys = [syslist objectAtIndex: systemIndex];
	
	[sys searchFor: p inObjects: l];
	if ([l count] > 0) 
	    break;
	++systemIndex;
    }
    if ([l count] == 1) 
	r = [l objectAtIndex: 0];
    else {
	r = nil;
	k = [l count];
	while (k--) {
	    q = [l objectAtIndex: k];
	    d = [q hitDistance: p];
	    if (d < dmin) {
		d = dmin;
		r = q;
	    }
	}
    }
    [l removeAllObjects];
    [l release];
    return r;
}


/*
  Select by dragging a box. Objects are selected if (with ALT up)
  they intersect the box or (with ALT down) they are enclosed by the box.

  Check each object on current page to see whether the box drags over it.
  Do hangers before the staffobj, so that the hanger is included on slist
  in its own right.  Interesting to see what happens to hangers.
  
  checkAll is too promiscuous, because it tries to select objects that cannot be hit
  (such as ChordGroup), so selectMe's should decide whether to put in list.
*/

#define DRAG_MASK (NSLeftMouseUpMask|NSLeftMouseDraggedMask|NSPeriodicMask)
#define CHECKBOX(q) ((alt && NSContainsRect(*sb , (q->bounds))) || (!alt && !NSIsEmptyRect(NSIntersectionRect(*sb , (q->bounds)))))

- checkAll: (BOOL) alt : (NSRect *) sb
{
  Staff *sp;
  System *sys;
  NSMutableArray *nl, *hl;
  StaffObj *q;
  Hanger *h;
  int systemIndex, k, j, n, theCount;
  
  systemIndex = [currentPage topSystemNumber];
  theCount = [syslist count];
  while (systemIndex <= [currentPage bottomSystemNumber] && systemIndex <= theCount)
  {
    sys = [syslist objectAtIndex:systemIndex];
    n = [sys numberOfStaves];
    while (n--)
    {
      sp = [sys getStaff: n];
      if (sp->flags.hidden) continue;
      nl = sp->notes;
      k = [nl count];
      while (k--)
      {
	  NSArray *enclosureList;
	  
        q = [nl objectAtIndex:k];
        hl = q->hangers;
        if (hl != nil)
	{
	  j = [hl count];
	  while (j--)
	  {
	    h = [hl objectAtIndex:j];
	    if (!([h isSelected]) && CHECKBOX(h)) [self selectObj: h];
	  }
	}
        enclosureList = [q enclosures];
        if (enclosureList != nil)
	{
	  j = [enclosureList count];
	  while (j--)
	  {
	    h = [enclosureList objectAtIndex:j];
	    if (!([h isSelected]) && CHECKBOX(h)) [self selectObj: h];
	  }
	}
        if (!([q isSelected]) && CHECKBOX(q)) [self selectObj: q : 1];
      }
    }
    nl = sys->nonStaffGraphics;
    j = [nl count];
    while (j--)
    {
      q = [nl objectAtIndex:j];
      if (!([q isSelected]) && CHECKBOX(q)) [self selectObj: q];
    }
    ++systemIndex;
  }
  return self;
}


- dragSelect: (NSEvent *) event 
{
    NSPoint p, last, start;
    BOOL alt, shift, hasregion, canscroll,wcache = NO, didMove = NO;
    NSRect region;
    NSWindow *window = [self window];
    NSRect cachedRect;
    
    BOOL timer = NO;
    p = start = [event locationInWindow];
    start = [self convertPoint: start fromView:nil];
    last = start;
    shift = ([event modifierFlags] & NSShiftKeyMask) ? YES : NO;
    alt = ([event modifierFlags] & NSAlternateKeyMask) ? YES : NO;
    [self lockFocus];
    event = [window nextEventMatchingMask:DRAG_MASK];
    hasregion = NO;
    region = [self visibleRect];
    [selShade set];
  // PSsetlinewidth(0.0);
    
    canscroll = !NSEqualRects(region , [self bounds]);
    if (canscroll && !timer) {
	[NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
	timer = YES;
    }
    while ([event type] != NSLeftMouseUp)
    {
	if ([event type] == NSPeriodic) 
	    event = periodicEventWithLocationSetToPoint(event, p);
	p = [event locationInWindow];
	p = [self convertPoint: p fromView: nil];
	if (p.x != last.x || p.y != last.y)
        {
	    didMove = YES;
	    getRegion(&region, &p, &start);
	    /* ensure that it encloses some area, so NSIntersectionRect will not get confused */
	    if (region.size.width == 0) 
		region.size.width = 0.01;
	    if (region.size.height == 0) 
		region.size.height = 0.01;
	    hasregion = YES;
	    
	    if (wcache) {
		[window restoreCachedImage];
//              [window discardCachedImage];
	    }
	    
	    [window disableFlushWindow];
	    if (canscroll) {
//              [self scrollRectToVisible:region];
		if ([self scrollPointToVisible: p]) {
		    [selShade set]; /* in case these are reset by the drawing code above */
		    // PSsetlinewidth(0.0);
		    [window displayIfNeeded];
		}
            }
	    [window enableFlushWindow];
	    
	    cachedRect = NSInsetRect([self convertRect: NSIntersectionRect(region, [self visibleRect]) toView: nil], -2, -2);
	    cachedRect.origin.x = (int) cachedRect.origin.x;
	    cachedRect.origin.y = (int) cachedRect.origin.y;
	    cachedRect.size.width = ceil(cachedRect.size.width);
	    cachedRect.size.height = ceil(cachedRect.size.height);
	    [window cacheImageInRect: cachedRect];
	    wcache = YES;
	    
	    NSFrameRect(region);
	    [self tryToPerform: @selector(updateRulers:) with: (void *) &region];
	    [window flushWindow];
	    last = p;
        }
	else 
	    didMove = NO;
	p = [event locationInWindow];
	event = [window nextEventMatchingMask: DRAG_MASK];
    }
    if (wcache) 
	[window restoreCachedImage];
    
    if (canscroll && timer) 
	[NSEvent stopPeriodicEvents];
    timer = NO;
    /* now we do something with region */
    if (hasregion) {
	if (grabflag) {
	    [self saveRect: region ofType: grabflag];
	    grabflag = 0;
	    [[window contentView] setDocumentCursor: [NSCursor arrowCursor]];
	}
	else {
	    [self checkAll: alt : &region];
	    [self drawSelectionWith: NULL];
	}
    }
    [self tryToPerform: @selector(updateRulers:) with: nil];
    [self unlockFocus];
    if (hasregion && !grabflag) 
	[self inspectSel: NO];
//[NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return self;
}


/* the Press Tools */

- pressTool: (int) t withArgument: (int) arg
{
    NSRect b0, b1;
    
    [self selectionHandBBox: &b0];
    if (![Graphic canCreateGraphicOfType: t asMemberOfView: self withArgument: arg])
	NSLog(@"pressTool: Could not create tool %d as member of graphic view with argument %d", t, arg);
    [self selectionHandBBox: &b1];
    b0 = NSUnionRect(b1, b0);
    [self cache: b0];
    [[self window] flushWindow];
    [self dirty];
    return self;
}


/* the add notehead Tool */

- noteheadTool: (GNote *) p : (float) y
{
    Staff *sp;
    System *sys;
    NSRect b;
    
    sys = [self findSys: y];
    sp = [sys findOnlyStaff: y];
    if (sp != [p staff] && [p myChordGroup] != nil) return self;
    [self selectionHandBBox: &b];
    if (![p newHeadOnStaff: [p staff] atHeight: y accidental: 0])
    {
	NSLog(@"noteheadTool: newHead: returned NO");
	return self;
    }
    [self dirty];
    [self drawSelectionWith: &b];
    return self;
}


/* select or autoselect current system */

- selectCurSys: (System *) g : (BOOL) command
{
  System *s;
  if (currentSystem != g)
  {
    s = currentSystem;
    [self selectSystemAsCurrent: g];
    [self reDraw: g]; /* g's marker */
    [self reDraw: s]; /* old marker */
  }
  [[CalliopeAppController sharedApplicationController] inspectClass: [SysInspector class] loadInspector: command];
  return self;
}


/*
  selection must have at least 1 staffobj or 1 anything
*/

- (BOOL) willingToMove
{
  int i, k, ns = 0;
  Graphic *p;
  i = k = [slist count];
  if (k == 1) return YES;
  while (i--)
  {
    p = [slist objectAtIndex:i];
    if (ISASTAFFOBJ(p)) ++ns;
  }
  return (ns > 0);
}


/*
 * This method handles a mouse down.
 *
 If a current tool is in effect (and no untoward shift keys),
 then the mouse down causes a new Graphic to begin being created.
 if cvFlag is in effect, then copy verse.
 Otherwise, the selection is modified
 either by adding elements to it or removing elements from it, or moving
 it.  Here are the rules:
 *
 * Tool in effect
 *    Shift OFF
 *	create a new Graphic which becomes the new selection
 *    Shift ON
 *	create a new Graphic and ADD it to the current selection
 *    Control ON
 *    Command ON
 *    Alternate ON
 *	do not create anything, but leave Tool and drop into selection mode
 * Otherwise
 *    Shift OFF
 *	a. Click on a selected Graphic -> no effect
 *	b. Click on an unselected Graphic -> that Graphic becomes selection
 *    Shift ON
 *	a. Click on a selected Graphic -> remove it from selection
 *	b. Click on unselected Graphic -> add it to selection
 *    Control ON
 *      click on any graphic -> pass control to MOVE
 *    Command ON
 *      click on any graphic -> select it and throw up its inspector
 *    Alternate ON
 *      a. click on any graphic -> disables internal editing (as if a corner hit)
 *                                 and pass alternate to MOVE
 *      b. if no affected graphic, causes drag select to select only objects
 *	completely contained within the dragged box.
 *    Except for:
        System, where a click makes it current
        'selbit' set, where a click must recalc and draw.
  */

extern struct toolData toolCodes[NUMTOOLS];

- (void) mouseDown: (NSEvent *) event
{
    NSPoint p;
    int /*oldMask,*/ i, tool, fontseltype = -1;
    Graphic *g = nil, *trymove = nil;
    System *sys;
    BOOL shift, control, command, alternate, autoalt = NO;
    if ([[self window] firstResponder] != self) [[self window] makeFirstResponder:self];
    if (currentSystem == nil) {
	NSLog(@"mouseDown: currentSystem is nil");
	return;
    }
    shift = ([event modifierFlags] & NSShiftKeyMask) ? YES : NO;
    control = ([event modifierFlags] & NSControlKeyMask) ? YES : NO;
    command = ([event modifierFlags] & NSCommandKeyMask) ? YES : NO;
    command |= ([event clickCount] == 2);
    alternate = ([event modifierFlags] & NSAlternateKeyMask) ? YES : NO;
    tool = toolCodes[currentTool].type;
    if (tool && (control || command || alternate))
    {
	[[CalliopeAppController sharedApplicationController] resetTool];
	return;
    }
    p = [event locationInWindow];
    p = [self convertPoint:p fromView:nil];
    NSLog(@"mouse down point %f, %f", p.x, p.y);
    if (grabflag)
    {
	[self dragSelect: event];
	grabflag = NO;
	[[self window] flushWindow];
//#error EventConversion: setEventMask:oldMask: is obsolete; you no longer need to use the eventMask methods; for mouse moved events, see 'setAcceptsMouseMovedEvents:'
//      [window setEventMask:oldMask];
	return;
    }
    if (tool == 101)
    {
	/* the 'add notehead' tool */
	g = [self isSelType: NOTE];
	if (g != nil && TOLFLOATEQ(p.x, ((GNote *)g)-> x, 8.0))
	{
	    [self noteheadTool: (GNote *)g : p.y];
	    trymove = g;
	    autoalt = YES;
	}
	else
	{
	    NSLog(@"mouseDown: g == nil || not within tolerance");
	    tool = 0;
	    g = nil;
	}
    }
    if (tool == 100)
    {
	/* the 'copy pasteboard' tool: might have clicked a staffobj too */
	g = [self isSelTypeCode: TC_STAFFOBJ : &i];
	if ([g hit: p])
	    [self pasteTool: &p : g];
	else
	    [self pasteTool: &p : nil];
	trymove = [self isSelLeftmost];
	if (trymove == nil)
	{
	    NSLog(@"trymove == nil");
	    return;
	}
	[self setuplist: (StaffObj *)trymove : &p];
	[self moveSelection: p : 0];
	[self drawSelectionWith: NULL];
    }
    else if (tool == 101)
    {
	/* (add notehead) take this to ignore remainder */
    }
    else if (tool == 102)
    {
	/* new staff */
	[self deselectAll: self];
	[[self findSys: p.y] newStaff: p.y];
	[self balanceOrAsk: currentPage : 0 askIfLoose: NO];
	[[CalliopeAppController sharedApplicationController] resetTool];
	[[CalliopeAppController sharedApplicationController] inspectClass: [SysInspector class] loadInspector: NO];
	trymove = nil;
    }
    else if (tool) 
    {
	g = [Graphic createMember: self : tool : p : [self findSys: p.y] : toolCodes[currentTool].arg1 : toolCodes[currentTool].arg2];
	if (g == nil) return;
	[self dirty];
	if (!shift) [self deselectAll: self];
	[self selectObj: g];
	lastHit = g;
	[self drawSelectionWith: NULL];
	fontseltype = 0;
	if (!shift) trymove = g;
    }
    else
    {
	g = [self searchFor: p];
	if (g != nil)
	{
	    if (cvFlag)
	    {
		[self copyVerseFrom: g];
		[[[self window] contentView] setDocumentCursor:[NSCursor arrowCursor]];
		cvFlag = NO;
//#error EventConversion: setEventMask:oldMask: is obsolete; you no longer need to use the eventMask methods; for mouse moved events, see 'setAcceptsMouseMovedEvents:'
//          [window setEventMask:oldMask];
		return;
	    }
	    if ([g graphicType] == SYSTEM)
	    {
		/* special treatment for System: fire and forget */
		[self selectCurSys: (System *)g : command];
		[self setFontSelection: 3 : 0];
		g = nil;
		trymove = nil;
	    }
	    else if ([g isSelected])
	    {
		if (g->gFlags.selbit)
		{
		    g->gFlags.selbit = 0;
		    [self tallyAndRedraw: g];
		}
		if (shift) [self deselectObj: g];
		else
		{
		    trymove = g;
		}
		fontseltype = 0;
	    }
	    else /* was not already selected */
	    {
		if (!shift) [self deselectAll: self];
		[self selectObj: g];
		if (g->gFlags.selbit)
		{
		    g->gFlags.selbit = 0;
		    [self tallyAndRedraw: g];
		}
		else [self drawSelectionWith: NULL];
		if (!shift) trymove = g;
		fontseltype = 0;
	    }
	}
	else /* nothing hit */
	{
	    if (!shift && [slist count]) [self deselectAll: self];
	    [self dragSelect: event];
	}
    }
    if (g != nil)
    {
	if (ISASTAFFOBJ(g))
	{
	    sys = [(StaffObj *)g mySystem];
	    if (sys != currentSystem) [self selectCurSys: sys : NO];
	}
	[[CalliopeAppController sharedApplicationController] inspectAppWithMe: g loadInspector: command : fontseltype];
	i = g->gFlags.selend;
	if ([g isResizable] && i == 7)
	{
	    cached = NO; /* to wipe current selection from screen */
	    [g resize: event in: self];
	    trymove = nil;
	}
	else if ([g isEditable] && !alternate && (i != 7 && i != 4))
	{
	    [[CalliopeAppController sharedApplicationController] resetTool];
	    [(TextGraphic *)g edit: event in: self];
	    trymove = nil;
	}
    }
//    [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil];
//    [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    if (trymove && [self willingToMove]) [self move: event : trymove : autoalt];
    [[self window] flushWindow];
}

static void drawVert(float x, float y, float h, NSRect r)
{
    NSRect line;
    
    line.origin.x = x;
    line.origin.y = y;
    line.size.width = 1.0;
    line.size.height = h;
    
    if (!NSIsEmptyRect(NSIntersectionRect(r, line)))
	cline(x, y, x, y + h, 0.0, markmode[0]);
}

static void drawHorz(float x, float y, float w, NSRect r)
{
    NSRect line;
    
    line.origin.x = x;
    line.origin.y = y;
    line.size.width = w;
    line.size.height = 1.0;
    
    if (!NSIsEmptyRect(NSIntersectionRect(r, line)))
	cline(x, y, x + w, y, 0.0, markmode[0]);
}

/*
 * Draws the GraphicView. The official drawRect: has to include selected objects.
 */
- (void) drawRect: (NSRect) rectToDrawWithin
{
    int systemIndex;
    Page *pageToDraw = currentPage;
    
    [backShade set];
    NSRectFill(rectToDrawWithin);
    
    if (pageToDraw == nil) 
	return;
    
    NSLog(@"GraphicView drawRect: (%f, %f, %f, %f)", rectToDrawWithin.origin.x, rectToDrawWithin.origin.y, rectToDrawWithin.size.width, rectToDrawWithin.size.height);
    NSLog(@"view is flipped %d\n", [self isFlipped]);
    
    if ([self showMargins]) {
	NSRect viewBounds = [self bounds];	
	float x = [pageToDraw leftMargin];
	float y = [pageToDraw topMargin];
	float w = viewBounds.size.width - x - [pageToDraw rightMargin];
	float h = viewBounds.size.height - y - [pageToDraw bottomMargin];
	
	drawHorz(x, y, w, rectToDrawWithin);
	drawVert(x, y, h, rectToDrawWithin);
	drawHorz(x, y + h, w, rectToDrawWithin);
	drawVert(x + w, y, h, rectToDrawWithin);
	drawHorz(x, [pageToDraw headerBase], w, rectToDrawWithin);
	drawHorz(x, viewBounds.size.height - [pageToDraw footerBase], w, rectToDrawWithin);
	x = [pageToDraw leftBinding];
	if (x > 0.001) 
	    drawVert(x, viewBounds.origin.y, viewBounds.size.height, rectToDrawWithin);
	x = [pageToDraw rightBinding];
	if (x > 0.001)
	    drawVert(viewBounds.origin.x + viewBounds.size.width - x, viewBounds.origin.y, viewBounds.size.height, rectToDrawWithin);
    }
    
    [pageToDraw drawRect: rectToDrawWithin];
    
    for (systemIndex = [pageToDraw topSystemNumber]; systemIndex <= [pageToDraw bottomSystemNumber]; systemIndex++) 
	[[syslist objectAtIndex: systemIndex] draw: rectToDrawWithin nonSelectedOnly: scrolling];
    for (systemIndex = [pageToDraw topSystemNumber]; systemIndex <= [pageToDraw bottomSystemNumber]; systemIndex++) 
	[[syslist objectAtIndex: systemIndex] drawHangers: rectToDrawWithin nonSelectedOnly: scrolling];    
}


/*
 * Handles keypresses.
 */
 
 
- (BOOL) performKeyEquivalent:(NSEvent *)e 
{
  NSRect b;
  int k;
  NSString *c;
  id p;
  BOOL r = NO;
  k = [slist count];
  if (k == 0) return NO;
  [self selectionHandBBox: &b];

  c = [e characters];
  while (k--)
  {
    p = [slist objectAtIndex:k];
      if ([p performKey: *[c UTF8String]]) /*sb: huh? was originally just performkey:c, but I needed to give an int */
    {
      r = YES;
    }
  }
  if (r)
  {
    [self dirty];
    [self drawSelectionWith: &b];
    [[CalliopeAppController sharedApplicationController] inspectApp];
  }
  return r;
}


/*
  navigate verses, return whether the arrow was consumed
  up/dn might change font panel.
*/

- (BOOL) handleTab: (BOOL) leftTab
{
  StaffObj *g = nil, *p;
  NSRect b;
  int dp;
  if (leftTab)
  {
    p = [self isSelLeftmost];
    g = [self prevNote: p];
  }
  else
  {
    p = [self isSelRightmost];
    g = [self nextNote: p];
  }
  if (g != nil)
  {
    g->selver = [p verseNeighbour: g];
    [self deselectAll: self];
    dp = [self findPageOff: g];
    if (dp) [self gotoPage: dp usingIndexMethod: 0];
    graphicBBox(&b, g);
    [self scrollRectToVisible:b];
    [self selectObj: g];
    [self drawSelectionWith: NULL];
    if (!ISAVOCAL(g)) NSLog(@"handleTab: is not a vocal");
    [[CalliopeAppController sharedApplicationController] inspectApp];
    return YES;
  }
  return NO;
}


- (BOOL) handleControl:(NSEvent *)event 
{
    NSPoint pt;
    Staff *sp;
    TimedObj *p;
    Barline *newBarLine;
    Barline *bl;
    int tb, td, b = NO, r = YES;
    int cst;
    
    //#warning EventConversion: the 'characters' method of NSEvent replaces the '.data.key.charCode' field of NXEvent. Use 'charactersIgnoringModifiers' to get the chars that would have been generated regardless of modifier keys (except shift)
    switch (cst = *[[event characters] UTF8String]) {
	case 'b': /* 2:   B */
	    [self pressTool: BEAM withArgument: 0];
	    break;
	case 't': /* 20:   T */
	    [self pressTool: TIENEW withArgument: 0];
	    break;
	case 'n': /*14:  N */
	    break;
	case 'm': /*13:  M */
	    [self getInsertionX: &(pt.x) : &sp : &p : &tb : &td];
	    pt.y = [sp yOfCentre];
	    newBarLine = (Barline *) [Graphic graphicOfType: BARLINE];
	    [newBarLine proto: self : pt : sp : [sp mySystem] : nil : 0];
	    bl = [self lastObject: [sp mySystem] : [sp myIndex] : BARLINE : YES];
	    if (bl != nil)
	    {
		newBarLine->flags.staff = bl->flags.staff;
		newBarLine->flags.bridge = bl->flags.bridge;
	    }
	    b = YES;
	    break;
	case 'r': /*18:  R */
	    [self getInsertionX: &(pt.x) : &sp : &p : &tb : &td];
	    pt.y = [sp yOfCentre];
	    p = (Rest *)[Graphic graphicOfType: REST];
	    [p proto: self : pt : sp : [sp mySystem] : nil : 5];
	    p->time.body = tb;
	    [p setDottingCode: 0];
	    p->staffPosition = [((Rest *)p) defaultPos];
	    b = YES;
	    break;
	default:
	    r = NO;
	    break;
    }
    if (b) {
	[sp linknote: p];
	lastHit = p;
	[p reShape];
	[self dirty];
	[self deselectAll: self];
	[self selectObj: p];
	[self drawSelectionWith: NULL];
	[[CalliopeAppController sharedApplicationController] inspectApp];
    }
    return r;
}


- (void)keyDown:(NSEvent *)event 
{
//#warning EventConversion: the 'characters' method of NSEvent replaces the '.data.key.charCode' field of NXEvent. Use 'charactersIgnoringModifiers' to get the chars that would have been generated regardless of modifier keys (except shift)
    NSString *cc = [event charactersIgnoringModifiers];
//#warning EventConversion: the '.data.key.charSet' field of NXEvent does not have an exact translation to an NSEvent method.  Possibly use [[event characters] canBeConvertedToEncoding:...]
//  int cs = event.data.key.charSet;
  int cf = [event modifierFlags];
  int cst=0;
  int t;
  NSRect b;
  id f;
  int act = 0;
  Graphic *p;

  if ([cc canBeConvertedToEncoding:NSNEXTSTEPStringEncoding]) cst = *[cc UTF8String];
//  if (cs == NX_ASCIISET && cc == 0x1B /* ESC */)
  if ([cc canBeConvertedToEncoding:NSNEXTSTEPStringEncoding] && cst == 0x1B /* ESC */)
  {
    if (currentTool == 0) t = escapedTool;
    else
    {
      escapedTool = currentTool;
      t = 0;
    }
    [[CalliopeAppController sharedApplicationController] resetToolTo: t];
    return;
  }
  if ([slist count] == 0) {[super keyDown:event]; return;}
  if ([cc canBeConvertedToEncoding:NSNEXTSTEPStringEncoding] && cst == 127 && (cf & NSAlternateKeyMask)) /* ALT-DEL */
  {
    [self delete:self];
    return;
  }
  p = [slist objectAtIndex:0];
  if (p != nil) 
  {
    if (cf & NSCommandKeyMask)
    {
      if ([self performKeyEquivalent: event]); else [super keyDown:event];
      return;
    }
    if	(cf & NSControlKeyMask)
    {
      if ([self handleControl: event]) return;
    }
    if (ISASTAFFOBJ(p))
    {
        if ([cc canBeConvertedToEncoding:NSASCIIStringEncoding])
      {
            if (cst == 9) act = [self handleTab: 0];//TAB
            else if (cst == 25) act = [self handleTab: 1];//SHIFT-TAB
      }
        else if ([cc canBeConvertedToEncoding:NSSymbolStringEncoding])
      {
            [self doToSelection: 8 : cst];
            if ([cc characterAtIndex:0] == NSUpArrowFunctionKey || [cc characterAtIndex:0] == NSDownArrowFunctionKey)
        {
          f = [(StaffObj *) p getVFont];
            if (f != nil) [[NSFontManager sharedFontManager] setSelectedFont:f isMultiple:NO];
        }
	act = YES;
      }
      if (act) return;
    }
    [self selectionHandBBox: &b];
    act = [p keyDownString:cc];
    if (act > 0)
    {
      [self dirty];
      [self drawSelectionWith: &b];
      [[CalliopeAppController sharedApplicationController] inspectAppWithMe: p loadInspector: NO : 0];
    }
    else if (act < 0) [super keyDown:event];
  }
}

- (NSMutableArray *) selectedGraphics
{
// TODO This might be a little heavy weight, since it probably involves a copy, but I'd rather enforce the immutability of the array than
// save processor cycles these days.
    // return [NSArray arrayWithArray: slist];
    return [[slist retain] autorelease];
}

/* clean out the selection list, free/realloc only if necessary */
- (void) clearSelection
{  
    if ([slist count] <= 16) 
	[slist removeAllObjects];
    else {
	[slist autorelease];
	slist = [[NSMutableArray allocWithZone:[self zone]] init];
    }
}


/*
 * Writes out the EPS or TIFF of the given rect.
*/

// static char *typeExts[3] = {NULL, "eps", "tiff"};

// TODO should be able to remove pasteboard saving into the NSDocument saving.
- (NSData *) saveRect: (NSRect) region ofType: (int) type
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSData *s;
    NSBitmapImageRep *bm;
    
    switch(type)
    {
	case 0:
	    return nil;
	case 1:
	    s = [self dataWithEPSInsideRect: region];
	    break;
	case 2:
	    [self lockFocus];
	    bm = [[NSBitmapImageRep alloc] initWithFocusedViewRect: region];
	    [self unlockFocus];
	    s = [bm TIFFRepresentationUsingCompression: NSTIFFCompressionLZW factor: TIFF_COMPRESSION_FACTOR];
	    [bm release];
	    break;
	case 3:
	    [pb declareTypes: [NSArray arrayWithObject: NSPostScriptPboardType] owner: [self class]];
	    s = [self dataWithEPSInsideRect: region];
	    [pb setData: s forType: NSPostScriptPboardType];
	    numPastes = 0;
	    break;
	case 4:
	    [pb declareTypes: [NSArray arrayWithObject: NSTIFFPboardType] owner: [self class]];
	    [self lockFocus];
	    bm = [[NSBitmapImageRep alloc] initWithFocusedViewRect: region];
	    [self unlockFocus];
	    s = [bm TIFFRepresentationUsingCompression: NSTIFFCompressionLZW factor: TIFF_COMPRESSION_FACTOR];
	    [bm release];
	    [pb setData: s forType: NSTIFFPboardType];
	    numPastes = 0;
	    break;
    }
    return s;
}


/*
  the trick here is to remove hangers first, so there is no
  dangling reference in the slist when staffobj remove hanger.
  If there are any runners, then marker area needs to be dealt with.
*/

- (void)delete:(id)sender
{
  NSRect sb, mybb;
  Graphic *p;
  int k;
  BOOL runs = NO, marg = NO;
  mybb = NSZeroRect;
  [self affectedBBox: &mybb];
  [self selectionHandBBox: &sb];
  sb  = NSUnionRect(mybb , sb);
  k = [slist count];
  while (k--)
  {
    p = [slist objectAtIndex:k];
    if ([p graphicType] == RUNNER)
    {
      (p->bounds)  = NSUnionRect(mybb , (p->bounds));
      runs = YES;
    }
    else if ([p graphicType] == MARGIN)
    {
        if ([(Margin *) p client] == [syslist objectAtIndex: 0])
        {
          NSLog(@"delete: client == first system");
          return;
        }
        p->bounds = NSUnionRect(mybb , (p->bounds));
        marg = YES;
    }
  }
  if (marg) [self saveSysLeftMargin];
  k = [slist count];
  if (k > 0)
  {
    [self dirty];
    while (k--)
    {
      p = [slist objectAtIndex:k];
      if ([p isDangler])
      {
        [p sysInvalid];
        [p removeObj];
	[slist removeObjectAtIndex: k];
      }
    }
    k = [slist count]; 
    while (k--)
    {
      p = [slist objectAtIndex:k];
      [p sysInvalid];
      [p removeObj];
    }
    [self clearSelection];
    if (runs || marg)
    {
      [self setRunnerTables];
      if (marg) [self shuffleIfNeeded];
      [self recalcAllSys];
      [self paginate: self];
    }
    else
    {
      [self cache: sb];
    }
    [[CalliopeAppController sharedApplicationController] inspectApp];
    [[self window] flushWindow];
  }
}


/* deselects all the items on the slist */

- deselectAll:sender
{
    int i, k, f;
    Graphic *p;
    NSRect sb;
    k = [slist count];
    f = 0;
    if (k)
    {
        [self selectionHandBBox: &sb];
//    for (i = 0; i < k; i++) 
//sb: I don't step through any more, as removing hangers
//alters the composition of slist.
        while ((i = [slist count]))
        {
            p = [slist objectAtIndex:i-1];
            p->gFlags.selected = 0;
            p->gFlags.seldrag = 0;
            [slist removeObjectAtIndex:i-1];
            [p selectHangers:slist : 0];
        }
        [self cache: sb];
        [self clearSelection];
    //    [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
        if (sender != self) [[self window] flushWindow];
    }
    return self;
}



- scaleTo: (int) i
{
    float j = (i == 127) ? 127.778 : i;
    float s = 0.01 * j;
    float w = s / currentScale;
    float h = s / currentScale;
    id clView = [[self enclosingScrollView] contentView];
    NSRect initialRect = [clView bounds];
    NSPoint thePoint = [clView convertPoint:(NSPoint){NSMinX(initialRect),NSMinY(initialRect)} toView:self];
    [self scaleUnitSquareToSize:NSMakeSize(w, h)];

    currentScale = s;
    return [[CalliopeAppController currentDocument] changeSize: ceil([self frame].size.width * w)
                                              : ceil([self frame].size.height * h)
                                              : (NSPoint)thePoint];
}


- (int) getScaleNum
{
    return (int) (100 * currentScale);//sb: removed the + 0.5
}

- (float) getScaleFactor
{
    return currentScale;
}

- (void) setScaleFactor: (float) newScaleFactor
{
    currentScale = newScaleFactor;
}

- (int) getPageNum
{
  if (currentPage == nil) return 0;
  return [currentPage pageNumber];
}

- (Page *) currentPage
{
    return [[currentPage retain] autorelease];
}

- (float) rulerScale
{
    // TODO should be retrieving the paperSize from currentDocument or it should be set here.
    //   [[CalliopeAppController currentDocument] paperSize];
    return [self bounds].size.width / paperSize.width / currentScale;
}

/* First Responder handling */

 
- (BOOL)acceptsFirstResponder
{
  return YES;
}


/* Printing */


- (BOOL) knowsPagesFirst: (int *) p0 last: (int *) p1
/* invoked with *p0 = 1, *p1 = MAXINT */
{
  Page *p;
  p = [pagelist objectAtIndex:0];
  if ([p pageNumber] != 1)
  {
    *p0 = [p pageNumber];
    p = [pagelist lastObject];
    *p1 = [p pageNumber];
  }
  return YES;
}


- (NSRect)rectForPage:(int)pn
{
      return [self findPage: pn usingIndexMethod: 2] ? [self bounds]: NSZeroRect;
}


- (void)addToPageSetup
{
    // TODO
//  float s = 1.0 / currentScale;
  // [super addToPageSetup];
  // PSscale(s, s);
}

- (void)print:(id)sender
{
  int n;
  [self deselectAll: self];
  n = [pagelist indexOfObject:currentPage];
  [super print:sender];
  [self gotoPage: n usingIndexMethod: 1];
}


- (NSPoint)locationOfPrintRect:(NSRect)r
{
    return NSZeroPoint;
}


/* Include the window title as the name of the document when printing. */

- (void)beginPrologueBBox:(NSRect)bb creationDate:(NSString *)dateCreated createdBy:(NSString *)app fonts:(NSString *)fontNames forWhom:(NSString *)user pages:(int )numPages title:(NSString *)aTitle
{
    // [super beginPrologueBBox:bb creationDate:dateCreated createdBy:@"Calliope" fonts:fontNames forWhom:user pages:numPages title:[[[self window] title] lastPathComponent]];
}


/* Emit the custom PostScript defs. */

- (void)beginSetup
{
    int n;
    // [super beginSetup];
    [self deselectAll: self];
    n = [pagelist indexOfObject:currentPage];
    [self gotoPage: n usingIndexMethod: 1];
}


/* Useful scrolling routines. */

- scrollGraphicToVisible:graphic
{
  NSPoint p;
  NSRect eb;
  p = [self bounds].origin;
  eb = [graphic bounds];
  NSContainsRect(eb , [self bounds]);
  p.x -= [self bounds].origin.x;
  p.y -= [self bounds].origin.y;
  if (p.x || p.y)
  {
      NSRect myBounds = [self bounds];
    [graphic moveBy:p];

    myBounds.origin.x += p.x;
    myBounds.origin.y += p.y;
    [self setBounds:myBounds];
    eb = [graphic bounds];
    [self scrollRectToVisible:eb];
  }
  return self;
}


- (BOOL)scrollPointToVisible:(NSPoint)point
{
  NSRect r;
  r.origin.x = point.x - 5.0;
  r.origin.y = point.y - 5.0;
  r.size.width = r.size.height = 10.0;
  return [self scrollRectToVisible:r];
}


/* dragging */

- (unsigned int) draggingEntered:sender
{
  int num;
  if (([sender draggingSourceOperationMask] & NSDragOperationCopy) &&
       ([sender draggingSource] != self)) 
  {
    [self isSelTypeCode: TC_STAFFOBJ : &num];
    if (num != 1) return NSDragOperationNone;
    return NSDragOperationGeneric;
  }
  return NSDragOperationNone;
}


- (unsigned int) draggingUpdated: sender
{
  if (([sender draggingSourceOperationMask] & NSDragOperationGeneric) &&
        ([sender draggingSource] != self)) 
  {
    return NSDragOperationGeneric;
  }
  return NSDragOperationNone;
}


- (BOOL) performDragOperation: sender
{
  return YES;
}

- (void)draggingExited:sender
{
}

- (void)concludeDragOperation:sender
{
  id workspace;
  BOOL fileFound;
  NSString *theFileType=nil;
  NSPasteboard *pboard;
  NSPoint p;
  NSArray *data = nil;
  NSString *appName=nil;
  pboard  = [sender draggingPasteboard];
  data = [pboard propertyListForType:NSFilenamesPboardType];
  workspace = [NSWorkspace sharedWorkspace];
  if (data)
      if ([data count]) {
          fileFound = [workspace getInfoForFile:[data objectAtIndex:0] application:&appName type:&theFileType];
          if (fileFound)
            {
              p = [sender draggingLocation];
              p = [self convertPoint:p fromView:nil];
              [(ImageGraphic *)[Graphic graphicOfType: IMAGE] protoFromPasteboard: pboard : self : p];
              [self setNeedsDisplay:YES];
            }
      }
}



/* Archiver-related methods. */


- updateMarginsWithHeader: (float) hb footer: (float) fb printInfo: pi
{
    System *s = [syslist objectAtIndex:0];
    Margin *m = [s margin];
    
    if (m) {
	[m setHeaderBase: hb];
	[m setFooterBase: fb];
		
	[m setLeftMargin: [pi leftMargin]];
	[m setRightMargin: [pi rightMargin]];
	[m setTopMargin: [pi topMargin]];
	[m setBottomMargin: [pi bottomMargin]];
    }
    
    [pi setLeftMargin: 0];
    [pi setRightMargin: 0];
    [pi setTopMargin: 0];
    [pi setBottomMargin: 0];
    return self;
}


- (Page *) myPage: (System *) s
{
  int i, k, n;
  Page *p;
  BOOL f = NO;
  n = [syslist indexOfObject:s];
  if (n == NSNotFound) return nil;
  k = [pagelist count];
  for (i = 0; (i < k && !f); i++)
  {
    p = [pagelist objectAtIndex:i];
    if ([p topSystemNumber] <= n && n <= [p bottomSystemNumber]) return p;
  }
  return nil;
}

- (void) setStaffScale: (float) newStaffScale
{
    staffScale = newStaffScale;
}

- (float) staffScale
{
    return staffScale;
}

/*
  Upon arousal, check systems for valid view and page, and update to put
  a margin object on the first system.
*/

//extern int needUpgrade;

struct oldflags		/* for old version */
{
  unsigned int dirty:1;             /* whether edited since last save */
  unsigned int anon2:1;
  unsigned int tabfactor : 2;
  unsigned int barnumstyle : 4;
  unsigned int anon : 8;
};


/* extra stuff for old version of systems */
/*sb: from awake method: */
extern int needUpgrade;

// This is pure, creamy fudge! Attempts to decode the View superclass that was encoded in older file formats.
- (void) superClassDecoderFakeout: (NSCoder *) aDecoder
{
    // Perhaps just create a dummy View and Responder & initWithCoder: those?
    id dummySuperClassObject;
    float dummyFloat;
    float dummyFloat1, dummyFloat2, dummyFloat3, dummyFloat4;
    char dummyString1[256], dummyString2[256];
    unsigned int systemVersion = [aDecoder systemVersion];
    
    NSLog(@"GraphicView decoding systemVersion %u", systemVersion);
    switch(systemVersion) {
	case 1000:
	    // for files that encoded OpenStep era AppKit objects, we can just use initWithCoder: to read it.
	    [[NSView alloc] initWithCoder: aDecoder];
	    break;
	default:
	    // Decode pre-OpenStep Appkit objects
	    [NSUnarchiver decodeClassName: @"PSMatrix" asClassName: @"PSMatrixDecodeFaker"];
	    dummySuperClassObject = [aDecoder decodeObject];
	    [aDecoder decodeValuesOfObjCTypes: "f", &dummyFloat];
	    [aDecoder decodeValuesOfObjCTypes: "ffff", &dummyFloat1, &dummyFloat2, &dummyFloat3, &dummyFloat4];
	    //NSLog(@"dummy floats %f %f %f %f", dummyFloat1, dummyFloat2, dummyFloat3, dummyFloat4);
	    [aDecoder decodeValuesOfObjCTypes: "ffff", &dummyFloat1, &dummyFloat2, &dummyFloat3, &dummyFloat4];
	    //NSLog(@"dummy floats %f %f %f %f", dummyFloat1, dummyFloat2, dummyFloat3, dummyFloat4);
	    [aDecoder decodeObject];
	    [aDecoder decodeObject];
	    [aDecoder decodeValuesOfObjCTypes: "@ss@", &dummySuperClassObject, dummyString1, dummyString2, &dummySuperClassObject];
	    break;
    }
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    struct oldflags f;
    int v = [aDecoder versionForClassName: @"GraphicView"];
    
    // We shouldn't have saved an NSView's ivars, this is just because the model and view are mixed together. In principle we should
    // only be decoding the model.
    // [super initWithCoder:aDecoder];
    // but we still need to decode the super class in order to read past it.
    [self initWithFrame: NSZeroRect]; // TODO this isn't right. [self frameRect]
//    [NSUnarchiver decodeClassName: @"List" asClassName: @"ListDecodeFaker"];
//    [NSUnarchiver decodeClassName: @"Font" asClassName: @"NSFont"];
    [self superClassDecoderFakeout: aDecoder];    

    // TODO is this even necessary anymore?
    [self setFrameSize: NSMakeSize(ceil([self frame].size.width), ceil([self frame].size.height))];
    partlist = nil;
    stylelist = nil;
    // TODO syslist is being decoded, but the System instances are not correctly initialised with -init!!
    switch(v) {
	case 0:
	    [aDecoder decodeValuesOfObjCTypes:"@@s", &syslist, &pagelist, &f];
	    currentScale = 1.0;
	    break;
	case 1:
	    [aDecoder decodeValuesOfObjCTypes:"@@fs", &syslist, &pagelist, &currentScale, &f];
	    break;
	case 2:
	    [aDecoder decodeValuesOfObjCTypes:"@@f", &syslist, &pagelist, &currentScale];
	    break;
	case 3:
	    [aDecoder decodeValuesOfObjCTypes:"@@@f", &syslist, &pagelist, &partlist, &currentScale];
	    break;
	case 4:
	    [aDecoder decodeValuesOfObjCTypes:"@@@@f", &syslist, &pagelist, &partlist, &chanlist, &currentScale];
	    break;
	case 5:
	    [aDecoder decodeValuesOfObjCTypes:"@@@@@f", &syslist, &pagelist, &partlist, &chanlist, &stylelist, &currentScale];
	    break;
	case 6:
	    [aDecoder decodeValuesOfObjCTypes:"@@@@@f", &syslist, &pagelist, &partlist, &chanlist, &stylelist, &currentScale];
	    break;
    }
    dirtyflag = NO;
    
    /* sb: was awake method: */
    {
	int k;
	System *s;
	
	/* this does a test */
	k = [syslist count];
	while (k--)
	{
	    s = [syslist objectAtIndex:k];
	    if ([s pageView] == nil)
	    {
		NSLog(@"NOTICE: corrected nil view found in unarchived system = %d\n", k);
		[s setPageView: self];
	    }
	    if ([s page] == 0)
		[s setPage: [self myPage: s]];
	    if (s->gFlags.type == 0)
	    {
		NSLog(@"NOTICE: corrected nil type found in unarchived system = %d", k);
		[s setTypeOfGraphic: SYSTEM];
	    }
	}
	s = [syslist objectAtIndex:0];
	if (![s margin])
	{
	    Margin *newMargin = [[Margin alloc] init];
	    
	    [newMargin setClient: s];
	    [s linkobject: newMargin];
	    [newMargin recalc];
	    [newMargin release];
	    needUpgrade |= 4;
	}
	
    } /* sb: end from awake method */
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  dirtyflag = NO;
  [[self window] setDocumentEdited:NO];
  [aCoder encodeValuesOfObjCTypes:"@@@@@f", &syslist, &pagelist, &partlist, &chanlist, &stylelist, &currentScale];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [aCoder setObject:syslist forKey:@"syslist"];
    [aCoder setObject:pagelist forKey:@"pagelist"];
    [aCoder setObject:partlist forKey:@"partlist"];
    [aCoder setObject:chanlist forKey:@"chanlist"];
    [aCoder setObject:stylelist forKey:@"stylelist"];
    [aCoder setFloat:currentScale forKey:@"CurrentScale"];
    // TODO must decide if we should archive this.
    // [aCoder setFloat: staffScale forKey: @"staffScale"];
}

#if 0
- (void)lockFocus
{
    [super lockFocus];
}

- (void)unlockFocus
{
    [super unlockFocus];
}
#endif

- (void) setDelegate: (id) newDelegate
{
    // We create only a weak reference to our delegate since this will be our parent (e.g OpusDocument).
    delegate = newDelegate;
}

- (id) delegate
{
    return delegate;
}

@end

