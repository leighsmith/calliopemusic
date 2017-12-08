#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface RangeInspector:NSPanel
{
    id	slantmatrix;
    id	linematrix;
    id  stylematrix;
}

- set:sender;
- setProto:sender;
- preset;
- presetTo: (int) i;

@end
