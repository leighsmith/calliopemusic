#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface NeumeInspector:NSPanel
{
    id	accmatrix;
    id	typematrix;
    id	incmatrix;
    id bodymatrix;
    id dotmatrix;
    id halfSizeSwitch;
}

- set:sender;
- setProto:sender;
- preset;
- presetTo: (int) i;

@end
