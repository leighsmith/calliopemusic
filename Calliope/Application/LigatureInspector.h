#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface LigatureInspector:NSPanel
{
    id	stylematrix;
    id edbutton;
    id fixmatrix;
    id placematrix;
    id dashbutton;
}

- set:sender;
- preset;
- setProto:sender;
- presetTo: (int) i;

@end
