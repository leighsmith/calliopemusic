#import "LayBarInspector.h"
#import <AppKit/NSApplication.h>
#import "CalliopeAppController.h"

@implementation LayBarInspector

- preset:sender
{
    return self;
}

- (void)cancel:(id)sender
{
    [NSApp abortModal];
}

- set:sender
{
    [NSApp stopModal];
    return NSApp;
}

@end
