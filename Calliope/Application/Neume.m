
/* OLD FORMAT:  JUST ENOUGH CODE TO READ IT IN */

#import "Neume.h"
#import "NeumeInspector.h"
#import "KeySig.h"
#import "GraphicView.h"
#import "Staff.h"
#import "System.h"
#import <AppKit/NSGraphics.h>
#import "draw.h"
#import "mux.h"
#import "muxlow.h"

@implementation Neume

extern int needUpgrade;

+ (void)initialize
{
  if (self == [Neume class])
  {
      (void)[Neume setVersion: 1];		/* class version, see read: */
  }
  return;
}


- drawMode: (int) m
{
  crect(x - 4, y - 4, 8, 8, m);
  return self;
}



/* archiving */

struct oldflags		/* for old version */
{
  unsigned int dot : 4;
  unsigned int vepisema : 4;
  unsigned int hepisema : 4;
  unsigned int quilisma : 4;
  unsigned int molle : 4;
  unsigned int num : 2;
};


/* convert old Molle to Keysig */
#define MOLLE 9

- awakeAfterUsingCoder:(NSCoder *)aDecoder;
{
  KeySig *q;
  if (gFlags.subtype != MOLLE) return nil;
  q =  [[KeySig alloc] init];
  q->x = x;
  q->y = y;
  q->p = p;
  q->mystaff = mystaff;
  q->gFlags.subtype = 2;
  q->keystr[6] = 1;
  [self release];
  return q;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  struct oldflags f;
  char b1, b2, b3, b4, b5, b6;
  needUpgrade |= 2;
  [super initWithCoder:aDecoder];
  if ([aDecoder versionForClassName:@"Neume"] == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"cci", &p2, &p3, &f];
    nFlags.dot = f.dot;
    nFlags.vepisema = f.vepisema;
    nFlags.hepisema = f.hepisema;
    nFlags.quilisma = f.quilisma;
    nFlags.molle = f.molle;
    nFlags.num = f.num;
  }
  else
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccccc", &p2, &p3, &b1, &b2, &b3, &b4, &b5, &b6];
    nFlags.dot = b1;
    nFlags.vepisema = b2;
    nFlags.hepisema = b3;
    nFlags.quilisma = b4;
    nFlags.molle = b5;
    nFlags.num = b6;
  }
  return self;
}


@end
