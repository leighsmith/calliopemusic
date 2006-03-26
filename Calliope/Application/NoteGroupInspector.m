#import "NoteGroupInspector.h"
#import "NoteGroup.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "mux.h"
#import <AppKit/NSMatrix.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSForm.h>
#import <Foundation/NSArray.h>


@implementation NoteGroupInspector:NSPanel


/* to enable/disable position matrix (above/below/left/right) for each group type */

char typeEnabled[NUMNOTEGROUPS][4] =
{
  {1, 1, 0, 0},
  {1, 1, 0, 0},
  {1, 1, 0, 0},
  {1, 1, 0, 0},
  {1, 1, 1, 1},
  {1, 1, 1, 1},
  {1, 1, 1, 1},
  {1, 1, 1, 1},
  {1, 1, 1, 1},
  {1, 1, 1, 1},
  {1, 1, 1, 1},
  {1, 1, 0, 0},
  {1, 1, 0, 0},
  {1, 1, 0, 0},
  {1, 1, 1, 1},
  {1, 0, 0, 0}
};


- setClient: (NoteGroup *) p
{
  p->gFlags.subtype = [[typematrix selectedCell] tag];
  p->flags.fixed = [freematrix selectedColumn];
  p->flags.position = [hdtlmatrix selectedColumn];
  return self;
}


- setProto: sender
{
  return [self setClient: [NoteGroup myPrototype]];
}

/*
  a variant of setClient that sets certain parameters to legal or default values 
*/

- setNewChoice: (NoteGroup *) p
{
  int st = [[typematrix selectedCell] tag];
  p->gFlags.subtype = st;
  p->flags.fixed = [freematrix selectedColumn];
  p->flags.position = [hdtlmatrix selectedColumn];
  if (st == GROUPVOLTA && p->mark[0] == '\0')
  {
    p->mark[0] = '1';
    p->mark[1] = '.';
    p->mark[2] = '\0';
  }
  return self;
}


- set:sender
{
  NSRect b;
  NSMutableArray *sl;
  GraphicView *v = [[DrawApp currentDocument] graphicView];
  NoteGroup *p;
  int k;
  if ([v startInspection: GROUP : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == GROUP)
    {
      if (p->gFlags.subtype != [[typematrix selectedCell] tag]) [self setNewChoice: p];
      else [self setClient: p];
      [p setHanger];
    }
  }
  [v endInspection: &b];
  return self;
}


- setChoice: sender
{
  int i, n, p;
  n = [[typematrix selectedCell] tag];
  p = [hdtlmatrix selectedColumn];
  if (!typeEnabled[n][p])
  {
    for (i = 0; i < 4; i++) if (typeEnabled[n][i])
    {
      [hdtlmatrix selectCellAtRow:0 column:i];
      break;
    }
  }
  for (i = 0; i < 4; i++) [[hdtlmatrix cellAtRow:0 column:i] setEnabled:typeEnabled[n][i]];
  return self;
}


- updatePanel: (NoteGroup *) p
{
  [typematrix selectCellWithTag:p->gFlags.subtype];
  [freematrix selectCellAtRow:0 column:p->flags.fixed];
  [hdtlmatrix selectCellAtRow:0 column:p->flags.position];
  [self setChoice: self];
  return self;
}


- preset
{
    NoteGroup *p = [(GraphicView *)[[DrawApp currentDocument] graphicView] canInspect: GROUP];
  if (p == nil) return self;
  return [self updatePanel: p];
}


- presetTo: (int) i
{
  return [self updatePanel: [NoteGroup myPrototype]];
}

@end
