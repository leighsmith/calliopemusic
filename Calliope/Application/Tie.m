/* $Id$ */
#import <Foundation/Foundation.h>
#import "Tie.h"
#import "TieInspector.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "TimedObj.h"
#import "GNote.h"
#import "NoteHead.h"
#import "GraphicView.h"
#import "Ligature.h"
#import "NoteGroup.h"
#import "TieNew.h"
#import "System.h"
#import "DrawApp.h"
#import "Staff.h"

@implementation Tie

char mapTieSubtype[NUMTIES] = {TIEBOWNEW, LIGLINE, 0, LIGBRACK, LIGCORN, GROUPCRES, GROUPDECRES, TIESLURNEW};
/* whether the placement and constraint matrices are enabled for each subtype */

char enablePlace[NUMTIES] = {1, 0, 0, 1, 1, 1, 1, 1};

char enableConst[NUMTIES] = {0, 1, 1, 1, 1, 1, 1, 1};

/* whether subtype needs dx, dy, d, sin, cos */

static char needtheta[NUMTIES] = { 1, 0, 0, 0, 1, 1, 1, 1};

static char candash[NUMTIES] = { 1, 1, 0, 1, 1, 1, 1, 1};

static Tie *proto;


+ (void)initialize
{
  if (self == [Tie class])
  {
      (void)[Tie setVersion: 6];		/* class version, see read: */
    proto = [[Tie alloc] init];
  }
  return;
}


+ myInspector
{
  return nil;
}


+ myPrototype
{
  return proto;
}


/* default depth of curve as a function of chordlength */

static float getdepth(float d)
{
  d *= 0.25;
  if (d > 12.0) d = 12.0;
  if (d < 4.0) d = 4.0;
  return(d);
}


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


- init
{
  [super init];
  gFlags.type = TIE;
  gFlags.subtype = TIEBOW;
  headnum = 0;
  flatness = 0.0;
  flags.fixed = 0;
  flags.place = 0;
  flags.ed = 0;
  flags.usedepth = 0;
  flags.horvert = 0;
  flags.dashed = 0;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


/* override so that interlinked partners reset the other's bounds */

- recalc
{
  Tie *t = partner;
  flags.same = ([client sysNum] == [t->client sysNum]);
  t->flags.same = flags.same;
  bbinit();
  [self drawMode: 0];
  bounds = getbb();
  if (flags.same) t->bounds = bounds;
  else
  {
    bbinit();
    [t drawMode: 0];
    t->bounds = getbb();
  }
  [client sysInvalid];
  return self;
}


/* update except for master, headnum, offset */

- updatePartner
{
  return self;
}


- coordsForHandle: (int) h  asX: (float *) x  andY: (float *) y
{
  Tie *t;
  StaffObj *p = client;
  if (h == 0)
  {
    *x = p->x + offset.x;
    *y = [p headY: headnum] + offset.y;
  }
  else if (h == 1)
  {
    t = partner;
    if (flags.same)
    {
      p = (StaffObj *)(t->client);
      *x = p->x + t->offset.x;
      *y = [p headY: t->headnum] + t->offset.y;
    }
    else
    {
      *x = [p xOfStaffEnd: ([p sysNum] < [t->client sysNum])];
      *y = [p headY: headnum] + offset.y;
    } 
  }
  return self;
}


- (BOOL) getHandleBBox: (NSRect *) r
{
  float x, y;
  NSRect b;
  [self coordsForHandle: 0  asX: &x  andY: &y];
  *r = NSMakeRect(x - HANDSIZE, y - HANDSIZE, 2 * HANDSIZE, 2 * HANDSIZE);
  if (partner == nil) return YES;
  [self coordsForHandle: 1  asX: &x  andY: &y];
  b = NSMakeRect(x - HANDSIZE, y - HANDSIZE, 2 * HANDSIZE, 2 * HANDSIZE);
  *r  = NSUnionRect(b , *r);
  return YES;
}


- (BOOL) clientOrder: (TimedObj *) p : (TimedObj *) q
{
  if (flags.same) return (p->x < q->x);
  return ([p sysNum] < [q sysNum]);
}



- setHanger
{
  [self recalc];
  [partner recalc];
  return self;
}


/* self is a pair of interlinked partners */
/* note clients passed using sp and sys parameters */

- proto: (GraphicView *) v : (NSPoint) pt : (StaffObj *) n0 : (StaffObj *) n1 : (Graphic *) g : (int) i
{
  return self;
}


/* set the default options for style t */

static char defPlace[NUMTIES] = {0, 0, 0, 0, 0, 1, 1, 1};
static char defConst[NUMTIES] = {0, 0, 1, 0, 0, 1, 1, 0};


- setDefault: (int) t
{
  flags.place = defPlace[t];
  flags.horvert = defConst[t];
  flags.fixed = 0;
  flags.usedepth = 0;
  flags.dashed = 0;
  return self;
}


- (BOOL) isClosed: (NSMutableArray *) l
{
  if ([l indexOfObject:client] == NSNotFound) return NO;
  if (partner == nil) return NO;
  if ([l indexOfObject:((Tie *) partner)->client] == NSNotFound) return NO;
  return YES;
}


- (void)removeObj
/* sb: FIXME need to think about releasing the client. Do it here or not? */
{
    Tie *t = partner;
    [self retain];
    [client unlinkhanger: self];
    if (t != nil)
      {
        [t->client unlinkhanger: t];
        /* I think ok to release here, since we are the only object to have retained it (see archiving code) */
        [t release]; 
      }
    [self release];
}


- (BOOL) hit: (NSPoint) p
{
  StaffObj *q;
  float x, y;
  q = client;
  x = q->x + offset.x;
  y = [q headY: headnum] + offset.y;
  return (TOLFLOATEQ(p.x, x, 4.0) && TOLFLOATEQ(p.y, y, 4.0));
}


- (BOOL)selectMe: (NSMutableArray *) sl : (int) d :(int)active
{
    if (((Graphic *)partner)->gFlags.selected == active) return NO;
    return [super selectMe: sl : d :active];
}


- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  return NO;
}


- (void)setSize:(int)ds
{
  Tie *t = partner;
  int sz = gFlags.size + ds;
  if (sz < 0) sz = 0; else if (sz > 2) sz = 2;
  gFlags.size = sz;
  gFlags.morphed = 0;
  t->gFlags.size = sz;
  t->gFlags.morphed = 0;
}

- drawMode: (int) m
{
    float x[2], y[2], dx=0.0, dy=0.0, cx, cy, d=0.0, h, v, a, th, cth=0.0, sth=0.0;
    int e, b = 0;
    int sz = gFlags.size;
    int style = gFlags.subtype;
    StaffObj *p = client;
    Tie *t = partner;
    x[0] = p->x + offset.x;
    y[0] = [p headY: headnum] + offset.y;
    if (t == nil)
    {
	NSLog(@"Unpartnered connector of type %d at %f, %f\n", style, x[0], y[0]);
	cline(x[0] - 32, y[0] - 32, x[0] + 32, y[0] + 32, 0, m);
	cline(x[0] - 32, y[0] + 32, x[0] + 32, y[0] - 32, 0, m);
	return self;
    }
    e = 3;
    if (flags.same)
    {
	p = (StaffObj *)(t->client);
	x[1] = p->x + t->offset.x;
	y[1] = [p headY: t->headnum] + t->offset.y;
    }
    else
    {
	e = ([p sysNum] < [t->client sysNum]);
	x[1] = [p xOfStaffEnd: e];
	y[1] = y[0];
	b = 1;
	e += 1;
    }
    orderXY(x, y);
    if (needtheta[style])
    {
	dx = x[1] - x[0];
	dy = y[1] - y[0];
	d = hypot(dx,dy);
	cth = dx / d;
	sth = dy / d;
    }
    if (candash[style] && flags.dashed)
    {
	csetdash(YES, nature[sz] * 2);
    }
    if (gFlags.selected && !gFlags.seldrag)
    {
	if (e & 2) crect(x[0] - HANDSIZE, y[0] - HANDSIZE, 2*HANDSIZE, 2*HANDSIZE, m);
	if (e & 1) crect(x[1] - HANDSIZE, y[1] - HANDSIZE, 2*HANDSIZE, 2*HANDSIZE, m);
    }
    switch(style)
    {
	case TIESLUR:
	case TIEBOW:
	    if (d < 5.0) return self;
	    cth = dx / d;
	    a = acos((double) cth) * DEGpRAD;
	    if (flags.above) a += 180.0;
		if (dy < 0) a = -a;
		    th = 0.25 * nature[sz];
	    cx = x[0] + 0.5 * dx;
	    cy = y[0] + 0.5 * dy;
	    if (b) h = getdepth(dx); else h = depth;
//NSLog(@"cx=%f, cy=%f, d=%f, h=%f, th=%f, a=%f, cth=%f, fl=%f\n", cx, cy, d, h, th, a, cth, flatness);
	    ctie(cx, cy, d, h, th, a, flatness, flags.dashed, m);
	    if (flags.ed)
	    {
		h = depth;
		if (flags.above) h = -h;
		cx += -sth * h;
		cy += cth * h;
		cline(cx, cy - 5, cx, cy + 5, barwidth[0][sz], m);
	    }
		break;
	case TIELINE:
	    cline(x[0], y[0], x[1], y[1], staffthick[0][sz], m);
	    break;
	case 2:
	case TIEBRACK:
	    th = staffthick[0][sz];
	    v = 2.0 * nature[sz];
	    if (flags.above) v = -v;
		cmakeline(x[0], y[0], x[0], y[0] + v, m);
	    cmakeline(x[0], y[0] + v, x[1], y[1] + v, m);
	    cmakeline(x[1], y[1] + v, x[1], y[1], m);
	    cstrokeline(th, m);
	    break;
	case TIECORN:
	    th = staffthick[0][sz];
	    h = v = 2.0 * nature[sz];
	    if (flags.above) v = -v;
		cmakeline(x[0], y[0], x[0], y[0] + v, m);
	    cmakeline(x[0], y[0] + v, x[0] + h * cth, (y[0] + v) + h * sth, m);
	    cmakeline(x[1], y[1], x[1], y[1] + v, m);
	    cmakeline(x[1], y[1] + v, x[1] - h * cth, (y[1] + v) - h * sth, m);
	    cstrokeline(th, m);
	    break;
	case TIECRES:
	    th = staffthick[0][(int)smallersz[sz]];
	    h = 0.5 * depth;
	    cx = x[1] - h * sth;
	    cy = y[1] + h * cth;
	    cmakeline(x[0], y[0], cx, cy, m);
	    cx = x[1] + h * sth;
	    cy = y[1] - h * cth;
	    cmakeline(x[0], y[0], cx, cy, m);
	    cstrokeline(th, m);
	    break;
	case TIEDECRES:
	    th = staffthick[0][(int)smallersz[sz]];
	    h = 0.5 * depth;
	    cx = x[0] - h * sth;
	    cy = y[0] + h * cth;
	    cmakeline(x[1], y[1], cx, cy, m);
	    cx = x[0] + h * sth;
	    cy = y[0] - h * cth;
	    cmakeline(x[1], y[1], cx, cy, m);
	    cstrokeline(th, m);
	    break;
    }
    if (candash[style] && flags.dashed) 
	csetdash(NO, 0.0);

    return self;
}


/* if Aselected == Bselected, then master is drawn. else selected is drawn */

- draw
{
  if (flags.same)
  {
    if (gFlags.selected == ((Tie *)partner)->gFlags.selected)
    {
      if (!flags.master) return NO;
    }
    else if (!gFlags.selected) return NO;
  }
  return [self drawMode: drawmode[gFlags.selected][gFlags.invis]];
}



/* Archiving */

struct oldflags  /* for old version */
{
  unsigned int fixed : 1;  	/* whether location fixed */
  unsigned int place : 2;	/* 0=head 1=tail, 2=top 3=bottom */
  unsigned int above : 1;	/* whether above the group (cache) */
  unsigned int same : 1;	/* whether same as partner */
  unsigned int ed : 1;	/* editorial mark */
  unsigned int usedepth : 1;	/* whether to use depth */
  unsigned int master : 1;	/* whether this is the master */
};



extern int needUpgrade;

- (id)initWithCoder:(NSCoder *)aDecoder
{
  char r1, r2, r3, r4, r5, r6, r7, r8, r9;
  struct oldflags f;
  int v = [aDecoder versionForClassName:@"Tie"];
  [super initWithCoder:aDecoder];
  needUpgrade |= 1;
  partner = [[aDecoder decodeObject] retain];
  offset = [aDecoder decodePoint];
  headnum = 0;
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"fccccc", &depth, &r1, &r2, &r3, &r4, &r5];
    flags.fixed = r3;
    flags.place = 0;
    flags.above = r1;
    flags.same = r5;
    flags.ed = r2;
    flags.usedepth = r4;
    flags.master = 1;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"fs", &depth, &f];
    flags.fixed = f.fixed;
    flags.place = f.place;
    flags.above = f.above;
    flags.same = f.same;
    flags.ed = f.ed;
    flags.usedepth = f.usedepth;
    flags.master = f.master;
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"fccccccc", &depth, &r1, &r2, &r3, &r4, &r5, &r6, &r7];
    flags.fixed = r1;
    flags.place = r2;
    flags.above = r3;
    flags.same = r4;
    flags.ed = r5;
    flags.usedepth = r6;
    flags.master = r7;
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"fcccccccc", &depth, &headnum, &r1, &r2, &r3, &r4, &r5, &r6, &r7];
    flags.fixed = r1;
    flags.place = r2;
    flags.above = r3;
    flags.same = r4;
    flags.ed = r5;
    flags.usedepth = r6;
    flags.master = r7;
    if (headnum > 0) headnum--;
  }
  else if (v == 4)
  {
    [aDecoder decodeValuesOfObjCTypes:"fcccccccc", &depth, &headnum, &r1, &r2, &r3, &r4, &r5, &r6, &r7];
    flags.fixed = r1;
    flags.place = r2;
    flags.above = r3;
    flags.same = r4;
    flags.ed = r5;
    flags.usedepth = r6;
    flags.master = r7;
  }
  else if (v == 5)
  {
    [aDecoder decodeValuesOfObjCTypes:"fccccccccc", &depth, &headnum, &r1, &r2, &r3, &r4, &r5, &r6, &r7, &r8];
    flags.fixed = r1;
    if (r2 > 1) r2 -= 2;  /* change of format: now all are 0 or 1 */
    flags.place = r2;
    flags.above = r3;
    flags.same = r4;
    flags.ed = r5;
    flags.usedepth = r6;
    flags.master = r7;
    flags.horvert = r8;
  }
  else if (v == 6)
  {
    [aDecoder decodeValuesOfObjCTypes:"ffcccccccccc", &depth, &flatness, &headnum, &r1, &r2, &r3, &r4, &r5, &r6, &r7, &r8, &r9];
    flags.fixed = r1;
    flags.place = r2;
    flags.above = r3;
    flags.same = r4;
    flags.ed = r5;
    flags.usedepth = r6;
    flags.master = r7;
    flags.horvert = r8;
    flags.dashed = r9;
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder;
{
  char r1, r2, r3, r4, r5, r6, r7, r8, r9;
    [super encodeWithCoder:aCoder];
    [aCoder encodeConditionalObject:partner];
    [aCoder encodePoint:offset];
  r1 = flags.fixed;
  r2 = flags.place;
  r3 = flags.above;
  r4 = flags.same;
  r5 = flags.ed;
  r6 = flags.usedepth;
  r7 = flags.master;
  r8 = flags.horvert;
  r9 = flags.dashed;
  [aCoder encodeValuesOfObjCTypes:"ffcccccccccc", &depth, &flatness, &headnum, &r1, &r2, &r3, &r4, &r5, &r6, &r7, &r8, &r9];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setObject:partner forKey:@"partner"];
    [aCoder setPoint:offset forKey:@"offset"];
    [aCoder setFloat:depth forKey:@"depth"];
    [aCoder setFloat:flatness forKey:@"flatness"];
    [aCoder setInteger:headnum forKey:@"headnum"];
    [aCoder setInteger:flags.fixed forKey:@"fixed"];
    [aCoder setInteger:flags.place forKey:@"place"];
    [aCoder setInteger:flags.above forKey:@"above"];
    [aCoder setInteger:flags.same forKey:@"same"];
    [aCoder setInteger:flags.ed forKey:@"ed"];
    [aCoder setInteger:flags.usedepth forKey:@"usedepth"];
    [aCoder setInteger:flags.master forKey:@"master"];
    [aCoder setInteger:flags.horvert forKey:@"horvert"];
    [aCoder setInteger:flags.dashed forKey:@"dashed"];
}

@end
