#import "winheaders.h"
#import "TimedObj.h"

/*
  gFlags.subtype hold the design (0 = no serif, 1 = serif)
*/



@interface SquareNote:TimedObj
{
@public
  char shape;
  char colour;
  char stemside;
  char p1;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- (BOOL) getPos: (int) i : (int *) pos : (int *) d : (int *) m : (float *) t;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : sys : (int) alt;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
