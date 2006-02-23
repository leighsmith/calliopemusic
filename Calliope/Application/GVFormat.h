#import "winheaders.h"
#import "GraphicView.h"


@interface GraphicView(GVFormat)

- prevNote: (StaffObj *) p;
- nextNote: (StaffObj *) p;
- (System *) findSys: (float) y;
- sysOffAndPageNum: (System *) sys : (int *) sn : (int *) pn;
- (int) findPageOff: (StaffObj *) p;
- (BOOL) findPage: (int) n : (int) off;
- firstPage: sender;
- lastPage: sender;
- prevPage: sender;
- nextPage: sender;
- gotoPage: (int) n : (int) off;
- getSystem: sys : (int) off;
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
