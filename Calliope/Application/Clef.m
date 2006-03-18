/* $Id$ */

/* Generated by Interface Builder */

#import "DrawApp.h"
#import "Clef.h"
#import "ClefInspector.h"
#import "GraphicView.h"
#import "Staff.h"
#import "StaffObj.h"
#import "System.h"
#import "mux.h"
#import "muxlow.h"

@implementation Clef


/* MAXECLEFS different of each keycentre type of clef are allowed */
/* column order: modern, chant, old A, old B, old C */

char clefuid[NUMTCLEFS][MAXECLEFS] =
{
  { 0,  2,  1, 10, -1, -1, -1, -1},  /* C clefs */
  { 3,  5,  4,  8, -1, -1, -1, -1},  /* F clefs */
  { 6, -1,  7,  9, -1, -1, -1, -1},  /* G clefs */
  {11, -1, -1, -1, -1, -1, -1, -1}   /* P clefs */
};

char clefdefaultpos[NUMUCLEFS] = {4, 4, 0, 2, 2, 2, 6, 6, 2, 6, 4, 0};

unsigned char clefcpos[NUMUCLEFS] = {4, 4, 0, 5, 5, 5, 3, 3, 5, 3, 4, 0};


unsigned char clefbodies[NUMUCLEFS] =
{
  SF_cclef, CH_occlef, CH_doh, SF_bass, CH_obass, CH_fah, SF_treble, CH_otreble,
  CH_ofclef, CH_ogclef, CH_occlef2, 47
};

unsigned char cleffont[NUMUCLEFS] = { 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1};


/* graphic offset to place clef[size][uid] at pos 0 */

char cleforigins[3][NUMUCLEFS] =
{
  { 16, 16, 24, 24, 24, 24, 8, 8, 24, 8, 16, 8},
  { 12, 12, 18, 18, 18, 18, 6, 6, 18, 6, 12, 6},
  {  8,  8, 12, 12, 12, 12, 4, 4, 12, 4,  8, 4}
};


static char clefmidc[NUMUCLEFS] =
{
  4, 4, 0, -2, -2, -2, 10, 10, -2, 10, 4, 0
};


static char clefottava[] = {0, -7, 7};

static Clef *proto;


+ (void)initialize
{
  if (self == [Clef class])
  {
      (void)[Clef setVersion: 1];
    proto = [self alloc];
    proto->gFlags.subtype = 0;
    proto->keycentre = 2;
    proto->p = clefdefaultpos[(int)clefuid[2][0]];
    proto->ottava = 0;
  }
  return;
}


+ myPrototype
{
  return proto;
}


+  myInspector
{
  return [ClefInspector class];
}


- init
{
  [super init];
  gFlags.type = CLEF;
  gFlags.subtype = 0;
  keycentre = 2;
  p = [self defaultPos];
  ottava = 0;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- (int) defaultPos
{
  return clefdefaultpos[(int)clefuid[(int)keycentre][(int)gFlags.subtype]];
}


- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
{
  [super proto: v : pt : sp : sys : g : i];
  gFlags.subtype = proto->gFlags.subtype;
  keycentre = proto->keycentre;
  ottava = proto->ottava;
  p = [self defaultPos];
  return self;
}


- newFrom
{
  Clef *q = [[Clef alloc] init];
  q->gFlags.subtype = gFlags.subtype;
  q->gFlags.size = gFlags.size;
  q->x = x;
  q->keycentre = keycentre;
  q->ottava = ottava;
  q->p = p;
  return q;
}


- (BOOL) getXY: (float *) fx : (float *) fy
{
  *fx = x;
  *fy = [self yOfPos: p];
  return YES;
}


/* return the pos of middle-C for self */

- (int) middleC
{
  return(clefmidc[(int)clefuid[(int)keycentre][(int)gFlags.subtype]] + clefottava[(int)ottava] + (p - [self defaultPos]));
}

- (BOOL) performKey: (int) c
{
  int i;
  BOOL r = NO;
  if (isdigitchar(c))
  {
    i = c - '0';
    p = (getLines(mystaff) - i) << 1;
    r = YES;
  }
  i = [@"CFGP" rangeOfString:[NSString stringWithFormat:@"%c", c]].location;
  if (i != NSNotFound)
  {
    gFlags.subtype = 0;
    keycentre = i;
    p = [self defaultPos];
    r = YES;
  }
  if (r)
  {
    [self reShape];
    return YES;
  }
  else return [super performKey: c];
}


/* Caller does the setHangers that matches the markHangers here */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : (System *) sys : (int) alt
{
  int mp;
  float nx = dx + pt.x;
  float ny = dy + pt.y;
  BOOL m = NO, am = NO, inv;
  if (ABS(ny - y) > 1 || ABS(nx - x) > 1)
  {
    m = YES;
    x = nx;
    y = ny;
    inv = [sys relinknote: self];
    if (TYPEOF(mystaff) == STAFF)
    {
      if (alt)
      {
        mp = [mystaff findPos: y];
	if ((p & 1) == (mp & 1))  /* move only by increments of 2 ss */
	{
	  am = (mp != p);
          p = mp;
          y = [mystaff yOfPos: mp];
	}
      }
      else if (inv)
      {
        p = [self defaultPos];
	y = [mystaff yOfPos: p];
      }
    }
    [self recalc];
    [self markHangers];
    [self setVerses];
  }
  if (am) [NSApp inspectMe: self loadInspector: NO];
  return m;
}


- drawMode: (int) m
{
  float cx, cy;
  int cid, sz;
  NSFont *f, *f8;
  unsigned char cs;
  cid = clefuid[(int)keycentre][(int)gFlags.subtype];
  cs = clefbodies[cid];
  sz = gFlags.size;
  f = musicFont[cleffont[cid]][sz];
  if (TYPEOF(mystaff) == SYSTEM) cy =  y;
  else cy = cleforigins[sz][cid] + [mystaff yOfPos: p];
  drawCharacterInFont(x, cy, cs, f, m);
  if (ottava)
  {
    cx = x + charhalfFGW(f, cs);
    f8 = musicFont[1][(int)smallersz[sz]];
    if (ottava == -1) cy += charFLLY(f8, SF_ital8) - charFURY(f, cs) - 0.5 * nature[sz];
    else cy += 0.5 * nature[sz] - charFLLY(f, cs) + charFURY(f8, SF_ital8);
    centxChar(cx, cy, SF_ital8, f8, m);
  }
  return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  char b1;
  int v = [aDecoder versionForClassName:@"Clef"];
  [super initWithCoder:aDecoder];
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccc", &keycentre, &b1, &ottava];
      p = b1 + clefdefaultpos[(int)clefuid[(int)keycentre][(int)gFlags.subtype]];
  }
  else if (v == 1) [aDecoder decodeValuesOfObjCTypes:"cc", &keycentre, &ottava];
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeValuesOfObjCTypes:"cc", &keycentre, &ottava];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:keycentre forKey:@"keycentre"];
    [aCoder setInteger:ottava forKey:@"ottava"];
}
@end
