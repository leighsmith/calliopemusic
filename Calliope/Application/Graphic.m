/* $Id$ */
#import <AppKit/AppKit.h>
#import "Graphic.h"
#import "GVSelection.h"
#import "System.h"
#import "Staff.h"
#import "Enclosure.h"
#import "Barline.h"
#import "Bracket.h"
#import "TimeSig.h"
#import "Margin.h"
#import "GNote.h"
#import "Rest.h"
#import "Clef.h"
#import "KeySig.h"
#import "Range.h"
#import "ImageGraphic.h"
#import "Tablature.h"
#import "Block.h"
#import "TextGraphic.h"
#import "Beam.h"
#import "TieNew.h"
#import "Metro.h"
#import "NeumeNew.h"
#import "Accent.h"
#import "CalliopeAppController.h"
#import "Runner.h"
#import "Tuple.h"
#import "NoteGroup.h"
#import "SquareNote.h"
#import "ChordGroup.h"
#import "Ligature.h"
//#import "draw.h"  // This was generated by the pswrap utility from draw.psw.
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "FileCompatibility.h"

#define RESIZE_MASK (NSLeftMouseUpMask|NSLeftMouseDraggedMask|NSPeriodicMask)

@implementation Graphic : NSObject

id CrossCursor = nil;	/* global since subclassers may need it */

#define stopTimer(timer) if (timer) { [NSEvent stopPeriodicEvents]; timer = NO; }

#define startTimer(timer) if (!timer) { [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1]; timer = YES ; }

/* Returns a drawing mode indexed as [selected][invisible], the drawmode forms a suitable index into modegray[] and noprint[]. 
   Accessed via +drawingModeIfSelected:IfInvisible: 
 */
int drawmode[2][4] =
{
    {1, 4, 3, 2},
    {7, 7, 7, 7}
};

extern int selMode;

+ (Class) classFor: (GraphicType) t
{
  id obj;
  
  switch(t) {
    case NOTE:
      obj = [GNote class];
      break;
    case REST:
      obj = [Rest class];
      break;
    case BEAM:
      obj = [Beam class];
      break;
    case TUPLE:
      obj = [Tuple class];
      break;
    case TIENEW:
      obj = [TieNew class];
      break;
    case METRO:
      obj = [Metro class];
      break;
    case BRACKET:
      obj = [Bracket class];
      break;
    case BARLINE:
      obj = [Barline class];
      break;
    case TIMESIG:
      obj = [TimeSig class];
      break;
    case CLEF:
      obj = [Clef class];
      break;
    case KEY:
      obj = [KeySig class];
      break; 
    case RANGE:
      obj = [Range class];
      break; 
    case TABLATURE:
      obj = [Tablature class];
      break;
    case NEUMENEW:
      obj = [NeumeNew class];
      break;
    case TEXTBOX:
      obj = [TextGraphic class];
      break;
    case MARGIN:
      obj = [Margin class];
      break;
    case RUNNER:
      obj = [Runner class];
      break;
    case BLOCK:
      obj = [Block class];
      break;
    case ACCENT:
      obj = [Accent class];
      break;
    case GROUP:
      obj = [NoteGroup class];
      break;
    case ENCLOSURE:
      obj = [Enclosure class];
      break;
    case SQUARENOTE:
      obj = [SquareNote class];
      break;
    case CHORDGROUP:
      obj = [ChordGroup class];
      break;
    case LIGATURE:
      obj = [Ligature class];
      break;
    case IMAGE:
      obj = [ImageGraphic class];
      break;
    default:
      obj = nil;
      break;
  }
  return obj;
}

+ (Graphic *) graphicOfType: (GraphicType) typeCode
{
    Graphic *obj = nil;
    Class GraphicSubclass = [self classFor: typeCode];
    
    if (GraphicSubclass == nil) 
	NSLog(@"missing case in [Graphic graphicOfType: %d]", typeCode);
    else 
	obj = [[[GraphicSubclass alloc] init] autorelease];
    return obj;
}


+ getInspector: (GraphicType) t
{
    id c = [self classFor: t];
    
    return (c == nil) ? nil : [c myInspector];
}


+ (void)initialize
{
  if (self == [Graphic class])
  {
      (void)[Graphic setVersion: 3];   	/* class version, see read: */ /*sb set to 3 for List conversion */
  }
  return;
}


+ cursor
{
  NSPoint spot;
  if (!CrossCursor)
  {
      spot.x = 7.0; spot.y = 7.0;
      CrossCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cross.tiff"] hotSpot:spot];
  }
  return CrossCursor;
}


/*
  Create and link in a new Graphic of type t at (converted) location p
*/

+ createMember: (GraphicView *) v : (int) t : (NSPoint) pt : (System *) sys : (int) arg1 : (int) arg2
{
  Graphic *g = nil;
  Staff *sp = [sys findOnlyStaff: pt.y];
  g = [self graphicOfType: t];
  [g proto: v : pt : sp : sys : nil : arg1];
  switch (arg2)
  {
    case 0:
      break;
    case 1:
      [sys linkobject: g];
      break;
    case 2:
      // TODO Staff -linknote: expects a StaffObj which is a subclass of Graphic.
      [sp linknote: g];
      break;
    case 3:
      [sys linkobject: g];
      [[CalliopeAppController sharedApplicationController] resetTool];
      break;
  }
  [g reShape];
  return g;
}

- (void) setTypeOfGraphic: (GraphicType) graphicType
{
    gFlags.type = graphicType;
}

- (GraphicType) graphicType
{
    return gFlags.type;
}


// The work is done by subclasses.
- presetHanger
{
    return self;
}

/* tie up a pair of chords.  Return NO if need to use default method */

+ (BOOL) tieChord: (GraphicView *) v
{
  TieNew *t;
  GNote *p, *q;
  NSMutableArray *a;
  int i, j, k = 0;
  findEndpoints([v selectedGraphics], &p, &q);
  if (p == q) return NO;
  if ([p graphicType] != NOTE || [q graphicType] != NOTE) return NO;
  k = [p numberOfNoteHeads];
  if (k == 1) return NO;
  if (k != [q numberOfNoteHeads]) return NO;
  t = [TieNew myPrototype];
  if (t->gFlags.subtype != TIEBOW) return NO;
  [v deselectAll: v];
  for (i = 0; i < k; i++)
  {
      t = (TieNew *)[self graphicOfType: TIENEW];
    [t proto: v : p : q : i];
    if (a = [t willSplit])
    {
      [t removeObj];
      for (j = 0; j < 2; j++)
      {
        t = [a objectAtIndex:j];
        [t presetHanger];
        t->gFlags.selected = YES;
        [[v selectedGraphics] addObject: t];
      }
      [a autorelease];
    }
    else
    {
      [t presetHanger];
      t->gFlags.selected = YES;
      [[v selectedGraphics] addObject: t];
    }
  }
  return YES;
}


/* must store accents in list so no problem when selection is deselected! */

+ (BOOL) makeAccents: (GraphicView *) v
{
    NSMutableArray *sl = [v selectedGraphics];
    NSMutableArray *accentList;
    int typeCode, accentCount, numberSelected;
    BOOL r = NO;
    Accent *a;
    StaffObj *p;
    
    [v canInspectTypeCode: TC_STAFFOBJ : &typeCode];
    if (typeCode == 0) 
	return NO;
    accentList = [[NSMutableArray alloc] init];
    numberSelected = [sl count];
    while (numberSelected--) {
	p = [sl objectAtIndex: numberSelected];
	if (ISASTAFFOBJ(p)) {
	    a = (Accent *) [self graphicOfType: ACCENT];
	    [a proto: v : NSZeroPoint : nil : nil : p : 0];
	    [a recalc];
	    [accentList addObject: a];
	}
    }
    accentCount = [accentList count];
    if (accentCount > 0) {
	[v deselectAll: v];
	while (accentCount--) 
	    [v selectObj: [accentList objectAtIndex: accentCount]];
	r = YES;
    }
    [accentList autorelease];
    return r;
}

+ (BOOL) canCreateGraphicOfType: (GraphicType) typeCode asMemberOfView: (GraphicView *) v withArgument: (int) arg 
{
    NSMutableArray *a;
    int i;
    
    if (typeCode == TIENEW) {
	if ([self tieChord: v]) 
	    return YES;
    }
    if (typeCode == ACCENT) {
	if (![self makeAccents: v]) 
	    return NO;
    }
    else {
	Graphic *p = [self graphicOfType: typeCode];
	
	if ([p proto: v : NSZeroPoint : nil : nil : nil : arg] == nil) {
	    return NO;
	}
	[v deselectAll: v];
	if ([p canSplit] && (a = [p willSplit])) {
	    [p removeObj];
	    for (i = 0; i < 2; i++) {
		p = [a objectAtIndex: i];
		[p presetHanger];
		[v selectObj: p];
	    }
	    [a autorelease];
	}
	else {
	    [p presetHanger];
	}
	[p recalc];
	[v selectObj: p];
	if (p->gFlags.subtype == LABEL) {
	    if ([p respondsToSelector: @selector(editMe:)])
		[(TextGraphic *)p performSelector: @selector(editMe:) withObject: v afterDelay: 0];
	}
    }
    return YES;
}


+ myInspector
{
  return nil;
}


- myInspector
{
  return [[self class] myInspector];
}


- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ type=%d, subtype=%d", [super description], gFlags.type, gFlags.subtype];
}


- init
{
    self = [super init];
    if(self != nil) {
	gFlags.selected = 0;
	gFlags.seldrag = 0;
	gFlags.selend = 0;
	gFlags.selbit = 0;
	gFlags.morphed = 0;
	gFlags.locked = 0;
	gFlags.invis = 0;
	gFlags.size = 0;
	[self setTypeOfGraphic: 0];
	gFlags.subtype = 0;
	enclosures = nil;
    }
    return self;
}

- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  return self;
}


- (int) myLevel
{
  return -1;
}


- (BOOL) linkPaste: (GraphicView *) v
{
  return NO;
}


- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
  return NO;
}


- recalc
{
    // This attempts to force redrawing, whereas in a NSView app, we at best just mark that the NSView needs redisplaying.
    bbinit();
#if 0
    [self drawMode: 0];
#endif
    bounds = getbb();
    
    [self sysInvalid];
    return self;
}


- reShape
{
  return [self recalc];
}

/* this reached only if not handled by a subclass */

- sysInvalid
{
  return self;
}


- (BOOL) canSplit
{
  return NO;
}


- (NSMutableArray *) willSplit
{
  return nil;
}


- (void)removeObj
{
  NSLog(@"Warning: did [Graphic removeObj::]\n");
}


/* structure copying of bounds. */

- (NSRect)bounds
{
    return bounds;
}

- setBounds:(const NSRect)aRect
{
    bounds = aRect;
    return self;
}


- (BOOL) getHandleBBox: (NSRect *) r
{
  return NO;
}

- verseWidths: (float *) tb : (float *) ta
{
  *tb = 0.0;
  *ta = 0.0;
  return self;
}


- (BOOL) getXY: (float *) x : (float *) y
{
    *x = [self bounds].origin.x;
    *y = [self bounds].origin.y;
  return YES;
}


- mark
{
  gFlags.morphed = 1;
  return self;
}


- (void)moveBy:(float)dx :(float)dy
{
    NSRect newSize;
  int k;
    id theObj;
  if (!gFlags.morphed) return;
  
  newSize = [self bounds];
  newSize.origin.x += dx;
  newSize.origin.y += dy;
  [self setBounds:newSize];

  k = [enclosures count];
  while (k--) {
      theObj = [enclosures objectAtIndex:k];
      [theObj moveBy:dx :dy];
  }
  gFlags.morphed = 0;
}


- (float) headY: (int) n
{
    return [self bounds].origin.y;
}


/* some hangers modify the time value of the notes they enclose */

- (float) modifyTick: (float) t
{
  return t;
}



- (BOOL) performKey: (int) c
{
    return NO;
}


- (int)keyDownString:(NSString *)cc
{
    return -1;
}
  

- (BOOL) changeVFont: (NSFont *) f : (BOOL) all
{
    return NO;
}


- (BOOL)selectMe: (NSMutableArray *) sl : (int) d :(int)active
{
    int count = [sl count];
//    if (gFlags.selected) return self;//sb: would this prevent me from deselecting?
    gFlags.seldrag = d;
    gFlags.selected = active;
    if (active) {
        if (![sl containsObject:self]) [sl addObject: self];
    }
    else {
        [sl removeObject:self];
    }
    [self selectHangers:sl :active];
    if (count == [sl count]) return NO;
    return YES;
}


- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  return NO;
}


- moveFinished: (GraphicView *) v
{
  return self;
}


/* increment (decrement) size by ds clicks, and clear morphed flag HERE */


- (void)setSize:(int)ds
{
  int sz = gFlags.size + ds;
  if (sz < 0) sz = 0; else if (sz > 2) sz = 2;
  gFlags.size = sz;
  gFlags.morphed = 0;
}


- markHangers
{
  int k = [enclosures count];
  while (k--) [[enclosures objectAtIndex:k] mark];
  return self;
}


- markHangersExcept: (Graphic *) q
{
  int k;
  Graphic *h;
  k = [enclosures count];
  while (k--)
  {
    h = [enclosures objectAtIndex:k];
    if (h != q) h->gFlags.morphed = 1;
  }
  return self;
}


- recalcHangers
{
  Enclosure *h;
  int k = [enclosures count];
  while (k--)
  {
    h = [enclosures objectAtIndex:k];
    if (h->gFlags.morphed)
    {
      [h recalc];
      h->gFlags.morphed = 0;
    }
  }
  return self;
}


/* setSize clears morphed */

- resizeHangers: (int) ds
{
  Enclosure *h;
  int k = [enclosures count];
  while (k--)
  {
    h = [enclosures objectAtIndex:k];
    if (h->gFlags.morphed) [h setSize:ds];
  }
  return self;
}


- setHangersOnly: (int) t
{
  Enclosure *h;
  int k = [enclosures count];
  while (k--)
  {
    h = [enclosures objectAtIndex:k];
    if (h->gFlags.morphed && [h graphicType] == t)
    {
      [h setHanger];
      h->gFlags.morphed = 0;
    }
  }
  return self;
}


- setHangersExcept: (int) t
{
  Enclosure *h;
  int k = [enclosures count];
  while (k--)
  {
    h = [enclosures objectAtIndex:k];
    if (h->gFlags.morphed && [h graphicType] != t)
    {
      [h setHanger];
      h->gFlags.morphed = 0;
    }
  }
  return self;
}


/* this is called only when markHangers has not been called first. */

- setOwnHangers
{
  int k = [enclosures count];
  while (k--) [[enclosures objectAtIndex:k] setHanger];
  return self;
}


- setHangers
{
  int k = [enclosures count];
  while (k--) [[enclosures objectAtIndex:k] setHanger];
  return self;
}


- linkEnclosure: (Enclosure *) e
{
  if (enclosures == nil) enclosures = [[NSMutableArray alloc] init];
  [enclosures addObject: e];
  return self;
}

- unlinkEnclosure: (Enclosure *) e
{
    int theLocation = [enclosures indexOfObject:e];
    if (theLocation != NSNotFound) [enclosures removeObjectAtIndex: theLocation];
    return self;
}


- drawHangers: (NSRect) r nonSelectedOnly: (BOOL) nso
{
  Enclosure *h;
  int k = [enclosures count];
  while (k--)
  {
    h = [enclosures objectAtIndex:k];
    if (h->gFlags.morphed)
    {
      [h draw: r nonSelectedOnly: nso];
      h->gFlags.morphed = 0;
    }
  }
  return self;
}


- (BOOL) isDangler
{
  return NO;
}


- (BOOL) hasEnclosures
{
  if (enclosures == nil) return NO;
  return ([enclosures count] > 0);
}

- (NSArray *) enclosures
{
    return [NSArray arrayWithArray: enclosures];
}

- (int) hasHangers
{
  return 0;
}

- (BOOL)selectHangers: (id)sl :(int) b
{
    int k = [enclosures count];
    int j = [sl count];
    /*sb: FIXME!!!!!! I want to do [[enclosures objectAtIndex:k] selectObj:sl :b], I think */
//    while (k--) ((Graphic *)[enclosures objectAtIndex:k])->gFlags.selected = b;
    while (k--) [[enclosures objectAtIndex:k] selectMe:sl :0 :b];
    if (j == [sl count]) return NO;/* sb: flag whether list changed */
    return YES;
}


- closeHangers: (NSMutableArray *) cl
{
  Enclosure *q;
  int k = [enclosures count];
  while (k--) 
  {
    q = [enclosures objectAtIndex:k];
    if (![q isClosed: cl]) [q removeObj];
  }
  return self;
}


- (void) searchFor: (NSPoint) pt inObjects: (NSMutableArray *) arr
{
  Enclosure *q;
  int k = [enclosures count];
  while (k--)
  {
    q = [enclosures objectAtIndex:k];
    if ([q hit: pt])
        if (![arr containsObject:q])
            [arr addObject:q]; /*sb: note: the array retains the object */
  }
}


- setPageTable: p
{
  return self;
}


/* this draws the object, and is rarely overridden */

// Should move drawmode array inside Graphic, and then override the draw method in subclasses as needed.
- draw
{
  return [self drawMode: drawmode[gFlags.selected][gFlags.invis]];
}

/*
  Draws the graphic inside rect.  If rect is NULL, then it draws the
  entire Graphic.  If the Graphic is not intersected by rect, then it
  is not drawn at all. However, the hangers might intersect, so check them.
  This method is not intended to be overridden,
  except by Graphics that have subobjects (Systems and Staves).
  BOOL nso is whether nonselected objects only are drawn.
  It calls the overrideable method "draw".
*/

- draw: (NSRect) rect nonSelectedOnly: (BOOL) nso
{
    [self markHangers];
    if (ISASTAFFOBJ(self)) 
	[self drawVerses: rect nonSelectedOnly: nso];
    if (nso && gFlags.selected) 
	return nil;
    if ([self graphicType] == ENCLOSURE) {
	NSRect box;
	
	[(Enclosure *)self getHandleBBox: &box];
	if (NSIsEmptyRect(rect) || !NSIsEmptyRect(NSIntersectionRect(rect, box)))
	    [self draw];
    }
    else if (NSIsEmptyRect(rect) || !NSIsEmptyRect(NSIntersectionRect(rect, bounds)))
	[self draw];
    return nil;
}

+ (int) drawingModeIfSelected: (int) selected ifInvisible: (int) invisible
{
    return drawmode[selected][invisible];
}

- traceBounds
{
  NSRect b = bounds;
  b = NSInsetRect(b , -2.0 , -2.0);
  coutrect(b.origin.x, b.origin.y, b.size.width, b.size.height, 0.0, selMode);
  return self;
}


- moveBy:(const NSPoint)offset
{
    NSRect newSize;
    newSize = [self bounds];
    newSize.origin.x += floor(offset.x);
    newSize.origin.y += floor(offset.y);
    [self setBounds:newSize];

//  [self bounds].origin.x += floor(offset.x);
//  [self bounds].origin.y += floor(offset.y);
  return self;
}

- centerAt: (const NSPoint) p
{
  bounds.origin.x = floor(p.x - bounds.size.width / 2.0);
  bounds.origin.y = floor(p.y - bounds.size.width / 2.0);
  return self;
}

- sizeTo: (const NSSize *) size
{
  bounds.size.width = floor(size->width);
  bounds.size.height = floor(size->height);
  return self;
}


- boundsDidChange
{
  return self;
}


- resize:(NSEvent *)event in: view
{
    NSPoint p, last = {	0, 0 };
  id window = [view window];
  BOOL canScroll;
  BOOL timer = NO;
  NSRect b = NSZeroRect, visibleRect;
  [self getHandleBBox: &b];
  [view lockFocus];

  /* get rid of original image to prepare for instance drawing */
  // TODO why the hell is Graphic attempting to draw the page?
  // [view drawRect: b nonSelectedOnly: YES];
  // TODO why the hell is Graphic attempting to draw the page?
  // [view drawRect: b nonSelectedOnly: YES];

  [window cacheImageInRect:[view convertRect:b toView:nil]];
  [view drawSelectionInstance];
  visibleRect = [view visibleRect];
  canScroll = !NSEqualRects(visibleRect , bounds);
  if (canScroll) startTimer(timer);
  while ([event type] != NSLeftMouseUp)
  {
    p = [event locationInWindow];
    event = [NSApp nextEventMatchingMask:RESIZE_MASK untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];

    if ([event type] == NSPeriodic) event = periodicEventWithLocationSetToPoint(event, p);
    p = [event locationInWindow];
    p = [view convertPoint:p fromView:nil];
    if (p.x != last.x || p.y != last.y)
    {
      bounds.size.width = p.x - bounds.origin.x;
      bounds.size.height = p.y - bounds.origin.y;
      if (bounds.size.width < 2) bounds.size.width = 2;
      if (bounds.size.height < 2) bounds.size.height = 2;
      if (bounds.size.width == 2 && bounds.size.height == 2)
          bounds.size.height = bounds.size.width = 4;
      [self getHandleBBox: &b];
      [window disableFlushWindow]; 
      if (canScroll)
      {
	[view scrollRectToVisible:b];
	[view scrollPointToVisible:p];
      }
      [self boundsDidChange];
      [window restoreCachedImage];
      [window cacheImageInRect:[view convertRect:b toView:nil]];
      [view drawSelectionInstance];
      [view tryToPerform:@selector(updateRulers:) with:(void *)&b];
      [window enableFlushWindow];
      [window flushWindow];
      last = p;
    }
  }
  if (canScroll) stopTimer(timer);

  [view tryToPerform:@selector(updateRulers:) with:nil];
  [view unlockFocus];
  [window discardCachedImage];
  [view setNeedsDisplayInRect:b];
  
  return self;
}


/*
  Routines which may need subclassing for different Graphic types.
  By default, use PoinInRect, and set a quadrant
  code for the selected end.  hitCorners also sets a bit to tell if
  the corners were hit spot on.
*/

- (BOOL)hit:(NSPoint)p
{
  NSRect b = bounds;
  b = NSInsetRect(b , -4.0 , -4.0);
  if (NSPointInRect(p , b))
  {
    gFlags.selend = ((p.x > bounds.origin.x + 0.5 * bounds.size.width) << 1)
                   |(p.y > bounds.origin.y + 0.5 * bounds.size.height);
    return YES;
  }
  gFlags.selend = 0;
  return NO;
}


- (BOOL) hitCorners: (const NSPoint)p
{
  NSRect b = bounds;
  b = NSInsetRect(b , -4.0 , -4.0);
  if (NSPointInRect(p , b))
  {
    gFlags.selend = ((p.x > bounds.origin.x + 0.5 * bounds.size.width) << 1)
                   |(p.y > bounds.origin.y + 0.5 * bounds.size.height);
    if (gFlags.selend == 0)
    { 
      gFlags.selend |=
        (TOLFLOATEQ(bounds.origin.x, p.x, HANDSIZE)
         & TOLFLOATEQ(bounds.origin.y, p.y, HANDSIZE)) << 2;
    }
    else if (gFlags.selend == 3)
    { 
      gFlags.selend |=
        (TOLFLOATEQ(bounds.origin.x + bounds.size.width, p.x, HANDSIZE)
         & TOLFLOATEQ(bounds.origin.y + bounds.size.height, p.y, HANDSIZE)) << 2;
    }
    return YES;
  }
  gFlags.selend = 0;
  return NO;
}

 - (float) hitDistance: (NSPoint) p
{
   float d = hypot(p.x - (bounds.origin.x + 0.5 * bounds.size.width), p.y -  (bounds.origin.y + 0.5 * bounds.size.height));
   if (d > HANDSIZE * HANDSIZE) d = HANDSIZE * HANDSIZE;
   return d;
}


/*
 * All Graphics need to override these methods
 */


- drawMode: (int) m
{
    NSLog(@"Warning: did [Graphic drawMode:] for %@\n", self);
    return self;
}

- (BOOL) hasVoltaBesides: p
{
  NSLog(@"Warning: did [Graphic hasVoltaBesides]\n");
  return NO;
}


- drawVerses: (NSRect) rect nonSelectedOnly: (BOOL) nso
{
  NSLog(@"Warning: did [Graphic drawVerses:nonSelectedOnly:]\n");
  return self;
}


- (BOOL) isResizable
{
  return NO;
}


- (BOOL) isEditable
{
  return NO;
}


- (BOOL) isClosed: l /* this is, does not refer outside list l */
{
  return YES;
}


- (BOOL) hasHanger: h
{
  return NO;
}


- (BOOL) changeVFont: (int) fid
{
  return NO;
}


- (int) incrementNoteCodeBy: (int) a
{
  return -1;
}

/* Archiver-related methods. */


struct oldflags			/* for old Versions */
{
  unsigned int selected : 1;		/* selected (displays in white) */
  unsigned int morphed : 1;		/* mark bit */
  unsigned int locked : 1;		/* won't move beyond own staff */
  unsigned int invis : 1;		/* invisible (displays in gray) */
  unsigned int selend : 4;		/* selected end (16 codes possible )*/
  unsigned int size : 2;		/* size code */
  unsigned int type : 5;		/* type */
  unsigned int subtype : 4;		/* subtype */
  unsigned int editorial : 3;		/* type of editorial bracket */
};


/* some of the bits are caches, and need not be archived */

- (id) initWithCoder: (NSCoder *) aDecoder
{
    struct oldflags f;
    char b1, b2, b3, b4, b5, b6, v;

    bounds = [aDecoder decodeRect];
    v = [aDecoder versionForClassName: @"Graphic"];
    if (v == 0) {
	[aDecoder decodeValuesOfObjCTypes:"i", &f];
	gFlags.locked = f.locked;
	gFlags.invis = f.invis;
	gFlags.size = f.size;
	[self setTypeOfGraphic: f.type];
	gFlags.subtype = f.subtype;
    }
    else if (v == 1) {
	[aDecoder decodeValuesOfObjCTypes:"cccccc", &b1, &b2, &b3, &b4, &b5, &b6];
	gFlags.locked = b1;
	gFlags.invis = b2;
	gFlags.size = b3;
	[self setTypeOfGraphic: b4];
	gFlags.subtype = b5;
    }
    else if (v == 2) {
	[aDecoder decodeValuesOfObjCTypes:"@cccccc", &enclosures, &b1, &b2, &b3, &b4, &b5, &b6];
	gFlags.locked = b1;
	gFlags.invis = b2;
	gFlags.size = b3;
	[self setTypeOfGraphic: b4];
	gFlags.subtype = b5;
	[enclosures retain];
    }
    else if (v == 3) {
	[aDecoder decodeValuesOfObjCTypes:"@cccccc", &enclosures, &b1, &b2, &b3, &b4, &b5, &b6];
	gFlags.locked = b1;
	gFlags.invis = b2;
	gFlags.size = b3;
	[self setTypeOfGraphic: b4];
	gFlags.subtype = b5;
	[enclosures retain];
    }
    gFlags.selected = 0;
    gFlags.seldrag = 0;
    gFlags.morphed = 0;
    gFlags.selend = 0;
    gFlags.selbit = 0;
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b1, b2, b3, b4, b5, b6;
//  [super encodeWithCoder:aCoder]; //sb: unnec
  [aCoder encodeRect:bounds];
  b1 = gFlags.locked;
  b2 = gFlags.invis;
  b3 = gFlags.size;
  b4 = gFlags.type;
  b5 = gFlags.subtype;
  b6 = 0;
  [aCoder encodeValuesOfObjCTypes:"@cccccc", &enclosures, &b1, &b2, &b3, &b4, &b5, &b6];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
//    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setRect:bounds forKey:@"bounds"];
    [aCoder setObject:enclosures forKey:@"enclosures"];
    [aCoder setInteger:gFlags.locked forKey:@"locked"];
    [aCoder setInteger:gFlags.invis forKey:@"invis"];
    [aCoder setInteger:gFlags.size forKey:@"size"];
    [aCoder setInteger:gFlags.type forKey:@"type"];
    [aCoder setInteger:gFlags.subtype forKey:@"subtype"];
}


@end

