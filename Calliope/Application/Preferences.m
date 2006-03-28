
#import "Preferences.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GVCommands.h"
#import "PrefBlock.h"
#import "MultiView.h"
#import "mux.h"
#import "muxlow.h"
#import <AppKit/AppKit.h>


@implementation Preferences

extern NSSize paperSize;

PrefBlock *currblock;  /* storing state of some components */

static float shmm[8] =		/* staff height in mm given rastral number  */
{
  8.0, 7.5, 7.0, 6.5, 6.0, 5.5, 5.0, 4.5
};


/*
  Box codes:
    0 barlines
    1 tablature
    2 figures
    3 shared prefblock pathname
    4 text underlay
    5 rastral size
    6 layout options
    7 style sheet
    8 runner font
*/


+ (void)initialize
{
  if (self == [Preferences class])
  {
    currblock = [[PrefBlock alloc] init];
  }
  return;
}


- hitCalc: sender
{
  float h, r, conv;
  r = [heightreal floatValue];
  conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//  [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
  h = [rasheightcell floatValue] / conv; 
  if (r < 1 || h < 1)
  {
    [heightrelative setStringValue:@""];
    return self;
  }
  [heightrelative setFloatValue:r * 32.0 / h];
  return self;
}


- setRastralNumber: (float) f
{
  int i;
  float df;
  for (i = 0; i < 8; i++)
  {
    df = f - shmm[i];
    if (df < 0) df = -df;
    if (df < 0.01) {[rasnummatrix selectCellAtRow:0 column:i]; return rasnummatrix;}
  }
  clearMatrix(rasnummatrix);
  return self;
}


- setView: (int) i
{
  if (![[DrawApp sharedApplicationController] currentSystem])
  {
    [multiview replaceView: nodocview];
    return self;
  }
  switch(i)
  {
    case 0:
      [multiview replaceView: barview];
      break;
    case 1:
      [multiview replaceView: tabview];
      break;
    case 2:
      [multiview replaceView: figview];
      break;
    case 3:
      [multiview replaceView: pathview];
      break;
    case 4:
      [multiview replaceView: textview];
      break;
    case 5:
      [multiview replaceView: heightview];
      break;
    case 6:
      [multiview replaceView: layoutview];
      break;
    case 7:
      [multiview replaceView: styleview];
      break;
    case 8:
      [multiview replaceView: runview];
      break;
  }
  return self;
}

static void setFieldName(NSFont *fnt, id fld)
{
    [fld setStringValue:[NSString stringWithFormat:@"%.1f pt %@",[fnt pointSize],[fnt fontName]]];
}



- setPanel: (int) i : (PrefBlock *) p
{
  float conv;
  if (p == nil) return self;
  switch(i)
  {
    case 0:
      [barplacematrix selectCellAtRow:0 column:p->barplace];
      [barsurrmatrix selectCellAtRow:0 column:p->barsurround];
      [[barshowmatrix cellAtRow:0 column:0] setState:p->barnumfirst];
      [[barshowmatrix cellAtRow:1 column:0] setState:p->barnumlast];
      [bareveryfield setIntValue:p->barevery];
      setFieldName(p->barfont, barfontfield);
      currblock->barfont = p->barfont;
      break;
    case 1:
      [tabcromatrix selectCellAtRow:0 column:p->tabflag];
      setFieldName(p->tabfont, tabfontfield);
      currblock->tabfont = p->tabfont;
      break;
    case 2:
      setFieldName(p->figfont, figfontfield);
      currblock->figfont = p->figfont;
      break;
    case 3:
        [pathfield setStringValue:p->pathname ? p->pathname : @""];
      break;
    case 4:
      setFieldName(p->texfont, texfontfield);
      currblock->texfont = p->texfont;
      break;
    case 5:
        conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//      [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
      [rasheightcell setFloatValue:p->staffheight * conv];
        [self setRastralNumber: p->staffheight / PTPMM];
//sb: FIXME. I don't know what to do with the following, as I don't use doc-based units any more.
        currblock->unitflag = [[DrawApp sharedApplicationController] unitNum];
      [rasunits setStringValue:[[DrawApp sharedApplicationController] unitString]];
      break;
    case 6:
      [[layoutform cellAtIndex:0] setFloatValue:p->minsysgap];
      [[layoutform cellAtIndex:1] setFloatValue:p->maxbalgap];
      break;
    case 7:
        [styletext setStringValue:p->stylepath ? p->stylepath : @""];
      if (p->stylepath == nil)
      {
          [stylebutton setState:NO];
          [stylebutton setEnabled:NO];
      }
          else if ([p->stylepath length])
            {
              [stylebutton setState:p->usestyle];
              [stylebutton setEnabled:YES];
            }
          else
            {
              [stylebutton setState:NO];
              [stylebutton setEnabled:NO];
            }
      break;
    case 8:
      setFieldName(p->runfont, runfontfield);
      currblock->runfont = p->runfont;
      break;
  }
  return self;
}


- (void)awakeFromNib
{
    [mainPopup selectItemAtIndex: 0];
    [self setView: 0];
}


/* set a block from the panel controls */

- setPrefBlock: (int) i : (PrefBlock *) p
{
  NSString *s;
  float conv;
  switch(i)
  {
    case 0: 
      p->barplace = [barplacematrix selectedColumn];
      p->barsurround = [barsurrmatrix selectedColumn];
      p->barnumfirst = [[barshowmatrix cellAtRow:0 column:0] state];
      p->barnumlast = [[barshowmatrix cellAtRow:1 column:0] state];
      p->barfont = currblock->barfont;
      p->barevery = [bareveryfield intValue];
      break;
    case 1: 
      p->tabflag = [tabcromatrix selectedColumn];
      p->tabfont = currblock->tabfont;
      break;
    case 2: 
      p->figfont = currblock->figfont;
      break;
    case 3: 
      if (p->pathname) [p->pathname release];
      s = [pathfield stringValue];
        if (!s) p->pathname = nil;
        else if (![s length]) p->pathname = nil;
        else p->pathname = [[s copy] retain];
      break;
    case 4: 
      p->texfont = currblock->texfont;
      break;
    case 5:
        conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//      [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
      p->staffheight = [rasheightcell floatValue] / conv;
      p->unitflag = currblock->unitflag;
      break;
    case 6:
      p->minsysgap = [[layoutform cellAtIndex:0] floatValue];
      p->maxbalgap = [[layoutform cellAtIndex:1] floatValue];
      break;
    case 7:
      if (p->stylepath) [p->stylepath release];
      s = [styletext stringValue];
      if (s == nil)
        {
          p->stylepath = nil;
          p->usestyle = 0;
        }
          else if (![s length])
            {
              p->stylepath = nil;
              p->usestyle = 0;
            }
          else
      {
         p->stylepath = [[s copy] retain];
	 p->usestyle = [stylebutton state];
      }
      break;
    case 8: 
      p->runfont = currblock->runfont;
      break;
  }
  return self;
}


- (BOOL) panelValid: (int) i
{
  float conv, f;
  BOOL r = YES;
  switch(i)
  {
    case 5:
        conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//      [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
      f = [rasheightcell floatValue] / conv;
      r = (f > 8 && f < 288);
      break;
    case 6:
      f = [[layoutform cellAtIndex:0] floatValue];
      r = (f > 0 && f < 288);
      f = [[layoutform cellAtIndex:1] floatValue];
      r &= (f > 0 && f < 288);
      break;
  }
  return r;
}


- dataChanged: sender
{
  float conv;
  BOOL change = NO;
  PrefBlock *p = [[DrawApp currentDocument] prefInfo];
  switch([mainPopup indexOfSelectedItem])
  {
    case 0:
      if (!change) change = ([barplacematrix selectedColumn] != p->barplace);
      if (!change) change = ([barsurrmatrix selectedColumn] != p->barsurround);
      if (!change) change = ([[barshowmatrix cellAtRow:0 column:0] state] != p->barnumfirst);
      if (!change) change = ([[barshowmatrix cellAtRow:1 column:0] state] != p->barnumlast);
      if (!change) change = (currblock->barfont != p->barfont);
      if (!change) change = ([bareveryfield intValue] != p->barevery);
      break;
    case 1:
      if (!change) change = ([tabcromatrix selectedColumn] != p->tabflag);
      if (!change) change = (currblock->tabfont != p->tabfont);
      break;
    case 2: 
      if (!change) change = (currblock->figfont != p->figfont);
      break;
    case 3: 
      if (!change) change = (![[pathfield stringValue] isEqualToString:p->pathname]);
      break;
    case 4: 
      if (!change) change = (currblock->texfont != p->texfont);
      break;
    case 5:
        conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//      [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
      if (!change) change = (([rasheightcell floatValue] / conv) != p->staffheight);
      if (!change) change = (currblock->unitflag != p->unitflag);
      break;
    case 6:
      if (!change) change = ([[layoutform cellAtIndex:0] floatValue] != p->minsysgap);
      if (!change) change = ([[layoutform cellAtIndex:1] floatValue] != p->maxbalgap);
      break;
    case 7:
        if (!change) change = (![[styletext stringValue] isEqualToString:p->stylepath]);
      if (!change) change = ([stylebutton state] != p->usestyle);
      break;
    case 8: 
      if (!change) change = (currblock->runfont != p->runfont);
      break;
  }
  if (change)
  {
    if (![revertButton isEnabled]) [revertButton setEnabled:YES];
    if (![setButton isEnabled]) [setButton setEnabled:YES];
  }
  else
  {
    if ([revertButton isEnabled]) [revertButton setEnabled:NO];
    if ([setButton isEnabled]) [setButton setEnabled:NO];
  }
  [self setDocumentEdited:change];
  return self;
}


- hitChoice: sender
{
    int i = [mainPopup indexOfSelectedItem];
  [self setPanel: i : [[DrawApp currentDocument] prefInfo]];
  [self setView: i];
  return self;
}


- changeRastral: sender
{
  float conv, f;
    conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//  [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
  f = shmm[ [sender selectedColumn] ] * 2.834646;
  [rasheightcell setFloatValue:f * conv];
  currblock->unitflag = [[DrawApp sharedApplicationController] unitNum];
  [rasunits setStringValue:[[DrawApp sharedApplicationController] unitString]];
  [self hitCalc: self];
  if (![revertButton isEnabled]) [revertButton setEnabled:YES];
  if (![setButton isEnabled]) [setButton setEnabled:YES];
  [self setDocumentEdited:YES];
  return self;
}


- hitHeight: sender
{
    float conv;
    conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//  [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
    [self setRastralNumber: ([rasheightcell floatValue] / conv) / PTPMM];
    [self hitCalc: self];
    [self set: sender];
    return self;
}


- (void)changeFont:(id)sender
{
    NSFont *f = [[NSFontManager sharedFontManager] convertFont:[[NSFontManager sharedFontManager] selectedFont]];

    switch([mainPopup indexOfSelectedItem])
  {
    case 0:
      setFieldName(f, barfontfield);
      currblock->barfont = f;
      break;
    case 1:
      setFieldName(f, tabfontfield);
      currblock->tabfont = f;
      break;
    case 2:
      setFieldName(f, figfontfield);
      currblock->figfont = f;
      break;
    case 4:
      setFieldName(f, texfontfield);
      currblock->texfont = f;
      break;
    case 8:
      setFieldName(f, runfontfield);
      currblock->runfont = f;
      break;
  }
  if (![revertButton isEnabled]) [revertButton setEnabled:YES];
  if (![setButton isEnabled]) [setButton setEnabled:YES];
  [self setDocumentEdited:YES];
}


- setPrefFont: sender
{
NSFontManager *fm = [NSFontManager sharedFontManager];
    switch([mainPopup indexOfSelectedItem])
  {
    case 0:
        [fm setSelectedFont:currblock->barfont isMultiple:NO];
      break;
    case 1:
        [fm setSelectedFont:currblock->tabfont isMultiple:NO];
      break;
    case 2:
        [fm setSelectedFont:currblock->figfont isMultiple:NO];
      break;
    case 4:
        [fm setSelectedFont:currblock->texfont isMultiple:NO];
      break;
    case 8:
        [fm setSelectedFont:currblock->runfont isMultiple:NO];
      break;
  }
  [fm orderFrontFontPanel:self];
  return self;
}


- setPrefInfo: (int) i : (PrefBlock *) p
{
  if (!p) return nil;
  [self setPrefBlock: i : p];
  if ([revertButton isEnabled]) [revertButton setEnabled:NO];
  if ([setButton isEnabled]) [setButton setEnabled:NO];
  [self setDocumentEdited:NO];
  return self;
}


/*
  Sets, then takes account of the setting.
*/

- set:sender
{
  OpusDocument *d = [DrawApp currentDocument];
  GraphicView *v = [d graphicView];
  PrefBlock *p = [d prefInfo];
  float oss, nss, w, h;
  NSSize pr;
  int i;
  if (!p)
  {
    NSLog(@"Preferences -set: p == nil");
    return self;
  }
  oss = [d staffScale];
  i = [mainPopup indexOfSelectedItem];
  if (![self panelValid: i])
  {
    NSLog(@"Preferences -set: panel not valid");
    return self;
  }
  [self setPrefInfo: i : p];
  switch(i)
  {
    default:
      [d resetScrollers];
      break;
    case 5:
      nss = [d staffScale];
      pr = [d paperSize];
      w = pr.width / nss;
      h = pr.height / nss;
      [v setBoundsSize:NSMakeSize(w, h)];
      [d resetScrollers];
      [v shuffleAllMarginsByScale: oss : nss];
      [v recalcAllSys];
      [v paginate: d];
      break;
  }
  [v setNeedsDisplay:YES];
  [v dirty];
  return self;
}


- preset
{
  int i;
  OpusDocument *d = [DrawApp currentDocument];
  PrefBlock *p = [d prefInfo];
  if (!p)
  {
    p = [[PrefBlock alloc] init];
    [d installPrefInfo: p];
  }
  i = [mainPopup indexOfSelectedItem];
  [self setPanel : i : p];
  [self setView: i];
  return self;
}


- reflectSelection
{
  int i;
  OpusDocument *d = [DrawApp currentDocument];
  PrefBlock *p = [d prefInfo];
  if (p)
  {
      i = [mainPopup indexOfSelectedItem];
    [self setPanel : i : p];
    [self setView: i];
  }
  return self;
}


/* file handling for shared style sheets */

- (BOOL) getStyleFromFile: (NSString *) fn : (GraphicView *) v
{
  int version;
  BOOL ok = YES;
  NSData *s;
  NSArchiver *volatile ts;
  if (!fn) return NO;
  if ([fn isEqualToString:@""]) return NO;
  if (v == nil) return NO;
//  s = NXMapFile(fn, NX_READONLY);
  s = [NSData dataWithContentsOfMappedFile:fn];
  ts = nil;
  if (s)
  {
   
    NS_DURING
      ts = [[NSUnarchiver alloc] initForReadingWithData:s];
      [ts decodeValueOfObjCType:"i" at:&version];
      if (version == STYLE_VERSION)
      {
        if (v->stylelist) free(v->stylelist);
	[ts decodeValueOfObjCType:"@" at:&(v->stylelist)];
      }
      else ok = NO;
    NS_HANDLER
      ok = NO;
    NS_ENDHANDLER
    if (ts) [ts release];
  }
  if (ok)
  {
//    NXClose(s);
  }
  else
  {
//    if (s) NXClose(s);
  }
  return ok;
}


/* write style data */

BOOL writeStyleFile(NSString *f)
{
  int version;
  NSArchiver *ts;
  OpusDocument *doc;
  GraphicView *v;
  if (![f length]) return NO;
  doc = [DrawApp currentDocument];
  if (doc == nil) return NO;
  v = [doc graphicView];
  if (v == nil) return NO;
  ts = [[NSArchiver alloc] initForWritingWithMutableData:[NSMutableData data]];
  if (ts)
  {
    version = STYLE_VERSION;
    [ts encodeValueOfObjCType:"i" at:&version];
    [ts encodeRootObject:v->stylelist];
    [[ts archiverData] writeToFile:f atomically:YES];
    [ts release];
    return YES;
  }
  return NO;
}



- openStyle: sender
{
  NSString *file=nil;
  NSArray *ext = [NSArray arrayWithObject:@"callstyle"];
  id openpanel;
  PrefBlock *p = [[DrawApp currentDocument] prefInfo];
  if (p == nil)
  {
    NSRunAlertPanel(@"Preferences", @"No Document is Open", @"OK", nil, nil);
    return self;
  }
  openpanel = [NSOpenPanel openPanel];
  [openpanel setAllowsMultipleSelection:NO];
  if ([openpanel runModalForTypes:ext] == NSOKButton)
  {
    file = [openpanel filename];
    if (file)
    {
      [styletext setStringValue:file];
      [stylebutton setEnabled:YES];
      [self setPrefInfo: 7 : p];
      if (![setButton isEnabled]) [setButton setEnabled:YES];
    }
  }
  if (![self getStyleFromFile:file  : [DrawApp currentView]])
  {
    NSRunAlertPanel(@"Preferences", @"Cannot Open Style Sheet", @"OK", nil, nil);
  }
  else
  {
    [[DrawApp currentView] dirty];
  }
  return self;
}


- saveStyle: sender
{
  id savepanel;
  NSString *fn;
  PrefBlock *p = [[DrawApp currentDocument] prefInfo];
  int i=0;
  if (p == nil)
  {
    NSRunAlertPanel(@"Preferences", @"No Document is Open", @"OK", nil, nil);
    return self;
  }
  fn = p->stylepath;
  if (fn == nil) i = 1;
    else if (![fn length]) i = 1;
    if (i)
  {
    savepanel = [[DrawApp sharedApplicationController] savePanel: @"callstyle"];
    if (![savepanel runModal]) return self;
    fn = [savepanel filename];
    [styletext setStringValue:fn];
    [stylebutton setEnabled:YES];
    [self setPrefInfo: 7 : p];
    if (![setButton isEnabled]) [setButton setEnabled:YES];
  }
  if (!writeStyleFile(fn))
  {
    NSRunAlertPanel(@"Preferences", @"Cannot Save Style Sheet", @"OK", nil, nil);
  }
  else
  {
    [[DrawApp currentView] dirty];
  }
  return self;
}


/*
 * File handling for shared prefblocks.
 */


/* target of the 'OPEN' button */

- open: sender
{
    NSString *file;
    PrefBlock *p;
//  static const char *const ext[2] = {"callpref", NULL};
    NSArray *ext = [NSArray arrayWithObject:@"callpref"];
  id openpanel = [NSOpenPanel openPanel]; [openpanel setAllowsMultipleSelection:NO];
  if ([openpanel runModalForTypes:ext] == NSOKButton)
  {
    file = [openpanel filename];
    if (file)
    {
        p = [PrefBlock readFromFile: file];
      if (!p)
      {
        NSRunAlertPanel(@"Preferences", @"Cannot Open.", @"OK", nil, nil);
      }
      else
      {
          [self setPanel: [mainPopup indexOfSelectedItem] : p];
	[[DrawApp currentDocument] installPrefInfo: p];
      }
    }
  }
  return self;
}


/* target of SAVE button (fake a SET first in case user forgot) */

- save: sender
{
  id savepanel;
  NSString *fn;
  PrefBlock *p = [[DrawApp currentDocument] prefInfo];
  int i=0;
  if (p == nil)
  {
    NSRunAlertPanel(@"Preferences", @"No Document is Open", @"OK", nil, nil);
    return self;
  }
  if (!(p->pathname)) i = 1;
    else if (![p->pathname length]) i = 1;

    if (i)
  {
    savepanel = [[DrawApp sharedApplicationController] savePanel: @"callpref"];
    if (![savepanel runModal]) return self;
    fn = [savepanel filename];
    [pathfield setStringValue:fn];
    [self setPrefInfo: [mainPopup indexOfSelectedItem] : p];
  }
  if (![p backup])
  {
    NSRunAlertPanel(@"Preferences", @"Cannot Save.", @"OK", nil, nil);
  }
  return self;
}


/* target of REVERT button */

- revert: sender
{
  PrefBlock *q, *p = [[DrawApp currentDocument] prefInfo];
    int i = 0;
    if ([mainPopup indexOfSelectedItem] < 3)
  {
    *currblock = *p;
        [self setPanel: [mainPopup indexOfSelectedItem] : p];
    if ([revertButton isEnabled]) [revertButton setEnabled:NO];
    if ([setButton isEnabled]) [setButton setEnabled:NO];
    [self setDocumentEdited:NO];
    return self;
  }
  if (p == nil)
  {
    NSRunAlertPanel(@"Preferences", @"No document is open.", @"OK", nil, nil);
    return self;
  }
  if (!(p->pathname)) i = 1;
    else if (![p->pathname length]) i=1;
    if (i)
  {
    NSRunAlertPanel(@"Preferences", @"No file from which to revert", @"OK", nil, nil);
    return self;
  }
  q = [p revert];
  if (!q) NSRunAlertPanel(@"Preferences", @"I/O error.  Cannot Revert.", @"OK", nil, nil);
  else
  {
      [self setPanel: [mainPopup indexOfSelectedItem] : q];
    [[DrawApp currentDocument] installPrefInfo: q];
  }
  return self;
}


/* text delegate */

- (void)controlTextDidChange:(NSNotification *)notification
{
    NSText *theText = [[notification userInfo] objectForKey:@"NSFieldEditor"];
    float conv;
    if ([theText superview] == rasheightcell)
    {
        conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//        [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
        [self setRastralNumber: ([rasheightcell floatValue] / conv) / PTPMM];
    }
    else [self dataChanged: [theText superview]];
}



@end

