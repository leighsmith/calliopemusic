#import "winheaders.h"
#import "Graphic.h"

@class Page;

// Differnt types of margins.
typedef enum {
    MarginLeft = 0,
    MarginRight = 1,
    MarginHeader = 2,
    MarginFooter = 3,
    MarginTop = 4,
    MarginBottom = 5,
    MarginLeftEvenBinding = 6,
    MarginRightEvenBinding = 7,
    MarginLeftOddBinding = 8,
    MarginRightOddBinding = 9,
    MaximumMarginTypes
} MarginType;

@interface Margin: Graphic
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
- setPageTable: (Page *) p;
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
