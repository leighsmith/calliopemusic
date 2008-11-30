/*! $Id$ */
/*!
  @class GNote
  @brief The class responsible for representing and displaying musical notes.
 */
#import "winheaders.h"
#import "TimedObj.h"

// TODO should be renamed NoteGraphic
@interface GNote: TimedObj
{
@private
    unsigned char showSlash;
    float dotdx;
    unsigned char instrument;
@public
    NSMutableArray *headlist;
}

+ (void) initialize;
+ myInspector;
+ myPrototype;

- init;
- (void) dealloc;
- (BOOL) reCache: (float) sy : (int) ss;
- (void) moveBy: (float) x : (float) y;
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

- (BOOL) showSlash;

- (void) setShowSlash: (BOOL) willShowSlash;

- (void) setDotOffset: (float) dotOffset;

- (float) dotOffset;

- (void) setStemLengthTo: (float) s;

- getKeyString: (int) mc : (char *) ks;

/*!
    Returns the instrument patch number.
 */
- (int) getPatch;

/*!
  Assigns the patch (currently doesn't increment it).
 */
- (void) setPatch: (unsigned char) newPatch;

- (int) midPosOff;
- (NSMutableArray *) tiedWith;
- (int) accAtPos: (int) pos;
- (BOOL)selectMember: (NSMutableArray *) sl : (int) d :(int)active;
- myChordGroup;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : (System *) sys : (int) alt;
- (BOOL) hit: (NSPoint) p;
- (BOOL) hitBeamAt: (float *) px : (float *) py;
- drawStem: (int) m;

/*!
 Draws the note in the given drawing Mode.
 */
- drawMode: (int) drawingMode;

- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
