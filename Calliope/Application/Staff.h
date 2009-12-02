/*! 
  $Id$ 

  @class Staff
  @brief Represents a single staff, several of which are combined in a System.
  See COPYING for license usage.
 */
#import "winheaders.h"
#import <Foundation/NSArray.h>
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>
#import "Graphic.h"
#import "StaffObj.h"
#import "TextGraphic.h"
#import "System.h"

#define MAXTEXT 16
#define MINPAD 4 /* = nature[0] */

/* for next version,
  spacing ought to be from float table
*/

@interface Staff: Graphic <NSCopying>
{
@public
    struct
    {
	unsigned int nlines : 4;	/* number of lines */
	unsigned int spacing : 4;	/* pixels between positions */
	unsigned int subtype : 2;	/* type of notation */
	unsigned int haspref : 1;	/* has prefatory staff */
	unsigned int hasnums : 1;	/* has extra bar numbers */
	unsigned int hidden : 1;	/* staff is hidden */
	unsigned int topfixed : 1;	/* topmarg is an exact distance */
    } flags;
    float voffa, voffb;		/*!< verse offsets */
    float vhigha;		/*!< amount of space taken by verses above Staff */
    float vhighb;		/*!< amount of space taken by verses below Staff */
    float barbase;		/*!< barnumber baseline */
    float topmarg;		/*!< amount of headroom */
    float botmarg;		/*!< used for equidistant spaff spacing */
    float pref1, pref2;		/*!< start and end of preface */
    NSMutableArray *notes;	/*! @var notes Array of things on the staff. */
@private
    NSString *part;		/*!< The part name for this Staff instance. */
    System *mysys;		/*!< backpointer to the encompassing System. */
    float y;			/*!< vertical position on the GraphicView */
}

+ (void) initialize;
- (void) dealloc;
- copyWithZone: (NSZone *) zone;

- sysInvalid;

/*!
  @brief Assign the System this Staff instance resides within.
 */
- (void) setSystem: (System *) newSystem;

/*!
  @brief Return the System this Staff instance resides within.
 */
- (System *) mySystem;

/*!
  @brief Return an NSArray of StaffObjs on the this Staff instance.
 */
// - (NSArray *) notesOnStaff;

- recalc;
- mark;
- (float) getHeadroom;
- trimVerses;
- measureStaff;
- resetStaff: (float) y;
- (void)moveBy:(float)x :(float)y;
- setHangers;
- recalcHangers;
- linknote: (StaffObj *) p;			/* link object p into self */
- staffRelink: p;		/* lazy relink if already there */
- unlinknote: p;
- (int) brackLevel;
- (BOOL) atTopOf: (int) bt;
- getNote: (int) i;
- nextNote: q;
- (TextGraphic *) makeName: (BOOL) full;
- prevNote: p;
- skipObjs: (float) x;
- (int) skipSigIx: (int) i;
- skipSig: (StaffObj *) p : (float) xi : (float *) x;
- (int) indexOfNoteAfter: (float) x;
- (float) staffHeight;
- (float) yOfCentre;
- (float) yOfTop;
- (float) yOfBottom;
- (float) yOfBottomPos: (int) p;
- (float) yOfStaffPosition: (int) p;
- (float) xOfHyphmarg;
- (float) xOfEnd;
- (int) posOfBottom;
- (int) myIndex;
- defaultNoteParts;
- (NSString *) getInstrument;

/*!
  @brief Returns the part name of the Staff.
 */
- (NSString *) partName;

/*!
  @brief Assigns the part name of the Staff.
 */
- (void) setPartName: (NSString *) newPartName;

/*!
  @brief Returns if the Staff instance is hidden from view.
 */
- (BOOL) isInvisible;

/*!
  @brief Assigns if the Staff instance is hidden from view.
 */
- (void) setInvisible: (BOOL) yesOrNo;

- (int) getChannel;
- (BOOL) hasAnyPart: (NSMutableArray *) l;
- (int) findPos: (float) y;
- searchType: (int) t :  (StaffObj *) q;
- findClef: k;
- (int) getKeyThru: (StaffObj *) p : (char *) ks;
- (float) firstTimedBefore:  (StaffObj *) p;
- (BOOL) textedBefore: (StaffObj *) p : (int) i;	
- (BOOL) vocalBefore: (StaffObj *) p : (int) i;	
- nextVersed: (StaffObj *) p : (int) vn;
- prevVersed: (StaffObj *) p : (int) vn;
- (float) endMelisma: (StaffObj *) p : (int) vn;
- (int) lastHyphen: (int) n : (int) v;
- hideVerse: (int) n;
- (int) firstClefCentre;
- packLeft;
- (void) searchFor: (NSPoint) p inObjects: (NSMutableArray *) l;
- resizeNotes: (int) ds;
- (BOOL) allRests;
- (int) countRests;
- drawBarnumbers: (int) mode;
- draw: (NSRect) r nonSelectedOnly: (BOOL) nso;
- drawHangers: (NSRect) r nonSelectedOnly: (BOOL) nso;
- draw;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
@end
