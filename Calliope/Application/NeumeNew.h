#import "winheaders.h"
#import "TimedObj.h"
#import "Neume.h"

/* NEUME gFlags.subtype */

#define PUNCTA 0
#define VIRGA 1
#define PUNCTINC 2
#define PODATUS 3
#define CLIVIS 4
#define EPIPHONUS 5
#define CEPHALICUS 6
#define PORRECTUS 7
#define TORCULUS 8
#define MOLLE 9


@interface NeumeNew:TimedObj
{
@public
  char p2, p3;
  struct
  {
    unsigned int dot : 5;
    unsigned int vepisema : 5;
    unsigned int hepisema : 5;
    unsigned int quilisma : 5;
    unsigned int molle : 5;
    unsigned int num : 4;
    unsigned int halfSize : 1;
  } nFlags;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- setNeume;
- upgradeFrom: (Neume *) n;
- (BOOL) reCache: (float) sy : (int) ss;
- reShape;
- (float) noteEval: (BOOL) f;
- (BOOL) getPos: (int) i : (int *) p : (int *) d : (int *) m : (float *) q;
- (BOOL) hit: (NSPoint) p;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;



@end
