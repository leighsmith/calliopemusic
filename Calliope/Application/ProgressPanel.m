
#import "ProgressPanel.h"

@implementation ProgressPanel

- preset
{
  [progview init];
  [progview clear:self];
  [titletext setStringValue:@""];
  return self;
}


- (void)setTitle:(NSString *)s
{
  [titletext setStringValue:s];
}


- setRatio: (float) f
{
  return [progview setRatio: f];
}

@end
