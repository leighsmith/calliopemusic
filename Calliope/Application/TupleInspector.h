#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface TupleInspector:NSPanel
{
    id ntupleform;
    id ratdenform;
    id ratnumform;
    id uneqmatrix;
    id notematrix;
    id dotmatrix;
    id hdtlmatrix;
    id freematrix;
    id horizbutton;
    id brackmatrix;
    id centrematrix;
}

- set:sender;
- setProto:sender;
- preset;
- presetTo: (int) i;
- setChoice: sender;
- clearTime: sender;

@end
