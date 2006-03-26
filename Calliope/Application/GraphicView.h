/* $Id$ */

/*!
  @class GraphicView
  @brief The GraphicView class is the visual representation of a single page of a OpusDocument (which holds several pages).

  It overrides the NSView methods related to drawing and event handling
  and allows manipulation of Graphic objects.
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

// TODO should become MusicalScoreView? or ScorePageView
@interface GraphicView : NSView
{
@public
    unsigned int cacheing;	/*! @var  whether cacheing or drawing */
    NSMutableArray *slist;				/*! @var slist The NSArray of selected Graphics */
    NSMutableArray *syslist;				/*! @var syslist The NSArray of Systems */
    NSMutableArray *stylelist;				/*! @var stylelist NSArray of Systems (templates for styles) */
    NSMutableArray *chanlist;				/*! @var chanlist The NSArray of Channels */
@private
    /*! @var delegate The object informed when page numbers have changed. */
    id delegate;
    NSMutableArray *partlist;				/*! @var partlist The NSArray of Parts */
    NSMutableArray *pagelist;				/*! @var pagelist The NSArray of Pages */
    Page *currentPage;			    /*! @var currentPage The current page to be drawn */
    System *currentSystem;                   /*! @var currentSystem System at top of page of view */
    NSFont *currentFont;                /*! @var currentFont TODO Used to display what? Musical font at any moment, for a particular task? */
    float currentScale;		      /*! @var currentScale The scaling factor: 1.0 = no scaling. */
    BOOL serviceActsOnSelection;        /*! @var serviceActsOnSelection Whether a service has arguments */
    BOOL dirtyflag;
    NSImage *cacheImage;		/*! @var cacheImage The cache of drawn graphics */
    NSRect *dragRect;			/*! @var dragRect Last rectangle we dragged out to select */
    BOOL cached;
    BOOL scrolling;
    BOOL showMargins;			/*! @var showMargins YES to display margins on the page. */
}

typedef enum { Normal, Resizing } DrawStatusType;

extern DrawStatusType DrawStatus;
extern NSString *DrawPboardType;
extern NSEvent *periodicEventWithLocationSetToPoint(NSEvent *oldEvent, NSPoint point);

+ (void) initialize;

- initWithFrame: (NSRect) frameRect;
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
- emptySlist;
- currentSystem;

// These should be removed, a document can be "dirty" i.e. modified, not a view.
- dirty;
- (BOOL) isDirty;

- (BOOL) isEmpty;
- reDraw: p;
- reShapeAndRedraw: g;
- cache:(NSRect)rect;

- setupGrabCursor;
- pressTool: (int) t : (int) a;

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
- (float) rulerScale;
- (int) getPageNum;
- updateMargins: (float) h : (float) f : pi;

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
  @method setDelegate:
  @param newDelegate The new object to receive notification messages.
 */
- (void) setDelegate: (id) newDelegate;

/*!
  @method delegate
  @result Returns the object that receives notification messages.
 */
- (id) delegate;

@end
