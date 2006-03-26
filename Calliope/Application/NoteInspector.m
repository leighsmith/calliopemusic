#import "NoteInspector.h"
#import "GNote.h"
#import "GNChord.h"
#import "NoteHead.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "CalliopeThreeStateButton.h"
#import "GVCommands.h"
#import "CallInst.h"
#import "CallPart.h"
#import "mux.h"
#import "muxlow.h"
#import <AppKit/AppKit.h>

extern id lastHit;

@implementation NoteInspector

extern NSString *GeneralMidiSounds[128];

static NSPopUpButton *midipopup;
static int whichlist = -1;
static int wheretuning = -1;
static int mypartlist = -1;


- (void)awakeFromNib
{
  int i;
  NSMutableArray *anArray = [NSMutableArray arrayWithCapacity:128];
  midipopup = [[NSPopUpButton alloc] init];
  [midipopup addItemWithTitle:@"multiple selection"];
  for (i = 0; i < 128; i++) [anArray addObject:GeneralMidiSounds[i]];
  [midipopup addItemsWithTitles:anArray];
}


/*
  if p is nonnull, use its 'where' to set w.
*/

- constructTuning: (GNote *) p
{
  NSMutableArray *pl;
  int i, k, w;
  w = (p == nil) ? [definebutton indexOfSelectedItem] - 1 : [p whereInstrument];
  if (w == -1) return self;
  switch(w)
  {
    case 0:  /* defined by note */
      if (wheretuning == w) return self;
//#error PopUpConversion: NSAttachPopUpList() is obsolete. Use the NSPopUpButton class.
//      NSAttachPopUpList(instbutton, midipopup);
        [instbutton removeAllItems];
        [instbutton addItemsWithTitles:[midipopup itemTitles]];
      whichlist = 0;
      break;
    case 1:  /* defined by note's part */
    case 2:  /* defined by staff's part */
      if ((wheretuning == 1 || wheretuning == 2) && mypartlist == partlistflag) return self;
//#error PopUpConversion: NSAttachPopUpList() is obsolete. Use the NSPopUpButton class.
//      NSAttachPopUpList(instbutton, instpopup);
//      k = [instpopup count];
//      while (k--) [instpopup removeItemAtIndex:k];
        [instbutton removeAllItems];
        [instbutton addItemWithTitle:@"multiple selection"];
      pl = [NSApp getPartlist];
      k = [pl count];
        for (i = 0; i < k; i++) [instbutton addItemWithTitle:[pl partNameForInt: i]];
      whichlist = 1;
      mypartlist = partlistflag;
      break;
  }
  wheretuning = w;
  return self;
}


/* the new action when instrument button is pressed */

- makeTuneList: sender
{
  int i;
  [self constructTuning: nil];
  i = [definebutton indexOfSelectedItem] - 1;
  if (i < 0) return self;
//  if (i) [instpopup popUp:sender]; else [midipopup popUp:sender];
  return self;
}




/* called during nib loading */

- setInstbutton: sender
{ 
  instbutton = sender;
//    instpopup = [instbutton target]; //sb: need to change this if it is ever used
  [instbutton setTarget:self];
  [instbutton setAction:@selector(makeTuneList:)];
  /* no action/target required for definepopup */
  return self;
}


/* set tuning based on where defined */

- defineTuning: (GNote *) p
{
  int i, d;
    d = [definebutton indexOfSelectedItem] - 1;
  if (d < 0) return self;
  switch(d)
  {
    case 0:
        i = popSelectionFor(instbutton) - 1;//sb: was midipopup
        if (i >= 0) p->instrument = i + 1;//sb: FIXME something is very wrong here
      break;
    case 1:
      p->instrument = 0;
        i = popSelectionFor(instbutton) - 1;//sb:  was instpopup
        if (i >= 0) {
            if (p->part) [p->part autorelease];
            p->part = [[[NSApp getPartlist] partNameForInt: i] retain];
        }
      break;
    case 2:
        if (p->part) [p->part autorelease];
        p->instrument = 0;//sb: this is instrument from 'GNote', not from CallPart
      p->part = nil;
      break;
  }
  return self;
}


/* check for "Don't Care" or out of range values */

- (BOOL) toolValid
{
    if ([stylematrix selectedColumn] == -1) return NO;
    if ([[objmatrix cellAtRow:0 column:0] threeState] == 2) return NO;
    if ([stemmatrix selectedColumn] == -1) return NO;
    if ([fixswitch threeState] == 2) return NO;
    if ([[objmatrix cellAtRow:1 column:0] threeState] == 2) return NO;
    if ([nostemswitch threeState] == 2) return NO;
    if ([[voiceform cellAtIndex:0] intValue] < 0) return NO;
    if ([gracematrix selectedColumn] == -1) return NO;
    if ([slashswitch threeState] == 2) return NO;
    return YES;
}


- setProto: sender
{
  GNote *p = [GNote myPrototype];
  if (![self toolValid])
  {
    NSRunAlertPanel(@"Tool", @"Cannot set Tool: Inspector is ambiguous", @"OK", nil, nil);
  }
  else
  {
    p->gFlags.subtype = [[stylematrix selectedCell] tag];
    p->gFlags.locked = ([[objmatrix cellAtRow:0 column:0] threeState] == 1);
    p->time.stemup = ![stemmatrix selectedColumn];
    p->time.stemfix = ([fixswitch threeState] == 1);
    p->time.tight = [[objmatrix cellAtRow:1 column:0] threeState];
    p->time.nostem = ([nostemswitch threeState] == 1);
    p->voice = [[voiceform cellAtIndex:0] intValue];
    [self defineTuning: p];
    p->isGraced = [gracematrix selectedColumn];
    p->showslash = ([slashswitch threeState] == 1);
  }
  return self;
}


void setAccidental(GNote *p, int se, int a, int e)
{
  int k, hk;
  NoteHead *h;
  hk = [p->headlist count];
  if (hk == 1) k = 0;
  else if (p == lastHit) k = se;
  else return;
  h = [p->headlist objectAtIndex:k];
  h->accidental = a;
  h->editorial = e;
}


int getAccidental(GNote *p, int se)
{
  int k, hk;
  NoteHead *h;
  hk = [p->headlist count];
  if (hk == 1) k = 0;
  else if (p == lastHit) k = se;
  else return -1;
  h = [p->headlist objectAtIndex:k];
  return h->accidental;
}


int getEditorial(GNote *p, int se)
{
  int k, hk;
  NoteHead *h;
  hk = [p->headlist count];
  if (hk == 1) k = 0;
  else if (p == lastHit) k = se;
  else return -1;
  h = [p->headlist objectAtIndex:k];
  return h->editorial;
}


static void setBodyTypes(GNote *p, int t)
{
  NoteHead *h;
  int hk = [p->headlist count];
  while (hk--)
  {
    h = [p->headlist objectAtIndex:hk];
    h->type = t;
  }
  p->gFlags.subtype = t;
}


- set:sender
{
  NSRect b;
  GNote *p;
  id sl, v = [[DrawApp currentDocument] graphicView];
  int i, k, num, seltime, seldot, selstyl, selacc, selstem, selgra, nostem, seled;
  BOOL doReset = NO;
  if ([v startInspection: NOTE : &b : &sl : &num])
  {
    seltime = [timematrix selectedColumn];
    seldot = [dotmatrix selectedColumn];
    selstyl = [[stylematrix selectedCell] tag];
    selacc = [accmatrix selectedColumn];
    selstem = [stemmatrix selectedColumn];
    selgra = [gracematrix selectedColumn];
    nostem = [nostemswitch threeState];
    seled = [edaccbutton selectedColumn];
    if (seltime >= 0 && seldot < 0) seldot = 0;
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == NOTE)
    {
      if (selstyl >= 0) setBodyTypes(p, selstyl);
      if (seltime >= 0)
      {
	p->time.body = seltime;
	p->time.dot = seldot;
      }
      if (selacc >= 0)
      {
        setAccidental(p, p->gFlags.selend, selacc, seled);
      }
      i = [nostemswitch threeState];
      if (i != 2) p->time.nostem = i;
      if (selgra >= 0) p->isGraced = selgra;
      if (selstem >= 0)
      {
      
        if (selstem == p->time.stemup)
        {
	  p->time.stemup = !(p->time.stemup);
	  [p reverseHeads];
	  [p resetStemlen];
        }
          i = [fixswitch threeState];
        if (i != 2) p->time.stemfix = i;
      }
      i = [[voiceform cellAtIndex:0] intValue];
      if ([voiceform indexOfSelectedItem] == 0) p->voice = i;
      i = [[verseform cellAtIndex:0] intValue];
      if ([verseform indexOfSelectedItem] == 0)
      {
        if (i != p->versepos) doReset = YES;
        p->versepos = i;
      }
      i = [[objmatrix cellAtRow:0 column:0] threeState];
      if (i != 2) p->gFlags.locked = i;
      i = [[objmatrix cellAtRow:1 column:0] threeState];
      if (i != 2) p->time.tight = i;
      i = [slashswitch threeState];
      if (i != 2) p->showslash = i;
      [self defineTuning: p];
      [p reShape];
    }
    [v endInspection: &b];
    if (doReset) [v balancePage: self];
  }
  return self;
}


/* assaying attributes for sensible display on inspector */

- assayList: (NSMutableArray *) sl : (int *) num
{
  GNote *p;
  int k, n;
  k = [sl count];
  initassay();
  n = 0;
  while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == NOTE)
  {
    ++n;
    assay(0, p->gFlags.locked);
    assay(1, p->time.tight);
    assay(2, p->time.stemfix);
    assay(3, p->isGraced);
    assay(5, p->time.body);
    assay(6, p->time.dot);
    assay(7, p->gFlags.subtype);
    assay(8, getAccidental(p, p->gFlags.selend));
    assay(9, (p->time.stemlen > 0));
    assay(10, p->voice);
    assay(11, [p whereInstrument]);
    assay(12, p->time.nostem);
    assay(13, p->versepos);
    assay(14, getEditorial(p, p->gFlags.selend));
    assayAsAtom(15, [p getPart]);
    assay(16, [p getPatch]);
    assay(17, p->showslash);
  }
  *num = n;
  return self;
}


- updatePanel
{
  int a, num;
  GraphicView *v = [[DrawApp currentDocument] graphicView];
  [self assayList: v->slist : &num];
  if (num == 0) return nil;
  for (a = 0; a <= 1; a++)
  {
    if (ALLSAME(a, num)) [[objmatrix cellAtRow:a column:0] setThreeState:(ALLVAL(a) != 0)];
      else [[objmatrix cellAtRow:a column:0] setThreeState:2];
  }
  if (ALLSAME(2, num)) [fixswitch setThreeState:(ALLVAL(2) != 0)]; else [fixswitch setThreeState:2];
  if (ALLSAME(3, num)) [gracematrix selectCellAtRow:0 column:ALLVAL(3)]; else clearMatrix(gracematrix);
  if (ALLSAME(5, num)) [timematrix selectCellAtRow:0 column:ALLVAL(5)]; else clearMatrix(timematrix);
  if (ALLSAME(6, num)) [dotmatrix selectCellAtRow:0 column:ALLVAL(6)]; else clearMatrix(dotmatrix);
  if (ALLSAME(7, num)) [stylematrix selectCellWithTag:ALLVAL(7)];else clearMatrix(stylematrix);
  if (ALLSAME(8, num)) [accmatrix selectCellAtRow:0 column:ALLVAL(8)]; else clearMatrix(accmatrix);
  if (ALLSAME(9, num)) [stemmatrix selectCellAtRow:0 column:ALLVAL(9)]; else clearMatrix(stemmatrix);
  if (ALLSAME(10, num)) [[voiceform cellAtIndex:0] setIntValue:ALLVAL(10)];
  else
  {
    [[voiceform cellAtIndex:0] setStringValue:@""];
    clearMatrix(voiceform);
  }
  if (ALLSAME(12, num)) [nostemswitch setThreeState:(ALLVAL(12) != 0)]; else [nostemswitch setThreeState:2];
  if (ALLSAME(13, num)) [[verseform cellAtIndex:0] setIntValue:ALLVAL(13)];
  else
  {
    [[verseform cellAtIndex:0] setStringValue:@""];
    clearMatrix(verseform);
  }
  if (ALLSAME(14, num)) [edaccbutton selectCellAtRow:0 column:ALLVAL(14)]; else clearMatrix(edaccbutton);
  if (ALLSAME(17, num)) [slashswitch setThreeState:(ALLVAL(17) != 0)]; else [slashswitch setThreeState:2];
  if (ALLSAME(11, num))
  {
      [definebutton selectItemAtIndex: ALLVAL(11) + 1];
      [self constructTuning: nil];
      if (ALLVAL(11) == 0)
        {
          if (ALLSAME(16, num)) selectPopFor(instbutton, instbutton, ALLVAL(16) + 1);//sb: was (midipopup, instbutton, ALLVAL(16) + 1)
          else selectPopFor(instbutton, instbutton, 0);//sb: was (midipopup, instbutton, 0)
        }
        else
        {
            if (ALLSAMEATOM(15, num)) selectPopNameFor(instbutton, instbutton, ALLVALATOM(15));//sb: was selectPopNameFor(instpopup, instbutton, ALLVALATOM(15));
            else selectPopFor(instbutton, instbutton, 0);//sb: was selectPopFor(instpopup, instbutton, 0);
        }
  }
  else
  {
      [definebutton selectItemAtIndex:0];
      if (whichlist == 0) selectPopFor(instbutton, instbutton, 0);//sb: was (midipopup, instbutton, 0)
      else selectPopFor(instbutton, instbutton, 0);//sb: was selectPopFor(instpopup, instbutton, 0);
  }
  return self;
}


- preset
{
  return [self updatePanel];
}


- presetTo: (int) n
{
  int w;
  GNote *p = [GNote myPrototype];
  [timematrix selectCellAtRow:0 column:n];
  [dotmatrix selectCellAtRow:0 column:0];
  [stylematrix selectCellWithTag:p->gFlags.subtype];
  [stemmatrix selectCellAtRow:0 column:!(p->time.stemup)];
  [nostemswitch setThreeState:p->time.nostem];
  [fixswitch setThreeState:p->time.stemfix];
  [[objmatrix cellAtRow:0 column:0] setThreeState:p->gFlags.locked];
  [[objmatrix cellAtRow:1 column:0] setThreeState:p->time.tight];
  [[voiceform cellAtIndex:0] setIntValue:p->voice];
  [[verseform cellAtIndex:0] setIntValue:p->versepos];
  [gracematrix selectCellAtRow:0 column:p->isGraced];
  [slashswitch setThreeState:p->showslash];
  w = [p whereInstrument];
  [definebutton selectItemAtIndex:w + 1];
  if (w == 0)
  {
      selectPopFor(instbutton, instbutton, [p getPatch]);//sb: was (midipopup, instbutton, [p getPatch])
  }
  else
  {
//    selectPopNameFor(instpopup, instbutton, [p getPart]);
  }
  return self;
}


/* called to choose where the tuning is defined */

NSString *partNameHavingPatch(int i)
{
  int j, k;
  CallPart *cp;
  NSMutableArray *pl = [NSApp getPartlist];
  k = [pl count];
  for (j = 0; j < k; j++)
  {
    cp = [pl objectAtIndex:j];
    if (i == [instlist soundForInstrument: cp->instrument]) return cp->name;
  }
  return nullPart;
}


- hitDefine: sender
{
  int num, w;
  GraphicView *v = [[DrawApp currentDocument] graphicView];
  [self constructTuning: nil];
  if (v == nil) return self;
  w = [definebutton indexOfSelectedItem] - 1;
  if (w < 0) return nil;
  [self assayList: v->slist : &num];
  if (num == 0) return nil;
  if (!ALLSAME(11, num))
  {
      if (whichlist == 0) selectPopFor(instbutton, instbutton, 0);//sb; was (midipopup, instbutton, 0)
      else selectPopFor(instbutton, instbutton, 0);//sb: was (instpopup, instbutton, 0)
  }
  if (w == 0) /* define by note's tuning */
  {
    if (ALLVAL(11) == 0) /* selection 'where' is by instrument */
    {
        if (ALLSAME(16, num)) selectPopFor(instbutton, instbutton, ALLVAL(16) + 1);//sb: was (midipopup, instbutton, ALLVAL(16) + 1)
        else selectPopFor(instbutton, instbutton, 0);//sb: was (midipopup, instbutton, 0)
    }
    else /* selection 'where' is by part */
    {
      if (ALLSAMEATOM(15, num))
      {
          selectPopFor(instbutton, instbutton,
                     [instlist soundForInstrument: [[NSApp getPartlist] instrumentForPart: ALLVALATOM(15)]] + 1);//sb: was (midipopup, ...
      }
        else selectPopFor(instbutton, instbutton, 0);//sb: was (midipopup, instbutton, 0)
    }
  }
  else /* define by a part */
  {
    if (ALLVAL(11) > 0)  /* selection 'where' is by part */
    {
        if (ALLSAMEATOM(15, num)) selectPopNameFor(instbutton, instbutton, ALLVALATOM(15));//sb: was (instpopup, instbutton, ALLVALATOM(15))
        else selectPopFor(instbutton, instbutton, 0);//sb: was (instpopup, instbutton, 0)
    }
    else /* selection 'where' is by instrument */
    {
      if (ALLSAME(16, num))
      {
          selectPopNameFor(instbutton, instbutton, partNameHavingPatch(ALLVAL(16)));//sb: was (instpopup, instbutton, partNameHavingPatch(ALLVAL(16)))
      }
        else selectPopFor(instbutton, instbutton, 0);//sb: was (instpopup, instbutton, 0)
    }
  }
  return self;
}

@end
