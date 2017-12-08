#import "winheaders.h"
#import <AppKit/AppKit.h>

@interface TabTuner:NSPanel
{
    id	addbutton;
    id	renamebutton;
    id	tabbrowser;
    id tabtext;
    id instpopup;
    id deletebutton;
    id noteview;
    id tuningpanel;
    id instform;
    id tabswitch;
    id newbutton;
    id modbutton;
    id delbutton;
}

- (NSMutableArray *) selectedList;
- (int) isTablature;
- (int) transposition;
- setSelectedTrans: (int) t;
- setAdd:sender;
- setRename:sender;
- preset;

@end
