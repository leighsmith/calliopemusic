/* $Id$ */
/*!
  @class Page
 
  @brief Relatively lightweight class holding which Systems span a page. Effectively it's a cursor or more correctly, a window
         over all the systems being displayed.
 
  In the past this suffered the classic confusion between a view and a model. It should be a model of the layout of systems on a page, 
  which using a particular view, should then be able to be displayed appropriately.
 
  However GraphicView is performing half the function of what should be PageView and half the function of NotationScore (the model).

  So this class should be split so that the drawing routines move into GraphicView and many of the computational routines
  in GVFormat move into Page or .
 */
#import "winheaders.h"
#import <Foundation/NSObject.h>
#import <AppKit/NSGraphics.h>
#import "System.h"
#import "Margin.h"
#import "Runner.h"

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
    // TODO These are both currently public. They are only accessed by GraphicView, GVCommands, GVFormat, GVPerform.

@public;
    short topsys;
    short botsys;
@private
    Runner *headfoot[12];
    char hfinfo[12];	    // can probably be removed if headfoot just checks for nil values.
    int num;			/*! @var num The displayed paged number. */
    float fillheight;		/* sums to page height (as screened) */
    Margin *margin;		/*! @var margin The margins for this page. */
    /*! @var format The current method page is formatted */
    PageFormat format;
    /*! @var alignment Controls whether margins are aligned with the highest or lowest staff lines */
    int alignment;
}

/*!
  @brief Initialises the page to a given page number and indexes to it's associated systems.
 */
- initWithPageNumber: (int) n topSystemNumber: (int) s0 bottomSystemNumber: (int) s1;

/*!
  @brief Returns the system number at the top of the page.
 */
- (int) topSystemNumber;

/*!
  @brief Returns the system number at the bottom of this page.
 */
- (int) bottomSystemNumber;

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
- (void) setMargin: (Margin *) newMargin;

/*!
 @brief Returns the margin for this page.
 */
- (Margin *) margin;

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
  @brief Returns YES if pages are to be aligned to the bottom system.
 */
- (BOOL) alignToBottomSystem;

/*!
  @brief Assigns the page to be aligned to the top system on the page.
 */
- (void) setAlignToTopSystem;

/*!
  @brief Assigns the page to be aligned to the bottom system on the page.
 */
- (void) setAlignToBottomSystem;

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

/*!
  @brief Assigns the page runners.
 */
- (void) setRunner: (Runner *) newRunner;


- (id) initWithCoder: (NSCoder *) aDecoder;
- (void) encodeWithCoder: (NSCoder *) aCoder;

// Drawing routines which should be factored.
- (void) drawRect: (NSRect) r;
- drawSysSep: (NSRect) r : (System *) s : (GraphicView *) v;

@end
