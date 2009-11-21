/*!
  $Id$

  @class TimedObj
  @brief Represents staff objects which have a time associated with them.

  In addition to describing staff objects which have a time associated with
  them, TimedObj also contains note stem descriptions. Note that the ivars beamed and 
  stem length (stemlen) are counted as timed information because they are affected by
  whether there is a figure.
 */
#import "winheaders.h"
#import "StaffObj.h"
#import "NoteHead.h"

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


@interface TimedObj: StaffObj
{
@public
  struct timeinfo time;
}


- init;
- (void) dealloc;
- copyWithZone: (NSZone *) zone;

- (BOOL) performKey: (int) c;
- (float) noteEval: (BOOL) f;

/*!
  @brief Increments the note code by the given index and returns the new code. 
 */
- (int) incrementNoteCodeBy: (int) a;

/*!
  @brief Returns the note code (identifier) of the timed object. 
 */
- (int) noteCode;

- defaultStem: (BOOL) up;
- (float) myStemBase;
- (float) stemXoff: (int) stype;
- (float) stemXoffLeft: (int) stype;
- (float) stemXoffRight: (int) stype;
- (float) stemYoff: (int) stype;

/*!
  @brief Assigns the new stem length in points and determines whether the stem is up or down by the sign.
 */
- (void) setStemLengthTo: (float) newStemLength;

/*!
  @brief Returns the stem length in points.
 */
- (float) stemLength;

/*!
  @brief Returns if the timed object has a stem.
 */
- (BOOL) hasNoStem;

/*!
  @brief Returns if the timed object's stem is up (or down).
 */
- (BOOL) stemIsUp;

/*!
  @brief Assigns that the timed object's stem is up (YES), or down (NO).
 */
- (void) setStemIsUp: (BOOL) yesOrNo;

/*!
  @brief Returns if the timed object's stem is fixed or free to be changed up or down.
 */
- (BOOL) stemIsFixed;

/*!
  @brief Assigns if the timed object's stem is fixed or free to be changed up or down.
 */
- (void) setStemIsFixed: (BOOL) yesOrNo;

/*!
 @brief Returns if the timed object is dotted. TODO should be an enum.
 */
- (int) dottingCode;

/*!
 @brief Assigns that the timed object is dotted. TODO should be an enum.
 */
- (void) setDottingCode: (int) newDottingCode;

/*!
  @brief Returns the half width of the note head, dependent on the size and body type of the Timed object.
 */
- (float) halfWidthOfNoteHead: (NoteHead *) noteHead;

/*!
  @brief Returns the half width of the timed object, dependent on the size and body of the Timed object, but not the note type.
 */
- (float) halfWidth;

- (BOOL) validAboveBelow: (int) a;

/*!
  @brief The TimedObj is able to have a beam drawn between itself and another TimedObj instance.
 */
- (BOOL) isBeamable;

/*!
  @brief Returns YES if the TimedObj instance is rhythmically dotted (extended by half duration).
 */
- (BOOL) isDotted;

- (BOOL) isBeamed;
- (BOOL) hitBeamAt: (float *) x : (float *) y;
- (BOOL) tupleStarts;
- (BOOL) tupleEnds;
- (id) initWithCoder: (NSCoder *) aDecoder;
- (void) encodeWithCoder: (NSCoder *) aCoder;

@end
