/* $Id$ */

/* Generated by Interface Builder */

#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "Graphic.h"
#import "Bracket.h"
#import "BrackInspector.h"
#import "DrawingFunctions.h"
#import <Foundation/NSArray.h>
#import <AppKit/NSFont.h>


@implementation Bracket


float brackwidth[3] = {4.8, 0.75 * 4.8, 0.5 * 4.8};


static Bracket *proto;


+ (void) initialize
{
    if (self == [Bracket class]) {
	[Bracket setVersion: 0];		/* class version, see read: */
	proto = [Bracket alloc];
	proto->gFlags.subtype = BRACK;
	proto->level = 0;
    }
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [BrackInspector class];
}


- init
{
    self = [super init];
    if(self != nil) {
	[self setTypeOfGraphic: BRACKET];
	gFlags.subtype = LINKAGE;
	client1 = client2 = nil;
	level = 0;	
    }
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- sysInvalid
{
  return [client1 sysInvalid];
}


/* set proto to a reasonable type (the init'ed type is a LINKAGE) */

- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
{
  if ([sys hasLinkage])
  {
    gFlags.subtype = proto->gFlags.subtype;
    if ([sp graphicType] == SYSTEM) sp = [sys findOnlyStaff: pt.y];
    client1 = client2 = sp;
    level = [sp brackLevel] + 1;
  }
  else client1 = sys;
  return self;
}


- (void)removeObj
{
    [self retain];
    [[self mySystem] unlinkobject: self];
    [self release];
}

/*
  The intricacy here is to set the clients to the appropriate
  staves of the new system sys. var s is the old system.
*/

- newFrom: (System *) sys
{
  System *s;
  Bracket *q = [[Bracket alloc] init];
  q->gFlags.subtype = gFlags.subtype;
  q->level = level;
  if (gFlags.subtype == LINKAGE)
  {
    q->client1 = sys;
    q->client2 = nil;
  }
  else
  {
      unsigned i,j;
    s = ((Staff *)client1)->mysys;
    i = [s indexOfStaff: client1];
    j = [s indexOfStaff: client2];
    if (i == NSNotFound || j == NSNotFound) {
        NSLog(@"Bracket: can't find clients!\n");
        q->client1 = nil;
        q->client2 = nil;
        return q;
    }
    q->client1 = [sys getStaff: i];
    q->client2 = [sys getStaff: j];
  }
  return q;
}
 
 
- mySystem
{
  if (gFlags.subtype == LINKAGE) return client1;
  else return ((Staff *)client1)->mysys;
}


/* return whether lower end of self connects to arg */

- (BOOL) atBottom: (Staff *) s
{
  Staff *s1, *s2;
  if (gFlags.subtype == LINKAGE) return NO;
  s1 = client1;
  s2 = client2;
  if (s1->flags.hidden || s2->flags.hidden) return NO;
  if ([s1 yOfTop] < [s2 yOfTop]) return (s2 == s);
  else return (s1 == s);
}


/* return whether upper end of self connects to arg */

- (BOOL) atTop: (Staff *) s
{
  Staff *s1, *s2;
  if (gFlags.subtype == LINKAGE) return NO;
  s1 = client1;
  s2 = client2;
  if (s1->flags.hidden || s2->flags.hidden) return NO;
  if ([s1 yOfTop] < [s2 yOfTop]) return (s1 == s);
  else return (s2 == s);
}


/* moving bracket sets to nearest staff in same system */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  Staff *s, *s1, *s2;
  BOOL m = NO;
  if (gFlags.subtype == LINKAGE) return NO;
  s1 = client1;
  s2 = client2;
  s = [s1->mysys findOnlyStaff: p.y];
  if (s->gFlags.type != STAFF) return NO;
  if (([s1 yOfTop] < [s2 yOfTop]) == (gFlags.selend & 1))
  {
    if (s2 != s)
    {
      client2 = s;
      m = YES;
      [self recalc];
    }
  }
  else
  {
    if (s1 != s)
    {
      client1 = s;
      m = YES;
      [self recalc];
    }
  }
  return m;
}


static void displink(System *sys, int m)
{
  float x, y, ymin, ymax;
  short i;
  char f1, f2;
  Staff *s, *smin, *smax=nil;
  if (sys == nil) return;
  ymin = 32000.0;
  ymax = 0.0;
  i = [sys numberOfStaves];
  f1 = f2 = 0;
  while (i--)
  {
    s = [sys getStaff: i];
    if (s->flags.hidden) continue;
    y = [s yOfTop];
    if (y < ymin)
    {
      f1 = 1;
      ymin = y;
      smin = s;
    }
    if (y > ymax)
    {
      f2 = 1;
      ymax = y;
      smax = s;
    }
  }
  if (f1 && f2) 
  {
    x = [sys leftWhitespace];
    ymax += [smax staffHeight];
    cline(x, ymin, x, ymax, 1.0, m);
  }
}

- drawMode: (int) m
{
  Staff *s1, *s2;
  System *sys;
  NSFont *f;
  float x, y1, y2, dy;
  int sz;
  if (gFlags.subtype == LINKAGE)
  {
    displink(client1, m);
    return self;
  }
  s1 = client1;
  s2 = client2;
  if (s1->flags.hidden || s2->flags.hidden) return self;
  if ([s1 yOfTop] < [s2 yOfTop])
  {
    y1 = [s1 yOfTop];
    y2 = [s2 yOfBottom];
  }
  else
  {
    y1 = [s2 yOfTop];
    y2 = [s1 yOfBottom];
  }
  // gcc 4.0 doesn't like typeof bit fields so we use the long hand version
  // sz = MAX(s1->gFlags.size, s2->gFlags.size);
  sz = s1->gFlags.size < s2->gFlags.size ? s2->gFlags.size : s1->gFlags.size;
  sys = s1->mysys;
  x = [sys getBracketX: self : sz];
  switch(gFlags.subtype)
  {
    case BRACK:
      f = musicFont[1][sz];
      crect(x, y1, brackwidth[sz], y2 - y1, m);
      DrawCharacterInFont(x, y1, SF_topbrack, f, m);
      DrawCharacterInFont(x, y2, SF_botbrack, f, m);
      break;
    case BRACE:
      dy = nature[sz];
      x += dy;
      if (level != 1) x += dy;
      cbrace(x, y2 + dy, x, y1 - dy, 1.5 * brackwidth[sz], m);
      break;
  }
  return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  [super initWithCoder:aDecoder];
  [aDecoder decodeValuesOfObjCTypes:"c", &level];
  client1 = [[aDecoder decodeObject] retain];
  client2 = [[aDecoder decodeObject] retain];
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeValuesOfObjCTypes:"c", &level];
    [aCoder encodeConditionalObject:client1];
    [aCoder encodeConditionalObject:client2];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:level forKey:@"level"];
    [aCoder setObject:client1 forKey:@"client1"];
    [aCoder setObject:client2 forKey:@"client2"];
}
@end
