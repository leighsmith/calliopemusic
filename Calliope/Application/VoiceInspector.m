#import "VoiceInspector.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "StaffObj.h"
#import "Staff.h"
#import "System.h"
#import "mux.h"
#import <AppKit/NSForm.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSGraphics.h>

@implementation VoiceInspector


- selectBack: sender
{
  int n, i, nk, j;
  Staff *sp;
  StaffObj *q;
  GraphicView *v = [[NSApp currentDocument] gview];
  System *sys = [NSApp currentSystem];
  NSMutableArray *sl, *nl;
  if (sys == nil) return self;
  [v deselectAll: v];
  sl = sys->staves;
  n = sys->flags.nstaves;
  for (i = 0; i < n; i++)
  {
    sp = [sl objectAtIndex:i];
    if (sp->flags.hidden) continue;
    nl = sp->notes;
    nk = [nl count];
    for (j = 0; j < nk; j++)
    {
      q = [nl objectAtIndex:j];
      if (q->isGraced == 2) [v selectObj: q];
    }
  }
  [v drawSelectionWith: NULL];
  [v inspectSel: NO];
  return self;
}


- selectVoice: sender
{
  int n, i, nk, j, vox;
  Staff *sp;
  StaffObj *q;
  GraphicView *v = [[NSApp currentDocument] gview];
  System *sys = [NSApp currentSystem];
  NSMutableArray *sl, *nl;
  if (sys == nil) return self;
  vox = [[selAllForm cellAtIndex:0] intValue];
  [v deselectAll: v];
  sl = sys->staves;
  n = sys->flags.nstaves;
  for (i = 0; i < n; i++)
  {
    sp = [sl objectAtIndex:i];
    if (sp->flags.hidden) continue;
    nl = sp->notes;
    nk = [nl count];
    for (j = 0; j < nk; j++)
    {
      q = [nl objectAtIndex:j];
      if (q->voice == vox) [v selectObj: q];
    }
  }
  [v drawSelectionWith: NULL];
  [v inspectSel: NO];
  return self;
}


- set:sender
{
  StaffObj *p;
  int k, vox;
  GraphicView *v = [[NSApp currentDocument] gview];
  NSMutableArray *sl = v->slist;
  vox = [[selectForm cellAtIndex:0] intValue];
  k = [sl count];
  while(k--)
  {
    p = [sl objectAtIndex:k];
    if (ISATIMEDOBJ(p)) p->voice = vox;
  }
  return self;
}


- preset
{
  int num;
  StaffObj *p = [[[NSApp currentDocument] gview] canInspectTypeCode: TC_TIMEDOBJ : &num];
  if (num == 1)
  {
    [[selectForm cellAtIndex:0] setIntValue:p->voice];
  }
  else
  {
    [selectForm setStringValue:@""];
  }
  return self;
}

@end
