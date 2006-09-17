/* $Id$ */
#import <AppKit/AppKit.h>
#import "SysInspector.h"
#import "SysAdjust.h"
#import "SysCommands.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVCommands.h"
#import "GVGlobal.h"
#import "OpusDocument.h"
#import "DrawApp.h"
#import "Staff.h"
#import "System.h"
#import "Page.h"
#import "Margin.h"
#import "Bracket.h"
#import "CallPart.h"
#import "MultiView.h"
#import "DragMatrix.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "CalliopeThreeStateButton.h"
#import "ProgressDisplay.h"

@implementation NSMutableArray(StyleSys)


- (NSString *) styleNameForInt: (int) i
{
  if (i == -1) return nullPart;
  if (i >= [self count]) return nullPart;
  return ((System *)[self objectAtIndex:i])->style;
}


- (System *) styleSysForName: (NSString *) a
{
  int k = [self count];
  System *s;
  while (k--)
  {
    s = [self objectAtIndex:k];
      if ([s->style isEqualToString: a]) return s;
  }
  return nil;
}


/*
  The sort is required to be fastest when elements are in order. Shellsort.
*/

#define STRIDE_FACTOR 3

- sortStylelist
{
  int c, d, f, s, k;
  System *p;
  k = [self count];
  if (k == 1) return self;
  s = 1;
  while (s <= k) s = s * STRIDE_FACTOR + 1;
  while (s > (STRIDE_FACTOR - 1))
  {
    s = s / STRIDE_FACTOR;
    for (c = s; c < k; c++)
    {
      f = NO;
      d = c - s;
      while ((d >= 0) && !f)
      {
//        if (strcmp(((System *)[self objectAt: d + s])->style, ((System *)[self objectAt: d])->style) < 0)
          if ([((System *)[self objectAtIndex:d + s])->style compare: ((System *)[self objectAtIndex:d])->style] == NSOrderedAscending)
	{
	  p = [[self objectAtIndex:d] retain];
	  [self replaceObjectAtIndex:d withObject:[self objectAtIndex:d + s]];
	  [self replaceObjectAtIndex:d + s withObject:p];
          [p release];
	  d -= s;
	}
	else f = YES;
      }
    }
  }
  return self;
}


@end

extern int staffspace[3][3];
extern float staffheads[3];

/*
  multiviews:
    0 indentation
    1 numbering
    2 page keep options
    3 vertical format
    4  adjustment
    5 styles
    6 system separator slashes
*/

/*
  staffviews:
    0 standard
    1 layout
    2 preface
*/


@implementation SysInspector

static int mypartlist = -1;
static BOOL busyFlag = 0;  /* so that inspector is not inspected because of a callout */


- (BOOL) isBusy
{
  return busyFlag;
}

- enableButtons: (int) b1 : (int) b2 : (int) b3 : (int) b4 : (int) b5 : (int) b6
{
  [newstybutton setEnabled:b1];
  [defstybutton setEnabled:b2];
  [constybutton setEnabled:b3];
  [delstybutton setEnabled:b4];
  [renstybutton setEnabled:b5];
  [finstybutton setEnabled:b6];
  return self;
}


- styleButtons: (NSString *) t
{
  System *st;
  NSString *n;
  int i = [[stybrowser matrixInColumn: 0] selectedRow];
  if (i < 0 || i > [[[DrawApp sharedApplicationController] getStylelist] count])
  {
    if (t != NULL) [stytext setStringValue:@""];
    [self enableButtons: 1 : 0 : 0 : 0 : 0 : 0];
  }
  else
  {
    if (t != nil) [stytext setStringValue:t];
    st = [[[DrawApp sharedApplicationController] getStylelist] objectAtIndex:i];
    n = [stytext stringValue];
    if (![st->style isEqualToString: n])
    {
        if ([n isEqualToString: @""]) [self enableButtons: 1 : 0 : 0 : 0 : 0 : 0];
      else [self enableButtons: 1 : 0 : 0 : 0 : 1 : 0];
    }
    else
    {
      [self enableButtons: 0 : 1 : 1 : 1 : 0 : 1];
    }
  }
  return self;
}



/*
  Loads up the inspector from system.
*/

- loadDataFor: (System *) sys : (int) bt
{
  float conv;
  [nstavestext setIntValue: [sys numberOfStaves]];
  switch (bt)
  {
    case -1:
    case 0:
        conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//      [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
      [[indentleft cellAtIndex:0] setFloatValue:sys->lindent * conv];
      [[indentright cellAtIndex:0] setFloatValue:sys->rindent * conv];
      break;
    case 1:
        if (sys->flags.newbar)
      {
        [newbarbutton setState:YES];
            [[newform cellAtIndex:0] setIntValue:sys->barnum];
	[[newform cellAtRow:0 column:0] setEnabled:YES];
      }
      else
      {
        [newbarbutton setState:NO];
        [[newform cellAtIndex:0] setIntValue:sys->barnum];
	[[newform cellAtRow:0 column:0] setEnabled:NO];
      }
        if (sys->flags.newpage)
      {
        [newpagebutton setState:YES];
        [[newform cellAtIndex:1] setIntValue: [sys pageNumber]];
	[[newform cellAtRow:1 column:0] setEnabled:YES];
      }
      else
      {
        [newpagebutton setState:NO];
        [[newform cellAtIndex:1] setIntValue: [sys pageNumber]];
	[[newform cellAtRow:1 column:0] setEnabled:NO];
      }
      break;
    case 2:
      [pagematrix setState:sys->flags.pgcontrol];
      break;
    case 3:
      [equidistbutton setState:sys->flags.equidist];
      [[expansionform cellAtIndex:0] setFloatValue:sys->expansion * 100.0];
      [[expansionform cellAtRow:0 column:0] setEnabled:!(sys->flags.equidist)];
      [[expansionform cellAtIndex:1] setFloatValue:sys->groupsep];
      break;
    case 4:
      [polymatrix selectCellAtRow:sys->flags.disjoint column:0];
      break;
    case 5:
      [stybrowser loadColumnZero];
        [stybrowser setPath:sys->style];
      [self styleButtons: sys->style];
      break;
    case 6:
      [[syssepmatrix cellAtRow:0 column:0] setState:(sys->flags.syssep & 2)];
      [[syssepmatrix cellAtRow:1 column:0] setState:(sys->flags.syssep & 1)];
      break;
  }
  return self;
}


- loadDataFor: (int) bt
{
  System *sys = [[DrawApp sharedApplicationController] currentSystem];
  if (sys != nil) [self loadDataFor: sys : bt];
  return self;
}


- setView: (int) i
{
  if ([NSView focusView] == multiview) [multiview unlockFocus];
  if (![[DrawApp sharedApplicationController] currentSystem])
  {
    if (multiview != nodocview) [multiview replaceView: nodocview];
    return self;
  }
  [self loadDataFor: i];
  switch(i)
  {
    case 0:
      if (multiview != indentview) [multiview replaceView: indentview];
      break;
    case 1:
      if (multiview != numberview) [multiview replaceView: numberview];
      break;
    case 2:
      if (multiview != keepview) [multiview replaceView: keepview];
      break;
    case 3:
      if (multiview != vertview) [multiview replaceView: vertview];
      break;
    case 4:
      if (multiview != polyview) [multiview replaceView: polyview];
      break;
    case 5:
      if (multiview != styleview) [multiview replaceView: styleview];
      break;
    case 6:
      if (multiview != syssepview) [multiview replaceView: syssepview];
      break;
  }
  return self;
}


- changeBox: sender
{
    return [self setView: [mainPopup indexOfSelectedItem]];
}


- changeStaffView: sender
{
  System *sys = [[DrawApp sharedApplicationController] currentSystem];
  if (sys != nil) [self pickstaff: self];
  switch([staffnumbutton indexOfSelectedItem])
  {
    case 0:
      if (staffview != standview) [staffview replaceView: standview];
      break;
    case 1:
      if (layoutview != numberview) [staffview replaceView: layoutview];
      break;
    case 2:
      if (prefview != keepview) [staffview replaceView: prefview];
      break;
  }
  return self;
}


- constructPartList
{
  int i, k;
  NSMutableArray *pl;
  if (mypartlist == partlistflag) return self;
  [partbutton removeAllItems];
  [partbutton addItemWithTitle:@"multiple selection"];
  pl = [[DrawApp sharedApplicationController] getPartlist];
  k = [pl count];
  for (i = 0; i < k; i++) [partbutton addItemWithTitle:[pl partNameForInt: i]];
  mypartlist = partlistflag;
  return self;
}


- setSystemPart
{
  GraphicView *v = [DrawApp currentView];
  System *sys = [v currentSystem];
  Staff *sp;
  if (sys == nil) return self;
  if (popSelectionFor(partbutton) == 0) return self;
  sp = [sys getstaff: [staffmatrix selectedRow]];
  if (sp->part) [sp->part autorelease];
  sp->part = [popSelectionNameFor(partbutton) retain];
  [v dirty];
  return self;
}


/* the new action when part button is pressed */

- makePartList: sender
{
  [self constructPartList];
//#error PopUpConversion: 'popUp:' is obsolete because it is no longer necessary.
//  [partpopup popUp:sender];
  [self setSystemPart];
  return self;
}


/* called during nib loading */

- setPartbutton: sender
{
  partbutton = sender;
//  partpopup = [partbutton target];
  [partbutton setTarget:self];
  [partbutton setAction:@selector(makePartList:)];
//  [partpopup setTarget:self];
//  [partpopup setAction:@selector(dataChanged:)];
  return self;
}


/* make a DragMatrix for the staff buttons, to get CTRL-drag functionality */

- createScrollingMatrix
{
  NSRect scrollRect, matrixRect;
  NSSize cellSize;
  NSButtonCell *procell;
  [staffscroll setBorderType:NSBezelBorder];
  [staffscroll setHasVerticalScroller:YES];
  [staffscroll setHasHorizontalScroller:NO];
  scrollRect = [staffscroll frame];
  (matrixRect.size) = [NSScrollView contentSizeForFrameSize:(scrollRect.size) hasHorizontalScroller:YES hasVerticalScroller:YES borderType:NSBezelBorder];
  procell = [[NSButtonCell alloc] init];
  [procell setImagePosition:NSImageRight];
  [procell setAlignment:NSLeftTextAlignment];
  [procell setTarget:self];
  [procell setAction:@selector(pickstaff:)];
  staffmatrix = [[DragMatrix alloc] initWithFrame:matrixRect mode:NSListModeMatrix prototype:procell numberOfRows:0 numberOfColumns:1];
  [staffmatrix setDeleg:self];/*sb: so matrix will let us know when reordered. sends self "matrixDidReorder:self" */
  cellSize.width = NSWidth(matrixRect);
  cellSize.height = 24.0;
  [staffmatrix setCellSize:cellSize];
  [staffmatrix setAutoscroll:YES];
  [staffscroll setDocumentView:staffmatrix];
  [[staffmatrix superview] setAutoresizesSubviews:YES];
  return self;
}

- matrixDidReorder:sender
{
    [self makeFirstResponder:reorderButton];
    return self;
}

- (void)awakeFromNib
{
  [self createScrollingMatrix];
  [(NSBrowser *)stybrowser setDelegate:self];
  [mainPopup selectItemAtIndex:0];
  [self changeBox: self];
  [staffnumbutton selectItemAtIndex: 0];
}


/*
  returns a code if something is to be done as a result of the setting
  bits: 1 = barnum; 2 = keep; 4 = page; 8 = margin.
*/

- (int) setSystem: (System *) sys
{
  float lind, rind, conv, f;
  int i, r = 0;
  switch([mainPopup indexOfSelectedItem])
  {
    case 0:
        conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//      [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&f];
      lind = [[indentleft cellAtIndex:0] floatValue] / conv;
      if (lind < -72 || lind > 72*5)
      {
        NSLog(@"Assertion failure in SysInspector");
	return 0;
      }
      rind = [[indentright cellAtIndex:0] floatValue] / conv;
      if (rind < -72 || rind > 72*5)
      {
        NSLog(@"Assertion failure in SysInspector");
	return 0;
      }
      if (lind != sys->lindent) r |= 8;
      sys->lindent = lind;
      sys->rindent = rind;
      break;
    case 1:
      i = [[newform cellAtIndex:0] intValue];
      if (i != sys->barnum) r |= 1;
      sys->barnum = i;
        i = [newbarbutton state];
        if (i != sys->flags.newbar) r |= 1;
        sys->flags.newbar = i;
        i = [[newform cellAtIndex:1] intValue];
        if (i != [sys pageNumber]) r |= 4;
	    [sys setPageNumber: i];
        i =  [newpagebutton state];
        if (i != sys->flags.newpage) r |= 4;
        sys->flags.newpage = i;
      break;
    case 2:
      i = [pagematrix state];
      if (i != sys->flags.pgcontrol) r |= 2;
      sys->flags.pgcontrol = i;
      break;
    case 3:
      f = [[expansionform cellAtIndex:0] floatValue] * 0.01;
      if (f < 0.5 || f > 2.0)
      {
        NSLog(@"Assertion failure in SysInspector");
	return 0;
      }
      sys->expansion = f;
      f = [[expansionform cellAtIndex:1] floatValue];
      if (f < -3 || f > 30)
      {
        NSLog(@"Assertion failure in SysInspector");
	return 0;
      }
      sys->groupsep = f;
      sys->flags.equidist = [equidistbutton state];
      break;
    case 4:
      sys->flags.disjoint = [polymatrix selectedRow];
      break;
    case 5:
      break;
    case 6:
      sys->flags.syssep = ([[syssepmatrix cellAtRow:0 column:0] state] << 1) + [[syssepmatrix cellAtRow:1 column:0] state];
      break;
  }
  return r;
}


- dataChanged: sender
{
  float conv;
  BOOL change = NO;
  System *sys = [[DrawApp sharedApplicationController] currentSystem];
  if (sys == nil)
  {
    if (![setButton isEnabled]) [setButton setEnabled:YES];
    if ([revertButton isEnabled]) [revertButton setEnabled:NO];
    return nil;
  }
  switch([mainPopup indexOfSelectedItem])
  {
    case 0:
        conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//      [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
      if (!change) change = (sys->lindent != [[indentleft cellAtIndex:0] floatValue] / conv);
      if (!change) change = (sys->rindent != [[indentright cellAtIndex:0] floatValue] / conv);
      break;
    case 1:
      if (!change) change = (sys->barnum != [[newform cellAtIndex:0] intValue]);
      if (!change) change =  ([newbarbutton state] != sys->flags.newbar);
      if (!change) change = ([sys pageNumber] != [[newform cellAtIndex: 1] intValue]);
      if (!change) change = ([newpagebutton state] != sys->flags.newpage);

      [[newform cellAtRow:0 column:0] setEnabled:[newbarbutton state]];
      [[newform cellAtRow:1 column:0] setEnabled:[newpagebutton state]];
      break;
    case 2: 
      if (!change) change = (sys->flags.pgcontrol != [pagematrix state]);
      break;
    case 3: 
      if (!change) change = (sys->expansion != [[expansionform cellAtIndex:0] floatValue] * 0.01);
      if (!change) change = (sys->groupsep != [[expansionform cellAtIndex:1] floatValue]);
      if (!change) change = (sys->flags.equidist != [equidistbutton state]);
      [[expansionform cellAtRow:0 column:0] setEnabled:!([equidistbutton state])];
      break;
    case 4:
      if (!change) change = (sys->flags.disjoint != [polymatrix selectedRow]);
      break;
    case 5:
      change = YES;
      break;
    case 6:
      if (!change) change = (sys->flags.syssep != ([[syssepmatrix cellAtRow:0 column:0] state] << 1) + [[syssepmatrix cellAtRow:1 column:0] state]);
      break;
  }
  if ([[sender superview] isDescendantOf:staffview]) change = YES;/* any changes in staffview automatically set setButton */
  if (change)
  {
    if (![revertButton isEnabled]) [revertButton setEnabled:YES];
    if (![setButton isEnabled]) [setButton setEnabled:YES];
    [self makeFirstResponder:setButton];
  }
  else
  {
    if ([revertButton isEnabled]) [revertButton setEnabled:NO];
    if ([setButton isEnabled]) [setButton setEnabled:NO];
  }
  return self;
}


void diffThreeState(NSButton *b, BOOL same, int val)
{
  if (same) [b setIntValue:(val != 0)];
  else [b setIntValue:2];
}


BOOL isClearForm(NSForm *f, int i)
{
  NSString *s = [[f cellAtIndex:i] stringValue];
  if (s == nil) return YES;
  return ([s isEqualToString:@""]);
}


/*
  Loads up the indexed staff(origin 0)  from the (self) inspector.
  return whether to update staff's button.
*/

- (BOOL) loadstaff: (System *) sys : (int) n
{
  int i, ds = 0, up = 0;
  Staff *sp = [sys getstaff: n];
//NSLog(@"enters loadstaff: %d\n", n);
  switch([staffnumbutton indexOfSelectedItem])
  {
    case 0:
        i = [hidebutton threeState];
      if (i != 2) sp->flags.hidden = i;
      if (!isClearForm(staffforms, 0))
      {
        up |= (sp->flags.nlines == [[staffforms cellAtIndex:0] intValue]);
        sp->flags.nlines = [[staffforms cellAtIndex:0] intValue];
      }
          if (popSelectionFor(partbutton) > 0) {
              if (sp->part) [sp->part autorelease];
              sp->part = [popSelectionNameFor(partbutton) retain];
          }
      i = [sizematrix selectedColumn];
      if (i >= 0 && sp->gFlags.size != i)
      {
        ds = i - sp->gFlags.size;
        sp->gFlags.size = i;
      }
      i = [notationmatrix selectedColumn];
      if (i >= 0 && (ds != 0 || sp->flags.subtype != i))
      {
        up |= (sp->flags.subtype != i);
        sp->flags.subtype = i;
        sp->topmarg = staffheads[i];
        sp->flags.spacing = staffspace[i][sp->gFlags.size];
      }
      break;
    case 1:
      i = [fixswitch threeState];
      if (i != 2) sp->flags.topfixed = i;
      if (!isClearForm(margintop, 0)) sp->topmarg = [[margintop cellAtIndex:0] floatValue];
      if (!isClearForm(verseoffform, 0)) sp->voffa = [[verseoffform cellAtIndex:0] floatValue];
      if (!isClearForm(verseoffform, 1)) sp->voffb = [[verseoffform cellAtIndex:1] floatValue];
      i = [barnumswitch threeState];
      if (i != 2) sp->flags.hasnums = i;
      if (!isClearForm(barbase, 0)) sp->barbase = [[barbase cellAtIndex:0] floatValue];
      break;
    case 2:
        i = [prefacebutton threeState];
      if (i != 2) sp->flags.haspref = i;
      if (!isClearForm(prefaceforms, 0)) sp->pref1 = [[prefaceforms cellAtIndex:0] floatValue];
      if (!isClearForm(prefaceforms, 1)) sp->pref2 = [[prefaceforms cellAtIndex:1] floatValue];
      break;
  }
  if (ds != 0) [sp resizeNotes: ds];
  return up;
}


- inspSys: (System *) sys
{
    if (sys != nil) [self loadDataFor: sys : [mainPopup indexOfSelectedItem]];
  return self;
}


void inspThreeState( id b, BOOL same, int val) /*sb: was NSButton *  */
{
  if (same) [b setThreeState:(val != 0)];
    else [b setThreeState:2];
}


void inspMatrix(NSMatrix *m, BOOL same, int row, int col)
{
  if (same) [m selectCellAtRow:row column:col]; else clearMatrix(m);
}


void inspIntForm(NSForm *f, int i, BOOL same, int val)
{
  if (same) [[f cellAtIndex:i] setIntValue:val];
  else
  {
    [[f cellAtIndex:i] setStringValue:@""];
    clearMatrix(f);
  }
}


void inspFloatForm(NSForm *f, int i, BOOL same, float val)
{
  if (same) [[f cellAtIndex:i] setFloatValue:val];
  else
  {
    [[f cellAtIndex:i] setStringValue:@""];
    clearMatrix(f);
  }
}


void inspAtomPop(NSPopUpButton *p, NSButton *b, BOOL same, NSString *val)
{
  if (same) selectPopNameFor(p, b, val); else selectPopFor(p, b, 0);
}


- inspStaff: (System *) sys : (int) n
{
    switch([staffnumbutton indexOfSelectedItem])
  {
    case 0:
      inspThreeState(hidebutton, ALLSAME(1, n), ALLVAL(1));
      inspMatrix(notationmatrix, ALLSAME(2, n), 0, ALLVAL(2));
      inspMatrix(sizematrix, ALLSAME(3, n), 0, ALLVAL(3));
      inspIntForm(staffforms, 0, ALLSAME(5, n), ALLVAL(5));
      inspAtomPop(partbutton, partbutton, ALLSAMEATOM(11, n), ALLVALATOM(11));
      break;
    case 1:
      inspThreeState(fixswitch, ALLSAME(0, n), ALLVAL(0));
      inspFloatForm(margintop, 0, ALLSAMEFLOAT(6, n), ALLVALFLOAT(6));
      inspFloatForm(verseoffform, 0, ALLSAMEFLOAT(9, n), ALLVALFLOAT(9));
      inspFloatForm(verseoffform, 1, ALLSAMEFLOAT(10, n), ALLVALFLOAT(10));
      inspThreeState(barnumswitch, ALLSAME(12, n), ALLVAL(12));
      inspFloatForm(barbase, 0, ALLSAMEFLOAT(13, n), ALLVALFLOAT(13));
      break;
    case 2:
      inspThreeState(prefacebutton, ALLSAME(4, n), ALLVAL(4));
      inspFloatForm(prefaceforms, 0, ALLSAMEFLOAT(7, n), ALLVALFLOAT(7));
      inspFloatForm(prefaceforms, 1, ALLSAMEFLOAT(8, n), ALLVALFLOAT(8));
      break;
  }
  return self;
}


/*
  Initialise the Staff selection matrix to contain the correct entries.
*/

static NSString *imstype[4] = {@"st5b", @"st6b", @"st4b", @"st5b"};
static NSString *imsclef[4] = {@"st5C", @"st5F", @"st5G", @"st1P"};

- setTheButton: (int) i : (int) n : (System *) sys
{
  int c;
  NSString *ci,*si;
  Staff *sp;
  NSButtonCell *cell = [staffmatrix cellAtRow:i column:0];
  if (atoi([[cell title] cString]) != i + 1)
  {
      [[staffmatrix cellAtRow:i column:0] setTitle:[NSString stringWithFormat:@"%d",i+1]];
  }
  /* figure out an icon */
  sp = [sys->staves objectAtIndex:i];
  si = imstype[sp->flags.subtype];
  if (sp->flags.subtype == 0)
  {
    c = [sp firstClefCentre];
      if (c >= 0) si = imsclef[c];
  }
  ci = [[cell image] name];
  if ([ci isEqualToString:@""] || ![ci isEqualToString:si]) [[staffmatrix cellAtRow:i column:0] setImage:[NSImage imageNamed:si]];
  return self;
}


- setStaffButton: (System *) sys
{
  int i, n, sn;
  if (sys == nil)
  {
    [staffmatrix renewRows:0 columns:1];
    [staffmatrix sizeToCells];
    [staffmatrix setNeedsDisplay];
    return self;
  }
  sn = [sys numberOfStaves];
  n = [[staffmatrix cells] count];
  [staffmatrix renewRows:sn columns:1];
//  [staffmatrix lockFocus];
  for (i = 0; i < sn; i++)
  {
    [staffmatrix highlightCell:NO atRow:i column:0];
    [[staffmatrix cellAtRow:i column:0] setState:0];
    [self setTheButton: i : n : sys];
  }
  [staffmatrix selectCellAtRow:0 column:0];
//  [staffmatrix unlockFocus];
  [staffmatrix sizeToCells];
  [staffmatrix setNeedsDisplay];
  return self;
}



/* Make a new system in view v. Might return nil */

- prepView: (GraphicView *) v
{
  busyFlag = YES;
  [v renumSystems];
  [v doPaginate];
  [v renumPages];
  [v setRunnerTables];
  [v balancePages];
  busyFlag = NO;
  return self;
}


- newSystem: (GraphicView *) v : (int) sn
{
  int i;
  System *sys;
  if (sn <= 0 || sn > NUMSTAVES)
  {
    NSRunAlertPanel(@"System", @"Incorrect number of staves: %d", @"OK", nil, nil, sn);
    return nil;
  }
  else
  {
    sys = [[System alloc] initWithStaveCount: sn onGraphicView: v];
    [self setSystem: sys];
    for (i = 0; i < sn; i++) [self loadstaff: sys : i];
    [sys initsys];
    if (sn > 1) [sys installLink];
    [self prepView: v];
    [v firstPage: self];
    [self setStaffButton: sys];
    [nstavestext setSelectable:NO];
    [newsysbutton setEnabled:NO];
  }
  return self;
}


/*
  Target of the SET button.
  Loadup the system and selected staff.
  Loads sys before staff because staff needs to know things from sys.
  DisplayCache the larger of the bounds before/after.
*/

- set: sender
{
  GraphicView *v = [DrawApp currentView];
  System *sys;
  int i, j, n;
  if (v == nil)
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  sys = [v currentSystem];
  if (sys == nil)
  {
    if ([self newSystem: v : [nstavestext intValue]] == nil) return self;
    sys = [v currentSystem];
  }
  if ([sys numberOfStaves] != [nstavestext intValue])
  {
    [nstavestext setIntValue: [sys numberOfStaves]];
  }
  [v saveSysLeftMargin];
  i = [self setSystem: sys];
//  NSLog(@"1. page number is %d\n", sys->pagenum);
  n = [[staffmatrix cells] count];
  for (j = 0; j < n; j++) if ([[staffmatrix cellAtRow:j column:0] isHighlighted])
  {
    if ([self loadstaff: sys : j]) [self setTheButton: j : n : sys];
  }
  busyFlag = YES;
  [sys recalc];
//  NSLog(@"2. page number is %d\n", sys->pagenum);
  if (i & (2+4+8))
  {
    /* does a paginate, but uses previous saveSysLeftMargin */
      ProgressDisplay *paginationProgress = [ProgressDisplay progressDisplayWithTitle: @"Paginating"];
    [v renumSystems];
    [v doPaginate];
    [v renumPages];
    [v setRunnerTables];
    [v shuffleIfNeeded];
    [v balancePages];
    [paginationProgress closeProgressDisplay];
    [v gotoPage: 0 usingIndexMethod: 4];
  }
  else if (i & 1)
  {
    [v renumSystems];
    [v renumPages];
  }
//  NSLog(@"3. page number is %d\n", sys->pagenum);
  if (i <= 1) [v balancePage: self];
  [self inspSys: sys];  /* do because paginate etc may have updated some sys values */
  busyFlag = NO;
  if ([revertButton isEnabled]) [revertButton setEnabled:NO];
  if ([setButton isEnabled]) [setButton setEnabled:NO];
  [self setDocumentEdited:NO];
  [v dirty];
  return self;
}


- (int) assayStaves: (System *) sys
{
  int i, n, a = 0;
  Staff *sp;
  initassay();
  n = [[staffmatrix cells] count];
  for (i = 0; i < n; i++) if ([[staffmatrix cellAtRow:i column:0] isHighlighted])
  {
    ++a;
    sp = [sys getstaff: i];
    assay(0, sp->flags.topfixed);
    assay(1, sp->flags.hidden);
    assay(2, sp->flags.subtype);
    assay(3, sp->gFlags.size);
    assay(4, sp->flags.haspref);
    assay(5, sp->flags.nlines);
    assayAsFloat(6, sp->topmarg);
    assayAsFloat(7, sp->pref1);
    assayAsFloat(8, sp->pref2);
    assayAsFloat(9, sp->voffa);
    assayAsFloat(10, sp->voffb);
    assayAsAtom(11, sp->part);
    assay(12, sp->flags.hasnums);
    assayAsFloat(13, sp->barbase);
  }
  return a;
}


/*
  Target of the Matrix in which are listed the staff number choices.
  Load the Inspector from the selected staff.
*/

- pickstaff: sender
{
  System *sys = [[DrawApp sharedApplicationController] currentSystem];
  if (sys != nil) [self inspStaff: sys : [self assayStaves: sys]];
  return self;
}


/*
  Handle a change of the number of staves in the system.
  If valid, make a new system and modify the staff number popup menu,
  else reset value.
*/

- setnstaves: sender;
{
    int sn;
    System *sys;
    OpusDocument *doc = [DrawApp currentDocument];
    GraphicView *v;
    sn = [nstavestext intValue];
    if (doc == nil)
    {
	doc = [OpusDocument new];
	v = [doc graphicView];
    }
    else 
	v = [doc graphicView];
    if ((sys = [v currentSystem]) != nil)
    {
	[nstavestext setIntValue: [sys numberOfStaves]];
	NSLog(@"-setnstaves: Current system != nil");
	return self;
    }
    if ([self newSystem: v : sn] == nil) return self;
    [newsysbutton setEnabled:NO];
    [self prepView: v];
    [v dirty];
    return self;
}


/*
  Called when Inspector is opened.  If no system, loadup panel with default values;
  else loadup from staff 1 of system.
*/

- preset
{
  System *sys = [[DrawApp sharedApplicationController] currentSystem];
  if (sys == nil)
  {
    [nstavestext setEditable:YES];
    [newsysbutton setEnabled:YES];
    [[barbase cellAtIndex:0] setFloatValue:(float) 0.0];
    [[indentleft cellAtIndex:0] setFloatValue:(float) 0.0];
    [[indentright cellAtIndex:0] setFloatValue:(float) 0.0];
    [[margintop cellAtIndex:0] setFloatValue:(float) staffheads[0]];
    [[margintop cellAtIndex:1] setFloatValue:(float) 0.0];
    [[expansionform cellAtIndex:0] setFloatValue:100.0];
    [[expansionform cellAtIndex:1] setFloatValue:0.0];    
    [nstavestext setIntValue:0];
    [nstavestext selectText:self];
    [[prefaceforms cellAtIndex:0] setIntValue:0];
    [[prefaceforms cellAtIndex:1] setIntValue:100];
    [[verseoffform cellAtIndex:0] setFloatValue:0];
    [[verseoffform cellAtIndex:1] setFloatValue:0];
    [[barbase cellAtIndex:0] setFloatValue:0.0];
    [barnumswitch setState:NO];
    [[staffforms cellAtIndex:0] setIntValue:5];
    [equidistbutton setState:NO];
    [newbarbutton setState:NO];
    [newpagebutton setState:NO];
    [polymatrix selectCellAtRow:0 column:0];
    [[syssepmatrix cellAtRow:0 column:0] setState:NO];
    [[syssepmatrix cellAtRow:1 column:0] setState:NO];
    [self setStaffButton: nil];
    [self constructPartList];
    selectPopNameFor(partbutton, partbutton, nullPart);
  }
  else
  {
    [nstavestext setSelectable:NO];
    [newsysbutton setEnabled:NO];
    [self setStaffButton: sys];
    [self constructPartList];
    [self inspSys: sys];
    [self inspStaff: sys : [self assayStaves: sys]];
  }
  [self changeBox: self];
  [self changeStaffView: self];
  return self;
}


- revert: sender
{
  System *sys = [[DrawApp sharedApplicationController] currentSystem];
    [self loadDataFor: sys : [mainPopup indexOfSelectedItem]];
  if ([revertButton isEnabled]) [revertButton setEnabled:NO];
  if ([setButton isEnabled]) [setButton setEnabled:NO];
  return self;
}


/* part extraction */

- hitExtract: sender
{
  int i, k = 0, n;
  char wantstaff[NUMSTAVES];
  GraphicView *v = [DrawApp currentView];
  if (![v sysSameShape])
  {
    NSRunAlertPanel(@"Extraction", @"Systems not same size", @"OK", nil, nil, NULL);
    return self;
  }
  busyFlag = YES;
  n = [[staffmatrix cells] count];
  for (i = 0; i < n; i++)
  {
    wantstaff[i] = 0;
    if ([[staffmatrix cellAtRow:i column:0] isHighlighted])
    {
      wantstaff[i] =  1;
      ++k;
    }
  }
  [v extractStaves: k : wantstaff];
  busyFlag = NO;
  return self;
}

/*
  re order staves */

- hitOrder: sender
{
  int a, i, n;
  System *sys = [[DrawApp sharedApplicationController] currentSystem];
  char order[NUMSTAVES];
  GraphicView *v = [DrawApp currentView];
  a = NSRunAlertPanel(@"Order Staves", @"Which systems to modify?", @"Current", @"All", @"Cancel");
  if (a == NSAlertOtherReturn) return self;
  busyFlag = YES;
  n = [[staffmatrix cells] count];
  for (i = 0; i < n; i++) order[i] = atoi([[[staffmatrix cellAtRow:i column:0] title] cString]) - 1;
  if (a == NSAlertAlternateReturn)
  {
    if (![v sysSameShape])
    {
      NSRunAlertPanel(@"Order Staves", @"All systems do not have the same format", @"OK", nil, nil, NULL);
      return self;
    }
    [v orderAllStaves: order];
  }
  else if (a == NSAlertDefaultReturn)
  {
    [v orderCurrStaves: sys : order];
  }
  [self setStaffButton: sys];
  busyFlag = NO;
  return self;
}



/* specific to Style View */


- hitBrowser: sender
{
  int i = [[stybrowser matrixInColumn: 0] selectedRow];
  return [self styleButtons: [[[DrawApp sharedApplicationController] getStylelist] styleNameForInt: i]];
}


- (System *) newEntry: (NSString *) n
{
  System *p, *sys;
  NSMutableArray *sl = [[DrawApp sharedApplicationController] getStylelist];
  int k = [sl count];
  while (k--)
  {
    p = [sl objectAtIndex:k];
      if ([n isEqualToString: p->style])
    {
      NSRunAlertPanel(@"System Style", @"Style name already in use", @"OK", nil, nil);
      return nil;
    }
  }
  sys = [[DrawApp sharedApplicationController] currentSystem];
  if (sys == nil)
  {
    NSRunAlertPanel(@"System Style", @"No current system", @"OK", nil, nil);
    return nil;
  }
  p = [[System alloc] initWithStaveCount: [sys numberOfStaves] onGraphicView: sys->view];
  [sys copyStyleTo: p];
  p->style =[[n copy] retain];
  [sl addObject: p];
  return p;
}



- hitNewstyle: sender
{
  NSString *s = [stytext stringValue];
  if (!s) s = @"NewStyle";
  else if (![s length]) s = @"NewStyle";

  if ([self newEntry: s] != nil)
  {
    [[[DrawApp sharedApplicationController] getStylelist] sortStylelist];
    [stybrowser loadColumnZero];
    [stybrowser setPath:s];
    [self styleButtons: s];
    [(GraphicView *)[DrawApp currentView] dirty];
  }
  return self;
}


- hitDefstyle: sender
{
  int i;
    NSString *buf;
    System *st, *sys = [[DrawApp sharedApplicationController] currentSystem];
  if (sys == nil)
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  i = [[stybrowser matrixInColumn: 0] selectedRow];
  if (i < 0 || i >= [[[DrawApp sharedApplicationController] getStylelist] count])
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  st = [[[DrawApp sharedApplicationController] getStylelist] objectAtIndex:i];
  if (st == nil)
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  if ([sys numberOfStaves] != [st numberOfStaves])
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  if (![sys->style isEqualToString: st->style])
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  buf = [NSString stringWithFormat:@"Are you sure you want to modify style '%@'?", st->style];
  if (NSRunAlertPanel(@"Calliope", buf, @"YES", @"NO", nil) != NSAlertDefaultReturn) return self;
  [sys copyStyleTo: st];
  busyFlag = YES;
  [(GraphicView *)[DrawApp currentView] flushStyle: st];
  busyFlag = NO;
  [(GraphicView *)[DrawApp currentView] dirty];
  return self;
}


- hitRenstyle: sender
{
    NSString *buf;
    System *st, *p;
  NSString *a;
  NSString *n;
  NSMutableArray *sl = [[DrawApp sharedApplicationController] getStylelist];
  int i, k;
  i = [[stybrowser matrixInColumn: 0] selectedRow];
  if (i < 0 || i >= [sl count])
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  st = [sl objectAtIndex:i];
  if (st == nil)
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  n = [stytext stringValue];
  if (![st->style isEqualToString: n])
  {
      buf = [NSString stringWithFormat:@"Do you want to rename style '%@' to '%@'?", st->style, n];
    if (NSRunAlertPanel(@"Calliope", buf, @"YES", @"NO", nil) != NSAlertDefaultReturn) return self;
    k = [sl count];
    while (k--)
    {
      p = [sl objectAtIndex:k];
        if ([n isEqualToString: p->style])
      {
        NSRunAlertPanel(@"System Style", @"Style name already in use", @"OK", nil, nil);
        return nil;
      }
    }
    a = n;
    [(GraphicView *)[DrawApp currentView] renameStyle: st->style : [a retain]];
    [st->style autorelease];
    st->style = [a retain];
    [[[DrawApp sharedApplicationController] getStylelist] sortStylelist];
    [stybrowser loadColumnZero];
    [stybrowser setPath:[a retain]];
    [self styleButtons: nil];
  }
  [(GraphicView *)[DrawApp currentView] dirty];
  return self;
}


- hitFinstyle: sender
{
  System *st;
  int i;
  GraphicView *v = [DrawApp currentView];
  if (v == nil)
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  i = [[stybrowser matrixInColumn: 0] selectedRow];
  if (i < 0 || i >= [[[DrawApp sharedApplicationController] getStylelist] count])
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  st = [[[DrawApp sharedApplicationController] getStylelist] objectAtIndex:i];
  if (st == nil)
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  busyFlag = YES;
  [v findSysOfStyle: st->style];
  busyFlag = NO;
  [self inspSys: [v currentSystem]];
  return self;
}


- hitConstyle: sender
{
  int i;
  float ss, lm;
  GraphicView *v = [DrawApp currentView];
  System *st, *sys = [v currentSystem];
  
  if (sys == nil)
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  i = [[stybrowser matrixInColumn: 0] selectedRow];
  if (i < 0 || i >= [[[DrawApp sharedApplicationController] getStylelist] count])
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  st = [[[DrawApp sharedApplicationController] getStylelist] objectAtIndex:i];
  if (st == nil)
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  if ([sys numberOfStaves] != [st numberOfStaves])
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  busyFlag = YES;
  if (sys->lindent != st->lindent)
  {
    ss = [[DrawApp currentDocument] staffScale];
    lm = [sys leftMargin];
    [sys shuffleNotes: lm + (sys->lindent / ss) : lm + (st->lindent / ss)];
  }
  [st copyStyleTo: sys];
  [sys recalc];
  [v paginate: self];
  busyFlag = NO;
  [self inspSys: sys];  /* do because paginate etc may have updated some sys values */
  [v dirty];
  return self;
}


- hitDelstyle: sender
{
  int i;
    NSString *buf;
    i = [[stybrowser matrixInColumn: 0] selectedRow];
  if (i < 0)
  {
    NSLog(@"Assertion failure in SysInspector");
    return self;
  }
  buf = [NSString stringWithFormat:@"Are you sure you want to delete style '%@'?",
      [[[DrawApp sharedApplicationController] getStylelist] styleNameForInt: i]];
  if (NSRunAlertPanel(@"Calliope", buf, @"YES", @"NO", nil) != NSAlertDefaultReturn)
      return self;
  [[[DrawApp sharedApplicationController] getStylelist] removeObjectAtIndex:i];
  [stybrowser loadColumnZero];
  [stybrowser setPath:@""];
  [self styleButtons: @""];
  [(GraphicView *)[DrawApp currentView] dirty];
  return self;
}


/* text delegate */

- (void)controlTextDidChange:(NSNotification *)notification
{
    NSText *theText = [[notification userInfo] objectForKey:@"NSFieldEditor"];
    NSLog(@"didchange\n");
    if (stytext == [theText superview])
      {
        [self styleButtons: nil];
      }
    else
      {
        [self dataChanged: [theText superview]];
      }
}


/* NXBrowser delegates */

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)col
{
  return [[[DrawApp sharedApplicationController] getStylelist] count];
}


- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)col
{
  if (col != 0) return;
  [cell setStringValue:[[[DrawApp sharedApplicationController] getStylelist] styleNameForInt: row]];
  [cell setLeaf:YES];
  [cell setEnabled:YES];
}



@end
