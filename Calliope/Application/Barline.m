/* $Id$ */
#import "Barline.h"
#import "Bracket.h"
#import "BarInspector.h"
#import "GraphicView.h"
#import "Staff.h"
#import "System.h"
#import <AppKit/NSFont.h>
//#import "draw.h"  // This was generated by the pswrap utility from draw.psw.
#import "mux.h"
#import "muxlow.h"


@implementation Barline

#define DRAGSIZE 20.0		/* size of a bar token if not on a staff */

static Barline *proto;


+ (void)initialize
{
  if (self == [Barline class])
  {
      (void)[Barline setVersion: 4];	/* class version, see read: sb: bumped up to 4 because of "pos"*/
    proto = [[Barline alloc] init];
    proto->gFlags.subtype = SINGLE;
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [BarInspector class];
}


- init
{
  [super init];
  gFlags.type = BARLINE;
  flags.editorial = 0;
  flags.staff = 1;
  flags.bridge = 0;
  flags.nocount = 0;
  flags.dashed = 0;
  flags.nonumber = 0;
  pos = 0;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- (int) barCount
{
  if (flags.nocount) return 0;
  if (ISINVIS(self)) return 0;
  return 1;
}


/* initialise the prototype barline */

- proto: (GraphicView *) v : (NSPoint ) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  [super proto: v : pt : sp : sys : g : i];
  gFlags.subtype = proto->gFlags.subtype;
  flags = proto->flags;
  if ((sp != nil) && [sp atTopOf: BRACE]) flags.bridge = 1;
  return self;
}


/*
  return positions at extremities (a = above)
  (override to give values relating to the staff, NOT to the bar itself
*/

- (int) posAboveBelow: (int) a
{
  return  a ?  0 : [mystaff posOfBottom];
}


- (float) yAboveBelow: (int) a;
{
  if (a) return [mystaff yOfTop];
  return [mystaff yOfBottom];
}


/* verses are "stopped" (hyphen doesn't continue) by thick barlines. */

static BOOL barstops[16] = { 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 };

- (BOOL) stopsVerse
{
  return barstops[gFlags.subtype];
}


/* override to avoid collisions with between-staff bars */

- verseWidths: (float *) tb : (float *) ta
{
  float v, w;
  [super verseWidths: &v : &w];
  if (flags.bridge && v == 0 && w == 0)
  {
    *tb = x - bounds.origin.x;
    *ta = bounds.origin.x + bounds.size.width - x;
  }
  else
  {
    *tb = v;
    *ta = w;
  }
  return self;
}


/*
  Draw dots for a bar.
  If nl < 0, then put a dot in each space.  Otherwise, put 2 or 3
  dots depending on whether nl is odd or even.
*/

void bardots(int nl, float x, float y, int spacing, int sz, int m)
{
  int i;
  NSFont *f = musicFont[1][sz];
  if (nl < 0)
  {
    nl = ((-nl) - 1) << 1;
    i = 1;
    while (i < nl)
    {
      centChar(x, y + spacing * i, SF_dot, f,  m);
      i += 2;
    }
  }
  else if (nl & 1)
  {
    nl--;
    centChar(x, y + spacing * (nl - 1), SF_dot, f, m);
    centChar(x, y + spacing * (nl + 1), SF_dot, f, m);
  }
  else
  {
    nl--;
    centChar(x, y + spacing * nl, SF_dot, f, m);
    centChar(x, y + spacing * (nl - 2), SF_dot, f, m);
    centChar(x, y + spacing * (nl + 2), SF_dot, f, m);
  }
}


/* draw various bar lines, accounting for staff thickness */

void barline(float x, float y1, float sth, float y2, float th, int m)
{
    NSLog(@"y1=%f, sth=%f, y2=%f", y1, sth, y2);
    cline(x, y1 - sth, x, y2, th, m);
}


void barthick(float x, float y1, float sth, float y2, float th, int m)
{
  crect(x, y1 - sth, th, y2 - y1 + 2.0 * sth, m);
}


static float dpattern[1];

static BOOL canbridge[16] = {1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1};

static int invismode[8] = {0, 4, 4, 4, 4, 4, 4, 7};

/* various inconsistencies are detected, and a suitable bar printed */

- drawMode: (int) m
{
  float y1, y2, f, bw, bs, ss, sth;
  int sz = gFlags.size;
  Staff *s1, *s;
  s = mystaff;
  if (TYPEOF(s) == SYSTEM)
  {
    barline(x, y, 0.0, (y + DRAGSIZE), barwidth[0][gFlags.size], m);
    return self;
  }
  y1 = [s yOfTop];
  if (flags.editorial)
  {
    barline(x, (y1 - nature[sz]), 0.0, (y1 - 3 * nature[sz]), barwidth[s->flags.subtype][gFlags.size], m);
  }
  y2 = y1 + [s staffHeight];
  if (canbridge[gFlags.subtype])
  {
    switch((flags.staff << 1) + flags.bridge)
    {
      case 0:
        m = invismode[m];
        break;
      case 1:
        s1 = [s->mysys nextstaff: s];
        if (s1 != nil)
	{
          y1 = y2;
	  y2 = [s1 yOfTop];
	}
	else  m = invismode[m];
        break;
      case 2:
        break;
      case 3:
        s1 = [s->mysys nextstaff: s];
        if (s1 != nil) y2 = [s1 yOfTop];
        break;
    }
  }
  bw = barwidth[s->flags.subtype][gFlags.size];
  sth = 0.5 * staffthick[s->flags.subtype][s->gFlags.size];
  bs = nature[0];
  f = 0.5 * bs;
  ss = s->flags.spacing;
  if (flags.dashed)
  {
    dpattern[0] = nature[sz];
    PSsetdash(dpattern, 1, 0.0);
    // TODO [bezPath setLineDash: dpattern count: 1 phase: 0.0]; // but we need to know bezPath!
  }
  if (s->flags.nlines == 1 && !flags.bridge)
  {
    y1 -= 2 * ss;
    y2 += 2 * ss;
  }
  switch (gFlags.subtype)
  {
    case SINGLE:
      barline(x, y1, sth, y2, bw, m);
      break;
    case DOUBLE:
      barline(x + f, y1, sth, y2, bw, m);
      barline(x - f, y1, sth, y2, bw, m);
      break;
    case BAREND:
      barthick(x, y1, sth, y2, bs, m);
      barline(x - bs, y1, sth, y2, bw, m);
      break;
    case BARENDR:
      barthick(x, y1, sth, y2, bs, m);
      barline(x - bs, y1, sth, y2, bw, m);
      bardots(s->flags.nlines, x - (bs * 2.0), [s yOfTop], ss, sz, m);
      break;
    case BARBEG:
      barthick(x - bs, y1, sth, y2, bs, m);
      barline(x + bs, y1, sth, y2, bw, m);
      break;
    case BARBEGR:
      barthick(x - bs, y1, sth, y2, bs, m);
      barline(x + bs, y1, sth, y2, bw, m);
      bardots(s->flags.nlines, x + (bs * 2.0), [s yOfTop], ss, sz, m);
      break;
    case BARDOUR:
      barthick(x, y1, sth, y2, bs, m);
      barline(x + (bs * 2.0), y1, sth, y2, bw, m);
      barline(x - bs, y1, sth, y2, bw, m);
      bardots(s->flags.nlines, x + (bs * 3.0), [s yOfTop], ss, sz, m);
      bardots(s->flags.nlines, x - (bs * 2.0), [s yOfTop], ss, sz, m);
      break;
    case BARDOTS:
      bardots(-(s->flags.nlines), x, [s yOfTop], ss, sz, m);
      break;
    case BARHALF:
      y1 = [s yOfTop] + ss * (((int) s->flags.nlines - 1) - 2);
      y2 = [s yOfTop] + ss * (((int) s->flags.nlines - 1) + 2);
      barline(x, y1, 0.0, y2, bw, m);
      break;
    case BARQUAR:
      y1 = [s yOfTop] - ss;
      y2 = [s yOfTop] + ss;
      barline(x, y1, 0.0, y2, bw, m);
      break;
    case BARUPPER:
      y2 = [s yOfTop] + ss * (s->flags.nlines - 1);
      barline(x, y1, 0.0, y2, bw, m);
      break;
    case BARLOWER:
      y1 = [s yOfTop] + ss * (s->flags.nlines - 1);
      barline(x, y1, 0.0, y2, bw, m);
      break;
    case BARDOURB:
      barthick(x, y1, sth, y2, bs, m);
      barthick(x - bs - f, y1, sth, y2, bs, m);
      bardots(s->flags.nlines, x + (bs * 2.0), [s yOfTop], ss, sz, m);
      bardots(s->flags.nlines, x - (bs * 2.0) - f, [s yOfTop], ss, sz, m);
      break;
  }
  if (flags.dashed) PSsetdash(dpattern, 0, 0.0);
      // TODO [bezPath setLineDash: dpattern count: 0 phase: 0.0]; // but we need to know bezPath!

  return self;
}


/* Archiving */

struct oldflags  /* used for old format */
{
  unsigned int editorial : 1;
  unsigned int staff : 1;
  unsigned int bridge : 1;
  unsigned int anon : 5;
};


- (id)initWithCoder:(NSCoder *)aDecoder
{
  struct oldflags f;
  char b1, b2, b3, b4, b5, b6;
  int v = [aDecoder versionForClassName:@"Barline"];
  [super initWithCoder:aDecoder];
  flags.nocount = 0;
  flags.nonumber = 0;
  if (v < 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"sc", &f, &pos];
    flags.editorial = f.editorial;
    flags.staff = f.staff;
    flags.bridge = f.bridge;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccc", &b1, &b2, &b3, &b4, &pos];
    flags.editorial = b1;
    flags.staff = b2;
    flags.bridge = b3;
    flags.nocount = b4;
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b1, &b2, &b3, &b4, &b5, &pos];
    flags.editorial = b1;
    flags.staff = b2;
    flags.bridge = b3;
    flags.nocount = b4;
    flags.dashed = b5;
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b1, &b2, &b3, &b4, &b5, &b6, &pos];
    flags.editorial = b1;
    flags.staff = b2;
    flags.bridge = b3;
    flags.nocount = b4;
    flags.dashed = b5;
    flags.nonumber = b6;
  }
  else if (v == 4)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &pos];
    flags.editorial = b1;
    flags.staff = b2;
    flags.bridge = b3;
    flags.nocount = b4;
    flags.dashed = b5;
    flags.nonumber = b6;
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b1, b2, b3, b4, b5, b6;
  [super encodeWithCoder:aCoder];
  b1 = flags.editorial;
  b2 = flags.staff;
  b3 = flags.bridge;
  b4 = flags.nocount;
  b5 = flags.dashed;
  b6 = flags.nonumber;
  [aCoder encodeValuesOfObjCTypes:"ccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &pos];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];

    [aCoder setInteger:flags.editorial forKey:@"editorial"];
    [aCoder setInteger:flags.staff forKey:@"staff"];
    [aCoder setInteger:flags.bridge forKey:@"bridge"];
    [aCoder setInteger:flags.nocount forKey:@"nocount"];
    [aCoder setInteger:flags.dashed forKey:@"dashed"];
    [aCoder setInteger:flags.nonumber forKey:@"nonumber"];
    [aCoder setInteger:pos forKey:@"pos"];
}

@end
