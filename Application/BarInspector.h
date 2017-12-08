#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface BarInspector:NSPanel
{
    id	typematrix;
    id	buttonmatrix;
    id numbermatrix;
}

- set:sender;		/* target of SET button */
- setProto: sender;	/* target of TOOL button */
- preset;		/* called when panel is opened */
- presetTo: (int) i;	/* called when tool-panel button is command-clicked */

@end
