#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface MetroInspector:NSPanel
{
    id	dot1matrix;
    id	tempoform;
    id	dot2matrix;
    id	note2matrix;
    id	typematrix;
    id	note1matrix;
    id  setButton;
}

- set:sender;
- preset;
- setChoice: sender;
- setProto: sender;
- presetTo: (int) i;
- hitNote2:sender;

@end
