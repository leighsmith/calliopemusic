#import "Ruler.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import <AppKit/NSFont.h>
#import <AppKit/NSText.h>
#import <AppKit/psopsOpenStep.h>
#import <math.h>
#import "mux.h"

#define LINE_X (15.0)
#define WHOLE_HT (10.0)
#define HALF_HT (8.0)
#define QUARTER_HT (4.0)
#define EIGHTH_HT (2.0)
#define NUM_X (3.0)

#define WHOLE (72)
#define HALF (WHOLE/2)
#define QUARTER (WHOLE/4)
#define EIGHTH (WHOLE/8)

extern NSSize paperSize;

@implementation Ruler

+ (float)width
{
    return 23.0;
}

- initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
#if (NS_VERSION == 3)
    [self setFont:[NSFont systemFontOfSize:8.0]];
#else
    [self setFont:[NSFont fontWithName:[NSString stringWithCString:NXSystemFont] size:8.0]];
#endif
    startX = [[self class] width];
    return self;
}


- (void)setFont:(NSFont *)aFont
{
    float as, lh;

    font = [aFont retain];
    NSTextFontInfo(aFont, &as, &descender, &lh);
    if (descender < 0.0) descender = -1.0 * descender;
}

const char *unitstring[4] = {"in", "cm", "pt", "pi"};

static float unitinc[4] = {(72.0 / 8.0), (72.0 / 2.54 / 2.0), (72.0 / 4.0), (72.0 / 5.0)};

static int unitmark[4][4] =
{
  {8, 4, 2, 1},
  {2, 1, 0, 0},
  {2, 1, 0, 0},
  {2, 1, 0, 0},
};

static int unitmul[4] = {1, 1, 36, 10};

static float unitlen[4][4] =
{
  {10, 6, 4, 2},
  {10, 4, 0, 0},
  {10, 4, 0, 0},
  {10, 4, 0, 0},
};


- drawHorizontal:(const NSRect *)rects
{
  NSRect line, clip;
  int curPos, last, i, j, n1, n2, u;
  char buf[10];
  float s, x;
  u = [[NSApp currentDocument] getPreferenceAsInt: UNITS];
  PSsetgray(NSLightGray);
  NSRectFill(*rects);
  if (lastlp >= rects->origin.x && lastlp < rects->origin.x + rects->size.width) lastlp = -1.0;
  if (lasthp >= rects->origin.x && lasthp < rects->origin.x + rects->size.width) lasthp = -1.0;
  line = [self bounds];				/* draw bottom line */
  line.size.height = 1.0;
  PSsetgray(NSDarkGray);
  if (!NSIsEmptyRect(line = NSIntersectionRect(*rects , line))) NSRectFill(line);
  line = [self bounds];
  line.size.width = 1.0;
  line.origin.x = startX - 1.0;
  if (!NSIsEmptyRect(line = NSIntersectionRect(*rects , line))) NSRectFill(line);
  line = [self bounds];				/* draw ruler line */
  line.origin.y = LINE_X;
  line.size.height = 1.0;
  line.origin.x = startX;
  line.size.width = [self bounds].size.width - startX;
  PSsetgray(NSBlack);
  if (!NSIsEmptyRect(line = NSIntersectionRect(*rects , line))) NSRectFill(line);
  clip = *rects;
  clip.origin.x = startX;
  clip.size.width = [self bounds].size.width - startX;
  if (!NSIsEmptyRect(clip = NSIntersectionRect(*rects , clip)))
  {
    s = unitinc[u] * (([self bounds].size.width - startX) / paperSize.width);
    curPos = (int)(NSMinX(clip) - startX);
    last = (int)(NSMaxX(clip) - startX);
    line.size.width = 1.0;
    [font set];
    n1 = curPos / s;
    n2 = last / s;
    for (i = n1; i <= n2; i++)
    {
      x = startX + i * s;
      line.origin.x =  x;
      for (j = 0; j <= 3; j++) if (unitmark[u][j])
      {
        if (!(i % unitmark[u][j]))
        {
          line.origin.y = LINE_X - unitlen[u][j];
          line.size.height = unitlen[u][j];
          NSRectFill(line);
          if (j == 0)
          {
            PSmoveto(x + NUM_X, descender + line.origin.y - 2.0);
	    sprintf(buf, "%d", unitmul[u] * i / unitmark[u][0]);
	    PSshow(buf);
	  }
	  break;
	}
      }
    }
  }
  return self;
}


- drawVertical:(const NSRect *)rects
{
    NSRect line, clip;
    int curPos, last, i, j, n1, n2, u;
    float s, y;
    char buf[10];
  u = [[NSApp currentDocument] getPreferenceAsInt: UNITS];
  PSsetgray(NSLightGray);
    NSRectFill(*rects);

    if (lastlp >= rects->origin.y && lastlp < rects->origin.y + rects->size.height) lastlp = -1.0;
    if (lasthp >= rects->origin.y && lasthp < rects->origin.y + rects->size.height) lasthp = -1.0;

    line = [self bounds];				/* draw bottom line */
    line.origin.x = [self bounds].size.width - 1.0;
    line.size.width = 1.0;
    PSsetgray(NSDarkGray);
    if (!NSIsEmptyRect(line = NSIntersectionRect(*rects , line))) NSRectFill(line);

    line = [self bounds];				/* draw ruler line */
    line.origin.x = [self bounds].size.width - LINE_X - 2.0;
    line.size.width = 1.0;
    PSsetgray(NSBlack);
    if (!NSIsEmptyRect(line = NSIntersectionRect(*rects , line))) NSRectFill(line);

    clip = *rects;
    line.origin.x++;
  if (!NSIsEmptyRect(clip = NSIntersectionRect(*rects , clip)))
  {
    s = unitinc[u] * (([self bounds].size.height) / paperSize.height);
    curPos = (int)(NSMinY(clip));
    last = (int)(NSMaxY(clip));
    line.size.height = 1.0;
    [font set];
    n2 = ([self bounds].size.height - curPos) / s;
    n1 = ([self bounds].size.height - last) / s;
    for (i = n1; i <= n2; i++)
    {
      y = [self bounds].size.height - (i * s);
      line.origin.y =  y - 1.0;
      for (j = 0; j <= 3; j++) if (unitmark[u][j])
      {
        if (!(i % unitmark[u][j]))
        {
          line.size.width = unitlen[u][j];
          NSRectFill(line);
          if (j == 0)
          {
            PSmoveto(line.origin.x + 1.0, y - 10.0);
	    sprintf(buf, "%d", unitmul[u] * i / unitmark[u][0]);
	    PSshow(buf);
	  }
	  break;
	}
      }
    }
  }
  return self;
}


- (void)drawRect:(NSRect)rect
{
  if ([self frame].size.width < [self frame].size.height)
  {
    [self drawVertical:&rect];
  }
  else
  {
    [self drawHorizontal:&rect];
  }
}


#define SETPOSITION(value) (isVertical ? (rect.origin.y = value - (absolute ? 0.0 : 1.0)) : (rect.origin.x = value + (absolute ? 0.0 : startX)))
#define SETSIZE(value) (isVertical ? (rect.size.height = value) : (rect.size.width = value))
#define SIZE (isVertical ? rect.size.height : rect.size.width)

- doShowPosition:(float)lp :(float)hp absolute:(BOOL)absolute
{
    NSRect rect;
    BOOL isVertical = ([self frame].size.width < [self frame].size.height);

    rect = [self bounds];

    if (!absolute && !isVertical) {
	if (lp < 0.0) lp -= startX;
	if (hp < 0.0) hp -= startX;
    }
    SETSIZE(1.0);
    lastlp = SETPOSITION(lp);
    NSHighlightRect(rect);
    lasthp = SETPOSITION(hp);
    NSHighlightRect(rect);
    return self;
}

- showPosition:(float)lp :(float)hp
{
    BOOL isVertical = ([self frame].size.width < [self frame].size.height);
    float scaleFactor;
    if (isVertical) scaleFactor = [self frame].size.height / [self bounds].size.height;
    else scaleFactor = [self frame].size.width / [self bounds].size.width;
    lp *= scaleFactor;
    hp *= scaleFactor;
    
    [self lockFocus];
    if (notHidden) [self doShowPosition:lastlp :lasthp absolute:YES];
    [self doShowPosition:lp :hp absolute:NO];
    [self unlockFocus];
    notHidden = YES;
    return self;
}

- hidePosition
{
    if (notHidden) {
	[self lockFocus];
	[self doShowPosition:lastlp :lasthp absolute:YES];
	[self unlockFocus];
	notHidden = NO;
    }
    return self;
}

@end
