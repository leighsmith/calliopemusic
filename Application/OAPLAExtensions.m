/*****
OAPLAExtensions.m
created by sbrandon on Wed 14-Jun-2000
*/

#import "OAPLAExtensions.h"
#import <CalliopePropertyListCoders/OAPropertyListCoder.h>
#import <Foundation/Foundation.h>


@implementation CalliopePropertyListArchiver : OAPropertyListArchiver

/*" A subclass of OAPropertyListArchiver which adds conditional encoding behaviour."*/
- init
{
    id ret = [super init];
    conditionalObjectsArray = [[NSMutableArray alloc] init];
    return ret;
}

- (void)setConditionalObject:(id)anObject forKey:(NSString *)aKey
{
    NSString *objectTag;
    NSValue *objectValue;

    NSParameterAssert(aKey != nil);
    /* NSCoders set nil for conditional objects that are nil */
    if (anObject == nil) {
      [self setObject:@"nil" forKey:aKey];
      return;
    }

    objectValue = [NSValue valueWithNonretainedObject:anObject];
    /* we already have the object unconditionally encoded. We could leave this till later,
        but why not just do it now? */
//    if ((objectTag = [tagsForObjectsDictionary objectForKey:objectValue])) {
//        [self setObject:anObject forKey:aKey];
//        return;
//    }
    /* so it hasn't been encoded yet: we add it to a list to do later, after all official
        objects have been encoded. */
    [conditionalObjectsArray addObject:objectValue];
    [conditionalObjectsArray addObject:objectValue];
}




@end
