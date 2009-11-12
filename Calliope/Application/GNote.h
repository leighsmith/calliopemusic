/*! $Id$ */
/*!
  @class GNote
  @brief The class responsible for representing and displaying musical notes. 
  @description A Note consists of a number of NoteHeads.
 */
#import "winheaders.h"
#import "TimedObj.h"
#import "NoteHead.h"

// TODO should be renamed NoteGraphic
@interface GNote: TimedObj
{
@private
    /*! Whether the note is attached to a slash. */
    unsigned char showSlash;
    /*! Horizontal offset of dot from the note heads. */
    float dotdx;
    /*! Array of NoteHeads comprising this GNote. */
    NSMutableArray *headlist;
    /*! Instrument handle playing the note. */
    unsigned char instrument;
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

- (void) setStemLengthTo: (float) s;

/*!
  Returns YES if this GNote shows a slash glyph.
 */
- (BOOL) showSlash;

/*!
 Assigns whether this GNote shows a slash glyph.
 */
- (void) setShowSlash: (BOOL) willShowSlash;

/*!
  Assigns the offset of the dot from the note heads.
 */
- (void) setDotOffset: (float) dotOffset;

/*!
   Returns the offset of the dot from the note heads.
 */
- (float) dotOffset;


- getKeyString: (int) mc : (char *) ks;

/*!
   Returns the number of note heads associated with this GNote instance.
 */
- (int) numberOfNoteHeads;

/*!
  Returns the autoreleased NoteHead instance numbered by the given index.
 */
- (NoteHead *) noteHead: (int) noteHeadIndex;

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

/*!
  @brief Returns YES if this instance contains the given point.
 */
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
