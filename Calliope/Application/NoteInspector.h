#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface NoteInspector:NSPanel
{
  int currinst;		/* numeric value of instrument */
  id accmatrix;
  id dotmatrix;
  id edaccbutton;
  id stylematrix;
  id stemmatrix;
  id timematrix;
  id gracematrix;
  id voiceform;
  id instbutton;
  id instpopup;
  id definebutton;
  id fixswitch;
  id objmatrix;
  id nostemswitch;
  id verseform;
  id slashswitch;
}

- setProto: sender;  /* called when TOOL is pressed */
- set:sender;
- preset;
- presetTo: (int) i;  /* called to load inspector from proto when command-tool */

@end
