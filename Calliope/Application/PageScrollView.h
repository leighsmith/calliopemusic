/* $Id$ */
#import "winheaders.h"
#import <AppKit/AppKit.h>

@interface SyncScrollView : NSScrollView
{
    /* items in the ScrollerGadgets window */
    IBOutlet NSButton *pageUpButton;
    IBOutlet NSButton *pageDownButton;
    IBOutlet NSButton *pageFirstButton;
    IBOutlet NSButton *pageLastButton;
    IBOutlet NSForm *pageForm;
    IBOutlet NSTextField *pageLabel;
    IBOutlet NSPopUpButton *zoomPopUpList;

    id hRuler;
    id vRuler;
    id rulerClass;
    NSRect vertScrollerArea, horzScrollerArea;
    float horizontalRulerWidth;
    float verticalRulerWidth;
    BOOL verticalRulerIsVisible;
    BOOL horizontalRulerIsVisible;
    BOOL rulersMade;
    NSRect rulerlineRect;
}

/*!
  @brief Does final initialisation of the instance since the buttons are not yet subviews 
 */
- (void) initialiseControls;

/* Setting up the rulers */
- (void) drawRulerlinesWithRect: (NSRect) aRect;
- (void) updateRulerlinesWithOldRect: (NSRect) oldRect newRect: (NSRect) newRect;
- (void) eraseRulerlines;

- (BOOL) bothRulersAreVisible;
- (BOOL) eitherRulerIsVisible;
- (BOOL) verticalRulerIsVisible;
- (BOOL) horizontalRulerIsVisible;
- (void) updateRuler;
- setRulerClass: factoryId;

- (void) setPageNumber: (int) p;
- setScaleNum: (int) i;
- (void) setMessage: (NSString *) s;

/* Comes up the responder chain to us */
- pageTo: sender;
- updateRulers: (const NSRect *) rect;
- (void) showHideRulers: sender;

/* Overridden from superclass */

- (void) reflectScrolledClipView: (NSClipView *) cView;
- (void) tile;
- (void) scrollClipView: (NSClipView *) aClipView toPoint: (NSPoint) aPoint;
- (void) viewFrameChanged: (NSNotification *) notification;
- (void) drawRect: (NSRect) rect;

@end
