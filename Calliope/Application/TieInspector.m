#import "TieInspector.h"
#import "TieNew.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "mux.h"
#import <AppKit/NSMatrix.h>
#import <AppKit/NSButton.h>
#import <Foundation/NSArray.h>


/*
  This inspector has a matrix in which the cells' titles change.
*/


@implementation TieInspector


- setClient: (TieNew *) p
{
  p->gFlags.subtype = [[stylematrix selectedCell] tag];
  p->flags.ed = [edbutton state];
  p->flags.fixed = [fixmatrix selectedColumn];
  p->flags.place = [placematrix selectedColumn];
  p->flags.flat = [flatmatrix selectedColumn];
  p->flags.dashed = [dashbutton state];
  return self;
}


- setProto: sender
{
  return [self setClient: [TieNew myPrototype]];
}



- set:sender
{
  NSRect b;
  TieNew *p;
  id sl, v = [DrawApp currentView];
  int k;
  if ([v startInspection: TIENEW : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == TIENEW)
    {
      [self setClient: p];
      [p setHanger];
    }
    [v endInspection: &b];
  }
  return self;
}


- updatePanel
{
  int c = [[stylematrix selectedCell] tag];
  if (c == 0)
  {
      [[placematrix cellAtRow:0 column:0] setTitle:@"head"];
      [[placematrix cellAtRow:0 column:1] setTitle:@"opp"];
  }
  else
  {
      [[placematrix cellAtRow:0 column:0] setTitle:@"above"];
      [[placematrix cellAtRow:0 column:1] setTitle:@"below"];
  }
  return self;
}


- preset: (TieNew *) p
{
  [stylematrix selectCellWithTag:p->gFlags.subtype];
  [self updatePanel];
  [edbutton setState:p->flags.ed];
  [fixmatrix selectCellAtRow:0 column:p->flags.fixed];
  [flatmatrix selectCellAtRow:0 column:p->flags.flat];
  [placematrix selectCellAtRow:0 column:p->flags.place];
  [dashbutton setState:p->flags.dashed];
  return self;
}


- preset
{
    TieNew *p = [(GraphicView *)[DrawApp currentView] canInspect: TIENEW];
  if (p != nil) [self preset: p];
  return self;
}


- presetTo: (int) i
{
  [self preset: [TieNew myPrototype]];
  return self;
}


/* called when style is changed:
      disables unavailable options and sets default options
*/

- setImageFrameStyle:sender
{
    TieNew *p = [(GraphicView *)[DrawApp currentView] canInspect: TIENEW];
  if (p == nil) return self;
  [p setDefault: [[stylematrix selectedCell] tag]];
  [fixmatrix selectCellAtRow:0 column:p->flags.fixed];
  [placematrix selectCellAtRow:0 column:p->flags.place];
  return [self updatePanel];
}

@end
