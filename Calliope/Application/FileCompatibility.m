#import "compatibility.h"

/*
 * This file is for compatibility with reading old draw/Calliope files.
 */

/*
 * This is just a convenience method for reading old Calliope files that
 * have List classes archived in them.  It creates an NSMutableArray
 * out of the passed in List.  It frees the List (it does this because
 * it assumes you are converting to the new world and want nothing to
 * do with the old world).
 */

@implementation NSMutableArray(Compatibility)

- (id)initFromList:(id)aList
{
    int i, count;

    if ([aList isKindOf:[List class]]) {
        count = [aList count];
        [self initWithCapacity:count];
        for (i = 0; i < count; i++) {
            [self addObject:[aList objectAt:i]];
        }
    } else if ([aList isKindOf:[NSArray class]]) {
        return [self initWithArray:aList];
    } else {
        /* should probably raise */
    }

    return self;
}

@end
