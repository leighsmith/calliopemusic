#import "NewPanel.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "System.h"
#import "SysInspector.h"
#import "DrawDocument.h"
#import "DrawApp.h"
#import "mux.h"
#import <AppKit/AppKit.h>

@implementation NewPanel

/*
  tag settings:
  -1 Staves
  1 single part
  2 grand staff
  3 solo + grand staff
  4 S A T B
  5 string quartet
*/


- preset
{
  [choicematrix selectCellAtRow:2 column:0];
  [numstavestext setStringValue:@""];
  return self;
}


- setChoice: sender
{
  if ([[choicematrix selectedCell] tag] == -1)
  {
    [numstavestext setEnabled:YES];
  }
  else
  {
    [numstavestext setStringValue:@""];
    [numstavestext setEnabled:NO];
  }
  return self;
}


- fillDocument: (DrawDocument *) doc : (int) sn
{
  GraphicView *v = doc->view;
  System *sys = [[System alloc] init: sn : v];
  [sys initsys];
  if (sn > 1) [sys installLink];
  [v renumSystems];
  [v doPaginate];
  [v renumPages];
  [v setRunnerTables];
  [v balancePages];
  [v firstPage: self];
  [v setNeedsDisplay:YES];
  return self;
}


- new: sender
{
  DrawDocument *doc = nil;
  NSString *path;
  NSString *fname;
  int i, n;
  i = [[choicematrix selectedCell] tag];
  if (i == -1)
  {
    n = [numstavestext intValue];
    if (n < 1 || n > NUMSTAVES)
    {
      NSBeep();
      return self;
    }
    [self fillDocument: [DrawDocument new] : n];
  }
  else
  {
    fname = [NSString stringWithFormat:@"template%d",i];
      if (path = [[NSBundle mainBundle] pathForResource:fname ofType:FILE_EXT])
    {
        doc = [NSApp openCopyOf: path reDirect: @"~"];
    }
    if (!doc) NSRunAlertPanel(@"Calliope", @"Cannot find template document", @"OK", nil, nil);
  }
  [self close];
  if ([inspbutton state]) [NSApp inspectClass: [SysInspector class] loadInspector: YES];
  return self;
}


/* text delegate */

- (void)controlTextDidChange:(NSNotification *)notification
{
    NSText *theText = [[notification userInfo] objectForKey:@"NSFieldEditor"];
    if (numstavestext == [theText superview])
        if ([choicematrix selectedRow] != 0) [choicematrix selectCellAtRow:0 column:0];
}

@end
