#import "winheaders.h"
#import "Graphic.h"
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>

@interface Course : NSObject
{
@public
  char pitch, acc, oct;
}

+ (void)initialize;
- init: (int) p : (int) a : (int) o;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
