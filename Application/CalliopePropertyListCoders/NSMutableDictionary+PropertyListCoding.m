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

@implementation NSMutableDictionary (PropertyListCoding)
/*" A category of NSMutableDictionary which provides PropertyListCoding behaviour."*/

- (Class)classForPropertyListCoder
{
  return [NSMutableDictionary class];
}

@end
