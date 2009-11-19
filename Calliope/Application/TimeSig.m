/* $Id$ */
#import "TimeSig.h"
#import "TimeInspector.h"
#import "Staff.h"
#import "StaffObj.h"
#import "System.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "DrawingFunctions.h"
#import "muxlow.h"


@implementation TimeSig

static TimeSig *proto;


+ (void) initialize
{
  if (self == [TimeSig class]) {
      [TimeSig setVersion: 3];		/* class version, see read: */
      proto = [[TimeSig alloc] init];
      proto->gFlags.subtype = 5;
      [proto setNumeratorString: @"4"];
      [proto setDenominatorString: @"4"];
      strcpy(proto->reduc, "2");
  }
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
    self = [super init];
    if(self != nil) {
	[self setTypeOfGraphic: TIMESIG];
	dot = 0;
	line = 0;
	numeratorString = nil;
	denominatorString = nil;
	fnum = 1.0;
	fden = 1.0;
	staffPosition = 4;
    }
    return self;
}


- (void) dealloc
{
    [numeratorString release];
    numeratorString = nil;
    [denominatorString release];
    denominatorString = nil;
    [super dealloc];
}


- (int) defaultPos
{
  return ([mystaff graphicType] == STAFF) ? getLines(mystaff) - 1 : 4;
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
    numeratorString = [proto->numeratorString copy];
    denominatorString = [proto->denominatorString copy];
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
      n = numerator;
      if (n > 0) n *= 0.5;
      break;
    case 5:
      n = numerator;
      if (n <= 0) break;
      m = denominator;
      if (m <= 0) break;
      n /= m;
      break;
    case 6:
      n = numerator;
      if (n <= 0) break;
      m = denominator;
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
    if (fnum <= 0) 
	return 1.0;
    if (fden <= 0) 
	return 1.0;
    return fnum / fden;
}

- (void) setDenominatorString: (NSString *) newDenominator
{
    [denominatorString release];
    denominatorString = [newDenominator copy];
    denominator = [denominatorString floatValue];
}

- (void) setDenominator: (float) newDenominator
{
    fden = newDenominator;
}

- (NSString *) denominatorString
{
    return [[denominatorString retain] autorelease];
}

- (void) setNumeratorString: (NSString *) newNumerator
{
    [numeratorString release];
    numeratorString = [newNumerator copy];
    numerator = [numeratorString floatValue];
}

- (void) setNumerator: (float) newNumerator;
{
    fnum = newNumerator;
}

- (NSString *) numeratorString
{
    return [[numeratorString retain] autorelease];
}

/* return number of ticks in a legal bar under my influence */

static int denom[8] = {128, 64, 32, 16,  8,  4,  2,   1};
static int ticks[8] = {  1,  2,  4,  8, 16, 32, 64, 128};

#define MINIMTICK 64

static int ticksForDenom(int x)
{
    int i = 8;
    
    while (i--) 
	if (x == denom[i]) 
	    return ticks[i];
    return MINIMTICK / 2;
}


- (int) myBarLength
{
    int n, m, r;
    
    r = MINIMTICK * 2;
    n = numerator;
    if (n <= 0) return r;
    m = denominator;
    r = n * ticksForDenom(m);
    if (gFlags.subtype == 6) {
	n = atoi(reduc);
	if (n > 0) 
	    r *= n;
    }
    return r;
}


- (int) myBeats
{
    int n, r, t;
    r = 4;
    n = numerator;
    if (n <= 0) return r;
    if (gFlags.subtype == 6) {
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
    
    switch(gFlags.subtype) {
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
	    d = numerator;
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
	if ([mystaff graphicType] == STAFF)
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
    float cy = ([mystaff graphicType] == STAFF) ? [mystaff yOfPos: staffPosition] : y;
    BOOL punct = YES;
    static char linedy[3] = {12, 9, 6};
    int sz = gFlags.size;
    NSFont *f = musicFont[1][sz], *ft;
    unichar firstNumeratorCharacter = [numeratorString length] ? [numeratorString characterAtIndex: 0] : 0;
    
    switch(gFlags.subtype)
    {
	case 0:
	    ccircle(x, cy, getSpacing(mystaff) * 2, 0, 360, linethicks[sz], m);
	    break;
	case 1:
	    ccircle(x, cy, getSpacing(mystaff) * 2, 50, 310, linethicks[sz], m);
	    break;
	case 2:
	    DrawCharacterCenteredInFont(x, cy, SF_comm, f, m);
	    break;
	case 3:
	    DrawCharacterCenteredInFont(x, cy, CH_rcomm, musicFont[0][sz], m);
	    break;
	case 4:
	    DrawCenteredText(x, cy, numeratorString, f, m);
	    punct = NO;
	    break;
	case 5:
	    DrawCenteredText(x, cy + charFLLY(f, firstNumeratorCharacter) - 1, numeratorString, f, m);
	    DrawCenteredText(x, cy + charFURY(f, firstNumeratorCharacter) + 2, denominatorString, f, m);
	    punct = NO;
	    break;
	case 6:
	    DrawCenteredText(x, cy + charFLLY(f, firstNumeratorCharacter) - 1, numeratorString, f, m);
	    DrawCenteredText(x, cy + charFURY(f, firstNumeratorCharacter) + 2, denominatorString, f, m);
	    ft = [NSFont fontWithName: @"Symbol" size: fontsize[sz] / [[CalliopeAppController currentDocument] staffScale]];
	    x1 = [f widthOfString: numeratorString];
	    x2 = [f widthOfString: denominatorString];
	    w = (x1 > x2) ? x1 : x2;
	    x1 = x + 0.5 * w + 2;
	    DrawCharacterInFont(x1, cy + 0.5 * charFGH(ft, 0264), 0264, ft, m);
	    x2 = x1 + charFGW(ft, 0264) + 2;
	    CAcString(x2, cy, reduc, f, m);
	    punct = NO;
	    break;
	case 7:
	    x1 = getSpacing(mystaff) * 2;
	    w = x1 / 1.618;
	    cline(x - w, cy - x1, x + w, cy + x1, linethicks[sz], m);
	    cline(x + w, cy - x1, x - w, cy + x1, linethicks[sz], m);
	    punct = NO;
    }
    if (punct) {
	if (dot) 
	    DrawCharacterCenteredInFont(x, cy, SF_dot, f, m);
	if (line)
	    cline(x, cy - linedy[sz], x, cy + linedy[sz], linethicks[sz], m);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    int v = [aDecoder versionForClassName: @"TimeSig"];
    char numer[FIELDSIZE], denom[FIELDSIZE];
    
    [super initWithCoder: aDecoder];
    fnum = 1.0;
    fden = 1.0;
    if (v == 0) {
	[aDecoder decodeValuesOfObjCTypes:"cc", &dot, &line];
	[aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:numer];
	[aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:denom];
	staffPosition = 4;
    }
    else if (v == 1) {
	[aDecoder decodeValuesOfObjCTypes:"cc", &dot, &line];
	[aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:numer];
	[aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:denom];
    }
    else if (v == 2) {
	[aDecoder decodeValuesOfObjCTypes:"ccff", &dot, &line, &fnum, &fden];
	[aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:numer];
	[aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:denom];
    }
    else if (v == 3) {
	[aDecoder decodeValuesOfObjCTypes:"ccff", &dot, &line, &fnum, &fden];
	[aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:numer];
	[aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:denom];
	[aDecoder decodeArrayOfObjCType:"c" count:FIELDSIZE at:reduc];
    }
    // TODO perhaps this should be with Symbol encoding, not UTF8?
    numeratorString = [[NSString stringWithUTF8String: numer] retain];
    denominatorString = [[NSString stringWithUTF8String: denom] retain];
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeValuesOfObjCTypes:"ccff", &dot, &line, &fnum, &fden];
    [aCoder encodeArrayOfObjCType:"c" count:FIELDSIZE at: [numeratorString UTF8String]];
    [aCoder encodeArrayOfObjCType:"c" count:FIELDSIZE at: [denominatorString UTF8String]];
    [aCoder encodeArrayOfObjCType:"c" count:FIELDSIZE at: reduc];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:dot forKey:@"dot"];
    [aCoder setInteger:line forKey:@"line"];
    [aCoder setFloat:fnum forKey:@"fnum"];
    [aCoder setFloat:fden forKey:@"fden"];
    [aCoder setObject: numeratorString forKey: @"numerator"];
    [aCoder setObject: denominatorString forKey: @"denominator"];
    for (i = 0; i < FIELDSIZE ; i++) 
	[aCoder setInteger:reduc[i] forKey:[NSString stringWithFormat:@"reduc%d",i]];
}

@end
