#ifdef WIN32
#import <stdio.h>
#import <fcntl.h>
#import <Winsock.h>
#import <malloc.h>
#import <io.h>

/*Windows does not have these!*/
#define MAXINT	((int)0x7fffffff)	/* max pos 32-bit int */
#define MININT 	((int)0x80000000)	/* max negative 32-bit integer */
#define MAXFLOAT ((float)3.4028234663852886e38)
#define MINFLOAT ((float)1.4012984643248171e-45)
#define MAXDOUBLE ((double)1.7976931348623157e308)
#define MINDOUBLE ((double)4.9406564584124654e-324)

/* MacOsX-Server does not have these!*/
#elif defined (__APPLE__)
#define MAXINT	((int)0x7fffffff)	/* max pos 32-bit int */
#define MINFLOAT ((float)1.4012984643248171e-45)
#endif
