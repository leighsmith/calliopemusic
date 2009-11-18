/* $Id$ */
#import <AppKit/NSTextView.h>
#import "Runner.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "RunInspector.h"
#import "System.h"
#import "Staff.h"
#import "Page.h"
#import "GVFormat.h"
// #import "FlippedView.h"
#import "DrawingFunctions.h"
#import "TextVarCell.h"

@implementation Runner

#define SIZEBOX 8.0	/* size of the box used to represent a runner */

extern int justcode[4];
extern NSColor * backShade;

NSTextView *myTextView = nil;	/* also refed to see which Text is VarCells rendered from */
int runnerIsDrawing = NO; // This is used by TextVarCell. We should replace this with updating the status of TextVarCell to control its drawing.


+ (void) initialize
{
    if (self == [Runner class])
    {
	(void)[Runner setVersion: 2];		/* class version, see read: */
	if (!myTextView)
	{
	    myTextView = [[NSTextView alloc] init];
	    [myTextView setRichText:YES];
	    [myTextView setEditable:NO];
	    [myTextView setSelectable:YES];
//      [myTextView setSelColor:[NSColor whiteColor]];
	    [myTextView setTextColor:[NSColor blackColor]];
	    [myTextView setBackgroundColor:backShade];
	    
	    [myTextView setVerticallyResizable:YES];
	    [myTextView setHorizontallyResizable:YES];
	    
	    [myTextView setDrawsBackground:YES];
	    [myTextView setUsesFontPanel:YES];
	    [[myTextView textContainer] setWidthTracksTextView:NO];
	    [[myTextView textContainer] setHeightTracksTextView:NO];
	    
	}
    }
    return;
}


+ myInspector
{
  return [RunInspector class];
}

- init
{
    self = [super init];
    if(self != nil) {
	[self setTypeOfGraphic: RUNNER];
	flags.onceonly = 0;
	flags.nextpage = 0;
	flags.horizpos = 0;
	flags.evenpage = 0;
	flags.oddpage = 0;
	flags.vertpos = 0;
	flags.just = 0;
	richText = nil;	
    }
    return self;
}


- (void) dealloc
{
    if (richText)
	[richText release];
    richText = nil;
    [super dealloc];
}


/*
  setrunnertables and tidying markers done by delete:
*/

- (void) removeObj
{
    id p;
    [self retain];
    [client unlinkobject: self];
    /* sb: I want to check here whether the inspector, if it exists, is
     * pointing at me, and if it is, order it off screen.
     */
    p = [[CalliopeAppController sharedApplicationController] getInspectorForClass: [RunInspector class] loadInspector: 0];
    if (p) {
        id r = [p runner];
	
        if (self == r) {
            [p orderOut:self];
        }
    }
    [self release];
}

- (Runner *) newFrom
{
  Runner *newRunner = [[Runner alloc] init];
  newRunner->gFlags = gFlags;
  newRunner->bounds = bounds;
  newRunner->flags = flags;
  newRunner->richText = [richText copy];
  return newRunner;
}


/*
this is how the expanded runner text is actually drawn.
Totally bizarre due to Text object's behaviour when scaled etc.
Seems to interfere with alignment. margins need resetting twice too.
 Also frame rect does not
seem to change size correctly, hence various transforms.
*/
- (void) renderInRect: (NSRect) r text: (NSAttributedString *) textString paperSize: (NSSize) ps onPage: (Page *) pg
{
    System *sys = client;
    NSRect fb, vb, fo;
    NSSize ms;
    float f;
    vb = [[sys pageView] bounds];
    
    if (textString == nil)
	return;
    [myTextView setMaxSize: (vb.size)];
    [[myTextView textContainer] setContainerSize: (vb.size)];
    ms.width = ms.height = 0.0;
    [myTextView setMinSize: ms];
    f = [client staffScale];
    runnerIsDrawing = YES;
    [[myTextView textStorage] beginEditing];
    [[myTextView textStorage] replaceCharactersInRange: NSMakeRange(0, [[myTextView string] length]) withAttributedString: textString];
    [[myTextView textStorage] endEditing];
    
    if ([myTextView alignment] != justcode[flags.just]) 
	[myTextView setAlignment:justcode[flags.just]];
    
    [myTextView sizeToFit];
    fb = [myTextView frame];
    fo = fb;
    [myTextView scaleUnitSquareToSize:NSMakeSize(1.0 / f, 1.0 / f)];
    fb.size.width /= f;
    fb.size.height /= f;
    switch(flags.horizpos) {
	case 0:
	    fb.origin.x = [pg leftMargin];
	    break;
	case 1:
	    fb.origin.x = 0.5 * (vb.size.width - fb.size.width);
	    break;
	case 2:
	    fb.origin.x = vb.size.width - fb.size.width - [pg rightMargin];
	    break;
    }
    fb.origin.y = flags.vertpos ? vb.size.height - fb.size.height - [pg footerBase] : [pg headerBase];
    //  coutrect(fb.origin.x, fb.origin.y, fb.size.width, fb.size.height, 0.0, 5);
    if (NSIsEmptyRect(r) || !NSIsEmptyRect(NSIntersectionRect(r , fb))) {
	id graphicView = [CalliopeAppController currentView];
	[[graphicView window] setAutodisplay:NO]; // don't let addSubview: cause redisplay
	[myTextView setFrame:fb];
	
	if ([myTextView alignment] != justcode[flags.just]) [myTextView setAlignment:justcode[flags.just]];
	[myTextView setBackgroundColor:backShade];
	[myTextView setDrawsBackground:YES];
	
	[[NSView focusView] addSubview: myTextView];
	//    [myTextView display];
	[myTextView lockFocus];
	[myTextView drawRect:[myTextView bounds]];
	[myTextView unlockFocus];
	[myTextView removeFromSuperview];
	[myTextView setFrame:fo];
	[[graphicView window] setAutodisplay:YES];
    }
    [myTextView scaleUnitSquareToSize:NSMakeSize(f, f)];
    runnerIsDrawing = NO;
}

- (void) renderTextInRect: (NSRect) r paperSize: (NSSize) ps onPage: (Page *) pg
{
    [self renderInRect: r text: richText paperSize: ps onPage: pg];
}

- (void) setRunnerText: (NSAttributedString *) textString
{
    [richText release];
    richText = [textString retain];
}

- (NSAttributedString *) runnerText
{
    return [[richText retain] autorelease];
}

- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  return NO;
}


- drawMode: (int) m
{
  System *s = client;
  Staff *sp = [s firststaff];
  float x = [s leftWhitespace] + s->width + 20;
  float y = [sp yOfTop] + [s whichMarker: self] * (SIZEBOX + 3);
  coutrect(x, y, SIZEBOX, SIZEBOX, 0.0, m);
  if (flags.vertpos) y += 0.5 * SIZEBOX;
  crect(x, y, SIZEBOX, (0.5 * SIZEBOX), m);
  return self;
}


- draw
{
  return [self drawMode: markmode[gFlags.selected]];
}


/* Archiving methods */


struct oldflags		/* for old version */
{
  unsigned int onceonly : 1;	/* once only */
  unsigned int nextpage : 1;	/* start next page */
  unsigned int horizpos : 2;	/* horizontal place */
  unsigned int evenpage : 1;	/* even page */
  unsigned int oddpage  : 1;	/* odd page */
  unsigned int vertpos  : 1;	/* head or foot*/
  unsigned int just     : 2;  /* justification */
};


- (id)initWithCoder:(NSCoder *)aDecoder
{
  struct oldflags f;
  char b1, b2, b3, b4, b5, b6, b7;
  int v;
  int indexOfCell,j;
  NSScanner *theScanner;
  NSFont *theFont;
  int length;
    
  [super initWithCoder:aDecoder];
  v = [aDecoder versionForClassName:@"Runner"];
  client = [[aDecoder decodeObject] retain];
  
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"si", &f, &length];
    flags.onceonly = f.onceonly;
    flags.nextpage = f.nextpage;
    flags.horizpos = f.horizpos;
    flags.evenpage = f.evenpage;
    flags.oddpage = f.oddpage;
    flags.vertpos = f.vertpos;
    flags.just = f.just;
  }
  else
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccccci", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &length];
    flags.onceonly = b1;
    flags.nextpage = b2;
    flags.horizpos = b3;
    flags.evenpage = b4;
    flags.oddpage = b5;
    flags.vertpos = b6;
    flags.just = b7;
  }
  if (v <= 1)  {
      char *olddata = malloc(length + 1);
      NSString *tempString, *resultString;
      NSMutableData *results = [NSMutableData dataWithCapacity:length+1];
      int start;
      int foundCells = 0;
      NSString *trickyScan = [NSString stringWithUTF8String:" }\12\254"];
      [aDecoder decodeArrayOfObjCType:"c" count:length at:olddata];
      olddata[length] = '\0';
      /*need to do the following:
          * scan for anything leading to {\TextVarCelln m }\0a\ac
          * print the 'anything' into newdata, followed by new identifying string
          * repeat as necessary
          *
          * place data into 'richText', as attributed string
          * replace all occurrances of text 'TextVarCelln' with real cells.
       */
      theScanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:olddata]];
      [theScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
      
      while ([theScanner isAtEnd] == NO) {
          start = [theScanner scanLocation];

          if ([theScanner scanUpToString:@"{\\TextVarCell" intoString:&tempString] &&
              [theScanner scanString:@"{\\TextVarCell" intoString:NULL] &&
              [theScanner scanInt:&indexOfCell] &&
              [theScanner scanString:@" " intoString:NULL] &&
              [theScanner scanInt:&indexOfCell] &&
              [theScanner scanString:trickyScan intoString:NULL])
            {
              foundCells++;
              resultString = [NSString stringWithFormat:@"%@<>TextVarCell<>%d<>",tempString,indexOfCell];
              [results appendBytes:[resultString UTF8String] length:[resultString length]];
            }
          else {
              resultString = [[theScanner string] substringFromIndex:start];
              [results appendBytes:[resultString UTF8String] length:[resultString length]];
              break;
          }
      }
      richText = [[NSMutableAttributedString alloc] initWithRTF:results documentAttributes:NULL];
      free(olddata);
      for (j=0;j<foundCells;j++) {
          int rangeStart;
          TextVarCell *v;
          char cellNo;
          NSAttributedString *theAttrString;
          NSFileWrapper *theWrapper;
          NSTextAttachment *theAttachment;
          theScanner = [NSScanner scannerWithString:[richText string]];
          [theScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

          [theScanner scanUpToString:@"<>TextVarCell<>" intoString:NULL];
          rangeStart = [theScanner scanLocation];
          [theScanner scanString:@"<>TextVarCell<>" intoString:NULL];
          [theScanner scanInt:&indexOfCell];

          v = [[TextVarCell alloc] init: indexOfCell];
          cellNo = indexOfCell;
          theWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData dataWithBytes:&cellNo length:1]];

          [theWrapper setPreferredFilename:@"UNTITLED"];
          theAttachment = [[NSTextAttachment alloc] initWithFileWrapper:theWrapper];
          [v setAttachment:theAttachment];
          theFont = [richText attribute:NSFontAttributeName atIndex:rangeStart effectiveRange:NULL];
          if (theFont) [(TextVarCell *)v setFont:theFont];

          [theAttachment setAttachmentCell:v];
          theAttrString = [NSAttributedString attributedStringWithAttachment:theAttachment];

          [richText beginEditing];
          [richText replaceCharactersInRange:NSMakeRange(rangeStart,18) withAttributedString:theAttrString];
          [richText addAttribute:NSFontAttributeName value:theFont range:NSMakeRange(rangeStart,1)];
          [richText endEditing];
      }
//      NSLog(@"%s\n",(char *)[results bytes]);
  }
  else {
      richText = [[aDecoder decodeObject] retain];
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b1, b2, b3, b4, b5, b6, b7;
  int length = 0;
    
  [super encodeWithCoder:aCoder];
  [aCoder encodeConditionalObject:client];
  b1 = flags.onceonly;
  b2 = flags.nextpage;
  b3 = flags.horizpos;
  b4 = flags.evenpage;
  b5 = flags.oddpage;
  b6 = flags.vertpos;
  b7 = flags.just;
  [aCoder encodeValuesOfObjCTypes:"ccccccci", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &length];
//  [aCoder encodeArrayOfObjCType:"c" count:length at:richText];
  [aCoder encodeObject:richText];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];

    [aCoder setInteger:flags.onceonly forKey:@"onceonly"];
    [aCoder setInteger:flags.nextpage forKey:@"nextpage"];
    [aCoder setInteger:flags.horizpos forKey:@"horizpos"];
    [aCoder setInteger:flags.evenpage forKey:@"evenpage"];
    [aCoder setInteger:flags.oddpage forKey:@"oddpage"];
    [aCoder setInteger:flags.vertpos forKey:@"vertpos"];
    [aCoder setInteger:flags.just forKey:@"just"];
    [aCoder setObject:richText forKey:@"richText"];
}


@end
