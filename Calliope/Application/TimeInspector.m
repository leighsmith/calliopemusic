#import "TimeInspector.h"
#import "OpusDocument.h"
#import "CalliopeAppController.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "TimeSig.h"
#import "DrawingFunctions.h"
#import <AppKit/AppKit.h>

@implementation TimeInspector


BOOL enablenum[8] = {NO, NO, NO, NO, YES, YES, YES, NO};
BOOL enableden[8] = {NO, NO, NO, NO, NO,  YES, YES, NO};
BOOL enablered[8] = {NO, NO, NO, NO, NO,  NO,  YES, NO};
BOOL enablepunct[8] = {YES, YES, YES, YES, NO, NO, NO, NO};


- setClient: (TimeSig *) p
{
  int i = [[choicematrix selectedCell] tag];
  p->gFlags.subtype = i;
  if (enablepunct[i])
  {
    p->dot = [[punctmatrix cellAtRow:0 column:0] state];
    p->line = [[punctmatrix cellAtRow:0 column:1] state];
  }
  if (enablenum[i]) strcpy(p->numer, [[[numdenform cellAtIndex:0] stringValue] UTF8String]);
  if (enableden[i]) strcpy(p->denom, [[[numdenform cellAtIndex:1] stringValue] UTF8String]);
  if (enablered[i]) strcpy(p->reduc, [[[reducform cellAtIndex:0] stringValue] UTF8String]);
  p->fnum = [[factorform cellAtIndex:0] floatValue];
  p->fden = [[factorform cellAtIndex:1] floatValue];
  return self;
}


- setProto: sender
{
  return [self setClient: [TimeSig myPrototype]];
}


- set:sender
{
  NSRect b;
  TimeSig *p;
  id sl, v = [CalliopeAppController currentView];
  int k;
  if ([v startInspection: TIMESIG : &b : &sl])
  {
    k = [sl count];
    while (k--) if ((p = [sl objectAtIndex:k]) && [p graphicType] == TIMESIG)
    {
      [self setClient: p];
      [p recalc];
    }
    [v endInspection: &b];
  }
  return self;
}


- update: sender
{
  int i = [[choicematrix selectedCell] tag];
  [[numdenform cellAtRow:0 column:0] setEnabled:enablenum[i]];
  [[numdenform cellAtRow:1 column:0] setEnabled:enableden[i]];
  [[reducform cellAtRow:0 column:0] setEnabled:enablered[i]];
  [punctmatrix setEnabled:enablepunct[i]];
  return self;
}


- updatePanel: (TimeSig *) p
{
  int i = p->gFlags.subtype;
  [choicematrix selectCellWithTag:i];
  if (enablepunct[i])
  {
    [punctmatrix setState:p->dot atRow:0 column:0];
    [punctmatrix setState:p->line atRow:0 column:1];
  }
  if (enablenum[i]) [[numdenform cellAtIndex:0] setStringValue:[NSString stringWithUTF8String:p->numer]];
  if (enableden[i]) [[numdenform cellAtIndex:1] setStringValue:[NSString stringWithUTF8String:p->denom]];
  if (enablered[i]) [[reducform cellAtIndex:0] setStringValue:[NSString stringWithUTF8String:p->reduc]];
  [[factorform cellAtIndex:0] setFloatValue:p->fnum];
  [[factorform cellAtIndex:1] setFloatValue:p->fden];
  return self;
}


- preset
{
  int n;
  TimeSig *p = [[CalliopeAppController currentView] canInspect: TIMESIG : &n];
  if (n == 0) return nil;
  [self updatePanel: p];
  [self update: self];
  return self;
}


- presetTo: (int) i
{
  return [self updatePanel: [TimeSig myPrototype]];
}



@end
