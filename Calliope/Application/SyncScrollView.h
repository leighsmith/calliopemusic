#import "winheaders.h"
#import <AppKit/NSScrollView.h>

@interface SyncScrollView : NSScrollView
{
    id hRuler;
    id vRuler;
    id rulerClass;
    id pageUpButton, pageDownButton;  /* items in ScrollerGadgets.nib */
    id pageFirstButton, pageLastButton;
    id pageForm, pageLabel, zoomPopUpList;  /* items in ScrollerGadgets.nib */
    NSRect vertScrollerArea, horzScrollerArea;
    float horizontalRulerWidth;
    float verticalRulerWidth;
    BOOL verticalRulerIsVisible;
    BOOL horizontalRulerIsVisible;
    BOOL rulersMade;
    NSRect rulerlineRect;
}

/* Setting up the rulers */
- (void)drawRulerlinesWithRect:(NSRect)aRect;
- (void)updateRulerlinesWithOldRect:(NSRect)oldRect newRect:(NSRect)newRect;
- (void)eraseRulerlines;

- (BOOL)bothRulersAreVisible;
- (BOOL)eitherRulerIsVisible;
- (BOOL)verticalRulerIsVisible;
- (BOOL)horizontalRulerIsVisible;
- (void)updateRuler;
- setRulerClass:factoryId;

- setPageNum: (int) p;
- setScaleNum: (int) i;
- setMessage: (NSString *) s;

/* Comes up the responder chain to us */
- pageTo: sender;
- updateRulers:(const NSRect *)rect;
- (void)showHideRulers:sender;

/* Overridden from superclass */

- initWithFrame:(NSRect)f;
- (void)reflectScrolledClipView:(NSClipView *)cView;
- (void)tile;
- (void)scrollClipView:(NSClipView *)aClipView toPoint:(NSPoint)aPoint;
- (void)viewFrameChanged:(NSNotification *)notification;
- (void)drawRect:(NSRect)rect;

@end
