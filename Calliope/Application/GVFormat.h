#import "winheaders.h"
#import "GraphicView.h"


@interface GraphicView(GVFormat)

- prevNote: p;
- nextNote: p;
- findSys: (float) y;
- sysOffAndPageNum: sys : (int *) sn : (int *) pn;
- (int) findPageOff: p;
- (BOOL) findPage: (int) n : (int) off;
- firstPage: sender;
- lastPage: sender;
- prevPage: sender;
- nextPage: sender;
- gotoPage: (int) n : (int) off;
- getSystem: sys : (int) off;
- findSysOfStyle: (NSString *) a;
- (BOOL) balanceOrAsk: p : (int) i : (int) j;
- resetPage: p;
- resetPagesOn: s1 : s2;
- resetPagelist: p : (int) i;
- (float) yBetween: (int) sn;
- saveSysLeftMargin;
- shuffleIfNeeded;
- setRunnerTables;
- doPaginate;
- balancePages;
- simplePaginate: sys : (int) i : (int) f;
- linkSystem: s : ns;
- thisSystem: s;
- nextStaff: sys : (int) sn;
- prevStaff: sys : (int) sn;
- (int) prevHyphened: sys : (int) sn : (int) vn : (int) vc;
- lastObject: sys : (int) sn : (int) t : (BOOL) all;
- flowTimeSig: sys;
- renumSystems;
- renumPages;
- setRanges;
@end
