#import "winheaders.h"
#import "GraphicView.h"

@interface GraphicView(NSMenu)

/* Validates whether a menu command makes sense now */

- (BOOL)validateMenuItem:(NSMenuItem *)menuCell;

@end
