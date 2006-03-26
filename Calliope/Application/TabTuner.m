#import "TabTuner.h"
#import "PrefBlock.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GVPerform.h"
#import "MultiView.h"
#import "TuningView.h"
#import "CallInst.h"
#import "GNote.h"
#import "Tablature.h"
#import "muxlow.h"
#import <AppKit/AppKit.h>

@implementation TabTuner

extern NSString *GeneralMidiSounds[128];
extern NSString *nullFingerboard;
extern NSString *nullProgChange;

- (void)awakeFromNib
{
  NSPopUpButton *p;
  int i;
  p = instpopup;
  [p removeItemAtIndex:0];
  for (i = 0; i < 128; i++) [p addItemWithTitle:GeneralMidiSounds[i]];
  [((TuningView *)noteview) init: self];
  [(NSBrowser *)tabbrowser setDelegate:self];
  [tabbrowser loadColumnZero];
}


- enableButtons: (int) b1 : (int) b2 : (int) b3
{
  [newbutton setEnabled:b1];
  [modbutton setEnabled:b2];
  [delbutton setEnabled:b3];
  return self;
}



- (NSMutableArray *) selectedList
{
  int inst;
  inst = [[tabbrowser matrixInColumn: 0] selectedRow];
  if (inst == -1) return nil;
  return ((CallInst *)[instlist objectAtIndex:inst])->tuning;
}


- (int) isTablature
{
  return [tabswitch state];
}


- (int) transposition
{
  int inst = [[tabbrowser matrixInColumn: 0] selectedRow];
  if (inst == -1) return 0;
  return ((CallInst *)[instlist objectAtIndex:inst])->trans;
}


- setSelectedTrans: (int) t
{
  int inst = [[tabbrowser matrixInColumn: 0] selectedRow];
  if (inst == -1) return self;
  [[instform cellAtIndex:1] setIntValue:t];
  ((CallInst *)[instlist objectAtIndex:inst])->trans = t;
  return self;
}


- (BOOL) instExists: (NSString *) n
{
  CallInst *p;
  int k = [instlist count];
  while (k--)
  {
    p = [instlist objectAtIndex:k];
      if ([n isEqualToString: p->name]) return YES;
  }
  return NO;
}


- newEntry: (NSString *) n
{
  CallInst *i;
  if ([self instExists: n])
  {
    NSRunAlertPanel(@"Instrumentation", @"Instrument name already in use", @"OK", nil, nil);
    return nil;
  }
  else
  {
    i = [[CallInst alloc] init: n : nil : 0 : 1 : 0 : 0 : nil];
    [instlist addObject: i];
  }
  return i;
}


- setAdd: sender
{
  NSString *s = [tabtext stringValue];
  CallInst *p;
  BOOL r = NO;
  int i=0;
  if (s == nil) i=1;
    else if (![s length]) i=1;
    if (i)
  {
    s = @"NewInstrument";
    r = ([self newEntry: s] != nil);
  }
  else if ((p = [self newEntry: s]) != nil)
  {
    [p update: s : [[instform cellAtIndex:0] stringValue] : [[instform cellAtIndex:1] intValue]
                : 0 : [tabswitch state] : [instpopup indexOfSelectedItem]];
    p->tuning = [[NSMutableArray alloc] init];
    r = YES;
  }
  if (r)
  {
    ++instlistflag;
    [instlist sortInstlist];
    [tabbrowser reloadColumn:0];
    [tabbrowser setPath:s];
    [delbutton setEnabled:1];
    [modbutton setEnabled:1];
    [tabtext setStringValue:s];
    [noteview preset];
  }
  return self;
}


- setRename: sender
{
  CallInst *p;
  NSString *s = [tabtext stringValue];
  int inst;
  int i=0;
  if (s == nil) i=1;
    else if (![s length]) i=1;
    if (i) NSBeep();
  else
  {
    inst = [[tabbrowser matrixInColumn: 0] selectedRow];
    if (inst == -1)
    {
      NSBeep();
      return self;
    }
    p = [instlist objectAtIndex:inst];
    [p update: s : [[instform cellAtIndex:0] stringValue] : [[instform cellAtIndex:1] intValue]
                : 0 : [tabswitch state] : [instpopup indexOfSelectedItem]];
    ++instlistflag;
    [instlist sortInstlist];
    [tabbrowser reloadColumn:0];
    [tabbrowser setPath:s];
    [noteview preset];
  }
  return self;
}


- hitRemove: sender
{
  int inst;
  inst = [[tabbrowser matrixInColumn: 0] selectedRow];
  if (inst < 0 || inst >= [instlist count])
  {
    NSBeep();
    return self;
  }
  [instlist removeObjectAtIndex:inst];
  instlistflag++;
  [tabbrowser reloadColumn:0];
  [tabbrowser setPath:@""];
  [self enableButtons: 0 : 0 : 0];
  [tabtext setStringValue:@""];
  [noteview preset];
  return self;
}


- setPanel: (NSString *) t
{
  CallInst *p;
  BOOL b;
  NSString *n;
  int i = [[tabbrowser matrixInColumn: 0] selectedRow];
  if (i < 0 || i > [instlist count])
  {
    if (t != nil)
        if ([t length]) [tabtext setStringValue:@""];
    [self enableButtons: 1 : 0 : 0];
  }
  else
  {
    if (t != nil)
        if ([t length]) [tabtext setStringValue:t];
    p = [instlist objectAtIndex:i];
    n = [tabtext stringValue];
    if (![p->name isEqualToString: n])
    {
      if (![n length]) [self enableButtons: 1 : 0 : 0];
      else [self enableButtons: 1 : 1 : 0];
    }
    else
    {
      b = (p->name != nullInstrument && p->name != nullFingerboard);
      [self enableButtons: 0 : b : b];
    }
    [[instform cellAtIndex:0] setStringValue:p->abbrev];
    [[instform cellAtIndex:1] setIntValue:p->trans];
    [tabbrowser setPath:p->name];
    [instpopup selectItemAtIndex:p->sound];
    [tabswitch setState:p->istab];
    [instpopup setEnabled:p->name != nullProgChange];
  }
  [noteview preset];
  return self;
}


- preset
{
  return [self setPanel: nil];
}


- browserHit: sender
{
  int i = [[tabbrowser matrixInColumn: 0] selectedRow];
  return [self setPanel: [instlist instNameForInt: i]];
}


/* text delegate */

- (void)controlTextDidChange:(NSNotification *)notification
{
    NSText *theText = [[notification userInfo] objectForKey:@"NSFieldEditor"];
    if (tabtext == [theText superview])
    {
        [self setPanel: nil];
    }
}


/* NXBrowser delegates */

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)col
{
  return [instlist count];
}


- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)col
{
  if (col == 0)
  {
    [cell setStringValue:[instlist instNameForInt: row]];
    [cell setLeaf:YES];
  }
  [cell setEnabled:YES];
}

@end
