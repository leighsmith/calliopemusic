/*****
NSFont+PropertyListCoding.m
created by sbrandon on Wed 14-Jun-2000
*/

/* Internal imports */
#import "NSFont+PropertyListCoding.h"
#import <CalliopePropertyListCoders/OAPropertyListCoder.h>

/* External imports */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/* Private type declarations */

/* Private method declarations */

/* Private class declarations and implementations */

/* Class Implementation */

@implementation NSFont (PropertyListCoding)

/*" A category of NSArray which provides PropertyListCoding behaviour."*/

- (Class)classForPropertyListCoder
{
  return [NSFont class];
}

- (id)initWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    NSString *name = [aCoder stringForKey:@"n"];
    float size = [aCoder floatForKey:@"s"];
    return [NSFont fontWithName:name size:size];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [aCoder setString:[self fontName] forKey:@"n"];
    [aCoder setFloat:[self pointSize] forKey:@"s"];

}
@end
