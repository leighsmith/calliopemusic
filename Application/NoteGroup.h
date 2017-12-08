/*!
  $Id$ 
  @class NoteGroup
  @brief 
 */
#import "winheaders.h"
#import "Hanger.h"
#import "Volta.h"
#import "Tie.h"

/*
     gFlags.subtype:
     0 = 8---; 1 = 15---; 2 = coll' 8---; 3 = trill 4 = arpegg, 5 = bracket
     6 = round brack, 7 curly brack, 8 anglebrack, 9 line, 10 dashed line,
     11 pedal, 12 crescendo, 13 decrescendo, 14 flat bow, 15 volta.
*/

#define NUMNOTEGROUPS 16

#define GROUPCRES 12
#define GROUPDECRES 13
#define GROUPVOLTA 15

@interface NoteGroup: Hanger
{
@public
  struct
  {
    unsigned int fixed : 1;  	/* whether position fixed */
    unsigned int position : 3;	/* above below right left */
    unsigned int bit0 : 1;	/* a useful bit */
  } flags;
  char mark[4];			/* a useful set of marks */
  float x1, y1, x2, y2; 	/* offsets to corners (interpreted depending on type) */
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- setHanger;
- sysInvalid;
- (BOOL) isClosed: (NSMutableArray *) l;
- (void)removeObj;
- (BOOL) getHandleBBox: (NSRect *) r;
- (BOOL) hit: (NSPoint) p;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

- proto: (Volta *) t;
- proto: (Tie *) t1 : (Tie *) t2;


@end
