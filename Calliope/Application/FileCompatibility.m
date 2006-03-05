/*
 * $Id$
 * This file is for compatibility with reading old draw/Calliope files.
 */
#import <FileCompatibility.h>

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
    // TODO LMS commented out to get things compiling, this is needed to support the legacy file format
#if 0
    if ([aList isKindOf:[List class]]) {
        count = [aList count];
        [self initWithCapacity:count];
        for (i = 0; i < count; i++) {
            [self addObject:[aList objectAt:i]];
        }
    }
#else
    if(0) ;
#endif
    else if ([aList isKindOf:[NSArray class]]) {
        return [self initWithArray:aList];
    }
    else {
        /* should probably raise */
    }

    return self;
}

@end

@implementation PrintInfo

@end

@implementation Font

- initWithCoder: (NSCoder *) aDecoder
{
    float floatParam;
    char stringParam1[80], stringParam2[80];
    unsigned char dataParam[80];
    
    // [super initWithCoder:aDecoder];
    [aDecoder decodeValuesOfObjCTypes:"%fss", &dataParam, &floatParam, &stringParam1, &stringParam2];
    return self;
}

@end

@implementation View

- initWithCoder: (NSCoder *) aDecoder
{
    NSLog(@"in View initWithDecoder before super message\n");
    [super initWithCoder: aDecoder];
    return self;
}

@end

@implementation Responder

/*
- initWithCoder: (NSCoder *) aDecoder
{
    float floatParam;
    //[aDecoder decodeValuesOfObjCTypes:"f", &floatParam];
    return self;
}
*/

@end
