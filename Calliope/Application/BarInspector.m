#import "BarInspector.h"
#import "Barline.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "GVCommands.h"
#import "DrawDocument.h"
#import "DrawApp.h"
#import "Staff.h"
#import "System.h"
#import <AppKit/NSMatrix.h>
#import <AppKit/NSButton.h>
#import <Foundation/NSArray.h>
#import "mux.h"
#import "CalliopeThreeStateButton.h"


@implementation BarInspector


- (int) setClient: (Barline *) p
{
  int i;
  int r = 0;
  if ([typematrix selectedColumn] >= 0) p->gFlags.subtype = [[typematrix selectedCell] tag];
  i = [[buttonmatrix cellAtRow:0 column:0] threeState];
  if (i != 2) p->flags.staff = i;
  i = [[buttonmatrix cellAtRow:1 column:0] threeState];
  if (i != 2) p->flags.bridge = i;
  i = [[buttonmatrix cellAtRow:2 column:0] threeState];
  if (i != 2) p->flags.editorial = i;
  i = [[buttonmatrix cellAtRow:3 column:0] threeState];
  if (i != 2) p->flags.dashed = i;
  i = [[buttonmatrix cellAtRow:4 column:0] threeState];
  if (i != 2)
  {
    if (p->flags.nocount != i) r |= 1;
    p->flags.nocount = i;
  }
  i = [numbermatrix selectedRow];
  if (i >= 0)
  {
    if (p->flags.nonumber != i) r |= 2;
    p->flags.nonumber = i;
  }
  return r;
}


- setProto: sender
{
  [self setClient: [Barline myPrototype]];
  return self;
}


/* called when SET is pushed */

- set:sender
{
  NSRect b;
  Barline *p;
  id sl, v = [[NSApp currentDocument] graphicView];
  int k;
  int r = 0;
  if ([v startInspection: BARLINE : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == BARLINE)
    {
      r |= [self setClient: p];
      [p recalc];
    }
    [v endInspection: &b];
  }
  if (r & 1) [v renumber: v];
  if (r & 2) {
      [v setNeedsDisplay:YES];
  }
  return self;
}


/* assaying attributes for sensible display on inspector */

- assayList: (NSMutableArray *) sl : (int *) num
{
  Barline *p;
  int k, n;
  k = [sl count];
  initassay();
  n = 0;
  while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == BARLINE)
  {
    ++n;
    assay(0, p->flags.staff);
    assay(1, p->flags.bridge);
    assay(2, p->flags.editorial);
    assay(3, p->flags.dashed);
    assay(4, p->flags.nocount);
    assay(5, p->flags.nonumber);
    assay(6, p->gFlags.subtype);
  }
  *num = n;
  return self;
}


/* called when panel is opened.  Load values from inspector */

- preset
{
  int num, a;
  GraphicView *v = [[NSApp currentDocument] graphicView];
  [self assayList: v->slist : &num];
  if (num == 0) return self;
  for (a = 0; a <= 4; a++)
  {
    if (ALLSAME(a, num)) [[buttonmatrix cellAtRow:a column:0] setThreeState:(ALLVAL(a) != 0)];
      else [[buttonmatrix cellAtRow:a column:0] setThreeState:2];
  }
  if (ALLSAME(5, num)) [numbermatrix selectCellAtRow:ALLVAL(5) column:0];
  else clearMatrix(numbermatrix);
  if (ALLSAME(6, num)) [typematrix selectCellWithTag:ALLVAL(6)];
  else clearMatrix(typematrix);
  return self;
}


- presetTo: (int) i
{
  Barline *p = [Barline myPrototype];
    [[buttonmatrix cellAtRow:0 column:0] setThreeState:p->flags.staff];
    [[buttonmatrix cellAtRow:1 column:0] setThreeState:p->flags.bridge];
    [[buttonmatrix cellAtRow:2 column:0] setThreeState:p->flags.editorial];
    [[buttonmatrix cellAtRow:3 column:0] setThreeState:p->flags.dashed];
    [[buttonmatrix cellAtRow:4 column:0] setThreeState:p->flags.nocount];
  [numbermatrix selectCellAtRow:p->flags.nonumber column:0];
  [typematrix selectCellWithTag:p->gFlags.subtype];
  return self;
}


@end
