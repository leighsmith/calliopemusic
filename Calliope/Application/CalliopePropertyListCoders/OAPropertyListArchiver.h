/*****
OAPropertyListArchiver.h
created by mark on Wed 30-Jul-1997
Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved.

$Id$
*/

/* External imports */

/* Internal imports */
#import "OAPropertyListCoder.h"

/* Exported types declarations */

/* Class Interface */

@interface OAPropertyListArchiver : OAPropertyListCoder
{
  @private
  NSMutableDictionary	*currentDictionary; // nonretained

  NSMutableDictionary	*codedObjectsDictionary;

  NSMutableDictionary   *classVersionDictionary;
  NSMutableDictionary	*tagsForObjectsDictionary;
  NSMutableDictionary	*objectsForTagsDictionary;

  unsigned int		count;
}

+ (id)propertyListArchiver;
+ (id)propertyListWithRootObject:(id)anObject;

- (id)propertyListWithRootObject:(id)object;

- (void)setObject:(id)object forKey:(NSString *)aKey;
- (void)setSelector:(SEL)aSelector forKey:(NSString *)aKey;
- (void)setInteger:(int)anIntValue forKey:(NSString *)aKey;
- (void)setFloat:(float)aFloatValue forKey:(NSString *)aKey;
- (void)setString:(NSString *)aStringValue forKey:(NSString *)aKey;
- (void)setBool:(BOOL)aBoolValue forKey:(NSString *)aKey;
- (void)setRect:(NSRect)aRect forKey:(NSString *)aKey;
- (void)setPoint:(NSPoint)aPoint forKey:(NSString *)aKey;
- (void)setSize:(NSSize)aSize forKey:(NSString *)aKey;

@end

/* Exported informal protocols */
