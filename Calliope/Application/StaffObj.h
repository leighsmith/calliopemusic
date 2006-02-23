#import "winheaders.h"
#import <AppKit/NSFont.h>
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSArray.h>
#import "Graphic.h"
#import "GraphicView.h"
#import "Verse.h"
#import "Hanger.h"
#import "NoteGroup.h"


/*
  even though only timed and voiced objects know about parts, voices and stamps,
  they are stored for all staff objects for various reasons.
*/

@interface StaffObj:Graphic
{
@public
  NSMutableArray *hangers;		/* List of hangers */
  NSMutableArray *verses;			/* List of Verse */
  id mystaff;			/* backpointer */
  float x, y;			/* coordinates */
  float stamp;			/* cache (not archived) */
  float duration;		/* cache (not archived) */
  char tag;			/* cache (not archived) TRY NOT TO NEED THIS */
  char versepos;		/* how many verses above note */
  char p;			/* staff position */
  char selver;			/* selected verse */
  char isGraced;		/* 1 = graced object, 2 = backwards-timed */
  unsigned char voice;		/* voice number */
  NSString *part;			/* part name */
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
- (int) posOfY: (float) y;
- (float) yOfPos: (int) p;
- (float) yOfTopLine;
- (float) yOfBottomLine;
- mySystem;
- myView;
- (int) sysNum;
- (int) myIndex;
- (NSString *) getInstrument;
- (int) whereInstrument;
- (NSString *) getPart;
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
- findMetro;
- (BOOL) hasVoltaBesides: (NoteGroup *) p;
- (BOOL) hasCrossingBeam;
- (int) hangerAcc;
- (BOOL) hangerAccSticks;
- (int) hangerOtt;
- (void)searchFor: (NSPoint) p :(NSMutableArray *)arr;
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
- drawHangers: (NSRect) r : (BOOL) nso;
- drawVerses: (NSRect) r : (BOOL) nso;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
