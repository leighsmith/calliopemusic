#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface ClefInspector:NSPanel
{
    id	keymatrix;
    id	linematrix;
    id	ottavamatrix;
    id transswitch;
    id octavebutton;
}

- set:sender;
- setProto:sender;
- update: sender;
- preset;
- presetTo: (int) i;

@end
