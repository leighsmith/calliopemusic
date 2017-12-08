/*****
NSColor+PropertyListCoding.m
created by sbrandon on Wed 14-Jun-2000
*/

/* Internal imports */
#import "NSColor+PropertyListCoding.h"
#import "OAPropertyListCoder.h"

/* External imports */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/* Private type declarations */

/* Private method declarations */

/* Private class declarations and implementations */

/* Class Implementation */

@implementation NSColor (PropertyListCoding)

/*" A category of NSArray which provides PropertyListCoding behaviour."*/

- (Class)classForPropertyListCoder
{
  return [NSColor class];
}

- (id)initWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    NSString *ret = [aCoder stringForKey:@"value"];
    float r, g, b, a;
    NSArray *components = [ret componentsSeparatedByString:@","];
    if ([components count] < 3) return nil;
    r = [[components objectAtIndex:0] floatValue];
    g = [[components objectAtIndex:1] floatValue];
    b = [[components objectAtIndex:2] floatValue];
    a = [[components objectAtIndex:3] floatValue];
    return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    id colString = [NSString stringWithFormat:@"%f,%f,%f,%f",
        [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] redComponent],
        [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] greenComponent],
        [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] blueComponent],
        [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] alphaComponent]];

    [aCoder setString:colString forKey:@"value"];

}
@end
