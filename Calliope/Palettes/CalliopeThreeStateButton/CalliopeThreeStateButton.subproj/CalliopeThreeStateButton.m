
#import "CalliopeThreeStateButton.h"
#import "CalliopeThreeStateButtonCell.h"
#import <InterfaceBuilder/InterfaceBuilder.h>

static id threeStateCellClass = nil;

@implementation CalliopeThreeStateButton

+ (void)initialize
{ // need to set up to use our new cell subclass
    if (self == [CalliopeThreeStateButton class]) {
        threeStateCellClass = [CalliopeThreeStateButtonCell class];
	}
	[super initialize];
	return;
}

+ (void) setCellClass:(Class)classId
{
	threeStateCellClass = classId;
	return;
}

- initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	[self setCell:[[threeStateCellClass alloc] init]];
	return self;
}


- (void)setTitle:(NSString *)aString { return [[self cell] setTitle:aString]; }

- (void)setImage:image { [[self cell] setImage:image]; return; }
- (void)setButtonType:(NSButtonType)aType { [[self cell] setButtonType:aType]; return; }
- (int)state { return [[self cell] intValue]; }
- (void)setState:(int)value { [[self cell] setIntValue:value]; return; }
- (void)performAltClick:sender { [[self cell] performAltClick:sender]; return; }
- (void)performClick:(id)sender {[[self cell] performClick:sender];return; }

-(int) threeState {return [[self cell] threeState]; }
-(void) setThreeState:(int) newState {[[self cell] setThreeState:newState];return; }
-(int) incState {return [[self cell] incState]; }
-(int) decState {return [[self cell] decState]; }

-(id)   firstImage{return [[self cell] firstImage]; }
-(void) setFirstImage:(NSImage *) newValue {[[self cell] setFirstImage:newValue];return; }
-(id)   secondImage {return [[self cell] secondImage]; }
-(void) setSecondImage:(NSImage *) newValue {[[self cell] setSecondImage:newValue];return; }
-(id)   thirdImage {return [[self cell] thirdImage]; }
-(void) setThirdImage:(NSImage *) newValue {[[self cell] setThirdImage:newValue];return; }

-(void) _setImage {[[self cell] _setImage];return; }
- (void)setCyclic:(int)value {[[self cell] setCyclic:value]; return;}
- (int)cyclic {return [[self cell] cyclic]; }

@end
