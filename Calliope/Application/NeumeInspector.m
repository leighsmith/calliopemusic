#import "NeumeInspector.h"
#import "NeumeNew.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "DrawingFunctions.h"
#import <AppKit/AppKit.h>
#import "CalliopeThreeStateButton.h"


@implementation NeumeInspector


- setClient: (NeumeNew *) p
{
  int i, j, n, a;
  char mat[5];
  i = [[typematrix selectedCell] tag];
  n = (i != p->gFlags.subtype);
  p->gFlags.subtype = i;
  if (i == PUNCTINC)
  {
    j = [incmatrix selectedColumn];
    if (j < 0) j = 0;
    p->nFlags.num = j;
  }
  for (i = 0; i <= 4; i++)
  {
    mat[i] = 0;
    for (j = 0; j <= 4; j++)
      if ([[accmatrix cellAtRow:i column:j] threeState]) mat[i] |=  (1 << j);
  }
  p->nFlags.dot = mat[0];
  p->nFlags.hepisema = mat[1];
  p->nFlags.vepisema = mat[2];
  p->nFlags.quilisma = mat[3];
  p->nFlags.molle = mat[4];
  a = [halfSizeSwitch intValue];
  if (a < 2) p->nFlags.halfSize = a;
  p->time.body = [bodymatrix selectedColumn];
  p->time.dot = [dotmatrix selectedColumn];
  return self;
}


- setProto: sender
{
  return [self setClient: [NeumeNew myPrototype]];
}


- set:sender
{
  NSRect bb;
  NeumeNew *p;
  id sl, v = [DrawApp currentView];
  int a, b, j, k, n = 0, seltype;
  if ([v startInspection: NEUMENEW : &bb : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == NEUMENEW)
    {
      for (j = 0; j <= 4; j++)
      {
        b = (1 << j);
          a = [[accmatrix cellAtRow:0 column:j] threeState];
	if (a == 1) p->nFlags.dot |= b;
	else if (a == 0) p->nFlags.dot &= ~b;
        a = [[accmatrix cellAtRow:1 column:j] threeState];
        if (a == 1) p->nFlags.hepisema |= b;
	else if (a == 0) p->nFlags.hepisema &= ~b;
        a = [[accmatrix cellAtRow:2 column:j] threeState];
        if (a == 1) p->nFlags.vepisema |= b;
	else if (a == 0) p->nFlags.vepisema &= ~b;
        a = [[accmatrix cellAtRow:3 column:j] threeState];
        if (a == 1) p->nFlags.quilisma |= b;
	else if (a == 0) p->nFlags.quilisma &= ~b;
        a = [[accmatrix cellAtRow:4 column:j] threeState];
        if (a == 1) p->nFlags.molle |= b;
	else if (a == 0) p->nFlags.molle &= ~b;
      }
        a = [halfSizeSwitch intValue];
        if (a < 2) p->nFlags.halfSize = a;
        
      seltype = [typematrix selectedColumn];
      if (seltype >= 0)
      {
        j = [[typematrix selectedCell] tag];
        n = (j != p->gFlags.subtype);
	p->gFlags.subtype = j;
      }
      j = [incmatrix selectedColumn];
      if (j >= 0) p->nFlags.num = j;
      j = [bodymatrix selectedColumn];
      if (j >= 0) p->time.body = j;
      j = [dotmatrix selectedColumn];
      if (j >= 0) p->time.dot = j;
      if (n) [p setNeume];
      [p reShape];
    }
    [v endInspection: &bb];
  }
  return self;
}


/* assaying attributes for sensible display on inspector */

- assayList: (NSMutableArray *) sl : (int *) num
{
  NeumeNew *p;
  int c, j, k, n;
  k = [sl count];
  initassay();
  n = 0;
  while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == NEUMENEW)
  {
    ++n;
    for (j = 0; j <= 4; j++)
    {
      c = j * 5;
      assay(c + 0, (p->nFlags.dot >> j) & 1);
      assay(c + 1, (p->nFlags.hepisema >> j) & 1);
      assay(c + 2, (p->nFlags.vepisema >> j) & 1);
      assay(c + 3, (p->nFlags.quilisma >> j) & 1);
      assay(c + 4, (p->nFlags.molle >> j) & 1);
    }
    assay(25, p->gFlags.subtype);//sb was 20...
    assay(26, p->nFlags.num);
    assay(27, p->time.body);
    assay(28, p->time.dot);
    assay(29, p->nFlags.halfSize);
  }
  *num = n;
  return self;
}


- updatePanel
{
  int a, i, j, num, v;
  GraphicView *gv = [DrawApp currentView];
  [self assayList: [gv selectedGraphics] : &num];
  if (num == 0) return nil;
  for (i = 0; i <= 4; i++) for (j = 0; j <= 4; j++)
  {
    a = j * 5 + i;
    if (ALLSAME(a, num)) v = (ALLVAL(a) != 0); else v = 2;
    [[accmatrix cellAtRow:i column:j] setThreeState:v];
  }
  if (ALLSAME(25, num)) [typematrix selectCellWithTag:ALLVAL(25)]; else clearMatrix(typematrix);
  if (ALLVAL(25) == PUNCTINC && ALLSAME(26, num)) [incmatrix selectCellAtRow:0 column:ALLVAL(26)];
  else clearMatrix(incmatrix);
  if (ALLSAME(27, num)) [bodymatrix selectCellAtRow:0 column:ALLVAL(27)]; else clearMatrix(bodymatrix);
  if (ALLSAME(28, num)) [dotmatrix selectCellAtRow:0 column:ALLVAL(28)];else clearMatrix(dotmatrix);
  if (ALLSAME(29, num)) [halfSizeSwitch setIntValue:ALLVAL(29)];else [halfSizeSwitch setIntValue:2];
  return self;
}


- preset
{
  return [self updatePanel];
}


- presetTo: (int) i
{
  int j;
  NeumeNew *p = [NeumeNew myPrototype];
  for (j = 0; j <= 4; j++)
  {
      [[accmatrix cellAtRow:0 column:j] setThreeState:(p->nFlags.dot >> j) & 1];
      [[accmatrix cellAtRow:1 column:j] setThreeState:(p->nFlags.hepisema >> j) & 1];
      [[accmatrix cellAtRow:2 column:j] setThreeState:(p->nFlags.vepisema >> j) & 1];
      [[accmatrix cellAtRow:3 column:j] setThreeState:(p->nFlags.quilisma >> j) & 1];
      [[accmatrix cellAtRow:4 column:j] setThreeState:(p->nFlags.molle >> j) & 1];
  }
  [typematrix selectCellWithTag:p->gFlags.subtype];
  if (p->gFlags.subtype == PUNCTINC) [incmatrix selectCellAtRow:0 column:p->nFlags.num]; else clearMatrix(incmatrix);
  [bodymatrix selectCellAtRow:0 column:p->time.body];
  [dotmatrix selectCellAtRow:0 column:p->time.dot];
  [halfSizeSwitch setState: p->nFlags.halfSize];
  return self;
}

@end
