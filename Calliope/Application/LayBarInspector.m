#import "LayBarInspector.h"
#import <AppKit/NSApplication.h>
#import "DrawApp.h"

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
