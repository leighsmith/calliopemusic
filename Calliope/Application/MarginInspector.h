#import "winheaders.h"
#import <AppKit/AppKit.h>

@interface MarginInspector: NSPanel
{
    id  alignmatrix;
    id	lbindform;
    id	lmargcell;
    id	rbindform;
    id	rmargcell;
    id	vertmargform;
    id unitcell;
    id formatbutton;
}

- preset;
- set: sender;

@end
