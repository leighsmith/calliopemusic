#import "winheaders.h"
#import "Hanger.h"


@interface Beam:Hanger
{
@public
  char splitp;			/* used to hold an offset from p for split end */
  struct
  {
    unsigned int horiz : 1;	/* force horizontal */
    unsigned int body : 4;	/* duration of */
    unsigned int dot : 2;	/*      broken beam segment */
    unsigned int broken : 1;	/* whether broken */
    unsigned int fixed : 1;	/* whether direction is fixed */
    unsigned int dir : 1;	/* whether slashed if graced */
    unsigned int taper : 2;	/* whether tapered beams */
  } flags;
  
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- proto: v : (NSPoint) pt : sp : sys : (Graphic *) g : (int) i;
- (void)dealloc;
- (float) modifyTick: (float) t;
- (BOOL) isClosed: l;
- setHanger;
- setHanger: (BOOL) f1 : (BOOL) f2;
- (void)removeObj;
- (int) beamType;
- (BOOL) isCrossingBeam;
- setBeamDir: (int) i;
- (BOOL) hit: (NSPoint) p;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- moveFinished: v;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
