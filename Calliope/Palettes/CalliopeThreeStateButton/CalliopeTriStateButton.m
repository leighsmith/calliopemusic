
#import "CalliopeTriStateButton.h"
#import "CalliopeThreeStateButton.subproj/CalliopeThreeStateButton.h"
#import "CalliopeThreeStateButton.subproj/CalliopeThreeStateButtonCell.h"

@implementation CalliopeTriStateButton

- (void)finishInstantiate
{	
    [button1 setTitle:nil];
    [button1 setAlternateTitle:nil];
    [button1 setButtonType:NSToggleButton];
    [button1 setImage:[self imageNamed:@"NSSwitch"]];//default
    [button1 setFirstImage:[self imageNamed:@"NSSwitch"]];
    [button1 setSecondImage:[self imageNamed:@"mustHave"]];
    [button1 setThirdImage:[self imageNamed:@"mustNotHave"]];
    [button1 setImagePosition:NSImageOnly];
    [button1 setBordered:NO];
    [button1 setCyclic:YES];

    [button2 setTitle:@""];
    [button2 setAlternateTitle:@""];
    [button2 setButtonType:NSToggleButton];
    [button2 setImage:[self imageNamed:@"NSSwitch"]];//default
    [button2 setFirstImage:[self imageNamed:@"NSSwitch"]];
    [button2 setSecondImage:[self imageNamed:@"mustHave"]];
    [button2 setThirdImage:[self imageNamed:@"mustNotHave"]];
    [button2 setImagePosition:NSImageOnly];
    [button2 setBordered:NO];
    [button2 setCyclic:NO];

    [button3 setTitle:@""];
    [button3 setAlternateTitle:@""];
    [button3 setButtonType:NSToggleButton];
    [button3 setImage:[self imageNamed:@"DontCare"]];
    [button3 setFirstImage:[self imageNamed:@"DontCare"]];
    [button3 setSecondImage:[self imageNamed:@"mustHave"]];
    [button3 setThirdImage:[self imageNamed:@"mustNotHave"]];
    [button3 setImagePosition:NSImageOnly];
    [button3 setBordered:NO];
    [button3 setCyclic:YES];

    [button4 setTitle:@""];
    [button4 setAlternateTitle:@""];
    [button4 setButtonType:NSToggleButton];
    [button4 setImage:[self imageNamed:@"DontCare"]];
    [button4 setFirstImage:[self imageNamed:@"DontCare"]];
    [button4 setSecondImage:[self imageNamed:@"mustHave"]];
    [button4 setThirdImage:[self imageNamed:@"mustNotHave"]];
    [button4 setImagePosition:NSImageOnly];
    [button4 setBordered:NO];
    [button4 setCyclic:NO];

    [button5 setTitle:@""];
    [button5 setAlternateTitle:@""];
    [button5 setButtonType:NSToggleButton];
    [button5 setImage:[self imageNamed:@"NSSwitch"]];//default
    [button5 setFirstImage:[self imageNamed:@"NSSwitch"]];
    [button5 setSecondImage:[self imageNamed:@"NSHighlightedSwitch"]];
    [button5 setThirdImage:[self imageNamed:@"DontCare"]];
    [button5 setImagePosition:NSImageOnly];
    [button5 setBordered:NO];
    [button5 setCyclic:YES];

    [button6 setTitle:@""];
    [button6 setAlternateTitle:@""];
    [button6 setButtonType:NSToggleButton];
    [button6 setImage:[self imageNamed:@"NSSwitch"]];//default
    [button6 setFirstImage:[self imageNamed:@"NSSwitch"]];
    [button6 setSecondImage:[self imageNamed:@"NSHighlightedSwitch"]];
    [button6 setThirdImage:[self imageNamed:@"DontCare"]];
    [button6 setImagePosition:NSImageOnly];
    [button6 setBordered:NO];
    [button6 setCyclic:NO];

}

@end
