#import "CallPageLayout.h"
#import "DrawDocument.h"
#import "DrawApp.h"
#import "mux.h"
#import <AppKit/AppKit.h>

@implementation CallPageLayout : NSPageLayout

extern NSString *unitname[4];
float unitfactor[4] =
{
  0.013889, 0.035278, 1.0, 0.083333
};


static int unitAsInt(float f)
{
  int i;
  for (i = 0; i < 4; i++)  if (fabs(f - unitfactor[i]) < 0.0001) return i;
  NSLog(@"Unknown unit selected: inform developer.\n");
  return 0;
}


- (void)pickedUnits:(id)sender
{
    float old, new;
    int newunit; 
    [self convertOldFactor:&old newFactor:&new];
    newunit = unitAsInt(new);
    [[NSApp document] setPreferenceAsInt:newunit at: UNITS];/* obselete, really */
    [[NSUserDefaults standardUserDefaults] setObject:unitname[newunit] forKey:@"Units"];
    [super pickedUnits:sender];
}

@end
