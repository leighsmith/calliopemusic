#import "TextInspector.h"
#import "TextGraphic.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "System.h"
#import "Staff.h"
#import "TextVarCell.h"
#import <AppKit/AppKit.h>
#import "DrawingFunctions.h"

@implementation TextInspector

int subfor[4] = {2, 3, 2, 3};

- set:sender
{
  NSRect b;
  TextGraphic *p;
  Staff *sp, *nsp;
  System *sys;
  NSMutableArray *sl;
  GraphicView *v = [CalliopeAppController currentView];
  int k, num, sn;
  float conv = [[CalliopeAppController sharedApplicationController] pointToCurrentUnitFactor];
//  [[[CalliopeAppController sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];

  if ([v startInspection: TEXTBOX : &b : &sl :&num])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && [p graphicType] == TEXTBOX && SUBTYPEOF(p) != LABEL)
    {
      [[v window] endEditingFor:p];
      if ([typematrix selectedRow] >= 0) p->gFlags.subtype = subfor[[typematrix selectedRow]];
      if ([titplacematrix selectedRow] >= 0) p->horizpos = [titplacematrix selectedRow];
      if (num == 1) switch(p->gFlags.subtype)
      {
        case STAFFHEAD:
	  if ([p->client graphicType] == STAFF)
	      sys = [(Staff *) p->client mySystem];
	  else
	      sys = p->client;
	  sn = [staffform intValue];
	  sn = (sn <= 0) ? 0 : (sn - 1);
	  nsp = [sys getStaff: sn];
	  if (nsp != nil) p->client = nsp;
	  break;
        case TITLE:
	  sp = p->client;
	  if ([sp graphicType] == STAFF) 
	      p->client = [sp mySystem];
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
  GraphicView *v = [CalliopeAppController currentView];
  NSRect b;
  TextGraphic *p;
  NSMutableArray *sl;
  int k, num;
  if ([v startInspection: TEXTBOX : &b : &sl :&num])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && [p graphicType] == TEXTBOX)
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
  while (k--) if ((p = [sl objectAtIndex:k]) && [p graphicType] == TEXTBOX && SUBTYPEOF(p) != LABEL)
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
  GraphicView *v = [CalliopeAppController currentView];
  [self assayList: [v selectedGraphics] : &num];
  if (num == 0) return nil;
  if (ALLSAME(0, num)) [typematrix selectCellAtRow:rownum[ALLVAL(0)] column:0];
  else clearMatrix(typematrix);
  if (ALLSAME(1, num)) [titplacematrix selectCellAtRow:ALLVAL(1) column:0];
  else clearMatrix(titplacematrix);
  if (ALLVAL(0) == TITLE && num == 1)
  {
      p = [v canInspect: TEXTBOX : &num];
      conv = [[CalliopeAppController sharedApplicationController] pointToCurrentUnitFactor];
//    [[[CalliopeAppController sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
    [[marginform cellAtIndex:0] setFloatValue:p->baseline * conv];
    [marginform setEnabled:YES];
    [marginunits setStringValue:[[CalliopeAppController sharedApplicationController] unitString]];
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
