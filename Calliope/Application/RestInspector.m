#import "RestInspector.h"
#import "Rest.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "mux.h"
#import "muxlow.h"
#import "CalliopeThreeStateButton.h"
#import <AppKit/NSButton.h>
#import <AppKit/NSForm.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSGraphics.h>

extern short restoffs[4][10];
extern short prestoffs[10];

@implementation RestInspector


- setProto: sender
{
  Rest *p = [Rest myPrototype];
  p->style = [[stylematrix selectedCell] tag];
  p->voice = [[voiceform cellAtIndex:0] intValue];
  p->gFlags.locked = ([[objmatrix cellAtRow:0 column:0] threeState] == 1);
  p->isGraced = ([[objmatrix cellAtRow:1 column:0] threeState] == 1) ? 2 : 0;
  p->time.tight = ([[objmatrix cellAtRow:2 column:0] threeState] == 1);
  return self;
}

static char istimed[6] = {1, 1, 0, 0, 0, 1};

- set:sender
{
  NSRect b;
  Rest *p;
  id sl, v = [[NSApp currentDocument] graphicView];
  int i, k, selstyle, seltime, seldot, nb = 0, setdef;
  if ([choicematrix selectedRow] == 0)
  {
    nb = [[numbarsform cellAtIndex:0] intValue];
    if (nb < 1 || nb > 1000 || [stylematrix selectedColumn] < 2)
    {
      NSBeep();
      return self;
    }
  }
  if ([v startInspection: REST : &b : &sl])
  {
    selstyle = [[stylematrix selectedCell] tag];
    seltime = [timematrix selectedColumn];
    seldot = [dotmatrix selectedColumn];
    if (seltime >= 0 && seldot < 0) seldot = 0;
    if (!nb) [[numbarsform cellAtIndex:0] setIntValue:0];
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == REST)
    {
      setdef = 1000;
      if (selstyle >= 0)
      {
        if (selstyle != p->style) setdef = [p defaultPos];
        p->style = selstyle;
      } 
      if (istimed[selstyle] && seltime >= 0)
      {
        if (p->time.body != seltime) setdef = [p defaultPos];
        p->time.body = seltime;
        p->numbars = 0;
        p->time.dot = seldot;
      }
      if (!istimed[selstyle])
      {
        p->numbars = nb;
      }
      if ([voiceform indexOfSelectedItem] == 0) p->voice = [[voiceform cellAtIndex:0] intValue];
      i = [[objmatrix cellAtRow:0 column:0] threeState];
      if (i != 2) p->gFlags.locked = i;
      i = [[objmatrix cellAtRow:1 column:0] threeState];
      if (i != 2) p->isGraced = i * 2;
      i = [[objmatrix cellAtRow:2 column:0] threeState];
      if (i != 2) p->time.tight = i;
      if (setdef != 1000) p->p = [p defaultPos] + (p->p - setdef);
      [p reShape];
    }
    [v endInspection: &b];
  }
  return self;
}


/* assaying attributes for sensible display on inspector */

- assayList: (NSMutableArray *) sl : (int *) num
{
  Rest *p;
  int k, n;
  k = [sl count];
  initassay();
  n = 0;
  while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == REST)
  {
    ++n;
    assay(0, p->gFlags.locked);
    assay(1, (p->isGraced & 2));
    assay(2, p->time.tight);
    assay(3, p->time.body);
    assay(4, p->time.dot);
    assay(5, p->style);
    assay(6, p->voice);
    assay(7, istimed[(int)p->style]);
    assay(8, p->numbars);
  }
  *num = n;
  return self;
}




- updatePanel
{
  int a, c, num;
  GraphicView *v = [[NSApp currentDocument] graphicView];
  [self assayList: v->slist : &num];
  if (num == 0) return nil;
  for (a = 0; a < 3; a++)
  {
      if (ALLSAME(a, num)) [[objmatrix cellAtRow:a column:0] setThreeState:(ALLVAL(a) != 0)]; else [[objmatrix cellAtRow:a column:0] setThreeState:2];
  }
  if (ALLSAME(5, num)) [stylematrix selectCellAtRow:0 column:ALLVAL(5)]; else clearMatrix(stylematrix);
  if (ALLSAME(6, num)) [[voiceform cellAtIndex:0] setIntValue:ALLVAL(6)];
  else
  {
    [[voiceform cellAtIndex:0] setStringValue:@""];
    clearMatrix(voiceform);
  }
  clearMatrix(timematrix);
  clearMatrix(dotmatrix);
  [[numbarsform cellAtIndex:0] setStringValue:@""];
  if (ALLSAME(7,num))
  {
    [choicematrix selectCellAtRow:ALLVAL(7) column:0];
    c = [choicematrix selectedRow];
    for (a = 0; a < 5; a++) [[stylematrix cellAtRow:0 column:a] setEnabled:istimed[a] == c];
    if (c == 0)
    {
      [numbarsform setEnabled:YES];
      if (ALLSAME(8, num)) [[numbarsform cellAtIndex:0] setIntValue:ALLVAL(8)];
    }
    else
    {
      if (ALLSAME(3, num)) [timematrix selectCellAtRow:0 column:ALLVAL(3)];
      if (ALLSAME(4, num)) [dotmatrix selectCellAtRow:0 column:ALLVAL(4)];
      [numbarsform setEnabled:NO];
    }
  }
  else
  {
    clearMatrix(choicematrix);
  }
  return self;
}


- preset
{
  return [self updatePanel];
}


- presetTo: (int) i
{
  Rest *p = [Rest myPrototype];
  [[objmatrix cellAtRow:0 column:0] setThreeState:p->gFlags.locked];
  [[objmatrix cellAtRow:1 column:0] setThreeState:((p->isGraced & 2) != 0)];
  [[objmatrix cellAtRow:2 column:0] setThreeState:p->time.tight];
  [stylematrix selectCellWithTag:p->style];
  [[voiceform cellAtIndex:0] setIntValue:p->voice];
  if (istimed[(int)p->style])
  {
    [numbarsform setEnabled:NO];
    [timematrix selectCellAtRow:0 column:i];
    [dotmatrix selectCellAtRow:0 column:0];
  }
  else
  {
    [numbarsform setEnabled:YES];
    [[numbarsform cellAtIndex:0] setIntValue:p->numbars];
  }
  return self;
}

/*
  Called when a choice button is pushed.  Like preset, but does not
  preset the choice buttons.
*/

- setChoice: sender
{
  int c, a;
  c = [choicematrix selectedRow];
  clearMatrix(stylematrix);
  for (a = 0; a < 3; a++) [[objmatrix cellAtRow:a column: 0] setThreeState:0];
  for (a = 0; a < 5; a++) [[stylematrix cellAtRow:0 column:a] setEnabled:istimed[a] == c];
  if (c == 0)
  {
    [numbarsform setEnabled:YES];
    [[numbarsform cellAtIndex:0] setIntValue:1];
    [stylematrix selectCellAtRow:0 column:3];
    clearMatrix(timematrix);
    clearMatrix(dotmatrix);
  }
  else
  {
    [numbarsform setEnabled:NO];
    [stylematrix selectCellAtRow:0 column:0];
  }
  return self;
}

@end
