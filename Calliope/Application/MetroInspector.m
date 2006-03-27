#import "MetroInspector.h"
#import "Metro.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "mux.h"
#import <AppKit/AppKit.h>

@implementation MetroInspector


- setClient: (Metro *) p
{
  p->gFlags.subtype = [typematrix selectedRow];
  p->body[0] = [note1matrix selectedColumn];
  p->dot[0] = [dot1matrix selectedColumn];
  if (p->gFlags.subtype) p->ticks = [[tempoform cellAtIndex:0] intValue];
  else
  {
    p->body[1] = [note2matrix selectedColumn];
    p->dot[1] = [dot2matrix selectedColumn];
  }
  return self;
}


- setProto: sender
{
  return [self setClient: [Metro myPrototype]];
}


- set:sender
{
  NSRect b;
  Metro *p;
  id sl, v = [DrawApp currentView];
  int k;
  if ([v startInspection: METRO : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == METRO)
    {
      [self setClient: p];
      [p recalc];
    }
    [v endInspection: &b];
  }
  return self;
}


- updatePanel: (Metro *) p
{
  if ([typematrix selectedRow])
  {
    clearMatrix(note2matrix);
    clearMatrix(dot2matrix);
    [tempoform setEnabled:YES];
    [[tempoform cellAtIndex:0] setIntValue:p->ticks];
  }
  else
  {
    [tempoform setEnabled:NO];
    [note2matrix selectCellAtRow:p->body[1] column:0];
    [dot2matrix selectCellAtRow:p->dot[1] column:0];
  }
  return self;
}

- hitNote2:sender
{
    Metro *p = [(GraphicView *)[DrawApp currentView] canInspect: METRO];
    if (p)
      {
        if ([typematrix selectedRow]) {
            [tempoform setEnabled:NO];
            [typematrix selectCellAtRow:0 column:0];
        }
        [self makeFirstResponder:setButton];
      }
    return self;
}

- preset
{
    Metro *p = [(GraphicView *)[DrawApp currentView] canInspect: METRO];
  if (p)
  {
    [note1matrix selectCellAtRow:0 column:p->body[0]];
    [dot1matrix selectCellAtRow:0 column:p->dot[0]];
    [typematrix selectCellAtRow:p->gFlags.subtype column:0];
    [self updatePanel: p];
  }
  return self;
}

- presetTo: (int) i
{
  Metro *p = [Metro myPrototype];
  [note1matrix selectCellAtRow:0 column:p->body[0]];
  [dot1matrix selectCellAtRow:0 column:p->dot[0]];
  [typematrix selectCellAtRow:p->gFlags.subtype column:0];
  [self updatePanel: p];
  return self;
}

- setChoice: sender
{
    Metro *p = [(GraphicView *)[DrawApp currentView] canInspect: METRO];
  if (p) [self updatePanel: p];
  return self;
}

@end
