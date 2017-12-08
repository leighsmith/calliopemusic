#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface TabInspector:NSPanel
{
    id	ciphermatrix;
    id	strummatrix;
    id	dotmatrix;
    id	facematrix;
    id	dirmatrix;
    id  showmatrix;
    id	bodymatrix;
    id	timematrix;
    id	placematrix;
    id	strumbutton;
    id  stylematrix;
    id  tunepopup;
    id tunebutton;
    id definebutton;
}

- set:sender;
- setstyle:sender;
- preset;
- presetTo: (int) i;
- setChoice:sender;
- setProto: sender;

@end
