#import "winheaders.h"
#import "Graphic.h"
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>


@interface Channel : NSObject
{
@public
  char flag; /* a cache; not archived */
  float level, pan, reverb, chorus, vibrato;
}

+ (void)initialize;
- init;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
