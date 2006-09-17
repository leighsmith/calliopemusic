/* $Id:$ */
#import <Foundation/Foundation.h>
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "SquareNote.h"
#import "SquareNoteInspector.h"
#import "Staff.h"
#import "System.h"

@implementation SquareNote

static SquareNote *proto;

+ (void)initialize
{
  if (self == [SquareNote class])
  {
    proto = [[SquareNote alloc] init];
      [SquareNote setVersion: 0];		/* class version, see read: */
  }
  return;
}


+ myInspector
{
  return [SquareNoteInspector class];
}


+ myPrototype
{
  return proto;
}


- init
{
  [super init];
  gFlags.type = SQUARENOTE;
  gFlags.subtype = 0;
  time.body = 4;
  time.dot = 0;
  shape = 0;
  colour = 0;
  stemside = 0;
  p1 = 2;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


/* initialise the prototype squarenote */

static char timecodes[3] = {4, 4, 5};

- proto: v : (NSPoint) pt : (Staff *) sp : sys : (Graphic *) g : (int) i
{
  [super proto: v : pt : sp : sys : g : i];
  if (TYPEOF(sp) == STAFF)
  {
    p = [sp findPos: pt.y];
    y = [sp yOfPos: p];
  }
  gFlags.size = sp->gFlags.size;
  gFlags.subtype = proto->gFlags.subtype;
  shape = i;
  colour = proto->colour;
  stemside = proto->stemside;
  time.body = timecodes[i];
  time.dot = proto->time.dot;
  time.stemlen = 20;
  p1 = proto->p1;
  return self;
}


- (BOOL) reCache: (float) sy : (int) ss
{
  float t;
  t = sy + ss * p;
  if (t == y) return NO;
  y = t;
  return YES;
}


/* 
  pass back the pos and dot and whether molle'd of ith component
  of neume (origin 0).  Return whether exists.
*/

static char squarenum[3] = {1, 1, 2};
static float squaretick[3] = {1.0, 1.0, 0.5};

- (BOOL) getPos: (int) i : (int *) pos : (int *) d : (int *) m : (float *) t
{
    if (i >= squarenum[(int)shape]) return NO;
  if (i == 0) *pos = p;
  else if (i == 1) *pos = p + p1;
  *d = 0;
  *m = 0;
  *t = squaretick[(int)shape] * tickval(time.body, 0);
  return YES;
}


/* Caller does the setHangers that matches the markHangers here */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : (System *) sys : (int) alt
{
  int mp;
  float nx = dx + pt.x;
  float ny = dy + pt.y;
  BOOL m = NO, inv;
  if (alt == 1)  /* ALT-move */
  {
    if (stemside)
    {
      m = YES;
      [self setStemTo: ny - y];
    }
  }
  else if (alt == 2)  /* CONTROL-move */
  {
    if (TYPEOF(mystaff) == STAFF)
    {
      mp = [mystaff findPos: ny];
      if (mp - p != p1)
      {
        p1 = mp - p;
	m = YES;
      }
    }
  }
  else if (ABS(ny - y) > 1 || ABS(nx - x) > 1)
  {
    m = YES;
    x = nx;
    y = ny;
    inv = [sys relinknote: self];
    if (TYPEOF(mystaff) == STAFF)
    {
      p = [mystaff findPos: y];
      y = [mystaff yOfPos: p];
    }
  }
  if (m)
  {
    [self recalc];
    [self markHangers];
    [self setVerses];
  }
  return m;
}


/* */

- (BOOL) performKey: (int) c
{
  BOOL r = NO;
  if (r)
  {
    [self reShape];
    return YES;
  }
  else return [super performKey: c];
}


static float squarelinewidth[3] = {1.6, 1.2, 0.8};

static short mywidth[2] = {2, 4};


- drawMode: (int) m
{
  int sz, ss, dp, sl;
  float x1, y1=0.0, x2, y2=0.0, s1, s2, w=0.0, h, dy, lw, ser;
  Staff *sp;
  sz = gFlags.size;
  sp = mystaff;
  ss = getSpacing(sp);
  sl = getLines(sp);
  lw = squarelinewidth[sz];
  ser = 1.5 * ss;
  switch(shape)
  {
    case 0:  /* square */
    case 1:  /* maxima */
      x1 = x;
      y1 = y2 = y - ss;
        w = mywidth[(int)shape] * ss;
      h = 2 * ss;
      if (gFlags.subtype)
      {
        s1 = y - ser;
	s2 = y + ser;
	x2 = x1 + w;
        cline(x1, s1, x1, s2, lw, m);
        cline(x2, s1, x2, s2, lw, m);
        if (colour) cfillrect(x1, y1, w, h, lw, m);
	else
	{
	  cline(x1, y1, x2, y1, 2 * lw, m);
	  cline(x1, y1 + h, x2, y1 + h, 2 * lw, m);
	}
      }
      else
      {
        if (colour) cfillrect(x1, y1, w, h, lw, m); else coutrect(x1, y1, w, h, lw, m);
      }
      break;
    case 2:  /* oblique */
      x1 = x;
      y1 = y - ss;
      y2 = [self yOfPos: p + p1] - ss;
      dy = 2 * ss;
      w = ABS(y1 - y2) + 2 * ss;
      x2 = x1 + w;
      if (colour) cslant(x1, y1, x2, y2, dy, m); else coutslant(x1, y1, x2, y2, dy, lw, m);
      if (gFlags.subtype)
      {
        s1 = y - ser;
	s2 = y + ser;
        cline(x1, s1, x1, s2, lw, m);
	s1 = [self yOfPos: p + p1] - ser;
	s2 = [self yOfPos: p + p1] + ser;
        cline(x2, s1, x2, s2, lw, m);
      }
      break;
  }
  if (stemside) /* uses w, y2 from above */
  {
    x1 = x;
    if (stemside == 2)
    {
      x1 += w;
      y1 = y2;
    }
    cline(x1, y1, x1, y1 + time.stemlen, lw, m);
  }
  if (time.dot)
  {
    dp = p;
    if (shape == 2) dp += p1;
    if (!(dp & 1)) dp -= 1;
    x1 = x + w + nature[sz];
    y1 = [self yOfPos: dp];
    drawnotedot(sz, x1, y1, 0, 0, 1, time.dot, 0, m);
  }
  if (TYPEOF(sp) == STAFF)
  {
    h = 0.5 * w;
    drawledge(x + h, [sp yOfTop], h, sz, p, sl, ss, m);
  }
  return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  /*int v = */[aDecoder versionForClassName:@"SquareNote"];
  [super initWithCoder:aDecoder];
  [aDecoder decodeValuesOfObjCTypes:"cccc", &shape, &colour, &stemside, &p1];
  gFlags.type = SQUARENOTE;   /* stupid error in old version */
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeValuesOfObjCTypes:"cccc", &shape, &colour, &stemside, &p1];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:shape forKey:@"shape"];
    [aCoder setInteger:colour forKey:@"colour"];
    [aCoder setInteger:stemside forKey:@"stemside"];
    [aCoder setInteger:p1 forKey:@"p1"];
}

@end

