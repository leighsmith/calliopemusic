#import "winheaders.h"
#import "System.h"
#import <AppKit/NSFont.h>


@interface System(SysCommands)

- showVerse;
- hideVerse: (int) n;
- shuffleNotes: (float) ol : (float) nl;
- (BOOL) changeVFont: (int) vn : (NSFont *) f;
- (NSFont *) getVFont: (int) vn : (int *) m;
- layBars: (int) n : (NSRect *) r;
- spillBar;
- grabBar;
- expandSys;
- findJoins;

@end


