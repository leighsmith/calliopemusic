#import "winheaders.h"
#import "Graphic.h"

#define NUMMARGINS 10

/*
  0=lmarg, 1=rmarg, 2=hmarg, 3=fmarg, 4=tmarg, 5=bmarg;
  6=lebind, 7=rebind, 8=lobind, 9=robind;
*/

@interface Margin:Graphic
{
@public
  float margin[10];
  char format, alignment;
  id client;			/* a System */
}

+ (void)initialize;
+ myInspector;
- init;
- newFrom;
- (void)removeObj;
- setPageTable: p;
- (float) leftMargin;
- (float) rightMargin;
- (float) headerBase;
- (float) footerBase;
- (float) topMargin;
- (float) bottomMargin;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- drawMode: (int) m;
- draw;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
