/* $Id$ */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Beam.h"
#import "BeamInspector.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "GNote.h"
#import "GNChord.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "System.h"

@implementation Beam

#define MINSTEMLEN 4.0		/* minimum stem length within a beam in ss's (sock size) */
#define NUMBEAMS 32		/* number of distinct slants */
#define BEAMSLOPE 0.5		/* maximum slope (tan(26+ deg)) */
#define MIXEDSLOPE 0.25		/* max mixed slope (tan(14+ deg) */
#define NUMNOTES 256		/* number of notes under a beam */

extern char tabstemlens[3];
extern float stemyoff[3];
extern unsigned char hasflag[10];
extern unsigned char numflags[10];
extern unsigned char hasstem[10];

struct beaminfo
{
  id a, b;			/* the current endpoints */
  short lev;			/* which level in a stack of beams */
  short code;			/* the drawing code */
};

struct beaminfo beam[NUMBEAMS];
static Beam *proto;
int nbeams;


+ (void) initialize
{
    if (self == [Beam class]) {
	[Beam setVersion: 8];		/* class version, see read: */
	proto = [[Beam alloc] init];
	proto->flags.broken = 0;
    }
    return;
}


+ myInspector
{
    return [BeamInspector class];
}


+ myPrototype
{
    return proto;
}


- init
{
    self = [super init];
    if (self != nil) {
	[self setTypeOfGraphic: BEAM];
	[self setClient: nil];
	flags.broken = 0;
	flags.taper = 0;
    }
    return self;
}


// should become copy.
- (Beam *) newFrom
{
  Beam *t = [[Beam alloc] init];
  t->bounds = bounds;
  t->gFlags = gFlags;
  [t setLevel: [self myLevel]]; // TODO this should be done by the superclass copy.
  t->flags = flags;
  return t;
}


- (int) myLevel
{
  return -1;
}


- (BOOL) canSplit
{
  return YES;
}


- (BOOL) needSplit: (float) s0 : (float) s1
{
  return [super needSplitList: s0 : s1];
}


- haveSplit: (Beam *) a : (Beam *) b : (float) x0 : (float) x1
{
  StaffObj *p = [[a clients] lastObject];
  StaffObj *q = [b firstClient];
  a->splitp = (q->staffPosition - p->staffPosition) / 2;
  b->splitp = (p->staffPosition - q->staffPosition) / 2;
  return self;
}


- haveSplit: (Beam *) a : (Beam *) b
{
  return [self haveSplit: a : b : 0.0 : 0.0];
}


- (void) dealloc
{
    [client release];
    client = nil;
    [super dealloc];
}


- sysInvalid
{
  return [super sysInvalidList];
}


/* links the beamable things from the selected list of things into the beam */

- linkbeam: (NSMutableArray *) l
{
  int bk = 0;
  TimedObj *q;
  int k, lk = [l count];
  k = lk;
  while (k--)
  {
    q = [l objectAtIndex:k];
    if (ISATIMEDOBJ(q) && [q isBeamable]) ++bk;
  }
  if (bk < 2) return nil;
  client = [[NSMutableArray alloc] init];
  k = lk;
  while (k--)
  {
    q = [l objectAtIndex:k];
    if (ISATIMEDOBJ(q) && [q isBeamable]) [(NSMutableArray *)client addObject: q];
  }
  q = [client objectAtIndex:0];
  gFlags.size = q->gFlags.size;
  k = bk;
  while (k--)
  {
    q = [client objectAtIndex:k];
    [q linkhanger: self];
    if ([q graphicType] == NOTE) [(GNote *) q resetChord];
    [q recalc];
  }
  return self;
}


- linktremolo: (NSMutableArray *) l
{
  TimedObj *p, *q;
  int k, bk, lk = [l count];
  bk = 0;
  k = lk;
  while (k--)
  {
    q = [l objectAtIndex:k];
    if (ISATIMEDOBJ(q)) ++bk;
  }
  if (bk != 2) return nil;
  p = [l objectAtIndex:0];
  q = [l objectAtIndex:1];
  if (!ISATIMEDOBJ(p) || !ISATIMEDOBJ(q) || p->time.body != q->time.body) return nil;
  client = [[NSMutableArray alloc] init];
  [(NSMutableArray *)client addObject: p];
  [(NSMutableArray *)client addObject: q];
  gFlags.size = p->gFlags.size;
  k = 2;
  while (k--)
  {
    q = [client objectAtIndex:k];
    [q linkhanger: self];
    if ([q graphicType] == NOTE) [(GNote *) q resetChord];
    [q recalc];
  }
  return self;
}


/* a tremolo halves the tick */

- (float) modifyTick: (float) t
{
  return gFlags.subtype ? 0.5 * t : t;
}


/* return lower bound of permitted stem length */


static float beamsThick(int sz, int nb)
{
  return (nb * beamthick[sz] + (nb - 1) * beamsep[sz]);
}


/* minimum stemlength accounts for beam segments and ledger lines */
/* for args (p,r), p is the first of the group (which controls beam
  direction etc), r is the one under consideration.
  Remember body codes are inverse to numbers of beams!
  Opposing stemups method not quite right.
*/

static float minStem(TimedObj *p, TimedObj *r)
{
  int ss = [r getSpacing];
  float ry = (MINSTEMLEN * ss);
  float ly, rb;
  rb = [r myStemBase];
  if ([r stemIsUp])
  {
    ly = [r yOfBottomLine];
    if (rb - ry > ly) ry = rb - ly;
  }
  else
  {
    ly = [r yOfTopLine];
    if (rb + ry < ly) ry = ly - rb;
  }
  if ([p stemIsUp] == [r stemIsUp]) ry += beamsThick(r->gFlags.size, CROTCHET - r->time.body);
  else if (r->time.body < p->time.body) ry += beamsThick(r->gFlags.size, p->time.body - r->time.body);
  return ry;
}


static float minStemLen(TimedObj *p, TimedObj *r)
{
  float ms = minStem(p, r);
  return [r stemIsUp] ? -ms : ms;
}



static float beamedStem(TimedObj *p, float min)
{
  float f = [p stemLength];
  return (f < 0) ? MIN(f, -min) : MAX(f, min);
}


static int signof(float f)
{
  return (f < 0) ? -1 : ( (f > 0 ) ? 1 : 0 );
}


/* return the number of inflexions in the curve connecting the noteheads */

- (int) inflexions
{
  StaffObj *r;
  int i, k, s, os, n;
  float y, oy=0.0;//sb: initted oy
  n = os = 0;
  k = [client count];
  for (i = 0; i < k; i++)
  {
    r = [client objectAtIndex:i];
    y = [r yMean];
    if (i > 0)
    {
      s = signof(y - oy);
      if (s != 0)
      {
        if (s != os)
	{
	  if (os != 0) n++;
	  os = s;
	}
      }
    }
    oy = y;
  }
  return n;
}


/* line parameter estimation (Numerical Recipes: Eqq 15.2.15ff) */

- (float) estimateSlope: (TimedObj *) p : (BOOL) socks
{
  TimedObj *r;
  int n, k;
  float x, y, sxx = 0.0, sx = 0.0, sxy = 0.0, sy = 0.0;
  n = [client count];
  k = n;
  while (k--)
  {
    r = [client objectAtIndex:k];
    x = r->x + [r stemXoff: 0];
    y = [r myStemBase];
    if (socks) y += minStemLen(p, r);  /* allow for stocking feet */
    sxx += x * x;
    sx += x;
    sy += y;
    sxy += x * y;
  }
  return (n * sxy - sx * sy) / (n * sxx - sx * sx);
}


/* find any offset needed and set the stems */
  
- setStems: (float) m : (float) xc : (float) yc : (TimedObj *) p : (int) n
{
  float uer, der, x, y, ry;
  int k, su, ab;
  TimedObj *r;
  uer = der = 0.0;
  k = n;
  while (k--)
  {
    r = [client objectAtIndex:k];
    su = [r stemIsUp];
    x = r->x + [r stemXoff: 0];
    y = m * (x - xc) + yc;
    ry = [r myStemBase] + minStemLen(p, r);
    if (su)
    {
      if (ry < y)
      {
        ry -= y;
	if (ry < uer) uer = ry;
      }
    }
    else
    {
      if (ry > y)
      {
        ry -= y;
        if (ry > der) der = ry;
      }
    }
  }
// NSLog(@"uperr = %f, dnerr = %f\n", uer, der);
  k = n;
  while (k--)
  {
    r = [client objectAtIndex:k];
    x = r->x + [r stemXoff: 0];
    y = m * (x - xc) + yc + uer + der;
//    [r setStemLengthTo: y - [r myStemBase]];
    ab = (y < [r yMean]);
    ry = [r wantsStemY: ab];
    [r setStemLengthTo: y - ry];

  }
  return self;
}


- setMixed: (TimedObj *) p : (TimedObj *) q
{
  int k, n;
  TimedObj *r, *a = nil, *b = nil;
  float m, x, y, x1, x2, y1, y2, xc, yc;
  y1 = MAXFLOAT;
  y2 = MINFLOAT;
  n = [client count];
  k = n;
  while (k--)
  {
    r = [client objectAtIndex:k];
    x = r->x + [r stemXoff: 0];
    y = [r myStemBase] + minStemLen(p, r);
// NSLog(@"note %d minstem %f\n", k, minStemLen(p, r));
    if ([r stemIsUp])
    {
      if (y < y1)
      {
        y1 = y;
	a = r;
      }
    }
    else
    {
      if (y > y2)
      {
        y2 = y;
	b = r;
      }
    }
  }
  if (a == nil || b == nil) return self;
  x1 = a->x + [a stemXoff: 0];
  x2 = b->x + [b stemXoff: 0];
  if (flags.horiz || [self inflexions] > 1) m = 0.0;
  else
  {
    m = 0.25 * [self estimateSlope: p : YES];
    if (m > MIXEDSLOPE) m = MIXEDSLOPE;
    else if (m < -MIXEDSLOPE) m = -MIXEDSLOPE;
  }
  xc = x1 + 0.5 * (x2 - x1);
  yc = y1 + 0.5 * (y2 - y1);
  [self setStems: m : xc : yc : p : n];
  return self;
}


/* special case: a split with one note in the beam */

- setSplit: (int) f
{
  TimedObj *p;
  p = [client objectAtIndex:0];
  [p setStemLengthTo: beamedStem(p, minStem(p, p))];
  return self;
}


/*
  Recalculate appearance of a beam and the notestems attached to it.
  Sets the beam offsets and the notes' stemlengths.
  Called when a beamed note is moved or an attribute changes.
  Must preserve the beam type (determined by the notes).
  f: beam type:  0=default, 1=fix down, 2=fix up, 3=mixed.
  sn: whether to sort (not needed for repositioning offsets, etc).
  Ideally, the wantsY ought to be p->y.  Should be true.
*/

- setbeam: (int) f : (int) sn
{
  TimedObj *p, *q;
  int j, k, kn, sz, pup;
  float dx, s1, s2, x1, y1, x2, y2, m;
  float by1, by2;
  kn = [client count];
  if (kn == 1) return [self setSplit: f];
  if (sn) [super sortNotes: client];
  p = [client objectAtIndex:0];
  if ([p graphicType] == TABLATURE) return self;
  q = [client lastObject];
  x1 = p->x + [p stemXoffLeft: 0];
  x2 = q->x + [q stemXoffRight: 0];
  dx = x2 - x1;
  if (dx <= 2.0) return self;
  sz = p->gFlags.size;
  pup = [p stemIsUp];
  if (f == 3) return [self setMixed: p : q];
  if (f == 0)
  {
    /* set stems to majority */
    j = 0;
    k = kn;
    while (k--) j += [[client objectAtIndex:k] midPosOff];
    j = (j > 0);
    f = j + 1;
  }
  else
  {
    /* set stems to agree with ones fixed */
    j = f - 1;
  }
  k = kn;
  while (k--) [[client objectAtIndex:k] defaultStem: j];
  s1 = beamedStem(p, minStem(p, p));
  by1 = [p myStemBase];
  y1 = by1 + s1;
  s2 = beamedStem(q, minStem(p, q));
  by2 = [q myStemBase];
  y2 = by2 + s2;
  if (flags.horiz || by1 == by2 || [self inflexions] > 1) m = 0.0;
  else
  {
    m = 0.5 * [self estimateSlope: p : NO];
    if (m > BEAMSLOPE) m = BEAMSLOPE;
    else if (m < -BEAMSLOPE) m = -BEAMSLOPE;
  }
  switch(f)
  {
    case 0:
      break;
    case 1:
      if (m > 0.0)
      {
        y2 = m * dx + y1;
	if (y2 < by2 + s2)
	{
	  y2 = by2 + s2;
	  y1 = m * -dx + y2;
	}
      }
      else
      {
        y1 = m * -dx + y2;
	if (y1 < by1 + s1)
	{
	  y1 = by1 + s1;
	  y2 = m * dx + y1;
	}
      }
      break;
    case 2:
      if (m < 0.0)
      {
        y2 = m * dx + y1;
	if (y2 > by2 + s2)
	{
	  y2 = by2 + s2;
	  y1 = m * -dx + y2;
	}
      }
      else
      {
        y1 = m * -dx + y2;
	if (y1 > by1 + s1)
	{
	  y1 = by1 + s1;
	  y2 = m * dx + y1;
	}
      }
      break;
  }
//  NSLog(@"Case %d: y1=%f, y2=%f, m=%f\n", f, y1, y2, m);
  [self setStems: m : x1 : y1 : p : kn];
  return self;
}

/* setting endpoints according to dragging the handle. y1 or y2 == 0.0 */

- setEnds: (float) y1 : (float) y2
{
  TimedObj *p, *q, *r;
  float m, x1, x2, dx, x, y, ry;
  int k, ab;
  p = [client objectAtIndex:0];
  if ([p graphicType] == TABLATURE) return self;
  q = [client lastObject];
  x1 = p->x + [p stemXoff: 0];
  x2 = q->x + [q stemXoff: 0];
  dx = x2 - x1;
  if (dx <= 2.0) return self;
  if (flags.horiz) y1 = y2 = y1 + y2;
  else
    {
      if (y1 == 0.0) y1 = [p myStemBase] + [p stemLength];
      if (y2 == 0.0) y2 = [q myStemBase] + [q stemLength];
    }
  m = (y2 - y1) / dx;
  k = [client count];
  while (k--)
  {
    r = [client objectAtIndex:k];
    x = r->x + [r stemXoff: 0];
    y = m * (x - x1) + y1;
    ab = (y < [r yMean]);
    ry = [r wantsStemY: ab];
    [r setStemLengthTo: y - ry];
  }
  return self;
}


/* for Beam only, the next two are the same */

- setHanger
{
  [self setbeam: [self beamType] : 1];
  [self recalc];
  return self;
}

- setHanger: (BOOL) f1 : (BOOL) f2
{
  [self setbeam: [self beamType] : 1];
  [self recalc];
  return self;
}


/*
  Find direction of stems under the beam.
  (b: 0=default, 1=fix down, 2=fix up, 3=mixed).
*/

- (int) beamType
{
  TimedObj *p;
  int nfix = 0, nup = 0, ndn = 0;
  int k = [client count];
    
  while (k--)
  {
    p = [client objectAtIndex: k];
    if ([p graphicType] == NOTE)
    {
      if ([p stemIsFixed])
      {
        ++nfix;
        if ([p stemIsUp]) ++nup; else ++ndn;
      }
    }
  }
  if (nfix == 0) return 0;  /* none fixed */
  if (nup == 0) return 1;   /* at least 1 fixed only down */
  if (ndn == 0) return 2;   /* at least 1 fixed only up */
  return 3;  /* mixed fixed */
}


- (BOOL) isCrossingBeam
{
  StaffObj *p;
  Staff *sp = nil;
  int i = [client count];
  while (i--)
  {
    p = [client objectAtIndex:i];
    if (sp == nil) sp = [p staff];
    else if (sp != [p staff]) return YES;
  }
  return NO;
}


- (BOOL) isGraced
{
  StaffObj *p;
  int k = [client count];
  int i = k;
  int g = 0;
  while (i--)
  {
    p = [client objectAtIndex:i];
    if ([p graphicType] == NOTE && p->isGraced == 1) ++g;
  }
  return (g == k);
}


/*
  Control direction of stems under the beam.  Called by inspector.
  (b: 0=default, 1=fix down, 2=fix up, 3=mixed).
*/

- setBeamDir: (int) b
{
  GNote *p;
  int k;
  k = [client count];
  while (k--)
  {
    p = [client objectAtIndex:k];
    if ([p graphicType] == NOTE)
    {
      if (b == 0)
      {
	[p setStemIsFixed: NO];
        [p defaultStem: ([p midPosOff] >= 0)];
      }
      else if (b < 3)
      {
	[p setStemIsFixed: YES];
        [p defaultStem: (b - 1)];
      }
      else if (b == 3) 
      {
	[p setStemIsFixed: YES];
        [p defaultStem: [p stemIsUp]];
      }
    }
  }
  [self setbeam: b : 0];
  [self recalc];
  return self;
}


- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
{
  gFlags.subtype = i;
  if (i == 0)
  {
    if ([self linkbeam: [v selectedGraphics]] == nil) return nil;
  }
  else
  {
    if ([self linktremolo: [v selectedGraphics]] == nil) return nil;
  }
  [self setbeam: [self beamType] : 1];
  return self;
}


- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
  if (gFlags.subtype == 0)
  {
    if ([self linkbeam: sl] == nil) return NO;
  }
  else
  {
    if ([self linktremolo: sl] == nil) return NO;
  }
  [self setbeam: [self beamType] : 1];
  [v selectObj: self];
  return YES;
}  

/* remove from client anything not on list l.  Return whether an OK beam. */

- (BOOL) isClosed: (NSMutableArray *) l
{
    int n;
    
    [super closeClients: l];
    n = [client count];
    return (n >= 2 || (([self splitToLeft] || [self splitToRight]) && n > 0));
}


- (void)removeObj
{
  int i, k = [client count];
  TimedObj *p;
  [self retain]; /* so the releasing by the notesdoes not free us too soon */
  [super removeGroup];
  for (i = 0; i < k; i++)
  {
    p = [client objectAtIndex:i];
    p->time.oppflag = 0;
    [p reDefault];
  }
  [self release];
}


- (BOOL) coordsForHandle: (int) h asX: (float *) x andY: (float *) y
{
  TimedObj *p;
  if (h == 0)
  {
    if ([self splitToLeft]) return NO;
    p = [client objectAtIndex:0];
  }
  else
  {
    if ([self splitToRight]) return NO;
    p = [client lastObject];
  }
  return ([p hitBeamAt: x : y]);
}


- (BOOL) getHandleBBox: (NSRect *) r
{
    int h;
    BOOL k = NO;
    float x, y;
    NSRect b;
    
    for (h = 0; h <= 1; h++) {
	if ([self coordsForHandle: h asX: &x andY: &y]) {
	    if (k == NO) 
		*r = NSMakeRect(x - HANDSIZE, y - HANDSIZE, 2 * HANDSIZE, 2 * HANDSIZE);
	    else {
		b = NSMakeRect(x - HANDSIZE, y - HANDSIZE, 2 * HANDSIZE, 2 * HANDSIZE);
		*r  = NSUnionRect(b , *r);
	    }
	}
	k = YES;
    }
    return k;
}


/* override hit */

- (BOOL) hit: (NSPoint) pt
{
    return [super hit: pt : 0 : 1];
}

- (float) hitDistance: (NSPoint) pt
{
    return [super hitDistance: pt : 0 : 1];
}

- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : sys : (int) alt
{
  int k;
  if (gFlags.selend) [self setEnds: 0.0 : pt.y]; else [self setEnds: pt.y : 0.0];
  [self recalc];
  k = [client count];
  while (k--) [[client objectAtIndex:k] markHangersExcept: self];
  return YES;
}


- moveFinished: (GraphicView *) v
{
  int k = [client count];
  while (k--) [[client objectAtIndex:k] setHangersExcept: BEAM];
  return self;
}


/* new method for finding and printing beams */

#define NUMUNDER 128

static TimedObj *toj[NUMUNDER];
static char sup[NUMUNDER];
static char beamBreak[NUMUNDER];
static char flg[NUMUNDER];
static char acc[NUMUNDER];
static float stemy[NUMUNDER];
static char nflg[NUMUNDER];

/* does all work.  Returns ymax in case tremolos follow */

/* special case: a split with one note */

- (float) drawSplit: (int) df : (TimedObj *) p : (int) sz : (int) dflag
{
  int i, n, su;
    float xa=0.0, ya=0.0, xb=0.0, yb=0.0, y1, y2, ymax=0.0, th, bsep, bth, ys=0.0;//sb: innited values
    
  su = [p stemIsUp];
  if ([self splitToLeft] && ![self splitToRight]) {
    xa = [p xOfStaffEnd: 0];
    ya = [p yOfStaffPosition: p->staffPosition + splitp] + [p stemYoff: 0] + [p stemLength];
    xb = p->x + [p stemXoffRight: 0];
    yb = [p myStemBase] + [p stemYoff: 0] + [p stemLength];
    ys = yb;
  }
  else if ([self splitToRight] && ![self splitToLeft]) {
    xa = p->x + [p stemXoffLeft: 0];
    ya = [p myStemBase] + [p stemYoff: 0] + [p stemLength];
    ys = ya;
    xb = [p xOfStaffEnd: 1];
    yb = [p yOfStaffPosition: p->staffPosition + splitp] + [p stemYoff: 0] + [p stemLength];
  }
  th = beamthick[sz];
  bsep = th + beamsep[sz];
  if (su)
  {
    bth = th;
  }
  else
  {
    bsep = -bsep;
    bth = -th;
  }
  n = df - p->time.body;
  for (i = 0; i < n; i++)
  {
    y1 = ya + i * bsep;
    y2 = yb + i * bsep;
    cslant(xa, y1, xb, y2, bth, dflag);
    ymax = y1 + bsep;
  }
  if ([p graphicType] == NOTE)
  {
    xa = p->x + [p stemXoff: 0];
    cline(xa, [p myStemBase], xa, ys, stemthicks[sz], dflag);
  }
  return ymax;
}


/*
  implement the rules for which side the half-beam lies.
  k is passed as k - 1.
  Note oppCode is used for two different reasons.
*/

int oppCode[3] = {1, 2, 1};

int getHalfCode(TimedObj *r, int a, int k)
{
  TimedObj *s;
  int code, d;
  if (a == 0) code = 1;			/* left end */
  else if (a == k) code = 2;		/* right end */
  else if (beamBreak[a]) code = 1;	/* end after break */
  else if (beamBreak[a + 1]) code = 2;	/* end before break */
  else if ([r tupleStarts]) code = 1;	/* end starts tuple */
  else if ([r tupleEnds]) code = 2;	/* end ends tuple */
  else					/* single in middle */
  {
    d = nflg[a + 1] - nflg[a - 1];
    if (d < 0) code = 2;		/* more flags on left */
    else if (d > 0) code = 1;		/* more flags on right */
    else				/* ambiguous: resolve towards dots */
    {
      s = toj[a - 1];
      code = oppCode[([s dottingCode] > 0)];  	/* else flag to right */
    }
  }
  if (r->time.oppflag) code = oppCode[code];	/* in case reverse it */
  return code;
}


- (float) drawBeams: (int) df 
    : (TimedObj *) p 
    : (TimedObj *) q 
    : (int) sz 
    : (int) dflag
{
  int i, k, a, b, lev, bl, w, code;
  float ticks = 0.0, broke;
  float x1, y1, x2, y2, m, dx, bsep, bth, th, xa, ya, xb, yb, x, y, ymax;
  TimedObj *r, *s;
  k = [client count];
  for (i = 0; i < k; i++)
  {
    beamBreak[i] = 0; /* init here because set i+1 below */
    acc[i] = 0;
  }
  broke = (flags.broken) ? tickval(flags.body, flags.dot) : 0.0;
  for (i = 0; i < k; i++)
  {
    toj[i] = r = [client objectAtIndex:i];
    flg[i] = nflg[i] = df - r->time.body;
    sup[i] = [r stemIsUp];
    ticks += [r noteEval: NO];
    if (flags.broken && TOLFLOATEQ(ticks, broke, 0.1))
    {
      if (i < k) beamBreak[i + 1] = 1;
      ticks = 0.0;
    }
  }
  dx = DrawWidthOfCharacter(musicFont[1][sz], SF_stemsp);
  th = beamthick[sz];
  bsep = th + beamsep[sz];
  x1 = p->x + [p stemXoffLeft: 0];
  y1 = [p myStemBase] + [p stemLength];
  x2 = q->x + [q stemXoffRight: 0];
  y2 = [q myStemBase] + [q stemLength];
  m = (y2 - y1) / (x2 - x1);
  a = 0;
  lev = 0;
  /* first do primary and init stem lengths */
  for (i = 0; i < k; i++)
  {
    --flg[i];
    r = toj[i];
    x = r->x + [r stemXoff: 0];
    stemy[i] = m * (x - x1) + y1;
  }
  r = toj[0];
  s = toj[k - 1];
  xa = r->x + [r stemXoffLeft: 0];
  xb = s->x + [s stemXoffRight: 0];
  if ([self splitToLeft])	/* split to the left */
  {
    xa -= nature[sz] * 4;
  }
  if ([self splitToRight])	/* split to the right */
  {
    xb += nature[sz] * 4;
  }
  ya = m * (xa - x1) + y1;
  yb = m * (xb - x1) + y1;
  if (sup[a]) 
    bth = th;
  else  
    bth = -th;
  cslant(xa, ya, xb, yb, bth, dflag);
  ymax = ya + (sup[0] ? bsep : -bsep);
  /* do in case of any secondaries */
  lev = 1;
  while (1)
  {
    while (a < k && !flg[a]) ++a;
    if (a == k) break;
    b = a + 1;
    while (b < k && flg[b] && !beamBreak[b]) ++b;
    --b;
    if (a == b)				/* boundary condition: half beam */
    {
      r = toj[a];
      code = getHalfCode(r, a, k - 1);
      if (code == 1)
      {
        xa = r->x + [r stemXoffLeft: 0];
        xb = xa + dx;
      }
      else if (code == 2)
      {
        xb = r->x + [r stemXoffLeft: 0];
        xa = xb - dx;
      }
      if (([self splitToLeft]) && r == p)	/* split to the left */
      {
        xa -= nature[sz] * 4;
      }
      if (([self splitToRight]) && r == q)	/* split to the right */
      {
        xb += nature[sz] * 4;
      }
    }
    else				/* normal case (code 0) */
    {
      r = toj[a];
      s = toj[b];
      xa = r->x + [r stemXoffLeft: 0];
      xb = s->x + [s stemXoffRight: 0];
      if (([self splitToLeft]) && r == p)	/* split to the left */
      {
        xa -= nature[sz] * 4;
      }
      if (([self splitToRight]) && s == q)	/* split to the right */
      {
        xb += nature[sz] * 4;
      }
    }
    if (sup[a] != sup[0])		/* stem of opposite sense */
    {
      if (sup[a])
      {
        bl = lev - acc[a];
        bth = -th;
      }
      else
      {
        bl = acc[a] - lev;
        bth = th;
      }
      w = 0;
    }
    else
    {
      if (sup[a])
      {
        bl = lev;
        bth = th;
      }
      else
      {
        bl = -lev;
        bth = -th;
      }
      w = 1;
    }
    ya = yb = bl * bsep;
    switch(flags.taper)
    {
      case 0:
      case 3:
        ya += m * (xa - x1) + y1;
        yb += m * (xb - x1) + y1;
        break;
      case 1:
        m = (y2 - y1) / (x2 - x1);
        yb += m * (xb - x1) + y1;
	m = (yb - y1) / (xb - x1);
        ya = m * (xa - x1) + y1; 
        break;
      case 2:
        m = (y2 - y1) / (x2 - x1);
        ya += m * (xa - x1) + y1; 
	m = (y2 - ya) / (x2 - xa);
        yb = m * (xb - xa) + ya;
        break;
    }
    cslant(xa, ya, xb, yb, bth, dflag);
    ymax = ya + (sup[0] ? bsep : -bsep);
    for (i = a; i <= b; i++)
    {
      --flg[i];
      if (w) ++acc[i];
      r = toj[i];
      x = r->x + [r stemXoff: 0];	/* update length in case of */
      y = m * (x - xa) + ya;		/*   opposite sense stems */
      if (sup[i])
      {
        if (y < stemy[i]) stemy[i] = y;
      }
      else
      {
        if (y > stemy[i]) stemy[i] = y;
      }
    }
    a = b + 1;
    while (a < k && !flg[a]) ++a;
    if (a == k)
    {
      ++lev;
      a = 0;
    }
  }
  for (i = 0; i < k; i++)
  {
    r = toj[i];
    if ([r graphicType] == NOTE)
    {
      x = r->x + [r stemXoff: 0];
      cline(x, [r myStemBase] + [r stemYoff: 0], x, stemy[i], stemthicks[sz], dflag);
    }
  }
  return ymax;
}


/* tab is a simplified case because stems are always up */

- drawTabBeams: (int) df : (TimedObj *) p : (TimedObj *) q : (int) sz : (int) dflag
{
  int i, k, a, b, lev, code;
  float ticks = 0.0, broke;
  float dx, bsep, th, xa=0.0, ya=0.0, xb=0.0, x, y; //sb: initted values
  TimedObj *r, *s;
  broke = (flags.broken) ? tickval(flags.body, flags.dot) : 0.0;
  k = [client count];
  for (i = 0; i < k; i++)
  {
    beamBreak[i] = 0; /* init here because set i+1 below */
    acc[i] = 0;
  }
  for (i = 0; i < k; i++)
  {
    toj[i] = r = [client objectAtIndex:i];
    flg[i] = df - r->time.body;
    ticks += [r noteEval: NO];
    if (flags.broken && TOLFLOATEQ(ticks, broke, 0.1))
    {
      if (i < k) beamBreak[i + 1] = 1;
      ticks = 0.0;
    }
  }
  dx = DrawWidthOfCharacter(musicFont[1][sz], SF_stemsp);
  th = 0.5 * beamthick[sz];
  bsep = 1.2 * beamthick[sz];
  a = 0;
  /* need not distinguish primary and secondaries */
  lev = 0;
  while (1)
  {
    while (a < k && !flg[a]) ++a;
    if (a == k) break;
    b = a + 1;
    while (b < k && flg[b] && !beamBreak[b]) ++b;
    --b;
    if (a == b)				/* boundary condition: half beam */
    {
      r = toj[a];
      code = getHalfCode(r, a, k - 1);
      if (code == 1)
      {
        xa = r->x;
        xb = xa + dx;
      }
      else if (code == 2)
      {
        xb = r->x;
        xa = xb - dx;
      }
    }
    else				/* normal case */
    {
      r = toj[a];
      s = toj[b];
      xa = r->x;
      xb = s->x;
    }
    ya = [r myStemBase] - [r stemLength] - tabstemlens[sz] + lev * bsep;
    crect(xa, ya, xb - xa, th, dflag);
    for (i = a; i <= b; i++) --flg[i];
    a = b + 1;
    while (a < k && !flg[a]) ++a;
    if (a == k)
    {
      ++lev;
      a = 0;
    }
  }
  for (i = 0; i < k; i++)
  {
    r = toj[i];
    x = r->x;
    y = [r myStemBase] - [r stemLength];
    cline(x, y, x, y - tabstemlens[sz], stemthicks[sz], dflag);
    if ([r dottingCode]) restdot(smallersz[sz], 0.0, x, y, 0, [r dottingCode], 0, dflag);
  }
  return self;
}


float tremoffa[2][2] = { { 1.0,  2.5}, { 1.0,  1.5} };
float tremoffb[2][2] = { {-1.0, -1.5}, {-1.0, -2.5} };

static void drawTremolo(int n, TimedObj *a, TimedObj *b, float ytrem, int sz, int dflag)
{
  int i, at, pup;
  float bsep, th, bskip, dx, xa, xb, ya, yb, t;
  float x1, y1, x2, y2, m;
  bsep = beamsep[sz];
  th = beamthick[sz];
  bskip = bsep + th;
  at = a->time.body;
  dx = halfwidth[sz][0][at];
  xa = a->x;
  xb = b->x;
  x1 = a->x + [a stemXoffLeft: 0];
  x2 = b->x + [b stemXoffRight: 0];
  if (hasstem[at])
  {
    y1 = [a myStemBase] + [a stemLength];
    y2 = [b myStemBase] + [b stemLength];
    if (ytrem < 0)
    {
      cline(x1, [a myStemBase] + [a stemYoff: 0], x1, y1, stemthicks[sz], dflag);
      cline(x2, [b myStemBase] + [b stemYoff: 0], x2, y2, stemthicks[sz], dflag);
    }
    pup = [a stemIsUp];
  }
  else
  {
    y1 = [a myStemBase];
    y2 = [b myStemBase];
    pup = 0;
  }
  if (ytrem < 0) ytrem = y1;
  m = (y2 - y1) / (x2 - x1);
  if (!pup)
  {
    th = -th;
    bsep = -bsep;
    bskip = - bskip;
  }
  if (!hasstem[at])
  {
    xa += dx * 1.5;
    xb -= dx * 1.5;
    if (xb - xa > 6 * nature[sz])
    {
      t = xa + 0.5 * (xb - xa);
      xa = t - 3 * nature[sz];
      xb = t + 3 * nature[sz];
    }
  }
  else
  {
    xa += [a stemXoffLeft: 0];
    xb += [b stemXoffRight: 0];
    if (at <= CROTCHET)
    {
      i = numflags[at] + n > 3;
      xa += dx * tremoffa[pup][i];
      xb += dx * tremoffb[pup][i];
    }
  }
  ya = m * (xa - x1) + ytrem;
  yb = m * (xb - x1) + ytrem;
  while (n--)
  {
    cslant(xa, ya, xb, yb, th, dflag);
    ya += bskip;
    yb += bskip;
  }
}


/* code in case the beam slash is needed */

- drawBeamGrace: (TimedObj *) p : (TimedObj *) q : (int) sz : (int) dflag
{
  float bsep = beamthick[sz] + beamsep[sz];
  int pup = [p stemIsUp];
  float x1 = p->x + [p stemXoffLeft: 0];
  float x2 = q->x + [q stemXoffRight: 0];
  float y1 = [p myStemBase] + [p stemLength];
  float y2 = [q myStemBase] + [q stemLength];
  float m = (y2 - y1) / (x2 - x1);
  float x = p->x - (pup ? 1.0 : 1.5) * bsep;
  float y =  y1 - 0.5 * [p stemLength];
  float x3 = x1 + 0.5 * (x2 - x1);
  float y3 = (m * (x3 - x1) + y1) + (pup ? -bsep : bsep);
  cline(x, y, x3 , y3, stemthicks[sz], dflag);
  return self;
}


/*
  assumes notes are sorted.
  stem must not go to top of beam (hence -dy) so that bits don't show.
*/


- drawMode: (int) m
{
    TimedObj *p, *q;
    float ytrem, x, y;
    int sz = gFlags.size;
    
    if (gFlags.selected && !gFlags.seldrag) {
	if ([self coordsForHandle: 0 asX: &x andY: &y]) 
	    chandle(x, y, m);
	if ([self coordsForHandle: 1 asX: &x andY: &y]) 
	    chandle(x, y, m);
    }
    if (!client) 
	NSLog(@"will die: client nil (in Beam.m)\n");
    p = [client objectAtIndex: 0];
    if ([client count] == 1) {
	if (p->time.body < CROTCHET) 
	    ytrem = [self drawSplit: CROTCHET : p : sz : m];
	//    if (flags.dir && [self isGraced]) [self drawBeamGrace: p : q : sz : m];
	//    if (gFlags.subtype) drawTremolo(gFlags.subtype, p, q, -1, sz, m);
	return self;
    }
    q = [client lastObject];
    if (TOLFLOATEQ(p->x, q->x, 2.0))
	return self;
    if ([p graphicType] == TABLATURE) {
	return [self drawTabBeams: CROTCHET + 1 + [[CalliopeAppController currentDocument] getPreferenceAsInt: TABCROTCHET] : p : q : sz : m];
    }
    else if (p->time.body < CROTCHET) {
	ytrem = [self drawBeams: CROTCHET : p : q : sz : m];
	if (gFlags.subtype) 
	    drawTremolo(gFlags.subtype, p, q, ytrem, sz, m);
	/* the following can be used for slashed groups, but is not standard */
	if (flags.dir && [self isGraced]) 
	    [self drawBeamGrace: p : q : sz : m];
    }
    if (gFlags.subtype) 
	drawTremolo(gFlags.subtype, p, q, -1, sz, m);
    return self;
}


struct oldflags
{
  unsigned int count : 6;	/* hence limit of 64 notes */
  unsigned int body : 4;	/* duration of */
  unsigned int dot : 2;		/*   broken beam segment */
  unsigned int broken : 1;	/* whether broken */
  unsigned int fixed : 1;	/* whether direction is fixed */
  unsigned int dir : 1;		/* whether direction is up (0) or down (1) */
  unsigned int anon : 1;
};


- (id)initWithCoder:(NSCoder *)aDecoder
{
  char tup1, tup2;
  char i, j, k, m, n, o, p, t;
  struct oldflags f;
  int v = [aDecoder versionForClassName:@"Beam"];
  [super initWithCoder:aDecoder];
  flags.horiz = 0;
  flags.taper = 0;
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"@scc", &client, &flags, &tup1, &tup2];
    flags.fixed = 0;
    flags.dir = 1;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"@s", &client, &f];
    flags.body = f.body;
    flags.dot = f.dot;
    flags.broken = f.broken;
    flags.fixed = f.fixed;
    flags.dir = f.dir;
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"@cccccc", &client, &i, &j, &k, &m, &n, &o];
    flags.body = j;
    flags.dot = k;
    flags.broken = m;
    flags.fixed = n;
    flags.dir = o;
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"@cccccc", &client, &i, &j, &k, &m, &n, &o];
    flags.horiz = i;
    flags.body = j;
    flags.dot = k;
    flags.broken = m;
    flags.fixed = n;
    flags.dir = o;
  }
  else if (v == 4)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccccc", &i, &j, &k, &m, &n, &o, &p];
    flags.horiz = i;
    flags.body = j;
    flags.dot = k;
    flags.broken = m;
    flags.fixed = n;
    flags.dir = o;
      [self setSplitToLeft: (p & 2) == 2];
      [self setSplitToRight: (p & 1) == 1];
  }
  else if (v == 5)
  {
    [aDecoder decodeValuesOfObjCTypes:"iccccccc", &UID, &i, &j, &k, &m, &n, &o, &p];
    flags.horiz = i;
    flags.body = j;
    flags.dot = k;
    flags.broken = m;
    flags.fixed = n;
    flags.dir = o;
      [self setSplitToLeft: (p & 2) == 2];
      [self setSplitToRight: (p & 1) == 1];
  }
  else if (v == 6)
  {
    [aDecoder decodeValuesOfObjCTypes:"icccccccc", &UID, &i, &j, &k, &m, &n, &o, &p, &splitp];
    flags.horiz = i;
    flags.body = j;
    flags.dot = k;
    flags.broken = m;
    flags.fixed = n;
    flags.dir = o;
      [self setSplitToLeft: (p & 2) == 2];
      [self setSplitToRight: (p & 1) == 1];
  }
  else if (v == 7)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccccc", &i, &j, &k, &m, &n, &o, &splitp];
    flags.horiz = i;
    flags.body = j;
    flags.dot = k;
    flags.broken = m;
    flags.fixed = n;
    flags.dir = o;
  }
  else if (v == 8)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccccc", &i, &j, &k, &m, &n, &o, &splitp, &t];
    flags.horiz = i;
    flags.body = j;
    flags.dot = k;
    flags.broken = m;
    flags.fixed = n;
    flags.dir = o;
    flags.taper = t;
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b1, b2, b3, b4, b5, b6, b7;
  [super encodeWithCoder:aCoder];
  b1 = flags.horiz;
  b2 = flags.body;
  b3 = flags.dot;
  b4 = flags.broken;
  b5 = flags.fixed;
  b6 = flags.dir;
  b7 = flags.taper;
  [aCoder encodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &splitp, &b7];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];

    [aCoder setInteger:flags.horiz forKey:@"horiz"];
    [aCoder setInteger:flags.body forKey:@"body"];
    [aCoder setInteger:flags.dot forKey:@"dot"];
    [aCoder setInteger:flags.broken forKey:@"broken"];
    [aCoder setInteger:flags.fixed forKey:@"fixed"];
    [aCoder setInteger:flags.dir forKey:@"dir"];
    [aCoder setInteger:splitp forKey:@"splitp"];
    [aCoder setInteger:flags.taper forKey:@"taper"];
}

@end
