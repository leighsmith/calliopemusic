#import "winheaders.h"
#import "Hanger.h"

/*
  gFlags.subtype: 0=head, 1=tail, 2=top, 3=bottom
*/

#define ACCSIGNS 4

@interface Accent:Hanger
{
@public
  char sign[ACCSIGNS];
  float xoff, yoff;
  char accstick;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- (BOOL) getXY: (float *) x : (float *) y;
- (int) hasAccidental;
- (int) hasOttava;
- (int) getDefault: (int) i;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- (BOOL) performKey: (int) c;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
