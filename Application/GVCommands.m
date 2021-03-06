/* $Id$ */
#import <AppKit/AppKit.h>
#import "Graphic.h"
#import "GraphicView.h"
#import "GVCommands.h"
#import "GVSelection.h"
#import "GVFormat.h"
#import "GVPasteboard.h"
#import "GVSelection.h"
#import "OpusDocument.h"
#import "SysCommands.h"
#import "StaffObj.h"
#import "Staff.h"
#import "CallPart.h"
#import "CallInst.h"
#import "Runner.h"
#import "ChordGroup.h"
#import "Bracket.h"
#import "TimedObj.h"
#import "GNote.h"
#import "NoteHead.h"
#import "Margin.h"
#import "Tie.h"
#import "TieNew.h"
#import "KeySig.h"
#import "Neume.h"
#import "NeumeNew.h"
#import "NoteGroup.h"
#import "Ligature.h"
#import "CalliopeAppController.h"
#import "TextGraphic.h"
#import "Page.h"
#import "Tablature.h"
#import "SysInspector.h"
#import "SysAdjust.h"
#import "SysCommands.h"
#import "PageScrollView.h"
#import "Rest.h"
#import "Range.h"
#import "Verse.h"
#import "TimeSig.h"
#import "Barline.h"
#import "Enclosure.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "ProgressDisplay.h"

@implementation GraphicView(GVCommands)

#define MINIMTICK 64
//#define VOICEID(v, s) (v ? NUMSTAVES + v : s)

int staffFlag;
BOOL cvFlag;	/* whether in copyverse mode */
NSMutableArray *cvList;		/* stores list for copyverse */
int fontflag;		/* which kind of font change */

extern int noteFromTicks(float t);
extern int dotsFromTicks(float t, int i);

static NSString *partscratchpad[NUMSTAVES];
static NSString *stylescratch;



- hideMargins: sender
{
    showMargins = NO;
    [self setNeedsDisplay: YES];
    return self;
}

- (BOOL) showMargins
{
    return showMargins;
}

- labelObjs: (int) t
{
  StaffObj *p;
  TextGraphic *tx;
  NSMutableArray *slc;
  BOOL b = NO;
  int k = [slist count];
  if (k > 0)
  {
    slc = [slist copy];
    [self deselectAll: self];
    while (k--)
    {
      p = [slc objectAtIndex:k];
      if (HASAVOICE(p))
      {
        b = YES;
        tx = [p makeName: t];
        if (tx != nil)
        {
          [tx recalc];
	  [self selectObj: tx];
        }
      }
    }
    [slc autorelease];
  }
  if (b)
  {
//      [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    [self drawSelectionWith: NULL];
  }
  return self;
}


- labelPN: sender
{
  return [self labelObjs: 0];
}


- labelPA: sender
{
  return [self labelObjs: 1];
}


- labelIN: sender
{
  return [self labelObjs: 2];
}


- labelIA: sender
{
  return [self labelObjs: 3];
}


- makePartNames: sender
{
  if (currentSystem)
  {
    [currentSystem makeNames: YES : self];
    [self drawSelectionWith: NULL];
  }
  return self;
}


- makePartAbbrevs: sender
{
  if (currentSystem)
  {
    [currentSystem makeNames: NO : self];
    [self drawSelectionWith: NULL];
  }
  return self;
}


- renameStyle: (NSString *) s : (NSString *) t
{
  System *sys;
  int k = [syslist count];
  while (k--)
  {
    sys = [syslist objectAtIndex:k];
      if ([sys->style isEqualToString: s]) sys->style = t;
  }
  return self;
}

- copyStyle: sender
{
  stylescratch = currentSystem->style;
  return self;
}


- pasteStyle: sender
{
  float ss, lm;
  System *sys = [[[CalliopeAppController sharedApplicationController] getStylelist] styleSysForName: stylescratch];
  if (sys == nil)
  {
    NSLog(@"Assertion failure in GVCommands");
    return self;
  }
  if ([sys numberOfStaves] != [currentSystem numberOfStaves])
  {
    NSLog(@"Assertion failure in GVCommands");
    return self;
  }
  if (sys->lindent != currentSystem->lindent)
  {
    ss = [self staffScale];
    lm = [currentSystem leftMargin];
    [currentSystem shuffleNotes: lm + (currentSystem->lindent / ss) : lm + (sys->lindent / ss)];
  }
  [sys copyStyleTo: currentSystem];
  [currentSystem recalc];
  [self paginate: self];
  [[CalliopeAppController sharedApplicationController] inspectClass: [SysInspector class] loadInspector: NO];
  [self dirty];
  return self;
}


/* flush style through document */

- flushStyle: (System *) st
{
  System *sys;
  BOOL b = NO;
  float ss, lm;
  NSString * n = st->style;
  int k = [syslist count];
  while (k--)
  {
    sys = [syslist objectAtIndex:k];
      if ([sys->style isEqualToString: n])
    {
      b = YES;
      if (sys->lindent != st->lindent)
      {
        ss = [self staffScale];
        lm = [sys leftMargin];
        [sys shuffleNotes: lm + (sys->lindent / ss) : lm + (st->lindent / ss)];
      }
      [st copyStyleTo: sys];
      [sys recalc];
    }
  }
  if (b)
  {
    [self paginate: self];
    [self dirty];
  }
  return self;
}


- clearNumbering: sender
{
  int i, j, k;
  System *sys = [[CalliopeAppController sharedApplicationController] currentSystem];
  j = [syslist indexOfObject:sys];
  k = [syslist count];
  for (i = j; i < k; i++)
  {
    sys = [syslist objectAtIndex:i];
      [sys setPageNumber: 0];
      sys->barnum = 0;
      sys->flags.newbar = 0;
      sys->flags.newpage = 0;
  }
  return [self renumber: self];
}


- delPageFormats: sender
{
  Graphic *p;
  int i, j, k, ok;
  NSMutableArray *ol;
  System *sys = [[CalliopeAppController sharedApplicationController] currentSystem];
  j = [syslist indexOfObject:sys];
  if (j == 0)
  {
    NSLog(@"Assertion failure in GVCommands");
    return self;
  }
  k = [syslist count];
  for (i = j; i < k; i++)
  {
    sys = [syslist objectAtIndex:i];
    ol = sys->nonStaffGraphics;
    ok = [ol count];
    while (ok--)
    {
      p = [ol objectAtIndex:ok];
      if ([p graphicType] == MARGIN) [ol removeObjectAtIndex:ok];
    }
  }
  return [self paginate: self];
}


/*sb: I am not worrying about retaining the parts as they are copied. They are retained if they are moved
 * from here into another part list
 */
- copyPartsFrom: (System *) sys
{
    int i;
    int ns = [sys numberOfStaves];
    
    for (i = 0; i < NUMSTAVES; i++) 
	partscratchpad[i] = 0;
    for (i = 0; i < ns; i++) {
	Staff *sp = [sys getStaff: i];
	
	partscratchpad[i] = [sp partName];
    }
    return self;
}


- pastePartsTo: (System *) sys
{
    int s;
    int ns = [sys numberOfStaves];
    
    for (s = 0; s < ns; s++) {
	Staff *sp = [sys getStaff: s];
	
	[sp setPartName: partscratchpad[s]];
	[sp defaultNoteParts];
    }
    return self;
}


- copyParts: sender
{
  return [self copyPartsFrom: [[CalliopeAppController sharedApplicationController] currentSystem]];
}


- pasteParts: sender
{
  return [self pastePartsTo: [[CalliopeAppController sharedApplicationController] currentSystem]];
}


/* flush parts through document */

- flushParts: sender
{
  int i, j, k;
  System *sys = [[CalliopeAppController sharedApplicationController] currentSystem];
  [self copyParts: self];
  j = [syslist indexOfObject:sys];
  k = [syslist count];
  for (i = j; i < k; i++) [self pastePartsTo: [syslist objectAtIndex:i]];
  return self;
}


/* set single-bar rests to agree with time signature */

- retimeRests: sender
{
  int nsys, ns, i, j, k, n, v, t, c, bart[NUMSTAVES];
  int numrests[NUMVOICES], numvox[NUMVOICES];
  System *sys;
  Staff *sp;
  TimedObj *p;
  Rest *r;//sb: these were originally Rest, but I made them superclass
  Rest *rests[NUMVOICES]; //sb: these were originally Rest, but I made them superclass
  NSMutableArray *nl;
  nsys = [syslist count];
  for (i = 0; i < NUMSTAVES; i++) bart[i] = MINIMTICK * 2;
  for (i = 0; i < nsys; i++)
  {
    for (v = 0; v < NUMVOICES; v++) numrests[v] = numvox[v] = 0;
    sys = [syslist objectAtIndex:i];
    ns = [sys numberOfStaves];
    for (j = 0; j < ns; j++)
    {
      sp = [sys getStaff: j];
      nl = sp->notes;
      k = [nl count];
      for (n = 0; n < k; n++)
      {
        p = [nl objectAtIndex:n];
	if ([p graphicType] == TIMESIG) bart[j] = [((TimeSig *)p) myBarLength];
        else if (ISATIMEDOBJ(p))
	{
 	  v = p->voice;
          if ([p graphicType] == REST)
          {
	    rests[v] = (Rest *)p;
	    numrests[v]++;
          }
	  else numvox[v]++;
	}
	else if ([p graphicType] == BARLINE)
        {
          for (v = 0; v < NUMVOICES; v++)
	  {
	    if (numrests[v] == 1 && numvox[v] == 0)
	    {
	      r = rests[v];
	      t = bart[j];
	      c = noteFromTicks(t);
	      r->time.body = c;
	      [r setDottingCode: dotsFromTicks(t, c)];
	      r->style = 5;
	    }
	    numrests[v] = numvox[v] = 0;
	  }
	}
      }
    }
  }
  return self;
}


/*
  This checks consistency with time signatures.
  The tricky part is handling multiple signatures (up to 8)
*/

#define NUMMULTSIG 8

- checkBarLength: sender
{
  int nsys, ns, i, j, k, m, n, ni, bn, nsig[NUMSTAVES];
  float lwhite, bt, t;
  BOOL barf[NUMSTAVES], sc, allOK = YES;
  TimeSig *tsig[NUMSTAVES][NUMMULTSIG];
  System *sys;
  Staff *sp;
  StaffObj *p;
  NSMutableArray *nl;
  nsys = [syslist count];
  for (i = 0; i < NUMSTAVES; i++)
  {
    barf[i] = YES;
    nsig[i] = 0;
    for (j = 0; j < NUMMULTSIG; j++) tsig[i][j] = nil;
  }
  [self renumber: self];
  for (i = 0; i < nsys; i++)
  {
    sys = [syslist objectAtIndex:i];
    ns = [sys numberOfStaves];
    lwhite = [sys leftWhitespace];
    [sys  doStamp: ns : lwhite];
    for (j = 0; j < ns; j++)
    {
      bn = sys->barnum;
      bt = 0;
      sp = [sys getStaff: j];
      ni = [sp indexOfNoteAfter: lwhite];
      nl = sp->notes;
      k = [nl count];
      for (n = ni; n < k; n++)
      {
        p = [nl objectAtIndex:n];
	if ([p graphicType] == TIMESIG)
	{
	  if (barf[j])
	  {
	    barf[j] = NO;
	    nsig[j] = 0;
	  }
	  if (nsig[j] < NUMMULTSIG)
	  {
              tsig[j][nsig[j]] = (TimeSig *)p;
	    nsig[j]++;
	  }
	}
        else if ([p graphicType] == BARLINE)
	{
	  barf[j] = YES;
	  t = p->stamp - bt;
	  sc = NO;
	  for (m = 0; m < nsig[j]; m++) if (!sc) sc |= [tsig[j][m] isConsistent: t];
	  if (!sc)
	  {
	    NSLog(@"Inconsistent bar length in page %d, bar %d, staff %d\n", [sys pageNumber], bn, j + 1);
	    allOK = NO;
	  }
	  bt = p->stamp;
	  bn += [p barCount];
	}
      }
    }
  }
  if (allOK) NSRunAlertPanel(@"Calliope", @"All bars consistent.", @"OK", nil, nil);
  return self;
}


/* join chords across staves (quadratic checking but low n) */


- joinChords: sender
{
  return [self pressTool: CHORDGROUP withArgument: 0];
}

extern char *typename[NUMTYPES];

- breakChords: sender
{
  int k = [slist count];
  GNote *p;
  ChordGroup *q;
  while (k--)
  {
    p = [slist objectAtIndex:k];
    if ([p graphicType] == NOTE)
    {
      q = [p myChordGroup];
      if (q != nil) [q removeObj];
    }
  }
  [self dirty];
  [self drawSelectionWith: NULL];
  return self;
}


/* the selected verses are noted so that copyVerseFrom has a destination */

- wantVerse: sender
{
    if (cvList != nil) 
	[cvList autorelease];
    if (slist != nil)
    {
	[self setupGrabCursor: 0];
	cvList = [slist mutableCopy];
	cvFlag = YES;
    }
    else cvFlag = NO;
    return self;
}


/* sender clears cvFlag */

- copyVerseFrom: p
{
  StaffObj *q;
  NSRect b0, b1;
  int k = [cvList count];
  if (k == 0) return self;
  if (!ISASTAFFOBJ(p)) return self;
  graphicListBBox(&b0, cvList);
  while (k--)
  {
    q = [cvList objectAtIndex:k];
    if (ISASTAFFOBJ(q)) [q copyVerseFrom: p];
  }
  graphicListBBox(&b1, cvList);
  b1  = NSUnionRect(b0 , b1);
  [self cache: b1];
  [[self window] flushWindow];
  [cvList autorelease];
  cvList = nil;
  [self dirty];
  return self;
}


/* show all verses */

- showVerse: sender
{
  if (currentSystem == nil)
  {
    NSLog(@"Assertion failure in GVCommands");
    return self;
  }
  [currentSystem showVerse];
  [self resetPage: currentPage];
  [self dirty];
  return self;
}


/* hide all verses in system that are selected */

- hideSystemVerse: sender
{
  int k;
  StaffObj *p;
  if (currentSystem == nil)
  {
    NSLog(@"Assertion failure in GVCommands");
    return self;
  }
  k = [slist count];
  if (k == 0) return self;
  while (k--)
  {
    p = [slist objectAtIndex:k];
    [currentSystem hideVerse: p->selver];
  }
  [self resetPage: currentPage];
  [self dirty];
  return self;
}


/* hide all verses in staff that are selected */

- hideStaffVerse: sender
{
  int k;
  StaffObj *p;
  Staff *sp;
  if (currentSystem == nil)
  {
    NSLog(@"Assertion failure in GVCommands");
    return self;
  }
  k = [slist count];
  if (k == 0) return self;
  while (k--)
  {
    p = [slist objectAtIndex:k];
    if (ISASTAFFOBJ(p))
    {
      sp = [p staff];
      if ([sp graphicType] == STAFF) [sp hideVerse: p->selver];
    }
  }
  [self resetPage: currentPage];
  [self dirty];
  return self;
}



- newRunner: sender
{
  Runner *p;
  if (currentSystem == nil)
  {
    NSLog(@"No current system");
    return self;
  }
  p = [[[Runner alloc] init] autorelease];
  p->client = currentSystem;
  [currentSystem linkobject: p];
  [self deselectAll: self];
  [currentSystem recalcObjs];
  [self selectObj: p];
  [[CalliopeAppController sharedApplicationController] inspectMe: p loadInspector: YES];
  return self;
}


- (Margin *) prevMargin: (System *) s
{
  int i = [syslist indexOfObject:s];
  System *sys;
  Margin *m;
  if (i == NSNotFound) return nil;
  while (i--)
  {
    sys = [syslist objectAtIndex:i];
    m = [sys margin];
    if (m) return m;
  }
  return nil;
}


- newMargins: sender
{
    Margin *newMargin, *previousMargin;
    
    if (currentSystem == nil)
    {
	NSLog(@"-newMargins, currentSystem == nil");
	return self;
    }
    if ([currentSystem margin])
    {
	NSLog(@"-newMargins, currentSystem failed margin check");
	return self;
    }
    previousMargin = [self prevMargin: currentSystem];
    if (previousMargin != nil)
	newMargin = [previousMargin copy];
    else 
	newMargin = [[Margin alloc] init];
    [newMargin setClient: currentSystem];
    [currentSystem linkobject: newMargin];
    [self deselectAll: self];
    [currentSystem recalcObjs];
    [self selectObj: newMargin];
    [[CalliopeAppController sharedApplicationController] inspectMe: newMargin loadInspector: YES];
    return self;
}

 
- objInspect: sender
{
  if ([slist count] > 0)
  {
    [self inspectSel: YES];
    [self setFontSelection: 0 : 0];
  }
  else
  {
    [[CalliopeAppController sharedApplicationController] inspectClass: [SysInspector class] loadInspector: YES];
    [self setFontSelection: 3 : 0];
  }
  return self;
}


int nextshade[4] = {2, 1, 3, 0};

static BOOL doToObject(Graphic *p, int c, int a)
{
  BOOL morph = NO;
  switch (c)
  {
    case 0:
      p->gFlags.invis = a;
      break;
    case 1:
      p->gFlags.locked = a;
      break;
    case 2:
      if (ISATIMEDOBJ(p)) ((TimedObj *)p)->time.tight = a;
      break;
    case 3:
      p->gFlags.size = smallersz[p->gFlags.size];
      morph = 1;
      break;
    case 4:
      p->gFlags.size = largersz[p->gFlags.size];
      morph = 1;
      break;
    case 5:
      /* leave this as a NO-OP */
      break;
    case 6:
      /* vacant */
      break;
    case 7:
      if (ISATIMEDOBJ(p)) ((StaffObj *)p)->isGraced = a;
      break;
    case 8:
      { /*sb: what a gross hack. All to convert to NSSymbolStringEncoding. Bah. */
          char temp[2];
          temp[0] = a;
          temp[1] = 0;
          [p keyDownString:[[[NSString alloc] initWithData:[NSData dataWithBytes:temp length:1] encoding:NSSymbolStringEncoding] autorelease]];
      }
      break;
    case 9:
      [p incrementNoteCodeBy: a];
      morph = 1;
      break;
    case 10:
      p->gFlags.invis = nextshade[p->gFlags.invis];
      break;
  }
  return morph;
}



- doToSelection: (int) c : (int) a
{
  NSRect b;
  Graphic *p;
  int k;
  k = [slist count];
  if (k == 0) return self;
  [self selectionHandBBox: &b];
  while (k--)
  {
    p = [slist objectAtIndex:k];
    if (doToObject(p, c, a)) [p reShape];
  }
  [self dirty];
  [self drawSelectionWith: &b];
//  [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
  return self;
}


/*
  Find relevant staves.  Packleft each selected obj of staff.
*/

- packLeft: sender
{
  NSRect b;
  StaffObj *p;
  Staff *sp;
  int i, k;
  i = k = [slist count];
  if (k == 0) return self;
  [self selectionHandBBox: &b];
  while (i--)
  {
    p = [slist objectAtIndex:i];
    if (ISASTAFFOBJ(p))
    {
      sp = [p staff];
      if ([sp graphicType] == STAFF && sp->gFlags.morphed == 0)
      {
        sp->gFlags.morphed = 1;
	[sp packLeft];
	[sp resizeNotes: 0];
      }
    }
  }
  i = k;
  while (i--)
  {
    p = [slist objectAtIndex:i];
    if (ISASTAFFOBJ(p))
    {
      sp = [p staff];
      if ([sp graphicType] == STAFF) sp->gFlags.morphed = 0;
    }
  }
  [self dirty];
  [self drawSelectionWith: &b];
  return self;
}


- alignColumn: sender
{
  NSRect b;
  StaffObj *p;
  int i, k;
  float mx = MAXFLOAT;
  i = k = [slist count];
  if (k == 0) return self;
  [self selectionHandBBox: &b];
  while (i--)
  {
    p = [slist objectAtIndex:i];
    if (ISASTAFFOBJ(p) && [p x] < mx) mx = [p x];
  }
  if (mx < MAXFLOAT)
  {
    i = k;
    while (i--)
    {
      p = [slist objectAtIndex:i];
      if (ISASTAFFOBJ(p))
      {
        p->x = mx;
	[p reShape];
      }
    }
    [self dirty];
    [self drawSelectionWith: &b];
  }
  return self;
}


/*
  fontflag has which thing to change:
    0 selected syllable of selected object(s)
    1 all syllables of selected object(s)
    2 selected verse in system of selected object
    3 all verses in selected system
*/

- (void)changeFont:(id)sender
{
  NSFont *f;
  StaffObj *p;
  System *sys;
  int num;
  BOOL err = YES;
  f = [[NSFontManager sharedFontManager] convertFont:[[NSFontManager sharedFontManager] selectedFont]];
  switch (fontflag)
  {
    case 0:
    case 1:
      if ([slist count] > 0)
      {
        [self changeSelectedFontsTo: f forAllGraphics: fontflag];
	err = NO;
      }
      break;
    case 2:
      p = [self canInspectTypeCode: TC_STAFFOBJ : &num];
      if (num == 1)
      {
        sys = [p mySystem];
	if ([sys graphicType] == SYSTEM)
        {
          [sys changeVFont: p->selver : f];
	  [self balancePage: self];
	  err = NO;
        }
      }
      break;
    case 3:
      if (currentSystem)
      {
        [currentSystem changeVFont: -1 : f];
	[self balancePage: self];
	err = NO;
      }
      break;
  }
  if (!err)
  {
    [self dirty];
  [[NSFontManager sharedFontManager] setSelectedFont:f isMultiple:NO];
  }
  else NSLog(@"Assertion failure in GVCommands");
}


/*
  whichFont is target of the matrix of buttons on the Font accessory.
  sets the fontflag and the selection of the font panel
*/


- whichFont: sender
{
  return [self setFontSelection: [sender selectedRow] : 1];
}


- doubleValue: sender
{
  return [self doToSelection: 9 : 1];
}


- halveValue: sender
{
  return [self doToSelection: 9 : -1];
}


- objVisible: sender
{
  return [self doToSelection: 0 : 0];
}


- objInvisible: sender
{
  return [self doToSelection: 0 : 1];
}


- objShade: sender
{
  return [self doToSelection: 10 : 0];
}


- lock:sender
{
  return [self doToSelection: 1 : 1];
}


- unlock:sender
{
  return [self doToSelection: 1 : 0];
}


- objTight: sender
{
  return [self doToSelection: 2 : 1];
}


- objNotTight: sender
{
  return [self doToSelection: 2 : 0];
}


- objSmaller: sender
{
  int i, k;
  k = i = [slist count];
  while (k--) [[slist objectAtIndex:k] markHangers];
  k = i;
  while (k--) [[slist objectAtIndex:k] resizeHangers: 1];
  return [self doToSelection: 3 : 0];
}


- objLarger: sender
{
  int i, k;
  k = i = [slist count];
  while (k--) [[slist objectAtIndex:k] markHangers];
  k = i;
  while (k--) [[slist objectAtIndex:k] resizeHangers: -1];
  return [self doToSelection: 4 : 0];
}


/* just set Grace */

- objGrace: sender
{
  return [self doToSelection: 7 : 1];
}


/* just unset Grace */

- objNotGrace: sender
{
  return [self doToSelection: 7 : 0];
}

- objBackward: sender
{
  return [self doToSelection: 7 : 2];
}


- selectAllOnStaff: sender
{
  StaffObj *p;
  Staff *sp;
  System *sys;
  NSMutableArray *nl;
  int k = [syslist count], nk, st, i, j;
  p = [slist objectAtIndex:0];
  [self deselectAll: self];
  if (ISASTAFFOBJ(p))
  {
    sp = [p staff];
    if ([sp graphicType] == STAFF)
    {
      sys = [sp mySystem];
      st = [sys indexOfStaff: sp];
      j = [syslist indexOfObject:sys];
      for (i = j; i < k; i++)
      {
        sys = [syslist objectAtIndex:i];
	sp = [sys getStaff: st];
	if (sp != nil)
	{
	  nl = sp->notes;
	  nk = [nl count];
	  while (nk--) [self selectObj: [nl objectAtIndex:nk] : 1];
	}
      }
      [self setNeedsDisplay:YES];
      [[CalliopeAppController sharedApplicationController] inspectApp];
      return self;
    }
  }
  NSLog(@"Assertion failure in GVCommands");
  return self;
}


/* Test Points */

char ch[8] = ".@#!.FSN";

#if 0
  System *sys;
  Staff *sp;
  NSMutableArray *nl;
  StaffObj *p;
  int i, j, k, ns;
  k = [syslist count];
  while (k--)
  {
    sys = [syslist objectAtIndex:k];
    ns = [sys numberOfStaves];
    if (ns != [sys numberOfStaves]) NSLog(@"System %d: count=%d, number of staves=%d\n", k, ns, [sys numberOfStaves]);
  }
  NSLog(@"checking finished\n");
#endif

- testPoint1: sender
{
    int k;
    Graphic *g;
    k = [slist count];
    while (k--)
    {
      g = [slist objectAtIndex: k];
      NSLog(@"%@", g);
    }
    return self;
#if 0
  Enclosure *p;
  NSMutableArray *nl;
  NSString *buf;
  int k;
  p = [slist objectAtIndex:0];
  nl = p->notes;
  k = [nl count];
  while (k--)
  {
    p = [nl objectAtIndex:k];
      buf = [NSString stringWithFormat:@"  %s\n", typename[[p graphicType]]];
    NSLog(buf);
  }
  return self;
#endif
}

extern char *typename[NUMTYPES];

- testPoint2: sender
{
  System *sys;
  Staff *sp;
  NSMutableArray *nl;
  StaffObj *p;
//  char buf[192];
  int i, j, k, ns, nsys, nn;
  k = 0;
  nsys = [syslist count];
  while (k < nsys)
  {
    sys = [syslist objectAtIndex: k];
    NSLog(@"System %d [page %d]:\n", k + 1, [sys pageNumber]);
    ++k;
    //[NXApp log: buf];
    ns = [sys numberOfStaves];
    for (i = 0; i < ns; i++)
    {
      sp = [sys getStaff: i];
      NSLog(@"  Staff %d [part=%s, y=%f]:\n", i+1, [[sp partName] UTF8String], [sp yOfTop]);
      //[NXApp log: buf];
      nl = sp->notes;
      nn = [nl count];
      for (j = 0;j < nn; j++)
      {
        p = [nl objectAtIndex:j];
        NSLog(@"    %d [%@]: %s x=%f, y=%f, stamp=%f, duration=%f\n", j, [p partName], typename[[p graphicType]], [p x], [p y], p->stamp, p->duration);
        //[NXApp log: buf];
      }
    }
  }
  return self;
}


- testPoint3: sender
{
//  System *sys;
  int n, nsys;
  nsys = [syslist count];
  n = [[CalliopeAppController sharedApplicationController] getLayBarNumber];
  if (n < 0 || n > nsys)
  {
    NSLog(@"Assertion failure in GVCommands");
    return self;
  }
  [syslist removeObjectAtIndex:n - 1];
  return self;
}


- testPoint4: sender
{
  return self;
}


- delOffScreenObjs: (int) s
{
  int i, k, nk;
  float lox, hix;
  NSSize r = NSZeroSize;
  NSMutableArray *nl;
  StaffObj *p;
  Staff *sp;
  System *sys;
/* #warning PrintingConversion:  [NSApp printInfo] is now [NSPrintInfo sharedPrintInfo].
 * This might want to be [[NSPrintOperation currentOperation] printInfo] or possibly
 * [[PageLayout new] printInfo]. */
/* sb: I think this is ok (1999). I'll leave it to the currentDocument to decide
 * where to get the info from (shared or not */
  r = [[CalliopeAppController currentDocument] paperSize];
  sys = [syslist objectAtIndex:s];
  lox = 0;
  hix = r.width / [self staffScale];
  k = [sys numberOfStaves];
  for (i = 0; i < k; i++)
  {
    sp = [sys getStaff: i];
    nl = sp->notes;
    nk = [nl count];
    while (nk--)
    {
      p = [nl objectAtIndex:nk];
      if ([p x] != [p x])
      {
        NSLog(@"deleting NaN-x object of type %d at y = %f, %dth obj on sys %d staff %d (org1)\n", [p graphicType], [p y], nk, s + 1, i + 1);
	[p removeObj];
      }
      else if ([p x] < lox || [p x] > hix)
      {
        NSLog(@"deleting off screen object of type %d at x = %f, y = %f, %dth obj on sys %d staff %d (org1)\n", [p graphicType], [p x], [p y], nk, s + 1, i + 1);
	[p removeObj];
      }
    }
  }
  return self;
}



/* report and delete staff objects that are off the screen in current system */


- delOffScreen: sender
{
  int i;
  if (currentSystem  == nil)
  {
    NSLog(@"Assertion failure in GVCommands");
    return self;
  }
  [self deselectAll: self];
  i = [syslist indexOfObject:currentSystem];
  [self delOffScreenObjs: i];
  return self;
}


- delBogusSystems: sender
{
  System *sys;
  Staff *sp;
//  StaffObj *p;
  int b,/* i, j,*/ k, ns;
  k = [syslist count];
  while (k--)
  {
    sys = [syslist objectAtIndex:k];
    b = 0;
    ns = [sys numberOfStaves];
    while (ns--)
    {
      sp = [sys getStaff: ns];
      if ([sp yOfTop] != [sp yOfTop]) b = 1;
    }
    if (b)
    {
      [syslist removeObjectAtIndex:k];
      NSLog(@"system (org 0) %d removed\n", k);
    }
    else
    {
      [self delOffScreenObjs: k];
    }
  }
  return self;
}



/* For my own use only.  Removes tablature lines from old 3-staff editions */
#if 0
- delAll3rdStaves: sender
{
  System *sys;
  Staff *sp;
  int j, k, r;
  char buff[64];
  id p;
  NSMutableArray *ol;
  r = 0;
  k = [syslist count];
  while (k--)
  {
    sys = [syslist objectAtIndex:k];
    if ([sys numberOfStaves] != 3) continue;
    sp = [sys getStaff: 2];
    if (sp->flags.subtype != 1) continue;
    [sys->staves removeObjectAtIndex:2];
    ++r;
    --(sys->flags.nstaves);
    ol = sys->nonStaffGraphics;
    j = [ol count];
    while (j--)
    {
      p = [ol objectAtIndex:j];
      if ([p graphicType] == TEXTBOX && SUBTYPEOF(p) == STAFFHEAD)
      {
        if (sp == ((TextGraphic *)p)->client) [p removeObj];
      }
      else if ([p graphicType] == BRACKET && SUBTYPEOF(p) != LINKAGE)
      {
	if (sp == ((Bracket *)p)->client1 || sp == ((Bracket *)p)->client2)
	  [p removeObj];
      }
    }
    [sp release];
  }
  sprintf(buff, "Removed %d staves.", r);
  if (r > 0) [self paginate: self];
  [self firstPage: self];
  return self;
}
#endif

#if 0

/* actually clear all hangers */

- delOffScreen: sender
{
  int i, k, nk;
  float lox, hix;
  NSRect *r;
  NSMutableArray *nl;
  StaffObj *p;
  Staff *sp;
  System *sys;
  if (currentSystem  == nil)
  {
    NSLog(@"Assertion failure in GVCommands");
    return self;
  }
  [self deselectAll: self];
  sys = currentSystem;
  k = [sys numberOfStaves];
  for (i = 0; i < k; i++)
  {
    sp = [sys getStaff: i];
    nl = sp->notes;
    nk = [nl count];
    while (nk--)
    {
      p = [nl objectAtIndex:nk];
      p->hangers = nil;
    }
  }
  return self;
}

#endif

/* toggle staff line display (my own use) */

- toggleStaffDisp: sender
{
  staffFlag ^= 1;
    [self setNeedsDisplay:YES];
  return self;
}


/*
  Commands from User
*/


/* set the page, return -1 if OK, or what should read */

- (int) gotoPage: (int) n
{
    if (currentPage == nil) 
	return 0;
    if ([self gotoPage: n usingIndexMethod: 2] == nil) 
	return [currentPage pageNumber];
    return -1;
}


- paginate: sender
{
    ProgressDisplay *paginateProgress = [ProgressDisplay progressDisplayWithTitle: @"Paginating"];
    
    [self saveSysLeftMargin];
    [self renumSystems];
    [self doPaginate];
    [self renumPages];
    [self setRunnerTables];
    [self shuffleIfNeeded];
    [self balancePages];
    [self setRanges];
    [self dirty];
    [paginateProgress closeProgressDisplay];
    [self gotoPage: 0 usingIndexMethod: 4];
    return self;
}


- balancePage: sender
{
  [self balanceOrAsk: currentPage : 0 askIfLoose: YES];
  return [self dirty];
}


- formatAll: sender
{
    int systemIndex, systemCount = [syslist count];
    ProgressDisplay *formatProgress = [ProgressDisplay progressDisplayWithTitle: @"Adjusting all systems"];
    
    [self flowTimeSig: NULL];
    for (systemIndex = 0; systemIndex < systemCount; systemIndex++)
    {
	[formatProgress setProgressRatio: 1.0 * systemIndex / systemCount];
	[[syslist objectAtIndex: systemIndex] userAdjust: YES];
    }
    [self paginate: sender];
    [formatProgress closeProgressDisplay];
    return [self dirty];
}


- formatPage: sender
{
  int systemIndex;
  Page *p = currentPage;
  
  [self flowTimeSig: [syslist objectAtIndex: [p bottomSystemNumber]]];
  for (systemIndex = [p topSystemNumber]; systemIndex <= [p bottomSystemNumber]; systemIndex++) 
    [[syslist objectAtIndex:systemIndex] userAdjust: YES];
  [self resetPage: currentPage];
  return [self dirty];
}


- doFullAdjust: sender
{
  [self flowTimeSig: currentSystem];
  [currentSystem userAdjust: YES];
  [self resetPage: currentPage];
  return [self dirty];
}


- doPartAdjust: sender
{
  [self flowTimeSig: currentSystem];
  [currentSystem userAdjust: NO];
  [self resetPage: currentPage];
  return [self dirty];
}


/* Duplicate current system, and make it current. TODO This should become part of NotationScore */
- duplicateSystem: sender
{
    System *sys = [currentSystem newFormattedSystem];
    
    [self insertSystem: sys afterSystem: currentSystem];
    [self selectSystemAsCurrent: sys];
    [self setFontSelection: 1 : 0];
    [self simplePaginate: sys afterAddingCount: 1 askIfLoose: NO];
    // TODO if we are going to display an inspector it should be from a controller.
    // [[CalliopeAppController sharedApplicationController] inspectClass: [SysInspector class] loadInspector: NO];
    return [self dirty];
}


/*
  find or make the next system of same number of staves as arg.
  Return sys; pass back whether next system was there already.
*/

- (System *) nextSystem: (System *) prototypeSystem didCreate: (BOOL *) didCreate
{
    System *nextSystem;
    
    *didCreate = NO;
    if (prototypeSystem == [syslist lastObject]) 
	*didCreate = YES;
    else {
	unsigned whereToInsertNewSystem = [syslist indexOfObject: prototypeSystem];
	
	if (whereToInsertNewSystem == NSNotFound) {
	    NSLog(@"System not in syslist? Should not happen!");
	    
	    if ([syslist count]) 
		whereToInsertNewSystem = 0;
	    else 
		return nil;
	}
	nextSystem = [syslist objectAtIndex: whereToInsertNewSystem + 1];
	if ([nextSystem numberOfStaves] != [prototypeSystem numberOfStaves])
	    *didCreate = YES;
    }
    if (*didCreate) {
	nextSystem = [prototypeSystem newFormattedSystem];
	[self addSystem: nextSystem];
    }
    return nextSystem;
}


/* lay out barlines */

- layBarlines: sender
{
  NSRect r;
  int n;
  if (currentSystem == nil) NSLog(@"Assertion failure in GVCommands");
  else
  {
    n = [[CalliopeAppController sharedApplicationController] getLayBarNumber];
    [currentSystem layBars: n : &r];
    [self cache: r];
    [[self window] flushWindow];
    [self dirty];
  }
  return self;
}


/* recalc all systems. */

- recalcAllSys
{
  int systemIndex, systemCount = [syslist count];
  ProgressDisplay *recalcProgress = [ProgressDisplay progressDisplayWithTitle: @"Resetting system layout"];

  for (systemIndex = 0; systemIndex < systemCount; systemIndex++)
  {
    [recalcProgress setProgressRatio: 1.0 * systemIndex / systemCount];
    [[syslist objectAtIndex: systemIndex] recalc];
  }
  [recalcProgress closeProgressDisplay];
  return self;
}


- reShapeAllSys: sender
{
    int systemIndex, systemCount = [syslist count];
    Staff *sp;
    ProgressDisplay *reshapeProgress = [ProgressDisplay progressDisplayWithTitle: @"Reshaping system layout"];
    
    for (systemIndex = 0; systemIndex < systemCount; systemIndex++) {
	System *s = [syslist objectAtIndex: systemIndex];
	int staveCount = [s numberOfStaves];
	
	[reshapeProgress setProgressRatio: 1.0 * systemIndex / systemCount];
	while (staveCount--) {
	    sp = [s getStaff: staveCount];
	    if ([sp yOfTop] != [sp yOfTop])  /* check for NaN */
	    {
		// sp->y = 500; // TODO this seems bogus in the extreme!
		NSLog(@"  staff %d has NaN y\n", staveCount + 1);
		[sp recalc];
	    }
	}
	[s reShape];
    }
    [reshapeProgress closeProgressDisplay];
    [self dirty];
    [self setNeedsDisplay: YES];
    return self;
}


- shuffleAllMarginsByScale: (float) oss : (float) nss
{
  int systemIndex, nsys;
  System *sys;
  float lm;
  ProgressDisplay *shuffleProgress = [ProgressDisplay progressDisplayWithTitle: @"Recalculating Margins"];

  nsys = [syslist count];
  for (systemIndex = 0; systemIndex < nsys; systemIndex++)
  {
    sys = [syslist objectAtIndex:systemIndex];
    lm = [sys leftWhitespace] * nss;  /* convert to raw points */
    [shuffleProgress setProgressRatio: 1.0 * systemIndex / nsys];
    [sys shuffleNotes: lm / oss : lm / nss];
  }
  [shuffleProgress closeProgressDisplay];
  return self;
}


/* set margins and rastral number of all systems */

- sizeAllSys: sender
{
  NSLog(@"Assertion failure in GVCommands");
  return self;
}


/* set hidden of relevant staves of similar systems */

- hiddenAllSys: sender
{
    int i, j, k, kspl, ktpl;
    System *t, *s = currentSystem;
    Staff *tp, *sp;
    
    if (s == nil) {
	NSLog(@"Assertion failure in GVCommands");
	return self;
    }
    kspl = [s numberOfStaves];
    k = [syslist count];
    for (i = 0; i < k; i++) {
	t = [syslist objectAtIndex:i];
	if (t == s) 
	    continue;
	ktpl = [t numberOfStaves];
	if (ktpl != kspl) continue;
	for (j = 0; j < ktpl; j++) {
	    sp = [s getStaff: j];
	    tp = [t getStaff: j];
	    tp->flags.hidden = sp->flags.hidden;
	}
	[t recalc];
    }
    return [self paginate: self];
}


- spillBar: sender
{
  if (currentSystem == nil) NSLog(@"Assertion failure in GVCommands");
  else
  {
    [currentSystem spillBar];
    [self dirty];
    [self setNeedsDisplay:YES];
  }
  return self;
}


- grabBar: sender
{
  if (currentSystem == nil) NSLog(@"Assertion failure in GVCommands");
  else
  {
    [currentSystem grabBar];
    [self dirty];
    [self setNeedsDisplay:YES];
  }
  return self;
}


- renumber: sender
{
  [self renumSystems];
  [self renumPages];
  [self setRanges];
  [self dirty];
  [self setNeedsDisplay:YES];
  return self;
}


static void highlightBox(NSRect *r, GraphicView *v)
{
  [v lockFocus];
  NSHighlightRect(*r);
  [[v window] flushWindow];
  [v unlockFocus];
}


static BOOL askAboutSys(char *s, System *sys, GraphicView *v)
{
  NSRect r;
  int i;
  [sys measureSys: &r];
  highlightBox(&r, v);
  i = NSRunAlertPanel(@"Calliope", [NSString stringWithUTF8String:s], @"YES", @"NO", nil);
  highlightBox(&r, v);
  return (i == NSAlertDefaultReturn);
}


- (BOOL) deleteThisSystem: (System *) sys
{
  int i;
  Page *p = [sys page];
  BOOL r = NO, m = NO;
  int theLocation;
    
  i = (sys == [syslist lastObject]) ? -1 : 1;
  [self selectSystemAsCurrent: [self getSystem: sys offsetBy: i]];
  m = ([sys margin] != nil);
  if (m) [self saveSysLeftMargin];
  theLocation = [syslist indexOfObject:sys];
  if (theLocation != NSNotFound) [syslist removeObjectAtIndex: theLocation];
  if (m) [self shuffleIfNeeded];
  if ([p topSystemNumber] == [p bottomSystemNumber])
  {
    [self paginate: self];
    r = YES;
  }
  else
  {
    [self resetPagelist: p addingSystemCount: -1];
    [self resetPage: p];
  }
  [self dirty];
  return r;
}


- deleteSys: sender
{
  System *sys = currentSystem;
  if ([syslist count] <= 1)
  {
    NSLog(@"Assertion failure in GVCommands");
    return nil;
  }
  if (askAboutSys("You wish to delete this system?", sys, self))
  {
    [self deleteThisSystem: currentSystem];
    [[CalliopeAppController sharedApplicationController] inspectApp];
  }
  return self;
}

/*
  delete the hidden staves in a system.  Complication:
  must delete things that depend on the staff.  User Beware.
*/

- deleteStaves: sender
{
  System *sys = currentSystem;
  if ([syslist count] <= 1)
  {
    NSLog(@"Assertion failure in GVCommands");
    return nil;
  }
  if (!askAboutSys("You wish to delete all hidden staves from this system?", sys, self)) return nil;
  [sys deleteHiddenStaves];
  [self dirty];
  return self;
}


- delAllHidden: sender
{
  int k;
  System *sys = currentSystem;
  if (sys == nil || [syslist count] < 1)
  {
    NSLog(@"Assertion failure in GVCommands");
    return nil;
  }
  if (!askAboutSys("You wish to delete all hidden staves from ALL systems?", sys, self)) return nil;
  k = [syslist count];
  while (k--) 
      [[syslist objectAtIndex: k] deleteHiddenStaves];
  [self dirty];
  [self setNeedsDisplay:YES];
  return self;
}


/* use the Pasteboard, but forge a list membership */

- copySys: sender
{
  System *sys = currentSystem;
  [self deselectAll: sender];
  sys->oldleft = [sys leftMargin];
  [slist addObject: sys];
  [self copyToPasteboard];
  [slist removeObjectAtIndex:0];
  return self;
}


- copyAllSys: sender
{
  int i, k;
  System *sys;
  [self deselectAll: sender];
  k = [syslist count];
  for (i = 0; i < k; i++)
  {
    sys = [syslist objectAtIndex:i];
    sys->oldleft = [sys leftMargin];
    [slist addObject: sys];
  }
  [self copyToPasteboard];
  [self clearSelection];
  return self;
}


- cutSys: sender
{
  BOOL m = NO;
  if ([syslist count] <= 1)
  {
    NSLog(@"Assertion failure in GVCommands");
    return nil;
  }
  m = ([currentSystem margin] != nil);
  [self copySys: sender];
  [self deleteThisSystem: currentSystem];
  if (m) [self paginate: self];
  [[CalliopeAppController sharedApplicationController] inspectApp];
  return self;
}


/*
  paste as many systems as we can find.
  Tricky because needs to go in current page so width and shuffle correct,
  but them  */

- pasteSys: sender
{
  int i, k, n;
  NSMutableArray *pl = [self pasteFromPasteboard];
  System *sys, *ns;
    
  k = [pl count];
  n = 0;
  sys = currentSystem;
  for (i = 0; i < k; i++)
  {
    ns = [pl objectAtIndex:i];
    if ([ns graphicType] == SYSTEM)
    {
      ++n;
      [ns setPageView: self];
      [ns setPage: [sys page]];
      [ns closeSystem];
      [self insertSystem: ns afterSystem: sys];
      if (ns->oldleft != [ns leftMargin]) [ns shuffleNotes: ns->oldleft : [ns leftMargin]];
      [ns recalc];
      sys = ns;
    }
  }
  if (n == 0)
  {
    NSLog(@"Assertion failure in GVCommands");
    return nil;
  }
  [self paginate: self];
  [self selectSystemAsCurrent: sys];
  [[CalliopeAppController sharedApplicationController] inspectApp];
  [self setNeedsDisplay:YES];
  return self;
}


/*
  Merge currentsys and the one following it into one big system.
  Take care with nonStaffGraphics, using only runners, staff headers, brackets.
*/

- mergeSys: sender
{
    int i, k;
    System *sys = currentSystem;
    System *nsys;
    Staff *sp;
    Page *p1, *p2;
    id p;
    BOOL pag;
    
    if (currentSystem  == nil)
    {
	NSLog(@"Assertion failure in GVCommands");
	return self;
    }
    nsys = [self getSystem: currentSystem offsetBy: 1];
    if (nsys == nil)
    {
	NSLog(@"Assertion failure in GVCommands");
	return self;
    }
    k = [nsys numberOfStaves];
    for (i = 0; i < k; i++)
    {
	sp = [nsys getStaff: i];
	[sys addStaff: sp];
	[sp setSystem: sys];
    }
    k = [nsys->nonStaffGraphics count];
    for (i = 0; i < k; i++) 
    {
	p = [nsys->nonStaffGraphics objectAtIndex:i];
	if ([p graphicType] == RUNNER)
	{
	    ((Runner *)p)->client = sys;
	    [sys linkobject: p];
	}
	else if (([p graphicType] == TEXTBOX && SUBTYPEOF(p) == STAFFHEAD) ||
		 ([p graphicType] == BRACKET && SUBTYPEOF(p) != LINKAGE)) 
	    [sys linkobject: p];
    }
    [sys recalc];
    p1 = [sys page];
    p2 = [nsys page];
    pag = [self deleteThisSystem: nsys];
    if (!pag) [self simplePaginate: sys afterAddingCount: 0 askIfLoose: YES];
    [[CalliopeAppController sharedApplicationController] inspectApp];
    return self;
}


/* un-normalise tablature to add redundant flags */

- unsetTablature: sender
{
  int nsys, ns, i, j, k, n, cf=0, df=0;
  NSMutableArray *al;
  System *sys;
  Staff *sp;
  Tablature *p;
  
  nsys = [syslist count];
  for (i = 0; i < nsys; i++)
  {
    sys = [syslist objectAtIndex:i];
    ns = [sys numberOfStaves];
    for (j = 0; j < ns; j++)
    {
      sp = [sys getStaff: j];
      al = sp->notes;
      k = [sp indexOfNoteAfter: [sys leftWhitespace]];
      n = [al count];
      while (k < n)
      {
        p = [al objectAtIndex:k];
        if ([p graphicType] == TABLATURE && !(p->gFlags.subtype))
        {
	  if (p->flags.prevtime)
          {
	    p->time.body = cf;
	    [p setDottingCode: df];
	    p->flags.prevtime = 0;
	    [p recalc];
          }
          else
          {
            cf = p->time.body;
            df = [p dottingCode];
          }
	}
	++k;
      }
    }
  }
  [self dirty];
  [self setNeedsDisplay:YES];
  return self;
}

/* normalise tablature to remove redundant flags */

- setTablature: sender
{
  int nsys, ns, i, j, k, n, cf=0, df=0;
  NSMutableArray *al;
  System *sys;
  Staff *sp;
  Tablature *p;
  nsys = [syslist count];
  for (i = 0; i < nsys; i++)
  {
    sys = [syslist objectAtIndex:i];
    ns = [sys numberOfStaves];
    for (j = 0; j < ns; j++)
    {
      sp = [sys getStaff: j];
      al = sp->notes;
      k = [sp indexOfNoteAfter: [sys leftWhitespace]];
      n = [al count];
      while (k < n)
      {
        p = [al objectAtIndex:k];
        if ([p graphicType] == BARLINE) cf = -1;
        else if ([p graphicType] == TABLATURE)
        {
          if (p->gFlags.subtype) cf = -1;
          else if (!(p->flags.prevtime))
          {
            if (cf == p->time.body && df == [p dottingCode] && [p tabCount] > 0 && ![p isBeamed])
            {
              p->flags.prevtime = 1;
	      [p recalc];
            }
            else
            {
              cf = p->time.body;
              df = [p dottingCode];
            }
          }
	}
        ++k;
      }
    }
  }
  [self dirty];
  [self setNeedsDisplay:YES];
  return self;
}


- upgradeNeumes
{
  int nsys, ns, i, j, k/*, n */;
  NSMutableArray *al;
  System *sys;
  Staff *sp;
  Neume *p;
  NeumeNew *np;
//  Verse *v;
  nsys = [syslist count];
  for (i = 0; i < nsys; i++)
  {
    sys = [syslist objectAtIndex: i];
    ns = [sys numberOfStaves];
    for (j = 0; j < ns; j++)
    {
      sp = [sys getStaff: j];
      al = sp->notes;
      k = [al count]; 
      while (k--)
      {
        p = [al objectAtIndex:k];
	if ([p graphicType] == NEUME)
	{
	  np = [[NeumeNew alloc] init];
	  [np upgradeFrom: p];
	  p->verses = nil;
	  [p removeObj];
	  [sp linknote: np];
	}
      }
    }
  }
  [self dirty];
  [self setNeedsDisplay:YES];
  return self;
}


- upgradeParts
{
    int nsys, ns, i, j, k;
    NSMutableArray *al, *pl = [[CalliopeAppController sharedApplicationController] getPartlist];
    CallPart *cp;
//  Tablature *t;
    
    k = [pl count];
    while (k--) {
	cp = [pl objectAtIndex:k];
	if ((int) cp->instrument < 256)
	{
	    cp->instrument = [[NSString stringWithString:[instlist instNameForInt: (int) cp->instrument]] retain];
	}
    }
    nsys = [syslist count];
    for (i = 0; i < nsys; i++) {
	System *sys = [syslist objectAtIndex: i];
	
	ns = [sys numberOfStaves];
	for (j = 0; j < ns; j++) {
	    Staff *sp = [sys getStaff: j];
	    
	    [sp setPartName: nullPart]; 
	    al = sp->notes;
	    k = [al count]; 
	    while (k--) {
		StaffObj *p = [al objectAtIndex: k];
		
		[p setPartName: nullPart]; 
	    }
	}
    }
    [self dirty];
    [self setNeedsDisplay:YES];
    return self;
}


void setSplit(Hanger *h, int u, int f)
{
    h->UID = u;
    [h setSplitToLeft: (f & 2) == 2];
    [h setSplitToRight: (f & 1) == 1];
}


- upgradeTies
{
  int nsys, ns, i, j, k, n, hk, e;
  NSMutableArray *al, *hl;
  System *sys;
  Staff *sp;
  StaffObj *p;
  Tie *h, *hp;
  Hanger *nt;
  Class nc = nil;
  
  nsys = [syslist count];
  for (i = 0; i < nsys; i++)
  {
    sys = [syslist objectAtIndex:i];
    ns = [sys numberOfStaves];
    for (j = 0; j < ns; j++)
    {
      sp = [sys getStaff: j];
      al = sp->notes;
      k = 0;
      n = [al count];
      while (k < n)
      {
        p = [al objectAtIndex:k];
	hl = p->hangers;
	hk = [hl count];
	while (hk--)
	{
	  h = [hl objectAtIndex:hk];
	  if ([h graphicType] == VOLTA)
	  {
            nt = [[NoteGroup alloc] init];
              [(NoteGroup *)nt proto: (Volta *)h];
	    [h removeObj];
	  }
	  else if ([h graphicType] == TIE)
	  {
	    if (!h->flags.master) continue;
	    switch(h->gFlags.subtype)
	    {
	      case TIEBOW:
	      case TIESLUR:
	        nc = [TieNew class];
		break;
	      case TIELINE:
	      case TIEBRACK:
	      case TIECORN:
	        nc = [Ligature class];
	        break;
	      case TIECRES:
	      case TIEDECRES:
	        nc = [NoteGroup class];
	        break;
	    }
	    hp = h->partner;
	    if (h->flags.same)
            {
              nt = [[nc alloc] init];
              [nt proto: h : hp];
	      [h removeObj];
            }
            else
            {
              e = ([[h firstClient] sysNum] < [[hp firstClient] sysNum]);
              if (e)
              {
                nt = [[nc alloc] init];
                [nt proto: h : nil];
		setSplit(nt, (int) h, 1);
                nt = [[nc alloc] init];
                [nt proto: nil : hp];
		setSplit(nt, (int) h, 2);
              }
              else
              {
                nt = [[nc alloc] init];
                [nt proto: nil : h];
		setSplit(nt, (int) h, 2);
                nt = [[nc alloc] init];
                [nt proto: hp : nil];
		setSplit(nt, (int) h, 1);
              }
	      [h removeObj];
            }
	  }
	}
        ++k;
      }
    }
  }
  [self dirty];
  [self setNeedsDisplay:YES];
  return self;
}

@end



