#import "winheaders.h"
#import <AppKit/AppKit.h>

#define PROGRESS_DEFAULTSTEPSIZE 5
#define PROGRESS_MAXSIZE 100

@interface ProgressView: NSView
{
	int numTicks, emphasis, total, count, stepSize;
	float ratio;
	NSColor * bg, *fg, *bd, *tc; // foreground, background, border, tic colors
	BOOL	isTicsVisible;
	BOOL	isTicsOverBar;
}

- (NSColor *)tickColor;
- setTickColor:(NSColor *)color;
- renderTicks;
- renderBar;
- setTicsVisible:(BOOL)aBool;
- (BOOL)isTicsVisible;
- setTicsOverBar:(BOOL)aBool;
- (BOOL)isTicsOverBar;
- setNumTicks:(int)anInt;
- (int)numTicks;
- setEmphasis:(int)anInt;
- (int)emphasis;
- init;
- renderBackground;
- renderBar;
- renderBorder;
- (void)drawRect:(NSRect)rect;
- setStepSize:(int)value;
- (int)stepSize;
- (NSColor *)backgroundColor;
- (NSColor *)foregroundColor;
- (NSColor *)borderColor;
- (void)setBackgroundColor:(NSColor *)color;
- setForegroundColor:(NSColor *)color;
- setBorderColor:(NSColor *)color;
- setRatio:(float)newRatio;
- (void)takeIntValueFrom:sender;
- increment:sender;
- (void)takeFloatValueFrom:(id)sender;
- (void)clear:(id)sender;

@end
