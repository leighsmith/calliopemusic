#import <Foundation/NSArray.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontManager.h>
#import "GraphicView.h"
#import "GVSelection.h"
#import "GVFormat.h"
#import "GVCommands.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "System.h"
#import "SysAdjust.h"
#import "SysCommands.h"
#import "SysInspector.h"
#import "StaffObj.h"
#import "TimedObj.h"
#import "Tie.h"
#import "muxlow.h"
#import "mux.h"

extern int fontflag;

@implementation GraphicView(GVSelection)


/*
  Handle Inspections
  The versions that don't pass back num should be phased out.
*/


- canInspect: (int) type
{
  id p = [self isSelType: type];
  if (p == nil) NSBeep();
  return p;
}


- canInspectTypeCode: (int) tc : (int *) num
{
  int n;
  id p = [self isSelTypeCode: tc : &n];
  if (n == 0) NSBeep();
  *num = n;
  return p;
}


- canInspect: (int) type : (int *) num
{
  id p, q = nil;
  int n = 0, k = [slist count];
  while (k--)
  {
    p = [slist objectAtIndex:k];
    if (TYPEOF(p) == type)
    {
      ++n;
      if (n == 1) q = p;
    }
  }
  if (n == 0) NSBeep();
  *num = n;
  return q;
}


- (BOOL) startInspection: (int) type : (NSRect *) r : (id *) sl
{
  if ([self canInspect: type])
  {
    [self selectionHandBBox: r];
    *sl = slist;
    return YES;
  }
  return NO;
}


- (BOOL) startInspection: (int) type : (NSRect *) r : (id *) sl : (int *) num
{
  if ([self canInspect: type : num])
  {
    [self selectionHandBBox: r];
    *sl = slist;
    return YES;
  }
  return NO;
}


- endInspection: (NSRect *) r
{
  [self drawSelectionWith: r];
  [[self window] makeKeyWindow];
  [self dirty];
  return self;
}


/*
  update the inspector for each type of object in the selection.
  The complication is to launch each type only once for efficiency,
  so an array of flags, one for each type, is used.
  Should be called only by InspectAppWithMe.
*/

- inspectSelWithMe: g : (BOOL) launch : (int) fontseltype
{
  int i, t;
  id p;
  BOOL flag[NUMTYPES];
  t = NUMTYPES;
  while (t--) flag[t] = NO;
  if (g != nil)
  {
    [NSApp inspectMe: g loadInspector: launch];
    flag[TYPEOF(g)] = YES;
  }
  i = [slist count];
  while (i--)
  {
    p = [slist objectAtIndex:i];
    t = TYPEOF(p);
    if (!flag[t])
    {
      flag[t] = YES;
      [NSApp inspectMe: p loadInspector: launch];
    }
  }
  return self;
}


- inspectSel: (BOOL) launch
{
  return [NSApp inspectAppWithMe: nil loadInspector: (BOOL) launch : 0];
}


/*
  Handle selections
*/

- (BOOL) hasEmptySelection
{
  return [slist count] == 0;
}


/* select an object. */

- selectObj: p
{
    [p selectMe: slist : 0 :1];
    return self;
}


/* a hack as too lazy to change format of selectObj */

- selectObj: p : (int) d
{
    [p selectMe: slist : d :1];
    return self;
}


/* restore the slist to a decent state after a split */

- splitSelect: (Hanger *) h : (NSMutableArray *) hl
{
  int j, k = [hl count], theLocation;
    if ((theLocation = [slist indexOfObject:h]) != NSNotFound)
  {
        [slist removeObjectAtIndex: theLocation];
    for (j = 0; j < k; j++) [slist addObject: [hl objectAtIndex:j]];
  }
  return self;
}


/*
  deselect (and writeback) object g.
  slist has changed, so re-propagate the hanger selection state
*/

- deselectObj: g
{
    int k;
    BOOL h = 0;
    ((Graphic *)g)->gFlags.selected = 0;
    ((Graphic *)g)->gFlags.seldrag = 0;
    if ([g hasHangers] || [g hasEnclosures] || (ISASTAFFOBJ(g) && [g verseOf: 0] != nil))
      {
        [g selectHangers:slist : 0];
        h = 1;
      }
    if ([slist containsObject:g]) [slist removeObject: g];
    if (h)
      {
        k = [slist count];
        while (k--) [[slist objectAtIndex:k] selectHangers:slist : 1];
      }
    [self cache: ((Graphic *)g)->bounds];
//  [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return self;
}



/* return some specified object in selection (or nil). */

- isSelType: (int) type
{
  id p;
  int k = [slist count];
  while (k--)
  {
    p = [slist objectAtIndex:k];
    if (TYPEOF(p) == type) return p;
  }
  return nil;
}


- isSelTypeCode: (int) tc : (int *) num
{
  id p, q = nil;
  int n = 0, k = [slist count];
  while (k--)
  {
    p = [slist objectAtIndex:k];
    if (typecode[TYPEOF(p)] & tc)
    {
      ++n;
      if (n == 1) q = p;
    }
  }
  *num = n;
  return q;
}


- isListLeftmost: (NSMutableArray *) l
{
  int k;
  float minx = MAXFLOAT;
  id r = nil;
  StaffObj *o;
  k = [l count];
  while (k--)
  {
    o = [l objectAtIndex:k];
    if (ISASTAFFOBJ(o) && o->x < minx)
    {
      minx = o->x;
      r = o;
    }
  }
  return r;
}


- isSelLeftmost
{
  return [self isListLeftmost: slist];
}


- isSelRightmost
{
  int k;
  float maxx = MINFLOAT;
  id r = nil;
  StaffObj *o;
  k = [slist count];
  while (k--)
  {
    o = [slist objectAtIndex:k];
    if (ISASTAFFOBJ(o) && o->x > maxx)
    {
      maxx = o->x;
      r = o;
    }
  }
  return r;
}


- isTimedRightmost
{
  int k;
  float maxx = MINFLOAT;
  id r = nil;
  StaffObj *o;
  k = [slist count];
  while (k--)
  {
    o = [slist objectAtIndex:k];
    if (ISATIMEDOBJ(o) && o->x > maxx)
    {
      maxx = o->x;
      r = o;
    }
  }
  return r;
}


/*
  guess a reasonable insertion point depending on what is there.
  pass back the x, the insertion staff and its last obj, and a reasonable body/dot.
*/
extern float ctimex(float d);

- getInsertionX: (float *) x : (Staff **) rsp : (StaffObj **) rp : (int *) tb : (int *) td
{
  int b;
  System *sys;
  Staff *sp;
  TimedObj *t = [self isTimedRightmost];
  StaffObj *p = [self isSelRightmost];
  if (t != nil)
  {
    *x = t->x + ctimex([t noteEval: NO]) * 8;
    *tb = t->time.body;
    *td = t->time.dot;
  }
  else
  {
    *x = RIGHTBOUND(p) + 4 * nature[p->gFlags.size];
    *tb = CROTCHET;
    *td = 0;
  }
  sp = p->mystaff;
  if (*x > [sp xOfEnd])
  {
    sys = [self nextSystem: sp->mysys : &b];
    if (!b) [self simplePaginate: sys : 1 : 0];
    sp = [sys sameStaff: sp];
    if ([sp->notes count] > 0)
    {
      p = [sp->notes lastObject];
      if (ISATIMEDOBJ(p))
      {
        t = (TimedObj *) p;
       *x = t->x + ctimex([t noteEval: NO]) * 8;
        *tb = t->time.body;
        *td = t->time.dot;
      }
      else
      {
        *x = RIGHTBOUND(p) + 4 * nature[p->gFlags.size];
      }
    }
    else
    {
      *x = 4 * getSpacing(sp) + [sys leftWhitespace];
    }
  }
  *rsp = sp;
  *rp = p;
  return self;
}


- getBlinkX: (float *) x : (Staff **) rsp
{
  TimedObj *t = [self isTimedRightmost];
  StaffObj *p = [self isSelRightmost];
  if (t == nil && p == nil) return nil;
  if (t != nil)
  {
    *x = t->x + ctimex([t noteEval: NO]) * 8;
    *rsp = t->mystaff;
  }
  else
  {
    *x = RIGHTBOUND(p) + 4 * nature[p->gFlags.size];
    *rsp = p->mystaff;
  }
  return self;
}


/* get the majority verse font in the selection */

- (NSFont *) getVFont: (int *) num
{
  int k;
  StaffObj *p;
  initVotes();
  k = [slist count];
  if (k == 0) return nil;
  while (k--)
  {
    p = [slist objectAtIndex:k];
    if (ISASTAFFOBJ(p) && p->verses != nil) votesFor([p getVFont], 1);
  }
  *num = multVotes();
  return mostVotes();
}


- changeSelFont: (NSFont *) f : (BOOL) all
{
  NSRect b;
  Graphic *p;
  int k = [slist count];
  if (k == 0) return self;
  [self selectionHandBBox: &b];
  while (k--)
  {
    p = [slist objectAtIndex:k];
    if ([p changeVFont: f : all]) [p reShape];
  }
  [self dirty];
  [self drawSelectionWith: &b];
  return self;
}

/*
  sw = 0: change sel to ff
       1: don't change sel, but use ff
       2: don't change sel, but use fontflag.
*/

- setFontSelection: (int) ff : (int) sw
{
  StaffObj *p;
  System *sys;
  int num, fs=0;
  NSFont *f;
  NSFontManager *fm = [NSFontManager sharedFontManager];
  switch(sw)
  {
    case 0:
      if (fontflag != ff)
      {
        [NSApp selectFontSelection: ff];
        fontflag = ff;
      }
      fs = ff;
      break;
    case 1:
      fs = ff;
      break;
    case 2:
      fs = fontflag;
      break;
  }
  switch (fs)
  {
    case 0:
    case 1:
      f = [self getVFont: &num];
      if (f == nil) f = [[NSApp currentDocument] getPreferenceAsFont: TEXFONT];
      [fm setSelectedFont:f isMultiple:(num > 0)];
      break;
    case 3:
      if (currentSystem)
      {
        f = [currentSystem getVFont : -1 : &num];
        if (f == nil) f = [[NSApp currentDocument] getPreferenceAsFont: TEXFONT];
	[fm setSelectedFont:f isMultiple:(num > 0)];
      }
      break;
    case 2:
      p = [self canInspectTypeCode: TC_STAFFOBJ : &num];
      if (p != nil)
      {
        if (num == 1)
	{
	  sys = [p mySystem];
	  if (TYPEOF(sys) == SYSTEM)
	  {
            f = [sys getVFont : p->selver : &num];
            if (f == nil) f = [[NSApp currentDocument] getPreferenceAsFont: TEXFONT];
	    [fm setSelectedFont:f isMultiple:(num > 0)];
	  }
	}
      }
      break;
  }
  return self;
}



@end

