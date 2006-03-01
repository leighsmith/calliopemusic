#import "SysAdjust.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "System.h"
#import "mux.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "muxCollide.h"
#import "Staff.h"
#import "NeumeNew.h"
#import "Barline.h"
#import "GNote.h"
#import "NoteHead.h"
#import "TimedObj.h"
#import "Rest.h"
#import "muxlow.h"
#import <Foundation/NSArray.h>
#import <AppKit/NSPanel.h>



@implementation System(SysAdjust)

#define NUMTHREADS NUMSTAVES+NUMVOICES
#define TICKTOL (0.1) /* resolution of distinguishable sim (1 = 128th note) */
#define NUMBARS 200
#define NOTEPAD 2 /* smaller so as not to separate ledger lines too much */
#define AFTERSIG (2 * nature[0])
#define BARPADAFTER (0.25 * widthfactor)
#define VOICEID(v, s) (v ? NUMSTAVES + v : s)
static unsigned char hasbars[NUMSTAVES];	/* number of barlines in staff */
static int voiceused[NUMTHREADS];
static float spacefactor;			/* optimisation parameter */
static float widthfactor;			/* note width in relevant font */
static float sigmargin;				/* system's post-signature margin */
/*sb: does not seem to be used */
//static int minvalue;				/* minimum value in system */

/*
  Return the proper spacing after note p.
  Function of s(x) = k * x^b + a, where x is in ticks.
*/

/*sb: does not seem to be used */
#if 0
static float ticksincode[10] =
{
/* 128  64   32   16   8     4     2      1     B       L   */
  1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0, 128.0, 256.0, 512.0
};
#endif

extern float ctimex(float d);

static float timex(float dur, int tight)
{
  return (ctimex(dur) * widthfactor * spacefactor * (tight ? 0.618 : 1.0));
}


static float gracespace[10] =
{
  1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0
};

static float gracex(TimedObj *p)
{
  return (widthfactor * gracespace[[p noteCode: 0]] * pronature[p->gFlags.size]);
}



/*
  A machine for adjusting columns of signatures
  Knows to squeeze time signatures together
  Option to start at Clef or Key (ignored, hmmm).
  Option to skip specified staves.
*/


extern char sigorder[NUMTYPES];

static float adjustSigIx(int start, NSMutableArray *nl[], int nix[], int n, float sx, int skip, BOOL enable[])
{
  char hadtime[NUMSTAVES];
  int i, j, mj, t;
  float x, cx, mx;
  StaffObj *p;
  BOOL r = NO;
  for (i = 0; i < NUMSTAVES; i++) hadtime[i] = 0;
  cx = mx = sx;
  while (YES)
  {
    mj = 9;
    for (i = 0; i < n; i++) if (!skip || enable[i])
    {
        if ([nl[i] count] == nix[i]) continue;//sb
      p = [nl[i] objectAtIndex:nix[i]];
      if (p == nil) continue;
      j = sigorder[TYPEOF(p)];
      if (j < mj) mj = j;
    }
    if (mj == 9) break;
    for (i = 0; i < n; i++) if (!skip || enable[i])
    {
        if ([nl[i] count] == nix[i]) continue;//sb
      p = [nl[i] objectAtIndex:nix[i]];
      if (p == nil) continue;
      t = TYPEOF(p);
      if (mj == sigorder[t])
      {
        r = YES;
	x = cx + [p leftBearing: YES];
	if (t == TIMESIG)
	{
	  x += (hadtime[i]) ? 0.5 * MINPAD : MINPAD;
	  hadtime[i] = 1;
	}
	else
	{
	  x += MINPAD;
	  hadtime[i] = 0;
	}
	MOVE(p, x);
	x += [p rightBearing: YES];
	if (x > mx) mx = x;
	++nix[i];
      }
    }
    cx = mx;
  }
  if (r) mx += AFTERSIG;
  return mx;
}


/*
  Routines for in-staff change-of-signature and grace notation.
*/


/* find width and setting of signatures between b and k (inclusive). */

static float widthSigsIx(int b, int k, NSMutableArray *nl)
{
  int i;
  StaffObj *p;
  float w = 0.0;
  int theCount = [nl count];
  for (i = k; i >= b; i--)
  {
      if (i > theCount -1) p = nil;
    else p = [nl objectAtIndex:i];
    if (ISASIGBLOCK(p)) w += p->bounds.size.width + MINPAD;
  }
// NSLog(@"sigs %d-%d width=%f\n", b, k, w);
  return w;
}


static void setSigsIx(int b, int k, NSMutableArray *nl, float x)
{
  int i;
  StaffObj *p;
  int theCount = [nl count];
// NSLog(@"sigs %d-%d set back from %f\n", b, k, x);
  for (i = k; i >= b; i--)
  {
      if (i > theCount -1) p = nil;
    else p = [nl objectAtIndex:i];
    if (ISASIGBLOCK(p))
    {
      x -= RIGHTBEARING(p);
      MOVE(p, x);
      x -= LEFTBEARING(p) + MINPAD;
    }
  }
}


/* find width and setting of grace notes of voice v between b and k (inclusive). */

static float widthGraceIx(int v, int b, int k, NSMutableArray *nl)
{
  int i;
  TimedObj *p, *q = nil;
  float w = 0.0;
  int theCount = [nl count];
  for (i = k; i >= b; i--)
  {
      if (i > theCount -1) p = nil;
    else p = [nl objectAtIndex:i];
    if (p->voice == v && p->isGraced == 1)
    {
      q = p;
      w += gracex(p);
    }
  }
  if (q != nil) w += LEFTBEARING(q) + MINPAD;
  return w;
}


static float setGraceIx(int v, int b, int k, NSMutableArray *nl, float x)
{
  int i;
  TimedObj *p, *q = nil;
  int theCount = [nl count];
  for (i = k; i >= b; i--)
  {
      if (i > theCount -1) p = nil;
    else p = [nl objectAtIndex:i];
    if (p->voice == v && p->isGraced == 1)
    {
      q = p;
      x -= gracex(p);
      MOVE(p, x);
    }
  }
  if (q != nil) x -= (LEFTBEARING(q) + MINPAD);
  return x;
}



/*
  Adjust a single line of chant.  Does a more conventional looking job
  than ordinary adjust.  If chant is on a system with staff notation,
  then use ordinary adjust.  array[0] is a circumlocution for adjustSigIx.
*/

#define CHABARPAD	8	/* distance before / after bars for chant */
#define CHAMINPAD	2	/* chant separation */

static void adjchant(NSMutableArray *staves, float lmx)
{
  StaffObj *p;
  NSMutableArray *nl[1];
  Staff *sp;
  int nix[1];
  float x, bx, ax, tbx, tax, cx;
  float rx, trx, pad;
  BOOL v, b;
  if ([staves count]) sp = [staves objectAtIndex:0];
    else sp = nil;
  nix[0] = [sp indexOfNoteAfter: lmx];
  nl[0] = sp->notes;
  x = sigmargin = adjustSigIx(0, nl, nix, 1, lmx, 0, NULL);
  if (nix[0] + 1 > [nl[0] count]) p = nil;
  else p = [nl[0] objectAtIndex:nix[0]];
  cx = rx = trx = x;
  while (p != nil)
  {
    bx = LEFTBEARING(p);
    ax = RIGHTBEARING(p);
    tbx = tax = 0.0;
    v = [p hasAnyVerse];
    if (v) [p verseWidths: &tbx : &tax];
    b = (TYPEOF(p) == BARLINE);
    pad = 0;
    if (b) pad = CHABARPAD;
//    else if (v) pad = MINPAD;
//    else if (TYPEOF(p) == NEUMENEW && SUBTYPEOF(p) == PUNCTINC) pad = 0;
//    else pad = CHAMINPAD;
    if (cx - pad - bx < rx) cx = rx + bx + pad;
    if (v && cx - tbx < trx) cx = trx + tbx;
    MOVE(p, cx);
    rx = cx + ax;
    if (b) rx += CHABARPAD;
    else if (TYPEOF(p) == NEUMENEW && ((NeumeNew *)p)->nFlags.dot) rx += 2;
    if (v && cx + tax > trx) trx = cx + tax;
    if (b) cx = MAX(rx, trx);
    ++nix[0];
    p = [nl[0] objectAtIndex:nix[0]];
  }
}


/*
  do an adjustment.
  Multiple voices are merged into the staff notelists, and have to be unpicked.
*/

/* insertEvent could be done by binary chop, you fool! Could be called by Staff linknote too. */

static void insertEvent(StaffObj *p, NSMutableArray *el)
{
  int i, k;
  StaffObj *q;
  float px = p->x;
  k = [el count];
  for (i = 0; i < k; i++)
  {
    q = [el objectAtIndex:i];
    if (q->x > px)
    {
      [el insertObject:p atIndex:i];
      return;
    }
  }
  [el addObject: p];
  return;
}


/* voice v has maxtick t at bar b, so update all.  Another reason for dumping poxy polymeter1. */

- setBarStamp: (int) n : (int) b : (int) v : (float) t
{
  int i, j, k, s;
  Staff *sp;
  NSMutableArray *nl;
  StaffObj *p;
  for (i = 0; i < n; i++)
  {
    sp = [staves objectAtIndex:i];
    if (sp->flags.hidden) continue;
    nl = sp->notes;
    k = [nl count];
    s = 0;
    for (j = 0; j < k; j++)
    {
      p = [nl objectAtIndex:j];
      if (TYPEOF(p) == BARLINE)
      {
        if (s == b)
	{
	  if (t > p->stamp) p->stamp = t;
	  break; 
	}
	++s;
      }
    }
  }
  return self;
}


/*
  Allocate timestamps to certain staff objects.
  This is a rather beautiful algorithm, as it does graced objects
    and backwards-timed objects in a single reverse pass.
  Then clever exchange sort of events based on their timestamp.
  Slow but won't swap notes across bar boundaries.
  Minimal work if already sorted (the notelist is usually already sorted).
*/

/*
  This algorithm handles polymetric notation Interpretation I:
  (coinciding barlines).
*/

- polymeter1: (int) n : (float) lmx
{
  int i, j, k, th;
  NSMutableArray *nl;
  int nix[NUMTHREADS];
  char inbar[NUMTHREADS], hasgrace[NUMTHREADS], barevents[NUMTHREADS], barrests[NUMTHREADS];
  float ticks[NUMTHREADS], maxt, t;
  NSMutableArray *thread[NUMTHREADS];
  StaffObj *p;
  Staff *sp;
  BOOL allbars, some;
  for (i = 0; i < n; i++) hasbars[i] = 0;
  for (i = 0; i < NUMTHREADS; i++)
  {
    thread[i] = nil;
    voiceused[i] = 0;
    hasgrace[i] = 0;
  }
  /* put each voice on a separate thread, and tag each event with its bar number */
  for (i = 0; i < n; i++)
  {
    sp = [staves objectAtIndex:i];
    if (sp->flags.hidden) continue;
    nl = sp->notes;
    k = [nl count];
    for (j = 0; j < k; j++)
    {
      p = [nl objectAtIndex:j];
      if (p->x > lmx)
      {
        if (ISATIMEDOBJ(p))
        {
          p->tag = hasbars[i];
	  p->duration = [p noteEval: YES];
          th = VOICEID(p->voice, i);
	  voiceused[th]++;
          if (thread[th] == nil) thread[th] = [[NSMutableArray alloc] init];
          insertEvent(p, thread[th]);
        }
        else if (TYPEOF(p) == BARLINE)
	{
	  p->stamp = 0;
	  hasbars[i]++;
	}
      }
    }
  }
  for (i = 0; i < NUMTHREADS; i++) if (voiceused[i])
  {
    nix[i] = 0;
    ticks[i] = 0.0;
    inbar[i] = 0;
    barrests[i] = 0;
    barevents[i] = 0;
  }
  /* find syncs for each thread.  Chords sync at greatest tick in thread. */
  some = YES;
  while (some)
  {
    allbars = YES;
    some = NO;
    for (i = 0; i < NUMTHREADS; i++)  if (voiceused[i] && nix[i] < voiceused[i])
    {
      some = YES;
        p = [thread[i] objectAtIndex:nix[i]];
      if (p->tag <= inbar[i])
      {
	p->stamp = ticks[i];
	if (p->isGraced) hasgrace[i] = 1;
	else
	{
	  t = p->duration;
	  ticks[i] += t;
  	  barevents[i]++;
	}
	if (TYPEOF(p) == REST) barrests[i]++;
	allbars = NO;
        nix[i]++;
      }
    }
    if (!some || (allbars && some))
    {
      /* a new bar restarts the tick at the greatest tick in previous bar,
         but special treatment for systems having single-rest bars */
      maxt = MINFLOAT;
      for (i = 0; i < NUMTHREADS; i++)  if (voiceused[i] && ticks[i] > maxt) maxt = ticks[i];
#if 0
      /* used to check for pathological case: just empty bars or single-rest bars */
      j = 1;
      for (i = 0; i < NUMTHREADS; i++) j &= (barevents[i] == 0 || barrests[i] == 1);
      if (j)
      { for (i = 0; i < NUMTHREADS; i++)  if (voiceused[i] && ticks[i] > maxt) maxt = ticks[i]; }
      else
      { for (i = 0; i < NUMTHREADS; i++)  if (voiceused[i] && ticks[i] > maxt && !(barrests[i] == 1 && barevents[i] == 1)) maxt = ticks[i]; }
#endif  
      /* set the graced and timebacked objects (timed back from greatest tick) */
      for (i = 0; i < NUMTHREADS; i++) if (hasgrace[i])
      {
        t = maxt;
        j = nix[i];
        while (j--)
        {
            if (j - 1 <= voiceused[i]) p = [thread[i] objectAtIndex:j]; else p = nil; //sb
	  if (p->tag != inbar[i]) break;
          if (p->isGraced == 2) p->stamp = t - p->duration;
          else if (p->isGraced == 1) p->stamp = t - 1.5;
          t = p->stamp;
	}
	hasgrace[i] = 0;
      }
      /* ready for new bar */
      for (i = 0; i < NUMTHREADS; i++)  if (voiceused[i])
      {
        [self setBarStamp: n : inbar[i] : i : maxt];
        ticks[i] = maxt;
	inbar[i]++;
	barevents[i] = 0;
	barrests[i] = 0;
      }
    }
  }
        for (i = 0; i < NUMTHREADS; i++)  if (thread[i]) [thread[i] release];//sb fixes memory leak
  return self;
}


/*
  This algorithm handles polymetric notation Interpretation II:
  (non-coinciding barlines).  Its shortcoming is that
  each bar in each staff needs to have a voice in effect for full duration of bar.
*/


- polymeter2: (int) n : (float) lmx
{
  int i, j, k, th, v;
  float vt[NUMVOICES], maxt;
  NSMutableArray *nl;
  char hasgrace;
  StaffObj *p;
  Staff *sp;
  for (i = 0; i < n; i++) hasbars[i] = 0;
  /* stamp notes, and barlines with max tick in bar on this staff */
  for (i = 0; i < n; i++)
  {
    sp = [staves objectAtIndex:i];
    if (sp->flags.hidden) continue;
    for (v = 0; v < NUMVOICES; v++) vt[v] = 0;
    hasgrace = 0;
    nl = sp->notes;
    k = [nl count];
    for (j = 0; j < k; j++)
    {
      p = [nl objectAtIndex:j];
      if (p->x  > lmx)
      {
        if (ISATIMEDOBJ(p))
        {
          p->duration = [p noteEval: NO];
          if (p->isGraced) hasgrace = 1;
          else
          {
            th = VOICEID(p->voice, i);
	    voiceused[th]++;
	    p->stamp = vt[th];
	    vt[th] += p->duration;
          }
        }
        else if (TYPEOF(p) == BARLINE)
        {
	  ++hasbars[i];
          maxt = 0;
          for (v = 0; v < NUMVOICES; v++) if (vt[v] > maxt) maxt = vt[v];
	  p->stamp = maxt;
          for (v = 0; v < NUMVOICES; v++) vt[v] = maxt;
	}
      }
    }
    /* now do a backward pass if needed.  vt[v] is valid and used */
    if (hasgrace)
    {
      j = k;
      while (j--)
      {
        p = [nl objectAtIndex:j];
	if (TYPEOF(p) == BARLINE)
	{
	  maxt = p->stamp;
	  for (v = 0; v < NUMVOICES; v++) vt[v] = maxt;
	}
	else if (ISATIMEDOBJ(p))
	{
	  th = VOICEID(p->voice, i);
	  if (p->isGraced == 2) p->stamp = vt[th] - p->duration;
          else if (p->isGraced == 1) p->stamp = vt[th] - 1.5;
          vt[th] = p->stamp;
	}
      }
    }
  }
  return self;
}


- doStamp: (int) n : (float) lmx
{
  int i, j, k, some;
  StaffObj *p, *q;
  Staff *sp;
  NSMutableArray *nl;
  if (flags.disjoint) [self polymeter2: n : lmx]; else [self polymeter1: n : lmx];
  /* now sort the note lists on time stamp */
  for (i = 0; i < n; i++)
  {
    sp = [staves objectAtIndex:i];
    if (sp->flags.hidden) continue;
    nl = sp->notes;
    k = [nl count];
    some = (k>0);//sb: was YES;, but if nl is empty (no notes) causes errors.
    while (some)
    {
      some = NO;
      q = [nl objectAtIndex:0];
      for (j = 1; j < k; j++)
      {
        p = q;
        q = [nl objectAtIndex:j];
        if (p->x > lmx && q->x > lmx && HASAVOICE(p) && HASAVOICE(q) && p->stamp > q->stamp  &&!p->isGraced && !q->isGraced)
        {
	  some = YES;
            [q retain];
            [p retain];
	  [nl replaceObjectAtIndex:j withObject:p];
	  [nl replaceObjectAtIndex:j - 1 withObject:q];
          [q release];
          [p release];
	  q = p;  /* I'm glad I thought of this first time! */
        }
      }
    }
#if 0
NSLog(@"s%d:", i);
for (j = 0; j < k; j++)
{
  p = [nl objectAtIndex:j];
  if (TYPEOF(p) == BARLINE) NSLog(@" |");
  else if (ISATIMEDOBJ(p)) NSLog(@"  (%d,%3.0f)", p->voice, p->stamp);
  else NSLog(@" @");
}
NSLog(@"\n");
#endif
  }
  return self;
}


/*
  fmark[i] iff staff i has an unprocessed token on the frontier.
  vmark[v] iff voice v is in a sim on the beat line.
*/

static void adjust(NSMutableArray *staves, int n, float lmx)
{
  int i, j, numbars, v, fin, ns;
  float vtick[NUMTHREADS], vpred[NUMTHREADS], prevtimex[NUMTHREADS];
  float prevtick[NUMTHREADS], prevx[NUMTHREADS];
  float xoff, tmp, bbt[NUMSTAVES];
  float dur, dx, mbx, mindur, curstamp[NUMSTAVES];
  float mintick, barpred[NUMSTAVES], presigx[NUMSTAVES];
  NSMutableArray *nl[NUMSTAVES];
  int nk[NUMSTAVES], nix[NUMSTAVES];
  short sigstart[NUMSTAVES], sigend[NUMSTAVES], simstart[NUMSTAVES], simend[NUMSTAVES];
  short grastart[NUMSTAVES], graend[NUMSTAVES], barstart[NUMSTAVES];
  BOOL todo, onbeat[NUMSTAVES], fmark[NUMSTAVES], vmark[NUMTHREADS], onbar[NUMSTAVES];
  Staff *sp;
  StaffObj *p;
  if (n == 1 && ((Staff *)[staves objectAtIndex:0])->flags.subtype == 2)
  {
    adjchant(staves, lmx);
    return;
  }
  ns = 0;
  for (i = 0; i < n; i++)
  {
    sp = [staves objectAtIndex:i];
    if (!sp->flags.hidden)
    {
      nl[ns] = sp->notes;
      nk[ns] = [sp->notes count];
      nix[ns] = [sp indexOfNoteAfter: lmx];
      ++ns;
    }
  }
  xoff = sigmargin = adjustSigIx(0, nl, nix, ns, lmx, 0, NULL);
  for (i = 0; i < ns; i++)
  {
    barpred[i] = xoff;
    bbt[i] = 0;
    fmark[i] = 0;
    curstamp[i] = -1.0;
  }
  for (v = 0; v < NUMTHREADS; v++)
  {
    vpred[v] = xoff;
    vmark[v] = 0;
    vtick[v] = 0;
  }
  while (1)
  {
    /* Find the current frontier, using any still-marked old frontier */
    mintick = MAXFLOAT;
    for (i = 0; i < ns; i++) if (0 < fmark[i] && fmark[i] < 3)
    {
      if (barstart[i] >= 0 && curstamp[i] < mintick) mintick = curstamp[i];
      if (simstart[i] >= 0 && curstamp[i] < mintick) mintick = curstamp[i];
    }
    else
    {
      sigstart[i] = grastart[i] = simstart[i] = barstart[i] = -1;
    }
    do
    {
      todo = 0;
      for (i = 0; i < ns; i++) if (fmark[i] == 0)
      {
        if (nix[i] < nk[i])
        {
            p = [nl[i] objectAtIndex:nix[i]];
	  if (TYPEOF(p) == BARLINE)
	  {
	    if (simstart[i] >= 0) fmark[i] = 1;
	    else
	    {
	      barstart[i] = nix[i];
	      fmark[i] = 2;
	      curstamp[i] = tmp = p->stamp;
	      if (tmp < mintick) mintick = tmp;
	      ++nix[i];
	    }
	  }
	  else if (ISASIGBLOCK(p))
	  {
	    if (simstart[i] >= 0) fmark[i] = 1;
	    else
	    {
	      if (sigstart[i] < 0) sigstart[i] = nix[i];
	      sigend[i] = nix[i];
	      todo = 1;
	      ++nix[i];
	    }
	  }
	  else if (p->isGraced == 1)
	  {
	    if (simstart[i] >= 0) fmark[i] = 1;
	    else
	    {
	      if (grastart[i] < 0) grastart[i] = nix[i];
	      graend[i] = nix[i];
	      todo = 1;
	      ++nix[i];
	    }
	  }
	  else if (ISATIMEDOBJ(p))
	  {
	    if (simstart[i] < 0)
	    {
	      simstart[i] = nix[i];
	      curstamp[i] = tmp = p->stamp;
	      if (tmp < mintick) mintick = tmp;
	    }
	    if (TOLFLOATEQ(curstamp[i], p->stamp, TICKTOL))
	    {
	      simend[i] = nix[i];
	      todo = 1;
	      ++nix[i];
	    }
	    else fmark[i] = 1;
	  }
	  else
	  {
            NSRunAlertPanel(@"Adjust", @"Skip type %d on staff %d", @"OK", nil, nil, TYPEOF(p), i);
	    ++nix[i];
	  }
	}
	else
	{
	  fmark[i] = 3;
	}
      }
    } while (todo);
/*
NSLog(@"Frontier (mintick = %f):\n", mintick);
for (i = 0; i < ns; i++) fprintf(stderr,"s%d (%f) mk%d:  sig(%d,%d) gra(%d,%d) sim(%d,%d) bar(%d)\n", i, curstamp[i], fmark[i], sigstart[i], sigend[i], grastart[i], graend[i], simstart[i], simend[i], barstart[i]);
*/
    fin = 0;
    for (i = 0; i < ns; i++) fin += (fmark[i] == 3);
    if (fin == ns) return;
    mbx = 0;
    tmp = -1;
    numbars = 0;
    for (i = 0; i < ns; i++)
    {
      onbar[i] = (fmark[i] != 3 && barstart[i] >= 0 && TOLFLOATEQ(curstamp[i], mintick, TICKTOL));
      numbars += onbar[i];
    }
    if (numbars)
    {
      /* There are some bars: find the bar line */
      /* but first check barpreds of sims having same tick as bars */
      for (i = 0; i < ns; i++) if (fmark[i] != 3 && simstart[i] >= 0 && TOLFLOATEQ(curstamp[i], mintick, TICKTOL))
      {
          if (simstart[i] >= nk[i]) p = nil;
        else p = [nl[i] objectAtIndex:simstart[i]];
	tmp = barpred[i];
	if (tmp > mbx) mbx = tmp;
      }
      for (i = 0; i < ns; i++) if (onbar[i])
      {
          if (barstart[i] >= nk[i]) p = nil;
        else p = [nl[i] objectAtIndex:barstart[i]];
	tmp = barpred[i]  + LEFTBEARING(p);
	if (tmp > mbx) mbx = tmp;
      }
      /* set each bar */
      dx = 0.0;
// NSLog(@" (| %3.0f %4.0f)", mintick, mbx);
      for (i = 0; i < ns; i++) if (onbar[i])
      {
          if (barstart[i] >= nk[i]) p = nil;
        else p = [nl[i] objectAtIndex:barstart[i]];
	MOVE(p, mbx);
	/* now set preceding change of sig */
	if (sigstart[i] >= 0) setSigsIx(sigstart[i], sigend[i], nl[i], mbx - LEFTBEARING(p) - MINPAD);
	tmp = RIGHTBEARING(p);
	if (tmp > dx) dx = tmp;
	fmark[i] = 0;
      }
      xoff = mbx + dx;
      tmp = adjustSigIx(1, nl, nix, ns, xoff, 1, onbar);
      if (tmp == xoff) tmp += BARPADAFTER;
      for (v = 0; v < NUMTHREADS; v++) if (voiceused[v]) vpred[v] = tmp;
      for (i = 0; i < ns; i++) barpred[i] = tmp;
    }
    else
    {
      /* No bars.  Find the next beat line */
      for (i = 0; i < ns; i++) if (fmark[i] != 3 && simstart[i] >= 0 && TOLFLOATEQ(curstamp[i], mintick, TICKTOL))
      {
        onbeat[i] = 1;
        for (j = simstart[i]; j <= simend[i]; j++)
	{
            if (j >= nk[i]) p = nil; else p = [nl[i] objectAtIndex:j];
 	  v = VOICEID(p->voice, i);
	  tmp = vpred[v];
	  if (tmp > mbx) mbx = tmp;
	}
      }
      else onbeat[i] = 0;
      mindur = MAXFLOAT;
      /* go through all sims on the beat line */
      for (i = 0; i < ns; i++) if (onbeat[i])
      {
        presigx[i] = MAXFLOAT;
	barpred[i] = MINFLOAT;
	bbt[i] = mintick;
        for (j = simstart[i]; j <= simend[i]; j++)
	{
            if (j >= nk[i]) p = nil; else p = [nl[i] objectAtIndex:j];
 	  v = VOICEID(p->voice, i);
	  MOVE(p, mbx);
	  /* set preceding grace notes for v and refine location of preceding change of signature */
	  tmp = mbx - LEFTBEARING(p) - MINPAD;
          if (grastart[i] >= 0)
          {
            tmp += MINPAD;
            tmp = setGraceIx(p->voice, grastart[i], graend[i], nl[i], tmp);
          }
	  if (tmp < presigx[i]) presigx[i] = tmp;
	  /* set up predictions */
	  dur = p->duration;
	  dx = timex(dur, ((TimedObj *)p)->time.tight);
	  prevtimex[v] = dx;
prevtick[v] = mintick;
prevx[v] = mbx;
	  /* set up bar prediction in case next token is a bar */
#if 0
	  tmp = mbx + dx  - BARPADAFTER;
	  if (tmp > barpred[i]) barpred[i] = tmp;
#endif
	  tmp = mbx + RIGHTBEARING(p) + 0.5 * dx;
	  if (tmp > barpred[i]) barpred[i] = tmp;
	  /* set up voice prediction */
	  vpred[v] = mbx + dx;
	  vtick[v] = mintick + dur;
	  if (dur < mindur) mindur = dur;
	  vmark[v] = 1;
	}
	/* set preceding change of signature */
	if (sigstart[i] >= 0) setSigsIx(sigstart[i], sigend[i], nl[i], presigx[i]);
	fmark[i] = 0;
      }
      /* now pass through all voices not on the beat line, refining prediction */
      if (mindur < MAXFLOAT)
      {
        for (v = 0; v < NUMTHREADS; v++) if (voiceused[v])
        {
	  if (vmark[v]) vmark[v] = 0;
	  else
	  {
	    /* note: the next test used to be <.  That might still be right */
	    if (vtick[v] <= mintick) vpred[v] = mbx;
	    // else vpred[v] = mbx + (mindur - (vtick[v] - mintick)) / mindur * prevtimex[v];
	    else vpred[v] = prevx[v] + (mbx - prevx[v]) / ((mintick - prevtick[v]) / (vtick[v] - prevtick[v]));
	  }
        }
      }
    }
  }
}



/*
  Stretch or shrink the system to fit the entire line.
  Return proportion stretched.  If adj, do the stretch.
  Assume system is correctly adjusted.  Special treatment of signatures
  after the last barline.
*/

static float stretch(BOOL adj, NSMutableArray *staves, int n, float lmx, float rmx)
{
  int i, j, k, f;
  float lx, dx, e, t, zero, maxt, a;
  StaffObj *p;
  int sigend[NUMSTAVES], notes[NUMSTAVES], nlk[NUMSTAVES];
  Staff *sp;
  NSMutableArray *nl;
  int theCount;
  /* find last barline, highest tick */
  zero = MAXFLOAT;
  maxt = 0;
  k = n;
  while (k--)
  {
    sp = [staves objectAtIndex:k];
    if (sp->flags.hidden) continue;
    nl = sp->notes;
    i = notes[k] = [sp indexOfNoteAfter: sigmargin];
    if (i >= [nl count]) p = nil;
      else {
          p = [nl objectAtIndex:i];
// if (p == nil) NSLog(@"staff %d: note at %d is nil\n", k, i);
          t = p->x;
// NSLog(@"staff %d: note at %d has x = %f\n", k, i, t);
          if (sigmargin <= t && t <= zero) zero = t;
      }
    j = nlk[k] = [nl count];
    sigend[k] = -1;
    if (j)
    {
      f = 1;
      while (j > i && f)
      {
        --j;
        p = [nl objectAtIndex:j];
        f = ISASIGBLOCK(p);
      }
      if (!f && TYPEOF(p) == BARLINE)
      {
        sigend[k] = j;
	if (p->stamp > maxt) maxt = p->stamp;
      }
    }
  }
  /* find amount to justify and room for trailing sigs */
  dx = 0;
  lx = 0;
  k = n;
  while (k--)
  {
    sp = [staves objectAtIndex:k];
    if (sp->flags.hidden) continue;
    nl = sp->notes;
    if (sigend[k] >= 0)
    {
      /* well formed input will use the highest-tick bars */
        if (sigend[k] >= [nl count]) p = nil; else p = [nl objectAtIndex:sigend[k]];
      if (p->stamp == maxt)
      {
        e = LEFTBOUND(p);
        if (e > lx) lx = e;
        p = [nl lastObject];
        e = RIGHTBOUND(p) - e;
        if (e > dx) dx = e;
      }
    }
    else
    {
      /* non well-formed input will use anything beyond */
        if ([nl count]) {
            p = [nl lastObject];
            e = RIGHTBOUND(p);
            if (e > lx) lx = e;
        } else p = nil;
    }
  }
  /* now find left margin */
  if (lx == 0) t = 1.0;
  else t = (rmx - dx - zero) / (lx - zero);
// NSLog(@"sigmarg=%f, zero=%f, maxt=%f, lx=%f, dx=%f, rmx=%f, t=%f\n", sigmargin, zero, maxt, lx, dx, rmx, t);
  if (adj)
  {
    a = rmx - dx - lx;
    k = n;
    while (k--)
    {
      sp = [staves objectAtIndex:k];
      if (sp->flags.hidden) continue;
      nl = sp->notes;
      theCount = [nl count];
      i = notes[k];
      j = sigend[k];
      if (j >= 0)
      {
        /* adjust up to the ending signatures */
        while (i < j)
        {
            if (i >= theCount) p = nil; else p = [nl objectAtIndex:i++];
            e = t * (p->x - zero) + zero;
            MOVE(p, e);
        }
        /* right-justify each ending signature */
        f = nlk[k];
        while (j < f)
        {
            if (j >= theCount) p = nil; p = [nl objectAtIndex:j++];
	  e = p->x + a;
	  MOVE(p, e);
        }
      }
      else
      {
        /* not ending in a bar: adjust up to the end */
	j = [nl count];
        while (i < j)
        {
          p = [nl objectAtIndex:i++];
	  e = t * (p->x - zero) + zero;
	  MOVE(p, e);
        }
      }
    }
  }
  return t;
}

/*
  Improve the placement on a system.  Like adjust, but starts with
  objects already placed.  Looks for crowded areas and pushes right.
  The result has no collisions, but has increased the width by
  an error factor.  Return the error.
*/


static float separate(NSMutableArray *staves, int n, float lmx)
{
  int err, i, j, numbars, v, fin, ns;
  float xoff, tmp, bx, btx, vbx, vax, px=0.0, mvnx, tx, vmx;
  float mbx, curstamp[NUMSTAVES], vnx[NUMTHREADS], vrb[NUMTHREADS], vcx[NUMTHREADS];
  float mintick, ax[NUMSTAVES], presigx[NUMSTAVES];
  float atx[NUMSTAVES];		/* Amount of space needed by underlay on staff */
  float txt[NUMSTAVES];		/* Right boundary of previous underlay on staff */
  float nx[NUMSTAVES];		/* Location of right boundary of previous obj on staff */
  NSMutableArray *nl[NUMSTAVES];
  int nk[NUMSTAVES], nix[NUMSTAVES];
  short sigstart[NUMSTAVES], sigend[NUMSTAVES], simstart[NUMSTAVES], simend[NUMSTAVES];
  short grastart[NUMSTAVES], graend[NUMSTAVES], barstart[NUMSTAVES];
  BOOL todo, onbeat[NUMSTAVES], fmark[NUMSTAVES], onbar[NUMSTAVES];
  Staff *sp;
  StaffObj *p;
  if (n == 1 && ((Staff *)[staves objectAtIndex:0])->flags.subtype == 2) return 0.0;
  xoff = sigmargin;
  ns = 0;
  for (i = 0; i < n; i++)
  {
    sp = [staves objectAtIndex:i];
    if (!sp->flags.hidden)
    {
      nl[ns] = sp->notes;
      nk[ns] = [sp->notes count];
      nix[ns] = [sp skipSigIx: [sp indexOfNoteAfter: lmx]];
      nx[ns] = xoff;
      txt[ns] = 0.0;
      fmark[ns] = 0;
      curstamp[ns] = -1.0;
      ++ns;
    }
  }
  for (v = 0; v < NUMTHREADS; v++) vnx[v] = xoff;
  err = 0.0;
  while (1)
  {
    /* Find the current frontier, using any still-marked old frontier */
    mintick = MAXFLOAT;
    for (i = 0; i < ns; i++) if (0 < fmark[i] && fmark[i] < 3)
    {
      if (barstart[i] >= 0 && curstamp[i] < mintick) mintick = curstamp[i];
      if (simstart[i] >= 0 && curstamp[i] < mintick) mintick = curstamp[i];
    }
    else
    {
      sigstart[i] = grastart[i] = simstart[i] = barstart[i] = -1;
    }
    do
    {
      todo = 0;
      for (i = 0; i < ns; i++) if (fmark[i] == 0)
      {
        if (nix[i] < nk[i])
        {
	  p = [nl[i] objectAtIndex:nix[i]];
	  if (TYPEOF(p) == BARLINE)
	  {
	    if (simstart[i] >= 0) fmark[i] = 1;
	    else
	    {
	      barstart[i] = nix[i];
	      fmark[i] = 2;
	      curstamp[i] = tmp = p->stamp;
	      if (tmp < mintick) mintick = tmp;
	      ++nix[i];
	    }
	  }
	  else if (ISASIGBLOCK(p))
	  {
	    if (simstart[i] >= 0) fmark[i] = 1;
	    else
	    {
	      if (sigstart[i] < 0) sigstart[i] = nix[i];
	      sigend[i] = nix[i];
	      todo = 1;
	      ++nix[i];
	    }
	  }
	  else if (p->isGraced == 1)
	  {
	    if (simstart[i] >= 0) fmark[i] = 1;
	    else
	    {
	      if (grastart[i] < 0) grastart[i] = nix[i];
	      graend[i] = nix[i];
	      todo = 1;
	      ++nix[i];
	    }
	  }
	  else if (ISATIMEDOBJ(p))
	  {
	    if (simstart[i] < 0)
	    {
	      simstart[i] = nix[i];
	      curstamp[i] = tmp = p->stamp;
	      if (tmp < mintick) mintick = tmp;
	    }
	    if (TOLFLOATEQ(curstamp[i], p->stamp, TICKTOL))
	    {
	      simend[i] = nix[i];
	      todo = 1;
	      ++nix[i];
	    }
	    else fmark[i] = 1;
	  }
	  else ++nix[i];
	}
	else
	{
	  fmark[i] = 3;
	}
      }
    } while (todo);
    fin = 0;
    for (i = 0; i < ns; i++) fin += (fmark[i] == 3);
    if (fin == ns) return(err);
    mbx = 0.0;
    tmp = -1;
    numbars = 0;
    for (i = 0; i < ns; i++)
    {
      onbar[i] = (fmark[i] != 3 && barstart[i] >= 0 && TOLFLOATEQ(curstamp[i], mintick, TICKTOL));
      numbars += onbar[i];
    }
    if (numbars)
    {
      /* We have some bars: find the bar line */
      for (i = 0; i < ns; i++) if (onbar[i])
      {
          p = [nl[i] objectAtIndex:barstart[i]];//sb: ok
	bx = LEFTBEARING(p);
	if (sigstart[i] >= 0) bx += widthSigsIx(sigstart[i], sigend[i], nl[i]);
	[p verseWidths: &btx : &(atx[i])];
	tmp = p->x + err;
        if (tmp - MINPAD - bx < nx[i]) tmp = nx[i] + bx + MINPAD;
        if (btx != 0 && tmp - btx < txt[i]) tmp = txt[i] + btx;
        if (nix[i] >= nk[i] && tmp - btx < txt[i]) tmp = txt[i] + btx;
        if (tmp > mbx) mbx = tmp;
      }
      /* set each bar */
      xoff = 0.0;
      for (i = 0; i < ns; i++) if (onbar[i])
      {
          p = [nl[i] objectAtIndex:barstart[i]];//sb: ok
	MOVE(p, mbx);
	if (mbx - p->x > err) err = mbx - p->x;
	/* now set preceding change of sig */
	if (sigstart[i] >= 0) setSigsIx(sigstart[i], sigend[i], nl[i], mbx - LEFTBEARING(p) - MINPAD);
	if (atx[i] != 0) txt[i] = mbx + atx[i];
	nx[i] = tmp = mbx + RIGHTBEARING(p);
	if (tmp > xoff) xoff = tmp;
	fmark[i] = 0;
      }
      tmp = adjustSigIx(1, nl, nix, ns, xoff, 1, onbar);
      /* */ if (tmp == xoff) tmp += BARPADAFTER; /* */
      for (i = 0; i < ns; i++) nx[i] = tmp;
    }
    else
    {
      /* find the beatline */
// for (i = 0; i < ns; i++) if (sigstart[i] >= 0) NSLog(@"staff %d: sig=%d, sim=%d, stamp=%f, mintick=%f\n", i, sigstart[i], simstart[i], curstamp[i], mintick);
      for (i = 0; i < ns; i++) if (fmark[i] != 3 && simstart[i] >= 0 && TOLFLOATEQ(curstamp[i], mintick, TICKTOL))
      {
        onbeat[i] = 1;
	mvnx = bx = btx = ax[i] = atx[i] = 0;
	/* check each voice to find maximum grace leftbearing and verse bearings */
	/* first find min x of sim, in case they are already kerned */
	px = MAXFLOAT;
        for (j = simstart[i]; j <= simend[i]; j++)
	{
          p = [nl[i] objectAtIndex:j];
	  tmp = p->x;
	  if (tmp < px) px = tmp;
	}
        for (j = simstart[i]; j <= simend[i]; j++)
	{
          p = [nl[i] objectAtIndex:j];
 	  v = VOICEID(p->voice, i);
	  tmp = RIGHTBEARING(p);
	  vrb[v] = tmp;
	  if (tmp > ax[i]) ax[i] = tmp;
	  tmp = LEFTBEARING(p) + MINPAD;
	  if (grastart[i] >= 0) tmp += widthGraceIx(p->voice, grastart[i], graend[i], nl[i]);
	  if (tmp > bx) bx = tmp;
	  [p verseWidths: &vbx : &vax];
	  if (vbx > btx) btx = vbx;
	  if (vax > atx[i]) atx[i] = vax;
	  if (vnx[v] > mvnx) mvnx = vnx[v];
	}
	if (sigstart[i] >= 0) bx += widthSigsIx(sigstart[i], sigend[i], nl[i]) + MINPAD;
	tmp = px + err;
	tx = nx[i] + bx + NOTEPAD;
        if (tx > tmp) tmp = tx;
	tx = mvnx + bx + MINPAD;
        if (tx > tmp) tmp = tx;
	tx = txt[i] + btx;
        if (btx != 0 && tx > tmp) tmp = tx;
        if (tmp > mbx) mbx = tmp;
      }
      else onbeat[i] = 0;
      /* go through all sims on the beat line */
      for (i = 0; i < ns; i++) if (onbeat[i])
      {
        kernsim(i, simstart[i], simend[i], nl[i], vcx);
        presigx[i] = MAXFLOAT;
	if (mbx - px > err) err = mbx - px;
        for (j = simstart[i]; j <= simend[i]; j++)
	{
          p = [nl[i] objectAtIndex:j];
 	  v = VOICEID(p->voice, i);
	  vmx = mbx + vcx[v];
	  MOVE(p, vmx);
	  /* set preceding grace notes for v and refine location of preceding change of signature */
	  tmp = mbx - LEFTBEARING(p) - MINPAD;
          if (grastart[i] >= 0)
          {
            tmp += MINPAD;
            tmp = setGraceIx(p->voice, grastart[i], graend[i], nl[i], tmp);
          }
	  if (tmp < presigx[i]) presigx[i] = tmp;
	  vnx[v] = vmx + vrb[v];
	}
	/* set preceding change of signature */
	if (sigstart[i] >= 0) setSigsIx(sigstart[i], sigend[i], nl[i], presigx[i]);
	if (atx[i] != 0) txt[i] = mbx + atx[i];
	nx[i] = mbx + ax[i];
	fmark[i] = 0;
      }
    }
  }
}


/*
  Look for single rests > halfrest in each voice and centre them in the bar.
  Assumes the line is otherwise formatted.
*/

static void adjrests(NSMutableArray *staves, int n, float lmx)
{
  StaffObj *p, *r, *rests[NUMTHREADS];
  Staff *s;
  NSMutableArray *nl;
  int numrests[NUMTHREADS], numvox[NUMTHREADS];
  int i, k, j, v, nk;
  float bx, x, w;
  for (i = 0; i < n; i++)
  {
    for (v = 0; v < NUMTHREADS; v++)
    {
      numrests[v] = numvox[v] = 0;
    }
    bx = sigmargin;
    s = [staves objectAtIndex:i];
    if (s->flags.hidden) continue;
    nl = s->notes;
    j = [s indexOfNoteAfter: sigmargin];
    nk = [nl count];
    for (k = j; k < nk; k++)
    {
      p = [nl objectAtIndex:k];
      if (ISATIMEDOBJ(p))
      {
 	v = VOICEID(p->voice, i);
        if (TYPEOF(p) == REST)
        {
	  rests[v] = p;
	  numrests[v]++;
        }
	else numvox[v]++;
      }
      else if (TYPEOF(p) == BARLINE)
      {
        x = 0.5 * (LEFTBOUND(p) - bx) + bx;
        for (v = 0; v < NUMTHREADS; v++)
	{
	  if (numrests[v] == 1 && numvox[v] == 0)
	  {
	    r = rests[v];
	    w = x - (0.5 * (RIGHTBOUND(r) - LEFTBOUND(r)) - LEFTBEARING(r));
	    MOVE(r, w);
	  }
	  numrests[v] = numvox[v] = 0;
	}
	bx = RIGHTBOUND(p);
      }
    }
  }
}


static void tidyends(NSMutableArray *staves, int n, int ul, float lmx, int ur, float rmx)
{
  StaffObj *p;
  Staff *s;
  NSMutableArray *nl;
  int i, nk;
  float nx;
  if (ur) for (i = 0; i < n; i++)
  {
    s = [staves objectAtIndex:i];
    if (s->flags.hidden) continue;
    nl = s->notes;
    nk = [nl count];
    if (nk < 2) continue;
    p = [nl lastObject];
    if (TYPEOF(p) != BARLINE) return;
  }
  for (i = 0; i < n; i++)
  {
    s = [staves objectAtIndex:i];
    if (s->flags.hidden) continue;
    nl = s->notes;
    nk = [nl count];
    if (nk < 2) continue;
    if (ul)
    {
        p = [nl objectAtIndex:0];//sb: ok
      if (TYPEOF(p) == BARLINE)
      {
        nx = lmx + LEFTBEARING(p);
	MOVE(p, nx);
      }
    }
    if (ur)
    {
        p = [nl lastObject];//sb: ok
      if (TYPEOF(p) == BARLINE)
      {
        nx = rmx - RIGHTBEARING(p);
	MOVE(p, nx);
      }
    }
  }
}


/* Quick adjustment of signatures (for copySystem) */

- sigAdjust
{
  float lmx = [self leftWhitespace];
  int nix[NUMSTAVES];
  NSMutableArray *nl[NUMSTAVES];
  Staff *sp;
  int k, n = flags.nstaves;
  k = n;
  while (k--)
  {
    sp = [staves objectAtIndex:k];
    nix[k] = [sp indexOfNoteAfter: lmx];
    nl[k] = sp->notes;
  }
  adjustSigIx(0, nl, nix, n, lmx, 0, NULL);
  return self;
}



/*
  Iterative adjustment to reduce error until subpixel or nondecreasing.
  Return residual error.
  Assume spacefactor and widthfactor are initialised.
*/

- (float) optAdjust
{
  float f, err, t, lmx, rmx;
  int n = flags.nstaves, i = 0;
  lmx = [self leftWhitespace];
  rmx = lmx + width;
  adjust(staves, n, lmx);
//  [view display];
//  NXRunAlertPanel("Calliope", "Adjust done", "OK", NULL, NULL);
  f = stretch(NO, staves, n, lmx, rmx);
  if (f > 1.8)
  {
    /* reformat at wider spacefactor */
    spacefactor = f;
    adjust(staves, n, lmx);
  }
  stretch(YES, staves, n, lmx, rmx);
  t = MAXFLOAT;
  while (1)
  {
    err = separate(staves, n, lmx);
//    [view display];
    if (err > 0) stretch(YES, staves, n, lmx, rmx);
    if (err < 0.01 || (t <= err && err < 1.0) || (i > 50)) break;
    t = err;
    ++i;
  }
  if (i > 50) return err;
  if (err < 1.0 && !flags.disjoint) tidyends(staves, n, 1, lmx, 1, rmx);
  return err;
}


- userAdjust: (BOOL) s
{
    NSString *buf;
    int n = flags.nstaves;
  float err = 0.0;
  float lmx = [self leftWhitespace];
  spacefactor = 1.0;
  widthfactor = charFGW(musicFont[1][0], SF_qnote);
  [self myHeight];  /* simply to reset if necessary */
  [self doStamp: n : lmx];
// NSLog(@"[sys%d userAdjust: %d]:\n", [self myIndex], s);
  if (s) err = [self optAdjust];
  else
  {
// NSLog(@"adjust:\n");
    adjust(staves, n, lmx);
// NSLog(@"separate:\n");
    separate(staves, n, lmx);
    if (!flags.disjoint) tidyends(staves, n, 1, lmx, 0, lmx + width);
  }
  adjrests(staves, n, lmx);
  [self recalcHangers];
  if (err > 1)
  {
      buf = [NSString stringWithFormat:@"Page %d: system beginning with bar %d is crowded by amount %f\n", pagenum, barnum, err];
    [NSApp log: buf];
  }
  return self;
}

/* test calls */

- adjustOnly
{
  int n = flags.nstaves;
  float err = 0.0;
  float lmx = [self leftWhitespace];
  spacefactor = 1.0;
  widthfactor = charFGW(musicFont[1][0], SF_qnote);
  [self myHeight];  /* simply to reset if necessary */
  [self doStamp: n : lmx];
  NSLog(@"adjust:\n");
  adjust(staves, n, lmx);
  [self recalcHangers];
  if (err > 1) NSLog(@"System is crowded by amount %f\n", err);
  return self;
}

- separateOnly
{
  int n = flags.nstaves;
  float err = 0.0;
  float lmx = [self leftWhitespace];
  spacefactor = 1.0;
  widthfactor = charFGW(musicFont[1][0], SF_qnote);
  [self myHeight];  /* simply to reset if necessary */
  [self doStamp: n : lmx];
  NSLog(@"separate:\n");
  separate(staves, n, lmx);
  [self recalcHangers];
  if (err > 1) NSLog(@"System is crowded by amount %f\n", err);
  return self;
}


@end

