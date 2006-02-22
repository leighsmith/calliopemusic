
#import <AppKit/AppKit.h>

#define BUTTON_THREESTATE_OFF 		0
#define BUTTON_THREESTATE_MUSTHAVE 	1
#define BUTTON_THREESTATE_MUSTNOTHAVE 	2

@interface CalliopeThreeStateButtonCell:NSButtonCell
{
    int		altClicked;
    int		threeState;
    int		cyclic;
    NSImage	*firstImage;
    NSImage	*secondImage;
    NSImage	*thirdImage;
}
/***********************/
-(int) state;
-(int) threeState;
-(void) toggleState;
-(void) setState:(int)aState;
-(void) setThreeState:(int) newState;
-(int) incState;
-(int) decState;

-(NSImage *)   firstImage;
-(void) setFirstImage:(NSImage *) newValue;
-(NSImage *)   secondImage;
-(void) setSecondImage:(NSImage *) newValue;
-(NSImage *)   thirdImage;
-(void) setThirdImage:(NSImage *) newValue;

-(void) _setImage;
- (void)setCyclic:(int)value;
- (int)cyclic;

 /*********************/
// the basics
- (id)init;
- copyWithZone:(NSZone *)zone;
- (void)dealloc;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end
