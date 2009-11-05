/* $Id$ */
#import <Foundation/Foundation.h>
#import "TieNew.h"
#import "TieInspector.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "TimedObj.h"
#import "GNote.h"
#import "NoteHead.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "System.h"
#import "DrawApp.h"
#import "Staff.h"
/* sb: moved import from middle of file: */
#import "Tie.h"

@implementation TieNew


/* whether the placement and constraint matrices are enabled for each subtype */

//static char enablePlace[NUMTIESNEW] = {1, 1};


static TieNew *proto;


+ (void)initialize
{
  if (self == [TieNew class])
  {
      (void)[TieNew setVersion: 3];		/* class version, see read: */
    proto = [[TieNew alloc] init];
  }
  return;
}


+ myInspector
{
  return [TieInspector class];
}


+ myPrototype
{
  return proto;
}



#if 0
/*sb: this does not seem to be used at all */
static void orderXY(float *x, float *y)
{
  float t;
  if (x[0] > x[1])
  {
    t = x[0];
    x[0] = x[1];
    x[1] = t;
    t = y[0];
    y[0] = y[1];
    y[1] = t;
  }
}
#endif

/* some diagnostic code to catch malformed head indices */

- checkHead1: (StaffObj *) p
{
  int n;
  if (head1 < 0)
  {
    head1 = 0;
      NSLog(@"head1 has index < 0. Fixed.\n");
  }
  else if (TYPEOF(p) == NOTE)
  {
    n = [((GNote *)p) numberOfNoteHeads];
      if (n == 0) NSLog(@"head1 has no notehead!\n");
    else if (head1 >= n)
    {
      head1 = n - 1;
      NSLog(@"head1 has index > noteheadcount. Fixed.\n");
    }
  }
  else if (head1 > 0)
  {
    head1 = 0;
      NSLog(@"head1 has index > 0. Fixed.\n");
  }
  return self;
}


- checkHead2: (StaffObj *) p
{
  int n;
  if (head2 < 0)
  {
    head2 = 0;
      NSLog(@"head2 has index < 0. Fixed.\n");
  }
  else if (TYPEOF(p) == NOTE)
  {
    n = [((GNote *)p) numberOfNoteHeads];
      if (n == 0) NSLog(@"head2 has no notehead!\n");
    else if (head2 >= n)
    {
      head2 = n - 1;
        NSLog(@"head2 has index > noteheadcount. Fixed.\n");
    }
  }
  else if (head2 > 0)
  {
    head2 = 0;
      NSLog(@"head2 has index > 0. Fixed.\n");
  }
  return self;
}


- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ type %d, head1=%d, head2=%d, clients=%d\n", [super description], gFlags.subtype, head1, head2, [client count]];
}

- init
{
  [super init];
  gFlags.type = TIENEW;
  gFlags.subtype = TIEBOWNEW;
  client = nil;
  head1 = head2 = 0;
  flags.fixed = 0;
  flags.place = 0;
  flags.ed = 0;
  flags.dashed = 0;
  flags.flat = 0;
  return self;
}


- (TieNew *) newFrom
{
  TieNew *t = [[TieNew alloc] init];
  t->gFlags = gFlags;
  t->hFlags = hFlags;
  t->head1 = head1;
  t->head2 = head2;
  t->off1 = off1;
  t->off2 = off2;
  t->con1 = con1;
  t->con2 = con2;
  t->flags = flags;
  return t;
}


- (BOOL) canSplit
{
  return YES;
}


- (BOOL) needSplit: (float) s0 : (float) s1
{
  return [super needSplitList: s0 : s1];
}


- sysInvalid
{
  return [super sysInvalidList];
}


- (void)removeObj
{
    [self retain];
    [super removeGroup];
    [self release];
}


- (void)dealloc
{
    [client release];
    [super dealloc];
}


- (int) whichEnd: (StaffObj *) p
{
    if ([client count])
        if (p == [client objectAtIndex:0]) return 1;
        else if (p == [client lastObject]) return 2;
    return 0;
}


/*
  handles in order:
  0=left end, 1 = right end, 2 = left control, 3 = right control,
  4 = left thick control, 5 = right thick control.
*/

- coordsForHandle: (int) h  asX: (float *) x  andY: (float *) y
{
  float dx, dy, x0, y0, x1, y1, th, t, d;
  StaffObj *p;
  switch (h)
  {
    case 0:
      if (hFlags.split & 2)
      {
        p = [client lastObject];
        *x = [p xOfStaffEnd: 0];
        [self checkHead1: p];
        *y = [p headY: head1] + off1.y;
      }
      else
      {
        p = [client objectAtIndex:0];
        *x = p->x + off1.x;
        [self checkHead1: p];
        *y = [p headY: head1] + off1.y;
      }
      break;
    case 1:
      if (hFlags.split & 1)
      {
        p = [client objectAtIndex:0];
        *x = [p xOfStaffEnd: 1];
        [self checkHead2: p];
        *y = [p headY: head2] + off2.y;
      }
      else
      {
         p = [client lastObject];
        *x = p->x + off2.x;
        [self checkHead2: p];
        *y = [p headY: head2] + off2.y;
      }
      break;
    case 2:
      [self coordsForHandle: 0  asX: &x0  andY: &y0];
      [self coordsForHandle: 1  asX: &x1  andY: &y1];
      dx = x1 - x0;
      dy = y1 - y0;
      *x = x0 + con1.x * dx - con1.y * dy;
      *y = y0 + con1.x * dy + con1.y * dx;
      break;
    case 3:
      [self coordsForHandle: 0  asX: &x0  andY: &y0];
      [self coordsForHandle: 1  asX: &x1  andY: &y1];
      dx = x1 - x0;
      dy = y1 - y0;
      *x = x0 + con2.x * dx - con2.y * dy;
      *y = y0 + con2.x * dy + con2.y * dx;
      break;
    case 4:
      th = nature[gFlags.size] * 0.5;
      [self coordsForHandle: 0  asX: &x0  andY: &y0];
      [self coordsForHandle: 1  asX: &x1  andY: &y1];
      dx = x1 - x0;
      dy = y1 - y0;
      d = hypot(dx, dy);
      t = (con1.y * d - th) / d;
      *x = x0 + con1.x * dx - t * dy;
      *y = y0 + con1.x * dy + t * dx;
      break;
    case 5:
      th = nature[gFlags.size] * 0.5;
      [self coordsForHandle: 0  asX: &x0  andY: &y0];
      [self coordsForHandle: 1  asX: &x1  andY: &y1];
      dx = x1 - x0;
      dy = y1 - y0;
      d = hypot(dx, dy);
      t = (con2.y * d - th) / d;
      *x = x0 + con2.x * dx - t * dy;
      *y = y0 + con2.x * dy + t * dx;
      break;
  }
  return self;
}


- (BOOL) getHandleBBox: (NSRect *) r
{
  int i;
  float x, y;
  NSRect b;
  [self coordsForHandle: 0  asX: &x  andY: &y];
  *r = NSMakeRect(x - HANDSIZE, y - HANDSIZE, 2 * HANDSIZE, 2 * HANDSIZE);
  for (i = 1; i < 4; i++)
  {
    [self coordsForHandle: i  asX: &x  andY: &y];
    b = NSMakeRect(x - HANDSIZE, y - HANDSIZE, 2 * HANDSIZE, 2 * HANDSIZE);
    *r  = NSUnionRect(b , *r);
  }
  return YES;
}


/* called on chords to allow for tie to the right-hand side of a dotted note */

static float anyDotFor(GNote *p)
{
    return (p->time.dot) ? [p dotOffset] : 0.0;
}


/* called on chords to allow for tie to accidental or the left-hand side of a wrong side head */

static float anyHeadFor(GNote *p, int n)
{
    NoteHead *noteHead = [p noteHead: n];
    float w = 0.0;

    if (!(p->time.stemup) && [noteHead isReverseSideOfStem]) 
	w = -2.0 * halfwidth[(int)p->gFlags.size][[noteHead bodyType]][p->time.body];
    if ([noteHead accidentalOffset] < w)
	w = [noteHead accidentalOffset]; 
    return w;
}


/* tieoffx[left/right][type] in notewidth units; tieoffy[left/right][type] in nature units */

static float tieoffx[2][8] =
{
  {0.0,  0.0,  0.0,  0.0,  0.0,  0.6,  0.0,  0.6},
  {0.0, -0.6,  0.0,  0.0, -0.6,  0.0,  0.0,  0.0}
};

static float tieoffy[2][8] =
{
  {-1.5,  1.5, -1.5,  1.5,  1.5,  -1.0,  1.5, -1.0},
  {-1.5,  1.5, -1.5,  1.5,  1.0,  -1.5,  1.5, -1.5}
};

/* sluroffx[type] in notewidth units; */

/*sb: does not seem to be used at all */
//static float sluroffx[4] = { -0.5,  0.0,  0.0,  0.5};

/* sluroffy: [below/above] */

static float sluroffy[2] = { 1.0, -1.0};


static char tiedir[8] = {1, 0, 1, 0, 0, 1, 0, 1};


/* return a suitable v parameter to use as a default depth */

- (float) depthParam
{
  float x0, y0, x1, y1, d, t;
  [self coordsForHandle: 0  asX: &x0  andY: &y0];
  [self coordsForHandle: 1  asX: &x1  andY: &y1];
  d = hypot(x1 - x0, y1 - y0);
  if (d < 5) return d;
  t = d * 0.25;
  if (t > 12.0) t = 12.0;
  if (t < 4.0) t = 4.0;
  return t / d;
}


- setBow
{
  int t, sz, psu, qsu, a, phk;
  float dx, dy;
  GNote *p, *q;
  NoteHead *noteHead;
  p = [client objectAtIndex:0];
  q = [client lastObject];
  sz = p->gFlags.size;
  dx = noteoffset[sz] * 2.0;
  dy = nature[sz];
  if (TYPEOF(p) == NOTE && TYPEOF(q) == NOTE)
  {
    phk = [p numberOfNoteHeads];
    if (phk > 1)
    {
      if (head1 == 0) a = !p->time.stemup;
      else
      {
        if (head1 + 1 == phk) a = p->time.stemup;
        else
        {
          noteHead = [p noteHead: head1];
          a = ([noteHead staffPosition] < 4);
        }
      }
      dx = noteoffset[sz] + 0.5 * nature[sz];
      off1.x = dx + anyDotFor(p);
      off1.y = 0.0;
      off2.x = -dx + anyHeadFor(q, head2);
      off2.y = 0.0;
      con1.x = 0.25;
      con2.x = 0.75;
    }
    else
    {
      psu = p->time.stemup;
      qsu = q->time.stemup;
      t = (psu << 2) | (qsu << 1) | flags.place;
      off1.x = tieoffx[0][t] * dx;
      off1.y = tieoffy[0][t] * dy;
      off2.x = tieoffx[1][t] * dx;
      off2.y = tieoffy[1][t] * dy;
      con1.x = 0.1;
      con2.x = 0.9;
      a = tiedir[t];
    }
  }
  else 
  {
    if (TYPEOF(p) == NOTE)
    {
      psu = qsu = p->time.stemup;
      t = (psu << 2) | (qsu << 1) | flags.place;
      a = tiedir[t];
      off1.x = tieoffx[0][t] * dx;
      off1.y = tieoffy[0][t] * dy;
    }
    else
    {
      t = flags.place;
      a = tiedir[t];
      off1.x = 0.0;
      off1.y = ([p boundAboveBelow: a] - p->y) + sluroffy[a] * dy;
    }
    if (TYPEOF(q) == NOTE)
    {
      psu = qsu = q->time.stemup;
      t = (psu << 2) | (qsu << 1) | flags.place;
      a = tiedir[t];
      off2.x = tieoffx[1][t] * dx;
      off2.y = tieoffy[1][t] * dy;
    }
    else
    {
      t = flags.place;
      a = tiedir[t];
      off2.x = 0.0;
      off2.y = ([q boundAboveBelow: a] - q->y) + sluroffy[a] * dy;
    }
    con1.x = 0.1;
    con2.x = 0.9;
  }
  if (hFlags.level)
  {
    dy = hFlags.level * 2 * nature[sz];
    if (a) dy = -dy;
    off1.y += dy;
    off2.y += dy;
  }
  dy = [self depthParam];
  if (a) dy = -dy;
  if (flags.flat)
  {
    con1.x = 0.25;
    con2.x = 0.75;
    dy *= 0.75;
  }
  con1.y = con2.y = dy;
  return self;
}


- setSlurFor: (TimedObj *) p : (int) a : (int) h : (float) dy : (float *) ox : (float *) oy
{
  float ex, ey;
  if (TYPEOF(p) == NOTE)
  {
    if (a == p->time.stemup)
    {
      [p hitBeamAt: &ex : &ey];
      *ox = ex - p->x;
      if (p->time.nostem) *oy = sluroffy[a] * dy;
      else *oy = ey - [p headY: h] + sluroffy[a] * dy;
    }
    else
    {
      *ox = 0.0;
      *oy = sluroffy[a] * dy;
    }
  }
  else
  {
    *ox = 0.0;
    *oy = ([p boundAboveBelow: a] - p->y) + sluroffy[a] * dy;
  }
  return self;
}


- setSlur
{
  TimedObj *p, *q;
  float dx, dy;
  int a, sz;
  p = [client objectAtIndex:0];
  q = [client lastObject];
  sz = p->gFlags.size;
  dx = noteoffset[sz] * 2.0;
  dy = nature[sz] * 2;
  a = !(flags.place);
  [self checkHead1: p];
  [self setSlurFor: p : a : head1 : dy : &(off1.x) : &(off1.y)];
  [self checkHead2: p];
  [self setSlurFor: q : a : head2 : dy : &(off2.x) : &(off2.y)];
  con1.x = 0.25;
  con2.x = 0.75;
  con1.y = con2.y = [self depthParam] * sluroffy[a];
  return self;
}


/* set above, offset, depth. if s1=s2, do both. */

- setGroup: (int) sn : (int) off
{
  if (sn) [super sortNotes: client];
  if (!off) return self;
  if (gFlags.subtype == TIEBOWNEW) [self setBow]; else [self setSlur];
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

- linkGroup: (NSMutableArray *) l : (int) i
{
  int k, lk, bk = 0, st;
  StaffObj *q;
  GNote *n, *m;
  BOOL f = 0;
  lk = [l count];
  k = lk;
  while (k--)
  {
    q = [l objectAtIndex:k];
    if (ISASTAFFOBJ(q)) ++bk;
  }
  if (bk < 2) return nil;
  client = [[NSMutableArray alloc] init];
  bk=0;//sb: added this to prevent array index probs
  st = i;
  k = [l count];
  findEndpoints(l, &m, &n);
  if (TYPEOF(n) == NOTE && TYPEOF(m) == NOTE)
  {
    if (n->staffPosition == m->staffPosition)
    {
      [(NSMutableArray *)client addObject: m];
      [(NSMutableArray *)client addObject: n];
      bk = 2;
      f = 1;
    }
  }
  if (!f)
  {
    while (k--)
    {
      q = [l objectAtIndex:k];
      if (ISASTAFFOBJ(q))
      {
          [(NSMutableArray *)client addObject: q];
        ++bk;
        if (!ISATIMEDOBJ(q)) st = TIESLURNEW;
      }
    }
  }
  gFlags.subtype = st;
  head1 = head2 = 0;
  hFlags.level = [self maxLevel] + 1;
  k = bk;
  while (k--) [[client objectAtIndex:k] linkhanger: self];
  return self;
}


- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  if ([self linkGroup: [v selectedGraphics] : i] == nil) return nil;
  flags.fixed = proto->flags.fixed;
  flags.place = proto->flags.place;
  flags.ed = proto->flags.ed;
  flags.dashed = proto->flags.dashed;
  return self;
}


- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
  if ([self linkGroup: sl : gFlags.subtype] == nil) return NO;
  [self setHanger: 1 : 1];
  [v selectObj: self];
  return YES;
}  


/* special case for tieing noteheads of known chords */

- proto: (GraphicView *) v : (StaffObj *) p : (StaffObj *) q : (int) i
{
  client = [[NSMutableArray alloc] init];
    [(NSMutableArray *)client addObject: p];
    [(NSMutableArray *)client addObject: q];
  [p linkhanger: self];
  [q linkhanger: self];
  gFlags.subtype = TIEBOWNEW;
  head1 = head2 = i;
  flags.fixed = proto->flags.fixed;
  flags.place = proto->flags.place;
  flags.ed = proto->flags.ed;
  flags.dashed = proto->flags.dashed;
  return self;
}

/* special case for upgrading old format.  might be nil, to indicate split. */

- proto: (Tie *) t1 : (Tie *) t2
{
  StaffObj *p, *q;
  client = [[NSMutableArray alloc] init];
  head1 = head2 = 0;
  if (t1 != nil)
  {
    p = t1->client;
      [(NSMutableArray *)client addObject: p];
    [p linkhanger: self];
    head1 = t1->headnum;
  }
  else hFlags.split |= 2;
  if (t2 != nil)
  {
    q = t2->client;
      [(NSMutableArray *)client addObject: q];
    [q linkhanger: self];
    head2 = t2->headnum;
  }
  else hFlags.split |= 1;
  if (t1 == nil) t1 = t2;
  gFlags.subtype = mapTieSubtype[t1->gFlags.subtype];
  flags.place = t1->flags.place;
  flags.ed = t1->flags.ed;
  flags.dashed = t1->flags.dashed;
  return [self presetHanger];
}


- setDefault: (int) t
{
  flags.place = 0;
  flags.fixed = 0;
  flags.dashed = 0;
  return self;
}


- (BOOL) isClosed: (NSMutableArray *) l
{
  int n;
  [super closeClients: l];
  n = [client count];
  return (n >= 2 || (hFlags.split && n > 0));
}

- (BOOL) hit: (NSPoint) p
{
  return [super hit: p : 0 : 3];
}

- (float) hitDistance: (NSPoint) p
{
  return [super hitDistance: p : 0 : 3];
}


/* solve for control point parameters given target point */

- (BOOL) solveParam: (float) x : (float) y : (float *) u : (float *) v
{
  float x0, y0, x1, y1, dx, dy, ds, wx, wy, t;
  [self coordsForHandle: 0  asX: &x0  andY: &y0];
  [self coordsForHandle: 1  asX: &x1  andY: &y1];
  dx = x1 - x0;
  dy = y1 - y0;
  ds = (dx * dx) + (dy * dy);
  if (ds < 5) return NO;
  wx = x0 - x;
  wy = y0 - y;
  t = -((dx * wx + dy * wy) / ds);
  wx = (x0 + t * dx) - x;
  wy = (y0 + t * dy) - y;
  *u = t;
  *v = -((dx * wy - dy * wx) / ds);
  return YES;
}


/*
  alt move moves control points symmetrically relative to each other.
  normal move moves each handle separately
*/

- (BOOL) move: (float) mdx : (float) mdy : (NSPoint) pt : sys : (int) alt
{
  StaffObj *p;
  float u, v;
  switch (gFlags.selend)
  {
    case 0:
      if (alt) return NO;
      if (hFlags.split & 2)
      {
        p = [client lastObject];
        off1.x = pt.x - [p xOfStaffEnd: 0];
        [self checkHead1: p];
        off1.y = pt.y - [p headY: head1];
      }
      else
      {
        p = [client objectAtIndex:0];
        off1.x = pt.x - p->x;
        [self checkHead1: p];
        off1.y = pt.y - [p headY: head1];
      }
      break;
    case 1:
      if (alt) return NO;
      if (hFlags.split & 1)
      {
        p = [client objectAtIndex:0];
        off2.x = pt.x - [p xOfStaffEnd: 1];
        [self checkHead2: p];
        off2.y = pt.y - [p headY: head2];
      }
      else
      {
        p = [client lastObject];
        off2.x = pt.x - p->x;
        [self checkHead2: p];
        off2.y = pt.y - [p headY: head2];
      }
      break;
    case 2:
      if (![self solveParam: pt.x : pt.y : &u : &v]) return NO;
      con1.x = u;
      con1.y = v;
      break;
      if (alt || flags.flat)
      {
        con2.x = 1.0 - u;
        con2.y = v;
      }
    case 3:
      if (![self solveParam: pt.x : pt.y : &u : &v]) return NO;
      con2.x = u;
      con2.y = v;
      if (alt || flags.flat)
      {
        con1.x = 1.0 - u;
        con1.y = v;
      }
      break;
  }
  [self recalc];
  flags.fixed = 1;
  return YES;
}


/*
  backsolve Bezier to find (x,y) for 0.5 t
*/

void drawEdmark(float x0, float y0, float x3, float y3, float x1, float y1, float x2, float y2, int sz, int m)
{
  float ax, ay, bx, by, cx, cy, t, t2, t3, ex, ey;
  cx = 3 * (x1 - x0);
  cy = 3 * (y1 - y0);
  bx = 3 * (x2 - x1) - cx;
  by = 3 * (y2 - y1) - cy;
  ax = x3 - x0 - cx - bx;
  ay = y3 - y0 - cy - by;
  t = 0.5;
  t2 = t * t;
  t3 = t2 * t;
  ex = ax * t3 + bx * t2 + cx * t + x0;
  ey = ay * t3 + by * t2 + cy * t + y0;
  cline(ex, ey - 2 * nature[sz], ex, ey + 2 * nature[sz], nature[sz] * 0.25, m);
}



- drawMode: (int) m
{
  float x[6], y[6], th;
  int i, sz = gFlags.size;
  for (i = 0; i < 6; i++)
  {
    [self coordsForHandle: i  asX: &(x[i])  andY: &(y[i])];
    if (i < 4 && gFlags.selected && !gFlags.seldrag) chandle(x[i], y[i], m);
  }
  if (flags.dashed)
  {
    csetdash(YES, nature[sz] * 2);
  }
  th = nature[sz] * 0.5;
  if (flags.flat) cflat(x[0], y[0], x[1], y[1], con1.x, con1.y, con2.x, con2.y, th * 0.75, flags.dashed, m);
  else ccurve(x[0], y[0], x[1], y[1], x[2], y[2], x[3], y[3], x[4], y[4], x[5], y[5], th, flags.dashed, m);
  if (flags.ed) drawEdmark(x[0], y[0], x[1], y[1], x[2], y[2], x[3], y[3], sz, m);
  if (flags.dashed) 
      csetdash(NO, 0.0);

  return self;
}



/* Archiving */


- (id)initWithCoder:(NSCoder *)aDecoder
{
  char r1, r2, r4, r5, r6, r7;
  int v = [aDecoder versionForClassName:@"TieNew"];
  [super initWithCoder:aDecoder];
  off1 = [aDecoder decodePoint];
  off2 = [aDecoder decodePoint];
  con1 = [aDecoder decodePoint];
  con2 = [aDecoder decodePoint];
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccccc", &head1, &head2, &r1, &r2, &r4, &r5, &r6];
    flags.fixed = r1;
    flags.place = r2;
    flags.ed = r4;
    flags.dashed = r5;
    hFlags.split = r6;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"iccccccc", &UID, &head1, &head2, &r1, &r2, &r4, &r5, &r6];
    flags.fixed = r1;
    flags.place = r2;
    flags.ed = r4;
    flags.dashed = r5;
    hFlags.split = r6;
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"icccccccc", &UID, &head1, &head2, &r1, &r2, &r4, &r5, &r6, &r7];
    flags.fixed = r1;
    flags.place = r2;
    flags.ed = r4;
    flags.dashed = r5;
    hFlags.split = r6;
    flags.flat = r7;
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccccc", &head1, &head2, &r1, &r2, &r4, &r5, &r7];
    flags.fixed = r1;
    flags.place = r2;
    flags.ed = r4;
    flags.dashed = r5;
    flags.flat = r7;
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder;
{
  char r1, r2, r4, r5, /*r6,*/ r7;
    [super encodeWithCoder:aCoder];
    [aCoder encodePoint:off1];
    [aCoder encodePoint:off2];
    [aCoder encodePoint:con1];
    [aCoder encodePoint:con2];
  r1 = flags.fixed;
  r2 = flags.place;
  r4 = flags.ed;
  r5 = flags.dashed;
  r7 = flags.flat;
  [aCoder encodeValuesOfObjCTypes:"ccccccc", &head1, &head2, &r1, &r2, &r4, &r5, &r7];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setPoint:off1 forKey:@"off1"];
    [aCoder setPoint:off2 forKey:@"off2"];
    [aCoder setPoint:con1 forKey:@"con1"];
    [aCoder setPoint:con2 forKey:@"con2"];                                      

    [aCoder setInteger:head1 forKey:@"head1"];
    [aCoder setInteger:head2 forKey:@"head2"];
    [aCoder setInteger:flags.fixed forKey:@"fixed"];
    [aCoder setInteger:flags.place forKey:@"place"];
    [aCoder setInteger:flags.ed forKey:@"ed"];
    [aCoder setInteger:flags.dashed forKey:@"dashed"];
    [aCoder setInteger:flags.flat forKey:@"flat"];
}

@end
