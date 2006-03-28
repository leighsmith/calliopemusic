#import "SysCommands.h"
#import "SysAdjust.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVCommands.h"
#import "GVSelection.h"
#import "System.h"
#import "mux.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "muxCollide.h"
#import "Staff.h"
#import "Neume.h"
#import "Barline.h"
#import "GNote.h"
#import "NoteHead.h"
#import "TimedObj.h"
#import "Rest.h"
#import "Hanger.h"
#import "muxlow.h"
#import <Foundation/NSArray.h>
#import <AppKit/NSPanel.h>



@implementation System(SysCommands)


/* show all verses of all staves in self */

- showVerse
{
  int i, j, k, nk, vk;
  Staff *sp;
  StaffObj *p;
  NSMutableArray *nl, *vl;
  Verse *v;
  k = flags.nstaves;
  while (k--)
  {
    sp = [staves objectAtIndex:k];
    nl = sp->notes;
    nk = [nl count];
    for (i = 0; i < nk; i++)
    {
      p = [nl objectAtIndex:i];
      if ((vl = p->verses) != nil)
      {
        vk = [vl count];
        for (j = 0; j < vk; j++)
	{
	  v = [vl objectAtIndex:j];
	  v->gFlags.invis = 0;
	}
      }
    }
  }
  return self;
}


/* hide verse n of all staves in self */

- hideVerse: (int) n
{
  int k;
  k = flags.nstaves;
  while (k--) [[staves objectAtIndex:k] hideVerse: n];
  return self;
}


/*
  When left margin and indent are changed as indicated by arguments,
  move notes so that they are still within the staff widths / preface.
  Does not recalc, as done by caller in SysInspector.
*/


- shuffleNotes: (float) oldLeft : (float) newLeft
{
  int i, n, k;
  float dx, nx;
  Staff *sp;
  StaffObj *p;
  NSMutableArray *nl;
  k = flags.nstaves;
  dx = newLeft - oldLeft;
  while (k--)
  {
    sp = [staves objectAtIndex:k];
    nl = sp->notes;
    n = [nl count];
    for (i = 0; i < n; i++)
    {
      p = [nl objectAtIndex:i];
      nx = p->x + dx;
      MOVE(p, nx);
    }
  }
  [self recalcHangers];
  return self;
}


/* change the font of all visible verses in the system */

- (BOOL) changeVFont: (int) vn : (NSFont *) f
{
  int a, i, j, k, n, r, vk;
  Staff *sp;
  StaffObj *p;
  NSMutableArray *vl, *nl;
  Verse *v;
  r = NO;
  n = flags.nstaves;
  for (i = 0; i < n; i++)
  {
    sp = [staves objectAtIndex:i];
    nl = sp->notes;
    k = [nl count];
    for (j = 0; j < k; j++)
    {
      p = [nl objectAtIndex:j];
      if ((vl = p->verses) != nil)
      {
        vk = [vl count];
	if (vn < 0)
	{
          for (a = 0; a < vk; a++)
	  {
	    v = [vl objectAtIndex:a];
	    if (!ISINVIS(v))
	    {
	      r = YES;
	      v->font = f;
	    }
	  }
	}
	else if (vn < vk)
	{
	  v = [vl objectAtIndex:vn];
	  if (!ISINVIS(v))
	  {
	    r = YES;
	    v->font = f;
	  }
	}
      }
    }
  }
  return r;
}


/*
  return the majority font of one (or all) visible verse(s) in the system.
  vn < 0 for doing all verses.
  pass back whether multiple fonts.
*/

- (NSFont *) getVFont: (int) vn : (int *) m
{
  int a, i, j, k, n, vk;
  Staff *sp;
  StaffObj *p;
  NSMutableArray *vl, *nl;
  Verse *v;
  initVotes();
  n = flags.nstaves;
  for (i = 0; i < n; i++)
  {
    sp = [staves objectAtIndex:i];
    nl = sp->notes;
    k = [nl count];
    for (j = 0; j < k; j++)
    {
      p = [nl objectAtIndex:j];
      if ((vl = p->verses) != nil)
      {
        vk = [vl count];
	if (vn < 0)
	{
          for (a = 0; a < vk; a++)
	  {
	    v = [vl objectAtIndex:a];
	    if (!ISINVIS(v)) votesFor(v->font, 1);
	  }
	}
	else if (vn < vk)
	{
	  v = [vl objectAtIndex:vn];
	  if (!ISINVIS(v)) votesFor(v->font, 1);
	}
      }
    }
  }
  *m = multVotes();
  return mostVotes();
}


/*
  search self to find hangers that fall outside the interval [bix, eix]
  d is whether ones in the interval get split left or right.
  Each hanger can be split only once.
  When removing, try remove from slist in case it is there.
*/

#define NUMJOINS 128

- findSplits: (Staff *) sp : (int) bix : (int) eix : (int) d
{
  float x0, x1;
  int j, m, hk, nums, r;
  NSMutableArray *nl, *hl, *sl;
  StaffObj *p;
  Hanger *h, *splits[NUMJOINS];
  nl = sp->notes;
  p = [nl objectAtIndex:bix];
  x0 = p->x;
  p = [nl objectAtIndex:eix];
  x1 = p->x;
  nums = 0;
  for (j = bix; j <= eix; j++)
  {
    p = [nl objectAtIndex:j];
    hl = p->hangers;
    hk = [hl count];
    while (hk--)
    {
      h = [hl objectAtIndex:hk];
      r = 0;
      for (m = 0; (m < nums && !r); m++) if (h == splits[m]) r = 1;
      if (r == 0 && nums < NUMJOINS)
      {
        splits[nums] = h;
	++nums;
        if ([h needSplit: x0 : x1])
        {
	  sl = [h splitMe: x0 : x1 : d];
	  [((GraphicView *)view) splitSelect: h : sl];
	  [h removeObj];
          [sl autorelease];
	}
      }
    }
  }
  return self;
}


/*
  search self to find hangers that need to join.
  When removing, try remove from slist in case it is there.
*/

- findJoins
{
  int i, j, k, ns, hk, a, nums, m, r;
  Hanger *splits[NUMJOINS];
  int UIDs[NUMJOINS];
  float lmx;
  Staff *sp;
  NSMutableArray *nl, *hl;
  StaffObj *p;
  Hanger *h;
  ns = flags.nstaves;
  lmx = [self leftWhitespace];
  nums = 0;
  for (i = 0; i < ns; i++)
  {
    sp = [staves objectAtIndex:i];
    nl = sp->notes;
    k = [nl count];
    a = [sp skipSigIx: [sp indexOfNoteAfter: lmx]];
    for (j = a; j < k; j++)
    {
      p = [nl objectAtIndex:j];
      hl = p->hangers;
      hk = [hl count];
      while (hk--)
      {
        h = [hl objectAtIndex:hk];
	if (TYPEOF(h) == TEXTBOX) continue;
	if (h->hFlags.split)
	{
	  r = 0;
	  for (m = 0; (m < nums && !r); m++)
	  {
	    if (h == splits[m]) r = 1;
	    else if (h->UID == UIDs[m])
	    {
	      [splits[m] mergeMe: h];
	      r = 2;
	    }
	  }
	  if (r == 2)
	  {
	    [((GraphicView *)view) splitSelect: h : nil];
	    [h removeObj];
	  }
	  else if (r == 0 && nums < NUMJOINS)
	  {
	    splits[nums] = h;
	    UIDs[nums] = h->UID;
	    ++nums;
	  }
	}
      }
    }
  }
  return self;
}


/*
  Spill Bars to the next system.  This is the original algorithm,
  which does not know how to parse and handle end-staff signature format.
*/

/*
  begbar[i] index of first obj in bar to be moved.
  endbar[i] index of last obj in bar (including barline) to be moved
*/

- spillBar
{
  int i, j, k, ns, begbar[NUMSTAVES], endbar[NUMSTAVES], a, b;
  float lmx, begx, destx, widx, nx, dy;
  Staff *sp, *dsp;
  NSMutableArray *snl, *dnl;
  System *sys;
  StaffObj *p;
  ns = flags.nstaves;
  lmx = [self leftWhitespace];
  /* first find all the bar boundaries. */
  for (i = 0; i < ns; i++)
  {
    sp = [staves objectAtIndex:i];
    snl = sp->notes;
    k = [snl count] - 1;
    a = [sp skipSigIx: [sp indexOfNoteAfter: lmx]];
    endbar[i] = -1;
    begbar[i] = a;
    b = NO;
    for (j = k; (j >= a && !b); j--)
    {
      p = [snl objectAtIndex:j];
      if (TYPEOF(p) == BARLINE)
      {
        if (endbar[i] == -1)
	{
          endbar[i] = j;
	}
	else
	{
	  begbar[i] = j + 1;
	  b = YES;
	}
      }
    }
    if (b) [self findSplits: sp : begbar[i] : endbar[i] : 1];
  }
  /* find or make next system */
  sys = [view nextSystem: self : &b];
  /* find where to insert the last bar if there is one */
  for (i = 0; i < ns; i++) if (endbar[i] > -1)
  {
    sp = [staves objectAtIndex:i];
    snl = sp->notes;
    dsp = [sys->staves objectAtIndex:i];
    dy = [dsp yOfTop] - [sp yOfTop];
    dnl = dsp->notes;
    a = [dsp skipSigIx: 0];
    destx = [dsp xOfHyphmarg] + 4;
    p = [snl objectAtIndex:begbar[i]];
    begx = p->x;
    p = [snl objectAtIndex:endbar[i]];
    widx = p->x - begx;
    /* shuffle destination objects right */
    k = [dnl count];
    for (j = a; j < k; j++)
    {
      p = [dnl objectAtIndex:j];
      nx = p->x + widx;
      MOVE(p, nx);
    }
    /* and insert source objects */
    j = 1 + endbar[i] - begbar[i];
    while (j--)
    {
//      p = [snl removeObjectAtIndex:begbar[i]];
//      if (p != nil)
        if (begbar[i] <= [snl count])
      {
            p = [[[snl objectAtIndex:begbar[i]] retain] autorelease];
            [snl removeObjectAtIndex:begbar[i]];
        [dnl insertObject:p atIndex:a];
        p->mystaff = dsp;
	p->x = destx + (p->x - begx);
        ++a;
      }
    }
  }
  sys->barnum -= 1;
  [view flowTimeSig: sys];
  [sys findJoins];
  [self sysInvalid];
  [self userAdjust: YES]; /* does the recache, recalc and sysHeight */
  [sys sysInvalid];
  [sys userAdjust: b];
  if (b) [view resetPagesOn: self : sys];
  else [view simplePaginate: self : 1 : 0];
  return self;
}




/*
  Grab Bars from the next system.  This is the original algorithm,
  which does not know how to parse and handle end-staff signature format.
*/

- grabBar
{
  int i, j, k, ns, q, ds;
  float rx, dy;
  Staff *ssp, *dsp;
  NSMutableArray *snl, *dnl, *sysl;
  System *sys;
  StaffObj *p;
  BOOL b;
  ns = flags.nstaves;
  /* find next system */
  sysl = ((GraphicView *)view)->syslist;
  ds = [sysl indexOfObject:self];
  while (1)
  {
    ++ds;
    if (ds >= [sysl count])
    {
      NSRunAlertPanel(@"Cannot Grab", @"No next system", @"OK", nil, nil, NULL);
      return nil;
    }
    sys = [sysl objectAtIndex:ds];
    if (sys->flags.nstaves != ns)
    {
      NSRunAlertPanel(@"Cannot Grab", @"Next system not same size", @"OK", nil, nil, NULL);
      return nil;
    }
    ssp = [sys->staves objectAtIndex:0];
    q = [ssp skipSigIx: 0];
    if (q == [ssp->notes count]) continue;
    else break;
  }
  for (i = 0; i < ns; i++)
  {
    dsp = [staves objectAtIndex:i];
    dy = [dsp yOfTop] - [ssp yOfTop];
    dnl = dsp->notes;
    if ([dnl count] == 0) rx = [self leftWhitespace];
    else rx = ((StaffObj *)[dnl lastObject])->x;
    ssp = [sys->staves objectAtIndex:i];
    snl = ssp->notes;
    q = [ssp skipSigIx: 0];
    k = [snl count];
    for (j = q; j < k; j++)
    {
      p = [snl objectAtIndex:j];
      if (TYPEOF(p) == BARLINE)
      {
        [sys findSplits: ssp : q : j : 0];
	break;
      }
    }
    k = [snl count] - q;
    b = NO;
    while (!b && k--)
    {
//      p = [snl removeObjectAtIndex:q];
//      if (p != nil)
        if (q <= [snl count])
      {
          p = [[[snl objectAtIndex:q] retain] autorelease];
          [snl removeObjectAtIndex:q];
        [dnl addObject: p];
        p->mystaff = dsp;
        p->x += rx;
        if (TYPEOF(p) == BARLINE) b = YES;
      }
    }
  }
  sys->barnum += 1;
  [view flowTimeSig: sys];
  [self findJoins];
  [self sysInvalid];
  [self userAdjust: YES]; /* does the recache, recalc, sysheight */
  [sys sysInvalid];
  [sys userAdjust: YES];
  [view resetPagesOn: self : sys];
  return self;
}


/* Lay Out N Bars */

- layBars: (int) n : (NSRect *) r
{
  int ns, i, b;
  float x, xoff, xwid;
  Staff *sp;
  StaffObj *p;
  Barline *prev[NUMSTAVES];
  BOOL f = NO;
  char sFlag, bFlag;
  float lwhite = [self leftWhitespace];
  ns = flags.nstaves;
  for (i = 0; i < ns; i++) prev[i] = [view lastObject: self : i : BARLINE : YES];
  xoff = 0.0;
  for (i = 0; i < ns; i++)
  {
    sp = [staves objectAtIndex:i];
    p = [sp->notes lastObject];
    if (p != nil) x = RIGHTBOUND(p); else x = lwhite;
    if (x > xoff) xoff = x;
  }
  xwid = (lwhite + width - xoff) / n;
  for (i = 0; i < ns; i++)
  {
    if (prev[i] == nil)
    {
      sFlag = 1;
      bFlag = 0;
    }
    else
    {
      sFlag = prev[i]->flags.staff;
      bFlag = prev[i]->flags.bridge;
    }
    sp = [staves objectAtIndex:i];
    for (b = 1; b <= n; b++)
    {
      p = [Graphic allocInit: BARLINE];
      p->x = xoff + b * xwid;
      p->y = [sp yOfTop];
      ((Barline *)p)->flags.staff = sFlag;
      ((Barline *)p)->flags.bridge = bFlag;
      [sp linknote: p];
      [p recalc];
      if (!(sp->flags.hidden))
      {
        if (f) *r  = NSUnionRect((p->bounds) , *r);
	else
	{
	  f = YES;
	  *r = p->bounds;
	}
      }
    }
  }
  return self;
}


/*
  Assume a system vertically compressed.  Apply the expansion factor to
  put space in between staves to optimise equal distance between.
*/

- expandSys
{
  Staff *sp;
  int i, k, ns;
  float sep[NUMSTAVES], s, sy, sumsep, maxsep, slack, maxy, deficit, orgy=0.0;
  short sindex[NUMSTAVES];
  sumsep = 0.0;
  maxsep = MINFLOAT;
  maxy = 0.0;
  k = flags.nstaves;
  ns = -1;
  for (i = 0; i < k; i++)
  {
    sp = [staves objectAtIndex:i];
    sindex[i] = -1;
    if (sp->flags.hidden) continue;
    ++ns;
    sindex[ns] = i;
    sep[ns] = [sp yOfTop];
    if (ns == 0) orgy = [sp yOfTop];
    else
    {
      s = sep[ns] - sep[ns - 1];
      sep[ns - 1] = s;
      sumsep += s;
      if (s > maxsep) maxsep = s;
      sy = [sp yOfTop] + sp->vhighb;
      if (sy > maxy) maxy = sy;
    }
  }
  if (ns < 1) return self;
  if (flags.equidist) expansion = maxsep * ns / sumsep;
  slack = (maxy - orgy) * (expansion - 1.0);
  deficit = 0.0;
  for (i = 0; i < ns; i++) deficit += maxsep - sep[i];
  if (slack >= deficit)
  {
    s = maxsep + (slack - deficit) / ns;
    for (i = 0; i < ns; i++)
    {
      sp = [staves objectAtIndex:sindex[i]];
      sp->botmarg = s - sep[i];
    }
  }
  else if (TOLFLOATEQ(deficit, 0.0, 0.1))
  {
    for (i = 0; i < ns; i++)
    {
      sp = [staves objectAtIndex:sindex[i]];
      sp->botmarg = 0.0;
    }
  }
  else
  {
    for (i = 0; i < ns; i++)
    {
      sp = [staves objectAtIndex:sindex[i]];
      sp->botmarg = ((maxsep - sep[i]) / deficit) * slack;
    }
  }
  return self;
}

@end

