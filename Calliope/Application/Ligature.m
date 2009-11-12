/* $Id$ */
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "Ligature.h"
#import "LigatureInspector.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "GNote.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "System.h"
#import "Staff.h"
#import "Tie.h"

/*
  note groups can have >= 1 staff objects in the group.
*/

@implementation Ligature

static Ligature *proto;

static char needtheta[NUMLIGATURES] = {0, 0, 1, 1};


+ (void)initialize
{
  if (self == [Ligature class])
  {
      (void)[Ligature setVersion: 1];		/* class version, see read: */
    proto = [[self alloc] init];
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [LigatureInspector class];
}


- init
{
  [super init];
  gFlags.type = LIGATURE;
  client = nil;
  flags.fixed = 0;
  flags.place = 0;
  flags.dashed = 0;
  flags.ed = 0;
  return self;
}


- (void)dealloc
{
  [client release];
  { [super dealloc]; return; };
}


- (void)removeObj
{
    [self retain];
    [super removeGroup];
    [self release];
}


- (BOOL) canSplit
{
  return YES;
}


- (Ligature *) newFrom
{
  Ligature *t = [[Ligature alloc] init];
  t->gFlags = gFlags;
  t->hFlags = hFlags;
  t->off1 = off1;
  t->off2 = off2;
  t->flags = flags;
  return t;
}


- (BOOL) needSplit: (float) s0 : (float) s1
{
  return [super needSplitList: s0 : s1];
}


- haveSplit: (Ligature *) a : (Ligature *) b : (float) x0 : (float) x1
{
  a->off1.y = a->off2.y = off1.y;
  b->off1.y = b->off2.y = off2.y;
  return self;
}


- sysInvalid
{
  return [super sysInvalidList];
}


- coordsForHandle: (int) h  asX: (float *) x  andY: (float *) y
{
  StaffObj *p;
  if (h == 0)
  {
    if (hFlags.split & 2)
    {
      p = [client lastObject];
      *x = [p xOfStaffEnd: 0];
      *y = off1.y + p->y;
    }
    else
    { 
      p = [client objectAtIndex:0];
      *x = p->x + off1.x;
      *y = p->y + off1.y;
    }
  }
  else if (h == 1)
  {
    if (hFlags.split & 1)
    {
      p = [client objectAtIndex:0];
      *x = [p xOfStaffEnd: 1];
      *y = off2.y + p->y;
    }
    else
    {
      p = [client lastObject];
      *x = p->x + off2.x;
      *y = p->y + off2.y;
    }
  }
  return self;
}


- setHorizontal: (TimedObj *) p : (TimedObj *) q
{
  float py = p->y + off1.y;
  float qy = q->y + off2.y;
  float ey = py - qy;
  if (!flags.place ^ (ey > 0)) off2.y += ey; else off1.y -= ey;
  return self;
}


/* braoffx[left/right][type] in notewidth units; */

static float braoffx[2][4] =
{
  {-1.0, -1.0, -1.0, -0.2},
  { 0.2,  1.0,  1.0,  1.0}
};

/* braoffy[left/right][below/above] in nature units */

static float braoffy[2] =  { 1.0, -1.0 };

- setBrack
{
  float dx, dy;
  int a, sz, t;
  TimedObj *p = [client objectAtIndex:0];
  TimedObj *q = [client lastObject];
  sz = p->gFlags.size;
  a = !flags.place;
  dx = noteoffset[sz] * 2.0;
  dy = nature[sz];
  if (!(hFlags.split & 2))
  {
    if (TYPEOF(p) == NOTE) t = ([p stemIsUp] << 1) | a; else t = 1;
    off1.x = braoffx[0][t] * dx;
    off1.y = ([p yAboveBelow: a] - p->y) + braoffy[a] * dy;
  }
  if (!(hFlags.split & 1))
  {
    if (TYPEOF(q) == NOTE) t = ([q stemIsUp] << 1) | a; else t = 1;
    off2.x = braoffx[1][t] * dx;
    off2.y = ([q yAboveBelow: a] - q->y) + braoffy[a] * dy;
  }
  if (hFlags.level)
  {
    dy = hFlags.level * nature[sz];
    off1.x -= dy;
    off2.x += dy;
    if (a) dy = -dy;
    off1.y += dy;
    off2.y += dy;
  }
  if (flags.ed) [self setHorizontal: p : q];
  return self;
}


- setLine
{
  float dy;
  StaffObj *p = [client objectAtIndex:0];
  StaffObj *q = [client lastObject];
  if (!(hFlags.split & 2))
  {
    off1.x = RIGHTBOUND(p) - p->x;
    off1.y = 0;
  }
  if (!(hFlags.split & 1))
  {
    off2.x = LEFTBOUND(q) - q->x;
    off2.y = 0;
  }
  if (hFlags.level)
  {
    dy = hFlags.level * 4 * nature[gFlags.size];
    if (!flags.place) dy = -dy;
    off1.y += dy;
    off2.y += dy;
  }
  if (flags.ed) [self setHorizontal: (TimedObj *)p : (TimedObj *)q];
  return self;
}


/* set caches according to flags sn to sort, off to set default offsets */

- setGroup: (int) sn : (int) off
{
  if (sn) [super sortNotes: client];
  if (!off) return self;
  switch(gFlags.subtype)
  {
    case LIGBRACK:
    case LIGCORN:
      [self setBrack];
      break;
    case LIGLINE:
      [self setLine];
      break;
  }
  return self;
}



- setHanger
{
  [self setGroup: 1 : !flags.fixed];
  return [self recalc];
}


- setHanger: (BOOL) f1 : (BOOL) f2
{
  [self setGroup: f1 : f2];
  return [self recalc];
}


- linkGroup: (NSMutableArray *) l
{
  int k, lk, bk = 0;
  StaffObj *q;
  lk = [l count];
  k = lk;
  while (k--)
  {
    q = [l objectAtIndex:k];
    if (ISASTAFFOBJ(q)) ++bk;
  }
  if (bk < 1) return nil;
  client = [[NSMutableArray alloc] init];
  k = lk;
  while (k--)
  {
    q = [l objectAtIndex:k];
      if (ISASTAFFOBJ(q)) [(NSMutableArray *)client addObject: q];
  }
  hFlags.level = [self maxLevel] + 1;
  k = bk;
  while (k--) [[client objectAtIndex:k] linkhanger: self];
  return self;
}


- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  if ([self linkGroup: [v selectedGraphics]] == nil) return nil;
  gFlags.subtype = i;
  flags.place = proto->flags.place;
  flags.dashed = proto->flags.dashed;
  flags.ed = proto->flags.ed;
  return self;
}


- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
  if ([self linkGroup: sl] == nil) return NO;
  [self setHanger: 1 : 1];
  [v selectObj: self];
  return YES;
}  

/* special case for upgrading old format.  might be nil, to indicate split. */

/* sb: moved this to top of file: #import "Tie.h" */

- proto: (Tie *) t1 : (Tie *) t2
{
  StaffObj *p, *q;
  client = [[NSMutableArray alloc] init];
  if (t1 != nil)
  {
    p = t1->client;
      [(NSMutableArray *)client addObject: p];
    [p linkhanger: self];
  }
  if (t2 != nil)
  {
    q = t2->client;
      [(NSMutableArray *)client addObject: q];
    [q linkhanger: self];
  }
  if (t1 == nil) t1 = t2;
  gFlags.subtype = mapTieSubtype[t1->gFlags.subtype];
  flags.place = t1->flags.place;
  flags.ed = t1->flags.ed;
  flags.dashed = t1->flags.dashed;
  return [self setHanger];
}


/* remove from client anything not on list l.  Return whether an OK tuple. */

- (BOOL) isClosed: (NSMutableArray *) l
{
  int n;
  [super closeClients: l];
  n = [client count];
  return (n >= 2 || (hFlags.split && n > 0));
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



/* override hit to find handles */

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


/* override move */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : sys : (int) alt
{
  StaffObj *p;
  if (gFlags.selend)
  {
    if (hFlags.split & 1)
    {
      p = [client objectAtIndex:0];
      off2.x = pt.x - [p xOfStaffEnd: 1];
      off2.y = pt.y - p->y;
    }
    else
    {
      p = [client lastObject];
      off2.x = pt.x - p->x;
      off2.y = pt.y - p->y;
    }
    if (flags.ed)
    {
      p = [client objectAtIndex:0];
      off1.y = pt.y - p->y;
    }
  }
  else
  {
    if (hFlags.split & 2)
    {
      p = [client lastObject];
      off1.x = pt.x - [p xOfStaffEnd: 0];
      off1.y = pt.y - p->y;
    }
    else
    {
      p = [client objectAtIndex:0];
      off1.x = pt.x - p->x;
      off1.y = pt.y - p->y;
    }
    if (flags.ed)
    {
      p = [client lastObject];
      off2.y = pt.y - p->y;
    }
  }
  [self setGroup: 0 : 0];
  [self recalc];
  flags.fixed = 1;
  return YES;
}



- drawMode: (int) m
{
  StaffObj *p, *q;
  int sz;
  float px, py, qx, qy, dx, dy=0.0, d=0.0, cth=0.0, sth=0.0, th, h, v;
  /* assume client sorted by the time we arrive here */
  sz = gFlags.size;
  p = [client objectAtIndex:0];
  q = [client lastObject];
  [self coordsForHandle: 0  asX: &px  andY: &py];
  [self coordsForHandle: 1  asX: &qx  andY: &qy];
  if (gFlags.selected && !gFlags.seldrag)
  {
    chandle(px, py, m);
    chandle(qx, qy, m);
  }
  if (needtheta[gFlags.subtype])
  {
    dx = qx - px;
    dy = qy - py;
    d = hypot(dx,dy);
    cth = dx / d;
    sth = dy / d;
  }
  if (flags.dashed)
  {
    csetdash(YES, nature[sz] * 2);
  }
  th = 2.0 * staffthick[0][sz];
  switch (gFlags.subtype)
  {
    case LIGLINE:
      cline(px, py, qx, qy, th, m);
      break;
    case LIGBRACK:
      v = 2.0 * nature[sz];
      if (!flags.place) v = -v;
      if (!(hFlags.split & 2)) cmakeline(px, py, px, py + v, m);
      cmakeline(px, py + v, qx, qy + v, m);
      if (!(hFlags.split & 1)) cmakeline(qx, qy + v, qx, qy, m);
      cstrokeline(th, m);
      break;
    case LIGCORN:
      h = v = 2.0 * nature[sz];
      if (!flags.place) v = -v;
      if (!(hFlags.split & 2))
      {
        cmakeline(px, py, px, py + v, m);
        cmakeline(px, py + v, px + h * cth, (py + v) + h * sth, m);
      }
      if (!(hFlags.split & 1))
      {
        cmakeline(qx, qy, qx, qy + v, m);
        cmakeline(qx, qy + v, qx - h * cth, (qy + v) - h * sth, m);
      }
      cstrokeline(th, m);
      break;
    case LIGGLISS:
      h = acos((double) cth) * DEGpRAD;
      if (dy < 0) h = -h;
      PSsetorigin(px, py, h);
      cbrack(6, 0, 0.0, 0.0, d, 0.0, 0.0, 0.0, sz, m);
      PSresetorigin();
      break;
  }
  if (flags.dashed) 
      csetdash(NO, 0.0);

  return self;
}


/* Archiving */

- (id)initWithCoder:(NSCoder *)aDecoder
{
  char b1, b2, b3, b4, b5;
  int v;
  [super initWithCoder:aDecoder];
  v = [aDecoder versionForClassName:@"Ligature"];
  if (v == 0)
  {
    off1 = [aDecoder decodePoint];
    off2 = [aDecoder decodePoint];
    [aDecoder decodeValuesOfObjCTypes:"iccccc", &UID, &b1, &b2, &b3, &b4, &b5];
    flags.fixed = b1;
    flags.place = b2;
    hFlags.split = b3;
    flags.dashed = b4;
    flags.ed = b5;
  }
  else if (v == 1)
  {
    off1 = [aDecoder decodePoint];
    off2 = [aDecoder decodePoint];
    [aDecoder decodeValuesOfObjCTypes:"cccc", &b1, &b2, &b4, &b5];
    flags.fixed = b1;
    flags.place = b2;
    flags.dashed = b4;
    flags.ed = b5;
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b1, b2,/* b3,*/ b4, b5;
  [super encodeWithCoder:aCoder];
  [aCoder encodePoint:off1];
  [aCoder encodePoint:off2];
  b1 = flags.fixed;
  b2 = flags.place;
  b4 = flags.dashed;
  b5 = flags.ed;
  [aCoder encodeValuesOfObjCTypes:"cccc", &b1, &b2, &b4, &b5];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setPoint:off1 forKey:@"off1"];
    [aCoder setPoint:off2 forKey:@"off2"];
    [aCoder setInteger:flags.fixed forKey:@"fixed"];
    [aCoder setInteger:flags.place forKey:@"place"];
    [aCoder setInteger:flags.dashed forKey:@"dashed"];
    [aCoder setInteger:flags.ed forKey:@"ed"];
}


@end
