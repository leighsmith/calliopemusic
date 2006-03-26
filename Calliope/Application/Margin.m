#import <AppKit/NSText.h>
#import "Page.h"
#import "Margin.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "MarginInspector.h"
#import "System.h"
#import "Staff.h"
#import "GVFormat.h"
#import "mux.h"

/*
  Margins are drawn as markers.
*/

@implementation Margin

#define SIZEBOX 8.0	/* size of the box used to represent a margin */

+ (void)initialize
{
  if (self == [Margin class])
  {
      (void)[Margin setVersion: 2];		/* class version, see read: */
  }
  return;
}


+ myInspector
{
  return [MarginInspector class];
}


static float defmarg[MaximumMarginTypes] = {36.0, 36.0, 36.0, 36.0, 72.0, 72.0, 0.0, 0.0, 0.0, 0.0};

- init
{
  int i = MaximumMarginTypes;
  [super init];
  gFlags.type = MARGIN;
  while (i--) margin[i] = defmarg[i];
  format = 0;
  alignment = 0;
  return self;
}


- newFrom
{
  int i = MaximumMarginTypes;
  Margin *n = [[Margin alloc] init];
  while (i--) n->margin[i] = margin[i];
  n->format = format;
  n->alignment = alignment;
  return n;
}


/*
  setrunnertables and tidying markers done by delete:
*/

- (void)removeObj
{
    [self retain];
    [client unlinkobject: self];
    [self release];
}


/* set the margins for page p */

- setPageTable: (Page *) p
{
    MarginType i = MaximumMarginTypes;
    while (i--) 
	[p setMarginType: i toSize: margin[i]];
    [p setFormat: format];
    [p setAlignment: alignment];
    return self;
}


- (float) leftMargin
{
  return margin[0] / [[DrawApp currentDocument] staffScale];
}


- (float) rightMargin
{
  return margin[1] / [[DrawApp currentDocument] staffScale];
}


- (float) headerBase
{
  return margin[2] / [[DrawApp currentDocument] staffScale];
}


- (float) footerBase
{
  return margin[3] / [[DrawApp currentDocument] staffScale];
}


- (float) topMargin
{
  return margin[4] / [[DrawApp currentDocument] staffScale];
}


- (float) bottomMargin
{
  return margin[5] / [[DrawApp currentDocument] staffScale];
}


- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  return NO;
}


- drawMode: (int) m
{
  System *s = client;
  Staff *sp = [s firststaff];
  float x = [s leftWhitespace] + s->width + 20;
  float y = sp->y + [s whichMarker: self] * (SIZEBOX + 3);
  coutrect(x, y, SIZEBOX, SIZEBOX, 0.0, m);
  crect(x, y, (0.25 * SIZEBOX), SIZEBOX, m);
  crect(x + (0.75 * SIZEBOX), y, (0.25 * SIZEBOX), SIZEBOX, m);
  return self;
}


- draw
{
  return [self drawMode: markmode[gFlags.selected]];
}


/* Archiving methods */


- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v = [aDecoder versionForClassName:@"Margin"];
  [super initWithCoder:aDecoder];
  if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"@cc",  &client, &format, &alignment];
    [aDecoder decodeArrayOfObjCType:"f" count:MaximumMarginTypes at:margin];
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"@c",  &client, &format];
    [aDecoder decodeArrayOfObjCType:"f" count:MaximumMarginTypes at:margin];
    alignment = 0;
  }
  else if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"@",  &client];
    [aDecoder decodeArrayOfObjCType:"f" count:MaximumMarginTypes at:margin];
    format = 0;
    alignment = 0;
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeValuesOfObjCTypes:"@cc",  &client, &format, &alignment];
  [aCoder encodeArrayOfObjCType:"f" count:MaximumMarginTypes at:margin];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setObject:client forKey:@"client"];
    [aCoder setInteger:format forKey:@"format"];
    [aCoder setInteger:alignment forKey:@"alignment"];
    [aCoder setInteger:MaximumMarginTypes forKey:@"MaximumMarginTypes"];
    for (i = 0; i < MaximumMarginTypes; i++) [aCoder setFloat:margin[i] forKey:[NSString stringWithFormat:@"margin%d",i]];
}

@end
