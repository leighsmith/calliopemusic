#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface CastInspector:NSPanel
{
    id partbrowser;
    id instbrowser;
    id partform;
    id parttext;
    id delbutton;
    id modbutton;
    id addbutton;
}

- setAdd:sender;
- setModify: sender;
- reflectSelection;

@end
