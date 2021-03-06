
/* Generated by Interface Builder */

#import "ChordGroup.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "GNChord.h"
#import "NoteHead.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSGraphics.h>
#import <Foundation/NSArray.h>

//#define VOICEID(v, s) (v ? NUMSTAVES + v : s)


/* note groups can have >= 1 staff objects in the group */


@implementation ChordGroup:Hanger



+ (void)initialize
{
  if (self == [ChordGroup class])
  {
      (void)[ChordGroup setVersion: 0];		/* class version, see read: */
  }
  return;
}


- init
{
  [super init];
  [self setTypeOfGraphic: CHORDGROUP];
  client = nil;
  return self;
}


- (void)dealloc
{
  [client release];
  { [super dealloc]; return; };
}


- sysInvalid
{
  return [super sysInvalidList];
}


- (int) myLevel
{
  return -1;
}


- (BOOL) isBeamed
{
  int k = [client count];
  while (k--) if ([[client objectAtIndex:k] isBeamed]) return YES;
  return NO;
}


/* return proximal chord (nearest head) of self (assume sorted into ascending y-order) */

- (GNote *) myProximal
{
  GNote *p = [client objectAtIndex:0];
  if ([p stemIsUp]) return p;
  return [client lastObject];
}



/*
  Sort into order of ascending staff
  The sort is required to be fastest when elements are in order. Shellsort.
*/

#define STRIDE_FACTOR 3

- sortGroup: (NSMutableArray *) l
{
  int c, d, f, s, k;
  StaffObj *p;
  k = [l count];
  s = 1;
  while (s <= k) s = s * STRIDE_FACTOR + 1;
  while (s > (STRIDE_FACTOR - 1))
  {
    s = s / STRIDE_FACTOR;
    for (c = s; c < k; c++)
    {
      f = NO;
      d = c - s;
      while ((d >= 0) && !f)
      {
        if ([((GNote *)[l objectAtIndex:d + s]) yMean] < [((GNote *)[l objectAtIndex:d]) yMean])
	{
	  p = [[l objectAtIndex:d] retain];
	  [l replaceObjectAtIndex:d withObject:[l objectAtIndex:d + s]];
	  [l replaceObjectAtIndex:d + s withObject:p];
          [p release];
	  d -= s;
	}
	else f = YES;
      }
    }
  }
  return self;
}


/*
  choose and return the best proximal chord (nil if inconclusive data) from list.
  best:  The beamed one; or the one whose stem isn't opposite, or the top one
  caller knows that clients in ascending y-order and number of beams = 1
*/

- pickProximal: (NSMutableArray *) nl
{
  GNote *p, *q, *bp = nil;
  p = [nl objectAtIndex:0];
  q = [nl lastObject];
  if ([p isBeamed])
  {
    if (![p stemIsUp]) return nil;
    bp = p;
  }
  else if ([q isBeamed])
  {
    if ([q stemIsUp]) return nil;
    bp = q;
  }
  else if ([self isBeamed]) return nil;
  if (bp != nil) return bp;
  else if (![p stemIsUp]) return q;
  else if ([q stemIsUp]) return p;
  else return p;
}


- setGroup
{
  GNote *p, *q;
  int k, sk = [client count];
  k = sk;
  p = [self pickProximal: client];

  [p setStemIsFixed: YES];
  while (k--)
  {
    q = [client objectAtIndex:k];
    if (q != p)
    {
      q->x = [p x];
      [q setStemIsUp: [p stemIsUp]];
      [q setStemIsFixed: YES];
      q->gFlags.locked = p->gFlags.locked;
    }
    [q resetChord];
    [q recalc];
  }
  return [self setHanger];
}


/* ensures client in same order as nl */

- linkGroup: (NSMutableArray *) nl
{
  GNote *q;
  int k = [nl count];
  client = [nl mutableCopy];
  while (k--)
  {
    q = [client objectAtIndex:k];
    [q linkhanger: self];
  }
  return self;
}


/* quadratic error checking, but low n means OK. return prox chord. */

- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) t;
{
  GNote *p, *q;
  NSMutableArray *cl = [[NSMutableArray alloc] init];
  NSMutableArray *sl = [v selectedGraphics];
  int i, j, k, ck, nb = 0, sk = [sl count], vi, vj;
  k = sk;
  while (k--)
  {
    p = [sl objectAtIndex:k];
    if ([p graphicType] == NOTE)
    {
        if ([p myChordGroup] != nil) { [cl release]; return nil; }
      [cl addObject: p];
      nb += [p isBeamed];
    }
  }
  /* check for independent voices */
  ck = [cl count];
  if (ck < 2 || nb > 1) { [cl release]; return nil; }
  for (i = 0; i < ck; i++)
  {
    p = [cl objectAtIndex:i];
    vi = [p voiceWithDefault: [[p staff] myIndex]];
    for (j = i + 1; j < ck; j++)
    {
      q = [cl objectAtIndex:j];
      vj = [q voiceWithDefault: [[q staff] myIndex]];
      if (vi == vj) { [cl release]; return nil; }
    }
  }
  [self sortGroup: cl];
  p = [self pickProximal: cl];
  if (p == nil) { [cl release]; return nil; }
  [self linkGroup: cl];
  [self setGroup];
  [cl release];
  return p;
}


/* remove from client anything not on list l.  Return whether an OK chord. */

- (BOOL) isClosed: (NSMutableArray *) l
{
  GNote *p;
  int k = [client count];
  while (k--)
  {
      p = [client objectAtIndex:k];
      if ([l indexOfObject:p] == NSNotFound) [(NSMutableArray *)client removeObjectAtIndex: k];
  }
  return ([client count] >= 2);
}


- (void)removeObj
{
    GNote *p;
    int k = [client count];
    [self retain];
    while (k--)
    {
        p = [client objectAtIndex:k];
        [p unlinkhanger: self];
    }
    [self release];
}


/*
  Override selectMe: called only if dragselect sweeps over self.
  Don't include self in slist, just select members.
*/

- (BOOL)selectGroup: (NSMutableArray *) sl : (int) d :(int)active
{
    int k = [client count];
    int slCount = [sl count];
    while (k--) [[client objectAtIndex:k] selectMember: sl : d :active];
    if (slCount == [sl count]) return NO;
    return YES;
}


- (BOOL)selectMe: (NSMutableArray *) sl : (int) d :(int)active
{
    return [self selectGroup: sl : d :active];
}


- (BOOL) hit: (NSPoint) pt
{
    return NO;
}

- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
    return NO;
}


/* prox = 1 for proximal, 0 for distal. (proximal is head nearest flag) */

- getExtremeHead: (int) prox
{
    NoteHead *h;
    GNote *p = [client objectAtIndex: 0];
    
    if (prox) {
	if (![p stemIsUp]) 
	    p = [client lastObject];
	h = [p noteHead: [p numberOfNoteHeads] - 1];
    }
    else {
	if ([p stemIsUp]) 
	    p = [client lastObject];
	h = [p noteHead: 0];
    }
    return h;
}



extern char stype[4];
extern unsigned char hasstem[10];



- drawMode: (int) m
{
  GNote *p;
  NoteHead *q, *h;
  int sb, body, st, sz;
  float dy, sl;
  BOOL b = [self isBeamed];

  p = [self myProximal];
  body = p->time.body;
  sz = p->gFlags.size;
  st = stype[p->gFlags.subtype];
  if (hasstem[body])
  {
    q = [self getExtremeHead: 1];
    h = [self getExtremeHead: 0];
    sl = [p stemLength];
    dy = [q y] - [h y];
    if (b) sb = 5;
    else
    {
      dy += sl;
      sb = body;
    }
    drawstem([p x], [h y], sb, dy, sz, [h bodyType], st, m);
    if (p->isGraced == 1) drawgrace([p x], [q y], sb, sl, sz, [q bodyType], st, m);
  }
  return self;
}


/* Archiving */

- (id)initWithCoder:(NSCoder *)aDecoder
{
  [super initWithCoder:aDecoder];
  /* v = NXTypedStreamClassVersion(s, "ChordGroup"); */
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
}
@end
