#import "winheaders.h"
#import "Hanger.h"

@interface Volta:Hanger
{
@public
  id endpoint;
  char mark[4];
  char pos;
}

+ (void)initialize;
+ myInspector;
- init;
- (BOOL) getXY: (float *) x : (float *) y;
- (void)dealloc;
- (BOOL) isClosed: l;
- (void)removeObj;
- (int)keyDownString:(NSString *)cc;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
