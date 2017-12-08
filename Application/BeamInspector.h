#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface BeamInspector:NSPanel
{
    id timematrix;
    id brokebutton;
    id dotmatrix;
    id freematrix;
    id tremmatrix;
    id horizbutton;
    id slashbutton;
    id taperbutton;
  id multiview;
  id blankview;
  id layoutview;
  id brokenview;
  id tremview;
  id taperview;
  id choicebutton;
}

- set:sender;
- preset;
- presetTo: (int) i;
- setProto: sender;
@end
