#import "winheaders.h"
#import "Hanger.h"

/*
  style = 0:
     gFlags.subtype: 0 = (reserved), 1 = tuplet; 2 = ratio; 3 = body+dot
 if style = 1, then print a funny thing to erase
*/

@interface Tuple:Hanger
{
@public
  struct
  {
      unsigned int formliga : 3;	/* 0=nobrack 1=tupout 2=tupmid 3=tupin, 4=tieout, 5=tiein */
    unsigned int fixed : 1;  	/* whether location fixed */
    unsigned int localiga : 2;	/* 0=head 1=tail, 2=top 3=bottom */
    unsigned int above : 1;	/* whether above the group (cache) */
    unsigned int horiz : 1;	/* whether horizontally constrained */
    unsigned int centre : 1;	/* 0 = graphic, 1=temporal */
  } flags;
  char style;			/* 0 = timed; 1 = ottava */
  char uneq1, uneq2;		/* has tuple, or ratio num+den */
  char body, dot;		/* has body+dot */
  float x1, y1, x2, y2; 	/* corners (caches) */
  unsigned int centre : 1;	/* 0 = graphic, 1=temporal */
  float vtrim1, vtrim2;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- setHanger;
- (BOOL) isClosed: (NSMutableArray *) l;
- (void)removeObj;
- (float) modifyTick: (float) t;
- (int) ligaDir: (int) i;
- (BOOL) hit: (NSPoint) p;
- (float) hitDistance: (NSPoint) p;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
