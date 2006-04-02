/* $Id$ */

/*! @class 
  Responsible for the formatting methods of GraphicView class.
  Routines for handling the systemlist, pagelist, and formatting.
 */

#import "winheaders.h"
#import "GraphicView.h"

typedef enum {
    GV_OFFSET_FROM_CURRENT_PAGE = 0,
    GV_PAGE_INDEX = 1,
    GV_PRINTED_PAGE_NUMBER = 2,
    GV_SYSTEM_INDEX = 3,
    GV_OFFSET_FROM_CURRENT_SYSTEM = 4
} GraphicViewIndexMethod;

@interface GraphicView(GVFormat)

// Interface builder action methods.
- firstPage: sender;
- lastPage: sender;
- prevPage: sender;
- nextPage: sender;

- prevNote: (StaffObj *) p;
- nextNote: (StaffObj *) p;
- (System *) findSys: (float) y;
- sysOffAndPageNum: (System *) sys : (int *) sn : (int *) pn;
- (int) findPageOff: (StaffObj *) p;

/*!
 @brief find page by: off = 0: offset from current page, 1: by page index,
 2: by printed page number, 3: by system index,
 4: by index relative to currentsystem.
 Sets currentSystem to top of page except off = 3,4.
 @return YES if able to find the numbered page, NO if indexed outside the legal range of page numbers.
 */
- (BOOL) findPage: (int) pageNumber usingIndexMethod: (GraphicViewIndexMethod) indexMethod;

- gotoPage: (int) pageNumber usingIndexMethod: (GraphicViewIndexMethod) indexMethod;
- getSystem: sys offsetBy: (int) off;
- findSysOfStyle: (NSString *) a;
- (BOOL) balanceOrAsk: (Page *) p : (int) i : (int) f;
- resetPage: p;
- resetPagesOn:  (System *) s1 : (System *) s2;
- resetPagelist: (Page *) p : (int) i;
- (float) yBetween: (int) sn;
- saveSysLeftMargin;
- shuffleIfNeeded;
- setRunnerTables;
- doPaginate;
- balancePages;
- simplePaginate: (System *) sys : (int) i : (int) f;
- linkSystem: (System *) s : (System *) ns;
- thisSystem: (System *) s;
- (Staff *) nextStaff: sys : (int) sn;
- (Staff *) prevStaff: sys : (int) sn;
- (int) prevHyphened: sys : (int) sn : (int) vn : (int) vc;
- lastObject: sys : (int) sn : (int) t : (BOOL) all;
- flowTimeSig: (System *) until;
- renumSystems;
- renumPages;
- setRanges;

/*!
  @brief Returns the channels as an immutable NSArray.
 */
- (NSArray *) channels;

/*!
  @brief Returns the styles as an NSMutableArray.
 */
- (NSMutableArray *) styles;

/*!
  @brief Assigns the style list
 */
- (void) setStyles: (NSArray *) newStyles;

/*!
  @brief Assigns the system to the system list.
 */
- (void) addSystem: (System *) newSystem;

/*!
  @brief Returns the systems as an immutable NSArray.
 */
- (NSArray *) allSystems;

@end
