#import "winheaders.h"
#import "StaffObj.h"

@interface Neume:StaffObj
{
@public
  char p2, p3;
  struct
  {
    unsigned int dot : 4;
    unsigned int vepisema : 4;
    unsigned int hepisema : 4;
    unsigned int quilisma : 4;
    unsigned int molle : 4;
    unsigned int num : 2;
  } nFlags;
}

+ (void)initialize;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end
