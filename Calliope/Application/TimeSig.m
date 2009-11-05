/* $Id$ */
#import "TimeSig.h"
#import "TimeInspector.h"
#import "Staff.h"
#import "StaffObj.h"
#import "System.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "DrawingFunctions.h"
#import "muxlow.h"


@implementation TimeSig

static TimeSig *proto;


+ (void)initialize
{
  if (self == [TimeSig class])
  {
      [TimeSig setVersion: 3];		/* class version, see read: */
    proto = [[TimeSig alloc] init];
    proto->gFlags.subtype = 5;
    strcpy(proto->numer, "4");
    strcpy(proto->denom, "4");
    strcpy(proto->reduc, "2");
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [TimeInspector class];
}


- init
{
  [super init];
  gFlags.type = TIMESIG;
  dot = 0;
  line = 0;
  numer[0] = '\0';
  denom[0] = '\0';
  fnum = 1.0;
  fden = 1.0;
  staffPosition = 4;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- (int) defaultPos
{
  return (TYPEOF(mystaff) == STAFF) ? getLines(mystaff) - 1 : 4;
}


- (BOOL) getXY: (float *) fx : (float *) fy
{
  *fx = x;
  *fy = [self yOfPos: staffPosition];
  return YES;
}


- proto: v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  [super proto: v : pt : sp : sys : g : i];
  gFlags.subtype = proto->gFlags.subtype;
  strcpy(numer, proto->numer);
  strcpy(denom, proto->denom);
  fnum = proto->fnum;
  fden = proto->fden;
  staffPosition = [self defaultPos];
  return self;
}


/* return quotient for polymetric evaluation */

- (float) myQuotient
{
  float m, n = 1.0, r;
  switch(gFlags.subtype)
  {
    case 4:
      n = atoi(numer);
      if (n > 0) n *= 0.5;
      break;
    case 5:
      n = atoi(numer);
      if (n <= 0) break;
      m = atoi(denom);
      if (m <= 0) break;
      n /= m;
      break;
    case 6:
      n = atoi(numer);
      if (n <= 0) break;
      m = atoi(denom);
      if (m <= 0) break;
      r = atoi(reduc);
      if (r <= 0) break;
      n = n * r / m;
      break;
  }
  return n;
}


/*
  Return a time factor to be used with note evaluation.
*/

- (float) myFactor: (int) t
{
  if (fnum <= 0) return 1.0;
  if (fden <= 0) return 1.0;
  return fnum / fden;
}


/* return number of ticks in a legal bar under my influence */

static int denom[8] = {128, 64, 32, 16,  8,  4,  2,   1};
static int ticks[8] = {  1,  2,  4,  8, 16, 32, 64, 128};

#define MINIMTICK 64

static int ticksfordenom(int x)
{
  int i = 8;
  while (i--) if (x == denom[i]) return ticks[i];
  return MINIMTICK / 2;
}


- (int) myBarLength
{
  int n, m, r;
  r = MINIMTICK * 2;
  n = atoi(numer);
  if (n <= 0) return r;
  m = atoi(denom);
  r = n * ticksfordenom(m);
  if (gFlags.subtype == 6)
  {
    n = atoi(reduc);
    if (n > 0) r *= n;
  }
  return r;
}


- (int) myBeats
{
  int n, r, t;
  r = 4;
  n = atoi(numer);
  if (n <= 0) return r;
  if (gFlags.subtype == 6)
  {
    t = atoi(reduc);
    if (t <= 0) return n;
    n *= t;
  }
  return n;
}


- (float) beatsFromTicks: (float) t
{
  return ([self myBeats] * t) / [self myBarLength];
}


static short perfdiv[4] = {6, 3, 9, 3};
static short imperfdiv[4] = {4, 2, 6, 4};

- (BOOL) isConsistent: (float) t
{
  int i, d;
  switch(gFlags.subtype)
  {
    case 0:
      i = t;
      d = perfdiv[(dot << 1) + line];
      return ((i % d) == 0);
      break;
    case 1:
    case 2:
    case 3:
      i = t;
      d = imperfdiv[(dot << 1) + line];
      return ((i % d) == 0);
      break;
    case 4:
      i = t;
      d = atoi(numer);
      if (d <= 0) d = 3;
      return ((i % d) == 0);
      break;
    case 5:
    case 6:
      t -= [self myBarLength];
      if (t < 0) t = -t;
      return (t < 1);
      break;
    case 7:
      return YES;
      break;
  }
  return NO;
}


/* Caller does the setHangers that matches the markHangers here */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : (System *) sys : (int) alt
{
  int mp;
  float nx = dx + pt.x;
  float ny = dy + pt.y;
  BOOL m = NO, inv;
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
	if (mp != staffPosition)
	{
          staffPosition = mp;
          y = [mystaff yOfPos: mp];
	}
      }
      else if (inv)
      {
        staffPosition = [self defaultPos];
	y = [mystaff yOfPos: staffPosition];
      }
    }
    [self recalc];
    [self markHangers];
    [self setVerses];
  }
  return m;
}

static float fontsize[3] = { 16, 12, 8};

- drawMode: (int) m
{
  float x1, x2, w;
  float cy = (TYPEOF(mystaff) == STAFF) ? [mystaff yOfPos: staffPosition] : y;
  BOOL punct = 1;
  static char linedy[3] = {12, 9, 6};
  int sz = gFlags.size;
  NSFont *f = musicFont[1][sz], *ft;
  switch(gFlags.subtype)
  {
    case 0:
      ccircle(x, cy, getSpacing(mystaff) * 2, 0, 360, linethicks[sz], m);
      break;
    case 1:
      ccircle(x, cy, getSpacing(mystaff) * 2, 50, 310, linethicks[sz], m);
      break;
    case 2:
      centChar(x, cy, SF_comm, f, m);
      break;
    case 3:
      centChar(x, cy, CH_rcomm, musicFont[0][sz], m);
      break;
    case 4:
      DrawCenteredText(x, cy, numer, f, m);
      punct = 0;
      break;
    case 5:
      DrawCenteredText(x, cy + charFLLY(f, numer[0]) - 1, numer, f, m);
      DrawCenteredText(x, cy + charFURY(f, numer[0]) + 2, denom, f, m);
      punct = 0;
      break;
    case 6:
      DrawCenteredText(x, cy + charFLLY(f, numer[0]) - 1, numer, f, m);
      DrawCenteredText(x, cy + charFURY(f, numer[0]) + 2, denom, f, m);
        ft = [NSFont fontWithName: @"Symbol" size: fontsize[sz] / [[DrawApp currentDocument] staffScale]];
      x1 = [f widthOfString:[NSString stringWithUTF8String:numer]];
      x2 = [f widthOfString:[NSString stringWithUTF8String:denom]];
      w = (x1 > x2) ? x1 : x2;
      x1 = x + 0.5 * w + 2;
      DrawCharacterInFont(x1, cy + 0.5 * charFGH(ft, 0264), 0264, ft, m);
      x2 = x1 + charFGW(ft, 0264) + 2;
      CAcString(x2, cy, reduc, f, m);
      punct = 0;
      break;
    case 7:
      x1 = getSpacing(mystaff) * 2;
      w = x1 / 1.618;
      cline(x - w, cy - x1, x + w, cy + x1, linethicks[sz], m);
      cline(x + w, cy - x1, x - w, cy + x1, linethicks[sz], m);
      punct = 0;
  }
  if (punct)
  {
    if (dot) centChar(x, cy, SF_dot, f, m);
    if (line) cline(x, cy - linedy[sz], x, cy + linedy[sz], linethicks[sz], m);
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v = [aDecoder versionForClassName:@"TimeSig"];
  [super initWithCoder:aDecoder];
  fnum = 1.0;
  fden = 1.0;
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"cc", &dot, &line];
    [aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:numer];
    [aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:denom];
    staffPosition = 4;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"cc", &dot, &line];
    [aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:numer];
    [aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:denom];
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccff", &dot, &line, &fnum, &fden];
    [aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:numer];
    [aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:denom];
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccff", &dot, &line, &fnum, &fden];
    [aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:numer];
    [aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:denom];
    [aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:reduc];
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeValuesOfObjCTypes:"ccff", &dot, &line, &fnum, &fden];
  [aCoder encodeArrayOfObjCType:"c" count:FIELDSIZE at:numer];
  [aCoder encodeArrayOfObjCType:"c" count:FIELDSIZE at:denom];
  [aCoder encodeArrayOfObjCType:"c" count:FIELDSIZE at:reduc];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:dot forKey:@"dot"];
    [aCoder setInteger:line forKey:@"line"];
    [aCoder setFloat:fnum forKey:@"fnum"];
    [aCoder setFloat:fden forKey:@"fden"];
    for (i = 0; i < FIELDSIZE ; i++) [aCoder setInteger:numer[i] forKey:[NSString stringWithFormat:@"numer%d",i]];
    for (i = 0; i < FIELDSIZE ; i++) [aCoder setInteger:denom[i] forKey:[NSString stringWithFormat:@"denom%d",i]];
    for (i = 0; i < FIELDSIZE ; i++) [aCoder setInteger:reduc[i] forKey:[NSString stringWithFormat:@"reduc%d",i]];
}

@end
