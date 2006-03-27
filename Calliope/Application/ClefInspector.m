
/* Generated by Interface Builder */

#import "ClefInspector.h"
#import "Clef.h"
#import "StaffTrans.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSButton.h>
#import <Foundation/NSArray.h>
#import "mux.h"


@implementation ClefInspector

- setProto: sender
{
  Clef *p = [Clef myPrototype];
  p->keycentre = [keymatrix selectedRow];
  p->gFlags.subtype = [keymatrix selectedColumn];
  p->p = (([linematrix selectedRow]) << 1);
  p->ottava = [ottavamatrix selectedRow] - 1;
  return self;
}


- set:sender
{
  NSRect b, tb;
  Clef *p;
  id sl, v = [DrawApp currentView];
  int i, k, mc=0, off;
  BOOL dotrans;
  if ([v startInspection: CLEF : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == CLEF)
    {
      dotrans = ([transswitch state] && (TYPEOF(p->mystaff) == STAFF));
      if (dotrans)
      {
        tb = p->bounds;
        [p transBounds: &tb : CLEF];
	mc = [p middleC];
      }
      p->keycentre = [keymatrix selectedRow];
      p->gFlags.subtype = [keymatrix selectedColumn];
      p->p = (([linematrix selectedRow] - (5 - [p getLines])) << 1);
      p->ottava = [ottavamatrix selectedRow] - 1;
      [p recalc];
      if (dotrans)
      {
      i = [octavebutton indexOfItemWithTitle:[octavebutton title]];
	off = 0;
	if (i == 1) off = -7; else if (i == 2) off = 7;
        if ((off += [p middleC] - mc))
	{
          [p->mystaff transClef: p : off];
          b  = NSUnionRect(tb , b);
	}
      }
    }
    [v endInspection: &b];
  }
  return self;
}


/* called when panel is opened.  Load values from inspector */
/* needs a mod to understand multiple selections */


- preset
{
  int n;
  GraphicView *v = [DrawApp currentView];
  Clef *p = [v canInspect: CLEF : &n];
  if (n == 0) return nil;
  [keymatrix selectCellAtRow:p->keycentre column:p->gFlags.subtype];
  [linematrix selectCellAtRow:(p->p >> 1) column:0];
  [ottavamatrix selectCellAtRow:p->ottava + 1 column:0];
  [octavebutton selectItemAtIndex: 0];
  return self;
}


/* called when a clef is chosen: selects default line */

static char defline[3] = {2, 1, 3};

- update: sender
{
  [linematrix selectCellAtRow:defline[ [keymatrix selectedRow] ] column:0];
  return self;
}


- presetTo: (int) i
{
  Clef *p = [Clef myPrototype];
  [keymatrix selectCellAtRow:p->keycentre column:p->gFlags.subtype];
  [linematrix selectCellAtRow:(p->p >> 1) column:0];
  [ottavamatrix selectCellAtRow:p->ottava + 1 column:0];
  [octavebutton selectItemAtIndex: 0];
  return self;
}

@end
