#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface NoteGroupInspector:NSPanel
{
    id typematrix;
    id freematrix;
    id hdtlmatrix;
}

- set:sender;
- setProto:sender;
- setChoice: sender;
- preset;
- presetTo: (int) i;

@end
