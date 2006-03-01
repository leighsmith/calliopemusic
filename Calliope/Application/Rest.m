/* $Id$ */
#import "mux.h"
#import "muxlow.h"
#import "Rest.h"
#import "RestInspector.h"
#import "Staff.h"
#import "System.h"
#import <Foundation/NSArray.h>

#define MINIMTICK 64

extern int getLines(Staff *s);

short rests[2][10] =
{
  {SF_r128, SF_r64, SF_r32, SF_r16, SF_r8, SF_r4, SF_r2, SF_r1, SF_r0, SF_r0},
  {CH_oerest, CH_oerest, CH_oerest, CH_oerest, CH_oerest, CH_oqrest, CH_ohrest, CH_ohrest, CH_obrest, CH_obrest}
};

short restoffs[7][10] =
{
  {9, 7, 5, 5, 3, 4, 4, 4, 4, 4},
  {4, 4, 4, 4, 4, 4, 4, 3, 3, 3},
  {4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
  {4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
  {4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
  {4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
  {4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
};

short prestoffs[10] =
{
  -7, -8, -6, -6, -4, -4, -4, -2, -2, -2
};

short dotoffs[2][10] = 
{
  {-8, -6, -4,  -2, 0, -1, -1, -1, -1, -1},
  {-1, -1, -1, -1, -1, -1, -1,  0,  0,  0}
};

BOOL hasledger[10] =
{
 0, 0, 0, 0, 0, 0, 1, 1, 0, 0
};

short ledgeroff[10] =
{
 0, 0, 0, 0, 0, 0, 0, -2, -4, -4
};

static char timesw[7] = {1, 1, 0, 0, 0, 1, 1};


@implementation Rest

static Rest *proto;

+ (void)initialize
{
  if (self == [Rest class])
  {
    proto = [[Rest alloc] init];
    [Rest setVersion: 4];		/* class version, see read: */
  }
  return;
}


+ myInspector
{
  return [RestInspector class];
}


+ myPrototype
{
  return proto;
}


+ newBarsRest: (int) n
{
  Rest *r = [[Rest alloc] init];
  r->style = 2;
  r->numbars = n;
  r->p = 4;
  return r;
}


- init
{
  [super init];
  gFlags.type = REST;
  numbars = 0;
  style = 0;
  barticks = MINIMTICK * 2;
  gFlags.locked = 0;
  time.tight = 0;
  voice = 0;
  isGraced = 0;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}

- (BOOL) isBarsRest
{
  return !(timesw[(int)style]);
}

- (int) barCount
{
    if (timesw[(int)style]) return 0;
  return (numbars > 0) ? numbars - 1 : 0;
}


/*
  override for effect of whole bar rests.  These return 1 bar's worth of tick, but
  leave it to the caller to multiply by numbers (only perform needs to do this)
*/

- (float) noteEval: (BOOL) f
{
  float a;
    if (timesw[(int)style]) return [super noteEval: f];
  a = barticks;
  if (time.factor != 0) a *= time.factor;
  return a;
}


- (float) myDuration
{
//NSLog(@"style = %d duration = %f numbars = %d\n", style, duration, numbars);
    return (timesw[(int)style] ? duration : duration * numbars);
}


- (int) defaultPos
{
  int i;
    i = restoffs[(int)style][time.body];
  if (getLines(mystaff) == 1)  i = (style ? 0 : i + prestoffs[time.body]);
  return i;
}


- (BOOL) hitBeamAt: (float *) px : (float *) py
{
  *px = x;
  *py = y + time.stemlen;
  return YES;
}

- resetStemlen
{
  time.stemlen = getstemlen(QUAVER, gFlags.size, 0, time.stemup, 4, getSpacing(mystaff));
  return self;
}


/* sets stem to the default in the specified direction */

- defaultStem: (BOOL) up
{
  if (up != time.stemup) time.stemup = up;
  [self resetStemlen];
  [self recalc];
  return self;
}


- (float) wantsStemY: (int) a
{
  return [super yMean];
}


- (float) myStemBase
{
  return [super yMean];
}


/* initialise the prototype rest */

- proto: v : (NSPoint) pt : (Staff *) sp : sys : (Graphic *) g : (int) i
{
  [super proto: v : pt : sp : sys : g : i];
  style = proto->style;
  gFlags.locked = proto->gFlags.locked;
  gFlags.size = sp->gFlags.size;
  time.body = i;
  time.tight = proto->time.tight;
  isGraced = proto->isGraced;
  voice = proto->voice;
  p = [self defaultPos];
  [self resetStemlen];
  return self;
}


- (BOOL) getXY: (float *) fx : (float *) fy
{
    if (style <= 1) *fx = x - 0.5 * charFGW(musicFont[!style][gFlags.size], rests[(int)style][time.body]);
  else *fx = x;
  *fy = [self yOfPos: p];
  return YES;
}


- (BOOL) reCache: (float) sy : (int) ss
{
  float t = sy + ss * p;
  BOOL mod = NO;
  if (t != y)
  {
    mod = YES;
    y = t;
  }
  return mod;
}



/* Caller does the setHangers that matches the markHangers here */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : (System *) sys : (int) alt
{
  int mp;
  float oy;
  float nx = dx + pt.x;
  float ny = dy + pt.y;
  BOOL m = NO, inv;
  if (ABS(ny - y) > 1 || ABS(nx - x) > 1)
  {
    m = YES;
    x = nx;
    oy = y;
    y = ny;
    inv = [sys relinknote: self];
    if (inv) y = oy;
    if (TYPEOF(mystaff) == STAFF)
    {
      if (alt)
      {
        mp = [mystaff findPos: y];
	if ((mp & 1) != ([self defaultPos] & 1))
	{
	  if (mp < p) --mp; else ++mp;
	}
        p = mp;
        y = [mystaff yOfPos: mp];
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
  return m;
}


/* override to provide correct pos for new time and for default pos */

- (BOOL) performKey: (int) c
{
  BOOL r = NO;
    if (timesw[(int)style])
  {
    if (isdigitchar(c))
    {
      time.body = c - '0';
      p = [self defaultPos];
      r = YES;
    }
    else if (c == 'd')
    {
      p = [self defaultPos];
      r = YES;
    }
  }
  if (r)
  {
    [self reShape];
    return YES;
  }
  else return [super performKey: c];
}


extern float ledgedxs[3];
extern float staffthick[3][3];

- numberMult: (int) sz : (int) ss: (int) m
{
  float sy, y1, y2, cx, wid;
  int numy;
  char num[6];
  sy = [self yOfPos: 0];
  cx = x - (4 * ss);
  y1 = GETYSP(sy, ss, p);
  wid = (8 * ss);
  crect(x, y1 - (ss - 1), wid, (2 * ss) - 1, m);
  y1 = GETYSP(sy, ss, p - 2);
  y2 = GETYSP(sy, ss, p + 2);
  cline(x, y1, x, y2, linethicks[sz], m);
  cline(x + wid, y1, x + wid, y2, linethicks[sz], m);
  sprintf(num, "%d", numbars);
  numy = (style == 3) ? 7 : -7;
  centString(x + (4 * ss), GETYSP(sy, ss, p + numy), num, musicFont[1][sz], m);
  return self;
}


- drawMode: (int) m
{
  int sz, ss, tp;
  float dx, y1, lx, ly, th;
  NSFont *f;
  Staff *sp;
  unsigned char c;
  sz = gFlags.size;
  ss = getSpacing(mystaff);
  switch(style)
  {
    case 6:
      f = musicFont[1][sz];
      c = 212;
      y1 = [self yOfPos: p];
      dx = 0.5 * charFGW(f, c);
      drawCharacterInFont(x - dx, y1, c, f, m);
      break;
    case 5:
      f = musicFont[1][sz];
      c = SF_r1;
      y1 = [self yOfPos: p];
      dx = 0.5 * charFGW(f, c);
      drawCharacterInFont(x - dx, y1, c, f, m);
      break;
    case 0:
    case 1:
    f = musicFont[!style][sz];  /* might need to depend on body etc */
        c = rests[(int)style][time.body];
    y1 = [self yOfPos: p];
    dx = 0.5 * charFGW(f, c);
    drawCharacterInFont(x - dx, y1, c, f, m);
    if (hasledger[time.body] && style == 0 && TYPEOF(mystaff) == STAFF)
    {
      tp = p + ledgeroff[time.body];
      if (tp < 0 || tp > 9)
      {
        lx = ledgedxs[sz];
	ly = [self yOfPos: tp];
	sp = mystaff;
	th = staffthick[sp->flags.subtype][sp->gFlags.size];
        cline(x - dx - lx, ly, x + dx + lx, ly, th, m);
      }
    }
    if (time.dot)
    {
        tp = p + dotoffs[(int)style][time.body];
      if ((tp & 1) == 0) --tp;
      ly = [self yOfPos: tp];
      th = (time.dot == 3) ? [self getSpacing] * 2 : 0;
      restdot(sz, charFURX(f, c), x - dx, ly, th, time.dot, style, m);
    }
      break;
    case 2:
    case 3:
      [self numberMult: sz : ss : m];
      break;
    case 4:
      f = musicFont[1][sz];
      ss = getSpacing(mystaff);
      y1 = [self yOfPos: p];
      ly = [self yOfPos: p + 2];
      switch(numbars)
      {
        case 1:
          c = rests[0][7];
	  drawCharacterInFont(x - 0.5 * charFGW(f, c), y1, c, f, m);
	  break;
        case 2:
          c = rests[0][8];
	  drawCharacterInFont(x - 0.5 * charFGW(f, c), y1, c, f, m);
	  break;
        case 3:
          c = rests[0][7];
	  drawCharacterInFont(x + 2 * ss, y1, c, f, m);
          c = rests[0][8];
	  drawCharacterInFont(x - 3 * ss, y1, c, f, m);
	  break;
        case 4:
          c = rests[0][8];
	  lx = x - 0.5 * charFGW(f, c);
	  drawCharacterInFont(lx, y1, c, f, m);
	  drawCharacterInFont(lx, ly, c, f, m);
	  break;
        case 5:
          c = rests[0][7];
	  drawCharacterInFont(x + 2 * ss, y1, c, f, m);
          c = rests[0][8];
	  drawCharacterInFont(x - 3 * ss, y1, c, f, m);
	  drawCharacterInFont(x - 3 * ss, ly, c, f, m);
	  break;
        case 6:
          c = rests[0][8];
	  drawCharacterInFont(x + 2 * ss, y1, c, f, m);
	  drawCharacterInFont(x - 3 * ss, y1, c, f, m);
	  drawCharacterInFont(x - 3 * ss, ly, c, f, m);
	  break;
        case 7:
          c = rests[0][7];
	  drawCharacterInFont(x + 3 * ss, y1, c, f, m);
          c = rests[0][8];
	  drawCharacterInFont(x - 0.5 * charFGW(f, c), [self yOfPos: 4], c, f, m);
	  drawCharacterInFont(x - 4 * ss, y1, c, f, m);
	  drawCharacterInFont(x - 4 * ss, ly, c, f, m);
	  break;
        case 8:
          c = rests[0][8];
	  drawCharacterInFont(x + 2 * ss, y1, c, f, m);
	  drawCharacterInFont(x + 2 * ss, ly, c, f, m);
	  drawCharacterInFont(x - 3 * ss, y1, c, f, m);
	  drawCharacterInFont(x - 3 * ss, ly, c, f, m);
	  break;
	default:
	  [self numberMult: sz : ss : m];
      }
      break;
  }
  return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v = [aDecoder versionForClassName:@"Rest"];
  [super initWithCoder:aDecoder];
  if (v < 3) 
  {
    [aDecoder decodeValuesOfObjCTypes:"s", &numbars];
    p = restoffs[gFlags.subtype & 1][time.body];
    y = [self yOfPos: p];
  }
  else if (v == 3) [aDecoder decodeValuesOfObjCTypes:"s", &numbars];
  else [aDecoder decodeValuesOfObjCTypes:"cs", &style, &numbars];
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeValuesOfObjCTypes:"cs", &style, &numbars];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:style forKey:@"style"];
    [aCoder setInteger:numbars forKey:@"numbars"];
}


@end

