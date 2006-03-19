#import "winheaders.h"
#import "GraphicView.h"

@interface GraphicView(GVGlobal)

- (BOOL) sysSameShape;
- extractStaves: (int) n : (char *) wantstaff;
- extractParts: (NSMutableArray *) pl;
/*! 
    @brief Returns the current list of parts being displayed.

    TODO should be returning NSArray.
 */
- (NSMutableArray *) partList;

- orderAllStaves: (char *) order;
- orderCurrStaves: (System *) sys : (char *) order;

@end
