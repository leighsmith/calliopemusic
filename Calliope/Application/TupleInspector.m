#import "TupleInspector.h"
#import "Tuple.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "DrawingFunctions.h"
#import <AppKit/NSMatrix.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSForm.h>

#import <Foundation/NSArray.h>


@implementation TupleInspector:NSPanel


- (BOOL) panelConsistent
{
  int choice;
  BOOL r = YES;
  choice = [uneqmatrix selectedRow];
  if (choice < 0) r = NO;
  else switch(choice)
  {
    case 0:
      if ([[ntupleform cellAtIndex:0] intValue] <= 0) r = NO;
      break;
    case 1:
      if ([[ratnumform cellAtIndex:0] intValue] <= 0) r = NO;
      if ([[ratdenform cellAtIndex:0] intValue] <= 0) r = NO;
      break;
    case 2:
      if ([notematrix selectedColumn] < 0) r = NO;
      else
      {
        if ([dotmatrix selectedColumn] < 0) [dotmatrix selectCellAtRow:0 column:0];
      }
      if ([dotmatrix selectedColumn] < 0) r = NO;
      break;
  }
  return r;
}


- setClient: (Tuple *) p
{
  int i = [uneqmatrix selectedRow];
  p->gFlags.subtype = i + 1;
  switch(i)
  {
    case 0:
      p->uneq1 = [[ntupleform cellAtIndex:0] intValue];
      p->flags.centre = [centrematrix selectedRow];
      break;
    case 1:
      p->uneq1 = [[ratnumform cellAtIndex:0] intValue];
      p->uneq2 = [[ratdenform cellAtIndex:0] intValue];
      break;
  }
  p->body = 0;
  if ([notematrix selectedColumn] >= 0)
  {
    p->body = [notematrix selectedColumn] + 1;
    i = [dotmatrix selectedColumn];
    p->dot = (i >= 0) ? i : 0;
  }
  p->flags.fixed = [freematrix selectedColumn];
  p->flags.formliga = [brackmatrix selectedColumn];
  p->flags.horiz = [horizbutton state];
  return self;
}


- setProto: sender
{
  return [self setClient: [Tuple myPrototype]];
}


- set:sender
{
  NSRect b;
  NSMutableArray *sl;
  GraphicView *v = [CalliopeAppController currentView];
  Tuple *p;
  int k;
  if ([v startInspection: TUPLE : &b : &sl])
  {
    if (![self panelConsistent]) NSLog(@"TupleInspector panel not consistent");
    else
    {
      k = [sl count];
      while (k--) if ((p = [sl objectAtIndex:k]) && [p graphicType] == TUPLE && p->style == 0)
      {
	[self setClient: p];
        [p ligaDir: [hdtlmatrix selectedColumn]]; /* does the recalc */
      }
    }
  }
  [v endInspection: &b];
  return self;
}


/*
  set whether enabled enabled[cell][style]
  order: ntupleform, ratnumform+ratdenform, note+dotmatrix, brackmatrix
*/

static char enabled[3][4] =
{
  {1, 0, 0, 1}, /* tuple */
  {0, 1, 0, 1}, /* ratio */
  {0, 0, 1, 1}, /* duration */
};


- setEnabledFor: (int) c
{
    [ntupleform setEnabled:enabled[c][0]];
    [centrematrix setEnabled:enabled[c][0]];
  [ratnumform setEnabled:enabled[c][1]];
  [ratdenform setEnabled:enabled[c][1]];
  [brackmatrix setEnabled:enabled[c][3]];
  if (!enabled[c][3]) clearMatrix(brackmatrix);
  return self;
}


- updatePanel: (Tuple *) p
{
  int c = p->gFlags.subtype - 1;
  [uneqmatrix selectCellAtRow:c column:0];
  if (p->body)
  {
    [notematrix selectCellAtRow:0 column:p->body - 1];
    [dotmatrix selectCellAtRow:0 column:p->dot];
  }
  else
  {
    clearMatrix(notematrix);
    clearMatrix(dotmatrix);
  }
  switch(c)
  {
    case 0:
      [[ntupleform cellAtIndex:0] setIntValue:p->uneq1];
      [centrematrix selectCellAtRow:p->flags.centre column:0];
      break;
    case 1:
      [[ratnumform cellAtIndex:0] setIntValue:p->uneq1];
      [[ratdenform cellAtIndex:0] setIntValue:p->uneq2];
      break;
  }
  [freematrix selectCellAtRow:0 column:p->flags.fixed];
  [hdtlmatrix selectCellAtRow:0 column:p->flags.localiga];
  [horizbutton setState:p->flags.horiz];
  if (enabled[c][3]) [brackmatrix selectCellAtRow:0 column:p->flags.formliga];
  return self;
}


- setChoice: sender
{
    int c;
    Tuple *p = [[CalliopeAppController currentView] canInspect: TUPLE];
  if (p == nil) return self;
  c = [uneqmatrix selectedRow];
  [self setEnabledFor: c];
  if (c == p->gFlags.subtype - 1) [self updatePanel: p];

  return self;
}


- clearTime: sender
{
  clearMatrix(notematrix);
  clearMatrix(dotmatrix);
  return self;
}


- preset
{
    Tuple *p = [[CalliopeAppController currentView] canInspect: TUPLE];
  if (p == nil || p->style != 0) return self;
  [self setEnabledFor: p->gFlags.subtype - 1];
  [self updatePanel: p];
  return self;
}


- presetTo: (int) i
{
  return  [self updatePanel: [Tuple myPrototype]];
}

@end
