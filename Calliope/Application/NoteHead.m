#import "NoteHead.h"
#import "GNote.h"
#import "Staff.h"
#import "System.h"
#import "draw.h"
#import "mux.h"
#import "muxlow.h"

@implementation NoteHead:NSObject


+ (void)initialize
{
  if (self == [NoteHead class])
  {
    [NoteHead setVersion: 2];	/* class version, see read: */
  }
  return;
}


- init
{
  [super init];
  type = 0;
  pos = 0;
  dotoff = 0;
  accidental = 0;
  editorial = 0;
  accidoff = 0.0;
  side = 0;
  myY = 0.0;
  myNote = nil;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- (void)moveBy:(float)x :(float)y
{
  myY += y;
}


- myStaff
{
  return ((GNote *)myNote)->mystaff;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v;
//  [super initWithCoder:aDecoder]; //sb: unnec
  v = [aDecoder versionForClassName:@"NoteHead"];
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccccf@", &type, &pos, &dotoff, &accidental,
    &editorial, &side, &myY, &myNote];
    accidoff = 0.0;
    editorial = 0;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccccff@", &type, &pos, &dotoff, &accidental, &editorial, &side, &accidoff, &myY, &myNote];
    editorial = 0;
  }
  else if (v == 2) [aDecoder decodeValuesOfObjCTypes:"ccccccff@", &type, &pos, &dotoff, &accidental, &editorial, &side, &accidoff, &myY, &myNote];
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeValuesOfObjCTypes:"ccccccff@", &type, &pos, &dotoff, &accidental,
        &editorial, &side, &accidoff, &myY, &myNote];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [aCoder setInteger:type forKey:@"type"];
    [aCoder setInteger:pos forKey:@"pos"];
    [aCoder setInteger:dotoff forKey:@"dotoff"];
    [aCoder setInteger:accidental forKey:@"accidental"];
    [aCoder setInteger:editorial forKey:@"editorial"];
    [aCoder setInteger:side forKey:@"side"];
    [aCoder setFloat:accidoff forKey:@"accidoff"];
    [aCoder setFloat:myY forKey:@"myY"];
    [aCoder setObject:myNote forKey:@"myNote"];
}

@end