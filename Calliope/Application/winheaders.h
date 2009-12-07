/* $Id$
 System specific includes.
 Nowdays we should try to avoid defining and using these.
 */

/*  Windows does not have these! */
#if defined (WIN32)
#import <stdio.h>
#import <fcntl.h>
#import <Winsock.h>
#import <malloc.h>
#import <io.h>
#endif

#import <math.h>

#ifndef MAXINT
#define MAXINT	((int)0x7fffffff)	/* max pos 32-bit int */
#endif

#ifndef MAXFLOAT
#define MAXFLOAT ((float)3.4028234663852886e38)
#endif

#ifndef MINFLOAT
#define MINFLOAT ((float)1.4012984643248171e-45)
#endif
