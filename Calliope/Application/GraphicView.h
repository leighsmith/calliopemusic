/*!
  $Id$

  @class GraphicView
  @brief The GraphicView class is the visual representation of a single page of a OpusDocument (which holds several pages).

  TODO should be renamed ScorePageView.
  Probably there should be a NotationScore which should hold the array of Graphics as the model,
  and ScorePageView which should be displaying a single Page (which should be renamed ScorePage).
 
  It overrides the NSView methods related to drawing and event handling and allows manipulation of Graphic objects.
  Moving is accomplished using instance drawing.
 */

#import "winheaders.h"
#import <AppKit/AppKit.h>
#import "System.h"
#import "Page.h"

/*sb: the following added 14/8/98 to alter the default compression factor for tiff images
 * written to pasteboard, saved etc.
 */
#define TIFF_COMPRESSION_FACTOR NSTIFFCompressionJPEG

@interface GraphicView: NSView
{
    // TODO ivars syslist, pagelist, partlist, chanlist, stylelist, currentScale should be refactored into a model class NotationScore.
    /*! @var syslist The NSArray of Systems */
    NSMutableArray *syslist;
    /*! @var pagelist The NSArray of Pages */
    NSMutableArray *pagelist;
    /*! @var partlist The NSArray of Parts */
    NSMutableArray *partlist;
    /*! @var chanlist The NSArray of Channels */
    NSMutableArray *chanlist;
    /*! @var stylelist NSArray of Systems (templates for styles) */
    NSMutableArray *stylelist;
    
    /*! @var currentScale The scaling factor: 1.0 = no scaling. */
    float currentScale;
    /*! @var staffScale The scale of the staff this graphic is to be drawn on. */
    float staffScale;

    // These ones still need deciding on which side of the model/view divide they should sit.
    BOOL dirtyflag;
    NSMutableArray *slist;				/*! @var slist The NSArray of selected Graphics */

    // These ivars strictly manage drawing the view and responding to user events on the view.
    /*! @var delegate The object informed when page numbers have changed. */
    id delegate;
    /*! @var currentPage The current page to be drawn */
    Page *currentPage;			    
    /*! @var currentSystem System at top of page of view */
    System *currentSystem;                   
    /*! @var currentFont TODO Used to display what? Musical font at any moment, for a particular task? */
    NSFont *currentFont;                
    /*! @var serviceActsOnSelection Whether a service has arguments */
    BOOL serviceActsOnSelection;        
    /*! @var cacheImage The cache of drawn graphics */
    NSImage *cacheImage;		
    /*! @var dragRect Last rectangle we dragged out to select */
    NSRect *dragRect;			
    /*! @var cached TODO */
    BOOL cached;
    /*! @var scrolling TODO */
    BOOL scrolling;
    /*! @var showMargins YES to display margins on the page. */
    BOOL showMargins;
}

typedef enum { Normal, Resizing } DrawStatusType;

extern DrawStatusType DrawStatus;
extern NSString *DrawPboardType;
extern NSEvent *periodicEventWithLocationSetToPoint(NSEvent *oldEvent, NSPoint point);

+ (void) initialize;

- initWithFrame: (NSRect) frameRect;
- initWithGraphicView: (GraphicView *) v;
- (BOOL) isFlipped;
- (void) dealloc;
- (BOOL) isWithinBounds: (NSRect) rect;
- (BOOL) move: (NSEvent *) event : (id) obj : (int) alt;
- dragSelect: (NSEvent *) event;
/* TODO This is called by Graphic! Should become private... */
- (void) drawRect: (NSRect) b;
- drawSelectionInstance;
- drawSelectionWith: (NSRect *) b;
- selectionBBox:(NSRect *) b;
- selectionHandBBox: (NSRect *) b;

/*!
  @brief Returns the list of Graphic objects which have been selected.
 */
- (NSMutableArray *) selectedGraphics;
 
/*! 
  @brief clean out the selection list, free/realloc only if necessary
 */
- (void) clearSelection;

- currentSystem;

// These should be removed, a document can be "dirty" i.e. modified, not a view.
- dirty;
- (BOOL) isDirty;

- (BOOL) isEmpty;
- reDraw: p;
- reShapeAndRedraw: g;
- cache:(NSRect)rect;

- setupGrabCursor;

/*!
  @brief method to initiate the use of the given tool t.
 */
- pressTool: (int) t withArgument: (int) a;

/*!
  Returns an NSData instance of the nominated region in the requested format.
 */
- (NSData *) saveRect: (NSRect) region ofType: (int) grabType;

- terminateMove;

/* Methods overridden from superclass */
- (void) mouseDown: (NSEvent *) event;
- (void) keyDown: (NSEvent *) event;
- (BOOL) performKeyEquivalent: (NSEvent *) theEvent;

/* Target/Action methods */
// TODO should just become pasteboard operations and the saving moved into the OpusDocument.
- saveEPS: sender;
- saveTIFF: sender;
- (void) delete: (id) sender;
- deselectAll: sender;

/* Image display manipulators */
- scaleTo: (int) i;
- (int) getScaleNum;
- (float) getScaleFactor;
- (void) setScaleFactor: (float) newScaleFactor;

/*!
 @brief Assigns the scale of the Staff to the Graphic.
 */
- (void) setStaffScale: (float) newStaffScale;

/*!
 @brief Returns the current scale of the staff.
 */
- (float) staffScale;

- (float) rulerScale;

/*!
  @brief Returns the printed number of the current page.
 
 Returns 0 if there is no current page.
 */
- (int) getPageNum;

/*!
  @brief Returns the page currently being displayed.
 */
- (Page *) currentPage;

- updateMarginsWithHeader: (float) h footer: (float) f printInfo: pi;

/* First Responder */
- (BOOL) acceptsFirstResponder;

/* Printing-related methods */
- (BOOL) knowsPagesFirst: (int *) p0 last: (int *) p1;
- (NSRect) rectForPage: (int) pn;
- (void) beginPrologueBBox: (NSRect) boundingBox
	      creationDate: (NSString *) dateCreated
		 createdBy: (NSString *) anApplication
		     fonts: (NSString *) fontNames
		   forWhom: (NSString *) user
		     pages: (int) numPages
		     title: (NSString *) aTitle;
- (void) beginSetup;
- (NSPoint) locationOfPrintRect: (NSRect) r;

/*  Dragging */
- (unsigned int) draggingEntered: sender;
- (unsigned int) draggingUpdated: sender;
- (BOOL) performDragOperation: sender;
- (void) draggingExited: sender;
- (void) concludeDragOperation: sender;

/* Archiving methods */
- (void) encodeWithCoder: (NSCoder *) aCoder;
- (id) initWithCoder: (NSCoder *) aDecoder;

/* Useful scrolling methods */
- scrollGraphicToVisible: graphic;
- (BOOL) scrollPointToVisible: (NSPoint) point;

/*!
  @param newDelegate The new object to receive notification messages.
 */
- (void) setDelegate: (id) newDelegate;

/*!
  @result Returns the object that receives notification messages.
 */
- (id) delegate;

@end
