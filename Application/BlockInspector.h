#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface BlockInspector:NSPanel
{
    id	typematrix;
    id  sizeform;
}

- setProto: sender;
- set:sender;
- preset;
- presetTo: (int) i;

@end
