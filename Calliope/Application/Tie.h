/* $Id$ */
#import "winheaders.h"
#import "Hanger.h"
// #import "Staff.h"

@class StaffObj;

/* TIE gFlags.subtype */

#define NUMTIES 8

#define TIEBOW 0
#define TIELINE 1
/* #define RESERVED 2 because of some mux files bave bracket here*/
#define TIEBRACK 3
#define TIECORN 4
#define TIECRES 5
#define TIEDECRES 6
#define TIESLUR 7
/* #define VACANT 8 */
/* #define VACANT 9 */

/*
  placement 0=head (or above), 1=opposite (or below)
*/

extern char mapTieSubtype[NUMTIES];

@interface Tie:Hanger
{
@public
  id partner;
  NSPoint offset;
  float depth, flatness;
  char headnum;			/* index of notehead of chord if any */
  struct
  {
    unsigned int fixed : 1;  	/* whether location fixed */
    unsigned int horvert : 2;	/* 0=no constraint, 1=horizontal, 2=vertical */
    unsigned int place : 2;	/* 0=head/above 1=opp/below */
    unsigned int above : 1;	/* whether above the group (cache) */
    unsigned int same : 1;	/* whether same as partner */
    unsigned int ed : 1;	/* editorial mark */
    unsigned int usedepth : 1;	/* whether to use depth */
    unsigned int master : 1;	/* whether this is the master */
    unsigned int dashed : 1;	/* whether dashed */
  } flags;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- recalc;
- updatePartner;
- (BOOL) getHandleBBox: (NSRect *) r;
- setDefault: (int) t;
- setHanger;
- (BOOL) isClosed: (NSMutableArray *) l;
- (void)removeObj;
- (BOOL)selectMe: (NSMutableArray *) l : (int) d :(int)active;
- (BOOL) hit: (NSPoint) p;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- (void)setSize:(int)ds;

// Declare the old form of proto to distinguish it from the later form used in Graphic.
- proto: (GraphicView *) v : (NSPoint) pt : (StaffObj *) n0 : (StaffObj *) n1 : (Graphic *) g : (int) i;

- drawMode: (int) m;
- draw;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
