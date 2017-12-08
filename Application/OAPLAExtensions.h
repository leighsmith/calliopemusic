/*****
OAPLAExtensions.m
created by sbrandon on Wed 14-Jun-2000
*/

#import <Foundation/Foundation.h>
#import <CalliopePropertyListCoders/OAPropertyListCoderProtocols.h>
#import <CalliopePropertyListCoders/OAPropertyListArchiver.h>


@interface CalliopePropertyListArchiver : OAPropertyListArchiver
{
    NSMutableArray *conditionalObjectsArray;
}

- (void)setConditionalObject:(id)anObject forKey:(NSString *)aKey;

@end
