#import "winheaders.h"
#import "StaffObj.h"

#define FIELDSIZE 8		/* length of the numer / denom strings */


@interface TimeSig:StaffObj
{
@public
  BOOL dot, line;
  char numer[FIELDSIZE], denom[FIELDSIZE], reduc[FIELDSIZE];
  float fnum, fden;
}

+ myInspector;
+ (void)initialize;
+ myPrototype;

- init;
- (void)dealloc;
- (float) myQuotient;
- (float) myFactor: (int) t;
- (int) myBarLength;
- (int) myBeats;
- (BOOL) isConsistent: (float) t;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
