#import "winheaders.h"
#import <AppKit/AppKit.h>
#import "System.h"
#import "Page.h"
/*sb: the following added 14/8/98 to alter the default compression factor for tiff images
 * written to pasteboard, saved etc.
 */
#define TIFF_COMPRESSION_FACTOR NSTIFFCompressionJPEG

@interface GraphicView : NSView
{
@public
  NSMutableArray *pagelist;				/* the List of Page */
  NSMutableArray *syslist;				/* the List of System */
  NSMutableArray *slist;				/* the list of selected Graphic */
  NSMutableArray *partlist;				/* the list of Part */
  NSMutableArray *chanlist;				/* the list of Channel */
  NSMutableArray *stylelist;				/* list of System (templates for styles) */
  Page *currentPage;
  System *currentSystem;                   /* System at top of page of view */
  NSFont *currentFont;
  float currentScale;
  BOOL serviceActsOnSelection;        /* whether a service has arguments */
  BOOL dirtyflag;
  NSImage *cacheImage;		/* the cache of drawn graphics */
  unsigned int cacheing;	/* whether cacheing or drawing */
  NSRect *dragRect;			/* last rectangle we dragged out to select */
  BOOL cached;
  BOOL scrolling;
}

typedef enum { Normal, Resizing } DrawStatusType;

extern DrawStatusType DrawStatus;
extern NSString *DrawPboardType;
extern NSEvent *periodicEventWithLocationSetToPoint(NSEvent *oldEvent, NSPoint point);

+ (void)initialize;

- initWithFrame:(NSRect)frameRect;
- (BOOL)isFlipped;
- (void)dealloc;
- (BOOL)isWithinBounds:(NSRect) rect;
- (BOOL)move:(NSEvent *)event : (id) obj : (int) alt;
- dragSelect:(NSEvent *)event;
- drawGV: (NSRect) b : (BOOL) nonselonly;
- drawSelectionInstance;
- drawSelectionWith: (NSRect *) b;
- selectionBBox:(NSRect *) b;
- selectionHandBBox: (NSRect *) b;
- emptySlist;
- currentSystem;
- dirty;
- (BOOL)isDirty;
- (BOOL) isEmpty;
- reDraw: p;
- reShapeAndRedraw: g;
- cache:(NSRect)rect;

- setupGrabCursor;
- pressTool: (int) t : (int) a;
- saveRect: (NSRect *) region : (int) grabflag;
- terminateMove;

/* Methods overridden from superclass */
- (void)mouseDown:(NSEvent *)event;
- (void)drawRect:(NSRect)rect;
- (void)keyDown:(NSEvent *)event;
- (BOOL) performKeyEquivalent:(NSEvent *)theEvent;

/* Target/Action methods */
- saveEPS: sender;
- saveTIFF: sender;
- (void)delete:(id)sender;
- deselectAll:sender;
- scaleTo: (int) i;
- (int) getScaleNum;
- (float) rulerScale;
- (int) getPageNum;
- updateMargins: (float) h : (float) f : pi;

/* First Responder */
- (BOOL)acceptsFirstResponder;

/* Printing-related methods */
- (BOOL) knowsPagesFirst: (int *) p0 last: (int *) p1;
- (NSRect)rectForPage:(int)pn;
- (void)beginPrologueBBox:(NSRect)boundingBox creationDate:(NSString *)dateCreated createdBy:(NSString *)anApplication fonts:(NSString *)fontNames forWhom:(NSString *)user pages:(int )numPages title:(NSString *)aTitle;
- (void)beginSetup;
- (NSPoint)locationOfPrintRect:(NSRect)r;

/*  Dragging */
- (unsigned int)draggingEntered:sender;
- (unsigned int)draggingUpdated:sender;
- (BOOL)performDragOperation:sender;
- (void)draggingExited:sender;
- (void)concludeDragOperation:sender;

/* Archiving methods */
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

/* Useful scrolling methods */
- scrollGraphicToVisible:graphic;
- (BOOL)scrollPointToVisible:(NSPoint)point;

@end
