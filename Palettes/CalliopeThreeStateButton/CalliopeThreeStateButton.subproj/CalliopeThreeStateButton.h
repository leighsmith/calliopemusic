
#import <AppKit/AppKit.h>

@interface CalliopeThreeStateButton:NSButton
{
}


+ (void)initialize;
+ (void) setCellClass:(Class)classId;
- initWithFrame:(NSRect)frameRect;

- (void)setTitle:(NSString *)aString;
- (void)setImage:(NSImage *)image;
- (void)setButtonType:(NSButtonType)aType;
- (int)state;
- (void)setState:(int)value;
- (void)performAltClick:sender;
- (void)performClick:(id)sender;
- (void)setCyclic:(int)value;
- (int)cyclic;

@end
