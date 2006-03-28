#import <Foundation/Foundation.h>
#include <string.h>

/* PSWrapsInit() sets up various definitions used by the main wraps */
void PSWrapsInit( void )
{
    NSLog(@"Called PSWrapsInit(), needs implementation\n");
}


/* These are what are called from main program */
void PSmovegray(float x, float y, float g)
{
    NSLog(@"Called PSmovegray(), needs implementation\n");
}

void PSslant(float w, float h, float dy, float x, float y)
{
    NSLog(@"Called PSslant(), needs implementation\n");
}

void PStie(float cx, float cy, float dy, float rh, float hw, float mh, float ln, float a)
{
    NSLog(@"Called PStie(), needs implementation\n");
}

void PStiedash(float cx, float cy, float dy, float hw, float mh, float ln, float a)
{
    NSLog(@"Called PStiedash(), needs implementation\n");
}

void PStietext(float w, float rh, float hw, float mh, float g, float dr)
{
    NSLog(@"Called PStietext(), needs implementation\n");
}

void PSellipse(float cx, float cy, float rx, float ry, float a1, float a2)
{
    NSLog(@"Called PSellipse(), needs implementation\n");
}

void PSsetorigin(float cx, float cy, float a)
{
    NSLog(@"Called PSsetorigin(), needs implementation\n");
}

void PSresetorigin( void )
{
    NSLog(@"Called PSresetorigin(), needs implementation\n");
}


