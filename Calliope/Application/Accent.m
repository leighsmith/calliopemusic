/* $Id$ */

/* Generated by Interface Builder */

#import "Accent.h"
#import "AccentInspector.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "GNote.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "System.h"
#import "Staff.h"
#import <Foundation/NSArray.h>
#import <AppKit/NSFont.h>

#define NUMSIGNS 45

@implementation Accent : Hanger

extern unsigned char hasstem[10];

struct signdata
{
  unsigned char upsign, dnsign;
  char smaller;
  char defpos;	/* 0=above, 1=below, 2=head, 3=tail */
  char place; 	/* 0=packed on staff lines,
  			1=placed outside staff,
			2 = like 1 but packed close together
			3 = programmed (ignores stacking), 
			uses upsign/dnsign for case/subcase
			4 = programmed (left to right packing) */
  char alter;	/* type of chromatic alteration */
  char keycut;	/* keyboard shortcut */
};

struct signdata signs[NUMSIGNS + 1] =
{
  {0, 0,			0, 0, 0, 0, 0}, /* reserved to indicate null sign */
  {SF_fermup, SF_fermdn,	0, 0, 1, 0, 0},
  {SF_dot, SF_dot, 		0, 2, 0, 0, 0},
  {SF_tenuto, SF_tenuto, 	0, 2, 0, 0, 0},
  {SF_lmordent, SF_lmordent, 	0, 0, 1, 0, 0},
  {SF_mordent, SF_mordent, 	0, 0, 1, 0, 0},
  {SF_circle, SF_circle, 	0, 2, 0, 0, 0},
  {SF_veeup, SF_veedn,		0, 2, 1, 0, 0},
  {SF_wedgeup, SF_wedgedn,	0, 2, 0, 0, 0},
  {SF_angle, SF_angle, 		0, 0, 1, 0, 0},
  {SF_downbow, SF_downbow, 	0, 0, 1, 0, 0},
  {SF_upbow, SF_upbow, 		0, 0, 1, 0, 0},
  {SF_flat, SF_flat, 		1, 0, 1, 1, 64},
  {SF_natural, SF_natural, 	1, 0, 1, 3, 33},
  {SF_sharp, SF_sharp, 		1, 0, 1, 2, 35},
  {SF_veedotup, SF_veedotdn, 	0, 2, 1, 0, 0},
  {SF_turn, SF_turn,		0, 0, 1, 0, 0},
  {SF_segno1, SF_segno1,	0, 0, 1, 0, 0},
  {SF_pedal, SF_pedal,		0, 1, 1, 0, 0},
  {SF_aster, SF_aster,		0, 1, 1, 0, 0},
  {48, 48, 2, 0, 2, 0, 48}, /* keyboard finger numbers */
  {49, 49, 2, 0, 2, 0, 49},
  {50, 50, 2, 0, 2, 0, 50},
  {51, 51, 2, 0, 2, 0, 51},
  {52, 52, 2, 0, 2, 0, 52},
  {53, 53, 2, 0, 2, 0, 53},
  {37, 37, 0, 0, 1, 0, 0},  /* segno % */
  {96, 96, 0, 0, 1, 0, 0}, /* tr */
  {44, 44, 1, 0, 1, 0, 44}, /* , */
  {186, 186, 1, 0, 1, 4, 0}, /* dfl */
  {220, 220, 1, 0, 1, 5, 0}, /* dsh */
  {165, 165, 1, 1, 1, 6, 56}, /* ottava (tag 31)*/
  {1, 1, 0, 3, 3, 0, 0}, /* trem 1 */
  {1, 2, 0, 3, 3, 0, 0}, /* trem 2 */
  {1, 3, 0, 3, 3, 0, 0}, /* trem 3 */
  {1, 4, 0, 3, 3, 0, 0}, /* trem 4 */
  {184, 184, 0, 2, 4, 0, 0}, /* ppp */
  {185, 185, 0, 2, 4, 0, 0}, /* pp */
  {112, 112, 0, 2, 4, 0, 0}, /* p */
  {80, 80, 0, 2, 4, 0, 0}, /* mp */
  {70, 70, 0, 2, 4, 0, 0}, /* mf */
  {102, 102, 0, 2, 4, 0, 0}, /* f */
  {196, 196, 0, 2, 4, 0, 0}, /* ff */
  {236, 236, 0, 2, 4, 0, 0}, /* fff */
  {115, 115, 0, 2, 4, 0, 0}, /* s */
  {122, 122, 0, 2, 4, 0, 0}, /* z */
};


/* updir[isNote && stemUp][accent pos] is whether accent is up or down */

static int updir[2][4] =
{
  {1, 0, 1, 0},
  {1, 0, 0, 1}
};


static float getTop(StaffObj *p)
{
  int j;
  j = [p posAboveBelow: 1];
  if (!(j & 1)) --j;
  return [[p staff] yOfPos: j];
}


static float getBottom(StaffObj *p)
{
  int j;
  j = [p posAboveBelow: 0];
  if (!(j & 1)) ++j;
  return [[p staff] yOfPos: j];
}

static Accent *proto;

+ (void)initialize
{
  int i;
  if (self == [Accent class])
  {
      (void)[Accent setVersion: 3];		/* class version, see read: */
    proto = [Accent alloc];
    proto->gFlags.subtype = 2;
    i = ACCSIGNS;
    while (i--) proto->sign[i] = 0;
    proto->sign[0] = 1;
    proto->accstick = 0;
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [AccentInspector class];
}


- init
{
  int i = ACCSIGNS;
  [super init];
  gFlags.type = ACCENT;
  while (i--) sign[i] = 0;
  xoff = yoff = 0.0;
  accstick = 0;
  return self;
}


- (Accent *) newFrom
{
  Accent *p = [[Accent alloc] init];
  int i = ACCSIGNS;
  p->bounds = bounds;
  p->gFlags = gFlags;
  while (i--) p->sign[i] = sign[i];
  p->xoff = xoff;
  p->yoff = yoff;
  p->accstick = accstick;
  return p;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- (int) myLevel
{
  return -1;
}


- (BOOL) getXY: (float *) x : (float *) y
{
  GNote *p = client;
  *x = xoff + p->x;
  *y = yoff + p->y;
  return YES;
}


- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
  StaffObj *p;
  Accent *t;
  BOOL r = NO;
  int k = [sl count];
  while (k--)
  {
    p = [sl objectAtIndex:k];
    if (ISASTAFFOBJ(p))
    {
      t = [self newFrom];
      t->client = p;
      [p linkhanger: t];
      [t recalc];
      [v selectObj: t];
      r = YES;
    }
  }
  return r;
}  


/* caller checks whether p is a staffobject */

- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  int k;
  gFlags.subtype = proto->gFlags.subtype;
  k = ACCSIGNS;
  while (k--) sign[k] = proto->sign[k];
  accstick = proto->accstick;
  client = g;
  gFlags.size = g->gFlags.size;
  [client linkhanger: self];
  return self;
}


- (int) getDefault: (int) i
{
  return signs[(int) sign[i]].defpos;
}


/* return a chromatic alteration code */


- (int) hasAccidental
{
  int i, k = ACCSIGNS;
  while (k--)
  {
    i = signs[(int) sign[k]].alter;
    if (i != 6  && i != 0) return i;
  }
  return 0;
}

- (int) hasOttava
{
  int top, i, k = ACCSIGNS;
  StaffObj *p = client;
  top = updir[(TYPEOF(p) == NOTE && ((TimedObj *)p)->time.stemup)][gFlags.subtype];
  while (k--)
  {
    i = signs[(int) sign[k]].alter;
      if (i == 6) return (top ? NUMACCS + 1 : NUMACCS + 0);
  }
  return 0;
}


- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  GNote *q = client;
  xoff = dx + p.x - q->x;
  yoff = dy + p.y - q->y;
  [self recalc];
  return YES;
}

int howsmall[3][3] = /* howsmall[amount][currsize] */
{
  {0, 1, 2},
  {1, 2, 2},
  {2, 2, 2}
};


- (BOOL) performKey: (int) c
{
  int i, s;
  BOOL r = NO;
  for (i = 1; i <= NUMSIGNS; i++)
  {
    s = signs[i].keycut;
    if (s > 0 && s == c)
    {
      r = YES;
      sign[0] = i;
      gFlags.subtype = [self getDefault: 0];
      break;
    }
  }
  if (r)
  {
    [self reShape];
    return YES;
  }
  else return [super performKey: c];
}


/* tyoff[hasstem][nslashes] = number of ss's down stem to start slashes */

float tyoff[2][5] =
{
 {0, 3, 3, 3,   3},
 {0, 4, 3, 2.5, 2}
};

- drawSpecial: (int) j : (int) m
{
  TimedObj *p = client;
  int k, sz, sd, pb;
  float x0, y0, x1, y1, th, jmp, dx, bh, ss;
  switch(signs[j].upsign)
  {
    case 1: /* tremolos */
      if (TYPEOF(p) != NOTE) return self;
      k = signs[j].dnsign;
      sz = p->gFlags.size;
      ss = getSpacing([p staff]);
      bh = 0.5 * nature[sz];
      pb = p->time.body;
      dx = halfwidth[sz][0][pb];
      sd = p->time.stemup ? -1 : 1;
      th = bh * sd;
      jmp = 2 * bh * sd;
      x0 = p->x - dx;
      if (hasstem[pb]) x0 += [p stemXoff: 0];
      x1 = x0 + 2.0 * dx;
      if (sd < 0)
      {
        y0 = p->y - (ss * tyoff[hasstem[pb]][k]);
        y1 = y0 - (2 * bh);
      }
      else
      {
        y1 = p->y + (ss * tyoff[hasstem[pb]][k]);
        y0 = y1 + (2 * bh);
      }
      while (k--)
      {
        cslant(x0, y0, x1, y1, th, m);
	y0 += jmp;
	y1 += jmp;
      }
      break;
  }
  return self;
}


- drawDynamics: (float) x : (float) y : (int) m
{
  int ch, i, j;
  NSFont *f = musicFont[1][gFlags.size];
  float dx = 0.5 * nature[gFlags.size];
  for (i = 0; i < ACCSIGNS; i++)
  {
    j = sign[i];
    if (signs[j].place == 4)
    {
      ch = signs[j].upsign;
      drawCharacterInFont(x, y, ch, f, m);
      x += charFGW(f, ch) - dx;
    }
  }
  return self;
}


- drawMode: (int) m
{
  float x, y, sy, ny;
  unsigned char ch;
  int i, j, sz, dir, top;
  NSFont *f;
  StaffObj *p = client;
  Staff *staff = [p staff];
  BOOL fr;
  
  if (!staff) {
      NSLog(@"unattached accent character?\n");
      return self;
  }
  if (TYPEOF(staff) != STAFF) return self;
  fr = (xoff != 0.0 || yoff != 0.0);
  x = p->x + xoff;
  dir = 2 * getSpacing(staff);
  top = updir[(TYPEOF(p) == NOTE && ((TimedObj *)p)->time.stemup)][gFlags.subtype];
  if (top)
  {
    dir = -dir;
    sy = [staff yOfTop];
    ny = getTop(p);
    if (sy > ny) sy = ny;
  }
  else
  {
    sy = [staff yOfBottom];
    ny = getBottom(p);
    if (sy < ny) sy = ny;
  }
  ny -= p->y;
  sy += dir;
  sz = gFlags.size;
  y = p->y + ny + dir + yoff;
  for (i = 0; i < ACCSIGNS; i++)
  {
    j = sign[i];
    if (j <= 0) continue;
    if (signs[j].place == 3)
    {
      [self drawSpecial: j : m];
      continue;
    }
    if (signs[j].place == 4) return [self drawDynamics: x : y : m];
    f = musicFont[1][howsmall[(int)(signs[j].smaller)][sz]];
    ch = top ? signs[j].upsign : signs[j].dnsign;
    if (signs[j].place)
    {
      if (top)
      {
        if (!fr && y > sy) y = sy;
	y += charFLLY(f, ch);
      }
      else
      {
        if (!fr && y < sy) y = sy;
	y += charFURY(f, ch);
      }
      centxChar(x, y, ch, f, m);
      if (top) y -= charFGH(f, ch); else y += charFGH(f, ch);
    }
    else
    {
      centChar(x, y, ch, f, m);
    }
    if (1)
    {
      if (top)
      {
        if (y > sy) y += dir; else y += 0.25 * dir;
      }
      else
      {
        if (y < sy) y += dir; else y += 0.25 * dir;
      }
    }
    else y += 0.25 * dir;
  }
  return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v = [aDecoder versionForClassName:@"Accent"];
  [super initWithCoder:aDecoder];
  accstick = 0;
  if (v <= 1) [aDecoder decodeArrayOfObjCType:"c" count:ACCSIGNS at:sign];
  else if (v == 2)
  {
    [aDecoder decodeArrayOfObjCType:"c" count:ACCSIGNS at:sign];
    [aDecoder decodeValuesOfObjCTypes:"ff", &xoff, &yoff];
  }
  else if (v == 3)
    {
      [aDecoder decodeArrayOfObjCType:"c" count:ACCSIGNS at:sign];
      [aDecoder decodeValuesOfObjCTypes:"ffc", &xoff, &yoff, &accstick];
    }

  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeArrayOfObjCType:"c" count:ACCSIGNS at:sign];
  [aCoder encodeValuesOfObjCTypes:"ffc", &xoff, &yoff, &accstick];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];

    [aCoder setInteger:ACCSIGNS forKey:@"ACCSIGNS"];
    for (i = 0; i < ACCSIGNS; i++) [aCoder setInteger:sign[i] forKey:[NSString stringWithFormat:@"sign%d",i]];

    [aCoder setFloat:xoff forKey:@"xoff"];
    [aCoder setFloat:yoff forKey:@"yoff"];
    [aCoder setInteger:accstick forKey:@"accstick"];
}



@end
