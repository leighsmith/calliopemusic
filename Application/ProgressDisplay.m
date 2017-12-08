//
//  $Id:$
//  Calliope
//
//  Created by Leigh Smith on 19/03/06.
//  Copyright 2006 Leigh Smith. All rights reserved.
//

#import "ProgressDisplay.h"

@implementation ProgressDisplay

+ (ProgressDisplay *) progressDisplayWithTitle: (NSString *) titleOfProgressingActivity
{
    return [[[[self class] alloc] initWithTitle: titleOfProgressingActivity] autorelease];
}

- initWithTitle: (NSString *) titleOfProgressingActivity
{
    self = [super init];
    if(self != nil) {
	// TODO Check [[NSUserDefaults standardUserDefaults] boolWithKey: @"DisplayProgressPanels"] whether to display these.
	if (!progressPanel)
	    [NSBundle loadNibNamed: @"ProgressPanel.nib" owner: self];
	[self setProgressTitle: titleOfProgressingActivity];
	[self setProgressRatio: 0.0];
	[progressPanel setFloatingPanel: YES];
	[progressPanel makeKeyAndOrderFront: self];
    }
    return self;
}

- (void) setProgressTitle: (NSString *) s
{
    [titleTextField setStringValue: s];
}

- (void) setProgressRatio: (float) f
{
    [progressIndicator setDoubleValue: f];
}

- (void) closeProgressDisplay
{
    [progressPanel orderOut: self];
}

@end
