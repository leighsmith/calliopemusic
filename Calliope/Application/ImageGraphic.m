#import "ImageGraphic.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "StaffObj.h"
#import "Staff.h"
#import "System.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "mux.h"
#import <AppKit/AppKit.h>

/*
  tricky because of change of coordinates from baseSize at baseScale.
  initial bounds = baseSize / staffScale
  display size = viewScale * (staffScale / baseScale);
*/

@implementation ImageGraphic : Hanger


+ (void)initialize
{
  if (self == [ImageGraphic class])
  {
      (void)[ImageGraphic setVersion: 0];
  }
  return;
}


+ myProto
{
  return nil;
}


+ myInspector
{
  return nil;
}


- (int) myLevel
{
  return -1;
}


- init
{
  [super init];
  gFlags.type = IMAGE;
  xoff = yoff = 0.0;
  client = nil;
  return self;
}


/*
 * Creates a new NXImage and sets it to be scalable and to retain
 * its data (which means that when we archive it, it will actually
 * write the TIFF or PostScript data into the stream).
 */

- initFromStream:(NSData *)stream allowAlpha:(BOOL)isAlphaOk
{
  float f;
  [super init];
  if (image = [[NSImage allocWithZone:[self zone]] initWithData:stream])
  {
    baseSize = [image size];
    [image setScalesWhenResized:YES];
    [image setDataRetained:YES];
    gFlags.subtype = isAlphaOk;
    bounds.size = baseSize;
    baseScale = f = [[NSApp currentDocument] staffScale];
    bounds.size.width = baseSize.width / f;
    bounds.size.height = baseSize.height / f;
  }
  else
  {
    [self release];
    self = nil;
  }
  return self;
}


- protoFromPasteboard: (NSPasteboard *) pb : (GraphicView *) v: (NSPoint) pt
{
  float f;
  int n;
  StaffObj *q;
  if (image = [[NSImage allocWithZone:[self zone]] initWithPasteboard:pb])
  {
    baseSize = [image size];
    [image setScalesWhenResized:YES];
    [image setDataRetained:YES];
    gFlags.subtype = 0;
    bounds.size = baseSize;
    baseScale = f = [[NSApp currentDocument] staffScale];
    bounds.size.width = baseSize.width / f;
    bounds.size.height = baseSize.height / f;
    q = client = [v isSelTypeCode: TC_STAFFOBJ : &n];
    xoff = pt.x - q->x;
    yoff = pt.y - q->y;
    bounds.origin.x = q->x + xoff;
    bounds.origin.y = q->y + yoff;
    [q linkhanger: self];
  }
  return self;
}


- protoFromPasteboard: (NSPasteboard *) pb : (GraphicView *) v
{
  float f;
//  int n;
//  StaffObj *q;
  if (image = [[NSImage allocWithZone:[self zone]] initWithPasteboard:pb])
  {
    baseSize = [image size];
    [image setScalesWhenResized:YES];
    [image setDataRetained:YES];
    gFlags.subtype = 0;
    bounds.size = baseSize;
    baseScale = f = [[NSApp currentDocument] staffScale];
    bounds.size.width = baseSize.width / f;
    bounds.size.height = baseSize.height / f;
    client = nil;
    xoff =  -0.5 * baseSize.width;
    yoff = -baseSize.height;
  }
  return self;
}

- (void)dealloc
{
  [image release];
  { [super dealloc]; return; };
}


- recalc
{
  bounds.origin.x = ((StaffObj *)client)->x + xoff;
  bounds.origin.y = ((StaffObj *)client)->y + yoff;
  return self;
}


- boundsDidChange
{
  float f;
  baseScale = f = [[NSApp currentDocument] staffScale];
  baseSize.width = f * bounds.size.width;
  baseSize.height = f * bounds.size.height;
  return self;
}


- (BOOL) getXY: (float *) x : (float *) y
{
  StaffObj *p = client;
  *x = xoff + p->x;
  *y = yoff + p->y;
  return YES;
}


- (BOOL) getHandleBBox: (NSRect *) r
{
  NSRect b = bounds;
  b = NSInsetRect(b , -2.0 , -2.0);
  *r  = NSUnionRect(b , *r);
  return YES;
}


- newFrom
{
  ImageGraphic *p = [[ImageGraphic alloc] init];
  p->gFlags = gFlags;
  p->image = [image copyWithZone:[self zone]];
  p->baseSize = baseSize;
  p->baseScale = baseScale;
  p->xoff = xoff;
  p->yoff = yoff;
  p->bounds = bounds;
  return p;
}



- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
  StaffObj *p;
  ImageGraphic *t;
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


/* add extra bits to indicate whether a corner hit */

- (BOOL) hit: (NSPoint)p
{
  return [super hitCorners: p];
}


- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  StaffObj *q = client;
  xoff = dx + p.x - q->x;
  yoff = dy + p.y - q->y;
  [self recalc];
  return YES;
}

/* Methods overridden from superclass */

- (BOOL) isOpaque
{
    return gFlags.subtype ? NO : YES;
}

- (float)naturalAspectRatio
{
    if (!baseSize.height) return 0.0;
    return baseSize.width / baseSize.height;
}


- (BOOL) isResizable
{
  return YES;
}


- (BOOL) performKey: (int) c
{
  BOOL r = NO;
  if (c == '.')
  {
    r = YES;
    gFlags.subtype ^= 1;
  }
  if (r)
  {
    [self reShape];
    return YES;
  }
  else return [super performKey: c];
}


/*
  draw NXImage object inside bounds.
  if opaque paint white background.
  SOVER the image.
 */

extern NSColor * backShade;

- drawMode: (int) m
{
  NSSize s, t;
  NSPoint p;
  float f;
  DrawDocument *doc;
  if (bounds.size.width < 1.0 || bounds.size.height < 1.0) return self;
  if (image)
  {
    doc = [NSApp currentDocument];
    f =  [doc viewScale] * ([doc staffScale] / baseScale);
    s.width = f * baseSize.width;
    s.height = f * baseSize.height;
    t = [image size];
    if (s.width != t.width || s.height != t.height) [image setSize:s];
    if (!(gFlags.subtype))
    {
      [backShade set];
      NSRectFill(bounds);
    }
    p.x = bounds.origin.x;
    p.y = bounds.origin.y + bounds.size.height;
    [image compositeToPoint:p operation:NSCompositeSourceOver];
    if (gFlags.selected && m) [self traceBounds];
  }
  return self;
}


/* Archiving */

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:image];
  [aCoder encodeSize:baseSize];
  [aCoder encodeValuesOfObjCTypes:"fff", &baseScale, &xoff, &yoff];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  [super initWithCoder:aDecoder];
  image = [[aDecoder decodeObject] retain];
  baseSize = [aDecoder decodeSize];
  [aDecoder decodeValuesOfObjCTypes:"fff", &baseScale, &xoff, &yoff];
  return self;
}

@end
