#import "BlockInspector.h"
#import "Block.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "DrawDocument.h"
#import "DrawApp.h"
#import <AppKit/NSMatrix.h>
#import <AppKit/NSForm.h>
#import <Foundation/NSArray.h>
#import "mux.h"

@implementation BlockInspector

/* called when TOOL is pushed */


- setClient: (Block *) p
{
  NSString *s;
  int seltype = [typematrix selectedColumn];
  int seltag = [[typematrix selectedCell] tag];
  if (seltype >= 0)  p->gFlags.subtype = seltag;
  if (seltag == 0)
  {
    s = [[sizeform cellAtIndex:0] stringValue];
    if ([s length]) p->width = [[sizeform cellAtIndex:0] floatValue];
    s = [[sizeform cellAtIndex:1] stringValue];
    if ([s length]) p->height = [[sizeform cellAtIndex:1] floatValue];
  }
  return self;
}


/* called when TOOL is pushed */

- setProto: sender
{
  return [self setClient: [Block myPrototype]];
}


/* called when SET is pushed */

- set:sender
{
  NSRect b;
  Block *p;
  id sl, v = [[DrawApp currentDocument] graphicView];
  int k;
  if ([v startInspection: BLOCK : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == BLOCK)
    {
      [self setClient: p];
      [p reShape];
    }
    [v endInspection: &b];
  }
  return self;
}


/* assaying attributes for sensible display on inspector */

- assayList: (NSMutableArray *) sl : (int *) num
{
  Block *p;
  int k, n;
  k = [sl count];
  initassay();
  n = 0;
  while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == BLOCK)
  {
    ++n;
    assay(0, p->gFlags.subtype);
    assayAsFloat(0, p->width);
    assayAsFloat(1, p->height);
  }
  *num = n;
  return self;
}


- updatePanel
{
  int n;
  GraphicView *v = [[DrawApp currentDocument] graphicView];
  [self assayList: v->slist : &n];
  if (n == 0) return self;
  [[sizeform cellAtIndex:0] setStringValue:@""];
  [[sizeform cellAtIndex:1] setStringValue:@""];
  if (ALLSAME(0, n))
  {
    [typematrix selectCellWithTag:ALLVAL(0)];
    if (ALLVAL(0) == 0)
    {
      if (ALLSAMEFLOAT(0, n)) [[sizeform cellAtIndex:0] setFloatValue:ALLVALFLOAT(0)];
      if (ALLSAMEFLOAT(1, n)) [[sizeform cellAtIndex:1] setFloatValue:ALLVALFLOAT(1)];
    }
  }
  else clearMatrix(typematrix);
  return self;
}


/* called when panel is opened.  Load values from inspector */

- preset
{
  [self updatePanel];
  return self;
}


- presetTo: (int) i
{
  Block *p = [Block myPrototype];
  [typematrix selectCellAtRow:0 column:p->gFlags.subtype];
  if (p->gFlags.subtype == 0)
  {
    [[sizeform cellAtIndex:0] setFloatValue:p->width];
    [[sizeform cellAtIndex:1] setFloatValue:p->height];
  }
  else
  {
    [[sizeform cellAtIndex:0] setStringValue:@""];
    [[sizeform cellAtIndex:1] setStringValue:@""];
  }
  return self;
}

@end
