#import "winheaders.h"
#import "Hanger.h"
#import <AppKit/NSGraphics.h>

/*
  This is an abstract class used for grouping the members of a chord that spans multiple staves.
*/


@interface ChordGroup:Hanger
{

}

+ (void)initialize;

- init;
- (void)dealloc;
- proto: v : (NSPoint) pt : sp : sys : g : (int) i;
- (BOOL) isClosed: l;
- (void)removeObj;
- myProximal;
- (BOOL)selectGroup: (NSMutableArray *) sl : (int) d :(int)active;
- (BOOL) hit: (NSPoint) pt;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
