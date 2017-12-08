#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface AccentInspector:NSPanel
{
    id	placematrix;
    id	nummatrix;
    id	typematrix;
    id  accswitch;
}

- set:sender;
- setdefault:sender;
- setnumber:sender;
- setProto: sender;
- preset;
- presetTo: (int) i;

@end
