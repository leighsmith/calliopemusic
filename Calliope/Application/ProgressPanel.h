#import "winheaders.h"
#import <AppKit/AppKit.h>

@interface ProgressPanel:NSPanel
{
    id	progview;
    id	titletext;
}

- preset;
- (void)setTitle:(NSString *)s;
- setRatio: (float) f;

@end

