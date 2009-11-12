/*!
  $Id$ 
  @class PageScrollView
  @brief Manages the scrolling of a Page.
 */
#import "winheaders.h"
#import <AppKit/AppKit.h>

@interface PageScrollView : NSScrollView
{
    /* items in the ScrollerGadgets window */
    IBOutlet NSButton *pageUpButton;
    IBOutlet NSButton *pageDownButton;
    IBOutlet NSButton *pageFirstButton;
    IBOutlet NSButton *pageLastButton;
    IBOutlet NSForm *pageForm;
    IBOutlet NSTextField *pageLabel;
    IBOutlet NSPopUpButton *zoomPopUpList;

    NSRect vertScrollerArea, horzScrollerArea;
    
    id hRuler;
    id vRuler;
    id rulerClass;
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

// Methods for setting page, scale and message.
- (void) setPageNumber: (int) p;
- (void) setScaleNumber: (int) i;
- (void) setMessage: (NSString *) s;

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

/* Comes up the responder chain to us */
- updateRulers: (const NSRect *) rect;
- (void) showHideRulers: sender;

/* Overridden from superclass */
- (void) reflectScrolledClipView: (NSClipView *) cView;
- (void) tile;
- (void) scrollClipView: (NSClipView *) aClipView toPoint: (NSPoint) aPoint;
- (void) viewFrameChanged: (NSNotification *) notification;
- (void) drawRect: (NSRect) rect;

@end
