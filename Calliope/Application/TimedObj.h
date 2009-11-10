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
- (void) dealloc;
- (BOOL) performKey: (int) c;
- (float) noteEval: (BOOL) f;

/*!
 Increments the note code by the given index and returns the new code. 
 */
- (int) incrementNoteCodeBy: (int) a;

/*!
 Returns the note code (identifier) of the timed object. 
 */
- (int) noteCode;

- defaultStem: (BOOL) up;
- (float) myStemBase;
- (float) stemXoff: (int) stype;
- (float) stemXoffLeft: (int) stype;
- (float) stemXoffRight: (int) stype;
- (float) stemYoff: (int) stype;

/*!
 Assigns the new stem length in points and determines whether the stem is up or down by the sign.
 */
- (void) setStemLengthTo: (float) newStemLength;

/*!
 Returns the stem length in points.
 */
- (float) stemLength;

/*!
 Returns if the timed object has a stem.
 */
- (BOOL) hasNoStem;

/*!
 Returns if the timed object's stem is up (or down).
 */
- (BOOL) stemIsUp;

/*!
  Assigns that the timed object's stem is up (YES), or down (NO).
 */
- (void) setStemIsUp: (BOOL) yesOrNo;

/*!
  Returns if the timed object's stem is fixed or free to be changed up or down.
 */
- (BOOL) stemIsFixed;

/*!
  Assigns if the timed object's stem is fixed or free to be changed up or down.
 */
- (void) setStemIsFixed: (BOOL) yesOrNo;

/*!
 Returns if the timed object is dotted. TODO should be an enum.
 */
- (int) dottingCode;

/*!
 Assigns that the timed object is dotted. TODO should be an enum.
 */
- (void) setDottingCode: (int) newDottingCode;

- (BOOL) validAboveBelow: (int) a;
- (BOOL) isBeamable;
- (BOOL) isBeamed;
- (BOOL) hitBeamAt: (float *) x : (float *) y;
- (BOOL) tupleStarts;
- (BOOL) tupleEnds;
- (id)initWithCoder: (NSCoder *) aDecoder;
- (void)encodeWithCoder: (NSCoder *) aCoder;

@end
