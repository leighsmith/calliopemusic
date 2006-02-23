#import "winheaders.h"
#import <AppKit/AppKit.h>
#import "GraphicView.h"

#define STYLE_VERSION 0

@interface Preferences:NSPanel
{
    id	barfontfield;
    id bareveryfield;
    id	barplacematrix;
    id	barshowmatrix;
    id	barsurrmatrix;
    id	barview;
    id	figfontfield;
    id	figview;
    id	heightview;
    id	layoutform;
    id	layoutview;
    id	mainPopup;
    id	multiview;
    id	nodocview;
    id	pathfield;
    id	pathview;
    id	rasheightcell;
    id	rasnummatrix;
    id	rasunits;
    id	revertButton;
    id	setButton;
    id	tabcromatrix;
    id	tabfontfield;
    id	tabview;
    id	texfontfield;
    id	textview;
    id styleview;
    id styletext;
    id stylebutton;
    id runview;
    id runfontfield;
    id heightreal;
    id heightrelative;
}

- (BOOL) getStyleFromFile: (NSString *) fn : (GraphicView *) v;
- reflectSelection;
- changeRastral:sender;
- dataChanged:sender;
- open:sender;
- save:sender;
- set:sender;
- setPrefFont:sender;

@end
