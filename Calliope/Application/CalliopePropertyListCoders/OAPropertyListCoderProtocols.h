/* Protocols.h created by mark on Mon 08-Sep-1997 */

#import <Foundation/Foundation.h>

@class OAPropertyListCoder;

@protocol OAPropertyListCoding <NSObject>
- (id)initWithPropertyListCoder:(OAPropertyListCoder *)aDecoder;
- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)anEncoder;
@end
