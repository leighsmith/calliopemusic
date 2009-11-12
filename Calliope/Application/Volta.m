#import "Volta.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "TimedObj.h"
#import "GraphicView.h"
#import "System.h"
#import "CalliopeAppController.h"
#import "Staff.h"
#import <Foundation/NSArray.h>

extern float barwidth[3][3];


@implementation Volta

+ (void)initialize
{
  if (self == [Volta class])
  {
      (void)[Volta setVersion: 1];		/* class version, see read: */
  }
  return;
}


+ myInspector
{
  return nil;
}


- init
{
  [super init];
  gFlags.type = VOLTA;
  mark[0] = '\0';
  pos = -1;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- (BOOL) getXY: (float *) x : (float *) y
{
  StaffObj *p = client;
  Staff *sp = p->mystaff;
  if (TYPEOF(sp) != STAFF) return NO;
  *x = p->x;
  *y = [sp yOfPos: pos];
  return YES;
}


/* called with a pair of interlinked partners */

- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  id n0, n1;
  if (!findEndpoints([v selectedGraphics], &n0, &n1)) return nil;
  client = n0;
  endpoint = n1;
  [n0 linkhanger: self];
  [n1 linkhanger: self];
  mark[0] = '1';
  mark[1] = '.';
  mark[2] = '\0';
  return self;
}


- (BOOL) isClosed: (NSMutableArray *) l
{
  if ([l indexOfObject:client] == NSNotFound) return NO;
  if ([l indexOfObject:endpoint] == NSNotFound) return NO;
  return YES;
}


- (void)removeObj
{
    [self retain];
    [client unlinkhanger: self];
    [endpoint unlinkhanger: self];
    [self release];
}


- (int)keyDownString:(NSString *)cc
{
    int cst;
    if (![cc canBeConvertedToEncoding:NSASCIIStringEncoding]) return -1;
//  if (cs == NX_SYMBOLSET) return -1;
    cst = *[cc UTF8String];
    if (cst == '|') gFlags.subtype ^= 1;
    else if (isdigitchar(cst)) mark[0] = cst;
  else return -1;
  return 1;
}


- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : sys : (int) alt
{
  int np;
  StaffObj *p = client;
  Staff *sp = p->mystaff;
  if (TYPEOF(sp) != STAFF) return NO;
  np = [sp findPos: dy + pt.y];
  if (np == pos) return NO;
  pos = np;
  [self recalc];
  return YES;
}


/* bartype[subtype] = bit 0 for beginning, 1 for ending */

char bartype[10] = {0, 0, 2, 2, 1, 1, 3, 0, 0, 0};


- drawMode: (int) m
{
  float x1, y1, x2, y2, th;
  int ss;
  StaffObj *p = client;
  Staff *sp = p->mystaff;
  if (TYPEOF(sp) != STAFF) return nil;
  ss = sp->flags.spacing;
  th = barwidth[sp->flags.subtype][sp->gFlags.size];
  y1 = [sp yOfPos: pos];
  y2 = y1 - 5 * ss;
  x1 = p->x;
  x1 = [p hasVoltaBesides: self] ? p->bounds.origin.x + p->bounds.size.width - (0.5 * th): p->x;
  p = endpoint;
  x2 = (![p hasVoltaBesides: self]) ? p->bounds.origin.x + p->bounds.size.width - (0.5 * th) : p->x;
  cline(x1, y1, x1, y2, th, m);
  cline(x1, y2, x2, y2, th, m);
  if (gFlags.subtype) cline(x2, y1, x2, y2, th, m);
  CAcString(x1 + ss, y1, mark, fontdata[FONTTEXT], m);
  return self;
}


extern int needUpgrade;

- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v = [aDecoder versionForClassName:@"Volta"];
  [super initWithCoder:aDecoder];
  needUpgrade |= 1;
  if (v == 0)
  {
    endpoint = [[aDecoder decodeObject] retain];
    [aDecoder decodeArrayOfObjCType:"c" count:4 at:mark];
    pos = -1;
  }
  else if (v == 1)
  {
    endpoint = [[aDecoder decodeObject] retain];
    [aDecoder decodeArrayOfObjCType:"c" count:4 at:mark];
    [aDecoder decodeValuesOfObjCTypes:"c", &pos];
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeConditionalObject:endpoint];
    [aCoder encodeArrayOfObjCType:"c" count:4 at:mark];
    [aCoder encodeValuesOfObjCTypes:"c", &pos];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setObject:endpoint forKey:@"endpoint"];
    for (i = 0; i < 4; i++) [aCoder setInteger:mark[i] forKey:[NSString stringWithFormat:@"mark%d",i]];
    [aCoder setInteger:pos forKey:@"pos"];
}

@end
