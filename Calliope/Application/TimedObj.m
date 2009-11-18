#import "TimedObj.h"
#import "Beam.h"
#import "Tuple.h"
#import "GNote.h"
#import "NoteHead.h"
#import <AppKit/AppKit.h>
#import <Foundation/NSArray.h>
#import "DrawingFunctions.h"
#import "muxlow.h"

@implementation TimedObj

+ (void)initialize
{
  if (self == [TimedObj class])
  {
      (void)[TimedObj setVersion: 5];	/* class version, see read: */
  }
  return;
}


- init
{
    self = [super init];
    if (self != nil) {
	time.body = 0;
	[self setDottingCode: 0];
	time.tight = 0;
	[self setStemIsUp: NO];
	[self setStemIsFixed: NO];
	time.nostem = 0;
	time.oppflag = 0;
	[self setStemLengthTo: 0.0];
	time.factor = 1.0;
    }
    return self;
}


- (void) dealloc
{
    [super dealloc];
}


- (BOOL) performKey: (int) c
{
  BOOL r = NO;
  if (isdigitchar(c))
  {
    time.body = c - '0';
    r = YES;
  }
  else if (c == '.')
  {
    [self setDottingCode: ([self dottingCode] == 1) ? 0 : 1];
    r = YES;
  }
  else if (c == '=')
  {
    time.oppflag = !(time.oppflag);
    r = YES;
  }
  if (r)
  {
    [self reShape];
    return YES;
  }
  else return [super performKey: c];
}


/* find note tick value to arbitrary nesting of unequal note groups */

- (float) noteEval: (BOOL) f
{
  float a = tickNest(hangers, tickval(time.body, [self dottingCode]));
  if (time.factor != 0) a *= time.factor;
  return a;
}


- (int) noteCode
{
    return time.body;
}

- (int) incrementNoteCodeBy: (int) i
{
  int c = time.body + i;
  if (0 <= c && c <= 8) time.body = c;
  return time.body;
}


- (float) myStemBase
{
  return y;
}


- defaultStem: (BOOL) up
{
    if (up != [self stemIsUp]) {
	[self setStemLengthTo: -[self stemLength]];
	[self setStemIsUp: ![self stemIsUp]];
    }
    return self;
}


- (void) setStemLengthTo: (float) s
{
    time.stemlen = s;
    [self setStemIsUp: (s < 0)];
}


- (float) stemXoff: (int) stype
{
  return 0.0;
}


- (float) stemXoffLeft: (int) stype
{
  return -0.5 * stemthicks[gFlags.size];
}


- (float) stemXoffRight: (int) stype
{
  return 0.5 * stemthicks[gFlags.size];
}


- (float) stemYoff: (int) stype
{
  return 0.0;
}

- (float) stemLength
{
    return time.stemlen;
}

- (BOOL) hasNoStem
{
    return time.nostem;
}

- (BOOL) stemIsUp
{
    return time.stemup == 1;
}

- (void) setStemIsUp: (BOOL) yesOrNo
{
    time.stemup = yesOrNo ? 1 : 0;
}

- (BOOL) stemIsFixed
{
    return time.stemfix == 1;
}

- (void) setStemIsFixed: (BOOL) yesOrNo
{
    time.stemfix = yesOrNo ? 1 : 0;
}

/*!
 Returns if the timed object is dotted. This might not be a bool.
 */
- (int) dottingCode
{
    return time.dot;
}

/*!
 Assigns that the timed object is dotted. TODO should be an enum.
 */
- (void) setDottingCode: (int) newDottingCode
{
    time.dot = newDottingCode;
}

/*
  Returns whether the yAboveBelow is to be used.  Do not use stemlengths
  that are involved in certain cross-staff beamings.
*/

- (BOOL) checkRemoteNotes: (int) a : (float) sy
{
  Beam *h;
  NSArray *nl;
  TimedObj *n;
  Staff *nsp;
  NoteHead *nh;
  int nk;
  int k = [hangers count];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    if ([h graphicType] == BEAM)
    {
      nl = [h clients];
      nk = [nl count];
      while (nk--)
      {
        n = [nl objectAtIndex:nk];
	nsp = n->mystaff;
	if ([nsp graphicType] != STAFF) return NO;
	if (a)
	{
	  if ([nsp yOfTop] < sy) return NO;
	}
	else
	{
	  if ([nsp yOfTop] > sy) return NO;
	}
      }
    }
  }
  if ([self graphicType] == NOTE)
  {
    GNote *q = (GNote *) self;
    k = [q numberOfNoteHeads];
    while (k--)
    {
      nh = [q noteHead: k];
      if (q != [nh myNote]) return NO;
    }
  }
  return YES;
}

/* a = 1 for above, 0 for below */

- (BOOL) validAboveBelow: (int) a
{
  if (a != [self stemIsUp]) return YES;
  if ([mystaff graphicType] != STAFF) return NO;
  return [self checkRemoteNotes: a : [mystaff yOfTop]];
}


- (BOOL) isBeamable
{
  return (time.body <= 4);
}


/* used to check if self does not have a stem written */

- (BOOL) isBeamed
{
  Beam *h;
  int k = [hangers count];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    if ([h graphicType] == BEAM) return YES;
  }
  return NO;
}

- (float) halfWidthOfNoteHead: (NoteHead *) noteHead
{
    return halfwidth[gFlags.size][[noteHead bodyType]][time.body];
}

- (float) halfWidth
{
    return halfwidth[gFlags.size][0][time.body];
}

/* overridden by beamable subclasses */

- (BOOL) hitBeamAt: (float *) px : (float *) py
{
  return NO;
}


/* used to check how to flip beam segment */

- (BOOL) tupleStarts
{
  Tuple *h;
  int hk = [hangers count];
  while (hk--)
  {
    h = [hangers objectAtIndex:hk];
    if ([h graphicType] == TUPLE && self == [h firstClient]) return YES;
  }
  return NO;
}


- (BOOL) tupleEnds
{
  Tuple *h;
  int hk = [hangers count];
  while (hk--)
  {
    h = [hangers objectAtIndex:hk];
    if ([h graphicType] == TUPLE && self == [[h clients] lastObject]) 
	return YES;
  }
  return NO;
}



/* Archiving.  the two functions are used by other clients */

void readTimeData2(NSCoder *s, struct timeinfo *t) /*sb: changed from NSArchiver after conversion */
{
  char b1, b2, b3,b4, b5;
  float sl;
  [s decodeValuesOfObjCTypes:"cccccf", &b1, &b2, &b3, &b4, &b5, &sl];
  t->body = b1;
  t->dot = b2;
  t->tight = b3;
  t->stemup = b4;
  t->stemfix = b5;
  t->stemlen = sl;
}

void readTimeData3(NSCoder *s, struct timeinfo *t) /*sb: changed from NSArchiver after conversion */
{
  char b1, b2, b3,b4, b5, b6;
  float sl;
  [s decodeValuesOfObjCTypes:"ccccccf", &b1, &b2, &b3, &b4, &b5, &b6, &sl];
  t->body = b1;
  t->dot = b2;
  t->tight = b3;
  t->stemup = b4;
  t->stemfix = b5;
  t->nostem = b6;
  t->stemlen = sl;
}

void readTimeData4(NSCoder *s, struct timeinfo *t) /*sb: changed from NSArchiver after conversion */
{
  char b1, b2, b3,b4, b5, b6;
  float sl, f;
  [s decodeValuesOfObjCTypes:"ccccccff", &b1, &b2, &b3, &b4, &b5, &b6, &sl, &f];
  t->body = b1;
  t->dot = b2;
  t->tight = b3;
  t->stemup = b4;
  t->stemfix = b5;
  t->nostem = b6;
  t->stemlen = sl;
  t->factor = f;
}

void readTimeData5(NSCoder *s, struct timeinfo *t) /*sb: changed from NSArchiver after conversion */
{
  char b1, b2, b3,b4, b5, b6, b7;
  float sl, f;
  [s decodeValuesOfObjCTypes:"cccccccff", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &sl, &f];
  t->body = b1;
  t->dot = b2;
  t->tight = b3;
  t->stemup = b4;
  t->stemfix = b5;
  t->nostem = b6;
  t->oppflag = b7;
  t->stemlen = sl;
  t->factor = f;
}

void writeTimeData5(NSCoder *s, struct timeinfo *t) /*sb: changed from NSArchiver after conversion */
{
  char b1, b2, b3, b4, b5, b6, b7;
  float sl, f;
  b1 = t->body;
  b2 = t->dot;
  b3 = t->tight;
  b4 = t->stemup;
  b5 = t->stemfix;
  b6 = t->nostem;
  b7 = t->oppflag;
  sl = t->stemlen;
  f = t->factor;
  [s encodeValuesOfObjCTypes:"cccccccff", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &sl, &f];
}


- (id) initWithCoder: (NSCoder *) aDecoder
{
    struct oldtimeinfo t;
    float sl;
    char b1, b2, b3, v;
    
    [super initWithCoder: aDecoder];
    time.nostem = 0;
    time.oppflag = 0;
    time.factor = 1.0;
    v = [aDecoder versionForClassName: @"TimedObj"];
    if (v == 0) {
	[aDecoder decodeValuesOfObjCTypes: "sf", &t, &sl];
	time.body = t.body;
	[self setDottingCode: t.dot];
	time.tight = 0;
	[self setStemIsUp: (sl < 0)];
	[self setStemIsFixed: NO];
	[self setStemLengthTo: sl];
    }
    else if (v == 1) {
	[aDecoder decodeValuesOfObjCTypes: "cccf", &b1, &b2, &b3, &sl];
	time.body = b1;
	[self setDottingCode: b2];
	time.tight = b3;
	[self setStemIsUp: (sl < 0)];
	[self setStemIsFixed: NO];
	[self setStemLengthTo: sl];
    }
    else if (v == 2) 
	readTimeData2(aDecoder, &time);
    else if (v == 3) 
	readTimeData3(aDecoder, &time);
    else if (v == 4) 
	readTimeData4(aDecoder, &time);
    else if (v == 5) 
	readTimeData5(aDecoder, &time);
    if (!mystaff) 
	NSLog(@"TimedObj %p has nil mystaff\n", self);
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  writeTimeData5(aCoder, &time);
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder: (OAPropertyListCoder *) aCoder];
    [aCoder setInteger: time.body forKey: @"body"];
    [aCoder setInteger: [self dottingCode] forKey: @"dot"];
    [aCoder setInteger: time.tight forKey: @"tight"];
    [aCoder setInteger: [self stemIsUp] forKey: @"stemup"];
    [aCoder setInteger: [self stemIsFixed] forKey: @"stemfix"];
    [aCoder setInteger: [self hasNoStem] forKey: @"nostem"];
    [aCoder setInteger: time.oppflag forKey: @"oppflag"];
    [aCoder setFloat: [self stemLength] forKey: @"stemlen"];
    [aCoder setFloat: time.factor forKey: @"factor"];
}


@end
