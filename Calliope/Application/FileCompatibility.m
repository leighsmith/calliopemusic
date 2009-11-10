/*
 * $Id$
 * This file is for compatibility with reading old draw/Calliope files.
 */
#import <FileCompatibility.h>

@implementation ListDecodeFaker

/*
 * This is just a convenience method for reading old Calliope files that
 * have List classes archived in them.  It creates an NSMutableArray
 * out of the decoded elements of the List. It returns an autoreleased NSMutableArray.
 */
- initWithCoder: (NSCoder *) aDecoder
{
    unsigned int elementCount;
    NSMutableArray *replacementForList;
    
    [aDecoder decodeValuesOfObjCTypes: "i", &elementCount];
    NSLog(@"decoding List with %d elements into NSMutableArray", elementCount);
    
    // We seem to need an extra retain here, even though a retain is issued on the array when it is returned.
    // So currently, no we don't return an autoreleased array
    // replacementForList = [NSMutableArray arrayWithCapacity: elementCount];
    replacementForList = [[NSMutableArray arrayWithCapacity: elementCount] retain];
    if(elementCount > 0) { // it seems it's possible to encode zero length Lists?
	id *staticObjectArray = (id *) malloc(sizeof(id) * elementCount);
	unsigned int elementIndex;
	
	[aDecoder decodeArrayOfObjCType: "@" count: elementCount at: staticObjectArray];
	
	for (elementIndex = 0; elementIndex < elementCount; elementIndex++) {
	    NSLog(@"Decoding %@ retain count %d\n", staticObjectArray[elementIndex], [staticObjectArray[elementIndex] retainCount]);
	    [replacementForList addObject: staticObjectArray[elementIndex]];
	}    
	free(staticObjectArray);
    }
    // NSLog(@"replacementForList %p\n", replacementForList);
    return replacementForList;
}

@end

@implementation PSMatrixDecodeFaker

- (id) initWithCoder: (NSCoder *) aDecoder
{
    float matrixValues[12];
    char s[256];
    
    self = [super init]; // make sure we are in good health before doing anything wacky...
    //NSLog(@"faking out the decoding of a PSMatrix");
    [aDecoder decodeValuesOfObjCTypes: "[12f]", matrixValues];
    //NSLog(@"matrixValue[0] = %f, matrixValue[11] = %f", matrixValues[0], matrixValues[11]);
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
    unsigned char dataParam[80]; // TODO need to verify this should be an array and not a pointer.
    
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

// Yet to fully implement
#if 0
// call with
[NSUnarchiver decodeClassName: @"Tie" asClassName: @"TieDecodeFaker"];

@implementation TieDecodeFaker

- (id) initWithCoder: (NSCoder *) aDecoder
{
  char r1, r2, r3, r4, r5, r6, r7, r8, r9;
  struct oldflags f;
  int v = [aDecoder versionForClassName:@"Tie"];
  // Create a version of TieNew initialised with the parameters retrieved from the old Tie class.
  TieNew *newTieNew = [[TieNew alloc] init];

  NSLog(@"Decoding Tie v%d object instance, should be upgraded to TieNew\n", v);
  headnum = 0;
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"fccccc", &depth, &r1, &r2, &r3, &r4, &r5];
    flags.fixed = r3;
    flags.place = 0;
    flags.above = r1;
    flags.same = r5;
    flags.ed = r2;
    flags.usedepth = r4;
    flags.master = 1;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"fs", &depth, &f];
    flags.fixed = f.fixed;
    flags.place = f.place;
    flags.above = f.above;
    flags.same = f.same;
    flags.ed = f.ed;
    flags.usedepth = f.usedepth;
    flags.master = f.master;
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"fccccccc", &depth, &r1, &r2, &r3, &r4, &r5, &r6, &r7];
    flags.fixed = r1;
    flags.place = r2;
    flags.above = r3;
    flags.same = r4;
    flags.ed = r5;
    flags.usedepth = r6;
    flags.master = r7;
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"fcccccccc", &depth, &headnum, &r1, &r2, &r3, &r4, &r5, &r6, &r7];
    flags.fixed = r1;
    flags.place = r2;
    flags.above = r3;
    flags.same = r4;
    flags.ed = r5;
    flags.usedepth = r6;
    flags.master = r7;
    if (headnum > 0) headnum--;
  }
  else if (v == 4)
  {
    [aDecoder decodeValuesOfObjCTypes:"fcccccccc", &depth, &headnum, &r1, &r2, &r3, &r4, &r5, &r6, &r7];
    flags.fixed = r1;
    flags.place = r2;
    flags.above = r3;
    flags.same = r4;
    flags.ed = r5;
    flags.usedepth = r6;
    flags.master = r7;
  }
  else if (v == 5)
  {
    [aDecoder decodeValuesOfObjCTypes:"fccccccccc", &depth, &headnum, &r1, &r2, &r3, &r4, &r5, &r6, &r7, &r8];
    flags.fixed = r1;
    if (r2 > 1) r2 -= 2;  /* change of format: now all are 0 or 1 */
    flags.place = r2;
    flags.above = r3;
    flags.same = r4;
    flags.ed = r5;
    flags.usedepth = r6;
    flags.master = r7;
    flags.horvert = r8;
  }
  else if (v == 6)
  {
    [aDecoder decodeValuesOfObjCTypes:"ffcccccccccc", &depth, &flatness, &headnum, &r1, &r2, &r3, &r4, &r5, &r6, &r7, &r8, &r9];
    flags.fixed = r1;
    flags.place = r2;
    flags.above = r3;
    flags.same = r4;
    flags.ed = r5;
    flags.usedepth = r6;
    flags.master = r7;
    flags.horvert = r8;
    flags.dashed = r9;
  }
  return self;
}

@end

#endif
