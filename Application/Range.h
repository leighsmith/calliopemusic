#import "winheaders.h"
#import "StaffObj.h"

@interface Range:StaffObj
{
@public
  char p1, p2;
  char a1, a2;
  char line;
  char slant;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- recalc;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
