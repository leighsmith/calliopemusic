#import "BeamInspector.h"
#import "Beam.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "MultiView.h"
#import "GVSelection.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import <AppKit/NSMatrix.h>
#import <AppKit/NSButton.h>
#import <Foundation/NSArray.h>

@implementation BeamInspector

- setView: (int) i
{
Beam *p = [(GraphicView *)[DrawApp currentView] canInspect: BEAM];
  if (p == nil) return [multiview replaceView: blankview];
  switch(i)
  {
    case -1:
    case 0:
      [multiview replaceView: layoutview];
      break;
    case 1:
      [multiview replaceView: brokenview];
      break;
    case 2:
      [multiview replaceView: tremview];
      break;
    case 3:
      [multiview replaceView: taperview];
      break;
  }
  return self;
}


- setPanel: (int) i
{
Beam *p = [(GraphicView *)[DrawApp currentView] canInspect: BEAM];
  if (p == nil) return self;
  switch(i)
  {
    case 0:
      [horizbutton setState:p->flags.horiz];
      [slashbutton setState:p->flags.dir];
      [freematrix selectCellAtRow:0 column:[p beamType]];
      break;
    case 1:
      if (p->flags.broken)
      {
        [brokebutton setState:YES];
        [timematrix selectCellAtRow:0 column:p->flags.body - 1];
        [dotmatrix selectCellAtRow:0 column:p->flags.dot];
      }
      else
      {
        [brokebutton setState:NO];
        clearMatrix(timematrix);
        clearMatrix(dotmatrix);
      }
      break;
    case 2:
      [tremmatrix selectCellAtRow:0 column:p->gFlags.subtype];
      break;
    case 3:
      [taperbutton selectCellAtRow:0 column:p->flags.taper];
      break;
  }
  return self;
}


- hitChoice: sender
{
    int i = [choicebutton indexOfSelectedItem];
  [self setPanel: i];
  [self setView: i];
  return self;
}


- setBroken: sender
{
  Beam *p;
  if ([brokebutton state])
  {
  p = [(GraphicView *)[DrawApp currentView] canInspect: BEAM];
    [timematrix selectCellAtRow:0 column:p->flags.body - 1];
    [dotmatrix selectCellAtRow:0 column:p->flags.dot];
  }
  else
  {
    clearMatrix(timematrix);
    clearMatrix(dotmatrix);
  }
  return self;
}


- (BOOL) panelConsistent
{
  BOOL r = YES;
  if ([brokebutton state])
  {
    if ([timematrix selectedColumn] < 0) r = NO;
    else
    {
      if ([dotmatrix selectedColumn] < 0) [dotmatrix selectCellAtRow:0 column:0];
    }
    if ([dotmatrix selectedColumn] < 0) r = NO;
  }
  return r;
}


- setClient: (Beam *) p
{
  int i = [brokebutton state];
  p->flags.broken = i;
  if (i)
  {
    p->flags.body = [timematrix selectedColumn] + 1;
    p->flags.dot = [dotmatrix selectedColumn];
  }
  p->gFlags.subtype = [tremmatrix selectedColumn];
  p->flags.horiz = [horizbutton state];
  p->flags.dir = [slashbutton state];
  p->flags.taper = [taperbutton selectedColumn];
  return self;
}


- setProto: sender
{
  return [self setClient: [Beam myPrototype]];
}


- set:sender
{
  NSRect b;
  NSMutableArray *sl;
  GraphicView *v = [DrawApp currentView];
  Beam *p;
  int k;
  if ([v startInspection: BEAM : &b : &sl])
  {
    if (![self panelConsistent]) NSLog(@"BeamInspector panel not consistent");
    else
    {
      k = [sl count];
      while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == BEAM)
      {
	[self setClient: p];
	[p setBeamDir: [freematrix selectedColumn]]; /* does reset and recalc */
      }
    }
  }
  [v endInspection: &b];
  return self;
}


- preset
{
  [self hitChoice: self];
  return self;
}


- presetTo: (int) i
{
  Beam *p = [Beam myPrototype];
  [brokebutton setState:p->flags.broken];
  [horizbutton setState:p->flags.horiz];
  [slashbutton setState:p->flags.dir];
  [taperbutton selectCellAtRow:0 column:p->flags.taper];
  [freematrix selectCellAtRow:0 column:0];
  [tremmatrix selectCellAtRow:0 column:p->gFlags.subtype];
  [self setView: [choicebutton indexOfSelectedItem]];
  return self;
}

@end
