#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface BrackInspector:NSPanel
{
    id	typematrix;
    id	levelmatrix;
}

- set:sender;		/* target of SET button */
- setProto: sender;
- preset;		/* called when panel is opened */
- presetTo: (int) i;

@end
