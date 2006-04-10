#import "GraphicView.h"
#import "TextVarCell.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import <AppKit/NSTextView.h>
#import <AppKit/NSFont.h>
#import "mux.h"
#import "muxlow.h"

@implementation NSTextStorage(Cells)
- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
    [super setAttributes:(NSDictionary *)attributes range:(NSRange)aRange];
    NSLog(@"Range location %d length %d\n",aRange.location,aRange.length);
}
- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
    [super addAttributes:(NSDictionary *)attributes range:(NSRange)aRange];
    NSLog(@"Range location %d length %d\n",aRange.location,aRange.length);
}
- (void)addAttribute:(NSString *)name value:(id)value range:(NSRange)aRange
{
    [super addAttribute:(NSString *)name
                          value:(id)value
                  range:(NSRange)aRange];
    NSLog(@"Range location %d length %d name %s\n",aRange.location,aRange.length,[name cString]);
}
@end

@implementation NSTextView(CellFont)

#define NUMVARTYPES 8

- (NSFont *) fontOfCell : c
{
    NSFont *theFont=nil;
    NSTextAttachment *theAtt = nil;
    int count,i=0;
    id theStorageString = [self textStorage];
    count = [theStorageString length];
    while (i < count) {
        theAtt = [theStorageString attribute:NSAttachmentAttributeName atIndex:i effectiveRange:NULL];
        if (theAtt)
            if ([theAtt attachmentCell] == c) {
                theFont = [theStorageString attribute:NSFontAttributeName atIndex:i effectiveRange:NULL];
                break;
            }
        i++;
    }


    NSLog(@"font found at %d, %p\n",i,theFont);
    if (theFont) return theFont;
  return [[DrawApp currentDocument] getPreferenceAsFont: RUNFONT];
}


- (int) posOfCell: c
{
  int p = 0;
    /* sb: FIXME this will need to be changed when changing TextVarCell
  NSRunArray *ra;
  NSRun *cl, *zl;
  ra = theRuns;
  zl = ra->runs + ((ra->chunk.used / sizeof(NSRun)) - 1);
  for (cl = ra->runs; cl <= zl; cl++)
  {
    if (cl->info == c) return p;
    else p += cl->chars;
  }
 */
  return p;
}


@end


@implementation TextVarCell:NSTextAttachmentCell

extern NSTextView *myText;
extern int runnerStatus;
//extern NSString *curvartext[NUMVARTYPES];


NSImage *images[NUMVARTYPES];

NSString *imfiles[NUMVARTYPES] =
{
  @"varPage", @"varDay", @"varMonth", @"varYear", @"varHour", @"varMin", @"varUser", @"varDoc"
};


+ (void)initialize
{
  int i;
  if (self == [TextVarCell class])
  {
      (void)[TextVarCell setVersion: 1];	/* class version, see read: sb: bumped up to v1 to accomodate fonts. */
    for (i = 0; i < NUMVARTYPES; i++)
    {
        images[i] = [[NSImage imageNamed:imfiles[i]] retain];
    }
  }
  return;
}


-(NSPoint)cellBaselineOffset
{
    return NSZeroPoint;
}

- (NSString *) getVarString
{
    NSCalendarDate *now = [NSCalendarDate calendarDate];

    switch (type) {
    case 0:
	return [NSString stringWithFormat: @"%d", [[[DrawApp currentView] currentPage] pageNumber]];
    case 1:
	return [now descriptionWithCalendarFormat:@"%d"];
    case 2:
	return [now descriptionWithCalendarFormat:@"%m"];
    case 3:
	return [now descriptionWithCalendarFormat:@"%y"];
    case 4:
	return [now descriptionWithCalendarFormat:@"%H"];
    case 5:
	return [now descriptionWithCalendarFormat:@"%M"];
    case 6:
	return NSUserName();
    case 7:
	return [[DrawApp currentDocument] filename];
    default:
	NSLog(@"TextVarCell getVarString type < 0, > 7?\n");
	return @"";
    }  
}


- init: (int) t
{
    id ret = [super init];
    type = t;
    highlighted = 0;
    theFont = nil;
    return ret;
}

- (void)dealloc
{
    if (theFont) [theFont release];
    [super dealloc];
    return;
}

- (NSSize)cellSize
{
  
    NSSize sz;
    NSFont *f;
  if (runnerStatus && myText != nil)
  {
//    f = [myText fontOfCell: self];
      if (theFont) f = theFont;
      else f = [myText fontOfCell:self];
      sz.width = [f widthOfString:[self getVarString]];
    sz.height = [f pointSize];
  }
  else
  {
      sz = [images[(int)type] size];
  }
  return sz;
}
- (void)setFont:(NSFont*)aFont
{
    if (theFont) [theFont autorelease];
    theFont = [aFont copy];
}

- (NSFont *)font
{
    return theFont;
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  if (highlighted != flag)
  {
    highlighted = flag;
    NSHighlightRect(cellFrame);
    [[controlView window] flushWindow];
  }
}

- (BOOL)wantsToTrackMouse
{
    return NO;
}

#define DRAG_MASK (NSLeftMouseUpMask | NSLeftMouseDraggedMask)

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)_untilMouseUp
{
    int    	/*oldMask,*/ p;
    NSEvent *event;
    NSPoint	mouseLocation;
    BOOL	mouseInCell = NO;
    
  /* start our event loop, looking for mouse-dragged or mouse-up events */
  event = [NSApp nextEventMatchingMask:DRAG_MASK untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
  while ([event type] != NSLeftMouseUp)
  {
    /* mouse-dragged event;  highlight if mouse is in cell bounds */
    mouseLocation = [event locationInWindow];
    mouseLocation = [controlView convertPoint:mouseLocation fromView:NULL];
    mouseInCell = NSPointInRect(mouseLocation , cellFrame);
    if (mouseInCell != highlighted)
    {
      /* we have to lock focus before calling hightlight:inView:lit: */
      [controlView lockFocus];
      [self highlight:mouseInCell withFrame:cellFrame inView:controlView];
      [controlView unlockFocus];
    }
    event = [NSApp nextEventMatchingMask:DRAG_MASK untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
  }
  /* turn off any highlighting */
  [controlView lockFocus];
  [self highlight:NO withFrame:cellFrame inView:controlView];
  [controlView unlockFocus];

  /* if a double-click and the mouse is over us, do something */
  mouseLocation = [event locationInWindow];
  mouseLocation = [controlView convertPoint:mouseLocation fromView:NULL];
  if (NSPointInRect(mouseLocation , cellFrame) && [event clickCount] == 2)
  {
    p = [(NSTextView *)controlView posOfCell: self];
      [(NSTextView *)controlView setSelectedRange:NSMakeRange(p,p+1)];
    return YES;
  }
  return YES;
return NO;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)v
{
  NSFont *f;
  NSPoint pt;
  PSgsave();
  pt = cellFrame.origin;
  pt.y += cellFrame.size.height;
  if (runnerStatus)
  {
      if (theFont) f = theFont;
      else f = [(NSTextView *)v fontOfCell: self];

      CAcString(pt.x, pt.y, [[self getVarString] cString], f, 1);
  }
  else
  {
      [images[(int)type] compositeToPoint:pt operation:NSCompositeSourceOver];
  }
  PSgrestore();
}


- readRichText:(NSString *)stream forView:view
{
    type = [stream intValue];//sb
  highlighted = 0;
  return self;
}


- (NSString *)richTextForView:(NSView *)view
{
    return [NSString stringWithFormat:@"%i ",type];
}
- (void)setAttachment:(NSTextAttachment *)anObject
{
    [super setAttachment:anObject];
    return;
}

- (NSTextAttachment *)attachment
{
    return [super attachment];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    int v;
    [super initWithCoder:aDecoder];
    v = [aDecoder versionForClassName:@"TextVarCell"];
    [aDecoder decodeValuesOfObjCTypes:"c", &type];
    if (v == 1)
        theFont = [[aDecoder decodeObject] retain];  
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeValuesOfObjCTypes:"c", &type];
    [aCoder encodeObject:theFont];
}

@end
