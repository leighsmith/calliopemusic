/*!
  $Id$ 

  @class System
  @brief A System groups a collection of staves to be performed simultaneously.

  Typically each stave in a system is for a different instrument, or hand,
  in the case of a keyboard instrument.
 */
#import "winheaders.h"
#import <Foundation/NSArray.h>
#import "Graphic.h"

@class StaffObj;
@class Bracket;
@class GraphicView;
@class Page;

@interface System: Graphic
{
@private
    /*! @var staves Array of staves */
    NSMutableArray *staves;			
    short pagenum;		/*!< system (actually page) number */
    float barbase;		/*!< bar number baseline offset */
    float height;		/*!< the height used in page balancing */
    float headroom;		/*!< included in height */
    Page *page;			/*!< backreference to our Page */
@public
    NSMutableArray *nonStaffGraphics;   /*!< Array of random graphics on this system not attached to a staff */
    GraphicView *view;			/*!< backreference to our GraphicView */
    struct
    {
	unsigned int nstaves : 7;	/* number of staves */ // Can now be defined protected. ideally derive from [staves count] or [self numberOfStaves]
	unsigned int pgcontrol : 3;	/*!< page break code */
	unsigned int haslink : 1;	/*!< staff linkage bar NOT USED */
	unsigned int equidist : 1;	/*!< make staff y-origins equidistant */
	unsigned int disjoint : 1;	/*!< polymetric format with noncoinciding bars */
	unsigned int syssep : 2;	/*!< to show system separator */
	unsigned int newbar : 1;	/*!< bar number changes sequence */
	unsigned int newpage : 1;   /*!< page number changes sequence */
    } flags;
    float width;			/*!< width within margins and indent */
    short barnum;			/*!< number of first measure on this staff */
    NSString *style;
    float lindent, rindent;	/*!< left and right indents */
    float oldleft;		/*!< left margin changes while pagination (not cache: copy/paste) */
    float groupsep;		/*!< extra group separation */
    float expansion;		/*!< expansion factor (default 1.0) */
}


+ (void) initialize;
+ (int) oldSizeCount;
+ getOldSizes: (float *) lm : (float *) rm : (float *) sh;
+ myInspector;
- sysInvalid;
- (int) myIndex;

/*!
  @brief Returns the GraphicView this System resides on.
*/
- (GraphicView *) pageView;

/*!
  @brief Assign the page view (GraphicView) instance to the receiving System.
 
  This is typically only used to correct old decoding problems.
 */
- (void) setPageView: (GraphicView *) newPageView;

- (BOOL) lastSystem;

/*!
  @brief Initialise the System instance with the given number of staves, on the given GraphicView page view.
 
  TODO This should take an extra parameter establishing the model on which the System is stored, independent of it's page view (GraphicView).
  This will happen when GraphicView is split.
 */
- initWithStaveCount: (int) n onGraphicView: (GraphicView *) v;
- initsys;

- mark;

/*!
  @brief Make and return a new system using the receiver as a template.
  
  The number of staves, clef, keysignature and brackets are duplicated.
  An autoreleased System is returned.
 */
- (System *) newFormattedSystem;

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
- margin;
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
- linkobject: p;		/* put arg on nonStaffGraphics list */
- unlinkobject: p;		/* remove p from nonStaffGraphics list */
- (BOOL) relinknote : (StaffObj *) p;		/* relink note to sensible destination */

// Staff manipulation.

/*!
   @brief return index of given staff 
 */
- (unsigned int) indexOfStaff: (Staff *) s;

/*!
  @brief Returns the number of staves (i.e Staff instances).
 */
- (int) numberOfStaves;

/*!
  @brief put a new staff near y 
 */
- newStaff: (float) y;

/*!
  @brief Return an array of all staves.
 */
- (NSArray *) staves;

/*!
  @brief Return staff indexed by n 
 */
- (Staff *) getStaff: (int) n;

/*!
   @brief Return staff indexed by n, but return nil if hidden 
 */
- getVisStaff: (int) n;

/*!
  @brief Deletes any staves which have been marked hidden.
 */
- (void) deleteHiddenStaves;

/*!
  @brief Appends the given staff to the current list of staves of this system.
 */
- (void) addStaff: (Staff *) newStaff;

/*!
  @brief Reorders the staves according to the index map.
 */
- (void) orderStavesBy: (char *) order;

/*!
  @brief Returns the current scale of the staff.
 
  This is enquired via the System's current GraphicView.
 */
- (float) staffScale;

- lastStaff;
- (int) whereIs: (Staff *) sp;		/* code for location of staff */
- firststaff;			/* return first visible staff */
- nextstaff: s;			/* return next visible staff after s */
- (Staff *) findOnlyStaff: (float) y; 	 /* find staff closest to y */
- sameStaff: (Staff *) sp;


- (int) whichMarker: (Graphic *) p;
- (void) searchFor: (NSPoint) p inObjects: (NSMutableArray *) arr;	/* look for a hit in the system */
- (void) dealloc;
- draw: (NSRect) r nonSelectedOnly: (BOOL) nso;
- drawHangers: (NSRect) r nonSelectedOnly: (BOOL) nso;
- draw;
- (id) initWithCoder:(NSCoder *)aDecoder;
- (void) encodeWithCoder:(NSCoder *)aCoder;
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

/*!
  @brief Assigns the Page this System is on.
*/
- (void) setPage: newPage;

/*!
  @brief Returns the Page this System is on.
*/
- (Page *) page;

@end
