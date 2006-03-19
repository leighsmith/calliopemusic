#import "SquareNoteInspector.h"
#import "SquareNote.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "mux.h"
#import "muxlow.h"
#import <AppKit/NSButton.h>
#import <AppKit/NSForm.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSGraphics.h>

@implementation SquareNoteInspector


- setProto: sender
{
  SquareNote *p = [SquareNote myPrototype];
  p->time.body = [timematrix selectedColumn];
  p->time.dot = [dotmatrix selectedColumn];
  p->shape = [shapematrix selectedColumn];
  p->colour = [colourmatrix selectedColumn];
  p->stemside = [stemmatrix selectedColumn];
  p->gFlags.subtype = [desmatrix selectedColumn];
  return self;
}


- set:sender
{
  NSRect b;
  SquareNote *p;
  id sl, v = [[DrawApp currentDocument] graphicView];
  int k, selshape, selcol, selstem, seltime, seldot, seldes;
  if ([v startInspection: SQUARENOTE : &b : &sl])
  {
    seltime = [timematrix selectedColumn];
    seldot = [dotmatrix selectedColumn];
    selshape = [shapematrix selectedColumn];
    selcol = [colourmatrix selectedColumn];
    selstem = [stemmatrix selectedColumn];
    seldes =  [desmatrix selectedColumn];
    if (seltime >= 0 && seldot < 0) seldot = 0;
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == SQUARENOTE)
    {
      if (seltime >= 0)
      {
	p->time.body = seltime;
	p->time.dot = seldot;
      }
      if (selshape >= 0) p->shape = selshape;
      if (selcol >= 0) p->colour = selcol;
      if (selstem >= 0) p->stemside = selstem;
      if (seldes >= 0) p->gFlags.subtype = seldes;
      [p reShape];
    }
    [v endInspection: &b];
  }
  return self;
}


/* assaying attributes for sensible display on inspector */

- assayList: (NSMutableArray *) sl : (int *) num
{
  SquareNote *p;
  int k, n;
  k = [sl count];
  initassay();
  n = 0;
  while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == SQUARENOTE)
  {
    ++n;
    assay(0, p->shape);
    assay(1, p->colour);
    assay(2, p->stemside);
    assay(3, p->time.body);
    assay(4, p->time.dot);
    assay(5, p->gFlags.subtype);
  }
  *num = n;
  return self;
}



- updatePanel
{
  int num;
  GraphicView *v = [[DrawApp currentDocument] graphicView];
  [self assayList: v->slist : &num];
  if (num == 0) return nil;
  clearMatrix(timematrix);
  clearMatrix(dotmatrix);
  if (ALLSAME(0, num)) [shapematrix selectCellAtRow:0 column:ALLVAL(0)]; else clearMatrix(shapematrix);
  if (ALLSAME(1, num)) [colourmatrix selectCellAtRow:0 column:ALLVAL(1)]; else clearMatrix(colourmatrix);
  if (ALLSAME(2, num)) [stemmatrix selectCellAtRow:0 column:ALLVAL(2)]; else clearMatrix(stemmatrix);
  if (ALLSAME(3, num)) [timematrix selectCellAtRow:0 column:ALLVAL(3)]; else clearMatrix(timematrix);
  if (ALLSAME(4, num)) [dotmatrix selectCellAtRow:0 column:ALLVAL(4)]; else clearMatrix(dotmatrix);
  if (ALLSAME(5, num)) [desmatrix selectCellAtRow:0 column:ALLVAL(5)]; else clearMatrix(desmatrix);
  return self;
}


- preset
{
  [self updatePanel];
  return self;
}


- presetTo: (int) i
{
  SquareNote *p = [SquareNote myPrototype];
  [shapematrix selectCellAtRow:0 column:p->shape];
  [colourmatrix selectCellAtRow:0 column:p->colour];
  [stemmatrix selectCellAtRow:0 column:p->stemside];
  [timematrix selectCellAtRow:0 column:p->time.body];
  [dotmatrix selectCellAtRow:0 column:p->time.dot];
  [desmatrix selectCellAtRow:0 column:p->gFlags.subtype];
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

@end
