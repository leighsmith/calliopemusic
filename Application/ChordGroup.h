#import "winheaders.h"
#import "Hanger.h"
#import <AppKit/NSGraphics.h>
#import "System.h"
#import "Staff.h"
#import "GNote.h"

/*
  This is an abstract class used for grouping the members of a chord that spans multiple staves.
*/


@interface ChordGroup:Hanger
{

}

+ (void)initialize;

- init;
- (void)dealloc;
- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) t;
- (BOOL) isClosed: (NSMutableArray *) l;
- (void)removeObj;
- (GNote *) myProximal;
- (BOOL)selectGroup: (NSMutableArray *) sl : (int) d :(int)active;
- (BOOL) hit: (NSPoint) pt;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
