#import "winheaders.h"
#import <Foundation/NSObject.h>
#import <AppKit/NSFont.h>
#import "GraphicView.h"

@interface PrefBlock:NSObject
{
@public
  char unitflag;
  char tabflag;
  char barplace;
  char barsurround;
  char barnumfirst;
  char barnumlast;
  char usestyle;
  int barevery;
  NSFont *barfont;
  NSFont *tabfont;
  NSFont *figfont;
  NSFont *texfont;
  NSFont *runfont;
  NSString *pathname;
  float staffheight;
  NSString *stylepath;
  float maxbalgap;
  float minsysgap;
}

+ readFromFile: (NSString *) f;

- init;
- newFrom;
- (void)dealloc;
- (int)intValueAt:(int)i;
- (float)floatValueAt:(int)i;
- setFloatValue:(float)v at:(int)i;
- (NSFont *) fontValueAt: (int) i;
- (NSString *)stringValueAt:(int)i;
- setStringValue:(NSString *)v at:(int)i;
- setIntValue:(int)v at:(int)i;
- backup;
- revert;
- (BOOL) checkStyleFromFile: (GraphicView *) v;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
