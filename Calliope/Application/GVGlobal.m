#import "GraphicView.h"
#import "GVFormat.h"
#import "GVCommands.h"
#import "GVGlobal.h"
#import "DrawDocument.h"
#import "DrawApp.h"
#import "GVPasteboard.h"
#import "System.h"
#import "Staff.h"
#import "StaffObj.h"
#import "Bracket.h"
#import "TextGraphic.h"
#import "Runner.h"
#import "Margin.h"
#import "Rest.h"
#import "Barline.h"
#import "CallPart.h"
#import "mux.h"
#import "muxlow.h"
#import <AppKit/AppKit.h>

@implementation GraphicView(GVGlobal)

static Staff *staffmap[NUMSTAVES]; /* indexed by old staff, points to new staff */


- (BOOL) sysSameShape
{
  int k, n;
  System *sys;
  if (currentSystem == nil) return NO;
  n = currentSystem->flags.nstaves;
  k = [syslist count];
  while (k--)
  {
    sys = [syslist objectAtIndex:k];
    if (sys->flags.nstaves != n) return NO;
  }
  return YES;
}


/*
  copy notes in nl to a new list which will be notes of esl,
  adding the parts to pl
*/

- copyNotes: (NSMutableArray *) nl : (Staff *) sp : (NSMutableArray *) pl
{
  NSMutableArray *enl, *opl;
  int k;
  id f;
  StaffObj *p;
  opl = [self partList];
  f = [self copyToPasteboard: nl];
  enl = [self pasteFromPasteboard: [NSPasteboard generalPasteboard]];
  [self closeList: enl];
  k = [enl count];
  while (k--)
  {
    p = [enl objectAtIndex:k];
    p->mystaff = sp;
    if ([pl partNamed: [p getPart]] == nil)
    {
      [pl addObject: [[opl partNamed: [p getPart]] newFrom]];
    }
  }
  sp->notes = enl;
  return self;
}


/* copy suitable objects in old system to new system */

static void makeLinkage(System *sys)
{
  Bracket *p = [[Bracket alloc] init];
  p->client1 = sys;
  [sys linkobject: p];
}


- copyObjs: (System *) osys : (System *) nsys
{
  Graphic *p, *t;
  Staff *sp1, *sp2;
  int i;
  NSMutableArray *ol = osys->objs;
  if (nsys->flags.nstaves > 1) makeLinkage(nsys);
  else
  {
    sp1 = [osys->staves objectAtIndex:0];
    if (sp1->flags.haspref) makeLinkage(nsys);
  }
  i = [ol count];
  while (i--)
  {
    p = [ol objectAtIndex:i];
    switch(TYPEOF(p))
    {
      case BRACKET:
        if (SUBTYPEOF(p) == LINKAGE) continue;
	sp1 = staffmap[[((Bracket *)p)->client1 myIndex]];
	if (sp1 == nil) continue;
	sp2 = staffmap[[((Bracket *)p)->client2 myIndex]];
	if (sp2 == nil) continue;
        t = [[Bracket alloc] init];
        ((Bracket *)t)->gFlags.subtype = ((Bracket *)p)->gFlags.subtype;
        ((Bracket *)t)->level = ((Bracket *)p)->level;
	((Bracket *)t)->client1 = sp1;
	((Bracket *)t)->client2 = sp2;
	[nsys linkobject: t];
        break;
      case MARGIN:
        t = [(Margin *) p newFrom];
        ((Margin *) t)->client = nsys;
        [nsys linkobject: t];
	break;
      case TEXTBOX:
        if (SUBTYPEOF(p) == TITLE)
	{
	  t = [(TextGraphic *) p newFrom];
	  ((TextGraphic *)t)->client = nsys;
	  [nsys linkobject: t];
	}
	else if (SUBTYPEOF(p) == STAFFHEAD)
	{
	  sp1 = staffmap[[((TextGraphic *)p)->client myIndex]];
	  if (sp1 == nil) continue;
	  t = [(TextGraphic *) p newFrom];
	  ((TextGraphic *)t)->client = sp1;
	  [nsys linkobject: t];
	}
	break;
      case RUNNER:
	t = [(Runner *) p newFrom];
	((Runner *)t)->client = nsys;
	[nsys linkobject: t];
	break;
    }
  }
  return self;
}


static void addBarsRest(Staff *sp, System *sys, int n)
{
  int a;
  StaffObj *p;
  NSMutableArray *nl = sp->notes;
  a = [sp skipSigIx: [sp indexOfNoteAfter: [sys leftWhitespace]]];
  p = [Rest newBarsRest: n];
  [nl insertObject:p atIndex:a];
  p->mystaff = sp;
  p = [[Barline alloc] init];
  p->mystaff = sp;
  [nl insertObject:p atIndex:a + 1];
}


- finishExtraction
{
  [self renumSystems];
  [self recalcAllSys];
  [self doPaginate];
  [self renumPages];
  [self setRunnerTables];
  [self balancePages];
  [self firstPage: self];
  [self formatAll: self];
  {
    id newVar = [self window];
    [newVar enableFlushWindow];
    [newVar flushWindowIfNeeded];
}
  return self;
}


/*
  Extract parts in which desired parts are designated
*/

- extractParts: (NSMutableArray *) pl
{
  int i, j, nsys, ns, n, barsrest[NUMSTAVES];
  Staff *sp, *esp;
  System *sys, *esys=nil;
  NSMutableArray *sl, *epl;
  DrawDocument *doc;
  GraphicView *v;
  BOOL hassys, wantstaff[NUMSTAVES];
  
  [self deselectAll: self];
  epl = [[NSMutableArray alloc] init];
  [epl addObject: [[CallPart alloc] init: nullPart : nil : 1 : nullInstrument]];
  for (i = 0; i < NUMSTAVES; i++) barsrest[i] = 0;
  nsys = [syslist count];
  doc = [[NSApp currentDocument] newFrom];
  v = doc->view;
  [[v window] disableFlushWindow];
  for (i = 0; i < nsys; i++)
  {
    sys = [syslist objectAtIndex:i];
    hassys = NO;
    sl = sys->staves;
    ns = sys->flags.nstaves;
    /* first pass tries to find relevant staves */
    n = 0;
    for (j = 0; j < ns; j++)
    {
      wantstaff[j] = 0;
      sp = [sl objectAtIndex:j];
      if ([sp hasAnyPart: pl])
      {
        wantstaff[j] = YES;
	++n;
      }
    }
    /* now do normal thing */
    for (j = 0; j < ns; j++)
    {
      sp = [sl objectAtIndex:j];
      if (wantstaff[j] == 0) staffmap[j] = nil;
      else
      {
        if (sp->flags.hidden || [sp allRests])
	{
	  barsrest[j] += [sp countRests];
	}
	else
	{
	  if (!hassys)
	  {
	    esys = [sys newExtraction: v : n];
	    hassys = YES;
	  }
          esp = [sp newFrom];
	  staffmap[j] = esp;
	  esp->mysys = esys;
	  [self copyNotes: sp->notes : esp : epl];
	  [esys->staves addObject: esp];
	  if (barsrest[j]) 
	  {
	    addBarsRest(esp, esys, barsrest[j]);
	    barsrest[j] = 0;
	  }
	}
      }
    }
    if (hassys)
    {
      [self copyObjs: sys : esys];
      [v->syslist addObject: esys];
    }
  }
  if (barsrest[j]) /* any left over */
  {
    /* do something! */
  
    /* do something! */
  }
  if (v->partlist) [v->partlist autorelease]; //sb: List is freed rather than released
  v->partlist = epl;
  [v finishExtraction];
  [doc->documentWindow makeKeyAndOrderFront:doc];
  return self;
}

- (NSArray *) partList
{
    return [NSArray arrayWithArray: partlist];
}

/*
  Extract parts in which desired staves are designated
*/

- extractStaves: (int) n : (char *) wantstaff
{
  int i, j, nsys, ns, barsrest[NUMSTAVES];
  Staff *sp, *esp;
  System *sys, *esys=nil;
  NSMutableArray *sl, *epl;
  DrawDocument *doc;
  GraphicView *v;
  BOOL hassys;
  epl = [[NSMutableArray alloc] init];
  [epl addObject: [[CallPart alloc] init: nullPart : nil : 1 : nullInstrument]];
  [self deselectAll: self];
  for (i = 0; i < NUMSTAVES; i++) barsrest[i] = 0;
  nsys = [syslist count];
  doc = [[NSApp currentDocument] newFrom];
  v = doc->view;
  [[v window] disableFlushWindow];
  for (i = 0; i < nsys; i++)
  {
    sys = [syslist objectAtIndex:i];
    hassys = NO;
    sl = sys->staves;
    ns = sys->flags.nstaves;
    for (j = 0; j < ns; j++)
    {
      sp = [sl objectAtIndex:j];
      if (wantstaff[j] == 0) staffmap[j] = nil;
      else
      {
        if (sp->flags.hidden || [sp allRests])
	{
	  barsrest[j] += [sp countRests];
	}
	else
	{
	  if (!hassys)
	  {
	    esys = [sys newExtraction: v : n];
	    hassys = YES;
	  }
          esp = [sp newFrom];
	  staffmap[j] = esp;
	  esp->mysys = esys;
	  [self copyNotes: sp->notes : esp : epl];
	  [esys->staves addObject: esp];
	  if (barsrest[j]) 
	  {
	    addBarsRest(esp, esys, barsrest[j]);
	    barsrest[j] = 0;
	  }
	}
      }
    }
    if (hassys)
    {
      [self copyObjs: sys : esys];
      [v->syslist addObject: esys];
    }
  }
  if (barsrest[j]) /* any left over */
  {
    /* do something! */
  
    /* do something! */
  }
  if (v->partlist) [v->partlist autorelease]; //sb: List is freed rather than released
  v->partlist = epl;
  [v finishExtraction];
  [doc->documentWindow makeKeyAndOrderFront:doc];
  return self;
}


static void orderStaves(System *sys, char *order)
{
  int sn, j;
  NSMutableArray *sl, *nsl;
  sl = sys->staves;
  sn = [sl count];
  nsl = [[NSMutableArray alloc] init];
  for (j = 0; j < sn; j++) [nsl addObject: [sl objectAtIndex:order[j]]];
  [sl autorelease]; //sb: List is freed rather than released
  sys->staves = nsl;
}


- orderCurrStaves: (System *) sys : (char *) order
{
  orderStaves(sys, order);
  [sys recalc];
  [self resetPage: currentPage];
  return self;
}


- orderAllStaves: (char *) order
{
  int i, nsys;
  nsys = [syslist count];
  for (i = 0; i < nsys; i++) orderStaves([syslist objectAtIndex:i], order);
  [self recalcAllSys];
  [self balancePages];
  [self setNeedsDisplay:YES];
  return self;
}


@end
