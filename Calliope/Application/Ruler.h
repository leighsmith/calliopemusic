#import <AppKit/NSView.h>
#import <AppKit/NSFont.h>

@interface Ruler : NSView
{
    id font;
    float descender;
    float startX;
    float lastlp, lasthp;
    BOOL notHidden;
}

+ (float)width;

- showPosition:(float)lp :(float)hp;
- hidePosition;

- (void)setFont:(NSFont *)aFont;
- (void)drawRect:(NSRect)rect;

@end
