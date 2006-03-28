/* $Id$ */
#import <AppKit/NSTextView.h>
#import "Runner.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "RunInspector.h"
#import "System.h"
#import "Staff.h"
#import "Page.h"
#import "GVFormat.h"
#import "FlippedView.h"
#import "mux.h"
#import "TextVarCell.h"

/*
  Runners are drawn in two ways.  The official mechanism merely handles the
  markers.  The actual text is prepared by Page and sent here via renderMe:.
*/

@implementation Runner

#define SIZEBOX 8.0	/* size of the box used to represent a runner */

extern int justcode[4];
extern NSColor * backShade;

NSTextView *myText = nil;	/* also refed to see which Text is VarCells rendered from */
int runnerStatus = 0;


+ (void)initialize
{
    if (self == [Runner class])
    {
	(void)[Runner setVersion: 2];		/* class version, see read: */
	if (!myText)
	{
	    myText = [[NSTextView alloc] init];
	    [myText setRichText:YES];
	    [myText setEditable:NO];
	    [myText setSelectable:YES];
//      [myText setSelColor:[NSColor whiteColor]];
	    [myText setTextColor:[NSColor blackColor]];
	    [myText setBackgroundColor:backShade];
	    
	    [myText setVerticallyResizable:YES];
	    [myText setHorizontallyResizable:YES];
	    
	    [myText setDrawsBackground:YES];
	    [myText setUsesFontPanel:YES];
	    [[myText textContainer] setWidthTracksTextView:NO];
	    [[myText textContainer] setHeightTracksTextView:NO];
	    
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
	gFlags.type = RUNNER;
	flags.onceonly = 0;
	flags.nextpage = 0;
	flags.horizpos = 0;
	flags.evenpage = 0;
	flags.oddpage = 0;
	flags.vertpos = 0;
	flags.just = 0;
	length = 0;
	data = nil;	
    }
    return self;
}


- (void)dealloc
{
  if (data) [data release];
  [super dealloc];
  return;
}


/*
  setrunnertables and tidying markers done by delete:
*/

- (void)removeObj
{
    id p;
    [self retain];
    [client unlinkobject: self];
    /* sb: I want to check here whether the inspector, if it exists, is
     * pointing at me, and if it is, order it off screen.
     */
    p = [[DrawApp sharedApplicationController] getInspectorForClass: [RunInspector class] loadInspector: 0];
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
  newRunner->data = [data copy];
  newRunner->length = length;
  return newRunner;
}


/*
this is how the expanded runner text is actually drawn.
Totally bizarre due to Text object's behaviour when scaled etc.
Seems to interfere with alignment. margins need resetting twice too.
 Also frame rect does not
seem to change size correctly, hence various transforms.
*/

extern int selMode;

- renderMe: (NSRect) r : (NSAttributedString *) stream : (NSSize) ps : (Page *) pg
{
  System *sys = client;
  NSRect fb, vb, fo;
  NSSize ms;
  float f;
  vb = [sys->view bounds];

  [myText setMaxSize:(vb.size)];
  [[myText textContainer] setContainerSize:(vb.size)];
  ms.width = ms.height = 0.0;
  [myText setMinSize:ms];
  f = [[DrawApp currentDocument] staffScale];
  runnerStatus = 1;
  [[myText textStorage] beginEditing];
  [[myText textStorage] replaceCharactersInRange:NSMakeRange(0, [[myText string] length]) withAttributedString:stream];
  [[myText textStorage] endEditing];
  
  if ([myText alignment] != justcode[flags.just]) [myText setAlignment:justcode[flags.just]];

  [myText sizeToFit];
  fb = [myText frame];
  fo = fb;
  [myText scaleUnitSquareToSize:NSMakeSize(1.0 / f, 1.0 / f)];
  fb.size.width /= f;
  fb.size.height /= f;
  switch(flags.horizpos)
  {
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
  if (flags.vertpos)
  {
    fb.origin.y = vb.size.height - fb.size.height - [pg footerBase];
  }
  else
  {
    fb.origin.y = [pg headerBase];
  }
//  coutrect(fb.origin.x, fb.origin.y, fb.size.width, fb.size.height, 0.0, 5);
  if (NSIsEmptyRect(r) || !NSIsEmptyRect(NSIntersectionRect(r , fb)))
  {
      id graphicView = [DrawApp currentView];
      [[graphicView window] setAutodisplay:NO]; // don't let addSubview: cause redisplay
    [myText setFrame:fb];

    if ([myText alignment] != justcode[flags.just]) [myText setAlignment:justcode[flags.just]];
    [myText setBackgroundColor:backShade];
    [myText setDrawsBackground:YES];

    [[NSView focusView] addSubview: myText];
//    [myText display];
    [myText lockFocus];
    [myText drawRect:[myText bounds]];
    [myText unlockFocus];
    [myText removeFromSuperview];
    [myText setFrame:fo];
    [[graphicView window] setAutodisplay:YES];
  }
  [myText scaleUnitSquareToSize:NSMakeSize(f, f)];
  runnerStatus = 0;
  return self;
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
      NSString *trickyScan = [NSString stringWithCString:" }\12\254"];
      [aDecoder decodeArrayOfObjCType:"c" count:length at:olddata];
      olddata[length] = '\0';
      /*need to do the following:
          * scan for anything leading to {\TextVarCelln m }\0a\ac
          * print the 'anything' into newdata, followed by new identifying string
          * repeat as necessary
          *
          * place data into 'data', as attributed string
          * replace all occurrances of text 'TextVarCelln' with real cells.
       */
      theScanner = [NSScanner scannerWithString:[NSString stringWithCString:olddata]];
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
              [results appendBytes:[resultString cString] length:[resultString length]];
            }
          else {
              resultString = [[theScanner string] substringFromIndex:start];
              [results appendBytes:[resultString cString] length:[resultString length]];
              break;
          }
      }
      data = [[NSMutableAttributedString alloc] initWithRTF:results documentAttributes:NULL];
      free(olddata);
      for (j=0;j<foundCells;j++) {
          int rangeStart;
          TextVarCell *v;
          char cellNo;
          NSAttributedString *theAttrString;
          NSFileWrapper *theWrapper;
          NSTextAttachment *theAttachment;
          theScanner = [NSScanner scannerWithString:[data string]];
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
          theFont = [data attribute:NSFontAttributeName atIndex:rangeStart effectiveRange:NULL];
          if (theFont) [(TextVarCell *)v setFont:theFont];

          [theAttachment setAttachmentCell:v];
          theAttrString = [NSAttributedString attributedStringWithAttachment:theAttachment];

          [data beginEditing];
          [data replaceCharactersInRange:NSMakeRange(rangeStart,18) withAttributedString:theAttrString];
          [data addAttribute:NSFontAttributeName value:theFont range:NSMakeRange(rangeStart,1)];
          [data endEditing];
      }
//      printf("%s\n",(char *)[results bytes]);
  }
  else {
      data = [[aDecoder decodeObject] retain];
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b1, b2, b3, b4, b5, b6, b7;
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
//  [aCoder encodeArrayOfObjCType:"c" count:length at:data];
  [aCoder encodeObject:data];
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
    [aCoder setInteger:length forKey:@"length"];
    [aCoder setObject:data forKey:@"data"];
}


@end
