#import "winheaders.h"
#import "StaffObj.h"

/*
  note that beamed and stemlen are counted as timeinfo because they
  are affected by whether there is a figure.
*/

struct oldtimeinfo			/* used for reading ClassVersion 0 */
{
  unsigned int body : 4;
  unsigned int dot : 2;
  float stemlen;
};

struct timeinfo
{
  unsigned int body : 4;
  unsigned int dot : 2;
  unsigned int tight : 1;		/* iff timex should give less space */
  unsigned int stemup : 1;		/* 0/1 down/up */
  unsigned int stemfix : 1;		/* 0/1 free/fixed */
  unsigned int nostem : 1;
  unsigned int oppflag : 1;		/* half-flag opposite of default */
  float stemlen;
  float factor;
};


@interface TimedObj:StaffObj
{
@public
  struct timeinfo time;
}


- init;
- (void)dealloc;
- (BOOL) performKey: (int) c;
- (float) noteEval: (BOOL) f;
- (int) noteCode: (int) a;
- defaultStem: (BOOL) up;
- (float) myStemBase;
- (float) stemXoff: (int) stype;
- (float) stemXoffLeft: (int) stype;
- (float) stemXoffRight: (int) stype;
- (float) stemYoff: (int) stype;
- setStemTo: (float) s;
- (BOOL) validAboveBelow: (int) a;
- (BOOL) isBeamable;
- (BOOL) isBeamed;
- (BOOL) hitBeamAt: (float *) x : (float *) y;
- (BOOL) tupleStarts;
- (BOOL) tupleEnds;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
