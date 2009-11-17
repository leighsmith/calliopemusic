/* $Id$ */
#import "ToneTool.h"
#import "GNote.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "muxlow.h"
#import <AppKit/NSMatrix.h>
#import <Foundation/NSArray.h>

@implementation ToneTool


/* set General MIDI Tone */

- setTone: sender
{
  GNote *p;
  int i, k;
  GraphicView *v;
  NSMutableArray *sl;
  CalliopeAppController *appController;

  appController = [CalliopeAppController sharedApplicationController];
  if (appController == nil) return self;
  v = [CalliopeAppController currentView];
  if (v == nil) 
      return self;
  sl = [v selectedGraphics];
  i = 8 * [sender selectedRow] + [sender selectedColumn];
  k = [sl count];
  while (k--)
  {
    p = [sl objectAtIndex:k];
    if ([p graphicType] == NOTE) 
	[p setPatch: i + 1];
  }
  [v dirty];
  [appController inspectApp];
  return self;
}


- preset
{
  int mult, i, k, pat;
  OpusDocument *d;
  GraphicView *v;
  NSMutableArray *sl;
  GNote *p;

  d = [CalliopeAppController currentDocument];
  if (d == nil) return self;
  v = [CalliopeAppController currentView];
  if (v == nil) return self;
  sl = [v selectedGraphics];
  k = [sl count];
  i = -1;
  mult = 0;
  while (k--)
  {
    p = [sl objectAtIndex:k];
    if ([p graphicType] == NOTE && [p getPatch])
    {
      pat = [p getPatch] - 1;
      if (i == -1) i = pat;
      else if (i != pat) mult = 1;
    }
  }
  if (i == -1 || mult) clearMatrix(tonematrix);
  else [tonematrix selectCellAtRow:(i >> 3) column:(i & 7)];
  return self;
}


@end
