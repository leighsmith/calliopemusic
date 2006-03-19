#import "winheaders.h"
#import <Foundation/NSArray.h>
#import "Graphic.h"

@class StaffObj;
@class Bracket;
@class GraphicView;
@class Page;

@interface System : Graphic
{
@public
    NSMutableArray *objs;			/* List of random objects on this system */
    NSMutableArray *staves;			/* List of staves */
    GraphicView *view;			/* backreference to our GraphicView */
    Page *page;			/* backreference to our Page */
  struct
  {
    unsigned int nstaves : 7;	/* number of staves */
    unsigned int pgcontrol : 3;	/* page break code */
    unsigned int haslink : 1;	/* staff linkage bar NOT USED */
    unsigned int equidist : 1;	/* make staff y-origins equidistant */
    unsigned int disjoint : 1;	/* polymetric format with noncoinciding bars */
    unsigned int syssep : 2;	/* to show system separator */
    unsigned int newbar : 1;	/* bar number changes sequence */
    unsigned int newpage : 1;   /* page number changes sequence */
  } flags;
  float width;			/* width within margins and indent*/
  short barnum;			/* number of first measure on this staff */
  NSString *style;
  float lindent, rindent;	/* left and right indents */
  float oldleft;		/* left margin changes while pagination (not cache: copy/paste) */
  float groupsep;		/* extra group separation */
  float expansion;		/* expansion factor (default 1.0) */
@private
  short pagenum;		/* system (actually page) number */
  float barbase;		/* bar number baseline offset */
  float height;			/* the height used in page balancing */
  float headroom;		/* included in height */
}


+ (void)initialize;
+ (int) oldSizeCount;
+ getOldSizes: (float *) lm : (float *) rm : (float *) sh;
+ myInspector;
- sysInvalid;
- (int) myIndex;
- (BOOL) lastSystem;
- initWithStaveCount: (int) n onGraphicView: (GraphicView *) v;
- initsys;
- mark;
- newFrom;
- newExtraction: (GraphicView *) v : (int) sn;
- measureSys: (NSRect *) r;
- resetSys;
- closeSystem;
- (float) myHeight;
- moveTo: (float) y;
- (void) moveBy: (float) x : (float) y;
- (float) headerBase;
- (float) footerBase;
- (float) leftMargin;
- (float) rightMargin;
- (float) leftIndent;
- (float) leftWhitespace;
- (float) rightIndent;
- makeNames: (BOOL) full : (GraphicView *) v;
- checkMargin;
- recalc;
- recalcHangers;
- setHangers;
- reShape;
- installLink;
- copyStyleTo: (System *) sys;
- (BOOL) hasTitles;
- (BOOL) hasLinkage;		/* system has a staff linkage bar */
- (BOOL) hasBracket: (Staff *) sp;
- (BOOL) spanningBracket: (Staff *) sp1 : (Staff *) sp2;
- (float) leftPlace;		/* x of first free space to left of system */
- (float) getBracketX: (Bracket *) b : (int) sz;
- linkobject: p;		/* put arg on objs list */
- unlinkobject: p;		/* remove p from objs list */
- newStaff: (float) y;		/* put a new staff near y */
- getstaff : (int) n;		/* return staff indexed by n */
- getVisStaff: (int) n;		/* same, but nil if hidden */
- lastStaff;
- (unsigned int)indexOfObject:s;	/* return index of given staff */
- (int) whereIs: (Staff *) sp;		/* code for location of staff */
- (BOOL) relinknote : (StaffObj *) p;		/* relink note to sensible destination */
- firststaff;			/* return first visible staff */
- nextstaff: s;			/* return next visible staff after s */
- (Staff *) findOnlyStaff: (float) y; 	 /* find staff closest to y */
- sameStaff: (Staff *) sp;
- (int) whichMarker: (Graphic *) p;
- (void)searchFor: (NSPoint) p :(NSMutableArray *)arr;	/* look for a hit in the system */
- (void)dealloc;
- draw: (NSRect) r : (BOOL) nso;
- drawHangers: (NSRect) r : (BOOL) nso;
- draw;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- recalcObjs;

/*!
  @brief Returns the headroom on this system.
 */
- (float) headroom;

/*!
  @brief Returns the page number this System is on.
 */
- (int) pageNumber;

/*!
  @brief Assigns the page number this System is on.
 */
- (void) setPageNumber: (int) newPageNumber;

@end
