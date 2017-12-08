#import "CallPageLayout.h"
#import "OpusDocument.h"
#import "CalliopeAppController.h"
#import "DrawingFunctions.h"
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


- (void) pickedUnits: (id) sender
{
    float old, new;
    int newunit; 
    
    [self convertOldFactor:&old newFactor:&new];
    newunit = unitAsInt(new);
    // TODO Should use the standard system wide default but allow users to override in case Americans are working on
    // European scores or similar.
    [[NSUserDefaults standardUserDefaults] setObject: unitname[newunit] forKey: @"Units"];
    [super pickedUnits:sender];
}

@end
