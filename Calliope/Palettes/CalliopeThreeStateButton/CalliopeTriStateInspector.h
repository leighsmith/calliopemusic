
#import <InterfaceBuilder/InterfaceBuilder.h>
#import "CalliopeThreeStateButton.subproj/CalliopeThreeStateButtonCell.h"
#import "CalliopeThreeStateButton.subproj/CalliopeThreeStateButton.h"

@interface CalliopeTriStateInspector : IBInspector 
{
    id firstIcon;
    id secondIcon;
    id thirdIcon;
    id cyclic;
}

@end


@interface CalliopeThreeStateButton(IBSupport)

- (NSString *)inspectorClassName;

@end


@interface CalliopeThreeStateButtonCell(IBSupport)

- (NSString *)inspectorClassName;

@end
