/*
 * $Id$
 * This file is for compatibility with reading old draw/Calliope files.
 */
#import <FileCompatibility.h>

@implementation ListDecodeFaker

/*
 * This is just a convenience method for reading old Calliope files that
 * have List classes archived in them.  It creates an NSMutableArray
 * out of the decoded elements of the List. It returns a NSMutableArray.
 */
- initWithCoder: (NSCoder *) aDecoder
{
    unsigned int elementIndex, elementCount;
    NSMutableArray *replacementForList;
    id *staticObjectArray;
    
    [aDecoder decodeValuesOfObjCTypes: "i", &elementCount];
    NSLog(@"decoding List with %d elements", elementCount);
    
    replacementForList = [NSMutableArray arrayWithCapacity: elementCount];
    staticObjectArray = (id *) malloc(sizeof(id) * elementCount);
    
    [aDecoder decodeArrayOfObjCType: "@" count: elementCount at: staticObjectArray];
	
#if 0
    for (elementIndex = 0; elementIndex < elementCount; elementIndex++) {
	id arrayElement;
	
	[aDecoder decodeValuesOfObjCTypes: "[1@]", &arrayElement];
	[replacementForList addObject: arrayElement];
    }
#else
    for (elementIndex = 0; elementIndex < elementCount; elementIndex++) {
	
	[replacementForList addObject: staticObjectArray[elementIndex]];
    }    
#endif
    free(staticObjectArray);
    
    // should these be retained or should the receiving decoder do this?
    return replacementForList;
}

@end

@implementation PSMatrixDecodeFaker

- (id) initWithCoder: (NSCoder *) aDecoder
{
    float matrixValues[12];
    char s[256];
    
    self = [super init]; // make sure we are in good health before doing anything wacky...
    NSLog(@"faking out the decoding of a PSMatrix");
    [aDecoder decodeValuesOfObjCTypes: "[12f]", matrixValues];
    NSLog(@"matrixValue[0] = %f, matrixValue[11] = %f", matrixValues[0], matrixValues[11]);
    [aDecoder decodeValuesOfObjCTypes: "s", s];
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
