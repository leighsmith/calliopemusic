#import "winheaders.h"
#import <AppKit/NSPanel.h>
#import <AppKit/NSFont.h>

@interface RunInspector:NSPanel
{
    id	placematrix;
    id	scroller;
    id	typematrix;
    id	headfootmatrix;
    id	alignmatrix;
}

- set: sender;
- preset;
- runner;
- align: sender;
-(void)reflectFont;//sb
- insertVar: sender;

@end
