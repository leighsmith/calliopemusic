/*!
  $Id$ 

  @class Ligature
  @brief
*/
#import "winheaders.h"
#import "Hanger.h"

/*
     gFlags.subtype
*/

#define NUMLIGATURES 4

#define LIGLINE 0
#define LIGBRACK 1
#define LIGCORN 2
#define LIGGLISS 3

@interface Ligature:Hanger
{
@public
  NSPoint off1, off2;		/* offsets */
  struct
  {
    unsigned int fixed : 1;  	/* whether position fixed */
    unsigned int place : 1;	/* above below */
    unsigned int dashed : 1;
    unsigned int ed : 1;	/* constrain horizontal */
  } flags;
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

@end
