#import "winheaders.h"
#import "StaffObj.h"

#define NUMUCLEFS 12		/* number of unique clefs */
#define NUMTCLEFS  4		/* number of clef types (C, F, G, P) */
#define MAXECLEFS  8		/* number of each type of clef */

extern char clefuid[NUMTCLEFS][MAXECLEFS];
extern unsigned char clefcpos[NUMUCLEFS];

@interface Clef:StaffObj
{
@public
  char keycentre;
  char ottava;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- (int) defaultPos;
- newFrom;
- (int) middleC;
- (BOOL) performKey: (int) c;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
