#import "winheaders.h"
#import "Graphic.h"

@interface NoteHead : NSObject
{
@public
  char type;
  char pos;
  char dotoff;
  char accidental;
  char editorial;
  char side;
  float accidoff;
  float myY;
  id myNote;
}

+ (void)initialize;
- init;
- (void)dealloc;
- (void)moveBy:(float)x :(float)y;
- myStaff;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
