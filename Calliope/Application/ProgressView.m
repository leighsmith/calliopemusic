#import "ProgressView.h"

@implementation ProgressView

#define DEFAULT_TICKS 10		// number of ticks to show + 1
#define DEFAULT_EMPHASIS 5		// every nth tick is longer...

- init
{
	isTicsVisible = YES;
	isTicsOverBar = NO;
	numTicks = DEFAULT_TICKS;
	emphasis = DEFAULT_EMPHASIS;
	tc = [[NSColor darkGrayColor] retain];
        bg = [[NSColor lightGrayColor] retain];
        fg = [[NSColor darkGrayColor] retain];
        bd = [[NSColor blackColor] retain];
	total = PROGRESS_MAXSIZE;
	stepSize = PROGRESS_DEFAULTSTEPSIZE;
	count = 0;
	ratio = 0.0;
	return self;
}

- (NSColor *)tickColor { return tc; }

- setTickColor:(NSColor *)color
{
	tc = [color retain];
	return self;
}

- setTicsVisible:(BOOL)aBool
{
    isTicsVisible = aBool;
	[self display];
    return self;
}

- (BOOL)isTicsVisible
{
    return isTicsVisible;
}

- setTicsOverBar:(BOOL)aBool
{
    isTicsOverBar = aBool;
	[self display];
    return self;
}

- (BOOL)isTicsOverBar
{
    return isTicsOverBar;
}


- setNumTicks:(int)anInt
{
  numTicks = MAX(anInt + 1, 1);
  [self display];
  return self;
}


- (int) numTicks
{
  return (numTicks - 1);
}


- setEmphasis: (int) anInt
{
  emphasis = MAX(anInt, 1);
  [self display];
  return self;
}


- (int)emphasis
{
  return emphasis;
}


- renderTicks
{
	if (isTicsVisible == YES)  {
		int linecount;
		[tc set];
		for (linecount = 1; linecount <= numTicks; ++linecount)  {
			int xcoord = ([self bounds].size.width / numTicks) * linecount;
			PSnewpath();
			PSmoveto(xcoord, 0);
			if (linecount % emphasis)
				PSlineto(xcoord, (int)([self bounds].size.height / 4));
			else PSlineto(xcoord, (int)([self bounds].size.height / 2));
			PSstroke();
		}
	}
	return self;
}


- renderBackground
{
	[bg set];
	NSRectFill([self bounds]);
	return self;
}

- doBar
{
  if ((ratio > 0) && (ratio <= 1.0))
  {
    NSRect r = [self bounds];
    r.size.width = [self bounds].size.width * ratio;
    [fg set];
    NSRectFill(r);
    }
    return self;
}

- renderBar
{
	if (isTicsOverBar) {
		[self doBar];
		[self renderTicks];
	} else {
		[self renderTicks];
		[self doBar];
	}
	return self;
}

- renderBorder
{
	[bd set];
	NSFrameRect([self bounds]);
	return self;
}

- (void)drawRect:(NSRect)rect
{
	[self renderBackground];
	[self renderBar];
	[self renderBorder];
}

- setStepSize:(int)value
{
	stepSize = value;
	return self;
}

- (int)stepSize { return stepSize; }
- (NSColor *)backgroundColor { return bg; }
- (NSColor *)foregroundColor { return fg; }
- (NSColor *)borderColor { return bd; }

- (void)setBackgroundColor:(NSColor *)color
{
    bg = [color retain];
}

- setForegroundColor:(NSColor *)color
{
    fg = [color retain];
	return self;
}

- setBorderColor:(NSColor *)color
{
    bd = [color retain];
	return self;
}


- setRatio: (float) newRatio
{
  if (newRatio > 1.0) newRatio = 1.0;
  if (ratio != newRatio)
  {
    ratio = newRatio;
    [self display];
  }
  return self;
}


- (void)takeIntValueFrom:sender
{
	int temp = [sender intValue];
	if ((temp < 0) || (temp > total)) return;
	count = temp;
	[self setRatio:(float)count/(float)total];
}


- increment:sender
{
	count += stepSize;
	[self setRatio:(float)count/(float)total];
	return self;
}


- (void)takeFloatValueFrom:(id)sender
{
	[self setRatio:[sender floatValue]];
	count = ceil(ratio * (float)total);
}


- (void)clear:(id)sender
{
	count = 0;
	[self setRatio: 0.0];
}


@end
