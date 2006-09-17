
/* Generated by Interface Builder */

#import "AccentInspector.h"
#import "Accent.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "DrawingFunctions.h"
#import <AppKit/NSMatrix.h>
#import <AppKit/NSButton.h>
#import <Foundation/NSArray.h>


@implementation AccentInspector


- setProto: sender
{
  int n, s;
  Accent *p = [Accent myPrototype];
  p->gFlags.subtype = [placematrix selectedColumn];
  n = [nummatrix selectedColumn];
  s = [[typematrix selectedCell] tag];
  p->sign[n] = s;
  p->accstick = [accswitch state];
  return self;
}


- set:sender
{
  NSRect b;
  Accent *p;
  id sl, v = [DrawApp currentView];
  int k, n, s;
  if ([v startInspection: ACCENT : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == ACCENT)
    {
      p->xoff = p->yoff = 0.0;
      p->gFlags.subtype = [placematrix selectedColumn];
      n = [nummatrix selectedColumn];
      s = [[typematrix selectedCell] tag];
      if (p->sign[n] != s || p->accstick != [accswitch state])
      {
        p->sign[n] = s;
	p->gFlags.subtype = [p getDefault: n];
	p->xoff = 0.0;
	p->yoff = 0.0;
        p->accstick = [accswitch state];
        [placematrix selectCellAtRow:0 column:p->gFlags.subtype];
        [[nummatrix cellAtRow:0 column:n] setImage:[[typematrix selectedCell] image]];
      }
      [p recalc];
    }
    [v endInspection: &b];
  }
  return self;
}


- updatePanel: (Accent *) p
{
  int k = 4;
  [placematrix selectCellAtRow:0 column:p->gFlags.subtype];
  [nummatrix selectCellAtRow:0 column:0];
  [typematrix selectCellWithTag:p->sign[0]];
  [accswitch setState: p->accstick];
  while (k--) [[nummatrix cellAtRow:0 column:k] setImage:[[typematrix cellWithTag:p->sign[k]] image]];
  return self;
}


- preset
{
  Accent *p = [(GraphicView *)[DrawApp currentView] canInspect: ACCENT];
  if (p != nil) [self updatePanel: p];
  return self;
}


- presetTo: (int) i
{
  return [self updatePanel: [Accent myPrototype]];
}


- setdefault:sender
{
  NSRect b;
  Accent *p;
  id sl, v = [DrawApp currentView];
  int k;
  if ([v startInspection: ACCENT : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == ACCENT)
    {
      p->gFlags.subtype = [p getDefault: [nummatrix selectedColumn]];
      p->xoff = 0.0;
      p->yoff = 0.0;
      p->accstick = 0;
      [placematrix selectCellAtRow:0 column:p->gFlags.subtype];
      [p recalc];
    }
    [v endInspection: &b];
  }
  return self;
}


- setnumber:sender
{
  Accent *p = [(GraphicView *)[DrawApp currentView] canInspect: ACCENT];
  if (p != nil)
  {
    [typematrix selectCellWithTag:p->sign[[nummatrix selectedColumn]]];
    [placematrix selectCellAtRow:0 column:p->gFlags.subtype];
  }
  return self;
}

@end
