#import "TextInspector.h"
#import "TextGraphic.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "System.h"
#import "Staff.h"
#import "TextVarCell.h"
#import <AppKit/AppKit.h>
#import "mux.h"

@implementation TextInspector

int subfor[4] = {2, 3, 2, 3};

- set:sender
{
  NSRect b;
  TextGraphic *p;
  Staff *sp, *nsp;
  System *sys;
  float conv;
  NSMutableArray *sl;
  GraphicView *v = [[NSApp currentDocument] gview];
  int k, num, sn;
  conv = [NSApp pointToCurrentUnitFactor];
//  [[NSApp pageLayout] convertOldFactor:&conv newFactor:&anon];
  if ([v startInspection: TEXTBOX : &b : &sl :&num])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == TEXTBOX && SUBTYPEOF(p) != LABEL)
    {
      [[v window] endEditingFor:p];
      if ([typematrix selectedRow] >= 0) p->gFlags.subtype = subfor[[typematrix selectedRow]];
      if ([titplacematrix selectedRow] >= 0) p->horizpos = [titplacematrix selectedRow];
      if (num == 1) switch(p->gFlags.subtype)
      {
        case STAFFHEAD:
	  sys = p->client;
	  if (TYPEOF(sys) == STAFF) sys = ((Staff *) sys)->mysys;
	  sn = [staffform intValue];
	  sn = (sn <= 0) ? 0 : (sn - 1);
	  nsp = [sys getstaff: sn];
	  if (nsp != nil) p->client = nsp;
	  break;
        case TITLE:
	  sp = p->client;
	  if (TYPEOF(sp) == STAFF) p->client = sp->mysys;
	  p->baseline = [[marginform cellAtIndex:0] floatValue] / conv;
	  break;
      }
      [p recalc];
    }
    [v endInspection: &b];
  }
  return self;
}


- hitName: sender
{
  return self;
}


- hitAbbrev: sender
{
  return self;
}


/* for inserting vars.  Under construction  */

- insertVar: sender
{
  GraphicView *v = [[NSApp currentDocument] gview];
  NSRect b;
  TextGraphic *p;
  NSMutableArray *sl;
  int k, num;
  if ([v startInspection: TEXTBOX : &b : &sl :&num])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == TEXTBOX)
    {
//      [p replaceSelWithCell: v];
    
//      [p replaceSelWithCell: v];
    }
  }
  return self;
}


/* assaying attributes for sensible display on inspector */

- assayList: (NSMutableArray *) sl : (int *) num
{
  TextGraphic *p;
  int k, n;
  k = [sl count];
  initassay();
  n = 0;
  while (k--) if ((p = [sl objectAtIndex:k]) && TYPEOF(p) == TEXTBOX && SUBTYPEOF(p) != LABEL)
  {
    ++n;
    assay(0, p->gFlags.subtype);
    assay(1, p->horizpos);
  }
  *num = n;
  return self;
}

int rownum[4] = {0, 0, 0, 1};

- dataChanged: sender
{
    [self makeFirstResponder:setButton];
    return self;
}
- preset
{
  int num;
  float conv;
  TextGraphic *p;
  GraphicView *v = [[NSApp currentDocument] gview];
  [self assayList: v->slist : &num];
  if (num == 0) return nil;
  if (ALLSAME(0, num)) [typematrix selectCellAtRow:rownum[ALLVAL(0)] column:0];
  else clearMatrix(typematrix);
  if (ALLSAME(1, num)) [titplacematrix selectCellAtRow:ALLVAL(1) column:0];
  else clearMatrix(titplacematrix);
  if (ALLVAL(0) == TITLE && num == 1)
  {
      p = [v canInspect: TEXTBOX : &num];
      conv = [NSApp pointToCurrentUnitFactor];
//    [[NSApp pageLayout] convertOldFactor:&conv newFactor:&anon];
    [[marginform cellAtIndex:0] setFloatValue:p->baseline * conv];
    [marginform setEnabled:YES];
    [marginunits setStringValue:[NSApp unitString]];
  }
  else
  {
    [[marginform cellAtIndex:0] setStringValue:@" "];
    [marginunits setStringValue:@" "];
    [marginform setEnabled:NO];
  }
  if (ALLVAL(0) == STAFFHEAD && num == 1)
  {
    p = [v canInspect: TEXTBOX : &num];
    [staffform setIntValue:([p->client myIndex] + 1)];
    [staffform setEnabled:YES];
  }
  else
  {
    [staffform setStringValue:@" "];
    [staffform setEnabled:NO];
  }
  return self;
}

- presetTo: (int) i
{
  return self;
}

@end
