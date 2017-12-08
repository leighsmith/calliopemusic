
#import "CalliopeTriStateInspector.h"
#import <AppKit/AppKit.h>
#import "CalliopeThreeStateButton.subproj/CalliopeThreeStateButtonCell.h"
#import "CalliopeThreeStateButton.subproj/CalliopeThreeStateButton.h"

@implementation CalliopeTriStateInspector

- init
{
    NSString *buf;
    id bundle;
    
    [super init];
    bundle = [NSBundle bundleForClass:[CalliopeThreeStateButton class]];
    buf = [bundle pathForResource:@"TriStateInspector" ofType:@"nib"];
    [NSBundle loadNibFile:buf externalNameTable:[NSDictionary dictionaryWithObjectsAndKeys:self, @"NSOwner", nil] withZone:[self zone]];
    return self;
}

- (BOOL)wantsButtons { return YES; }

- (void)revert:(id)sender
{
    NSString *firstIconName = [[[self object] firstImage] name];
    NSString *secondIconName = [[[self object] secondImage] name];
    NSString *thirdIconName = [[[self object] thirdImage] name];
    if (!firstIconName) firstIconName = @"";
    if (!secondIconName) secondIconName = @"";
    if (!thirdIconName) thirdIconName = @"";
	// Put string in text object
    [firstIcon setStringValue:firstIconName];
    [secondIcon setStringValue:secondIconName];
    [thirdIcon setStringValue:thirdIconName];
    [cyclic setState:[[self object] cyclic]];

	[super revert:sender];
        return;
}

- (void)ok:(id)sender
{
    NSImage *theFirst = [NSImage imageNamed:[firstIcon stringValue]];
    [[self object] setImage:theFirst];
    [[self object] setFirstImage:theFirst];
    [[self object] setSecondImage:[NSImage imageNamed:[secondIcon stringValue]]];
    [[self object] setThirdImage:[NSImage imageNamed:[thirdIcon stringValue]]];
    [[self object] setCyclic:[cyclic state]];
	[super ok:sender];
        return;
}

@end

@implementation CalliopeThreeStateButton(IBSupport)

- (NSString *)inspectorClassName
{	// alt-click to bring up the button class inspector instead...
    NSEvent *ev = [[NSApplication sharedApplication] currentEvent];
#ifdef DEBUG
    printf ("Modifier: %d \n",[ev modifierFlags]);
#endif
	if ([ev modifierFlags] & NSAlternateKeyMask) return [super inspectorClassName];
    else return @"CalliopeTriStateInspector";
}

@end

@implementation CalliopeThreeStateButtonCell(IBSupport)

- (NSString *)inspectorClassName
{	// alt-click to bring up the button class inspector instead...
    NSEvent *ev = [[NSApplication sharedApplication] currentEvent];
#ifdef DEBUG
    printf ("Modifier (buttoncell): %d \n",[ev modifierFlags]);
#endif
	if ([ev modifierFlags] & NSAlternateKeyMask)
            return [[CalliopeThreeStateButton class] inspectorClassName];
    else return @"CalliopeTriStateInspector";
}

@end
