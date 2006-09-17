#import "LigatureInspector.h"
#import "Ligature.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "DrawingFunctions.h"
#import <AppKit/NSMatrix.h>
#import <AppKit/NSButton.h>
#import <Foundation/NSArray.h>


/*
  This inspector has a matrix in which the cells' titles change.
*/


@implementation LigatureInspector


- setClient: (Ligature *) p
{
  p->gFlags.subtype = [[stylematrix selectedCell] tag];
  p->flags.ed = [edbutton state];
  p->flags.fixed = [fixmatrix selectedColumn];
  p->flags.place = [placematrix selectedColumn];
  p->flags.dashed = [dashbutton state];
  return self;
}


- setProto: sender
{
  return [self setClient: [Ligature myPrototype]];
}



- set:sender
{
  NSRect b;
  Ligature *p;
  id sl, v = [DrawApp currentView];
  int k;
  if ([v startInspection: LIGATURE : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == LIGATURE)
    {
      [self setClient: p];
      [p setHanger];
    }
    [v endInspection: &b];
  }
  return self;
}




- preset
{
    Ligature *p = [(GraphicView *)[DrawApp currentView] canInspect: LIGATURE];
  if (p == nil) return self;
  [stylematrix selectCellWithTag:p->gFlags.subtype];
  [edbutton setState:p->flags.ed];
  [fixmatrix selectCellAtRow:0 column:p->flags.fixed];
  [placematrix selectCellAtRow:0 column:p->flags.place];
  [dashbutton setState:p->flags.dashed];
  return self;
}


- presetTo: (int) i
{
  Ligature *p = [Ligature myPrototype];
  [stylematrix selectCellWithTag:p->gFlags.subtype];
  [edbutton setState:p->flags.ed];
  [fixmatrix selectCellAtRow:0 column:p->flags.fixed];
  [placematrix selectCellAtRow:0 column:p->flags.place];
  [dashbutton setState:p->flags.dashed];
  return self;
}


@end
