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

@implementation NSData (PropertyListCoding)
/*" A category of NSData which provides PropertyListCoding behaviour."*/

- (Class)classForPropertyListCoder
{
  return [NSData class];
}

- (id)initWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
  NSZone		 *z = [self zone];

  int			 i, length = [aCoder integerForKey:@"length"];
  const unsigned char	 *bytes = [[aCoder stringForKey:@"bytes"] cString];

  unsigned char	 *dehexBytes = NSZoneMalloc(z, sizeof(unsigned char) * length);

  for (i = 0; i < length; i++) {
    int  val;

    sscanf(bytes + (2 * i), "%02x", &val);
    dehexBytes[i] = (unsigned char)val;
  }

  return [self initWithBytesNoCopy:dehexBytes length:length];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
  NSZone			*z = [self zone];
  
  int				i, length = [self length];
  
  const unsigned char		*bytes = [self bytes];

  NSString			*hexString = nil;
  unsigned char		*hexBytes = NSZoneMalloc(z, sizeof(unsigned char) * (length*2+1));
  
  [aCoder setInteger:length forKey:@"length"];

  for (i = 0; i < length; i++) {
    sprintf(hexBytes + (i * 2), "%02x", bytes[i]);
  }

  hexString = [[NSString allocWithZone:z]
    initWithCStringNoCopy:hexBytes
                  length:length*2
            freeWhenDone:YES];

  [aCoder setString:hexString forKey:@"bytes"];

  [hexString release];
}

@end
