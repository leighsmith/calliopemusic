/*!
 $Id$ 
 
 @class TimeSig
 @brief Represents notated time signatures.
 */
#import "winheaders.h"
#import "StaffObj.h"

#define FIELDSIZE 8		/* length of the numer / denom strings */


@interface TimeSig: StaffObj
{
@public
    BOOL dot;
    BOOL line;
    char reduc[FIELDSIZE];
    float fnum;
    float fden;
@private
    NSString *numeratorString;
    NSString *denominatorString;
    float numerator;
    float denominator;
}

+ myInspector;
+ (void)initialize;
+ myPrototype;

- init;
- (void) dealloc;
- (float) myQuotient;
- (float) myFactor: (int) t;
- (int) myBarLength;
- (int) myBeats;

/*!
  @brief Assigns the denominator of the time signature from an NSString.
 */
- (void) setDenominatorString: (NSString *) newDenominator;

/*!
  @brief returns the denominator formatted as an NSString.
 */
- (NSString *) denominatorString;

/*!
 @brief Assigns the denominator of the time signature from a floating point value.
 */
- (void) setDenominator: (float) newDenominator;

/*!
  @brief Assigns the numerator of the time signature from an NSString.
 */
- (void) setNumeratorString: (NSString *) newNumerator;

/*!
  @brief returns the numerator formatted as an NSString.
 */
- (NSString *) numeratorString;

/*!
  @brief Assigns the numerator of the time signature from a floating point value.
 */
- (void) setNumerator: (float) newNumerator;

- (BOOL) isConsistent: (float) t;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
