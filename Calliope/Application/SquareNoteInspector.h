#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface SquareNoteInspector:NSPanel
{
  id shapematrix;
  id stemmatrix;
  id colourmatrix;
  id timematrix;
  id dotmatrix;
  id desmatrix;
}

- set:sender;
- preset;
- setChoice: sender;
- setProto: sender;
- presetTo: (int) i;

@end
