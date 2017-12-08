/*****
OAPropertyListUnarchiver.h
created by mark on Wed 30-Jul-1997
Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved.

$Id$
*/

/* External imports */

/* Internal imports */
#import "OAPropertyListCoder.h"

/* Exported types declarations */

/* Class Interface */

@interface OAPropertyListUnarchiver : OAPropertyListCoder
{
  @private
  NSMutableDictionary	*currentDictionary; // nonretained

  NSMutableDictionary   *classVersionDictionary;
  NSMutableDictionary	*codedObjectsDictionary;
  NSMutableDictionary	*tagsForObjectsDictionary;
  NSMutableDictionary	*objectsForTagsDictionary;

  unsigned		count;
}

/*" Unarchiving objects from property lists "*/

+ (id)propertyListUnarchiver;
+ (id)unarchiveObjectWithPropertyList:(id)aPropertyList;

- (id)unarchiveObjectWithPropertyList:(id)aPropertyList;

/*" Reading values from a PropertyListUnarchiver "*/

- (id)objectForKey:(NSString *)aKey;
- (SEL)selectorForKey:(NSString *)aKey;
- (int)integerForKey:(NSString *)aKey;
- (BOOL)boolForKey:(NSString *)aKey;
- (float)floatForKey:(NSString *)aKey;
- (NSString *)stringForKey:(NSString *)aKey;
- (NSRect)rectForKey:(NSString *)aKey;
- (NSSize)sizeForKey:(NSString *)aKey;

@end

/* Exported informal protocols */
