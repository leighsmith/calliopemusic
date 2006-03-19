#import "RangeInspector.h"
#import "Range.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "mux.h"
#import <AppKit/AppKit.h>


@implementation RangeInspector

- setClient: (Range *) p
{
  p->gFlags.subtype = [stylematrix selectedRow];
  p->line = [linematrix selectedRow];
  p->slant = [slantmatrix selectedRow];
  return self;
}


- setProto: sender
{
  return [self setClient: [Range myPrototype]];
}


- set:sender
{
  NSRect b;
  Range *p;
  id sl, v = [[DrawApp currentDocument] graphicView];
  int k;
  if ([v startInspection: RANGE : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == RANGE)
    {
      [self setClient: p];
      [p recalc];
    }
    [v endInspection: &b];
  }
  return self;
}


- updatePanel: (Range *) p
{
  [stylematrix selectCellAtRow:p->gFlags.subtype column:0];
  [linematrix selectCellAtRow:p->line column:0];
  [slantmatrix selectCellAtRow:p->slant column:0];
  return self;
}

- preset
{
  int n;
  GraphicView *v = [[DrawApp currentDocument] graphicView];
  Range *p = [v canInspect: RANGE : &n];
  if (n == 0) return nil;
  [self updatePanel: p];
  return self;
}

- presetTo: (int) i
{
  return [self updatePanel: [Range myPrototype]];
}

@end
