/*****
OAPropertyListCoder.h
created by mark on Wed 30-Jul-1997
Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved.

$Id$
*/

/* External imports */
#import <Foundation/Foundation.h>

/* Internal imports */

/* Exported types declarations */

/* Class Interface */

@interface OAPropertyListCoder : NSObject

- (unsigned)versionForClassName:(NSString *)aName;

- (void)setObject:(id)object forKey:(NSString *)aKey;
- (id)objectForKey:(NSString *)aKey;

- (void)setSelector:(SEL)aSelector forKey:(NSString *)aKey;
- (SEL)selectorForKey:(NSString *)aKey;

- (void)setInteger:(int)anIntValue forKey:(NSString *)aKey;
- (int)integerForKey:(NSString *)aKey;

- (void)setFloat:(float)aFloatValue forKey:(NSString *)aKey;
- (float)floatForKey:(NSString *)aKey;

- (void)setString:(NSString *)aStringValue forKey:(NSString *)aKey;
- (NSString *)stringForKey:(NSString *)aKey;

- (void)setBool:(BOOL)aBoolValue forKey:(NSString *)aKey;
- (BOOL)boolForKey:(NSString *)aKey;

- (void)setRect:(NSRect)aRect forKey:(NSString *)aKey;
- (NSRect)rectForKey:(NSString *)aKey;

- (void)setPoint:(NSPoint)aRect forKey:(NSString *)aKey;
- (NSPoint)pointForKey:(NSString *)aKey;

- (void)setSize:(NSSize)aSize forKey:(NSString *)aKey;
- (NSSize)sizeForKey:(NSString *)aKey;

@end

/* Exported informal protocols */

@interface NSObject (PropertyListCoding)

- (Class)classForPropertyListCoder;

- (id)initWithPropertyListCoder:(OAPropertyListCoder *)coder;
- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)coder;

@end

