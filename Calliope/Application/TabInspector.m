#import "TabInspector.h"
#import "Tablature.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "GVPerform.h"
#import "CallInst.h"
#import "CallPart.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import <AppKit/AppKit.h>


@implementation TabInspector

static int wheretuning = -1;
static int myinstlist = -1;
static int mypartlist = -1;


/* given an instrument number, determine popup index */

int tuneIndex(int n)
{
  CallInst *ci;
  int i, t = 0;
  for (i = 0; i < n; i++)
  {
    ci = [instlist objectAtIndex:i];
    if (ci->istab) ++t;
  }
  return t;
}



/*
  if p is nonnull, use its 'where' to set w.
*/

- constructTuning
{
  CallInst *ci;
  NSMutableArray *pl;
  int i, k, w;
  w = [definebutton indexOfSelectedItem] - 1;
  switch(w)
  {
    case 0:  /* defined by note */
      if (wheretuning == w && myinstlist == instlistflag) return self;
      k = [tunepopup count];
      while (k--) [tunepopup removeItemAtIndex:k];
          [tunepopup addItemWithTitle:@"multiple selection"];
      k = [instlist count];
      for (i = 0; i < k; i++)
      {
        ci = [instlist objectAtIndex:i];
          if (ci->istab) [tunepopup addItemWithTitle:ci->name];
      }
      myinstlist = instlistflag;
      break;
    case 1:  /* defined by note's part */
    case 2:  /* defined by staff's part */
      if ((wheretuning == 1 || wheretuning == 2) && mypartlist == partlistflag) return self;
      k = [tunepopup count];
      while (k--) [tunepopup removeItemAtIndex:k];
          [tunepopup addItemWithTitle:@"multiple selection"];
      pl = [[CalliopeAppController sharedApplicationController] getPartlist];
      k = [pl count];
        for (i = 0; i < k; i++) [tunepopup addItemWithTitle:[pl partNameForInt: i]];
      mypartlist = partlistflag;
      break;
  }
  wheretuning = w;
  return self;
}


/* the new action when tuning button is pressed */

- makeTuneList: sender
{
  [self constructTuning];
//#error PopUpConversion: 'popUp:' is obsolete because it is no longer necessary.
//  [tunepopup popUp:sender];
  return self;
}


/* called during nib loading */

- setTunebutton: sender
{
  tunebutton = sender;
  tunepopup = [tunebutton target];
  [tunebutton setTarget:self];
  [tunebutton setAction:@selector(makeTuneList:)];
  /* no action/target required for tunepopup */
  return self;
}


/* set tuning based on where defined */

- defineTuning: (Tablature *) p
{
    int d = [definebutton indexOfSelectedItem] - 1;
  if (d < 0) return self;
  switch (d)
  {
    case 0:
        if (p->tuning) [p->tuning autorelease];
        p->tuning = [popSelectionNameFor(tunepopup) retain];
        break;
    case 1:
        if (p->tuning) [p->tuning autorelease];
        p->tuning = nil;
        if (p->part) [p->part autorelease];
        p->part = [popSelectionNameFor(tunepopup) retain];
      break;
    case 2:
        if (p->tuning) [p->tuning autorelease];
        if (p->part) [p->part autorelease];
      p->tuning = nil;
      p->part = nil;
      break;
  }
  return self;
}


/* set the prototype */

- setProto: sender
{
  int i;
  Tablature *p = [Tablature myPrototype];
  i = [bodymatrix selectedColumn];
  if (i >= 0) p->flags.body = i;
  i = [dirmatrix selectedColumn];
  if (i >= 0) p->flags.direction = i;
  i = [ciphermatrix selectedRow];
  if (i >= 0) p->flags.cipher = i;
  i = [facematrix selectedRow];
  if (i >= 0) p->flags.typeface = i;
  i = [placematrix selectedColumn];
  if (i >= 0) p->flags.online = i;
  [self defineTuning: p];
  return self;
}


/*
  do not allow the setting of a tablature that cannot be seen:
    flags or notes or both must be visible
*/

- set:sender
{
  NSRect b;
  Tablature *p;
  id sl, v = [CalliopeAppController currentView];
  int s, i, j, k, num, t;
  if ([v startInspection: TABLATURE : &b : &sl : &num])
  {
    s = [showmatrix selectedColumn];
    i = [timematrix selectedColumn];
    j = [dotmatrix selectedColumn];
    if (i >= 0 && j < 0) j = 0;
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == TABLATURE)
    {
      if (s >= 0)
      {
	if (s == 0 && [p tabCount] == 0)
	{
	  NSLog(@"TabInspector -set: s or tabCount == 0");
	  continue;
	}
        p->flags.prevtime = !s;
      }
      if (i >= 0)
      {
	p->time.body = i;
	[p setDottingCode: j];
      }
      if ([strumbutton state]) p->gFlags.subtype = 1 + [strummatrix selectedColumn];
      else
      {
        p->gFlags.subtype = 0;
        t = [bodymatrix selectedColumn];
        if (t >= 0) p->flags.body = t;
        t = [dirmatrix selectedColumn];
        if (t >= 0) p->flags.direction = t;
        t = [ciphermatrix selectedRow];
        if (t >= 0) p->flags.cipher = t;
        t = [facematrix selectedRow];
        if (t >= 0) p->flags.typeface = t;
        t = [placematrix selectedColumn];
        if (t >= 0) p->flags.online = t;
      }
      [self defineTuning: p];
      [p reShape];
    }
    [v endInspection: &b];
  }
  return self;
}


/* assaying attributes for sensible display on inspector */

- assayList: (NSMutableArray *) sl : (int *) num
{
  Tablature *p;
  int k, n;
  k = [sl count];
  initassay();
  n = 0;
  while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == TABLATURE)
  {
    ++n;
    assay(0, p->gFlags.subtype);
    assay(1, p->flags.prevtime);
    assay(2, p->time.body);
    assay(3, [p dottingCode]);
    assay(5, p->flags.body);
    assay(6, p->flags.direction);
    assay(7, p->flags.cipher);
    assay(8, p->flags.typeface);
    assay(9, (p->flags.online > 0));
//    assay(10, p->voice);
    assay(11, [p whereInstrument]);
//    assay(12, p->time.nostem);
//    assay(13, p->versepos);
//    assay(14, getEditorial(p, p->gFlags.selend));
    assayAsAtom(15, [p getPart]);
    assayAsAtom(16, [p getInstrument]);
  }
  *num = n;
  return self;
}

void setMatrix(int a, int num, int rv, int cv, NSMatrix *m)
{
  if (ALLSAME(a, num))  [m selectCellAtRow:rv column:cv]; else clearMatrix(m);
}


- updatePanel
{
  int b, num;
  GraphicView *v = [CalliopeAppController currentView];
  [self assayList: [v selectedGraphics] : &num];
  if (num == 0) return nil;
  if (ALLSAME(0, num)) /* strum */
  {
    if (ALLVAL(0))
    {
      [strumbutton setState:1];
      [strummatrix selectCellAtRow:0 column:ALLVAL(0) - 1];
      clearMatrix(ciphermatrix);
      clearMatrix(facematrix);
      clearMatrix(dirmatrix);
      clearMatrix(bodymatrix);
      clearMatrix(placematrix);
      clearMatrix(stylematrix);
      b = 0;
    }
    else
    {
      [strumbutton setState:0];
      clearMatrix(strummatrix);
      b = 1;
    }
  }
  else
  {
    [strumbutton setState:0]; /* ought to make 3-state */
    clearMatrix(strummatrix);
    b = 1;
  }
  [ciphermatrix setEnabled:b];
  [facematrix setEnabled:b];
  [dirmatrix setEnabled:b];
  [bodymatrix setEnabled:b];
  [placematrix setEnabled:b];
  [stylematrix setEnabled:b];
  [strummatrix setEnabled:!b];
  if (b)
  {
    setMatrix(5, num, 0, ALLVAL(5), bodymatrix);
    setMatrix(6, num, 0, ALLVAL(6), dirmatrix);
    setMatrix(7, num, ALLVAL(7), 0, ciphermatrix);
    setMatrix(8, num, ALLVAL(8), 0, facematrix);
    setMatrix(9, num, 0, ALLVAL(9), placematrix);
  }
  setMatrix(1, num, 0, !ALLVAL(1), showmatrix);
  setMatrix(2, num, 0, ALLVAL(2), timematrix);
  setMatrix(3, num, 0, ALLVAL(3), dotmatrix);
  if (ALLSAME(11, num))
  {
        [definebutton selectItemAtIndex:ALLVAL(11) + 1];
        [self constructTuning];
        if (ALLVAL(11) == 0)
        {
            if (ALLSAMEATOM(16, num)) selectPopNameFor(tunepopup, tunebutton, ALLVALATOM(16));
            else selectPopFor(tunepopup, tunebutton, 0);
        }
        else
        {
            if (ALLSAMEATOM(15, num)) selectPopNameFor(tunepopup, tunebutton, ALLVALATOM(15));
            else selectPopFor(tunepopup, tunebutton, 0);
        }
  }
  else
  {
      [definebutton selectItemAtIndex: 0];
    selectPopFor(tunepopup, tunebutton, 0);
  }
  return self;
}


- preset
{
  [self constructTuning];
  return [self updatePanel];
}


- presetTo: (int) i
{
  int w;
  NSString *pa;
  Tablature *p = [Tablature myPrototype];
  [timematrix selectCellAtRow:0 column:i];
  [dotmatrix selectCellAtRow:0 column:0];
  [bodymatrix selectCellAtRow:0 column:p->flags.body];
  [dirmatrix selectCellAtRow:0 column:p->flags.direction];
  [ciphermatrix selectCellAtRow:p->flags.cipher column:0];
  [facematrix selectCellAtRow:p->flags.typeface column:0];
  [placematrix selectCellAtRow:0 column:(p->flags.online > 0)];
  w = 0;
  [definebutton selectItemAtIndex:w + 1];
  [self constructTuning];
  pa = p->tuning;
  if (pa && [pa length]) selectPopNameFor(tunepopup, tunebutton, pa);
  else selectPopFor(tunepopup, tunebutton, 0);
  return self;
}


/* style shortcut: set appropriate for French/Italian */

- setstyle:sender
{
  switch([sender selectedRow])
  {
    case 0:
      [bodymatrix selectCellAtRow:0 column:4];
      [dirmatrix selectCellAtRow:0 column:0];
      [ciphermatrix selectCellAtRow:0 column:0];
      [placematrix selectCellAtRow:0 column:0];
      break;
    case 1:
      [dirmatrix selectCellAtRow:0 column:1];
      [bodymatrix selectCellAtRow:0 column:0];
      [ciphermatrix selectCellAtRow:1 column:0];
      break;
  }
  return self;
}

/*
  Called when a choice button is pushed.  Like preset, but does not
  preset the choice buttons.
*/

- setChoice: sender
{
  return self;
}


/* called to choose where the tuning is defined */


NSString *partNameHavingInst(NSString *i)
{
  int j, k;
  CallPart *cp;
  NSMutableArray *pl = [[CalliopeAppController sharedApplicationController] getPartlist];
  k = [pl count];
  for (j = 0; j < k; j++)
  {
    cp = [pl objectAtIndex:j];
      if ([cp->instrument isEqualToString:i]) return cp->name;
  }
  return nullPart;
}

- hitDefine: sender
{
  int num, w;
  NSMutableArray *pl;
  GraphicView *v = [CalliopeAppController currentView];
  [self constructTuning];
  if (v == nil) return self;
  w = [definebutton indexOfSelectedItem] - 1;
  if (w < 0) return nil;
  [self assayList: [v selectedGraphics] : &num];
  if (num == 0) return nil;
  if (!ALLSAME(11, num))
  {
    selectPopFor(tunepopup, tunebutton, 0);
    return self;
  }
  if (w == 0) /* define by note's tuning */
  {
    if (ALLVAL(11) == 0) /* selection 'where' is by instrument */
    {
      if (ALLSAMEATOM(16, num)) selectPopNameFor(tunepopup, tunebutton, ALLVALATOM(16));
      else selectPopFor(tunepopup, tunebutton, 0);
    }
    else /* selection 'where' is by part */
    {
      if (ALLSAMEATOM(15, num))
      {
        pl = [[CalliopeAppController sharedApplicationController] getPartlist];
        selectPopNameFor(tunepopup, tunebutton, [pl instrumentForPart: ALLVALATOM(15)]);
      }
      else selectPopFor(tunepopup, tunebutton, 0);
    }
  }
  else /* define by a part */
  {
    if (ALLVAL(11) > 0)  /* selection 'where' is by part */
    {
      if (ALLSAMEATOM(15, num)) selectPopNameFor(tunepopup, tunebutton, ALLVALATOM(15));
      else selectPopFor(tunepopup, tunebutton, 0);
    }
    else /* selection 'where' is by instrument */
    {
      if (ALLSAMEATOM(16, num))
      {
        selectPopNameFor(tunepopup, tunebutton, partNameHavingInst(ALLVALATOM(16)));
      }
      else selectPopFor(tunepopup, tunebutton, 0);
    }
  }
  return self;
}



@end
