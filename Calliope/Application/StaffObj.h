/*!
  $Id$ 

  @class StaffObj
  @brief Describes Graphic objects which reside on a Staff.

  Even though only timed and voiced objects know about parts, voices and stamps,
  they are stored for all staff objects for various reasons.
 */
#import "winheaders.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "Graphic.h"
#import "GraphicView.h"
#import "Verse.h"
#import "Hanger.h"
#import "NoteGroup.h"
#import "Metro.h"


@interface StaffObj: Graphic <NSCopying>
{
@public
    NSMutableArray *hangers;	/* Array of hangers */
    NSMutableArray *verses;	/* Array of Verse */
    float x, y;			/* coordinates */
    float stamp;			/* cache (not archived) */
    float duration;		/* cache (not archived) */
    char tag;			/* cache (not archived) TRY NOT TO NEED THIS */
    char versepos;		/* how many verses above note */
    char staffPosition;		/* staff position */
    char selver;			/* selected verse */
    char isGraced;		/* 1 = graced object, 2 = backwards-timed */
    unsigned char voice;		/* voice number */
@protected
    NSString *part;		/* part name */
    Staff *mystaff;		/* backpointer */
}

+ (void)initialize;

- init;
- reShape;
- reDefault;
- transBounds: (NSRect *) b : (int) t;
- (BOOL) getXY: (float *) x : (float *) y;
- (float) leftBearing: (BOOL) enc;
- (float) rightBearing: (BOOL) enc;
- (void)moveBy:(float)x :(float)y;
- (BOOL) reCache: (float) y : (int) ss;
- (int) barCount;
- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
- (float) noteEval: (BOOL) f;
- (int) getSpacing;
- (int) getLines;
- (int) midPosOff;
- (void) getKeyInfo: (int *) s : (int *) n : (int *) c;
- (float) headY: (int) n;
- (float) yMean;
- (float) wantsStemY: (int) a;
- (int) posAboveBelow: (int) a;
- (float) boundAboveBelow: (int) a;
- (float) yAboveBelow: (int) a;
- (BOOL) validAboveBelow: (int) a;
- (int) staffPositionOfY: (float) y;
- (float) yOfStaffPosition: (int) p;
- (float) yOfTopLine;
- (float) yOfBottomLine;

/*!
  @brief Returns the parent system.
 */
- (System *) mySystem;

/*!
  @brief Returns the parent encompassing GraphicView (TODO eventually the NotationScore).
 */
- (GraphicView *) pageView;

/*!
  @brief Returns the staff this object resides on.
 */
- (Staff *) staff;

/*!
  @brief Assigns the backpointer to the Staff this StaffObj is part of.
 */
- (void) setStaff: (Staff *) newStaff;

- (int) sysNum;
- (int) myIndex;

/*!
  @brief Returns the voice identifier, with a default value if the voice has not been assigned.
 */
- (int) voiceWithDefault: (int) defaultVoiceId;

- (NSString *) getInstrument;
- (int) whereInstrument;

/*!
  @brief Returns the part name of this StaffObj instance.
 */
- (NSString *) partName;

/*!
  @brief Assigns a new part name.
 */
- (void) setPartName: (NSString *) newPartName;

- (int) getChannel;
- makeName: (int) i;
- (float) xOfStaffEnd: (BOOL) e;
- verseWidths: (float *) tb : (float *) ta;
- (void)removeObj;
- (BOOL) linkPaste: (GraphicView *) v;
- linkhanger: q;
- unlinkhanger: q;
- unlinkverse: q;
- markHangers;
- markHangersExcept: (Hanger *) p;
- setHangers;
- setHangersExcept: (int) t;
- setHangersOnly: (int) t;
- setOwnHangers;
- recalcHangers;
- resizeHangers: (int) ds;
- (BOOL) hasHanger: h;
- (int) hasHangers;
- (BOOL)selectHangers:(id)sl : (int) b;
- closeHangers: (NSMutableArray *) l;
- (Metro *) findMetro;
- (BOOL) hasVoltaBesides: (NoteGroup *) p;
- (BOOL) hasCrossingBeam;
- (int) hangerAcc;
- (BOOL) hangerAccSticks;
- (int) hangerOtt;
- (void) searchFor: (NSPoint) p inObjects: (NSMutableArray *) arr;
- (BOOL) hasAnyVerse;
- trimVerses;
- recalcVerses;
- setVerses;
- justVerses;
- (Verse *) verseOf: (int) i;
- (BOOL) hasVerseText: (int) i;
- (BOOL) continuesLine: (int) i;
- (int) verseHyphenOf: (int) i;
- copyVerseFrom: (StaffObj *) p;
- (int) verseNeighbour: (StaffObj *) g;
- (BOOL) stopsVerse;
- (NSFont *) getVFont;
- (BOOL) changeVFont: (NSFont *) f : (BOOL) all;
- (int) maxGroupLevel;
- markGroups;
- renumberGroups: (int) lev;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : (System *) sys : (int) alt;
- moveFinished: (GraphicView *) v;
- (BOOL) performKey: (int) c;
- (int)keyDownString:(NSString *)cc;
- (float)verseOrigin; /* sb: inherited but only used by NeumeNew */
- drawHangers: (NSRect) r nonSelectedOnly: (BOOL) nso;
- drawVerses: (NSRect) r nonSelectedOnly: (BOOL) nso;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
