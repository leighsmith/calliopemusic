/* $Id$ */
#import "winheaders.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class GraphicView;
@class System;
@class Staff;
@class Enclosure;

#define LEFTBOUND(p) (p->bounds.origin.x)
#define LEFTBEARING(p) (p->x - LEFTBOUND(p))
#define RIGHTBOUND(p) (LEFTBOUND(p) + p->bounds.size.width)
#define RIGHTBEARING(p) (RIGHTBOUND(p) - p->x)
#define MOVE(p, nx) { LEFTBOUND(p) += ((nx) - (p)->x); (p)->x = (nx); }

#define TYPEOF(p) (((Graphic *)(p))->gFlags.type)
#define SUBTYPEOF(p) (((Graphic *)(p))->gFlags.subtype)
#define ISINVIS(p)  (((Graphic *) (p))->gFlags.invis == 1)

extern id CrossCursor;

@interface Graphic : NSObject
{
@public
    NSRect bounds;			/* the bounds */
    struct {
	unsigned int selected : 1;	/* selected (displays in white) */
	unsigned int seldrag : 1;	/* if it was drag-selected */
	unsigned int morphed : 1;	/* mark bit for hanger graphs */
	unsigned int locked : 1;	/* won't move beyond own staff */
	unsigned int invis : 2;		/* colour/invisible (displays in gray) */
	unsigned int selend : 5;	/* selected end (32 codes possible )*/
	unsigned int selbit : 1;	/* another bit used during selecting */
	unsigned int size : 2;		/* size code */
	unsigned int type : 5;		/* type */
	unsigned int subtype : 5;	/* subtype */
    } gFlags;
@protected
    /*! @var staffScale The scale of the staff this graphic is to be drawn on. */
    float staffScale;
    NSMutableArray *enclosures;			/* the list of enclosures */
}

/* Factory methods */

+ (void)initialize;

/*!
  @brief Return an autoreleased version of the named subclass of Graphic.
 */
+ (Graphic *) graphicOfType: (int) t;

+ cursor;
+ getInspector: (int) t;

// + graphicOfType: (int) t asMemberOfView: (GraphicView *) v atPoint: (NSPoint) pt withSystem: (System *) sys withArgument: (int) arg1 andArgument: (int) arg2;
+ createMember: (GraphicView *) v : (int) t : (NSPoint) pt : (System *) sys : (int) arg1 : (int) arg2;

/*!
  @result Returns YES if able to create a Graphic within the view using the argument, NO if unable to.
 */
+ (BOOL) canCreateGraphicOfType: (int) t asMemberOfView: (GraphicView *) v withArgument: (int) arg;
+ myInspector;
- myInspector;
- init;
- mark;
- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
- recalc;
- reShape;
- (BOOL) canSplit;
- (NSMutableArray *) willSplit;
- (void)removeObj;
- (BOOL) linkPaste: (GraphicView *) v;
- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl;
- (NSRect)bounds;
- setBounds:(const NSRect)aRect;
- (BOOL) getHandleBBox: (NSRect *) r;
- (void)moveBy:(float)x :(float)y;
- verseWidths: (float *) tb : (float *) ta;
- (BOOL) performKey: (int) c;
- (int) keyDownString:(NSString *)cc;
- (BOOL) changeVFont: (NSFont *) f : (BOOL) all;
- (BOOL) getXY: (float *) x : (float *) y;
- (float) headY: (int) n;
- (BOOL) selectMe: (NSMutableArray *) l : (int) drag :(int)active;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- moveFinished: (GraphicView *) v;
- resize: (NSEvent *)event in: view;
- traceBounds;
- draw: (NSRect) rect nonSelectedOnly: (BOOL) nso;
- (float) modifyTick: (float) t;
- (BOOL) isDangler;
- (BOOL) isEditable;
- (BOOL) isResizable;
- (BOOL) hasHanger: h;
- (BOOL) isClosed: l;
- (BOOL) hasVoltaBesides: p;
- moveBy:(const NSPoint)offset;
- centerAt: (const NSPoint) p;
- sizeTo: (const NSSize *) size;
- (void)setSize:(int)ds;
- (void)searchFor: (NSPoint) pt : (NSMutableArray *)arr;

/* Archiving (must be overridden by subclasses with instance variables) */

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

/* Routines intended to be subclassed for different types of Graphics. */

- (BOOL)hit:(NSPoint)point;
- (BOOL)hitCorners:(const NSPoint)point;	/* adds corner information */
- (float)hitDistance: (NSPoint) point;
- (BOOL) changeVFont: (int) fid;
- (int) noteCode: (int) a;
- (BOOL) hasEnclosures;

/*!
  @brief used by some subclasses to initialise the hanger.
 */
- presetHanger;

/*!
  @brief Returns an immutable array of Enclosures.
 */
- (NSArray *) enclosures;

- linkEnclosure: (Enclosure *) e;
- unlinkEnclosure: (Enclosure *) e;
- markHangers;
- markHangersExcept: (Graphic *) p;
- setHangersExcept: (int) t;
- setHangersOnly: (int) t;
- setHangers;
- setOwnHangers;
- recalcHangers;
- resizeHangers: (int) ds;
- (int) hasHangers;
- (BOOL)selectHangers:(id)sl : (int) b;
- closeHangers: (NSMutableArray *) l;
- setPageTable: p;
- draw;
- drawMode: (int) m;
- drawHangers: (NSRect)rect nonSelectedOnly: (BOOL) nso;
- drawVerses: (NSRect)rect nonSelectedOnly: (BOOL) nso;
 /*sb: this added at this juncture to prevent compiler warnings. Here, returns only self. Intended to be subclassed. */
- sysInvalid;

@end

