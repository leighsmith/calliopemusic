#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface RestInspector:NSPanel
{
    id choicematrix;
    id	dotmatrix;
    id	stylematrix;
    id	numbarsform;
    id	timematrix;
    id toolbutton;
    id voiceform;
    id objmatrix;
}

- set:sender;
- preset;
- setChoice: sender;
- setProto: sender;
- presetTo: (int) i;

@end
