/* $Id:$ */

/*! @class 
  Responsible for the formatting methods of GraphicView class.
  Routines for handling the systemlist, pagelist, and formatting.
 */

#import "winheaders.h"
#import "GraphicView.h"


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
 find page by: off = 0: offset from current page, 1: by page index,
 2: by printed page number, 3: by system index,
 4: by index relative to currentsystem.
 Sets currentSystem to top of page except off = 3,4.
 */
- (BOOL) findPage: (int) n usingIndexMethod: (int) indexMethod;

- gotoPage: (int) n usingIndexMethod: (int) off;
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

@end
