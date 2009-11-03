#import "RunInspector.h"
#import "Runner.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "GVFormat.h"
#import "System.h"
#import "Staff.h"
#import "TextVarCell.h"
#import <AppKit/AppKit.h>
#import "DrawingFunctions.h"

@implementation RunInspector

extern int justcode[4];

#define UPDATE(lv,rv) if (lv != rv) { lv = rv; b = YES; }

- insertVar: sender
{
    NSTextStorage* theStorage = [[scroller documentView] textStorage];
    NSFont *theFont;
    TextVarCell *v = [[TextVarCell alloc] init: [[sender selectedCell] tag]];
    char myTag = [[sender selectedCell] tag];
    NSAttributedString *theAttrString;
    NSFileWrapper *theWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData dataWithBytes:&myTag length:1]];
    NSTextAttachment *theAttachment;
    NSRange theRange = [[scroller documentView] selectedRange];
    [theWrapper setPreferredFilename:@"UNTITLED"];
    theAttachment = [[NSTextAttachment alloc] initWithFileWrapper:theWrapper];
    [v setAttachment:theAttachment];
    [theAttachment setAttachmentCell:v];
    theAttrString = [NSAttributedString attributedStringWithAttachment:theAttachment];
    theFont = [[[scroller documentView] typingAttributes] objectForKey:NSFontAttributeName];
    [v setFont:theFont];
    [theStorage beginEditing];
    [theStorage replaceCharactersInRange:theRange withAttributedString:theAttrString];
    [theStorage endEditing];
    theRange.length = 1;
    [theStorage addAttribute:NSFontAttributeName value:theFont range:theRange];
    [self makeFirstResponder:[scroller documentView]];
  return self;
}
- (void)awakeFromNib
{
    [[scroller documentView] setRichText:YES];
//    [[scroller documentView] setUsesFontPanel:YES]; //should be unnecessary
    [[scroller documentView] setFont:[[DrawApp currentDocument] getPreferenceAsFont: RUNFONT]];
    [[[scroller documentView] textStorage] setDelegate:self];
    [(NSText *)[scroller documentView] setDelegate:self];
    [(NSPanel *)self setDelegate:self];
}

/* delegate method for NSTextStorage. I wish to grab attributes as they are applied to
 * the text object, and ensure they are applied to the text attachment cells. At present,
 * the text attachment cells conveniently ignore all text formatting info they are given.
 */
- (void)textStorageWillProcessEditing:(NSNotification *)aNotification
{
    id anObj = [aNotification object];
    NSRange theRange = [anObj editedRange];
    NSTextAttachment *theAtt = nil;
    int count = theRange.length,i=0;
    NSFont *theFont=nil;
    if (([anObj editedMask] & NSTextStorageEditedAttributes)) {
        while (i < count) {
        theAtt = [anObj attribute:NSAttachmentAttributeName atIndex:theRange.location + i effectiveRange:NULL];
        if (theAtt) {
            theFont = [anObj attribute:NSFontAttributeName atIndex:theRange.location + i effectiveRange:NULL];
//            NSLog(@"font of cell at %d is %s\n",theRange.location + i,
//                   [[theFont displayName] UTF8String]);
            if (theFont) [(TextVarCell *)[theAtt attachmentCell] setFont:theFont];
            /* previous line assumes that once set, a font cannot be removed, only changed.
		This assumes that any time the text around it changes, the cell will receive an explicit font change too.*/
        }
        i++;
    }
    }
}

/* fix up attachment characters in range by getting their contained font and adding it as an attribute again! */
- (void)textStorageDidProcessEditing:(NSNotification *)aNotification
{
    id theStorageString = [aNotification object];
    NSRange theRange = [theStorageString editedRange],charRange;
    NSTextAttachment *theAtt = nil;
    int count = theRange.length,i=0;
    charRange.length = 1;
    if (([theStorageString editedMask] & NSTextStorageEditedAttributes))
      {
        while (i < count) {
            theAtt = [theStorageString attribute:NSAttachmentAttributeName atIndex:theRange.location + i effectiveRange:NULL];
            if (theAtt) {
                charRange.location =  theRange.location + i;
                [theStorageString addAttribute:NSFontAttributeName value:[(TextVarCell*)[theAtt attachmentCell] font] range:charRange];
            }
            i++;
        }
      }
}

/*
  The complication here is to reset the runner tables only if
  certain flags are updated.
*/

- set:sender
{
    int i,n;
  System *sys;
  BOOL b = NO;
  GraphicView *v = [DrawApp currentView];
  Runner *p = [v canInspect: RUNNER : &n];
  if (n == 0)
  {
    NSLog(@"RunInspector -set: n == 0");
    return nil;
  }
  sys = p->client;
  if (p == nil) NSLog(@"RunInspector -set: p == nil");
  else
  {
    p->flags.just = [alignmatrix selectedColumn];
    i = [headfootmatrix selectedRow];    
    UPDATE(p->flags.vertpos, i);
    i = [placematrix selectedColumn];
    UPDATE(p->flags.horizpos, i);
    i = [[typematrix cellAtRow:0 column:0] state];
    UPDATE(p->flags.onceonly, i);
    i = [[typematrix cellAtRow:1 column:0] state];
    UPDATE(p->flags.nextpage, i);
    i = [[typematrix cellAtRow:0 column:1] state];
    UPDATE(p->flags.evenpage, i);
    i = [[typematrix cellAtRow:1 column:1] state];
    UPDATE(p->flags.oddpage, i);
    if (b) [sys->view setRunnerTables];
    if (p->data) [p->data release];
    p->data = [[[scroller documentView] textStorage] mutableCopy];
    /*[[[scroller documentView] RTFDFromRange:NSMakeRange(0, [[[scroller documentView] string] length])] retain]; */
    p->length = 0;/*sb: redundant */
    /* [self close]; */
    [sys->view dirty];
    [sys->view setNeedsDisplay:YES];
  }
  return self;
}


- preset
{
  NSTextView *tv;
    int n;
    GraphicView *v = [DrawApp currentView];
    Runner *p = [v canInspect: RUNNER : &n];
    if (n == 0) return nil;
  [headfootmatrix selectCellAtRow:p->flags.vertpos column:0];
  [placematrix selectCellAtRow:0 column:p->flags.horizpos];
  [alignmatrix selectCellAtRow:0 column:p->flags.just];
  [typematrix setState:p->flags.onceonly atRow:0 column:0];
  [typematrix setState:p->flags.nextpage atRow:1 column:0];
  [typematrix setState:p->flags.evenpage atRow:0 column:1];
  [typematrix setState:p->flags.oddpage atRow:1 column:1];
  tv = [scroller documentView];
  if (!(p->data))
  {
    [tv setString:@""];
    [tv setFont:[[DrawApp currentDocument] getPreferenceAsFont: RUNFONT]];
  }
  else
  {
      [[tv textStorage] beginEditing];
      [[tv textStorage] replaceCharactersInRange:NSMakeRange(0, [[tv string] length]) withAttributedString:p->data];
      [[tv textStorage] endEditing];
  }
  [tv setDelegate:self];
  return self;
}
/*sb: added this so we can see which runner the inspector is referring to.
 * used so that when a runner is deleted, it checks to see if the inspector is inspecting
 * it, and if so, orders out the inspector.
 */
- runner
{
    int n;
    GraphicView *v = [DrawApp currentView];
    Runner *p = [v canInspect: RUNNER : &n];
    if (!n) return nil;
    return p;
}

- align: sender
{
    [[scroller documentView] setAlignment:justcode[[alignmatrix selectedColumn]]];
    return self;
}
- (void)textView:(NSTextView *)aTextView
clickedOnCell:(id <NSTextAttachmentCell>)attachmentCell
inRect:(NSRect)cellFrame
{
    NSLog(@"clicked on cell %p\n",attachmentCell);
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
    [self reflectFont];
}


- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    id theFont = [[[scroller documentView] typingAttributes] objectForKey:NSFontAttributeName];
    [[NSFontManager sharedFontManager] setSelectedFont:theFont isMultiple:NO];
    /* following line because it's not happening automatically for some reason */
    [[NSFontPanel sharedFontPanel] setPanelFont:theFont isMultiple:NO];
}

-(void)reflectFont
{
    NSRange aRange,oldRange;
    NSFont *theFont;
    BOOL isMult = NO;
    int theLength = [[[scroller documentView] textStorage] length];
//    NSLog(@"length: %d\n",theLength);
    if (theLength) {
        oldRange = [[scroller documentView] selectedRange];
        if (oldRange.location >= theLength) oldRange.location--;
        
        theFont = [[[scroller documentView] textStorage] attribute:NSFontAttributeName
                                                           atIndex:oldRange.location
                                                    longestEffectiveRange:&aRange
                                                           inRange:oldRange];
        if (aRange.location + aRange.length < oldRange.location + oldRange.length) isMult = YES;
//        NSLog(@"isMult: %d font: %s\n",isMult,[[theFont displayName] UTF8String]);
        [[NSFontManager sharedFontManager] setSelectedFont:theFont isMultiple:isMult];
    }
}
@end
