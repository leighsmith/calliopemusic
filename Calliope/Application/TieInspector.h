#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface TieInspector:NSPanel
{
    id	stylematrix;
    id	edbutton;
    id fixmatrix;
    id placematrix;
    id dashbutton;
    id flatmatrix;
}

- set:sender;
- preset;
- setImageFrameStyle:sender;
- setProto:sender;
- presetTo: (int) i;

@end
