#import "winheaders.h"
#import "Graphic.h"
#import <Foundation/NSArray.h>
//#import <OAPropertyListCoders/OAPropertyListCoders.h>
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>


@interface CallInst : NSObject
{
@public
  NSString *name;
  NSString *abbrev;
  char trans;
  unsigned char channel;  /* VACANT */
  unsigned char istab;
  unsigned char sound;
  NSMutableArray *tuning;
}

+ (void)initialize;
- init: (NSString *) n : (NSString *) a : (int) tr : (int) ch : (int) tab : (int) snd : (NSMutableArray *) tl;
- update:  (NSString *) n : (NSString *) a : (int) tr : (int) ch : (int) tab : (int) snd;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end

@interface NSMutableArray(InstCell)

- (CallInst *) instNamed: (NSString *) inst;
- (int) indexOfInstName: (NSString *) i;
- (int) indexOfInstString: (NSString *) i;
- (int) soundForInstrument: (NSString *) i;
- (NSMutableArray *) tuningForInstrument: (NSString *) i;
- (NSString *) instNameForInt: (int) i;  /* ForInt are temporary */
- (int) transForInstrument: (NSString *) inst;
- sortInstlist;

@end

