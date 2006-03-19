
#import "EnclosureInspector.h"
#import "Enclosure.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "DrawDocument.h"
#import "DrawApp.h"
#import <AppKit/NSMatrix.h>
#import <Foundation/NSArray.h>
#import "mux.h"

@implementation EnclosureInspector


- setProto: sender
{
  Enclosure *p = [Enclosure myPrototype];
  p->gFlags.subtype = [typematrix selectedColumn];
  p->gFlags.locked = [fixmatrix selectedColumn];
  return self;
}


- set:sender
{
  NSRect b;
  Enclosure *p;
  id sl, v = [[DrawApp currentDocument] graphicView];
  int k;
  if ([v startInspection: ENCLOSURE : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == ENCLOSURE)
    {
      p->gFlags.subtype = [typematrix selectedColumn];
      p->gFlags.locked = [fixmatrix selectedColumn];
      [p setHanger];
    }
    [v endInspection: &b];
  }
  return self;
}


- preset
{
  int n;
  GraphicView *v = [[DrawApp currentDocument] graphicView];
  Enclosure *p = [v canInspect: ENCLOSURE : &n];
  if (n)
  {
    [typematrix selectCellAtRow:0 column:p->gFlags.subtype];
    [fixmatrix selectCellAtRow:0 column:p->gFlags.locked];
  }
  return self;
}

- presetTo: (int) i
{
  Enclosure *p = [Enclosure myPrototype];
  [typematrix selectCellAtRow:0 column:p->gFlags.subtype];
  [fixmatrix selectCellAtRow:0 column:p->gFlags.locked];
  return self;
}

@end
