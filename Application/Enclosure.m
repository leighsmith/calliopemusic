/* $Id$ */

#import <Foundation/Foundation.h>
#import "Enclosure.h"
#import "EnclosureInspector.h"
#import "GVSelection.h"
#import "System.h"
#import "DrawingFunctions.h"
#import "muxlow.h"

extern void graphicListBBoxEx(NSRect *b, NSMutableArray *l, Graphic *ex);

@implementation Enclosure

static Enclosure *proto;

+ (void)initialize
{
  if (self == [Enclosure class])
  {
      (void)[Enclosure setVersion: 1];	/* class version, see read: */ /*sb: set to 1 for List conversion */
    proto = [self alloc];
    proto->gFlags.subtype = 0;
    proto->gFlags.locked = 0;
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [EnclosureInspector class];
}


- init
{
  [super init];
  [self setTypeOfGraphic: ENCLOSURE];
  notes = nil;
  return self;
}


- newFrom
{
  Enclosure *p = [[Enclosure alloc] init];
  p->gFlags = gFlags;
  p->x1 = x1;
  p->y1 = y1;
  p->x2 = x2;
  p->y2 = y2;
  return p;
}


- (BOOL) isDangler
{
  return YES;
}


- sysInvalid
{
    int k = [notes count];
    while (k--) [[notes objectAtIndex:k] sysInvalid];
    return self;
}


- (void) dealloc
{
    [notes release];
    notes = nil;
    [super dealloc];
    return;
}


/* X-standoff distances from corner bounds */

float pxoff[7] = {1.5, 0.0, 2.5, 0.0, 2.0, 2.0, 2.0};
float qxoff[7] = {2.0, 0.0, 3.0, 0.0, 2.0, 2.0, 2.0};


- setEnclosure: (int) sn : (int) off
{
  float ns;
  Graphic *p, *q;
  NSRect b;
//  if (sn) [super sortNotes: notes];
  if (!off) return self;
  ns = nature[gFlags.size];
  p = [notes objectAtIndex:0];
  q = [notes lastObject];
  graphicListBBoxEx(&b, notes, self);
  x1 = b.origin.x - (pxoff[gFlags.subtype] * ns) - p->bounds.origin.x;
  y1 = b.origin.y - ns - p->bounds.origin.y;
  x2 = b.origin.x + b.size.width + (qxoff[gFlags.subtype] * ns) - q->bounds.origin.x;
  y2 = b.origin.y + b.size.height + ns - q->bounds.origin.y;
  return self;
}


- setHanger: (BOOL) f1 : (BOOL) f2
{
  [self setEnclosure: f1 : f2];
  return [self recalc];
}


- setHanger
{
  return [self setHanger: 1 : !gFlags.locked];
}


- presetHanger
{
  return [self setHanger: 1 : 1];
}


- linkGroup: (NSMutableArray *) sl
{
  int k, bk = 0;
  Graphic *q;
  k = [sl count];
  if (k == 0) return nil;
  notes = [[NSMutableArray alloc] init];
  while (k--)
  {
    q = [sl objectAtIndex:k];
    [notes addObject: q];
    ++bk;
  }
  k = bk;
  while (k--) [[notes objectAtIndex:k] linkEnclosure: self];
  return self;
}


- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
{
    if ([self linkGroup: [v selectedGraphics]] == nil) return nil;
    gFlags.subtype = proto->gFlags.subtype;
    gFlags.locked = proto->gFlags.locked;
    [self setEnclosure: 1 : 1];
    return self;
}


- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
    if ([self linkGroup: sl] == nil) return NO;
    [self setHanger: 1 : 1];
    [v selectObj: self];
    return YES;
}  


/* remove from notes anything not on list l.  Return whether an OK tuple. */

- (BOOL) isClosed: (NSMutableArray *) l
{
    id p;
    int k = [notes count];
    while (k--)
      {
        p = [notes objectAtIndex:k];
        if ([l indexOfObject:p] == NSNotFound) [notes removeObjectAtIndex: k];
      }
    return ([notes count] > 0);
}


- (void)removeObj
{
  Graphic *p;
  int k;
  k = [enclosures count];
  while (k--) [[enclosures objectAtIndex:k] removeObj];
  k = [notes count];
  [self retain]; /* so the releasing by the notesdoes not free us too soon */
  while (k--)
  {
    p = [notes objectAtIndex:k];
    [p unlinkEnclosure: self];
  }
  [self release];
}


- coordsForHandle: (int) h  asX: (float *) x  andY: (float *) y
{
  StaffObj *p;
  if (h == 0)
  {
    p = [notes objectAtIndex:0];
    *x = p->bounds.origin.x + x1;
    *y = p->bounds.origin.y + y1;
  }
  else if (h == 1)
  {
    p = [notes lastObject];
    *x = p->bounds.origin.x + x2;
    *y = p->bounds.origin.y + y2;
  }
  return self;
}


- (BOOL) getHandleBBox: (NSRect *) r
{
  float x, y;
  NSRect b;
  [self coordsForHandle: 0  asX: &x  andY: &y];
  *r = NSMakeRect(x - HANDSIZE, y - HANDSIZE, 2 * HANDSIZE, 2 * HANDSIZE);
  [self coordsForHandle: 1  asX: &x  andY: &y];
  b = NSMakeRect(x - HANDSIZE, y - HANDSIZE, 2 * HANDSIZE, 2 * HANDSIZE);
  *r  = NSUnionRect(b , *r);
  return YES;
}


/* override hit. Same as Hanger. Ought to converge these somehow. */

- (BOOL) hit: (NSPoint) p
{
  int i;
  float x, y;
  for (i = 0; i <= 1; i++)
  {
    [self coordsForHandle: i  asX: &x  andY: &y];
    if (TOLFLOATEQ(p.x, x, HANDSIZE) && TOLFLOATEQ(p.y, y, HANDSIZE))
    {
      gFlags.selend = i;
      return YES;
    }
  }
  return NO;
}

- (float) hitDistance: (NSPoint) p
{
  int i;
  float x, y;
  for (i = 0; i <= 1; i++)
  {
    [self coordsForHandle: i  asX: &x  andY: &y];
    if (TOLFLOATEQ(p.x, x, HANDSIZE) && TOLFLOATEQ(p.y, y, HANDSIZE))
    {
      return hypot(p.x - x, p.y - y);
    }
  }
  return MAXFLOAT;
}

/*
  Unless overridden, hangers ignore requests to move.  Trapped here
  so that Graphic does not move the enclosure's bounding box!
*/

- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  Graphic *n;
  if (gFlags.selend)
  {
    n = [notes lastObject];
    x2 = p.x - n->bounds.origin.x;
    y2 = p.y - n->bounds.origin.y;
  }
  else
  {
    n = [notes objectAtIndex:0];
    x1 = p.x - n->bounds.origin.x;
    y1 = p.y - n->bounds.origin.y;
  }
  [self setEnclosure: 0 : 0];
  [self recalc];
  return YES;
}


- drawMode: (int) m
{
  Graphic *p, *q;
  int sz;
  float px, py, qx, qy;
  /* assume notes sorted by the time we arrive here */
  
  sz = gFlags.size;
  p = [notes objectAtIndex:0];
  q = [notes lastObject];
  px = p->bounds.origin.x + x1;
  py = p->bounds.origin.y + y1;
  qx = q->bounds.origin.x + x2;
  qy = q->bounds.origin.y + y2;
  if (gFlags.selected && !gFlags.seldrag)
  {
    chandle(px, py, m);
    chandle(qx, qy, m);
//    coutrect(p->bounds.origin.x, p->bounds.origin.y, q->bounds.origin.x - p->bounds.origin.x, q->bounds.origin.y - p->bounds.origin.y, 0.0, m);
  }
  cenclosure(gFlags.subtype, px, py, qx, qy, barwidth[0][sz], sz, m);
  return self;
}

- recalc /* put in here for debugging purposes */
{
    return [super recalc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeValuesOfObjCTypes:"@ffff", &notes, &x1, &y1, &x2, &y2];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setObject:notes forKey:@"notes"];
    [aCoder setFloat:x1 forKey:@"x1"];
    [aCoder setFloat:y1 forKey:@"y1"];
    [aCoder setFloat:x2 forKey:@"x2"];
    [aCoder setFloat:y2 forKey:@"y2"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v = [aDecoder versionForClassName:@"Enclosure"];
  [super initWithCoder:aDecoder];
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"@ffff", &notes, &x1, &y1, &x2, &y2];
  }
  else if (v == 1)
    {
      [aDecoder decodeValuesOfObjCTypes:"@ffff", &notes, &x1, &y1, &x2, &y2];
    }

  return self;
}

@end
