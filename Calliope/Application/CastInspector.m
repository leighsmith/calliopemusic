
/* Generated by Interface Builder */

#import "CastInspector.h"
#import "GraphicView.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "GVGlobal.h"
#import "GNote.h"
#import "Tablature.h"
#import "CallPart.h"
#import "CallInst.h"
#import "StaffObj.h"
#import "muxlow.h"
#import "mux.h"
#import <AppKit/AppKit.h>

@implementation CastInspector

- (void)awakeFromNib
{
  [(NSBrowser *)partbrowser setDelegate:self];
  [partbrowser setAllowsMultipleSelection:YES];
  [(NSBrowser *)instbrowser setDelegate:self];
}


- enableButtons: (int) b1 : (int) b2 : (int) b3
{
  [addbutton setEnabled:b1];
  [modbutton setEnabled:b2];
  [delbutton setEnabled:b3];
  return self;
}


- newEntry: (NSString *) n
{
  CallPart *p;
  NSMutableArray *pl = [NSApp getPartlist];
  int k = [pl count];
  while (k--)
  {
    p = [pl objectAtIndex:k];
      if ([n isEqualToString:p->name])
    {
      NSRunAlertPanel(@"Parts Allocation", @"Part name already in use", @"OK", nil, nil);
      return nil;
    }
  }
  p = [[CallPart alloc] init: n : nil : 1 : nil];
  [pl addObject: p];
  return p;
}


- setAdd: sender
{
  NSString *s = [parttext stringValue];
  CallPart *p;
  BOOL r = NO;
  NSString *a;
  int i=0;
  if (s) {
      i = 1;
      if (![s length]) i=0;
  }
  if (!i)
  {
    s = @"NewPart";
    r = ([self newEntry: s] != nil);
  }
  else if ((p = [self newEntry: s]) != nil)
  {
    i = [[instbrowser matrixInColumn: 0] selectedRow];
    if (i == -1) a = nullInstrument;
      else a = [instlist instNameForInt: i];
    [p update: s : [[partform cellAtIndex:0] stringValue] : [[partform cellAtIndex:1] intValue] : a];
    r = YES;
  }
  if (r)
  {
    partlistflag++;
    [[NSApp getPartlist] sortPartlist];
    [partbrowser reloadColumn:0];
    [partbrowser setPath:s];
    [delbutton setEnabled:1];
    [modbutton setEnabled:1];
    [parttext setStringValue:s];
    [(GraphicView *)[[NSApp currentDocument] graphicView] dirty];
  }
  return self;
}


- setModify: sender
{
  CallPart *p;
  NSString *a;
  NSString *s = [parttext stringValue];
  NSMutableArray *pl = [NSApp getPartlist];
  int i, part;
  if (s == nil) NSBeep();
  else if (![s length]) NSBeep();
  else
  {
    part = [[partbrowser matrixInColumn: 0] selectedRow];
    p = [pl objectAtIndex:part];
    i = [[instbrowser matrixInColumn: 0] selectedRow];
    if (i == -1) a = nullInstrument;
      else a = [instlist instNameForInt: i];
    [p update: s : [[partform cellAtIndex:0] stringValue] : [[partform cellAtIndex:1] intValue] : a];
    partlistflag++;
    [[NSApp getPartlist] sortPartlist];
    [partbrowser reloadColumn:0];
    [partbrowser setPath:s];
    [(GraphicView *)[[NSApp currentDocument] graphicView] dirty];
  }
  return self;
}


- hitRemove: sender
{
  int part;
  part = [[partbrowser matrixInColumn: 0] selectedRow];
  if (part < 0)
  {
    NSBeep();
    return self;
  }
  [[NSApp getPartlist] removeObjectAtIndex:part];
  partlistflag++;
  [partbrowser reloadColumn:0];
  [partbrowser setPath:@""];
  [self enableButtons: 0 : 0 : 0];
  [(GraphicView *)[[NSApp currentDocument] graphicView] dirty];
  [parttext setStringValue:@""];
  return self;
}


/*
  called with a string
*/

- setPanel: (NSString *) t
{
  CallPart *p;
  NSString *n;
  int i = [[partbrowser matrixInColumn: 0] selectedRow];
  if (i < 0 || i > [[NSApp getPartlist] count])
  {
    if (t != nil)
        if ([t length]) [parttext setStringValue:@""];
    [self enableButtons: 1 : 0 : 0];
  }
  else
  {
    if (t != nil)
        if ([t length]) [parttext setStringValue:t];
    p = [[NSApp getPartlist] objectAtIndex:i];
    n = [parttext stringValue];
    if (![p->name isEqualToString: n])
    {
        if (![n length]) [self enableButtons: 1 : 0 : 0];
      else [self enableButtons: 1 : 1 : 0];
    }
    else
    {
      [self enableButtons: 0 : 1 : 1];
    }
    [[partform cellAtIndex:0] setStringValue:p->abbrev ? p->abbrev : @""];
    [[partform cellAtIndex:1] setIntValue:p->channel];
    [instbrowser setPath:p->instrument];
  }
  return self;
}


/* reflect the selection */

- reflectSelection
{
  int mult, k;
  DrawDocument *d;
  GraphicView *v;
  NSMutableArray *sl, *pl;
  StaffObj *p;
  NSString *n;
  [partbrowser loadColumnZero];
  [instbrowser loadColumnZero];
  d = [NSApp currentDocument];
  if (d == nil) return self;
  v = [d graphicView];
  if (v == nil) return self;
  sl = v->slist;
  pl = [NSApp getPartlist];
  k = [sl count];
  n = nil;
  mult = 0;
  while (k--)
  {
    p = [sl objectAtIndex:k];
    if (!ISASTAFFOBJ(p)) continue;
    if (n == nil) n = p->part;
      else if (![n isEqualToString:p->part]) mult = 1;
  }
  if (n == nil || mult)
  {
    clearMatrix([partbrowser matrixInColumn: 0]);
    [parttext setStringValue:@""];
  }
  else
  {
    [partbrowser setPath:n];
    [self setPanel: n];
  }
  return self;
}


- preset
{
  [self reflectSelection];
  return self;
}


- browserHit: sender
{
  int i = [[partbrowser matrixInColumn: 0] selectedRow];
  return [self setPanel: [[NSApp getPartlist] partNameForInt: i]];
}


- hitExtract: sender
{
  int j, n;
  CallPart *cp;
  GraphicView *v = [[NSApp currentDocument] graphicView];
  NSMutableArray *pl, *xl;
  NSMatrix *m;
  NSCell *c;
  xl = [[NSMutableArray alloc] init];
  pl = [NSApp getPartlist];
  m = [partbrowser matrixInColumn: 0];
  n = [[m cells] count];
  for (j = 0; j < n; j++)
  {
    c = [m cellAtRow:j column:0];
    if ([c isHighlighted])
    {
        cp = [pl partNamed: [c stringValue]];
        if (![cp->name isEqualToString:nullPart]) [xl addObject: cp];
    }
  }
  if ([xl count]) [v extractParts: xl];
  else NSRunAlertPanel(@"Extraction", @"No Parts Assigned", @"OK", nil, nil, NULL);
  [xl release]; //sb: while this is a List, it is freed, not released.
  return self;
}


/* text delegate */

- (void)controlTextDidChange:(NSNotification *)notification
{
    NSText *theText = [[notification userInfo] objectForKey:@"NSFieldEditor"];
    if (parttext == [theText superview])
  {
    [self setPanel: NULL];
  }
}


/* NXBrowser delegates */

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)col
{
  NSMutableArray *pl;
  if (sender == partbrowser)
  {
    pl = [NSApp getPartlist];
    return [pl count];
  }
  return [instlist count];  
}


- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)col
{
  NSMutableArray *pl;
  if (col != 0) return;
  if (sender == partbrowser)
  {
    pl = [NSApp getPartlist];
    [cell setStringValue:[pl partNameForInt: row]];
    [cell setLeaf:YES];
  }
  else
  {
    [cell setStringValue:[instlist instNameForInt: row]];
    [cell setLeaf:YES];
  }
  [cell setEnabled:YES];
}



@end
