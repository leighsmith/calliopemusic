/* $Id$ */
/*!
  @brief These fake out loading old pre-OpenStep objects encoded in the data files. 
 */

#import "winheaders.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/*
 * This first one is only used by FileCompatibility.m and gvPasteboard.m.
 * It will not be required once gvPasteboard.m is changed to use
 * property lists as Draw's new pasteboard format.
 */

@interface ListDecodeFaker: NSObject
{
}

- initWithCoder: (NSCoder *) aDecoder;

@end

@interface PSMatrixDecodeFaker: NSObject
{
}

- initWithCoder: (NSCoder *) aDecoder;

@end

@interface PrintInfo : NSPrintInfo 
{
}

@end

@interface Font : NSObject //  NSFont 
{
}

@end

@interface View : NSView
{
}

@end

@interface Responder : NSResponder
{
}

@end
