/* $Id$ */
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "Tuple.h"
#import "TupleInspector.h"
#import "NoteGroupInspector.h"
#import "Beam.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "GNote.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "System.h"
#import "Staff.h"
#import "FileCompatibility.h"

@implementation Tuple

static Tuple *proto;

+ (void)initialize
{
  if (self == [Tuple class])
  {
      (void)[Tuple setVersion: 9];		/* class version, see read: */
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
  return [TupleInspector class];
}


- init
{
  [super init];
  [self setTypeOfGraphic: TUPLE];
  gFlags.subtype = 1;
  client = nil;
  flags.formliga = 0;
  flags.localiga = 0;
  flags.fixed = 0;
  flags.horiz = 0;
  flags.above = 0;
  flags.centre = 0;
  uneq1 = 3;
  uneq2 = 0;
  body = dot = 0;
  style = 0;
  vtrim1 = vtrim2 = 0.0;
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


/* find total notated tick of group: does not handle nested tuples */

- (float) notatedTick
{
  TimedObj *p;
  int k = [client count];
  float s = 0.0;
  while (k--)
  {
    p = [client objectAtIndex:k];
    s += tickval(p->time.body, [p dottingCode]);
  }
  return s;
}


/* how a tuple modifies the tick, check for override (case 3 happens by default) */

- (float) modifyTick: (float) t
{
  if (body)
  {
    return t *  tickval(body, dot) / [self notatedTick];
  }
  switch(gFlags.subtype)
  {
    case 1:  /* tuplet */
      t = 2.0 * t / uneq1;
      break;
    case 2:  /* ratio */
      t = uneq2 * t / uneq1;
      break;
  }
  return t;
}


/* set caches according to flags sn to sort, off to set default offsets */


/* braoffx[left/right][type] in notewidth units; */

static float braoffx[2][8] =
{
  {-1.0, -1.0, -1.0, -1.0, -1.0, -0.2, -1.0, -0.2},
  { 0.2,  1.0,  1.0,  1.0,  0.2,  1.0,  1.0,  1.0}
};

static int tupoffx[2][8] =
{
  {-1, -1, -1, -1,  0,  0,  0,  0},
  {-1,  1,  1,  1, -1,  1,  1,  1}
};

/* braoffy[left/right][below/above] in nature units */

static float braoffy[2][2] = 
{
  { 1.0, -1.0},
  { 1.0, -1.0}
};

- (BOOL) majorityUp
{
  int k, sd = 0, su = 0;
  TimedObj *p;
  k = [client count];
  while (k--)
  {
    p = [client objectAtIndex: k];
    if ([p stemIsUp]) ++su ; else ++sd;
  }
  return (su > sd);
}

- setTuple: (int) sn : (int) off
{
    int sz, a=0, tt, pup, qup; //sb: initted a
  float px, py, qx, qy, dx, dy, ly, y, my, ey;
  TimedObj *p, *q;
  if (sn) [super sortNotes: client];
  p = [client objectAtIndex:0];
  q = [client lastObject];
  pup = [p stemIsUp];
  qup = [q stemIsUp];
  sz = p->gFlags.size;
  switch(flags.localiga)
  {
    case 0:
        a = ![self majorityUp];
      break;
    case 1:
        a = [self majorityUp];
      break;
    case 2:
      a = 1;
      break;
    case 3:
      a = 0;
      break;
  }
  flags.above = a;
  if (off)
  {
    dx = noteoffset[sz] * 2.0;
    dy = nature[sz];
    tt = (pup << 2) | (qup << 1) | a;
    py = ([p yAboveBelow: a] - [p y]) + braoffy[0][a] * dy;
    qy = ([q yAboveBelow: a] - [q y]) + braoffy[1][a] * dy;
    if (flags.formliga >= 4)
    {
      px = tupoffx[0][tt] * noteoffset[sz];
      qx = tupoffx[1][tt] * noteoffset[sz];
    }
    else
    {
      px = braoffx[0][tt] * dx;
      qx = braoffx[1][tt] * dx;
    }
  }
  else
  {
    px = x1;
    py = y1;
    qx = x2;
    qy = y2;
  }
  /* satisfy the horizontality constraint */
  vtrim1 = vtrim2 = 0.0;
  if (flags.horiz)
  {
    ly = [p y] + py;
    my = [q y] + qy;
    ey = ly - my;
    if (a ^ (ey > 0)) vtrim2 = ey; else vtrim1 = -ey;
  }
  if (off)
  {
    /* now make sure it is above/below staff. */
    ly = [p y] + py;
    my = [q y] + qy;
    if (a)
    {
      y = [p yOfStaffPosition: -1];
      if (ly > y) py -= (ly - y);
      y = [q yOfStaffPosition: -1];
      if (my > y) qy -= (my - y);
    }
    else
    {
      y = [p yOfStaffPosition: 9];
      if (ly < y) py += (y - ly);
      y = [q yOfStaffPosition: 9];
      if (my < y) qy += (y - my);
    }
#if 0
    /* need to check for collisions (need to rewrite) */
    k = [client count] - 1;
    m = (qy - py) / (qx - px);
    my = MINFLOAT;
    for (i = 1; i < k; i++)
    {
      p = [client objectAtIndex:i];
      x = p->bounds.origin.x + 0.5 * p->bounds.size.width;
      ly = m * (x - px) + py;
      if (a)
      {
        y = p->bounds.origin.y;
        ey = ly - y;
      }
      else
      {
        y = p->bounds.origin.y + p->bounds.size.height;
        ey = y - ly;
      }
      if (ey > my) my = ey;
    }
    if (my > 0)
    {
      if (a)
      {
        py -= my;
        qy -= my;
      }
      else
      {
        py += my;
        qy += my;
      }
    }
 #endif
    if ([self myLevel])
    {
      dy = [self myLevel] * 4 * nature[sz];
      if (a) dy = -dy;
      py += dy;
      qy += dy;
    }
  }
  x1 = px;
  y1 = py;
  x2 = qx;
  y2 = qy;
  return self;
}



- setHanger
{
  [self setTuple: 1 : !flags.fixed];
  return [self recalc];
}


- setHanger: (BOOL) f1 : (BOOL) f2
{
  [self setTuple: f1 : f2];
  return [self recalc];
}


/*
  control ligature location: (b: 0 hd, 1 tl, 2 top, 3 bot, -1 no op).
  returns state.
*/

- (int) ligaDir: (int) b
{
  if (b == -1) return flags.localiga;
  flags.localiga = b;
  [self setTuple: 0 : !flags.fixed];
  [self recalc];
  return flags.localiga;
}


- linkGroup: (NSMutableArray *) l
{
  int bk = 0, k;
  TimedObj *q;
  Beam *b;
  NSArray *bl = nil;
  int lk = [l count];
  k = lk;
  if (k == 0) return nil;
  if (k == 1)
  {
    b = [l objectAtIndex:0];
    if ([b graphicType] == BEAM)
    {
      client = [[NSMutableArray alloc] init];
      bl = [b clients];
      bk = [bl count];
      for (k = 0; k < bk; k++) [(NSMutableArray *)client addObject: [bl objectAtIndex:k]];
    }
    else return nil;
  }
  else
  {
    k = lk;
    while (k--)
    {
      q = [l objectAtIndex:k];
      if (ISASTAFFOBJ(q)) ++bk;
    }
    if (bk < 2) return nil;
    client = [[NSMutableArray alloc] init];
    k = lk;
    while (k--)
    {
      q = [l objectAtIndex:k];
      if (ISATIMEDOBJ(q)) [(NSMutableArray *)client addObject: q];
    }
  }
  k = bk;
  [self setLevel: [self maxLevel] + 1];
  while (k--) [[client objectAtIndex:k] linkhanger: self];
  q = [client objectAtIndex:0];
  flags.localiga = 1;
  if (bl != nil && [self myLevel] == 0)
      flags.formliga = 0;
  else if ([q isBeamed]) flags.formliga = 2;
  else
  {
    flags.formliga = proto->flags.formliga;
    flags.localiga = proto->flags.localiga;
  }
  gFlags.size = q->gFlags.size;
  uneq1 = bk;
  return self;
}


- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
{
  if ([self linkGroup: [v selectedGraphics]] == nil) return nil;
  style = proto->style;
  gFlags.subtype = proto->gFlags.subtype;
  [self setTuple: 1 : 1];
  return self;
}


- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
  if ([self linkGroup: sl] == nil) return NO;
  [self setHanger: 1 : 1];
  [v selectObj: self];
  return YES;
}  


/* remove from client anything not on list l.  Return whether an OK tuple. */

- (BOOL) isClosed: (NSMutableArray *) l
{
  [super closeClients: l];
  return ([client count] >= 2);
}


/* the complication is renumbering the remaining tuples */

- (void)removeObj
{
    [self retain];
    [super removeGroup];
    [self release];
}


- coordsForHandle: (int) h  asX: (float *) x  andY: (float *) y
{
  StaffObj *p;
  if (h == 0)
  {
    p = [client objectAtIndex:0];
    *x = [p x] + x1;
    *y = [p y] + y1 + vtrim1;
  }
  else if (h == 1)
  {
    p = [client lastObject];
    *x = [p x] + x2;
    *y = [p y] + y2 + vtrim2;
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


/* override hit */

- (BOOL) hit: (NSPoint) p
{
  return [super hit: p : 0 : 1];
}

- (float) hitDistance: (NSPoint) p
{
  return [super hitDistance: p : 0 : 1];
}


/* override move */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  StaffObj *n;
  
  if (gFlags.selend)
  {
    n = [client lastObject];
    x2 = p.x - [n x];
    y2 = p.y - [n y];
    if (flags.horiz)
    {
      n = [client objectAtIndex:0];
      y1 = p.y - [n y];
    }
  }
  else
  {
    n = [client objectAtIndex:0];
    x1 = p.x - [n x];
    y1 = p.y - [n y];
    if (flags.horiz)
    {
      n = [client lastObject];
      y2 = p.y - [n y];
    }
  }
  [self setTuple: 0 : 0];
  [self recalc];
  return YES;
}

/* draw the old fashioned tie notation */

static float sluroffy[2] = { 1.0, -1.0};

- drawBow: (int) a : (float) h : (float) x0 : (float) y0 : (float) xe1 : (float) ye1 : (int) m
{
  float dx, dy,  xe2, ye2, x3, y3, x4, y4, x5, y5, th, t, d;
  NSPoint con1, con2;
  th = nature[gFlags.size] * 0.5;
  dx = xe1 - x0;
  dy = ye1 - y0;
  d = hypot(dx, dy);
  /* left and right controls */
  con1.x = 0.25;
  con2.x = 0.75;
  con1.y = con2.y = (h / d) * sluroffy[a];
  xe2 = x0 + con1.x * dx - con1.y * dy;
  ye2 = y0 + con1.x * dy + con1.y * dx;
  x3 = x0 + con2.x * dx - con2.y * dy;
  y3 = y0 + con2.x * dy + con2.y * dx;
  /* left and right depth controls */
  t = (con1.y * d - th) / d;
  x4 = x0 + con1.x * dx - t * dy;
  y4 = y0 + con1.x * dy + t * dx;
  t = (con2.y * d - th) / d;
  x5 = x0 + con2.x * dx - t * dy;
  y5 = y0 + con2.x * dy + t * dx;
  ccurve(x0, y0, xe1, ye1, xe2, ye2, x3, y3, x4, y4, x5, y5, th, 0, m);
  return self;
}

/* return the x on which to centre the number */

static float centreTime(NSMutableArray *nl)
{
  TimedObj *p;
  int i, k;
  float s, a;
  k = [nl count];
  s = 0.0;
  for (i = 0; i < k; i++)
  {
    p = [nl objectAtIndex:i];
    s += [p noteEval: NO];
  }
  s /= 2.0;
  a = 0.0;
  for (i = 0; i < k; i++)
  {
    p = [nl objectAtIndex:i];
    a += [p noteEval: NO];
    if (a - s > 0.0) return [p x];
  }
  return 0.0;
}



- drawMode: (int) m
{
    StaffObj *p, *q;
    GraphicView *gv = nil;
    int sz;
    float dx, dy, v, th, w, x, y, ty = 0.0, charh, px, py, qx, qy; //sb: initted ty
    NSString *tuple;
    char brack;
    
    /* assume client sorted by the time we arrive here */
    sz = gFlags.size;
    p = [client objectAtIndex:0];
    q = [client lastObject];
    px = [p x] + x1;
    py = [p y] + y1 + vtrim1;
    qx = [q x] + x2;
    qy = [q y] + y2 + vtrim2;
    dx = qx - px;
    dy = qy - py;
    if (ABS(dx) < 1.0) return self;
    if (gFlags.selected && !gFlags.seldrag)
    {
	chandle(px, py, m);
	chandle(qx, qy, m);
    }
    charh = charFGH(fontdata[FONTSTMR], '3');
    if (gFlags.subtype == 1 && flags.centre && [client count] > 2) x = centreTime(client);
    else x = px + 0.5 * dx;
    y = (dy / dx) * (x - px) + py;
    switch(flags.formliga)
    {
	case 1:
	    ty = 3.0 * nature[sz];
	    break;
	case 0:
	case 2:
	case 3:
	case 5:
	    ty = nature[sz];
	    break;
	case 4:
	    ty = charh + nature[sz];
	    break;   
    }
    ty = y + (flags.above ? -ty : ty);
    switch(gFlags.subtype)
    {
	case 0:
	    /* reserved */
	    break;
	case 1:
	    tuple = [NSString stringWithFormat: @"%d", uneq1];
	    if (!flags.above) 
		ty += charh;
	    DrawCenteredText(x, ty, tuple, fontdata[FONTSTMR], m);
	    break;
	case 2:
	    tuple = [NSString stringWithFormat: @"%d:%d", uneq1, uneq2];
	    if (!flags.above) 
		ty += charh;
	    DrawCenteredText(x, ty, tuple, fontdata[FONTSTMR], m);
	    break;
	case 3:
	    charh = stemlens[0][1];
	    csnote(x, ty, (flags.above ? -charh : charh), body, dot, 1, 0, 0, m);
	    break;
    }
    brack = 0;
    v = 2.0 * nature[sz];
    switch(flags.formliga)
    {
	case 0:
	    /* no liga: draw a grey (invisible) marker */
	    if (!gFlags.selected) m = 5;
	    brack = 1;
	    break;
	case 1:
	    break;
	case 2:
	    brack = 1;
	    break;
	case 3:
	    ty = 0.0;
	    charh += 2.0 * nature[sz];
	    if (charh > v) ty = charh - v;
	    if (flags.above) ty = -ty;
	    py += ty;
	    qy += ty;
	    break;
	case 4:
	    brack = 2;
	    break;
	case 5:
	    ty = 0.0;
	    charh += nature[sz];
	    if (charh > v) ty = charh - v;
	    if (flags.above) ty = -ty;
	    py += ty;
	    qy += ty;
	    brack = 2;
	    break;   
    }
    th = staffthick[0][sz];
    switch (brack)
    {
	case 0:
	    if (flags.above) v = -v;
	    cmakeline(px, py, px, py + v, m);
	    cmakeline(px, py + v, qx, qy + v, m);
	    cmakeline(qx, qy + v, qx, qy, m);
	    cstrokeline(th, m);
	    break;
	    
	case 1:
	    w = [fontdata[FONTSTMR] widthOfString:@"33"];
	    if (gFlags.subtype < 3) w += [fontdata[FONTSTMR] widthOfString: tuple];
	    w *= 0.5;
	    if (flags.above) v = -v;
	    cmakeline(px, py, px, py + v, m);
	    y = (dy / dx) * (x - w - px) + py;
	    cmakeline(px, py + v, x - w, y + v, m);
	    cmakeline(qx, qy, qx, qy + v, m);
	    y = (dy / dx) * (x + w - px) + py;
	    cmakeline(qx, qy + v, x + w, y + v, m);
	    if (m == 5)
	    {
		gv = [CalliopeAppController currentView];
		[gv lockFocus];
	    }
	    cstrokeline(th, m);
	    if (m == 5) [gv unlockFocus];
	    break;
	    
	case 2:
	    [self drawBow: flags.above : charh : px : py : qx : qy : m];
	    break;
    }
    return self;
}


/* Archiving */


struct oldflags	/* for old version */
{
  unsigned int count : 6;	/* hence limit of 64 notes */
  unsigned int subtype : 2;	/* 0=reserved 1=tuplet 2=ratio 3=body+dot */
  unsigned int formliga : 2;	/* 0=nobrack 1=tupout 2=tupmid 3=tupin */
  unsigned int fixed : 1;  	/* whether location fixed */
  unsigned int localiga : 2;	/* 0=head 1=tail, 2=top 3=bottom */
  unsigned int above : 1;	/* whether above the group (cache) */
  unsigned int horiz : 1;	/* whether horizontally constrained */
};


- readUpdate: (int) v
{
  switch(gFlags.subtype)
  {
    case 1:
      body = 0;
      break;
    case 2:
      if (v) uneq2 = uneq1 - 1;
      body = 0;
      break;
    case 3:
      body = uneq1;
      dot = uneq2;
      break;
    case 4:
    case 5:
    case 6:
      style = 1;
      gFlags.subtype -= 4;
      break;
  }
  return self;
}


/* versions 1 and 2 forgot to archive uneq2! */

- (id) initWithCoder: (NSCoder *) aDecoder
{
  char b1, b2, b3, b4, b5, b6, b7, b8, v, anon;
  struct oldflags f;

  [super initWithCoder: aDecoder];
  v = [aDecoder versionForClassName:@"Tuple"];
  [self setLevel: 0]; // TODO perhaps this shouldn't be done here?
  flags.centre = 0;
  vtrim1 = vtrim2 = 0.0;
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"@sccffff", &client, &f, &uneq1, &uneq2, &x1, &y1, &x2, &y2];
    gFlags.subtype = f.subtype;
    flags.formliga = f.formliga;
    flags.fixed = f.fixed;
    flags.localiga = f.localiga;
    flags.above = f.above;
    flags.horiz = f.horiz;
    x1 = x2 = y1 = y2 = 0.0;
    flags.fixed = 0;
    flags.localiga = 2;
    style = 0;
    [self readUpdate: 0];
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"@ffff", &client, &x1, &y1, &x2, &y2];
    [aDecoder decodeValuesOfObjCTypes:"cccccccc", &uneq1, &b1, &b2, &b3, &b4, &b5, &b6, &b7];
    gFlags.subtype = b2;
    flags.formliga = b3;
    flags.fixed = b4;
    flags.localiga = b5;
    flags.above = b6;
    flags.horiz = b7;
    x1 = x2 = y1 = y2 = 0.0;
    flags.fixed = 0;
    flags.localiga = 2;
    [self readUpdate: 1];
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"@ffff", &client, &x1, &y1, &x2, &y2];
    [aDecoder decodeValuesOfObjCTypes:"ccccccc", &uneq1, &b1, &b3, &b4, &b5, &b6, &b7];
    flags.formliga = b3;
    flags.fixed = b4;
    flags.localiga = b5;
    flags.above = b6;
    flags.horiz = b7;
    [self readUpdate: 1];
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"@ffff", &client, &x1, &y1, &x2, &y2];
    [aDecoder decodeValuesOfObjCTypes:"cccccccc", &uneq1, &uneq2, &b1, &b3, &b4, &b5, &b6, &b7];
    flags.formliga = b3;
    flags.fixed = b4;
    flags.localiga = b5;
    flags.above = b6;
    flags.horiz = b7;
    [self readUpdate: 1];
  }
  else if (v == 4)
  {
    [aDecoder decodeValuesOfObjCTypes:"@ffff", &client, &x1, &y1, &x2, &y2];
    [aDecoder decodeValuesOfObjCTypes:"cccccccccc", &style, &anon, &uneq1, &uneq2, &b1, &b3, &b4, &b5, &b6, &b7];
    flags.formliga = b3;
    flags.fixed = b4;
    flags.localiga = b5;
    flags.above = b6;
    flags.horiz = b7;
  }
  else if (v == 5)
  {
    [aDecoder decodeValuesOfObjCTypes:"@ffff", &client, &x1, &y1, &x2, &y2];
    [aDecoder decodeValuesOfObjCTypes:"ccccccccccc", &style, &body, &dot, &uneq1, &uneq2, &b1, &b3, &b4, &b5, &b6, &b7];
    flags.formliga = b3;
    flags.fixed = b4;
    flags.localiga = b5;
    flags.above = b6;
    flags.horiz = b7;
  }
  else if (v == 6)
  {
    [aDecoder decodeValuesOfObjCTypes:"@ffff", &client, &x1, &y1, &x2, &y2];
    [aDecoder decodeValuesOfObjCTypes:"ccccccccccc", &style, &body, &dot, &uneq1, &uneq2, &b1, &b3, &b4, &b5, &b6, &b7];
    [self setLevel: b1];
    flags.formliga = b3;
    flags.fixed = b4;
    flags.localiga = b5;
    flags.above = b6;
    flags.horiz = b7;
  }
  else if (v == 7)
  {
    [aDecoder decodeValuesOfObjCTypes:"ffff", &x1, &y1, &x2, &y2];
    [aDecoder decodeValuesOfObjCTypes:"cccccccccc", &style, &body, &dot, &uneq1, &uneq2, &b3, &b4, &b5, &b6, &b7];
    flags.formliga = b3;
    flags.fixed = b4;
    flags.localiga = b5;
    flags.above = b6;
    flags.horiz = b7;
  }
  else if (v == 8)
    {
      [aDecoder decodeValuesOfObjCTypes:"ffff", &x1, &y1, &x2, &y2];
      [aDecoder decodeValuesOfObjCTypes:"ccccccccccc", &style, &body, &dot, &uneq1, &uneq2, &b3, &b4, &b5, &b6, &b7, &b8];
        flags.formliga = b3;
        flags.fixed = b4;
        flags.localiga = b5;
        flags.above = b6;
        flags.horiz = b7;
        flags.centre = b8;
      }
      else if (v == 9)
      {
          [aDecoder decodeValuesOfObjCTypes:"ffffff", &x1, &y1, &x2, &y2, &vtrim1, &vtrim2];
          [aDecoder decodeValuesOfObjCTypes:"ccccccccccc", &style, &body, &dot, &uneq1, &uneq2, &b3, &b4, &b5, &b6, &b7, &b8];
        flags.formliga = b3;
        flags.fixed = b4;
        flags.localiga = b5;
        flags.above = b6;
        flags.horiz = b7;
        flags.centre = b8;
      }

  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b3, b4, b5, b6, b7, b8;
  [super encodeWithCoder:aCoder];
  [aCoder encodeValuesOfObjCTypes:"ffffff", &x1, &y1, &x2, &y2, &vtrim1, &vtrim2];
  b3 = flags.formliga;
  b4 = flags.fixed;
  b5 = flags.localiga;
  b6 = flags.above;
  b7 = flags.horiz;
  b8 = flags.centre;
  [aCoder encodeValuesOfObjCTypes:"ccccccccccc", &style, &body, &dot, &uneq1, &uneq2, &b3, &b4, &b5, &b6, &b7, &b8];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setFloat:x1 forKey:@"x1"];
    [aCoder setFloat:y1 forKey:@"y1"];
    [aCoder setFloat:x2 forKey:@"x2"];
    [aCoder setFloat:y2 forKey:@"y2"];
    [aCoder setFloat:vtrim1 forKey:@"vtrim1"];
    [aCoder setFloat:vtrim2 forKey:@"vtrim2"];
    [aCoder setInteger:style forKey:@"style"];
    [aCoder setInteger:body forKey:@"body"];
    [aCoder setInteger:dot forKey:@"dot"];
    [aCoder setInteger:uneq1 forKey:@"uneq1"];
    [aCoder setInteger:uneq2 forKey:@"uneq2"];
    [aCoder setInteger:flags.formliga forKey:@"formliga"];
    [aCoder setInteger:flags.fixed forKey:@"fixed"];
    [aCoder setInteger:flags.localiga forKey:@"localiga"];
    [aCoder setInteger:flags.above forKey:@"above"];
    [aCoder setInteger:flags.horiz forKey:@"horiz"];
    [aCoder setInteger:flags.centre forKey:@"centre"];
}

@end
