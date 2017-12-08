/*****
NSObject+ErrorHandling.m
created by mark on Sat 14-Sep-1996
Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved.
*/

static char rcsid[] = "Copyright 1997 by M. Onyschuk and Associates Inc. All Rights Reserved. $Id$";

/* Internal imports */
#import "NSObject+ErrorHandling.h"

/* External imports */

/* Private type declarations */

/* Private method declarations */

/* Private class declarations and implementations */

/* Class Implementation */

@implementation NSObject (ErrorHandling)
/*" A category of object which implements several methods used to stub methods which
must be implemented by subclasses, or which should not be called..

To stub a method #bar in an abstract superclass #Foo, implement the body of #bar
as a message to #isErrorHandling: passing the selector #bar as an
argument.

To revoke a method, so that calling it raises an exception, use the method
#isNotRecognized: passing the selector as an argument."*/

- (void)isNotRecognized:(SEL)aSelector
  /*" Raises an NSInternalInconsistecy Exception with a standard format."*/
{
  NSString *class 	= NSStringFromClass([self class]);
  NSString *selector	= NSStringFromSelector(aSelector);

  [NSException raise:NSInternalInconsistencyException
              format:@"[%@ %@] has been revoked and should not be called!",
    class, selector];
}

- (void)isSubclassResponsibility:(SEL)aSelector
  /*" Raises an NSInternalInconsistencyException with a standard format.  "*/
{
  NSString *class	= NSStringFromClass([self class]);
  NSString *selector	= NSStringFromSelector(aSelector);

  [NSException raise:NSInternalInconsistencyException
              format:@"%@ implemented in abstract superclass. Implement [%@ %@]!",
    selector, class, selector];
}

@end
