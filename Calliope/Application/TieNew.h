/*!
  $Id$ 

  @class TieNew
  @brief Represents Ties between two notes.
*/
#import "winheaders.h"
#import "Hanger.h"
#import "GraphicView.h"
#import "StaffObj.h"

/* TIENEW gFlags.subtype */

#define NUMTIESNEW 2

#define TIEBOWNEW 0
#define TIESLURNEW 1

/*
  placement 0=head (or above), 1=opposite (or below)
  off1,2 are x,y coordinate offsets from the notes.
  con1,2 are line parameters in the range 0..1
*/

@interface TieNew: Hanger
{
@public
  NSPoint off1, off2, con1, con2; /* control parameters */
  char head1, head2;		/* index of notehead of chord if any */
  struct
  {
    unsigned int fixed : 1;  	/* whether location fixed */
    unsigned int place : 1;	/* TIE: 0=norm, 1=opp; SLUR: 0=above, 1=below */
    unsigned int ed : 1;	/* editorial mark */
    unsigned int dashed : 1;	/* whether dashed */
    unsigned int flat : 1;	/* the flat shape */
  } flags;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (BOOL) needSplit: (float) s0 : (float) s1;
- (void) dealloc;
- (int) whichEnd: (StaffObj *) p;
- coordsForHandle: (int) h  asX: (float *) x  andY: (float *) y;
- proto: (GraphicView *) v : (StaffObj *) p : (StaffObj *) q : (int) i;
- (BOOL) getHandleBBox: (NSRect *) r;
- setDefault: (int) t;
- setHanger;
- (BOOL) isClosed: (NSMutableArray *) l;
- (void) removeObj;
- (BOOL) hit: (NSPoint) p;
- (float) hitDistance: (NSPoint ) p;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- drawMode: (int) m;
- (id) initWithCoder: (NSCoder *) aDecoder;
- (void) encodeWithCoder: (NSCoder *) aCoder;

@end
