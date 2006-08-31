#import "Metro.h"
#import "MetroInspector.h"
#import "mux.h"
#import "muxlow.h"
#import "StaffObj.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "System.h"
#import "Staff.h"

extern char stemshorts[3];

@implementation Metro


static Metro *proto;

+ (void)initialize
{
  if (self == [Metro class])
  {
      (void)[Metro setVersion: 1];		/* class version, see read: */
    proto = [[Metro alloc] init];
    proto->gFlags.subtype = 1;
    proto->body[0] = 5;
    proto->dot[0] = 0;
    proto->ticks = 72;
    proto->pos = -4;
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [MetroInspector class];
}


- (int) myLevel
{
  return -1;
}


- init
{
  [super init];
  gFlags.type = METRO;
  return self;
}


- newFrom
{
  int i;
  Metro *p = [[Metro alloc] init];
  p->gFlags = gFlags;
  p->pos = pos;
  p->ticks = ticks;
  for (i = 0; i < 2; i++)
  {
    p->body[i] = body[i];
    p->dot[i] = dot[i];
  }
  return p;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  int n;
  client = [v isSelTypeCode: TC_STAFFOBJ : &n];
  if (n != 1) return nil;
  gFlags.subtype = proto->gFlags.subtype;
  body[0] = proto->body[0];
  dot[0] = proto->dot[0];
  ticks = proto->ticks;
  pos = proto->pos;
  [client linkhanger: self];
  return self;
}


- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
  StaffObj *p;
  Metro *t;
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


- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : sys : (int) alt
{
  int np;
  StaffObj *p = client;
  Staff *sp = p->mystaff;
  if (TYPEOF(sp) != STAFF) return NO;
  np = [sp findPos: pt.y];
  if (np == pos) return NO;
  pos = np;
  [self recalc];
  return YES;
}


- drawMode: (int) m
{
    float x, y, dx, nx, dy;
    NSFont *f = fontdata[FONTSTMR];
    id sp = ((StaffObj *)client)->mystaff;
    int sz = smallersz[gFlags.size];
    
    if (TYPEOF(sp) != STAFF) 
	return self;
    x = ((StaffObj *)client)->x;
    y = [sp yOfPos: pos];
    dx = charFGW(f, '=');
    centxChar(x, y, '=', f, m);
    nx = dx * (2.0 + dot[0] * 0.5);
    dy = charFCH(f, '=');
    csnote(x - nx, y - dy, -stemshorts[sz], body[0], dot[0], sz, 0, 0, m);
    if (gFlags.subtype) {
	DrawTextWithBaselineTies(x + dx, y, [NSString stringWithFormat: @"%d", ticks], f, m);
    }
    else 
	csnote(x + 2.0 * dx, y - dy, -stemshorts[sz], body[1], dot[1], sz, 0, 0, m);
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v = [aDecoder versionForClassName:@"Metro"];
  [super initWithCoder:aDecoder];
  if (v == 0)
  {
    [aDecoder decodeArrayOfObjCType:"c" count:2 at:body];
    [aDecoder decodeArrayOfObjCType:"c" count:2 at:dot];
    [aDecoder decodeValuesOfObjCTypes:"s", &ticks];
  }
  else if (v == 1)
  {
    [aDecoder decodeArrayOfObjCType:"c" count:2 at:body];
    [aDecoder decodeArrayOfObjCType:"c" count:2 at:dot];
    [aDecoder decodeValuesOfObjCTypes:"ss", &ticks, &pos];
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeArrayOfObjCType:"c" count:2 at:body];
    [aCoder encodeArrayOfObjCType:"c" count:2 at:dot];
    [aCoder encodeValuesOfObjCTypes:"ss", &ticks, &pos];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    for (i = 0; i < 2; i++) [aCoder setInteger:body[i] forKey:[NSString stringWithFormat:@"body%d",i]];
    for (i = 0; i < 2; i++) [aCoder setInteger:dot[i] forKey:[NSString stringWithFormat:@"dot%d",i]];
    [aCoder setInteger:ticks forKey:@"ticks"];
    [aCoder setInteger:pos forKey:@"pos"];
}


@end
