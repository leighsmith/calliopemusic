#import "winheaders.h"
#import "StaffObj.h"

#define NUMBLOCKS 7

@interface Block:StaffObj
{
@public
  float width, height;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;
- init;
- (void)dealloc;
- (BOOL) reCache: (float) sy : (int) ss;
- drawMode: (int) m;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : sys : (int) alt;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
