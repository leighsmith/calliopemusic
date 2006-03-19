#import "Page.h"
#import "Runner.h"
#import "Margin.h"
#import "GVFormat.h"
#import "mux.h"
#import "muxlow.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@implementation Page

extern NSSize paperSize;
extern BOOL marginFlag;

NSString *curvartext[8];

+ (void)initialize
{
    int i;
    for (i=0;i<7;i++) curvartext[i]=nil;
  if (self == [Page class])
  {
      (void)[Page setVersion: 2];	/* class version, see read: */
  }
  return;
}


+ initPage
{
    NSCalendarDate *now = [NSCalendarDate calendarDate];
    int i;
    for (i=0;i<7;i++) if (curvartext[i]) {[curvartext[i] release];curvartext[i]=nil;}
    curvartext[0] = [[now descriptionWithCalendarFormat:@"%d"] retain];
    curvartext[1] = [[now descriptionWithCalendarFormat:@"%d"] retain];
    curvartext[2] = [[now descriptionWithCalendarFormat:@"%m"] retain];
    curvartext[3] = [[now descriptionWithCalendarFormat:@"%y"] retain];
    curvartext[4] = [[now descriptionWithCalendarFormat:@"%H"] retain];
    curvartext[5] = [[now descriptionWithCalendarFormat:@"%M"] retain];
    return self;
}


- (void)dealloc
{
    [super dealloc];
    return;
}


- init: (int) n : (int) s0 : (int) s1
{
  [super init];
  topsys = s0;
  botsys = s1;
  num = n;
  alignment = format = 0;
  return self;
}


/* copy page table info from previous page.  p is nil if no previous page */

- prevTable: (Page *) p
{
  int i = 12;
  if (p == nil)
  {
    while (i--)
    {
      headfoot[i] = nil;
      hfinfo[i] = 0;
    }
    i = NUMMARGINS;
    while (i--) margin[i] = 0;
    alignment = format = 0;
  }
  else
  {
    while (i--)
    {
      headfoot[i] = p->headfoot[i];
      hfinfo[i] = 0;
    }
    i = NUMMARGINS;
    while (i--) margin[i] = p->margin[i];
    alignment = p->alignment;
    format = p->format;
  }
  return self;
}

/* margin = margin + binding margin */

- (float) leftMargin
{
  float m = margin[0];
  m += (num & 1) ? margin[8] : margin[6];
  return m / [[DrawApp currentDocument] staffScale];
}


- (float) rightMargin
{
  float m = margin[1];
  m += (num & 1) ? margin[9] : margin[7];
  return m / [[DrawApp currentDocument] staffScale];
}


- (float) leftBinding
{
  float m;
  m = (num & 1) ? margin[8] : margin[6];
  return m / [[DrawApp currentDocument] staffScale];
}


- (float) rightBinding
{
  float m;
  m = (num & 1) ? margin[9] : margin[7];
  return m / [[DrawApp currentDocument] staffScale];
}


- (float) topMargin
{
  return margin[4] / [[DrawApp currentDocument] staffScale];
}


- (float) bottomMargin
{
  return margin[5] / [[DrawApp currentDocument] staffScale];
}

- (float) headerBase
{
  return margin[2] / [[DrawApp currentDocument] staffScale];
}


- (float) footerBase
{
  return margin[3] / [[DrawApp currentDocument] staffScale];
}


static void drawSlants(float x, float y, float hw, float th)
{
  float xa, xb, ya, yb;
  xa = x - hw;
  xb = x + hw;
  ya = y;
  yb = y - 3 * th;
  cslant(xa, ya, xb, yb, th, drawmode[0][0]);
  ya += 1.75 * th;
  yb += 1.75 * th;
  cslant(xa, ya, xb, yb, th, drawmode[0][0]);
}


- drawSysSep: (NSRect) r : (System *) s : (GraphicView *) v
{
  int mi = [s myIndex];
  float ym, th, hw;
  if (mi == botsys) return self;
  ym = [v yBetween: mi];
  th = beamthick[0];
  hw = 4 * nature[0];
  if (s->flags.syssep & 2) drawSlants([self leftMargin], ym, hw, th);
  if (s->flags.syssep & 1) drawSlants([self leftMargin] + [s leftIndent] + s->width, ym, hw, th);
  return self;
}


static void drawVert(float x, float y, float h, NSRect r)
{
  NSRect line;
  line.origin.x = x;
  line.origin.y = y;
  line.size.width = 1.0;
  line.size.height = h;
  if (!NSIsEmptyRect(line = NSIntersectionRect(r , line))) cline(x, y, x, y + h, 0.0, markmode[0]);
}


static void drawHorz(float x, float y, float w, NSRect r)
{
  NSRect line;
  line.origin.x = x;
  line.origin.y = y;
  line.size.width = w;
  line.size.height = 1.0;
  if (!NSIsEmptyRect(line = NSIntersectionRect(r , line))) cline(x, y, x + w, y, 0.0, markmode[0]);
}


- draw: (NSRect) r : (BOOL) nso
{
  int i, a, b;
  float x, y, w, h;
  NSRect vb;
  Runner *p;
  a = 0;

  if (curvartext[0]) [curvartext[0] autorelease];
  curvartext[0] = [[NSString stringWithFormat:@"%d",num] retain];
  if (num & 1) a = 6;
  b = a + 6;
  if (marginFlag)
  {
    vb = [[NSApp currentView] bounds];
    x = [self leftMargin];
    y = [self topMargin];
    w = vb.size.width - x - [self rightMargin];
    h = vb.size.height - y - [self bottomMargin];
    drawHorz(x, y, w, r);
    drawVert(x, y, h, r);
    drawHorz(x, y + h, w, r);
    drawVert(x + w, y, h, r);
    drawHorz(x, [self headerBase], w, r);
    drawHorz(x, vb.size.height - [self footerBase], w, r);
    x = [self leftBinding];
    if (x > 0.001) drawVert(x, vb.origin.y, vb.size.height, r);
    x = [self rightBinding];
    if (x > 0.001) drawVert(vb.origin.x + vb.size.width - x, vb.origin.y, vb.size.height, r);
  }
  for (i = a; i < b; i++)
  {
    p = headfoot[i];
    if (p == nil) continue;
    if (p->flags.onceonly && hfinfo[i] == 0) continue;
    if (p->flags.nextpage && hfinfo[i]) continue;
    [p renderMe: r : p->data : paperSize : self];
  }
  return self;
}

extern int needUpgrade;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    int i, v;
    float t, b;

    v = [aDecoder versionForClassName:@"Page"];
    if (v == 0)
      {
        [aDecoder decodeValuesOfObjCTypes:"ifffss", &num, &t, &fillheight, &b, &topsys, &botsys];
        margin[4] = t;
        margin[5] = b;
        for (i = 0; i < 12; i++) headfoot[i] = [[aDecoder decodeObject] retain];
        [aDecoder decodeArrayOfObjCType:"c" count:12 at:hfinfo];
        needUpgrade |= 4;
        format = alignment = 0;
      }
    else if (v == 1)
      {
        [aDecoder decodeValuesOfObjCTypes:"ifss", &num, &fillheight, &topsys, &botsys];
        for (i = 0; i < 12; i++) headfoot[i] = [[aDecoder decodeObject] retain];
        [aDecoder decodeArrayOfObjCType:"c" count:12 at:hfinfo];
        [aDecoder decodeArrayOfObjCType:"f" count:NUMMARGINS at:margin];
        format = alignment = 0;
      }
    else if (v == 2)
      {
        [aDecoder decodeValuesOfObjCTypes:"ifsscc", &num, &fillheight, &topsys, &botsys, &format, &alignment];
        for (i = 0; i < 12; i++) headfoot[i] = [[aDecoder decodeObject] retain];
        [aDecoder decodeArrayOfObjCType:"c" count:12 at:hfinfo];
        [aDecoder decodeArrayOfObjCType:"f" count:NUMMARGINS at:margin];
      }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    int i;

    [aCoder encodeValuesOfObjCTypes:"ifsscc", &num, &fillheight, &topsys, &botsys, &format, &alignment];
    for (i = 0; i < 12; i++) [aCoder encodeConditionalObject:headfoot[i]];
    [aCoder encodeArrayOfObjCType:"c" count:12 at:hfinfo];
    [aCoder encodeArrayOfObjCType:"f" count:NUMMARGINS at:margin];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
//    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];

    [aCoder setInteger:num forKey:@"num"];
    [aCoder setFloat:fillheight forKey:@"fillheight"];
    [aCoder setInteger:topsys forKey:@"topsys"];
    [aCoder setInteger:botsys forKey:@"botsys"];
    [aCoder setInteger:format forKey:@"format"];
    [aCoder setInteger:alignment forKey:@"alignment"];

    for (i = 0; i < 12; i++) [aCoder setObject:headfoot[i] forKey:[NSString stringWithFormat:@"hf%d",i]];
    for (i = 0; i < 12; i++) [aCoder setInteger:hfinfo[i] forKey:[NSString stringWithFormat:@"hfinfo%d",i]];
    [aCoder setInteger:NUMMARGINS forKey:@"nummargins"];
    for (i = 0; i < NUMMARGINS; i++) [aCoder setFloat:margin[i] forKey:[NSString stringWithFormat:@"margin%d",i]];
}


@end
