#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface TextInspector:NSPanel
{
    id	typematrix;
    id	staffform;
    id	titplacematrix;
    id marginform;
    id marginunits;
    id namebutton;
    id abbrevbutton;
    id setButton;
}

- set:sender;
- preset;
- dataChanged: sender;

@end
