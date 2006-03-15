/* $Id$ */
#import "TextGraphic.h"
#import "TextInspector.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "System.h"
#import "Staff.h"
#import "StaffObj.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "Page.h"
#import "mux.h"
#import "FileCompatibility.h"

int justcode[4] = {NSLeftTextAlignment, NSCenterTextAlignment, NSRightTextAlignment, NSJustifiedTextAlignment};

int justformats[9] =
{
  0, NSCenterTextAlignment, NSLeftTextAlignment, NSRightTextAlignment, NSLeftTextAlignment, NSCenterTextAlignment, NSLeftTextAlignment, NSCenterTextAlignment, NSRightTextAlignment
};


@implementation TextGraphic

#define BOXSIZE 16.0
#define TEXTOFFSET 3

static const NSSize TGMaxSize={ 2000, 2000 };
static const NSSize minSize={ 12, 12 };
static NSTextView *drawText = nil;

+ (void)initClassVars
{
  if (!drawText)
  {
    drawText = [[NSTextView alloc] init];
    [drawText setRichText:YES];
    [drawText setEditable:NO];
    [drawText setSelectable:NO];

    [drawText setMaxSize:TGMaxSize];
    [drawText setMinSize:minSize];
    //sb: these from new Draw example:
//    [[drawText textContainer] setWidthTracksTextView:YES];
    [[drawText textContainer] setHeightTracksTextView:YES];
    [[drawText textContainer] setLineFragmentPadding:5.0]; /* (default) just in case */
    [drawText setHorizontallyResizable:NO];
    [drawText setVerticallyResizable:NO];
    [drawText setDrawsBackground:NO];
  }
}

+ (NSTextView *)drawText
{
    if (!drawText) [self initClassVars];
    return drawText;
}

+ (void)initialize
{
  if (self == [TextGraphic class])
  {
      (void)[TextGraphic setVersion: 4];	/* class version, see read: */ /*sb: was 3 before conversion. 4 changes data from array to object. */
    [TextGraphic initClassVars];
  }
  return;
}


- myInspector
{
  return ((gFlags.subtype == LABEL) ? nil : [TextInspector class]);
}


- init
{
  [super init];
  gFlags.type = TEXTBOX;
  length = 0;
  richTextData = nil;
  just = 0;
  client = nil;
  [[self class] initClassVars];//sb: from new Draw example
  return self;
}


- (BOOL) isDangler
{
  return (gFlags.subtype == LABEL);
}


- (BOOL) needSplit: (float) s0 : (float) s1
{
  return NO;
}


- (void)dealloc
{
    if (richTextData) [richTextData release];
  [super dealloc];
  return;
}


- sysInvalid
{
  return [client sysInvalid];
}


- (BOOL) getHandleBBox: (NSRect *) r
{
  NSRect b = NSInsetRect(bounds , -2.0 , -2.0);//sb: was -2.0.
  *r  = NSUnionRect(b , *r);
  return YES;
}

- (TextGraphic *) newFrom
{
  TextGraphic *p = [[TextGraphic alloc] init];
  p->gFlags = gFlags;
  p->bounds = bounds;
  p->baseline = baseline;
  p->offset = offset;
  p->richTextData = [richTextData copy];//sb: was NXCopyStringBuffer(data);
  p->length = length;
  p->horizpos = horizpos;
  p->just = just;
  return p;
}


/*
  return the space required for a textgraphic.  This is its offset to its top border,
  plus its margin above that.
*/ 

- (float) topMargin
{
  float h = -(offset.y);
  if (h < 0) h = 0;
  if (gFlags.subtype == TITLE && baseline) h += baseline / [[NSApp currentDocument] staffScale];
  return h;
}


/*
  elaborate placement for Label
*/

- proto: v : (NSPoint) pt : (Staff *) sp : sys : (Graphic *) g : (int) i
{
  int n;
  float ty;
  StaffObj *p;
  float fontsize = [[[NSFontManager sharedFontManager] selectedFont] pointSize];
  
  gFlags.subtype = i;
  bounds.size.width = BOXSIZE;
  bounds.size.height = fontsize;
  switch(i)
  {
      case STAFFHEAD:
          if (TYPEOF(sp) == SYSTEM) sp = [sys findOnlyStaff: pt.y];
          client = sp;
          offset.x = pt.x - 5;/*sb: subtract 5 to compensate for text container inset */
          /* sb: subtract 1/2 fontsize, for better box positioning */
          offset.y = [sp yOfPos: [sp findPos: pt.y]] - sp->y - floor(fontsize / 2.0);
          break;
      case TITLE:
          client = sys;
          sp = [client firststaff];
          offset.x = pt.x - 5;/*sb: subtract 5 to compensate for text container inset */
          /* sb: subtract 1/2 fontsize, for better box positioning */
          offset.y = [sp yOfPos: [sp findPos: pt.y]] - sp->y - floor(fontsize / 2.0);
          break;
      case LABEL:
          p = [v isSelTypeCode: TC_STAFFOBJ : &n];
          if (n != 1) return nil;
          sp = p->mystaff;
          horizpos = 0;
          offset.x = -(0.5 * BOXSIZE) - 3;
          ty = p->bounds.origin.y - (0.5 * BOXSIZE);
          if (sp->y < ty) ty = sp->y;
              offset.y = (ty - 1.5 * BOXSIZE) - p->y;
          client = p;
          [client linkhanger: self];
          break;
  }
  return self;
}


/*
  pasting copy of self and attach to each staffobj element of sl.
*/

- attachTo: (StaffObj *) p
{   
  if (gFlags.subtype != LABEL)
  {
    gFlags.subtype = LABEL;
    horizpos = 0;
    offset.x = -(0.5 * bounds.size.width);
    offset.y = -(16.0 + bounds.size.height);
  }
  client = p;
  [client linkhanger: self];
  return [self recalc];
}


- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
  StaffObj *p;
  TextGraphic *t;
  BOOL r = NO;
  int k = [sl count];
  while (k--)
  {
    p = [sl objectAtIndex:k];
    if (ISASTAFFOBJ(p))
    {
      t = [self newFrom];
      [t attachTo: p];
      [v selectObj: t];
      r = YES;
    }
  }
  return r;
}  


- initFromString: (NSString *) s : (NSFont *) f
{
    NSSize maxSize;
    bounds.origin.x = bounds.origin.y = bounds.size.width = bounds.size.height = 0.0;
  [drawText setRichText:YES];
  [drawText setDrawsBackground:NO];
  maxSize.width = 500.0;
  maxSize.height = 500.0;
  [drawText setMinSize:bounds.size];
  [drawText setMaxSize:maxSize];
  printf("set max size in initFromString to %g %g\n",maxSize.width, maxSize.height);
  [drawText setVerticallyResizable:YES];
  [drawText setHorizontallyResizable:YES];
  [drawText setString:s];//sb: changed
  [drawText setFont:f];
  [drawText setRichText:YES];
  [drawText setAlignment:justcode[(int)just]];
  [drawText sizeToFit];
  [richTextData autorelease];
  richTextData = [[drawText RTFFromRange:NSMakeRange(0, [[drawText string] length])] retain];
//  richTextData = [[drawText textStorage] mutableCopy];
  bounds = [drawText frame];
  return self;
}


/* Reset some of the offsets and bounds, depending on subtype */

- recalc
{
  System *s=nil;
  Staff *sp=nil;
  NSRect r;
  float lm, w;
  w = bounds.size.width;
  switch (gFlags.subtype)
  {
    case LABEL:
      bounds.origin.x = ((StaffObj *)client)->x + offset.x;
      bounds.origin.y = ((StaffObj *)client)->y + offset.y;
      return self;
    case STAFFHEAD:
      sp = client;
      s = sp->mysys;
      break;
    case TITLE:
      s = client;
      sp = [s firststaff];
      break;
  }
  lm = [s leftMargin];
  switch(horizpos)
  {
    case 0:
      break;
    case 1:
      r = [s->view bounds];
      offset.x = 0.5 * (r.size.width - w);
      break;
    case 2:
        offset.x = [s leftWhitespace] - TEXTOFFSET;
      break;
    case 3:
        offset.x = [s leftWhitespace] + s->width - w + 2.2 ;/*sb: offset of +2.2 */
      break;
    case 4:
        offset.x = lm - TEXTOFFSET;
      break;
    case 5:
      offset.x = [s leftWhitespace] + 0.5 * s->width - 0.5 * w;
      break;
    case 6:
        offset.x = lm  - TEXTOFFSET;
        offset.y = [sp yOfCentre] - 0.5 * bounds.size.height - sp->y;
      break;
    case 7:
      offset.x = 0.5 * [s leftPlace] - 0.5 * w;
      offset.y = [sp yOfCentre] - 0.5 * bounds.size.height - sp->y;
      break;
    case 8:
        offset.x = [s leftPlace] - w - 10.0 + 2;/*sb: offset of +2*/
        offset.y = [sp yOfCentre] - 0.5 * bounds.size.height - sp->y;
      break;
  }
  bounds.origin.x = offset.x;
  bounds.origin.y = sp->y + offset.y;
  [client sysInvalid];
  return self;
}


/*
  Reset the offset.
  The bounds.size must be correct before this is called.
*/

- setHanger
{
  float x, w;
  if (gFlags.subtype == LABEL)
  {
    w = bounds.size.width;
    x = ((StaffObj *)client)->x;
    switch(horizpos)
    {
      case 0:
        break;
      case 1:
        offset.x = -0.5 * w;
        break;
      case 2:
        offset.x = -w;
        break;
      case 3:
        offset.x = 0;
        break;
    }
  }
  return [self recalc];
}


- presetHanger
{
  return [self setHanger];
}


/* removeObj is decomposed like this because sometimes unlink only is needed */

- unlinkObj
{
  System *s;
  switch (gFlags.subtype)
  {
    case LABEL:
      [client unlinkhanger: self];
      break;
    case STAFFHEAD:
      s = ((Staff *)client)->mysys;
      [s unlinkobject: self];
      break;
    case TITLE:
      [client unlinkobject: self];
      break;
  }
  return self;
}


- (void)removeObj
{
    [self retain];
    [self unlinkObj];
    [self release];
}


- (BOOL) changeVFont: (NSFont *) f : (BOOL) all
{
    NSSize maxSize;
//    NSTextStorage *myStorage;
    if (richTextData == nil) return NO;
    maxSize.width = 500.0;
    maxSize.height = 500.0;
    printf("changing vfont in TextGraphic! Didn't think we'd make it to here.\n");
    
    [drawText setMinSize:bounds.size];
    [drawText setMaxSize:maxSize];
    printf("set max size in changeVFont to %g %g\n",maxSize.width, maxSize.height);
    [drawText setVerticallyResizable:YES];
    [drawText setHorizontallyResizable:YES];
  [drawText replaceCharactersInRange:NSMakeRange(0, [[drawText string] length]) withRTF:richTextData];
//sb: replaced the former line with the following lines. Trying to get away from rtf
// data, and change to using the underlying objects instead.
//    myStorage = [drawText textStorage];
//    [myStorage beginEditing];
//    [myStorage setAttributedString:richTextData];
//    [myStorage endEditing];
    
    [drawText setFont:f];
    [drawText setRichText:YES];
    [drawText sizeToFit];
    bounds = [drawText frame];
    [richTextData autorelease];
    richTextData = [[NSData alloc] initWithData:[drawText RTFFromRange:(NSRange){0, (int)[[drawText string] length]}]];//sb: data used to be stream

    length = [richTextData length];
    return YES;
}


/* add extra bits to indicate whether a corner hit */

- (BOOL) hit:(NSPoint)p
{
  if (gFlags.subtype == STAFFHEAD && ((Staff *)client)->flags.hidden) return NO;
  return [super hitCorners: p];
}


- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  float nx = dx + p.x;
  float ny = dy + p.y;
  Staff *sp;
  switch(gFlags.subtype)
  {
    case LABEL:
      if (horizpos == 0) offset.x = nx - ((StaffObj *)client)->x;
      offset.y = ny - ((StaffObj *)client)->y;
      break;
    case STAFFHEAD:
      sp = client;
      if (horizpos == 0) offset.x = nx;
      offset.y = [sp yOfPos: [sp findPos: ny]] - sp->y;
      break;
    case TITLE:
      sp = [client firststaff];
      if (horizpos == 0) offset.x = nx;
      offset.y = [sp yOfPos: [sp findPos: ny]] - sp->y;
      break;
  }
  [self recalc];
  return YES;
}



+ cursor
{
    return [NSCursor IBeamCursor];
}

/* Factory method used to show/hide the ruler */
/* This has a bug inherited from Draw.  When the window is closed, the
view is freed, so hideRuler gets a bogus pointer */

+ hideRuler:view
/*
 * Tries to hide any rulers that are lying around.
 * If view is nil, obviously it won't hide the ruler
 * (we use this fact to cancel a previous request that
 * we might have made to hide the ruler).
 */
{
    [view tryToPerform:@selector(setRulerVisible:) with:NO];
    return self;
}

extern NSColor * backShade;
extern NSColor * selShade;
extern NSColor * markShade;
extern NSColor * inkShade;

/* convenience methods for use with delayed messages */
- (BOOL)edit:(NSEvent *)event
{
    return [self edit:event in:graphicView];
}
- (void)editMe:gv
{
    [self edit:nil in:gv];
    [[gv window] makeFirstResponder:fe];
}

- (BOOL)edit:(NSEvent *)event in:view
{
    NSSize maxSize,containerSize;
    NSSize minSize;
    NSRect viewBounds;
  /* Get the field editor in this window. */

    graphicView = (GraphicView *)view;
    /* sb: because GraphicView is flipped, we don't need editview. [editView superview];*/
            /* sb additions and changes from new Draw.app example */
    [[graphicView window] endEditingFor:self];

    fe = (NSTextView *)[[graphicView window] fieldEditor:YES forObject:self];
    [fe setFont:[[NSFontManager sharedFontManager] selectedFont]];/* sb: was [NSFontManager new]; */
    [fe setFieldEditor:NO];
    [fe setUsesFontPanel:YES];
    [fe setRichText:YES];
    [fe setDrawsBackground:NO];
    viewBounds = [graphicView bounds];//sb: not editview
    maxSize.width = viewBounds.origin.x + viewBounds.size.width - bounds.origin.x;
    maxSize.height = viewBounds.origin.y + viewBounds.size.height - bounds.origin.y;
    minSize.width = minSize.height = [[fe font] pointSize];

    [fe setMinSize:bounds.size];
    [fe setMaxSize:maxSize];
    [fe setFrame:bounds];
    [fe setVerticallyResizable:YES];
    [[fe textContainer] setLineFragmentPadding:5.0];/* in case the field editor was messed with by someone else */

    gFlags.selbit = 1;

  /* Show text ruler and abort hiding the ruler if recently ended editing. */
    [NSObject cancelPreviousPerformRequestsWithTarget:[self class]
                                             selector:@selector(hideRuler:)
                                               object:nil];
    [[self class] performSelector:@selector(hideRuler:)
                       withObject:nil
                       afterDelay:0];

    [fe setAlignment:justcode[(int)just]];

    lastEditingFrame = NSZeroRect;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editorFrameChanged:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:fe];
    if (richTextData)
  {
        [fe setHorizontallyResizable:NO];
        [[fe textContainer] setWidthTracksTextView:NO];
        containerSize.width = bounds.size.width + 1;
        containerSize.height = [[fe textContainer] containerSize].height;
        [[fe textContainer] setContainerSize:containerSize];
        [fe replaceCharactersInRange:(NSRange){0, [[fe string] length]} withRTF:richTextData];
  }
    else
  {
        [fe setHorizontallyResizable:YES];
        [[fe textContainer] setWidthTracksTextView:NO];
        containerSize.width = NSMaxX(viewBounds) - bounds.origin.x;
        containerSize.height = [[fe textContainer] containerSize].height;
        [[fe textContainer] setContainerSize:containerSize];
        [fe setString:@""];
        [fe setAlignment:NSLeftTextAlignment];
        [fe setFont:fontdata[FONTTEXT]];
        [fe setTextColor:inkShade range:[fe selectedRange]];
        [fe unscript:self];
  }
//  [fe setSelColor: selShade];

  /*
   * Add the Text object to the view hierarchy and set self as its delegate
   * so that we will receive the textDidEnd:endChar: message when editing
   * is finished.
  */
    [fe setDelegate:self];
    [graphicView addSubview:fe];
    [self traceBounds];//was always in Calliope
  /*
   * Make it the first responder.
  */
    [[graphicView window] makeFirstResponder:fe];
  /*
   * Either pass the mouse-down event on to the Text object, or set
   * the selection at the beginning of the text.
  */
    [fe setSelectedRange:(NSRange){0,0}];
    [graphicView cache:bounds];

  if (event)
  {
    [fe mouseDown:event];
  }
  return YES;
}

extern int selMode;
- traceBounds /* override from Graphic.m */
{
    coutrect(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height, 0.0, selMode);
    return self;
}

/*
  First load up the shared drawText Text object with
  our rich text.  Then set the frame of the drawText object
  to be our bounds.   Add the Text object as a subview of
  the view that is currently being drawn in ([NXApp focusView])
  and tell the Text object to draw itself.  Then remove the Text
  object view from the view hierarchy.
*/
- drawMode: (int) m
{
    NSSize conts;
    if (gFlags.selbit) return self;
    if (gFlags.selected && m) [self traceBounds];
    if (richTextData)
      {
        [drawText replaceCharactersInRange:NSMakeRange(0, [[drawText string] length]) withRTF:richTextData];
//        [self initFromData:richTextData];//sb
        [drawText setFrame:bounds];
        conts = bounds.size;
        conts.width += 1; /* allow text to take a little more room than it would otherwise */
        [[drawText textContainer] setContainerSize:conts];
//        printf("drawText textContainer size: %g %g\n",conts.width,conts.height);
//        printf("drawText frame size: %g %g\n",bounds.size.width,bounds.size.height);
        [[graphicView window] setAutodisplay:NO]; // don't let addSubview: cause redisplay
        [[NSView focusView] addSubview:drawText];
        [drawText setSelectedTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: selShade, NSBackgroundColorAttributeName, nil]];
        [drawText setTextColor:inkShade];
        [drawText lockFocus];
        [drawText drawRect:[drawText bounds]];
        [drawText unlockFocus];
//    [drawText setSelColor:selShade];
    //sb: ideally, we should use the following, that uses selection colours from a system-wide basis.
//    [drawText setSelectedTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor selectedControlTextColor], NSForegroundColorAttributeName, [NSColor selectedTextBackgroundColor], NSBackgroundColorAttributeName, nil]];
    //sb: but this will do ok.
        [drawText removeFromSuperview];
        [[graphicView window] setAutodisplay:YES];
      }
    return self;
}


- draw
{
  if (gFlags.subtype == STAFFHEAD && ((Staff *)client)->flags.hidden) return self;
  return [self drawMode: drawmode[gFlags.selected][gFlags.invis]];
}


- (BOOL) isResizable
{
  return YES;
}

- (BOOL) isEditable
{
  return YES;
}


/* Text object delegate methods */

- (void)alignLeft:(id)sender
{
  just = 0;
  [self recalc];
  return;
}

- (void)alignCenter:(id)sender
{
  just = 1;
  [self recalc];
  return;
}

- (void)alignRight:(id)sender
{
  just = 2;
  [self recalc];
  return;
}


/*
  Extract the rich text and store it away. rest bounds from frame of the Text object.
  If Text object is empty, then remove from the GraphicView and delayedFree: it.
  Remove the Text object from the view hierarchy and, since
  this Text object is going to be reused, set its delegate back to nil.
 */

- (void)textDidEndEditing:(NSNotification *)notification
{
    int len;
    NSRect redrawRect;

    printf("did end editing\n");

    if (richTextData) {
        [richTextData autorelease];
        richTextData = nil;
    }
    gFlags.selbit = 0;
    redrawRect = bounds;
    len = [[fe string] length];
    if (!len) {
        [graphicView deselectObj: self];
        [self unlinkObj];
    }
    else {
        NSSize conts = [[fe textContainer] containerSize];
        richTextData = [[NSData alloc] initWithData:[fe RTFFromRange:NSMakeRange(0, len)]];
        bounds = [fe frame];
//        bounds.size.width = ceil(bounds.size.width + 2); /* without this, sometimes text rewraps unexpectedly */
        printf("frame: %g %g %g %g\n",bounds.origin.x,bounds.origin.y,bounds.size.width,bounds.size.height);
        printf("cont size: %g %g\n",conts.width,conts.height);
        [self getHandleBBox: &redrawRect];
        redrawRect  = NSUnionRect(bounds , redrawRect);
        [self recalc];
    }
    [[graphicView window] disableFlushWindow];
    [graphicView tryToPerform:@selector(hideRuler:) with:nil];
    [fe removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:fe];
    [fe setDelegate:nil];
    [fe setSelectedRange:(NSRange){0,0}];
    fe = nil;

    [graphicView cache: redrawRect];
    [[graphicView window] enableFlushWindow];
    [[graphicView window] flushWindow];
    [graphicView dirty];
    if (!len) [self autorelease];
}
- (void)updateEditingViewRect:(NSRect)updateRect
{
/* this redraws the graphicview inside the area that the field editor occupied
 * before it shrunk.
 */
    [graphicView lockFocus];
    [graphicView drawRect:updateRect];
    [graphicView unlockFocus];
    [[graphicView window] flushWindow];
}

- (void)editorFrameChanged:(NSNotification *)arg
{
    NSRect currentEditingFrame = [[arg object] frame];
    if (!NSEqualRects(lastEditingFrame, NSZeroRect)) {
        if (lastEditingFrame.size.width > currentEditingFrame.size.width) {
            NSRect updateRect = lastEditingFrame;
            updateRect.origin.x = currentEditingFrame.origin.x + currentEditingFrame.size.width;
            [self updateEditingViewRect:updateRect];
        }
        if (lastEditingFrame.size.height > currentEditingFrame.size.height) {
            NSRect updateRect = lastEditingFrame;
            updateRect.origin.y = currentEditingFrame.origin.y + currentEditingFrame.size.height;
            [self updateEditingViewRect:updateRect];
        }
    }
    lastEditingFrame = currentEditingFrame;
}

/* Archiving methods */

struct oldflags /* for old version */
{
  unsigned int horizpos : 4;	/* runner/label/staffhead horizontal place */
  unsigned int just     : 2;  /* label/staffhead */
};


- (id)initWithCoder:(NSCoder *)aDecoder
{
  struct oldflags f;
  int v = [aDecoder versionForClassName:@"TextGraphic"];
  [super initWithCoder:aDecoder];
  client = [[aDecoder decodeObject] retain];
  offset = [aDecoder decodePoint];
  baseline = 0.0;
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"si", &f, &length];
    horizpos = f.horizpos >> 1;
    just = f.just;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"si", &f, &length];
    horizpos = f.horizpos;
    just = f.just;
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"cci", &horizpos, &just, &length];
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"fcci", &baseline, &horizpos, &just, &length];
  }
  if (v > 3) { /*sb: to change the way data is written/read (NSData object) */
      [aDecoder decodeValuesOfObjCTypes:"fcci", &baseline, &horizpos, &just, &length];
      richTextData = [[aDecoder decodeObject] retain];
  } else {/* sb: the old way (v3 and older) */
      char *newdata;
      static id listclass = nil;
      // TODO LMS commented out to get things compiling, this is needed to support the legacy file format
      //if (!listclass) listclass = [List class];
      newdata = malloc(length+1);
      [aDecoder decodeArrayOfObjCType:"c" count:length at:newdata];
      richTextData = [[NSData dataWithBytes:newdata length:length] retain];
      free(newdata);
      /* allow for differences between margins in old and new Text objects */
      bounds.origin.x -= 3;
      bounds.size.width += 5;
      if (gFlags.subtype == LABEL) offset.x -= 3;
      if (gFlags.subtype == STAFFHEAD || gFlags.subtype == TITLE) {
          switch(horizpos)
          {
            case 0:
                offset.x -= 3;
              break;
            case 1:
              break;/* centred on page width */
            case 2:
                offset.x -= 3;/* left align on indent */
              break;
            case 3:
                bounds.origin.x += 0.5;/* bring it back a bit...*/
                offset.x += 6;/* right align on rt margin */
              break;
            case 4:
                offset.x -= 3;/* left align on left margin */
              break;
            case 5:
                break;/* centred on staff width */
            case 6:
                offset.x -= 3;/* left align before staff */
              break;
            case 7:
                break;/* centred before staff */
            case 8:
                offset.x += 6;/* right align before staff */
              break;
          }
      }         
//      printf("text frame from old doc: %g %g %g %g\n",bounds.origin.x,bounds.origin.y,bounds.size.width,bounds.size.height);
      if ([client class] == listclass) client = [[NSMutableArray allocWithZone:[self zone]] initFromList:client]; /*fix up List object */
  }
    [[self class] initClassVars];
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeConditionalObject:client];
  [aCoder encodePoint:offset];
  [aCoder encodeValuesOfObjCTypes:"fcci", &baseline, &horizpos, &just, &length];
  [aCoder encodeObject:richTextData];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setObject:client forKey:@"client"];
    [aCoder setPoint:offset forKey:@"offset"];
    [aCoder setFloat:baseline forKey:@"baseline"];
    [aCoder setInteger:horizpos forKey:@"horizpos"];
    [aCoder setInteger:just forKey:@"just"];
    [aCoder setInteger:length forKey:@"length"];
//    [aCoder setObject:richTextData forKey:@"rtext"];
    [aCoder setString:[[[NSString alloc] initWithData:richTextData encoding:NSASCIIStringEncoding] autorelease] forKey:@"rtext"];
}

@end
