#import "MarginInspector.h"
#import "Margin.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVCommands.h"
#import "GVSelection.h"
#import "MarginInspector.h"
#import "System.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "mux.h"
#import "muxlow.h"

@implementation MarginInspector

#define UPDATE(lv,rv) if (lv != rv) { lv = rv; b = YES; }

NSString *unitname[4] =
{
  @"Inches", @"Centimeters", @"Points", @"Picas"
};


- preset
{
  int n;
  float conv;
  GraphicView *v = [[NSApp currentDocument] graphicView];
  Margin *p = [v canInspect: MARGIN : &n];
  if (n == 0) return nil;
  conv = [NSApp pointToCurrentUnitFactor];
//  [[NSApp pageLayout] convertOldFactor:&conv newFactor:&anon];
  [[lbindform cellAtIndex:0] setFloatValue:conv * p->margin[6]];
  [[lbindform cellAtIndex:1] setFloatValue:conv * p->margin[8]];
  [[rbindform cellAtIndex:0] setFloatValue:conv * p->margin[7]];
  [[rbindform cellAtIndex:1] setFloatValue:conv * p->margin[9]];
  [lmargcell setFloatValue:conv * p->margin[0]];
  [rmargcell setFloatValue:conv * p->margin[1]];
  [[vertmargform cellAtIndex:0] setFloatValue:conv * p->margin[2]];
  [[vertmargform cellAtIndex:1] setFloatValue:conv * p->margin[4]];
  [[vertmargform cellAtIndex:2] setFloatValue:conv * p->margin[5]];
  [[vertmargform cellAtIndex:3] setFloatValue:conv * p->margin[3]];
  [unitcell setStringValue:[NSApp unitString]];
  [formatbutton selectItemAtIndex:p->format];
  [[alignmatrix cellAtRow:0 column:0] setState:(p->alignment & 1)];
  [[alignmatrix cellAtRow:1 column:0] setState:(p->alignment & 2)];
  return self;
}


- set:sender
{
  int n;
  float f, conv;
  BOOL b = NO;
  System *sys;
  GraphicView *v = [[NSApp currentDocument] graphicView];
  Margin *p = [v canInspect: MARGIN : &n];
  if (n == 0)
  {
    NSBeep();
    return nil;
  }
  [v saveSysLeftMargin];
  p->format = [formatbutton indexOfItemWithTitle:[formatbutton title]];
  p->alignment = 0;
  if ([[alignmatrix cellAtRow:0 column:0] state]) p->alignment |= 1;
  if ([[alignmatrix cellAtRow:1 column:0] state]) p->alignment |= 2;
  conv = [NSApp pointToCurrentUnitFactor];
//  [[NSApp pageLayout] convertOldFactor:&conv newFactor:&anon];
  f = [[lbindform cellAtIndex:0] floatValue] / conv;
  UPDATE(p->margin[6], f);
  f = [[lbindform cellAtIndex:1] floatValue] / conv;    
  UPDATE(p->margin[8], f);
  f = [[rbindform cellAtIndex:0] floatValue] / conv;    
  UPDATE(p->margin[7], f);
  f = [[rbindform cellAtIndex:1] floatValue] / conv;    
  UPDATE(p->margin[9], f);
  f = [lmargcell floatValue] / conv;    
  UPDATE(p->margin[0], f);
  f = [rmargcell floatValue] / conv;    
  UPDATE(p->margin[1], f);
  f = [[vertmargform cellAtIndex:0] floatValue] / conv;    
  UPDATE(p->margin[2], f);
  f = [[vertmargform cellAtIndex:1] floatValue] / conv;    
  UPDATE(p->margin[4], f);
  f = [[vertmargform cellAtIndex:2] floatValue] / conv;    
  UPDATE(p->margin[5], f);
  f = [[vertmargform cellAtIndex:3] floatValue] / conv;    
  UPDATE(p->margin[3], f);
  sys = p->client;
  if (b) [v setRunnerTables];
  [v shuffleIfNeeded];
  [v recalcAllSys];
  [v paginate: self];
  [v dirty];
  [v setNeedsDisplay:YES];
  return self;
}


@end
