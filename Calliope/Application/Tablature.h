#import "winheaders.h"
#import "TimedObj.h"

struct tabinfo
{
  unsigned int body : 3;		/* type of flag body */
  unsigned int direction : 1;		/* reading top-down or bottum-up */
  unsigned int cipher : 1;		/* whether numbers or letters */
  unsigned int typeface : 1;		/* whether RomanItalic or 17C book */
  unsigned int online : 1;		/* whether on spaces or lines */
  unsigned int prevtime : 1;		/* whether to omit flag */
};


@interface Tablature:TimedObj
{
@public
  struct tabinfo flags;
    NSString *tuning;
  char chord[6];
  char selnote;
  char diapason;
  char diafret;
}

+ (void)initialize;
+ myPrototype;
+ myInspector;
- init;
- (void)dealloc;
- recalc;
- reShape;
- setstem: (int) m;
- (BOOL) hitBeamAt: (float *) px : (float *) py;
- (BOOL) isBeamable;
- (int) tabCount;
- (float) noteEval: (BOOL) f;
- (int) incrementNoteCodeBy: (int) a;
- (int) getPatch;
- (int)keyDownString:(NSString *)cc;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
