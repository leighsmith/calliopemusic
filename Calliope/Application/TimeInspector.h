#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface TimeInspector:NSPanel
{
    id	numdenform;
    id  reducform;
    id	punctmatrix;
    id	choicematrix;
    id factorform;
}

- set:sender;
- setProto:sender;
- update: self;
- preset;
- presetTo: (int) i;

@end
