#import "winheaders.h"
#import "Hanger.h"

@interface Metro:Hanger
{
@public
  char body[2], dot[2];
  short ticks, pos;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- proto: v : (NSPoint) pt : sp : sys : g : (int) i;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : sys : (int) alt;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
