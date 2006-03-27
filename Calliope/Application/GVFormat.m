/* 
  $Id$
  Routines for handling the systemlist, pagelist, and formatting
*/

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "GVFormat.h"
#import "GVCommands.h"
#import "GVSelection.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "Staff.h"
#import "StaffObj.h"
#import "System.h"
#import "SysInspector.h"
#import "SysAdjust.h"
#import "SysCommands.h"
#import "Page.h"
#import "Margin.h"
#import "Bracket.h"
#import "TextGraphic.h"
#import "Tablature.h"
#import "SyncScrollView.h"
#import "Rest.h"
#import "Barline.h"
#import "Runner.h"
#import "Range.h"
#import "TimeSig.h"
#import "mux.h"
#import "ProgressDisplay.h"

extern NSSize paperSize;

@implementation GraphicView(GVFormat)


/*
  Various system handling routines.
  Some (with sender) are called from menu, so they do their own redisplay.
*/

/* link in new system ns after existing system s */

- linkSystem: (System *) s : (System *) ns
{
  if ([syslist count] == 0 || s == nil)
  {
    [syslist addObject: ns];
    currentSystem = ns;
    ns->gFlags.selected = 1;
  }
  else [syslist insertObject:ns atIndex:([syslist indexOfObject:s] + 1)];
  return s;
}


/* specify a new currentSystem */

- thisSystem: (System *) s
{
    if (currentSystem != nil) 
	currentSystem->gFlags.selected = 0;
    currentSystem = s;
    s->gFlags.selected = 1;
    return s;
}


/*
  Look back through previous systems to find the last verse number vn
  of staff sn, and return its hyphen code.  Worth the trouble.
*/

- (int) prevHyphened: sys : (int) sn : (int) vn : (int) vc
{
  int i, h;
  Staff *sp;
  i = [syslist indexOfObject:sys];
  while (i--)
  {
    sp = [[syslist objectAtIndex:i] getVisStaff: sn];
    if (sp == nil) return 0;
    h = [sp lastHyphen: vn : vc];
    if (h >= 0) return h;
  }
  return 0;
}


- (Staff *) nextStaff: sys : (int) sn
{
  int i = [syslist indexOfObject:sys];
  System *s = [syslist objectAtIndex:i + 1];
  if (s == nil) return nil;
  return [s getVisStaff: sn];
}


- (Staff *) prevStaff: sys : (int) sn
{
  System *s;
  int i = [syslist indexOfObject:sys];
  if (i == 0 || i == NSNotFound) return nil;
  s = [syslist objectAtIndex:i - 1];
  if (s == nil) return nil;
  return [s getVisStaff: sn];
}

/*
  Look back through sys and previous systems to find the last object of type t
  on staff sn.  Used for making new systems, laying out bars, etc.
  Option whether to extend search past current system.
*/

- lastObject: sys : (int) sn : (int) t : (BOOL) all
{
  int i, j;
  NSMutableArray *nl;
  Staff *sp;
  StaffObj *p;
  i = [syslist indexOfObject:sys] + 1;
  while (i--)
  {
    sp = [[syslist objectAtIndex:i] getstaff: sn];
    if (sp == nil) return nil;
    nl = sp->notes;
    j = [nl count];
    while (j--)
    {
      p = [nl objectAtIndex:j];
      if (TYPEOF(p) == t) return p;
    }
    if (!all) return nil;
  }
  return nil;
}


/* Look back from staffobject to find previous one on staff, even on prev systems */

- prevNote: (StaffObj *) p
{
  Staff *sp;
  int sn, i, v;
  StaffObj *q, *r;
  sp = p->mystaff;
  if (TYPEOF(p->mystaff) == SYSTEM) return nil;
  v = p->voice;
  sn = [sp myIndex];
  r = p;
  while (1)
  {
    q = [sp prevNote: r];
    if (q == nil) break;
    if (q->voice == v) return q;
    r = q;
  }
  i = [syslist indexOfObject:sp->mysys];
  while (i--)
  {
    sp = [[syslist objectAtIndex:i] getstaff: sn];
    if (sp == nil) continue;
    q = [sp->notes lastObject];
    if (q != nil) return q;
  }
  return nil;
}


/* Look on from staffobject to find next one on staff, even on next systems */

- nextNote: (StaffObj *) p
{
  Staff *sp;
  int sn, i, k, v;
  StaffObj *q, *r;
  sp = p->mystaff;
  if (TYPEOF(p->mystaff) == SYSTEM) return nil;
  v = p->voice;
  sn = [sp myIndex];
  r = p;
  while (1)
  {
    q = [sp nextNote: r];
    if (q == nil) break;
    if (q->voice ==v) return q;
    r = q;
  }
  i = [syslist indexOfObject:sp->mysys];
  k = [syslist count];
  while (i < k - 1)
  {
    i++;
    sp = [[syslist objectAtIndex:i] getstaff: sn];
    if (sp == nil) continue;
//    q = [sp->notes objectAtIndex:0];
//    if (q != nil) return q;
    if ([sp->notes count]) return [sp->notes objectAtIndex:0];
  }
  return nil;
}


/* look through page for closest system */

- (System *) findSys: (float) y 
{
  int i, j, k;
  System *sys, *minsys = nil;
  Staff *sp;
  float dy, miny = MAXFLOAT;
  i = currentPage->topsys;
  j = currentPage->botsys;
  for (k = i; k <= j; k++)
  {
    sys = [syslist objectAtIndex:k];
    if (sys == nil) continue;
    sp = [sys firststaff];
    if (sp != nil)
    {
      dy = y - sp->y;
      if (dy < 0) dy = -dy;
      if (dy < miny)
      {
        miny = dy;
        minsys = sys;
      }
    }
    sp = [sys lastStaff];
    if (sp != nil)
    {
      dy = y - [sp yOfBottom];
      if (dy < 0) dy = -dy;
      if (dy < miny)
      {
        miny = dy;
        minsys = sys;
      }
    }
  }
  return minsys;
}


/* return various information for error messages */

- sysOffAndPageNum: (System *) sys : (int *) sn : (int *) pn
{
  int i = [syslist indexOfObject:sys];
  Page *p = sys->page;
  *sn = i - p->topsys + 1;
  *pn = [p pageNumber];
  return self;
}


/* return page offset to find page on which StaffObject p is found */

- (int) findPageOff: (StaffObj *) p
{
  return [pagelist indexOfObject:((System *)[p mySystem])->page]
          - [pagelist indexOfObject:currentPage];
}


/* reset the fields in the scrollerview */

- resetPageFields
{
  NSString *buf;
  int pk = 0, pi;
  Page *pg = currentPage;
  if (pg == nil)
  {
    [delegate setMessage: @""];
    return self;
  }
  [delegate setPageNum: [pg pageNumber]];
  pk = [pagelist count];
  if (pk > 0)
  {
    pg = [pagelist objectAtIndex:0];
    pi = [pg pageNumber];
    pg = [pagelist lastObject];
    pk = [pg pageNumber];
    buf = [NSString stringWithFormat:@"(%d-%d)", pi, pk];
  }
  else buf = @"";
  [delegate setMessage: buf];
  return self;
}


/*
  find page by indexMethod = 0: offset from current page, 1: by page index,
  2: by printed page number, 3: by system index,
  4: by index relative to currentsystem.
  Sets currentSystem to top of page except indexMethod = 3,4.
*/

- (BOOL) findPage: (int) n usingIndexMethod: (GraphicViewIndexMethod) indexMethod
{
    int i;
    Page *p = nil;
    BOOL f = NO;
    int pageCount = [pagelist count];
    
    switch(indexMethod)
    {
	case 0:
	    n += [pagelist indexOfObject:currentPage];
	    break;
	case 1:
	    break;
	case 2:
	    for (i = 0; (i < pageCount && !f); i++)
	    {
		p = [pagelist objectAtIndex:i];
		if ([p pageNumber] == n) { f = YES; break; }
	    }
	    if (f == NO) return NO;
	    n = i;
	    break;
	case 4:
	    if (currentSystem == nil) return NO;
	    n += [syslist indexOfObject:currentSystem];
	    /* drop through */
	case 3:
	    for (i = 0; (i < pageCount && !f); i++)
	    {
		p = [pagelist objectAtIndex:i];
		if (p->topsys <= n && n <= p->botsys)  { f = YES; break; };
	    }
	    if (f == NO) return NO;
	    if (currentPage) [currentPage autorelease];
		currentPage = [p retain];
	    [self thisSystem: [syslist objectAtIndex: n]];
	    return YES;
	    break;
    }
    if (n < 0 || n >= pageCount) 
	return NO;
    if (currentPage) 
	[currentPage autorelease];
    currentPage = [[pagelist objectAtIndex: n] retain];
    [self thisSystem: [syslist objectAtIndex: currentPage->topsys]];
    return YES;
}


- gotoPage: (int) pageNumber usingIndexMethod: (GraphicViewIndexMethod) indexMethod
{
    if ([self findPage: pageNumber usingIndexMethod: indexMethod])
    {
        [[self window] endEditingFor: self];
        [self setNeedsDisplay: YES];
        [self resetPageFields];
        // [[DrawApp sharedApplicationController] inspectApp]; // TODO LMS disabled to get things running.
        return self;
    }
    else
	NSLog(@"Unable to find page %d using index method %d", pageNumber, indexMethod);
    return nil;
}


- prevPage: sender
{
  return [self gotoPage: -1 usingIndexMethod: 0];
}


- nextPage: sender
{
  return [self gotoPage: 1 usingIndexMethod: 0];
}


- firstPage: sender
{
  return [self gotoPage: 0 usingIndexMethod: 1];
}


- lastPage: sender
{
  return [self gotoPage: (int)[pagelist count] - 1 usingIndexMethod: 1];
}


- getSystem: sys offsetBy: (int) off
{
  return [syslist objectAtIndex: [syslist indexOfObject: sys] + off];
}


- findSysOfStyle: (NSString *) styleToFind
{
    System *st, *sys = currentSystem;
    int k = [syslist count];
    int i = [syslist indexOfObject:sys] + 1;
    int pageIndex;
    
    for (pageIndex = i; pageIndex < k; pageIndex++)
    {
	st = [syslist objectAtIndex: pageIndex];
	if ([st->style isEqualToString: styleToFind])
	{
	    [self gotoPage: pageIndex usingIndexMethod: 3];
	    return self;
	}
    }
    NSLog(@"Could not find system of style %@", styleToFind);
    return self;
}


- (float) yBetween: (int) sn
{
  Staff *sp;
  float ym;
  sp = [[syslist objectAtIndex:sn] lastStaff];
  ym = [sp yOfBottom];
  sp = [[syslist objectAtIndex:sn + 1] firststaff];
  return ym + (0.5 * (sp->y - ym));
}


/*
  Document Pagination
*/

/*
  return amount to be subtracted from sysheights to recognise
  staff alignment options against top/bottom margins.
*/

- (float) alignShave: (Page *) p
{
  float sy = 0.0;
  System *s;
  if ([p alignToTopSystem])
  {
    s = [syslist objectAtIndex:p->topsys];
    if (![s hasTitles]) sy += [s headroom];
  }
  if ([p alignToBottomSystem])
  {
    s = [syslist objectAtIndex:p->botsys];
    sy += [s myHeight] - ([[s lastStaff] yOfBottom] - (((Staff *)[s firststaff])->y - [s headroom]));
  }
  return sy;
}


/*
  Return the y where the top of the page is to begin.  Default top
  margin, but depends on alignment option.
*/

- (float) startTop: (System *) s : (Page *) p
{
    float y = [p topMargin];
    if ([p alignToTopSystem] && ![s hasTitles])
	y -= [s headroom];
    return y;
}



/* choice when first|last page */

char autochoice[4] = {PGAUTO, PGTOP, PGBOTTOM, PGTOP};

/*
  readjust system locations on page. if sumheights == 0.0, then recompute it.
  return ratio of (sumheights / pageheight)
*/

- (float) balanceSystems: (Page *) p
{
  float y, dy=0.0, white, sep, defsep, sumheights;
  System *s;
  int i, nsys;
  PageFormat pc;
  BOOL lastp, firstp;
  
  defsep = [[DrawApp currentDocument] getPreferenceAsFloat: MAXBALGAP];
  sumheights = 0.0;
  for (i = p->topsys; i <= p->botsys; i++) sumheights += [[syslist objectAtIndex:i] myHeight];
  sumheights -= [self alignShave: p];
  white = [p fillHeight] - sumheights;
  lastp = ((p == [pagelist lastObject]) && white > 0);
  firstp = (p == [pagelist objectAtIndex:0]);
  nsys = p->botsys - p->topsys + 1;
  pc = [p format];
  if (pc == PGAUTO) pc = autochoice[(firstp << 1) | lastp];
  y = [self startTop: [syslist objectAtIndex:p->topsys] : p];
  switch(pc)
  {
    case PGBALANCE:
      dy = white / (nsys + 1);
      y += dy;
      break;
    case PGBOTTOM:
      if (nsys > 1)
      {
        sep = white / (nsys - 1);
        if (sep > defsep) sep = defsep;
        y += white - (sep * (nsys - 1));
        dy = sep;
      }
      else
      {
        y += white;
	dy = 0.0;
      }
      break;
    case PGAUTO:
    case PGSPREAD:
      dy = (nsys == 1) ? 0.0 : (white / nsys);
      break;
    case PGTOP:
      sep = white / nsys;
      if (sep > defsep) sep = defsep;
      dy = sep;
      break;
    case PGCENTRE:
      if (nsys == 1)
      {
        dy = 0.0;
	y += white / 2.0;
      }
      else
      {
        sep = white / (nsys - 1);
        if (sep > defsep) sep = defsep;
        dy = sep;
        y += (white - (sep * (nsys - 1))) / 2.0;
      }
      break;
    case PGEXPAND:
      dy = (nsys == 1) ? 0.0 : white / (nsys - 1);
      break;
    case PGPACKTOP:
      dy = 0.0;
      break;
    case PGPACKBOT:
      dy = 0.0;
      y += white;
      break;
  }
  for (i = p->topsys; i <= p->botsys; i++)
  {
    s = [syslist objectAtIndex:i];
    [s moveTo: y];
    y += [s myHeight] + dy;
  }
  return (sumheights / [p fillHeight]);
}


/* stash away the current left margin in case a shuffle is needed */

- saveSysLeftMargin
{
  System *sys;
  int k = [syslist count];
  while (k--)
  {
    sys = [syslist objectAtIndex:k];
    sys->oldleft = [sys leftMargin];
  }
  return self;
}

- shuffleIfNeeded
{
  System *sys;
  int i, systemIndex = [syslist count];
  ProgressDisplay *shuffleProgress = [ProgressDisplay progressDisplayWithTitle: @"Laying Out Margins"];
  
  for (i = 0; i < systemIndex; i++)
  {
    sys = [syslist objectAtIndex:i];
    if (sys->oldleft != [sys leftMargin]) [sys shuffleNotes: sys->oldleft : [sys leftMargin]];
    [shuffleProgress setProgressRatio: ((float) i) / systemIndex];
  }
  [shuffleProgress closeProgressDisplay];
  return self;
}

/*
  reset all the runner tables (caches) inside all the Pages.
  Done whenever runners/pages/margins are changed.
*/

- setRunnerTables
{
    int pageIndex, j, pageCount, firstSystem, s1, ok;
    Page *pg, *lp;
    NSMutableArray *ol;
    
    pageCount = [pagelist count];
    lp = nil;
    for (pageIndex = 0; pageIndex < pageCount; pageIndex++)
    {
	pg = [pagelist objectAtIndex: pageIndex];
	if(lp == nil)
	    pg = [[Page alloc] initWithPageNumber: 0 topSystemNumber: 0 bottomSystemNumber: 0];
	else {
	    // otherwise what is wanted is assigning parameters from the previous to current. */
	    pg = [lp copy];
	}
	firstSystem = pg->topsys;
	s1 = pg->botsys;
	for (j = firstSystem; j <= s1; j++)
	{
	    System *sys = [syslist objectAtIndex: j];
	    ol = sys->objs;
	    ok = [ol count];
	    while (ok--) {
		// Since Runners do not hold the back pointer to Page, all this does is assign Runners to Page.
		[pg setRunner: [ol objectAtIndex: ok]];
	    }
	}
	lp = pg;
    }
    return self;
}

// what is "done" when we doPage? Actually we assign systems to pages.
// Should be in the model.
- (id) doPage: (int) p 
  fromFirstSystem: (int) firstSystem
       forSystems: (int) numberOfSystemsOnPage 
		 : (float) sh 
		 : (float) him 
      usingMargin: (Margin *) newMargin 
outOfTotalSystems: (int) numsys
{
    int systemIndex, lastSystem = firstSystem + numberOfSystemsOnPage - 1;
    Page *pg = [[Page alloc] initWithPageNumber: p topSystemNumber: firstSystem bottomSystemNumber: lastSystem];
    
    [pg setMargin: newMargin];
    [pg setFillHeight: him];
    for (systemIndex = firstSystem; systemIndex <= lastSystem; systemIndex++)
    {
	System *sys = [syslist objectAtIndex: systemIndex];
	sys->page = pg;
    }
    [pagelist addObject: pg];
    // [pageProgress setProgressRatio: 1.0 * lastSystem / numsys];
    return self;
}


/*
  Caller needs to:
    [ set up progress panel]
    [self saveSysLeftMargin];
    [self renumSystems];
->  [self doPaginate] (will set progress ratio).
    [self renumPages];
    [self setRunnerTables];
    [self shuffleIfNeeded];
    [self balancePages];
    [ dismiss progress panel]
  balances systems in a second pass because each new system is the 'last' one,
  hence balancing would be misled if done in first pass.
  sheight is staffheight; used to estimate minimum spacing between systems.
*/


- doPaginate
{
    int i, systemCount, p, numberOfSystemsOnPage, firstSystem;
    float h=0.0, sh, him = 0.0, pheight, sheight;
    Margin *newMargin = nil;
    System *sys;
    
    systemCount = [syslist count];
    if (systemCount < 1)
	return nil;
    sys = [syslist objectAtIndex:0];
    if (![sys checkMargin])
    {
	NSLog(@"Cannot paginate: first system has no margins\n");
	return nil;
    }
    numberOfSystemsOnPage = firstSystem = 0;
    p = 1;
    pheight = [self bounds].size.height;
    sheight = [[DrawApp currentDocument] getPreferenceAsFloat: MINSYSGAP];
    sh = 0.0;
    if (pagelist != nil) 
	[pagelist autorelease]; //sb: List is freed rather than released
    pagelist = [[NSMutableArray allocWithZone:[self zone]] init];
    for (i = 0; i < systemCount; i++)
    {
	sys = [syslist objectAtIndex:i];
	if (sys->flags.newpage) p = [sys pageNumber];
	h = [sys myHeight];
	newMargin = [sys checkMargin];
	if (newMargin)
	{
	    if (numberOfSystemsOnPage > 0)
	    {
		[self doPage: p 
	     fromFirstSystem: firstSystem 
		  forSystems: numberOfSystemsOnPage 
			    : sh 
			    : him 
		 usingMargin: newMargin 
	   outOfTotalSystems: systemCount];
		sh = h;
		firstSystem = i;
		numberOfSystemsOnPage = 1;
		++p;
	    }
	    else
	    {
		sh += h;
		++numberOfSystemsOnPage;
	    }
	    him = pheight - ([newMargin topMargin] + [newMargin bottomMargin]);
	}
	else if (sys->flags.pgcontrol == 0 && numberOfSystemsOnPage > 0 && sh + h + ((numberOfSystemsOnPage - 1) * sheight) > him)
	{
	    if (numberOfSystemsOnPage == 1 && h > him) 
		NSLog(@"System overflows page %d", [sys pageNumber]);
	    [self doPage: p 
	 fromFirstSystem: firstSystem 
	      forSystems: numberOfSystemsOnPage 
			: sh 
			: him 
	     usingMargin: newMargin 
       outOfTotalSystems: systemCount];
	    sh = h;
	    firstSystem = i;
	    numberOfSystemsOnPage = 1;
	    ++p;
	}
	else
	{
	    sh += h;
	    ++numberOfSystemsOnPage;
	}
    }
    if (numberOfSystemsOnPage > 0)
    {
	if (numberOfSystemsOnPage == 1 && h > him) 
	    NSLog(@"System overflows page %d", [sys pageNumber]);
	[self doPage: p 
     fromFirstSystem: firstSystem 
	  forSystems: numberOfSystemsOnPage 
		    : sh 
		    : him 
	 usingMargin: newMargin 
   outOfTotalSystems: systemCount];
    }
    return self;
}


- balancePages
{
  int i, k;
  ProgressDisplay *balanceProgress = [ProgressDisplay progressDisplayWithTitle: @"Balance Pages"];
  k = [pagelist count];
  for (i = 0; i < k; i++)
  {
    [balanceProgress setProgressRatio: 1.0 * i / k];
    [self balanceSystems: [pagelist objectAtIndex:i]];
  }
  [balanceProgress closeProgressDisplay];
  return self;
}


/*
  renumber the systems and pages.
  Handle bar numbers, pagenumbers.
  The skip is done because the staff might start with a barline.
*/


- renumSystems
{
  int i, j, k, ns, n, b, pn[NUMSTAVES];
  StaffObj *p;
  System *sys;
  Staff *sp;
  NSMutableArray *al;
  k = [syslist count];
  b = 1;
  for (i = 0; i < NUMSTAVES; i++) pn[i] = 0;
  for (i = 0; i < k; i++)
  {
    sys = [syslist objectAtIndex:i];
    if (sys->flags.newbar) b = sys->barnum; else sys->barnum = b;
    al = sys->staves;
    ns = sys->flags.nstaves;
    if (i == k - 1) break;
    sp = [sys firststaff];
    if (sp == nil) continue;
    al = sp->notes;
    n = [al count];
    j = [sp indexOfNoteAfter: [sys leftWhitespace]];
    /* skips until after first timed object or before first barsrest. */
    while (j < n)
    {
      p = [al objectAtIndex:j];
      if (TYPEOF(p) == REST && [(Rest *)p isBarsRest]) break;
      ++j;
      if (ISATIMEDOBJ(p)) break;
    }
    while (j < n)
    {
      p = [al objectAtIndex:j];
      if (TYPEOF(p) == BARLINE || TYPEOF(p) == REST) b += [p barCount];
      ++j; 
    }
  }
  return self;
}


- renumPages
{
    int i, j, k, r;
    Page *pg;
    System *sys;
    k = [pagelist count];
    j = 1;
    for (i = 0; i < k; i++)
    {
	pg = [pagelist objectAtIndex:i];
	for (r = pg->topsys; r <= pg->botsys; r++)
	{
	    sys = [syslist objectAtIndex:r];
	    if (sys->flags.newpage) 
		j = [sys pageNumber];
	    else 
		[sys setPageNumber: j];
	}
	[pg setPageNumber: j];
	++j;
    }
    [self resetPageFields];
    return self;
}


/* set the ranges of the piece */

- setRanges
{
  Range *r[NUMSTAVES];
  int nsys, ns=0, i, j, k, n, pos, pb, minp[NUMSTAVES], maxp[NUMSTAVES];
  NSMutableArray *al, *sl;
  System *sys;
  Staff *sp;
  StaffObj *p;
  BOOL flag[NUMSTAVES];
  for (i = 0; i < NUMSTAVES; i++)
  {
    r[i] = nil;
    flag[i] = NO;
  }
  nsys = [syslist count];
  for (i = 0; i < nsys; i++)
  {
    sys = [syslist objectAtIndex:i];
    sl = sys->staves;
    ns = sys->flags.nstaves;
    for (j = 0; j < ns; j++)
    {
      sp = [sl objectAtIndex:j];
      pb = [sp posOfBottom];
      al = sp->notes;
      n = [al count];
      for (k = 0; k < n; k++)
      {
        p = [al objectAtIndex:k];
        if (TYPEOF(p) == RANGE)
        {
          if (r[j] != nil)
          {
            r[j]->p2 = minp[j];
            r[j]->p1 = maxp[j];
	    [r[j] recalc];
          }
          r[j] = (Range *) p;
          flag[j] = NO;
        }
        else if (ISAVOCAL(p))
        {
	  pos = p->p;
	  if (pos < -8 || pos > pb + 8)
	  {
	    NSLog(@"note %d of staff %d, sys %d has pos %d\n", k, j, i, pos);
	  }
	  if (!ISINVIS(p))
	  {
            if (flag[j])
            {
              if (pos < minp[j]) minp[j] = pos;
              if (pos > maxp[j]) maxp[j] = pos;
            }
            else
            {
              minp[j] = maxp[j] = pos;
              flag[j] = YES;
            }
	  }
        }
      }
    }
  }
  for (i = 0; i < ns; i++) if (r[i] != nil && flag[i])
  {
    r[i]->p2 = minp[i];
    r[i]->p1 = maxp[i];
    [r[i] recalc];
  }
  return self;
}


/*
   propagate the time signature information up to arg inclusive.
   This is the proportionality factor, and the number of ticks in the
   bar (bart) used for whole-bar rests.
*/

#define MINIMTICK 64

- flowTimeSig: (System *) until
{
  int nsys, ns, i, j, k, n, bart[NUMSTAVES];
  float fact[NUMSTAVES];
  System *sys;
  Staff *sp;
  TimedObj *p;
  NSMutableArray *nl, *sl;
  nsys = [syslist count];
  for (i = 0; i < NUMSTAVES; i++)
  {
    fact[i] = 1.0;
    bart[i] = MINIMTICK * 2;
  }
  for (i = 0; i < nsys; i++)
  {
    sys = [syslist objectAtIndex:i];
    sl = sys->staves;
    ns = sys->flags.nstaves;
    for (j = 0; j < ns; j++)
    {
      sp = [sl objectAtIndex:j];
      nl = sp->notes;
      k = [nl count];
      for (n = 0; n < k; n++)
      {
        p = [nl objectAtIndex:n];
	if (TYPEOF(p) == TIMESIG)
	{
	  fact[j] = [((TimeSig *)p) myFactor: 0];
	  bart[j] = [((TimeSig *)p) myBarLength];
	}
        else if (ISATIMEDOBJ(p))
	{
	  p->time.factor = fact[j];
	  if (TYPEOF(p) == REST) ((Rest *)p)->barticks = bart[j];
	}
      }
    }
    if (sys == until) break;
  }
  return self;
}


/*
  Page p has just added/subtracted (+/-) i systems.
  Assume there is something left.
  Reset all the page's top/bot indices.
*/

- resetPagelist: (Page *) p : (int) i;
{
  int j, k, ip;
  k = [pagelist count];
  p->botsys += i;
  ip = [pagelist indexOfObject:p] + 1;
  for (j = ip; j < k; j++)
  {
    p = [pagelist objectAtIndex:j];
    p->topsys += i;
    p->botsys += i;
  }
  [self renumSystems];
  [self renumPages];
  return self;
}


- resetPage: p
{
  [self balanceSystems: p];
    [self setNeedsDisplay:YES];
  return self;
}


/* used for spill and grab */

- resetPagesOn:  (System *) s1 : (System *) s2
{
  Page *p1, *p2;
  p1 = s1->page;
  [self  balanceSystems: p1];
  p2 = s2->page;
  if (p1 != p2) [self  balanceSystems: p2];
  return self;
}


/*
  sys is known to be on a page that has had a system modification, involving
  the addition or removal of another i systems.  Check for special case of
  removing all systems. Reset page, and only paginate if the reset page is
  too tight or too loose.  Whether ask-if-loose depends on f.
*/

- (BOOL) balanceOrAsk: (Page *) p : (int) i : (int) f
{
  float w;
  w = [self balanceSystems: p];
  [self setNeedsDisplay:YES];
  if (w > 1.2)
  {
     [self paginate: self];
     return YES;
  }
  else if (((w < 0.5 && f) || w > 0.99) && (p != [pagelist lastObject]))
  {
   i = NSRunAlertPanel(@"Calliope", @"Paginate?", @"YES", @"NO", nil);
   if (i == NSAlertDefaultReturn)
   {
     [self paginate: self];
     return YES;
   }
  }
  return NO;
}


- simplePaginate: (System *) sys : (int) i : (int) f
{
  Page *p = sys->page;
  if (p == nil)
  {
    [self paginate: self];
    return self;
  }
  [self resetPagelist: p : i];
  if (![self balanceOrAsk: p : i : f]) {
      [self setNeedsDisplay:YES];
  }
  return self;
}

@end
