#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface EnclosureInspector:NSPanel
{
  id typematrix;
  id fixmatrix;
}

- set:sender;
- setProto:sender;
- preset;
- presetTo: (int) i;

@end
