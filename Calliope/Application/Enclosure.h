#import "winheaders.h"
#import "Graphic.h"
#import "GraphicView.h"
#import <Foundation/NSArray.h>

@interface Enclosure:Graphic
{
@public
  NSMutableArray *notes;
  float x1, y1, x2, y2;		/* corner offsets from clients bounds */
}


+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- setHanger;
- presetHanger;
- (BOOL) isDangler;
- (BOOL) isClosed: (NSMutableArray *) l;
- (void)removeObj;
- (BOOL) hit: (NSPoint) p;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- drawMode: (int) m;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end
