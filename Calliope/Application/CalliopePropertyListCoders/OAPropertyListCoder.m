/*****
OAPropertyListCoder.m
created by mark on Wed 30-Jul-1997
Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved.
*/

static char rcsid[] = "Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved. $Id$";

/* Internal imports */
#import "OAPropertyListCoder.h"

/* External imports */
#import "NSObject+ErrorHandling.h"

/* Private type declarations */

/* Private method declarations */

/* Private class declarations and implementations */

/* Class Implementation */

@implementation OAPropertyListCoder

/*" Abstract superclass for objects with encode and decode arbitrary
obejct  graphs to and from NSPropertyList format."*/

- (unsigned)versionForClassName:(NSString *)aName
  /* Returns the version number for class name aName."*/
{
  [self isSubclassResponsibility:_cmd];
  return NSNotFound;
}

- (void)setObject:(id)anObject forKey:(NSString *)aKey
/*" Encodes anObject with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
}
- (void)setSelector:(SEL)aSelector forKey:(NSString *)aKey
  /*" Encodes aSelector with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
}
- (void)setInteger:(int)anIntValue forKey:(NSString *)aKey
  /*" Encodes anIntValue with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
}
- (void)setString:(NSString *)aStringValue forKey:(NSString *)aKey
  /*" Encodes aStringValue with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
}
- (void)setFloat:(float)aFloatValue forKey:(NSString *)aKey
  /*" Encodes aFloatValue with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
}
- (void)setBool:(BOOL)aBoolValue forKey: (NSString *)aKey
  /*" Encodes aBoolValue with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
}
- (void)setRect:(NSRect)aRect forKey:(NSString *)aKey
  /*" Encodes aRect with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
}
- (void)setPoint:(NSPoint)aPoint forKey:(NSString *)aKey
  /*" Encodes aPoint with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
}
- (void)setSize:(NSSize)aSize forKey:(NSString *)aKey
  /*" Encodes aSize with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
}

- (id)objectForKey:(NSString *)aKey;
  /*" Decodes the object stored with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
  return nil;
}
- (SEL)selectorForKey:(NSString *)aKey
  /*" Decodes the selector stored with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
  return NULL;
}
- (int)integerForKey:(NSString *)aKey
  /*" Decodes the integer stored with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
  return 0;
}
- (BOOL)boolForKey:(NSString *)aKey
  /*" Decodes the BOOL stored with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
  return NO;
}
- (float)floatForKey:(NSString *)aKey
  /*" Decodes the float stored with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
  return 0.0;
}
- (NSString *)stringForKey:(NSString *)aKey
  /*" Decodes the NSString stored with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
  return nil;
}
- (NSRect)rectForKey:(NSString *)aKey
  /*" Decodes the NSRect stored with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
  return NSZeroRect;
}
- (NSPoint)pointForKey:(NSString *)aKey
  /*" Decodes the NSPoint stored with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
  return NSZeroPoint;
}
- (NSSize)sizeForKey:(NSString *)aKey
  /*" Decodes the NSSize stored with key aKey."*/
{
  [self isSubclassResponsibility:_cmd];
  return NSZeroSize;
}

@end

