/*****
OAPropertyListUnarchiver.m
created by mark on Wed 30-Jul-1997
Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved.
*/

static char rcsid[] = "Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved. $Id$";

/* Internal imports */
#import "OAPropertyListUnarchiver.h"

/* External imports */
#import "NSObject+ErrorHandling.h"

/* Private type declarations */

/* Private method declarations */
@interface OAPropertyListUnarchiver (Private)
- (id)_objectFromDictionary:(NSDictionary *)aDictionary;
@end

/* Private class declarations and implementations */

/* Class Implementation */

@implementation OAPropertyListUnarchiver

/*" Decodes arbitrary object graphs to NSPropertyList format."*/

+ (id)propertyListUnarchiver
  /*" Returns an autoreleased unarchiver."*/
{
  return [[[[self class] alloc] init] autorelease];
}

+ (id)unarchiveObjectWithPropertyList:(id)aPropertyList
  /*" Unarchives and returns an object from the property list aPropertyList."*/
{
  return [[self propertyListUnarchiver] unarchiveObjectWithPropertyList:aPropertyList];
}

- (id)_objectFromDictionary:(NSDictionary *)aDictionary
{
  id ret = nil;

  if (aDictionary != nil) {
    NSString *class = [aDictionary objectForKey:@"_class"];
    if (class != nil) {
      ret = [[NSClassFromString(class) alloc] autorelease];
    }
  }
  return ret;
}

/* Inverse of stringWithRootObject */
- (id)unarchiveObjectWithPropertyList:(id)aPropertyList
  /*" Unarchives and returns an object from the property list aPropertyList."*/
{
  id ret;
  
  id anObject;

  NSParameterAssert(aPropertyList != nil);

  codedObjectsDictionary	= aPropertyList;
  objectsForTagsDictionary	= [NSMutableDictionary dictionary];
  classVersionDictionary	= [codedObjectsDictionary objectForKey:@"_versions"];

  currentDictionary		= [codedObjectsDictionary objectForKey:@"_root"];

  anObject = [self _objectFromDictionary:currentDictionary];
  [objectsForTagsDictionary setObject:[NSValue valueWithNonretainedObject:anObject] forKey:@"_root"];

  ret = [anObject initWithPropertyListCoder:self];

  codedObjectsDictionary	= nil;
  objectsForTagsDictionary	= nil;
  classVersionDictionary	= nil;
  
  return ret;
}

- (unsigned)versionForClassName:(NSString *)aName
  /*" Returns the version number used to archive classes named aName."*/
{
  if (classVersionDictionary == nil) {
    return 0;
  } else {
    id object;
    object = [classVersionDictionary objectForKey:aName];
    if (object == nil) {
      return NSNotFound;
    } else {
      return [object intValue];
    }
  }
}

/* Inverse of setObject:forKey: */

- (id)objectForKey:(NSString *)aKey
  /*" Decodes the object stored under key aKey."*/
{
  NSString *objectTag;
  NSValue *objectValue;

  NSParameterAssert(aKey != nil);

  objectTag = [currentDictionary objectForKey:aKey];

  /* We may want to delegate this to allow error handling,
    as this is suspect: ask to decode an attribute that plain
    doesn't exist! */
  
  if (objectTag == nil)
    return nil;
  
  if ([objectTag isEqualToString:@"nil"])
    return nil;
  
    // if the object hasn't been decoded yet...
  if ((objectValue = [objectsForTagsDictionary objectForKey:objectTag]) == nil) {
    id anObject;
    
        // remember the dictionary we are working on
    NSMutableDictionary *originalDictionary = currentDictionary;
    
        // read in the object tag for our yet-to-be-decoded object
    currentDictionary = [codedObjectsDictionary objectForKey:objectTag];
    anObject = [self _objectFromDictionary:currentDictionary];
    objectValue = [NSValue valueWithNonretainedObject:anObject];
    [objectsForTagsDictionary setObject:objectValue forKey:objectTag];
    
        // decode the object
    anObject = [[anObject initWithPropertyListCoder:self] retain];
    objectValue = [NSValue valueWithNonretainedObject:anObject];
    [objectsForTagsDictionary setObject:objectValue forKey:objectTag];
    
        // return to the original dictionary
    currentDictionary = originalDictionary;
  }

  return [objectValue nonretainedObjectValue];
}

// Decoding atomic values from the coder

- (SEL)selectorForKey:(NSString *)aKey
  /*" Decodes the selector stored under key aKey."*/
{
  NSString *s;

  NSParameterAssert(aKey != nil);

  s = [currentDictionary objectForKey:aKey];
  if ([s length] == 0) {
    return NULL;
  } else {
    return NSSelectorFromString(s);
  }
}

- (int)integerForKey:(NSString *)aKey
  /*" Decodes the integer stored under key aKey."*/
{
  NSString *s;
  NSParameterAssert(aKey != nil);

  s = [currentDictionary objectForKey:aKey];
  return [s intValue];
}

- (BOOL)boolForKey:(NSString *)aKey
  /*" Decodes the BOOL stored under key aKey."*/
{
  NSString *s;
  NSParameterAssert(aKey != nil);

  s = [currentDictionary objectForKey:aKey];
  return [s isEqualToString:@"YES"];
}

- (float)floatForKey:(NSString *)aKey
  /*" Decodes the float stored under key aKey."*/
{
  NSString *s;
  NSParameterAssert(aKey != nil);

  s = [currentDictionary objectForKey:aKey];
  return [s floatValue];
}

- (NSString *)stringForKey:(NSString *)aKey
  /*" Decodes the string stored under key aKey."*/
{
  NSString *s;
  NSParameterAssert(aKey != nil);

  s = [currentDictionary objectForKey:aKey];
  return s;
}

- (NSRect)rectForKey:(NSString *)aKey
  /*" Decodes the NSRect stored under key aKey."*/
{
  NSString *s;
  NSParameterAssert(aKey != nil);

  s = [currentDictionary objectForKey:aKey];
  return NSRectFromString(s);
}

- (NSPoint)pointForKey:(NSString *)aKey
  /*" Decodes the NSPoint stored under key aKey."*/
{
  NSString *s;
  NSParameterAssert(aKey != nil);

  s = [currentDictionary objectForKey:aKey];
  return NSPointFromString(s);
}

- (NSSize)sizeForKey:(NSString *)aKey
  /*" Decodes the NSSize stored under key aKey."*/
{
  NSString *s;
  NSParameterAssert(aKey != nil);

  s = [currentDictionary objectForKey:aKey];
  return NSSizeFromString(s);
}

@end
