#import "winheaders.h"
#import "Graphic.h"
#import <Foundation/NSArray.h>
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>

@interface CallPart : NSObject
{
@public
    NSString *name;
    NSString *abbrev;//sb: was char *
    int channel;
    NSString *instrument;
}

+ (void)initialize;
- init: (NSString *) n : (NSString *) a : (int) ch : (NSString *) i;
- update: (NSString *) n : (NSString *) a : (int) ch : (NSString *) i;
- (CallPart *) newFrom;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end

@interface NSMutableArray(PartCell)

- (NSString *) partNameForInt: (int) i;
- (CallPart *) partNamed: (NSString *) p;
- (NSString *) instrumentForPart: (NSString *) p;
- (int) channelForPart: (NSString *) p;
- (int) indexOfPartName: (NSString *) p;
- sortPartlist;

@end


