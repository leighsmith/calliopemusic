#import "winheaders.h"
#import "Hanger.h"
#import <AppKit/NSImage.h>

/* subtype has whether alphaOK */

@interface ImageGraphic : Hanger
{
  NSImage *image;		/* an NXImage object */
  float xoff, yoff;
  float baseScale;
  NSSize baseSize;		/* size in base coordinates*/
}

+ (void)initialize;
+ myProto;
+ myInspector;

- (int) myLevel;
- init;
- initFromStream:(NSData *)stream allowAlpha:(BOOL)alphaOk;
- protoFromPasteboard: (NSPasteboard *) pb : v: (NSPoint) pt;
- protoFromPasteboard: (NSPasteboard *) pb : v;
- (void)dealloc;
- recalc;
- newFrom;
- (BOOL) getXY: (float *) x : (float *) y;
- (BOOL) isResizable;
- (BOOL) linkPaste: v : sl;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- (BOOL)hit:(NSPoint)p;
- (BOOL) getHandleBBox: (NSRect *) b;

- (BOOL)isOpaque;
- (float)naturalAspectRatio;
- drawMode: (int) m;

/* Archiving methods */

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end

