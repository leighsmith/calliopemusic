#import "winheaders.h"
#import <AppKit/NSPanel.h>
#import "System.h"

@interface NSMutableArray(StyleSys)

- (NSString *) styleNameForInt: (int) i;
- sortStylelist;
- (System *) styleSysForName: (NSString *) a;

@end


@interface SysInspector:NSPanel
{
    id	prefaceforms;
    id equidistbutton;
    id expansionform;
    id	sizematrix;
    id	indentleft;
    id	pagematrix;
    id	notationmatrix;
    id	staffforms;
    id	staffnumbutton;
    id	prefacebutton;
    id	nstavestext;
    id	indentright;
    id margintop;
    id barbase;
    id hidebutton;
    id newbarbutton;
    id newpagebutton;
    id newform;
    id fixswitch;
    id verseoffform;
    id polymatrix;
    id staffmatrix;
    id staffscroll;
    id partbutton;
    id partpopup;
    id newsysbutton;
    id multiview;
    id styleview;
    id keepview;
    id indentview;
    id numberview;
    id vertview;
    id polyview;
    id mainPopup;
    id revertButton;
    id setButton;
    id stybrowser;
    id stytext;
    id newstybutton;
    id defstybutton;
    id constybutton;
    id delstybutton;
    id renstybutton;
    id finstybutton;
    id reorderButton;
    id nodocview;
    id syssepview;
    id syssepmatrix;
    id staffview;
    id standview;
    id layoutview;
    id prefview;
    id barnumswitch;
}

- (BOOL) isBusy;
- changeBox: sender;
- dataChanged: sender;
- set: sender;			/* target of SET button */
- setnstaves: sender;		/* target of setting a number of staves */
- pickstaff: sender;		/* target of choosing a staff number */
- preset;			/* called when inspector is opened */
- revert: sender;
- matrixDidReorder:sender;	/* called by DragMatrix to alert to proposed layout change */

@end
