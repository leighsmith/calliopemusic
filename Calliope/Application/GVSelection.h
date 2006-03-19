#import "winheaders.h"
#import <AppKit/NSFont.h>
#import <Foundation/NSArray.h>
#import "GraphicView.h"

@class Hanger;

@interface GraphicView(GVSelection)

- inspectSel: (BOOL) a;
- inspectSelWithMe: g : (BOOL) command : (int) fontseltype;
- canInspect: (int) type;
- canInspect: (int) type : (int *) num;
- canInspectTypeCode: (int) tc : (int *) num;
- (BOOL) startInspection: (int) type : (NSRect *) r : (id *) sl;
- (BOOL) startInspection: (int) type : (NSRect *) r : (id *) sl : (int *) num;
- endInspection: (NSRect *) r;
- (BOOL)hasEmptySelection;
- selectObj: p;
- selectObj: p : (int) b;
- deselectObj: g;
- splitSelect: (Hanger *) h : (NSMutableArray *) hl;
- isSelType: (int) type;
- isSelTypeCode: (int) tc : (int *) num;
- isListLeftmost: (NSMutableArray *) l;
- isSelLeftmost;
- isSelRightmost;
- changeSelectedFontsTo: (NSFont *) f forAllGraphics: (BOOL) all;
- (NSFont *) mostCommonOutOfTotalVerseFonts: (int *) num;
- setFontSelection: (int) ff : (int) sw;
- getInsertionX: (float *) x : (Staff **) rsp : (StaffObj **) rp : (int *) tb : (int *) td;
- getBlinkX: (float *) x : (Staff **) rsp;

@end
