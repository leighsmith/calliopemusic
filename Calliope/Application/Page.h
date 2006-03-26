/* $Id$ */
/*!
  @class Page
 
  This suffers the classic confusion between a view and a model. It should be a model of the layout of systems on a page, 
  which using a particular view, should then be able to be displayed appropriately.
 
  However GraphicView is performing half the function of what should be PageView and half the function of Page (the model).

  So this class should be split so that the drawing routines move into GraphicView and many of the computational routines
  in GVFormat move into Page.
 */
#import "winheaders.h"
#import <Foundation/NSObject.h>
#import <AppKit/NSGraphics.h>
#import "System.h"
#import "Margin.h"

@class GraphicView;

/* ways pages can be formatted */

typedef enum {
    PGAUTO = 0,		/* default */
    PGTOP = 1,		/* top justified */
    PGBOTTOM = 2,	/* bottom justified */
    PGSPREAD = 3,	/* top and bottom justified */
    PGBALANCE = 4,	/* balanced */
    PGCENTRE = 5,	/* centred */
    PGEXPAND = 6,	/* expanded */
    PGPACKTOP = 7,	/* pack from top */
    PGPACKBOT = 8	/* pack from bottom */
} PageFormat;

@interface Page: NSObject
{
@public;
  short topsys;
  short botsys;
  id headfoot[12];
  char hfinfo[12];
@private
  int num;			/*! @var num The displayed paged number. */
  float fillheight;		/* sums to page height (as screened) */
  float margin[10];
  PageFormat format;
  int alignment;
}

- initWithPageNumber: (int) n topSystemNumber: (int) s0 bottomSystemNumber: (int) s1;

/*!
  @brief copy page table info from previous page.  p is nil if no previous page 
 */
- prevTable: (Page *) p;

- (float) headerBase;
- (float) footerBase;
- (float) leftMargin;
- (float) rightMargin;
- (float) topMargin;
- (float) bottomMargin;
- (float) leftBinding;
- (float) rightBinding;


/*!
  @brief Assigns the given margin.
 */
- (void) setMarginType: (MarginType) marginType toSize: (float) newMarginValue;

/*!
  @brief Returns the page height (as screened) 
 */
- (float) fillHeight;

/*!
  @brief Assigns the page height (as screened) 
 */
- (void) setFillHeight: (float) newHeight;

/*!
  @brief Returns YES if pages are to be aligned to the top system.
 */
- (BOOL) alignToTopSystem;

/*!
  @brief Returns NO if pages are to be aligned to the top system.
 */
- (BOOL) alignToBottomSystem;

/*!
  @brief Assigns the alignment.
 */
- (void) setAlignment: (int) newAlignment;

/*!
  @brief Returns the current page format behaviour.
 */
- (PageFormat) format;

/*!
  @brief Assigns the format of the page.
 */
- (void) setFormat: (PageFormat) newFormat;

/*!
  @brief Returns the displayed page number.
 */
- (int) pageNumber;

/*!
 @brief Assigns the page number
 */
- (void) setPageNumber: (int) newPageNumber;


- (id) initWithCoder: (NSCoder *) aDecoder;
- (void) encodeWithCoder: (NSCoder *) aCoder;

// Drawing routines which should be factored.
- (void) drawRect: (NSRect) r;
- drawSysSep: (NSRect) r : (System *) s : (GraphicView *) v;

@end
