/*! $Id:$ */
/*!
  @class GNote
  @brief The class responsible for representing and displaying musical notes.
 */
#import "winheaders.h"
#import "TimedObj.h"

@interface GNote: TimedObj
{
@public
    NSMutableArray *headlist;
    float dotdx;
    unsigned char instrument;
    unsigned char showslash;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- (BOOL) reCache: (float) sy : (int) ss;
- (void)moveBy:(float)x :(float)y;
- reShape;
- reDefault;
- defaultStem: (BOOL) up;
- posRange: (int *) pl : (int *) ph;
- (int) posAboveBelow: (int) a;
- (float) boundAboveBelow: (int) a;
- (float) yAboveBelow: (int) a;
- (float) yMean;
- (float) headY: (int) n;
- (float) stemXoff: (int) stype;
- (float) stemXoffLeft: (int) stype;
- (float) stemXoffRight: (int) stype;
- (float) stemYoff: (int) stype;
- setStemTo: (float) s;
- getKeyString: (int) mc : (char *) ks;
- (int) getPatch;
- (int) midPosOff;
- (NSMutableArray *) tiedWith;
- (int) accAtPos: (int) pos;
- (BOOL)selectMember: (NSMutableArray *) sl : (int) d :(int)active;
- myChordGroup;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : (System *) sys : (int) alt;
- (BOOL) hit: (NSPoint) p;
- (BOOL) hitBeamAt: (float *) px : (float *) py;
- drawStem: (int) m;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
