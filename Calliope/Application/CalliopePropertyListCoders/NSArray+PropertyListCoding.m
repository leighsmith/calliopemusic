/*****
NSArray+PropertyListCoding.m
created by mark on Wed 30-Jul-1997
Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved.
*/

static char rcsid[] = "Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved. $Id$";

/* Internal imports */
#import "OAPropertyListCoder.h"

/* External imports */
#import <Foundation/Foundation.h>

/* Private type declarations */

/* Private method declarations */

/* Private class declarations and implementations */

/* Class Implementation */

@implementation NSArray (PropertyListCoding)

/*" A category of NSArray which provides PropertyListCoding behaviour."*/

- (Class)classForPropertyListCoder
{
  return [NSArray class];
}

- (id)initWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
  id ret;
  int i, count = [aCoder integerForKey:@"count"];

  if (count > 0) {
    NSZone *z = [self zone];
    id *buf = (id *)NSZoneMalloc(z, sizeof(id) * count);

    for (i = 0; i < count; i++) {
      buf[i] = [aCoder objectForKey:[NSString stringWithFormat:@"object%d",i]];
    }
    
    ret = [self initWithObjects:buf count:count];

    NSZoneFree(z, buf);
  } else {
    ret = [self init];
  }
  
  return ret;
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
  int i;
  int count = [self count];

  [aCoder setInteger:count forKey:@"count"];

  for (i = 0; i < count; i++) {
    [aCoder setObject:[self objectAtIndex:i] forKey:[NSString stringWithFormat:@"object%d", i]];
  }
}
@end
