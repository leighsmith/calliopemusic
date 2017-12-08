/*****
NSObject+ErrorHandling.h
created by mark on Sat 14-Sep-1996
Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved.

$Id$
*/

/* External imports */
#import <Foundation/Foundation.h>

/* Internal imports */

/* Exported types declarations */

/* Class Interface */

@interface NSObject (ErrorHandling)
- (void)isNotRecognized:(SEL)selector;
- (void)isSubclassResponsibility:(SEL)selector;
@end

/* Exported informal protocols */
