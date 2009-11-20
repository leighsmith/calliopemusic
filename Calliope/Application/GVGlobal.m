#import "GraphicView.h"
#import "GVFormat.h"
#import "GVCommands.h"
#import "GVGlobal.h"
#import "OpusDocument.h"
#import "CalliopeAppController.h"
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
#import "DrawingFunctions.h"
#import "muxlow.h"
#import <AppKit/AppKit.h>

@implementation GraphicView(GVGlobal)

static Staff *staffmap[NUMSTAVES]; /* indexed by old staff, points to new staff */


- (BOOL) sysSameShape
{
  int k, n;
  System *sys;
  if (currentSystem == nil) return NO;
  n = [currentSystem numberOfStaves];
  k = [syslist count];
  while (k--)
  {
    sys = [syslist objectAtIndex:k];
    if ([sys numberOfStaves] != n) return NO;
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
    [p setStaff: sp];
    if ([pl partNamed: [p partName]] == nil)
    {
      [pl addObject: [[opl partNamed: [p partName]] newFrom]];
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
  NSMutableArray *ol = osys->nonStaffGraphics;
  if ([nsys numberOfStaves] > 1) makeLinkage(nsys);
  else
  {
    sp1 = [osys getStaff: 0];
    if (sp1->flags.haspref) makeLinkage(nsys);
  }
  i = [ol count];
  while (i--)
  {
    p = [ol objectAtIndex:i];
    switch([p graphicType])
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
        t = [(Margin *) p copy];
	  [(Margin *) t setClient: nsys];
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
      default:
        NSLog(@"copyObjs: Unexpected graphicType: %d\n", [p graphicType]);
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
  [p setStaff: sp];
  p = [[Barline alloc] init];
  [p setStaff: sp];
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
  NSMutableArray *epl;
  OpusDocument *doc;
  GraphicView *v;
  BOOL hassys, wantstaff[NUMSTAVES];
  
  [self deselectAll: self];
  epl = [[NSMutableArray alloc] init];
  [epl addObject: [[CallPart alloc] init: nullPart : nil : 1 : nullInstrument]];
  for (i = 0; i < NUMSTAVES; i++) barsrest[i] = 0;
  nsys = [syslist count];
  doc = [[CalliopeAppController currentDocument] newFrom];
  v = [doc graphicView];
  [[v window] disableFlushWindow];
  for (i = 0; i < nsys; i++)
  {
    sys = [syslist objectAtIndex:i];
    hassys = NO;
    ns = [sys numberOfStaves];
    /* first pass tries to find relevant staves */
    n = 0;
    for (j = 0; j < ns; j++)
    {
      wantstaff[j] = 0;
      sp = [sys getStaff: j];
      if ([sp hasAnyPart: pl])
      {
        wantstaff[j] = YES;
	++n;
      }
    }
    /* now do normal thing */
    for (j = 0; j < ns; j++)
    {
      sp = [sys getStaff: j];
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
	  [esys addStaff: esp];
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
      [v addSystem: esys];
    }
  }
  if (barsrest[j]) /* any left over */
  {
    /* do something! */
  
    /* do something! */
  }
  if (v->partlist) [v->partlist autorelease];
  v->partlist = epl;
  [v finishExtraction];
  // [doc->documentWindow makeKeyAndOrderFront:doc];
  return self;
}

- (NSMutableArray *) partList
{
//    return [NSArray arrayWithArray: partlist];
    return [[partlist retain] autorelease];
}

/*
  Extract parts in which desired staves are designated
*/

- extractStaves: (int) n : (char *) wantstaff
{
    int i, j, nsys, ns, barsrest[NUMSTAVES];
    Staff *sp, *esp;
    System *sys, *esys=nil;
    OpusDocument *doc;
    GraphicView *v;
    BOOL hassys;
    NSMutableArray *epl = [[NSMutableArray alloc] init];
    
    [epl addObject: [[CallPart alloc] init: nullPart : nil : 1 : nullInstrument]];
    [self deselectAll: self];
    for (i = 0; i < NUMSTAVES; i++) barsrest[i] = 0;
    nsys = [syslist count];
    doc = [[CalliopeAppController currentDocument] newFrom];
    v = [doc graphicView];
    [[v window] disableFlushWindow];
    for (i = 0; i < nsys; i++) {
	sys = [syslist objectAtIndex:i];
	hassys = NO;
	ns = [sys numberOfStaves];
	for (j = 0; j < ns; j++)
	{
	    sp = [sys getStaff: j];
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
		    [esys addStaff: esp];
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
	    [v addSystem: esys];
	}
    }
    if (barsrest[j]) /* any left over */
    {
	/* do something! */
	
	/* do something! */
    }
    if (v->partlist) [v->partlist autorelease];
    v->partlist = epl;
    [v finishExtraction];
    // [doc->documentWindow makeKeyAndOrderFront:doc];
    return self;
}

- orderCurrStaves: (System *) sys by: (char *) order
{
    [sys orderStavesBy: order];
    [sys recalc];
    [self resetPage: currentPage];
    return self;
}

- orderAllStaves: (char *) order
{
  int i, nsys = [syslist count];
  
  for (i = 0; i < nsys; i++) 
      [[syslist objectAtIndex: i] orderStavesBy: order];
  [self recalcAllSys];
  [self balancePages];
  [self setNeedsDisplay:YES];
  return self;
}


@end
