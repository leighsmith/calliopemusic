
/* Generated by Interface Builder */

#import "Course.h"

@implementation Course:NSObject


+ (void)initialize
{
  if (self == [Course class])
  {
    [Course setVersion: 0];	/* class version, see read: */
  }
  return;
}


- init: (int) p : (int) a : (int) o
{
  [super init];
  pitch = p;
  acc = a;
  oct = o;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v;
//    [super initWithCoder:aDecoder]; //sb: unnec
  v = [aDecoder versionForClassName:@"Course"];
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccc", &pitch, &acc, &oct];
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
//    [super encodeWithCoder:aCoder]; //sb: unnec
    [aCoder encodeValuesOfObjCTypes:"ccc", &pitch, &acc, &oct];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [aCoder setInteger:pitch forKey:@"pitch"];
    [aCoder setInteger:acc forKey:@"acc"];
    [aCoder setInteger:oct forKey:@"oct"];
}

@end
