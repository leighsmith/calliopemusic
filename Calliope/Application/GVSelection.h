#import "winheaders.h"
#import "GraphicView.h"
#import <AppKit/NSFont.h>
#import <Foundation/NSArray.h>

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
- splitSelect: h : hl;
- isSelType: (int) type;
- isSelTypeCode: (int) tc : (int *) num;
- isListLeftmost: l;
- isSelLeftmost;
- isSelRightmost;
- changeSelFont: (NSFont *) f : (BOOL) all;
- getVFont: (int *) num;
- setFontSelection: (int) ff : (int) sw;
- getInsertionX: (float *) x : (id *) rsp : (id *) rp : (int *) tb : (int *) td;
- getBlinkX: (float *) x : (id *) rsp;

@end
