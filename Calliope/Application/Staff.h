#import "winheaders.h"
#import "Graphic.h"
#import "StaffObj.h"
#import <Foundation/NSArray.h>
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>

#define MAXTEXT 16
#define MINPAD 4 /* = nature[0] */

/* for next version,
  spacing ought to be from float table
*/

@interface Staff:Graphic
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
    NSString *part;
  float voffa, voffb;		/* verse offsets */
  float vhigha;			/* amount of space taken by verses above */
  float vhighb;			/* amount of space taken by verses below */
  float y;			/* position */
  float barbase;		/* barnumber baseline */
  float topmarg;		/* amount of headroom */
  float botmarg;		/* use for equidistant spaff spacing */
  float pref1, pref2;		/* start and end of preface */
  id mysys;			/* backpointer */
  NSMutableArray *notes;			/* List of things on the staff */
}

+ (void)initialize;

- sysInvalid;
- initstaff: s;				/* init a staff in system s */
- recalc;
- mark;
- (float) getHeadroom;
- trimVerses;
- measureStaff;
- resetStaff: (float) y;
- (void)dealloc;
- newFrom;
- (void)moveBy:(float)x :(float)y;
- setHangers;
- recalcHangers;
- linknote: p;			/* link object p into self */
- staffRelink: p;		/* lazy relink if already there */
- unlinknote: p;
- (int) brackLevel;
- (BOOL) atTopOf: (int) bt;
- getNote: (int) i;
- nextNote: q;
- makeName: (BOOL) full;
- prevNote: p;
- skipObjs: (float) x;
- (int) skipSigIx: (int) i;
- skipSig: p : (float) xi : (float *) x;
- (int) indexOfNoteAfter: (float) x;
- (float) staffHeight;
- (float) yOfCentre;
- (float) yOfTop;
- (float) yOfBottom;
- (float) yOfBottomPos: (int) p;
- (float) yOfPos: (int) p;
- (float) xOfHyphmarg;
- (float) xOfEnd;
- (int) posOfBottom;
- (int) myIndex;
- defaultNoteParts;
- (NSString *) getInstrument;
- (NSString *) getPart;
- (int) getChannel;
- (BOOL) hasAnyPart: l;
- (int) findPos: (float) y;
- searchType: (int) t :  q;
- findClef: k;
- (int) getKeyThru: (StaffObj *) p : (char *) ks;
- (float) firstTimedBefore:  p;
- (BOOL) textedBefore : p : (int) i;	
- (BOOL) vocalBefore : p : (int) i;	
- nextVersed: p : (int) vn;
- prevVersed: p : (int) vn;
- (float) endMelisma: p : (int) vn;
- (int) lastHyphen: (int) n : (int) v;
- hideVerse: (int) n;
- (int) firstClefCentre;
- packLeft;
- (void)searchFor: (NSPoint) p :(NSMutableArray *)l;
- resizeNotes: (int) ds;
- (BOOL) allRests;
- (int) countRests;
- drawBarnumbers: (int) mode;
- draw: (NSRect) r : (BOOL) nso;
- drawHangers: (NSRect) r : (BOOL) nso;
- draw;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
@end
