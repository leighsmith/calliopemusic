#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface KeyInspector:NSPanel
{
    id cancelswitch;
    id nummatrix;
    id signmatrix;
    id styleswitch;
    id octavematrix;
    id transswitch;
    id octavebutton;
}

- setConvChoice: sender;
- setCustChoice: sender;
- setProto:sender;
- set:sender;
- presetTo: (int) i;
- preset;

@end
