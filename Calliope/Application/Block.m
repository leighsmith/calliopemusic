/* $Id$ */
#import "Block.h"
#import "BlockInspector.h"
#import "GraphicView.h"
#import "Staff.h"
#import "System.h"
#import <AppKit/NSFont.h>
//#import "draw.h"  // This was generated by the pswrap utility from draw.psw.
#import "DrawingFunctions.h"
#import "muxlow.h"

/*
  gFlags.subtype
  0=block, 1=gup, 2=gdn, 3=gd, 4=breath, 5=GP, 6=gd
*/

@implementation Block


static Block *proto;


+ (void)initialize
{
  if (self == [Block class])
  {
      (void)[Block setVersion: 6];		/* class version, see read: */
    proto = [self alloc];
    proto->gFlags.subtype = 0;
    proto->p = 4;
    proto->width = 4;
    proto->height = 4;
  }
  return;
}


+ myInspector
{
  return [BlockInspector class];
}


+ myPrototype
{
  return proto;
}


- init
{
  [super init];
  gFlags.subtype = 0;
  gFlags.type = BLOCK;
  p = 4;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


/* initialise the prototype block */

- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
{
  [super proto: v : pt : sp : sys : g : i];
  width = proto->width;
  height = proto->height;
  gFlags.subtype = proto->gFlags.subtype;
  return self;
}


- (BOOL) reCache: (float) sy : (int) ss
{
  float t;
  t = sy + ss * p;
  if (t == y) return NO;
  y = t;
  return YES;
}



/* move a block */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : sys : (int) alt
{
  float nx=0.0, ny=0.0;
  int a, b;
  BOOL m = NO;
  if (alt)
  {
    if (TYPEOF(mystaff) == STAFF)
    {
      nx = pt.x;
      ny = pt.y;
      m = YES;
      a = [mystaff findPos: ny] - p;
      if (a <= 0 || a > 127) return NO;
      b  = (nx - x) / getSpacing(mystaff);
      if (b <= 0 || b > 127) return NO;
      if (a == height && b == width) return NO;
      height = a;
      width = b;
      m = YES;
    }
  }
  else
  {
    if (TYPEOF(mystaff) == STAFF)
    {
      nx = dx + pt.x;
      ny = dy + pt.y;
      a = [mystaff findPos: ny];
      if (a == p && x == nx) return NO;
      p = a;
      y = [mystaff yOfPos: p];
      x = nx;
      m = YES;
    }
    else
    {
      p = 0;
      x = nx;
      y = ny;
      m = YES;
    }
    [sys relinknote: self];
  }
  [self recalc];
  [self markHangers];
  [self setVerses];
  return m;
}


static char blockchar[NUMBLOCKS] = {0, CH_guideup, CH_guidedn, CH_guide, 44, 34, 75};
static char blockfont[NUMBLOCKS] = {1, 0, 0, 0, 1, 1, 0};
static char blockledger[NUMBLOCKS] = {0, 1, 1, 1, 0, 0, 1};

- drawMode: (int) m
{
  int sz, ss, bc, t;
  NSFont *bf;
  Staff *s;
  t = gFlags.subtype;
  if (t == 0)
  {
    ss = getSpacing(mystaff);
    crect(x, y, (float) width * ss, (float) height * ss, m);
  }
  else
  {      
    sz = gFlags.size;
      bf = musicFont[(int)blockfont[t]][sz];
    bc = blockchar[t];
    drawCharacterInFont(x, y, bc, bf, m);
    s = mystaff;
    if (blockledger[t] && TYPEOF(s) == STAFF)
    {
      drawledge(x, [s yOfTop], charhalfFGW(bf, bc),
                sz, p, s->flags.nlines, s->flags.spacing, m);
    }
  }
  return self;
}


/* v == 0 has to do conversion from old format */

- (id)initWithCoder:(NSCoder *)aDecoder
{
  char b1, b2;
  int v = [aDecoder versionForClassName:@"Block"];
  [super initWithCoder:aDecoder];
  if (v < 5)
  {
    width = bounds.size.width / 4;
    height = bounds.size.height / 4;
  }
  if (v == 5)
  {
    [aDecoder decodeValuesOfObjCTypes:"cc", &b1, &b2];
    width = b1;
    height = b2;
  }
  else if (v == 6) [aDecoder decodeValuesOfObjCTypes:"ff", &width, &height];
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeValuesOfObjCTypes:"ff", &width, &height];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setFloat:width forKey:@"width"];
    [aCoder setFloat:height forKey:@"height"];
}

@end
