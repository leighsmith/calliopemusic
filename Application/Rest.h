#import "winheaders.h"
#import "TimedObj.h"

/*
*/

/* style:  modern, old book, number above, number below, multiple bars */

@interface Rest:TimedObj
{
@public
  char style;
  short numbars;
  short barticks;	/* a cache: not archived: size permits 256 whole-note bars rest */
}

+ (void)initialize;
+ myInspector;
+ myPrototype;
+ newBarsRest: (int) n;

- init;
- (void)dealloc;
- (BOOL) isBarsRest;
- (int) barCount;
- (float) noteEval: (BOOL) f;
- (float) myDuration;
- (int) defaultPos;
- (float) myStemBase;
- (BOOL) hitBeamAt: (float *) px : (float *) py;
- resetStemlen;
- defaultStem: (BOOL) up;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : (System *) sys : (int) alt;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
