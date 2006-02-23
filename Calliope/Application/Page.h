#import "winheaders.h"
#import <Foundation/NSObject.h>
#import <AppKit/NSGraphics.h>
#import "System.h"

@class GraphicView;

@interface Page:NSObject
{
@public;
  int num;
  short topsys;
  short botsys;
  float fillheight;		/* sums to page height (as screened) */
  id headfoot[12];
  char hfinfo[12];
  float margin[10];
  char format, alignment;
}

+ initPage;
- init: (int) n : (int) s0 : (int) s1;
- (void)dealloc;
- prevTable: (Page *) p;
- (float) headerBase;
- (float) footerBase;
- (float) leftMargin;
- (float) rightMargin;
- (float) topMargin;
- (float) bottomMargin;

- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- draw: (NSRect) r : (BOOL) nso;
- drawSysSep: (NSRect) r : (System *) s : (GraphicView *) v;
@end
