/* $Id$ */

/* Generated by Interface Builder */

#import "GNChord.h"
#import "GNote.h"
#import "System.h"
#import "TieNew.h"
//#import "draw.h"  // This was generated by the pswrap utility from draw.psw.
#import "DrawingFunctions.h"
#import "muxlow.h"
#import <Foundation/NSArray.h>
#import <AppKit/NSFont.h>

#define MAXHEADS 16	/* max number of heads in a single chord */
#define MAXSIMHEADS 64	/* max number of heads in a sim */

extern float offside[2];
//extern char btype[4];
extern char stype[NUMHEADS];
//extern char oldhead[NUMHEADS];
extern unsigned char headfont[NUMHEADS][10];


/*
  The note heads in headlist are ordered by their y-coordinate, not their pos,
  so there is no ambiguity about being same pos but different staff.
*/
  
@implementation GNote(GNChord)


/*
  the "pos database" is generally useful to disambiguate whether
  a given pos is on which staff.
*/

static char pos[MAXSIMHEADS], uid[MAXSIMHEADS];
static Staff *staff[MAXSIMHEADS];
static int nextpos;

/* users of the pos database must call this first */

static void initPos()
{
  int i = MAXSIMHEADS;
  while (i--)
  {
    pos[i] = 0;
    staff[i] = nil;
    uid[i] = -1;
  }
  nextpos = 0;
}


/* return whether a (staff,pos) exists */

static BOOL hasPos(Staff *sp, int pn)
{
  int i = nextpos;
  while (i--) if (pos[i] == pn && staff[i] == sp) return YES;
  return NO;
}


/* insert a (staff,pos) */

static void putPos(Staff *sp, int pn, int u)
{
  int i = nextpos;
  if (i == MAXSIMHEADS) return;
  pos[i] = pn;
  staff[i] = sp;
  uid[i] = u;
  ++nextpos;
}


/* for debugging only */
- (NSString *) describeChordHeads
{
    NoteHead *h;
    int headIndex, headCount = [headlist count];
    NSMutableString *listString = [NSMutableString stringWithString: @"( "];
    
    for (headIndex = 0; headIndex < headCount; headIndex++) {
	h = [headlist objectAtIndex: headIndex];
	[listString appendString: [NSString stringWithFormat: @"(%d-%f) ", [h staffPosition], [h y]]];
    }
    [listString appendString: @")"];
    return listString;
}


/* chord has changed sense, so update the GNote values */

- updateNote
{
  NoteHead *h;
  h = [headlist lastObject];
  staffPosition = [h staffPosition];
  y = [h y];
  return self;
}


/*
  reverse the headlist: used if the stem direction changes.
  Accounts for the selected notehead and any hangers indexing heads.
*/

- reverseHeads
{
  NSMutableArray *nl = headlist;
  NoteHead *h, *q = nil;
  TieNew *t;
  int i, j, k, hk, e;
  hk = [nl count];
  j = hk / 2;
  k = hk;
  if (gFlags.selend < k) q = [nl objectAtIndex:gFlags.selend];
  for (i = 0; i < j; i++)
  {
    k--;
    if (i != k)
    {
        h = [[nl objectAtIndex:i] retain];//sb: retain, because it will be released when replaced...
      [nl replaceObjectAtIndex:i withObject:[nl objectAtIndex:k]];
      [nl replaceObjectAtIndex:k withObject:h];
      [h release];
    }
  }
  if (q)
  {
    gFlags.selend = [nl indexOfObject:q];
    nl = hangers;
    k = [nl count];
    while (k--)
    {
      t = [nl objectAtIndex:k];
      if ([t graphicType] == TIENEW)
      {
          e = [t whichEnd: self];
          if (e == 2)
	{
	  t->head2 = (hk - 1) - t->head2;
	}
	else if (e == 1)
	{
	  t->head1 = (hk - 1) - t->head1;
	}
      }
    }
  }
  [self updateNote];
  return self;
}


/*
  reset the side of each notehead according to interval.
  Problem when unison and seconds in the same place.
*/

- resetSides
{
    NSMutableArray *nl = headlist;
    NoteHead *noteHead;
    GNote *n, *on = nil;
    int i, k = [nl count], noteHeadStaffPosition;
    int oldNoteHeadStaffPosition = MAXINT, s;
    BOOL state = NO;
    
    for (i = 0; i < k; i++) {
	noteHead = [nl objectAtIndex: i];
	noteHeadStaffPosition = [noteHead staffPosition];
	n = [noteHead myNote];
	s = (state && (ABS(noteHeadStaffPosition - oldNoteHeadStaffPosition) <= 1) && (n == on));
	[noteHead setReverseSideOfStem: s];
	oldNoteHeadStaffPosition = noteHeadStaffPosition;
	on = n;
	state = !s;
    }
    return self;
}


/*
  reset the dot y-offset (in nature units) and x-offset for each notehead.
  The searching part is for handling chords that straddle staves.
*/

/* general case: handles k chords in a sim.  All in np[] must have dots. */

void lineupDots(GNote *np[], int k)
{
  NoteHead *noteHead;
  GNote *p;
  Staff *sp;
  NSMutableArray *nl;
  struct timeinfo *ti;
  int bt, i, j, hk, n, sz, dir, dy, dys, dp;
  BOOL b, f;
  float t, mpx = 0.0, x, r = 0.0;
  initPos();
  for (n = 0; n < k; n++)
  {
    p = np[n];
    x = [p x];
    if (x > mpx) mpx = x;
    sz = p->gFlags.size;
    ti =  &(p->time);
    dir = ([p stemIsUp] ? -2 : 2);
    dys = -1;
    if (!([p stemIsUp]) && [p stemIsFixed])
	dys = 1;
    b = [p isBeamed];
    nl = p->headlist;
    hk = [nl count]; 
    for (i = 0; i < hk; i++)
    {
      noteHead = [nl objectAtIndex:i];
      j = [noteHead staffPosition];
      sp = [noteHead myStaff];
      dy = 0;
      if (!(j & 1))
      {
        j += dys;
        dy = dys;
      }
      f = NO;
      dp = 0;
      while (!f)
      {
        if (hasPos(sp, j + dp)) 
	    dp += dir;
        else
        {
          putPos(sp, j + dp, 0);
	    [noteHead setDotOffset: dp + dy];
	  f = YES;
        }
      }
      bt = [noteHead bodyType];
      t = getdotx(sz, bt, 0, ti->body, b, [p stemIsUp]);
      if ([noteHead isReverseSideOfStem])
	  t += [p halfWidthOfNoteHead: noteHead] * offside[[p stemIsUp] ? 1 : 0];
      if (t > r) r = t;
    }
  }
  for (n = 0; n < k; n++)
  {
    p = np[n];
      [p setDotOffset: r + (mpx - [p x])];
  }
}


- resetDots
{
    dotdx = 0.0;
    if ([self dottingCode] == 0)
	return self;
    lineupDots(&self, 1);
    return self;
}


/* reset the stem direction (OK to use pos here) */

- resetStemdir: (int) m
{
    int s;
    
    if ([self stemIsFixed])
	return self;
    s = [self midPosOff];
    if (m == 0 && s == 0) 
	return self;
    if ([self stemIsUp] != (s > 0)) {
	[self setStemIsUp: (s > 0)];
	[self setStemLengthTo: -[self stemLength]];
	[self reverseHeads];
    }
    return self;
}


/*
  reset the stem length (defined to touch the notehead nearest the tail end.
  If caller did a flip, then reverseHeads BEFORE calling this.
*/

- resetStemlen
{
  NoteHead *noteHead = [headlist lastObject];
  [self setStemLengthTo: getstemlen(time.body, gFlags.size, stype[(int)[noteHead bodyType]], [self stemIsUp], [noteHead staffPosition], [self getSpacing])];
  return self;
}


/* used for sims, when p encroaches from another note */

- resetStemlenUsing: (int) pos
{
  [self setStemLengthTo: getstemlen(time.body, gFlags.size, 0, [self stemIsUp], pos, [self getSpacing])];
  return self;
}


/* reset the accidentals */

extern unsigned char accidents[NUMHEADS][NUMACCS];
extern unsigned char accifont[NUMHEADS][NUMACCS];


/* returns whether to delay placement because of a reversed second */

static BOOL revSecond(NoteHead *p, float px, NoteHead *q, float qx)
{
  return (px < qx && [q accidental] && [q accidentalOffset] == 0.0
    && [p myStaff] == [q myStaff] && [q staffPosition] - [p staffPosition] == 1);
}


/* return whether noteHead's accidental is too close to a protruding notehead */

/* unused, flat, sharp, natural, d-flat, d-sharp, 2q-flat, 1q-flat, 2q-sharp, 1q-sharp */

static char clearbot[NUMACCS] = {0, 2, 3, 3, 2, 3, 2, 2, 3, 3};
static char cleartop[NUMACCS] = {0, -4, -3, -3, -4, -2, -4, -4, -3, -3};

static BOOL hitsSide(float curx, NoteHead *noteHead, NoteHead *nh[], float lbear[], int n)
{
  NoteHead *p;
  Staff *hs;
  int i, dp, cb, ct, hp;
  cb = clearbot[(int)[noteHead accidental]];
  ct = cleartop[(int)[noteHead accidental]];
  hp = [noteHead staffPosition];
  hs = [noteHead myStaff];
  for (i = 0; i < n; i++)
  {
    p = nh[i];
    if (curx > lbear[i] && [p myStaff] == hs)
    {
      dp = [p staffPosition] - hp;
      if (0 <= dp && dp <= cb) return YES;
      if (dp <= 0 && dp >= ct) return YES;
    }
  }
  return NO;
}

static int nix(NoteHead *noteHead, NoteHead *nh[], int hn)
{
  while (hn--)
  {
    if (noteHead == nh[hn]) return hn;
  }
  return 0;
}

static float accxoff[3] = {3.0, 2.25, 1.5};

void lineupAccs(NoteHead *ah[], int an, NoteHead *nh[], GNote *note[], int hn)
{
  int i, j, dp, lpos, lowest, didskip, sz;
  float lbear[64], ncw, curx, accx, w, minb = MAXFLOAT;
  NSFont *f;
  Staff *lsp;
  GNote *p;
  NoteHead *noteHead, *g;
  for (i = 0; i < hn; i++)
  {
    p = note[i];
    w = [p halfWidth];
    lbear[i] = [p x];
    if (!([p stemIsUp]) && [nh[i] isReverseSideOfStem]) lbear[i] -= 3.0 * w; else lbear[i] -= w;
    accx = lbear[i] - accxoff[p->gFlags.size];
    if (accx < minb) minb = accx;
  }
  curx = minb;
  ncw = halfwidth[0][0][5];
  dp = 1;
  i = 0;
  while(an)
  {
    lpos = 0;
    lsp = nil;
    lowest = 0;
    didskip = 0;
    for ( ; (0 <= i && i < an); i += dp)
    {
      noteHead = ah[i];
      if ([noteHead myStaff] == lsp && ABS([noteHead staffPosition] - lpos) < 6)
      {
        didskip = 1;
	continue;
      }
      if (i + 1 < an)
      {
        g =  ah[i + 1];
	if (revSecond(noteHead, lbear[nix(noteHead, nh, hn)], g, lbear[nix(g, nh, hn)]))
        {
          didskip = 1;
	  continue;
        }
      }
      if (hitsSide(curx, noteHead, nh, lbear, hn))
      {
        didskip = 1;
	continue;
      }
      p = note[nix(noteHead, nh, hn)];
      sz = p->gFlags.size;
      f = musicFont[accifont[(int)[noteHead bodyType]][(int)[noteHead accidental]]][sz];
      w = charFGW(f, accidents[(int)[noteHead bodyType]][(int)[noteHead accidental]]);
      if (w > ncw) ncw = w;
      [noteHead setAccidentalOffset: (curx - w) - [p x]];
/*
NSLog(@"curx %f: pos[%d] set to: %f\n", curx, [noteHead staffPosition], [noteHead accidentalOffset]);
*/
      lpos = [noteHead staffPosition];
      lsp = [noteHead myStaff];
      an--;
      if (i == an) lowest = 1;
      for (j = i; j < an; j++) ah[j] = ah[j + 1];
      if (dp == 1) i--;
    }
    if (!lowest && !didskip)
    {
      dp = -1;
      i = an - 1;
    }
    else
    {
      dp = 1;
      i = 0;
    }
    curx -= ncw + 1.0;
    ncw = 0.0;
  }
}


- resetAccidentals
{
  NoteHead *noteHead, *ah[MAXHEADS], *nh[MAXHEADS];
  GNote *note[MAXHEADS];
  int i, j, k, hk, n;
  hk = [headlist count];
  n = 0;
  for (i = 0; i < hk; i++)
  {
    noteHead = [headlist objectAtIndex:i];
    nh[i] = noteHead;
    note[i] = self;
    if ([noteHead accidental])
    {
      ah[n++] = noteHead;
      [noteHead setAccidentalOffset: 0.0];
    }
  }
  if (n == 0) return self;
  /* reverse list if stem is up */
  if ([self stemIsUp])
  {
    j = n / 2;
    k = n;
    for (i = 0; i < j; i++)
    {
      k--;
      noteHead = ah[i];
      ah[i] = ah[k];
      ah[k] = noteHead;
    }
  }
  lineupAccs(ah, n, nh, note, hk);
  return self;
}


/*
  insert a NoteHead into the headlist. upstems in descending y-order,
  downstems in ascending y-order. Return whether success.
  Now allows double-stopped unisons, so always succeeds.
*/

- (BOOL) insertHead: (NoteHead *) noteHead
{
  int i, k;
  NoteHead *q;
  float hy = [noteHead y];
  k = [headlist count];
  if ([self stemIsUp])
  {
    for (i = 0; i < k; i++)
    {
      q = [headlist objectAtIndex:i];
      if ([q y] < hy)
      {
        [headlist insertObject:noteHead atIndex:i];
        return YES;
      }
    }
  }
  else
  {
    for (i = 0; i < k; i++)
    {
      q = [headlist objectAtIndex:i];
      if ([q y] > hy)
      {
        [headlist insertObject:noteHead atIndex:i];
        return YES;
      }
    }
  }
  [(NSMutableArray *)headlist addObject: noteHead];
  return YES;
}


/* ensure Chord is in a consistent format after mods have taken place */


- resetChord
{
  [self resetStemdir: 0];
  [self reshapeChord];
  return self;
}


- reshapeChord
{
  [self resetSides];
  [self resetDots];
  [self resetStemlen];
  [self resetAccidentals];
  [self updateNote];
  return self;
}



- normaliseChord
{
  [self resetChord];
  [self updateNote];
  return self;
}


/*
  create a new notehead for self at y.
  Return whether succeeded.
*/

- (BOOL) newHeadOnStaff: (Staff *) sp atHeight: (float) ny accidental: (int) acc
{
    NoteHead *noteHead;
    
    if ([headlist count] == MAXHEADS) return NO;
    noteHead = [[NoteHead alloc] init];
    [noteHead setStaffPosition: [sp findPos: ny]];
    [noteHead setCoordinateY: [sp yOfStaffPosition: [noteHead staffPosition]]];
    [noteHead setAccidental: acc];
    [noteHead setNote: self];
    [noteHead setBodyType: gFlags.subtype];
    [self insertHead: noteHead];
    gFlags.selend = [headlist indexOfObject:noteHead];
    [self normaliseChord];
    [self recalc];
    [self setOwnHangers];
    return YES;
}


/* remove head with index i and insert it in appropriate place */

- relinkHead: (int) i
{
    NoteHead *noteHead = [[headlist objectAtIndex:i] retain];
    [headlist removeObjectAtIndex:i];
  [self insertHead: noteHead];
  gFlags.selend = [headlist indexOfObject:noteHead];
  [self normaliseChord];
  return self;
}


/* remove notehead, check for reversion to notehead=nil format and Ties */

- deleteHead: (int) i
{
  int k, e;
  TieNew *t;
  if (i < [headlist count])
  {
    [headlist removeObjectAtIndex:i];
    k = [hangers count];
    while (k--)
    {
      t = [hangers objectAtIndex:k];
      if ([t graphicType] == TIENEW)
      {
          e = [t whichEnd: self];
          if (e == 2)
	{
          if (i == t->head2) [t removeObj];
          else if (i < t->head2) t->head2 -= 1;
	}
	else if (e == 1)
	{
          if (i == t->head1) [t removeObj];
          else if (i < t->head1) t->head1 -= 1;
	}
      }
    }
    [self normaliseChord];
    if (gFlags.selend != 0) --(gFlags.selend);
  }
  return self;
}


/*
  Draw ledger lines. Amazingly difficult because a chord could have notes that
  cause ledger lines on each staff in the system.  Four main cases (stemup/dn,
  above/below staff).  Also handles different widths for 'wrong side' notes.
  Fortunately this method generalises to sims.
*/

extern float ledgethicks[3];
extern float ledgedxs[3];


- drawLedgerAt: (float) dx size: (int) sz mode: (int) mode
{
  char ha[NUMSTAVES], hwsa[NUMSTAVES], lb[NUMSTAVES], lwsb[NUMSTAVES];
  Staff *sps[NUMSTAVES];
  NoteHead *noteHead;
  Staff *sp;
  int i, j, k, sn, hp, mp;
  float lx1, lx2, ly, dwsx;
  BOOL f = NO;
  if (mystaff == nil) return self;
  dx += ledgedxs[sz];
  for (i = 0; i < NUMSTAVES; i++)
  {
    ha[i] = -1;
    hwsa[i] = -1;
    lb[i] = 9;
    lwsb[i] = 9;
    sps[i] = nil;
  }
  k = [headlist count];
  for (i = 0; i < k; i++)
  {
    noteHead = [headlist objectAtIndex:i];
    sp = [noteHead myStaff];
    if ([sp graphicType] == STAFF)
    {
      sn = [sp myIndex];
      sps[sn] = sp;
      hp = [noteHead staffPosition];
      if ([noteHead isReverseSideOfStem])
      {
        if (hp < hwsa[sn]) hwsa[sn] = hp;
        if (hp > lwsb[sn]) lwsb[sn] = hp;
      }
      else
      {
        if (hp < ha[sn]) ha[sn] = hp;
        if (hp > lb[sn]) lb[sn] = hp;
      }
    }
  }
  for (i = 0; i < NUMSTAVES; i++) if ((sp = sps[i]) != nil)
  {
    mp = MIN(ha[i], hwsa[i]);
    if (mp < -1)
    {
      if (mp & 1) ++mp;
      for (j = mp; j <= -2; j += 2)
      {
        ly = [sp yOfTop] + (int) sp->flags.spacing * j;
	dwsx = (hwsa[i] < -1 && j >= hwsa[i] ? dx : 0.0);
        if ([self stemIsUp])
	{
	  lx1 = x - dx;
	  lx2 = x + dx + dwsx;
	}
	else
	{
	  lx1 = x - dx - dwsx;
	  lx2 = x + dx;
	}
	cmakeline(lx1, ly, lx2, ly, mode);
        f = YES;
      }
    }
    mp = MAX(lb[i], lwsb[i]);
    if (mp > 9)
    {
      if (mp & 1) --mp;
      for (j = 10; j <= mp; j += 2)
      {
        ly = [sp yOfTop] + (int) sp->flags.spacing * j;
	dwsx = (lwsb[i] > 9 && j <= lwsb[i] ? dx : 0.0);
        if ([self stemIsUp])
	{
	  lx1 = x - dx;
	  lx2 = x + dx + dwsx;
	}
	else
	{
	  lx1 = x - dx - dwsx;
	  lx2 = x + dx;
	}
	cmakeline(lx1, ly, lx2, ly, mode);
        f = YES;
      }
    }
  }
  if (f) cstrokeline(ledgethicks[sz], mode);
  return self;
}

@end
