#import "Range.h"
#import "RangeInspector.h"
#import "Staff.h"
#import "StaffObj.h"
#import "mux.h"
#import "muxlow.h"

@implementation Range

static Range *proto;

+ (void)initialize
{
  if (self == [Range class])
  {
    [Range setVersion: 0];		/* class version, see read: */
    proto = [[Range alloc] init];
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [RangeInspector class];
}


- init
{
  [super init];
  gFlags.type = RANGE;
  gFlags.subtype = 0;
  p1 = 8;
  p2 = 0;
  line = 1;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- proto: v : (NSPoint) pt : (Staff *) sp : sys : (Graphic *) g : (int) i
{
  [super proto: v : pt : sp : sys : g : i];
  gFlags.subtype = proto->gFlags.subtype;
  gFlags.size = sp->gFlags.size;
  slant = proto->slant;
  line = proto->line;
  return self;
}


- recalc
{
  [super recalc];
  if (TYPEOF(mystaff) == STAFF) y = [mystaff yOfTop];
  return self; 
}


unsigned char ranbody[3] = {SF_qnote, CH_oqnote, CH_punctsqu};

char ranfont[3] = {1, 0, 0};


- drawMode: (int) m
{
  int ss, nl, sz, st;
  float x2, y1, y2, hw;
  unsigned char ch;
  NSFont *f;
  Staff *sp = mystaff;
  if (TYPEOF(sp) == STAFF)
  {
    ss = sp->flags.spacing;
    nl = sp->flags.nlines;
    st = sp->flags.subtype;
  }
  else
  {
    ss = 4;
    nl = 5;
    st = 0;
  }
  sz = gFlags.size;
  ch = ranbody[gFlags.subtype];
  y1 = GETYSP(y, ss, p1);
  f = musicFont[(int)ranfont[(int)gFlags.subtype]][sz];
  y2 = GETYSP(y, ss, p2);
  x2 = x + slant * ss;
  centChar(x, y1, ch, f, m);
  centChar(x2, y2, ch, f, m);
  if (TYPEOF(sp) == STAFF)
  {
    hw = charhalfFGW(f, ch);
    drawledge(x2, y, hw, sz, p2, nl, ss, m);
    drawledge(x, y, hw, sz, p1, nl, ss, m);
  }
  if (line) cline(x, y1, x2, y2, barwidth[st][sz], m);
  return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  [super initWithCoder:aDecoder];
  [aDecoder decodeValuesOfObjCTypes:"cccccc", &p1, &p2, &a1, &a2, &line, &slant];
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeValuesOfObjCTypes:"cccccc", &p1, &p2, &a1, &a2, &line, &slant];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:p1 forKey:@"p1"];
    [aCoder setInteger:p2 forKey:@"p2"];
    [aCoder setInteger:a1 forKey:@"a1"];
    [aCoder setInteger:a2 forKey:@"a2"];
    [aCoder setInteger:line forKey:@"line"];
    [aCoder setInteger:slant forKey:@"slant"];
}
@end
