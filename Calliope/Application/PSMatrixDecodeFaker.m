//
//  PSMatrixDecodeFaker.m
//  Calliope
//
//  Created by Leigh Smith on 30/03/06.
//  Copyright 2006 Oz Music Code LLC. All rights reserved.
//

#import "PSMatrixDecodeFaker.h"


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
    NSLog(@"s = %s", s);
    return self;
}

@end
