/*!
  $Id$
 
  @class Barlne
  @brief Represents the bar lines on a staff. 
 */
#import "winheaders.h"
#import "StaffObj.h"
#import "GraphicView.h"
#import "Staff.h"
#import "System.h"

/* BARLINE gFlags.subtype, used by Barline, Volta*/

#define SINGLE 0
#define DOUBLE 1
#define BAREND 2
#define BARENDR 3
#define BARBEG  4
#define BARBEGR 5
#define BARDOUR 6
#define BARDOTS 7
#define BARHALF 8	/* half bar (chant notation ) */
#define BARQUAR 9	/* quarter bar (chant notation) */

#define BARGUUP 10	/* guide up (used by MuxInput) */
#define BARGUDN 11 	/* guide down (used by MuxInput) */
#define BARGUID 12	/* the mordent-shaped guide (used by MuxInput) */

#define BARUPPER 13	/* upper half bar */
#define BARLOWER 14	/* lower half bar */
#define BARDOURB 15	/* alternative double repeat */

/* nonumber: 1=suppress; 2 = force */

@interface Barline:StaffObj
{
@public
  struct
  {
    unsigned int editorial : 1;
    unsigned int staff : 1;
    unsigned int bridge : 1;
    unsigned int nocount : 1;
    unsigned int dashed : 1;
    unsigned int nonumber : 2;
  } flags;
  char pos;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- (int) barCount;
- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
- (int) posAboveBelow: (int) a;
- (float) yAboveBelow: (int) a;
- (BOOL) stopsVerse;
- verseWidths: (float *) tb : (float *) ta;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
