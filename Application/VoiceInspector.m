#import "VoiceInspector.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "StaffObj.h"
#import "Staff.h"
#import "System.h"
#import "DrawingFunctions.h"
#import <AppKit/NSForm.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSGraphics.h>

@implementation VoiceInspector


- selectBack: sender
{
    int n, i, nk, j;
    Staff *sp;
    StaffObj *q;
    GraphicView *v = [CalliopeAppController currentView];
    System *sys = [[CalliopeAppController sharedApplicationController] currentSystem];
    
    if (sys == nil) 
	return self;
    [v deselectAll: v];
    n = [sys numberOfStaves];
    for (i = 0; i < n; i++) {
	NSMutableArray *nl;

	sp = [sys getStaff: i];
	if (sp->flags.hidden) 
	    continue;
	nl = sp->notes;
	nk = [nl count];
	for (j = 0; j < nk; j++) {
	    q = [nl objectAtIndex: j];
	    if (q->isGraced == 2) 
		[v selectObj: q];
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
    GraphicView *v = [CalliopeAppController currentView];
    System *sys = [[CalliopeAppController sharedApplicationController] currentSystem];
    
    if (sys == nil) 
	return self;
    vox = [[selAllForm cellAtIndex: 0] intValue];
    [v deselectAll: v];
    n = [sys numberOfStaves];
    for (i = 0; i < n; i++) {
	NSMutableArray *nl;

	sp = [sys getStaff: i];
	if (sp->flags.hidden) continue;
	nl = sp->notes;
	nk = [nl count];
	for (j = 0; j < nk; j++) {
	    q = [nl objectAtIndex: j];
	    if (q->voice == vox)
		[v selectObj: q];
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
  GraphicView *v = [CalliopeAppController currentView];
  NSMutableArray *sl = [v selectedGraphics];
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
  StaffObj *p = [[CalliopeAppController currentView] canInspectTypeCode: TC_TIMEDOBJ : &num];
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
