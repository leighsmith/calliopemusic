#import "winheaders.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSEvent.h>

#define LEFTBOUND(p) (p->bounds.origin.x)
#define LEFTBEARING(p) (p->x - LEFTBOUND(p))
#define RIGHTBOUND(p) (LEFTBOUND(p) + p->bounds.size.width)
#define RIGHTBEARING(p) (RIGHTBOUND(p) - p->x)
#define MOVE(p, nx) { LEFTBOUND(p) += ((nx) - (p)->x); (p)->x = (nx); }


extern id CrossCursor;

@interface Graphic : NSObject
{
@public
  NSRect bounds;			/* the bounds */
  NSMutableArray *enclosures;			/* the list of enclosures */
  struct
  {
    unsigned int selected : 1;		/* selected (displays in white) */
    unsigned int seldrag : 1;		/* if it was drag-selected */
    unsigned int morphed : 1;		/* mark bit for hanger graphs */
    unsigned int locked : 1;		/* won't move beyond own staff */
    unsigned int invis : 2;		/* colour/invisible (displays in gray) */
    unsigned int selend : 5;		/* selected end (32 codes possible )*/
    unsigned int selbit : 1;		/* another bit used during selecting */
    unsigned int size : 2;		/* size code */
    unsigned int type : 5;		/* type */
    unsigned int subtype : 5;		/* subtype */
  } gFlags;
}

/* Factory methods */

+ (void)initialize;
+ allocInit: (int) t;
+ cursor;
+ getInspector: (int) t;
+ createMember:  v : (int) t : (NSPoint) pt :  sys : (int) arg1 : (int) arg2;
+ (BOOL) createMember: (int) t : v : (int) arg;
+ myInspector;
- myInspector;
- printMe;
- init;
- mark;
- proto: v : (NSPoint) pt : sp : sys : g : (int) i;
- recalc;
- reShape;
- (BOOL) canSplit;
- willSplit;
- (void)removeObj;
- (BOOL) linkPaste: v;
- (BOOL) linkPaste: v : sl;
- (NSRect)bounds;
- setBounds:(const NSRect)aRect;
- (BOOL) getHandleBBox: (NSRect *) r;
- (void)moveBy:(float)x :(float)y;
- verseWidths: (float *) tb : (float *) ta;
- (BOOL) performKey: (int) c;
- (int)keyDownString:(NSString *)cc;
- (BOOL) changeVFont: f : (BOOL) all;
- (BOOL) getXY: (float *) x : (float *) y;
- (float) headY: (int) n;
- (BOOL)selectMe: l : (int) drag :(int)active;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- moveFinished: v;
- resize:(NSEvent *)event in: view;
- traceBounds;
- draw:(NSRect)rect : (BOOL) nso;
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
- linkEnclosure: e;
- unlinkEnclosure: e;
- markHangers;
- markHangersExcept: p;
- setHangersExcept: (int) t;
- setHangersOnly: (int) t;
- setHangers;
- setOwnHangers;
- recalcHangers;
- resizeHangers: (int) ds;
- (int) hasHangers;
- (BOOL)selectHangers:(id)sl : (int) b;
- closeHangers: l;
- setPageTable: p;
- draw;
- drawMode: (int) m;
- drawHangers: (NSRect)rect : (BOOL) nso;
- drawVerses: (NSRect)rect : (BOOL) nso;
 /*sb: this added at this juncture to prevent compiler warnings. Here, returns only self. Intended to be subclassed. */
- sysInvalid;

@end
