/*****
OAPropertyListArchiver.m
created by mark on Wed 30-Jul-1997
Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved.
*/

static char rcsid[] = "Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved. $Id$";

/* Internal imports */
#import "OAPropertyListArchiver.h"

/* External imports */
#import "NSObject+ErrorHandling.h"

/* Private type declarations */

/* Private method declarations */
@interface OAPropertyListArchiver (Private)
- (void)_setVersionForObject:(id)anObject;
- (NSMutableDictionary *)_newRetainedDictionaryForObject:(id)anObject;
@end

/* Private class declarations and implementations */

/* Class Implementation */

@implementation OAPropertyListArchiver

/*" Encodes arbitrary object graphs to NSPropertyList format."*/

+ (id)propertyListArchiver
  /*" Returns an autoreleased property list archiver.."*/
{
  return [[[[self class] alloc] init] autorelease];
}

+ (id)propertyListWithRootObject:(id)anObject
  /*" Archives anObject to an NSPropertyList and returns the list."*/
{
  return [[self propertyListArchiver] propertyListWithRootObject:anObject];
}

- (void)_setVersionForObject:(id)anObject
{
  NSString *key;
  NSString *value;

  key = NSStringFromClass([anObject class]);
  value = [NSString stringWithFormat:@"%d", [[anObject class] version]];
  
  [classVersionDictionary setObject:value forKey:key];
}

- (NSMutableDictionary *)_newRetainedDictionaryForObject:(id)anObject
/* Returns a new, retained mutable dictionary meant to contain anObject */
{
  Class class;
  NSMutableDictionary *ret = [[NSMutableDictionary allocWithZone:[self zone]] init];

  if ([anObject respondsToSelector:@selector(classForPropertyListCoder)]) {
    class = [anObject classForPropertyListCoder];
  } else {
    class = [anObject class];
  }
  [ret setObject:NSStringFromClass(class) forKey:@"_class"];
  return ret;
}

- (id)propertyListWithRootObject:(id)anObject
  /*" Archives anObject to an NSPropertyList and returns the list."*/
{
  NSDictionary *ret;

  NSParameterAssert(anObject != nil);

  count				= 0;
  classVersionDictionary	= [NSMutableDictionary dictionary];
  codedObjectsDictionary	= [NSMutableDictionary dictionary];
  tagsForObjectsDictionary	= [NSMutableDictionary dictionary];

  [self _setVersionForObject:anObject];
  currentDictionary = [self _newRetainedDictionaryForObject:anObject];

  [tagsForObjectsDictionary setObject:@"_root" forKey:[NSValue valueWithNonretainedObject:anObject]];
  [codedObjectsDictionary setObject:currentDictionary forKey:@"_root"];
  [codedObjectsDictionary setObject:classVersionDictionary forKey:@"_versions"];

  [anObject encodeWithPropertyListCoder:self];

  ret = codedObjectsDictionary;

  count				= 0;
  classVersionDictionary	= nil;
  codedObjectsDictionary	= nil;
  tagsForObjectsDictionary	= nil;

  return ret;
}

/*" Encoding an object onto the coder "*/
- (void)setObject:(id)anObject forKey:(NSString *)aKey
  /*" Encodes anObject with key value aKey."*/
{
  NSString *objectTag;
  NSValue *objectValue;

  NSParameterAssert(aKey != nil);

  if (anObject == nil) {
    [currentDictionary setObject:@"nil" forKey:aKey];
    return;
  }

  objectValue = [NSValue valueWithNonretainedObject:anObject];
  
    // if the object hasn't been encoded yet...
  if ((objectTag = [tagsForObjectsDictionary objectForKey:objectValue]) == nil) {
    
        // remember the dictionary we are working on
    NSMutableDictionary *originalDictionary = currentDictionary;
    
        // create an object tag for our yet-to-be-encoded object
    objectTag = [NSString stringWithFormat:@"Object%u", count++];
    [tagsForObjectsDictionary setObject:objectTag forKey:objectValue];
    
        // create a new dictionary for the object and work on encoding that object
    [self _setVersionForObject:anObject];
    currentDictionary = [self _newRetainedDictionaryForObject:anObject];
    [codedObjectsDictionary setObject:currentDictionary forKey:objectTag];
    [anObject encodeWithPropertyListCoder:self];
    
        // return to the original dictionary
    currentDictionary = originalDictionary;
  }
  
    // simply set the associated value to be the tag of the object
  [currentDictionary setObject:objectTag forKey:aKey];
}

// Encoding atomic values onto the coder

- (void)setSelector:(SEL)aSelector forKey:(NSString *)aKey
  /*" Encodes aSelector with key value aKey."*/
{
  NSString *v;
  if (aSelector != NULL) {
    v = @"";
  } else {
    v = NSStringFromSelector(aSelector);
    if (v = nil) {
      v = @"";
    }
  }
  [currentDictionary setObject:v forKey:aKey];
}

- (void)setInteger:(int)anIntValue forKey:(NSString *)aKey
  /*" Encodes anIntValue with key value aKey."*/
{
  NSString *v;
  NSParameterAssert(aKey != nil);

  v = [NSString stringWithFormat:@"%d", anIntValue];
  [currentDictionary setObject:v forKey:aKey];
}

- (void)setString:(NSString *)aStringValue forKey:(NSString *)aKey
  /*" Encodes aStringValue with key value aKey."*/
{
  NSParameterAssert(aKey != nil);
  [currentDictionary setObject:(aStringValue) ? aStringValue : @"" forKey:aKey];
}

- (void)setFloat:(float)aFloatValue forKey:(NSString *)aKey
  /*" Encodes aFloatValue with key value aKey."*/
{
  NSString *v;
  NSParameterAssert(aKey != nil);

  v = [NSString stringWithFormat:@"%f", aFloatValue];
  [currentDictionary setObject:v forKey:aKey];
}

- (void)setBool:(BOOL)aBoolValue forKey: (NSString *)aKey
  /*" Encodes aBoolValue with key value aKey."*/
{
  NSString *v;
  NSParameterAssert(aKey != nil);

  v = aBoolValue ? @"YES" : @"NO";
  [currentDictionary setObject:v forKey:aKey];
}

- (void)setRect:(NSRect)aRect forKey:(NSString *)aKey
  /*" Encodes aRect with key value aKey."*/
{
  NSString *v;
  NSParameterAssert(aKey != nil);

  v = NSStringFromRect(aRect);
  [currentDictionary setObject:v forKey:aKey];
}

- (void)setPoint:(NSPoint)aPoint forKey:(NSString *)aKey
  /*" Encodes aPoint with key value aKey."*/
{
  NSString *v;
  NSParameterAssert(aKey != nil);

  v = NSStringFromPoint(aPoint);
  [currentDictionary setObject:v forKey:aKey];
}

- (void)setSize:(NSSize)aSize forKey:(NSString *)aKey
  /*" Encodes aSize with key value aKey."*/
{
  NSString *v;
  NSParameterAssert(aKey != nil);

  v = NSStringFromSize(aSize);
  [currentDictionary setObject:v forKey:aKey];
}

@end
