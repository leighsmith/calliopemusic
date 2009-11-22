/* $Id$ */
#import <Foundation/Foundation.h>
#import "Hanger.h"
#import "TimedObj.h"
#import "System.h"
#import "DrawingFunctions.h"
#import "FileCompatibility.h"

@implementation Hanger

+ (void) initialize
{
    if (self == [Hanger class]) {
	[Hanger setVersion: 2];	/* class version, see read: */ /*sb: set to 2 for List conversion */
    }
}


- init
{
    self = [super init];
    if (self != nil) {
	hFlags.level = 0;
	hFlags.split = 0;
	UID = 0;
	client = nil;
    }
    return self;
}

- copyWithZone: (NSZone *) zone
{
    // We know that our super class does not use NSCopyObject().
    Hanger *newHanger = [super copyWithZone: zone];
    
    if([self splitToLeft])
	[newHanger setSplitToLeft: YES];
    if([self splitToRight])
        [newHanger setSplitToRight: YES];
    [newHanger setLevel: [self myLevel]];
    newHanger->UID = self->UID;
    newHanger->client = [client copy];
    return newHanger;
}

- (BOOL) canSplit
{
    return NO; // Perhaps return hFlags.split != 0;
}

- (BOOL) splitToLeft
{
    return hFlags.split & 2;
}

- (void) setSplitToLeft: (BOOL) yesOrNo
{
    if(yesOrNo)
	hFlags.split |= 2;
    else
	hFlags.split &= 1;
}

- (BOOL) splitToRight
{
    return hFlags.split & 1;
}

- (void) setSplitToRight: (BOOL) yesOrNo
{
    if(yesOrNo)
	hFlags.split |= 1;
    else
	hFlags.split &= 2;
}

- (BOOL) isDangler
{
  return YES;
}


- (BOOL) needSplit: (float) s0 : (float) s1
{
  return NO;
}


/* see if any clients fall outside the interval [s0, s1] */

- (BOOL) needSplitList: (float) s0 : (float) s1
{
  int k = [client count];
  float x;
  while (k--)
  {
    x = ((StaffObj *)[client objectAtIndex:k])->x;
    if (x < s0 || s1 < x) return YES;
  }
  return NO;
}


/*
  willSplit is for situations that might be de facto split (moving, proto),
  but do nothing if split not needed.  If split, return list of splits.
  SplitMe: is for situations before the split has happened (spill grab).
  Caller needs to check whether a selected thing was modified.
*/


- (NSMutableArray *) willSplit
{
  int i, k, j, si = -1, sm = MAXINT;
  BOOL need = NO;
  NSMutableArray *l[2], *a;
  Hanger *t[2], *n;
  System *s, *sys = nil;
  StaffObj *p;
  k = [client count];
  for (i = 0; i < k; i++)
  {
    s = [[client objectAtIndex:i] mySystem];
    j = [s myIndex];
    if (si == -1) si = j;
    need = (si != j);
    if (j < sm)
    {
      sm = j;
      sys = s;
    }
  }
  if (!need) return nil;
  l[0] = [[NSMutableArray alloc] init];
  l[1] = [[NSMutableArray alloc] init];
  for (i = 0; i < k; i++)
  {
    p = [client objectAtIndex:i];
    j = [[p mySystem] myIndex];
    [l[(j > sm)] addObject: p];
  }
  for (i = 0; i < 2; i++)
  {
    t[i] = n = [self copy];
    a = l[i];
    n->client = a;
    n->UID = (int) self;
    n->hFlags.split = i + 1;
    k = [a count];
    while (k--) [[a objectAtIndex:k] linkhanger: n];
  }
  [self haveSplit: t[0] : t[1]];
  a = [[NSMutableArray alloc] init];
  [a addObject: t[0]];
  [a addObject: t[1]];
  return a;
}


/*
  All the clients lying in the interval [s0,s1] go to dth in list.  else to !d.
*/

- (NSMutableArray *) splitMe: (float) s0 : (float) s1 : (int) d
{
  int i, k;
  float x;
  NSMutableArray *l[2], *a;
  Hanger *t[2], *n;
  StaffObj *p;
  k = [client count];
  l[0] = [[NSMutableArray alloc] init];
  l[1] = [[NSMutableArray alloc] init];
  while (k--)
  {
    p = [client objectAtIndex:k];
    x = p->x;
    if (s0 <= x && x <= s1) [l[d] addObject: p]; else [l[!d] addObject: p];
  }
  for (i = 0; i < 2; i++)
  {
    t[i] = n = [self copy];
    a = l[i];
    n->client = a;
    n->UID = (int) self;
    n->hFlags.split = i + 1;
    k = [a count];
    while (k--) [[a objectAtIndex:k] linkhanger: n];
  }
  [self haveSplit: t[0] : t[1] : s0 : s1];
  a = [[NSMutableArray alloc] init];
  [a addObject: t[0]];
  [a addObject: t[1]];
  return a;
}


- haveSplit: a :  b : (float) x0 : (float) x1
{
  return self;
}

- haveSplit: a :  b
{
  return self;
}

/*  Called after the objects have been moved */

- mergeMe: (Hanger *) h
{
  int k;
  NSMutableArray *hl;
  StaffObj *p;
  hl = h->client;
  k = [hl count];
  while (k--)
  {
    p = [hl objectAtIndex:k];
      [client addObject: p];
    [p linkhanger: self];
  }
  hFlags.split &= h->hFlags.split;
  [self setHanger];
  return self;
}


/* needs to be overridden by Hangers without level */

- (int) myLevel
{
    return hFlags.level;
}

- (void) setLevel: (int) newLevel
{
    hFlags.level = newLevel;
}

/* must be called before self is one of the Hangers */

- (int) maxLevel
{
    int m = -1, k = [client count];

    while (k--) {
	StaffObj *p = [client objectAtIndex: k];
	int i = [p maxGroupLevel];

	if (i > m) 
	    m = i;
    }
    return m;
}

// TODO this should return a (Graphic *)
- firstClient
{
    return [client objectAtIndex: 0];
}

// - (void) setClient: (Graphic *) newClient
- (void) setClient: (id) newClient
{
    [client addObject: newClient];
}

- (NSArray *) clients
{
    return [NSArray arrayWithArray: client];
}

/* remove from clients anything not in l */
- closeClients: (NSMutableArray *) l
{
    int k = [client count];

    while (k--) {
	id p = [client objectAtIndex: k];
	
	if ([l indexOfObject: p] == NSNotFound) 
	    [client removeObjectAtIndex: k];
    }
    return self;
}

// TODO probably should just be merged with sysInvalidList.
- sysInvalid
{
    return [[self firstClient] sysInvalid];
}

- (float) staffScale
{
    return [[[self firstClient] mySystem] staffScale];
}

- sysInvalidList
{
    int k = [client count];
    while (k--) 
	[[client objectAtIndex: k] sysInvalid];
  return self;
}


- setHanger
{
  return [self recalc];
}


/* this is subclassed by those that need it */

- setHanger: (BOOL) f1 : (BOOL) f2
{
  return [self recalc];
}


/* this is called after a proto to force a set */

- presetHanger
{
  return [self setHanger: 1 : 1];
}


- (void)removeObj
{
  int k;
  k = [enclosures count];
  while (k--) [[enclosures objectAtIndex:k] removeObj];
  [self retain];
  [[self firstClient] unlinkhanger: self];
  [self release];
}


- removeGroup
{
  StaffObj *p;
  int lev = hFlags.level;
  int i, k;
  k = [enclosures count];
  while (k--) [[enclosures objectAtIndex:k] removeObj];
  k = [client count];
  for (i = 0; i < k; i++) [[client objectAtIndex:i] markGroups];
  for (i = 0; i < k; i++)   
  {
    p = [client objectAtIndex:i];
    [p unlinkhanger: self];
    [p renumberGroups: lev];
  }
  return self;
}


/*
  The sort is required to be fastest when elements are in order. Shellsort.
*/

#define STRIDE_FACTOR 3

- sortNotes: (NSMutableArray *) l
{
  int c, d, f, s, k;
  StaffObj *p;
  k = [l count];
  s = 1;
  while (s <= k) s = s * STRIDE_FACTOR + 1;
  while (s > (STRIDE_FACTOR - 1))
  {
    s = s / STRIDE_FACTOR;
    for (c = s; c < k; c++)
    {
      f = NO;
      d = c - s;
      while ((d >= 0) && !f)
      {
        if (((StaffObj *)[l objectAtIndex:d + s])->x < ((StaffObj *)[l objectAtIndex:d])->x)
	{
            p = [[l objectAtIndex:d] retain];
	  [l replaceObjectAtIndex:d withObject:[l objectAtIndex:d + s]];
	  [l replaceObjectAtIndex:d + s withObject:p];
          [p release];
	  d -= s;
	}
	else f = YES;
      }
    }
  }
  return self;
}

// This is an abstract method that should never actually run, all subclasses should override this.
- (BOOL) coordsForHandle: (int) handle asX: (float *) x andY: (float *) y
{
    NSLog(@"Hanger abstract -coordsForHandle: %d messaged, returning coords = [0,0]\n", handle);
    *x = 0.0;
    *y = 0.0;
    return NO;
}

/* many hangers use this generic hit */

- (BOOL) hit: (NSPoint) p : (int) j : (int) k
{
  int i;
  float x, y;
  for (i = j; i <= k; i++)
  {
    [self coordsForHandle: i  asX: &x  andY: &y];
    if (TOLFLOATEQ(p.x, x, HANDSIZE) && TOLFLOATEQ(p.y, y, HANDSIZE))
    {
      gFlags.selend = i;
      return YES;
    }
  }
  return NO;
}


- (float) hitDistance: (NSPoint) p : (int) j : (int) k
{
  int i;
  float x, y;
  for (i = j; i <= k; i++)
  {
      [self coordsForHandle: i  asX: &x  andY: &y];
    if (TOLFLOATEQ(p.x, x, HANDSIZE) && TOLFLOATEQ(p.y, y, HANDSIZE))
    {
      return hypot(p.x - x, p.y - y);
    }
  }
  return MAXFLOAT;
}


/*
  Unless overridden, hangers ignore requests to move.  Trapped here
  so that Graphic does not move the hanger's bounding box!
*/

- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  return NO;
}

/*
 For upgrading old format. The upgrading is done in the subclasses.
 */
- proto: (Tie *) t1 : (Tie *) t2
{
    return self;
}

/* archiving */


- (id)initWithCoder:(NSCoder *)aDecoder
{
    char b0, b1;
    int v = [aDecoder versionForClassName:@"Hanger"];
    id decodedClient;
    
    [super initWithCoder:aDecoder];
    decodedClient = [aDecoder decodeObject];
    if ([decodedClient isKindOfClass: [NSMutableArray class]])
	client = [decodedClient retain];
    else
	client = [[NSMutableArray arrayWithObject: decodedClient] retain];
    if (v == 0) {
	UID = 0;
	hFlags.split = 0;
	hFlags.level = 0;
    }
    else if (v == 1) {
	[aDecoder decodeValuesOfObjCTypes:"icc", &UID, &b0, &b1];
	hFlags.split = b0;
	hFlags.level = b1;
    }
    else if (v == 2) {
	[aDecoder decodeValuesOfObjCTypes:"icc", &UID, &b0, &b1];
	hFlags.split = b0;
	hFlags.level = b1;
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b0, b1;
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:client];
  b0 = hFlags.split;
  b1 = hFlags.level;
  [aCoder encodeValuesOfObjCTypes:"icc", &UID, &b0, &b1];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setObject:client forKey:@"client"];
    [aCoder setInteger:UID forKey:@"UID"];
    [aCoder setInteger:hFlags.split forKey:@"split"];
    [aCoder setInteger:hFlags.level forKey:@"level"];
}

@end
