
/* Generated by Interface Builder */

#import "GraphicView.h"
#import "TextVarCell.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import <AppKit/NSTextView.h>
#import <AppKit/NSFont.h>
#import "mux.h"
#import "muxlow.h"

@implementation NSTextView(CellFont)

#define NUMVARTYPES 8

- (NSFont *) fontOfCell : c
{
    /* sb: FIXME this will need to be changed when changing TextVarCell
  NSRunArray *ra;
  NSRun *cl, *zl;
  ra = theRuns;
  zl = ra->runs + ((ra->chunk.used / sizeof(NSRun)) - 1);
  for (cl = ra->runs; cl <= zl; cl++) if (cl->info == c) return cl->font;
    */

  return [[NSApp currentDocument] getPreferenceAsFont: TEXFONT];
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


@implementation TextVarCell:NSObject
/*sb: FIXME make this class a subclass of NSTextAttachmentCell. This does a lot of the hard work. */
extern NSTextView *myText;
extern int runnerStatus;
extern NSString *curvartext[NUMVARTYPES];
extern NSString *username;


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
      (void)[TextVarCell setVersion: 0];	/* class version, see read: */
    for (i = 0; i < NUMVARTYPES; i++)
    {
        images[i] = [[NSImage imageNamed:imfiles[i]] retain];
    }
  }
  return;
}


- (NSString *) getVarString
{
  if (type == 6) return username;
  else if (type == 7) return [[NSApp currentDocument] filename];
  return (NSString *)curvartext[(int)type];
}


- init: (int) t
{
  type = t;
  highlighted = 0;
  return self;
}


- (NSSize)cellSize
{
  
    NSSize sz;
    NSFont *f;
  if (runnerStatus && myText != nil)
  {
    f = [myText fontOfCell: self];
      sz.width = [f widthOfString:[self getVarString]];
    sz.height = [f pointSize];
  }
  else
  {
      sz = [images[(int)type] size];
  }
  return sz;
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


#define DRAG_MASK (NSLeftMouseUpMask | NSLeftMouseDraggedMask)

#warning RectConversion: 'trackMouse:inRect:ofView:untilMouseUp:' used to be 'trackMouse:inRect:ofView:'.  untilMouseUp == YES when inRect used to be NULL
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)_untilMouseUp
{
    int    	/*oldMask,*/ p;
    NSEvent *event;
    NSPoint	mouseLocation;
    BOOL	mouseInCell = NO;
    
  /* we want to grab mouse dragged events */
//#error EventConversion: addToEventMask:NX_MOUSEDRAGGEDMASK: is obsolete; you no longer need to use the eventMask methods; for mouse moved events, see 'setAcceptsMouseMovedEvents:'
//  oldMask = [[controlView window] addToEventMask:NSLeftMouseDraggedMask];
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
  /* reset the event mask */
//#error EventConversion: setEventMask:oldMask: is obsolete; you no longer need to use the eventMask methods; for mouse moved events, see 'setAcceptsMouseMovedEvents:'
//  [[controlView window] setEventMask:oldMask];
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
    f = [(NSTextView *)v fontOfCell: self];
    [NSApp readyFont: f];
    CAcString(pt.x, pt.y, [[self getVarString] cString], f, 1);
  }
  else
  {
      [images[(int)type] compositeToPoint:pt operation:NSCompositeSourceOver];
  }
  PSgrestore();
}


#warning TextConversion: 'readRichText:forView:' takes an NSString instance as its first argument (used to take NXStream)
- readRichText:(NSString *)stream forView:view
{
//  int i;
//  NXScanf(stream, "%i ", &i);
//  type = i;
    type = [stream intValue];//sb
  highlighted = 0;
  return self;
}


#warning DONE I THINK TextConversion: 'richTextForView:' (used to be 'writeRichText:forView') now returns the rich text as an NSString instance (used to write to an NXStream)
- (NSString *)richTextForView:(NSView *)view
{
//  NXPrintf(stream, "%i ", type);
    return [NSString stringWithFormat:@"%i ",type];
//  return self;
}

@end