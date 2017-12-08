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

@implementation NSDictionary (PropertyListCoding)
/*" A category of NSDictionary which provides PropertyListCoding behaviour."*/

- (Class)classForPropertyListCoder
{
  return [NSDictionary class];
}

- (id)initWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
  id ret;
  int i, count = [aCoder integerForKey:@"count"];

  if (count > 0) {
    NSZone *z = [self zone];
    id *keys = (id*)NSZoneMalloc(z, sizeof(id) * count);
    id *values = (id*)NSZoneMalloc(z, sizeof(id) * count);

    for (i = 0; i < count; i++) {
      keys[i] = [aCoder objectForKey:[NSString stringWithFormat:@"key%d",i]];
      values[i] = [aCoder objectForKey:[NSString stringWithFormat:@"object%d",i]];
    }
    ret = [self initWithObjects:values forKeys:keys count:count];

    NSZoneFree(z, keys);
    NSZoneFree(z, values);
  } else {
    ret = [self init];
  }

  return ret;
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
  int		i, count = [self count];
  NSEnumerator	*keyEnumerator = [self keyEnumerator];

  [aCoder setInteger:count forKey:@"count"];

  for (i = 0; i < count; i++) {
    id key = [keyEnumerator nextObject];
    id value = [self objectForKey:key];
    
    NSString *keyS = [NSString stringWithFormat:@"key%d",i];
    NSString *valueS = [NSString stringWithFormat:@"object%d",i];

    [aCoder setObject:key forKey:keyS];
    [aCoder setObject:value forKey:valueS];
  }
}

@end
