#import "GNote.h"
#import "NoteHead.h"
#import "TimedObj.h"
#import "ChordGroup.h"
#import "muxlow.h"
#import <Foundation/NSArray.h>


/* 
  A rudimentary algorithm for resolving collisions of sims by case analysis.
  This finds the first collision in a sim and fixes it.
*/

#define VOICEID(v, s) (v ? NUMSTAVES + v : s)
#define MAXNOTES 3
#define MAXACCS  64

extern unsigned char hasstem[10];
extern unsigned char hasflag[10];
extern void lineupDots(GNote *np[], int k);
extern void lineupAccs(NoteHead *ah[], int an, NoteHead *nh[], GNote *note[], int hn);


/*
  stems might need to be lengthened in sim clusters
  Use vcx as a known x-offset.
*/

/* stemheight in ss units */

static float stemheight[3][5] =
{
  {10,   9,    8,  7,    7},
  {7.5,  6.75, 6,  5.25, 5.25},
  {5,    4.5,  4,  3.5,  3.5}
};


static void doStems(GNote *nn[], int k, int sn, float vcx[])
{
  int i, j, mp, hlk, psu;
  float px, sl;
  NoteHead *h;
  GNote *p, *q;
  for (i = 0; i < k; i++)
  {
    p = nn[i];
    px = vcx[VOICEID(p->voice,sn)];
    if (hasflag[p->time.body] && !(p->time.nostem))
    {
      psu = [p stemIsUp];
      mp = p->staffPosition;
      for (j = 0; j < k; j++)
      {
	if (i == j) continue;
	q = nn[j];
        if (vcx[VOICEID(q->voice,sn)] >= px)
	{
	  hlk = [q numberOfNoteHeads];
	  while (hlk--)
	  {
	    h = [q noteHead: hlk];
	    if (psu)
	    {
	      if ([h staffPosition] < mp) mp = [h staffPosition];
	    }
	    else
	    {
	      if ([h staffPosition] > mp) mp = [h staffPosition];
	    }
	  }
	}
      }
      if (psu)
      {
          sl = ((p->staffPosition - mp) - stemheight[p->gFlags.size][p->time.body] - 0.5) * [p getSpacing];
	  if (sl < [p stemLength]) 
	      [p setStemLengthTo: sl];
      }
      else
      {
        sl = ((mp - p->staffPosition) + stemheight[p->gFlags.size][p->time.body] + 0.5) * [p getSpacing];
	if (sl > [p stemLength])
	    [p setStemLengthTo: sl];
      }
    }
  } 
}


/*
  accidents where accidoff > 0 are not included, as this is a special code that
  means the accidental is suppressed for coincident unisons
*/

static void doAccidentals(GNote *nn[], int k)
{
  NoteHead *nh[MAXACCS], *ah[MAXACCS], *h;
  GNote *p, *note[MAXACCS];
  int g, j, i, nk, nacc = 0, nheads = 0;
    
  for (i = 0; i < k; i++)
  {
    p = nn[i];
    nk = [p numberOfNoteHeads];
    for (j = 0; j < nk; j++)
    {
      h = [p noteHead: j];
      if (nheads < MAXACCS)
      {
        nh[nheads] = h;
	note[nheads++] = p;
      }
      if ([h accidental] && [h accidentalOffset] <= 0.0 && nacc < MAXACCS)
      {
        ah[nacc++] = h;
	[h setAccidentalOffset:  0.0];
      }
    }
  }
  if (nacc == 0) return;
  /* now sort into pos order */
  for (g = nacc / 2; g > 0; g /= 2)
  {
    for (i = g; i < nacc; i++)
    {
      for (j = i - g; j >= 0; j -= g)
      {
        if ([ah[j] staffPosition] > [ah[j+g] staffPosition])
	{
	  h = ah[j];
	  ah[j] = ah[j+g];
	  ah[j+g] = h;
	}
      }
    }
  }
  lineupAccs(ah, nacc, nh, note, nheads);
}


/* check if two notes are clear */

static char clearcode[4][4] =
{
  { 1, 1, 1, 1},
  { 1, 0, 1, 0},
  { 0, 0, 1, 1},
  { 0, 0, 1, 0}
};


static BOOL clearPair(GNote *a, GNote *b)
{
  return (clearcode[(hasstem[a->time.body] << 1) | hasstem[b->time.body]]
  				[([a stemIsUp] << 1) | [b stemIsUp]]);
}


/* see whether a sim needs to be 'kerned': several formulae */

/* for p and q unison same-stem */

static float kern0(GNote *p, GNote *q)
{
  return halfwidth[p->gFlags.size][0][p->time.body]
   + halfwidth[q->gFlags.size][0][q->time.body];
}


/* for p and q at interval of a second */

static float kern1(GNote *p, GNote *q)
{
// NSLog(@"used kern1 (%d, %d)\n", p->time.body, q->time.body);
  return 0.7 * halfwidth[p->gFlags.size][0][p->time.body]
    + 0.7 * halfwidth[q->gFlags.size][0][q->time.body];
}


/* add to q for q's stem to bybass p's body (p is above q)*/
 
static float kern2(GNote *p, GNote *q)
{
  float pw = halfwidth[p->gFlags.size][0][p->time.body];
  float qw = halfwidth[q->gFlags.size][0][q->time.body];
  float e = pw - qw;
// NSLog(@"used kern2 (%d, %d)\n", p->time.body, q->time.body);
  return e + 0.7 * qw;
}


/* 0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1
   0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  */
   
static char paircode[4][16] =
{
  {0, 2, 3, 3, 0, 2, 3, 3, 0, 2, 0, 0, 1, 2, 3, 3},
  {0, 2, 3, 3, 0, 2, 3, 3, 0, 2, 0, 0, 1, 2, 3, 3},
  {0, 6, 6, 3, 0, 6, 6, 6, 0, 6, 0, 0, 1, 6, 6, 6},
  {0, 2, 3, 3, 0, 2, 3, 3, 0, 2, 0, 0, 1, 2, 3, 3},
};


static float kernValue(int c, GNote *a, GNote *b)
{
  switch(c)
  {
    case 0: return 0.0;
    case 1: return kern0(a, b);
    case 2: return kern1(a, b);
    case 3: return kern2(a, b);
    case 4: return -kern1(b, a);
    case 5: return -kern2(b, a);
    case 6: return -kern0(b, a);
  }
  return 0.0;
}


/*
  Test clearance of one chord with another
*/

static int chordClearance(GNote *p, GNote *q)
{
  int pl, ph, ql, qh, r = 2;
  [p posRange: &pl : &ph];
  [q posRange: &ql : &qh];
  if (pl < ql)
  {
    if (ph >= ql) r = 0;
    else if (ph + 1 == ql) r = 1;
    if (r == 2 && !(clearPair(p, q))) r = 0;
  }
  else
  {
    if (qh >= pl) r = 0;
    else if (qh + 1 == pl) r = -1;
    if (r == 2 && !(clearPair(q, p))) r = 0;
  }
// NSLog(@"chordClearance(%d [%d-%d], %d [%d-%d]) = %d\n", p->time.body, pl, ph, q->time.body, ql, qh, r);
  return r;
}


/*
  crude quadratic method probably faster than using Pos database for small n
*/

static char pbelow[2][2] = {{0, 1}, {4, 0}};
static char pabove[2][2] = {{0, 2}, {6, 0}};

static char nestleCode(GNote *p, int pk, GNote *q, int qk)
{
  int i, j, dp;
  NoteHead *ph, *qh;
  unsigned char ps = [p stemIsUp];
  unsigned char qs = [q stemIsUp];
  if (ps == qs) return 1;
  for (i = 0; i < pk; i++)
  {
    ph = [p noteHead: i];
    for (j = 0; j < qk; j++)
    {
      qh = [q noteHead: j];
      if ([ph myNote] != [qh myNote])  /* is this test ever NO? */
      {
        dp = [ph staffPosition] - [qh staffPosition];
	if (dp == 0) return (ps ? 6 : 1);
        else if (dp == -1) return pabove[ps][qs];
	else if (dp == 1) return pbelow[ps][qs];
      }
    }
  }
  return (ps ? 5 : 3);
}


/*
  Special treatment for unisons.
  suppress one accidental in a pair of coincident unisons
  caller ensures dp == 0
*/

static char uniscode[4][4] =
{
  { 1,  1, -1,  1},
  { 1,  1,  1,  1},
  {-1, -1, -1, -1},
  { 1,  1, -1,  1},
};

/* a UID to check head coincidence compatibility */

static char headgraf[10] = { 1, 1, 1, 1, 1, 1, 2, 3, 4, 5};

/* has stems:  neither, q, p, both */

static char ustemcode[4] =  {0, -1, 1, 0};

/* returns r (added to q) or -r (-added to p) */

static float checkUnison(GNote *p, GNote *q)
{
  char ad, bd, au, bu, c, ea;
  float r;
  NoteHead *g, *h;
  ad = ([p dottingCode] != 0);
  au = [p stemIsUp];
  bd = ([q dottingCode] != 0);
  bu = [q stemIsUp];
  g = [p noteHead: 0];
  h = [q noteHead: 0];
  ea = ([g accidental] == [h accidental]);
  if (au != bu /* && [p dottingCode] == [q dottingCode] */ && headgraf[p->time.body] == headgraf[q->time.body]) r = 0.0;
  else if (c = ustemcode[(hasstem[p->time.body] << 1) | hasstem[q->time.body]]) r = c * kern0(p, q);
  else r = uniscode[(ad << 1) | bd][(au << 1) | bu] * kern0(p, q);
  if (r < 0)
  {
    if (ea && [h accidentalOffset] <= 0) [g setAccidentalOffset: 1.0];
  }
  else
  {
    if (ea && [g accidentalOffset] <= 0) [h setAccidentalOffset: 1.0];
  }
  return r;
}

static char nstmcode[2][2] =
{
  {0, 2},
  {0, 2}
};

static char bstmcode[4][8] =
{
  {0, 2, 0, 0, 0, 2, 6, 6},
  {0, 2, 0, 0, 0, 6, 6, 6},
  {0, 2, 0, 0, 0, 2, 6, 6},
  {0, 2, 0, 0, 0, 6, 6, 6}
};

static char astmcode[4][8] =
{
  {6, 5, 0, 0, 6, 5, 4, 4},
  {6, 5, 0, 0, 6, 5, 4, 4},
  {6, 5, 0, 0, 1, 2, 0, 0},
  {6, 5, 0, 0, 6, 5, 4, 4}
};

/*
  never called with dp == 0
*/

static int kernPairCode(GNote *a, GNote *b, int dp)
{
  unsigned char ad, bd, as, bs, c;
  ad = ([a dottingCode] != 0);
  bd = ([b dottingCode] != 0);
  as = hasstem[a->time.body];
  bs = hasstem[b->time.body];
  c = ((as << 1) | bs);
  switch (c)
  {
    case 0:  /* neither stemmed */
      c = nstmcode[ad][(dp == 1)];
// NSLog(@"kernPairCode(b%d, b%d) nst[%d][%d] = %d\n", a->time.body, b->time.body, ad, (dp == 1), c);
      break;
    case 1:  /* only b stemmed */
      bs = [b stemIsUp];
      c = bstmcode[(ad << 1) | bd][(bs << 2) | dp];
// NSLog(@"kernPairCode(b%d, b%d) bst[%d][%d] = %d\n", a->time.body, b->time.body, (ad << 1) | bd, (bs << 2) | dp, c);
      break;
    case 2:  /* only a stemmed */
      as = [a stemIsUp];
      c = astmcode[(ad << 1) | bd][(as << 2) | dp];
// NSLog(@"kernPairCode(b%d, b%d) ast[%d][%d] = %d\n", a->time.body, b->time.body, (ad << 1) | bd, (as << 2) | dp, c);
      break;
    case 3:  /* both stemmed */
      as = [a stemIsUp];
      bs = [b stemIsUp];
      c = paircode[(ad << 1) | bd][(as << 3) | (bs << 2) | dp];
// NSLog(@"kernPairCode(b%d, b%d) pc[%d][%d] = %d\n", a->time.body, b->time.body, (ad << 1) | bd, (as << 3) | (bs << 2) | dp, c);
  }
  return c;
}


void kernsim(int sn, int s1, int s2, NSMutableArray *nl, float vcx[])
{
  int i, j, v, dp, nn, dnn;
  char pp, qp, nh[MAXNOTES];
  float k;
  GNote *p, *n[MAXNOTES], *dn[MAXNOTES], *na, *nb;
  ChordGroup *g;
  nn = dnn = 0;
  for (i = s1; i <= s2; i++)
  {
    p = [nl objectAtIndex:i];
    v = VOICEID(p->voice, sn);
    vcx[v] = 0.0;
    if ([p graphicType] == NOTE && !ISINVIS(p))
    {
      if (nn < MAXNOTES)
      {
        n[nn] = p;
	nh[nn++] = [p numberOfNoteHeads];
      }
      if ([p dottingCode] && dnn < MAXNOTES) dn[dnn++] = p;
    }
  }
  for (i = 0; i < nn - 1; i++)
  {
    for (j = i + 1; j < nn; j++)
    {
      g = [n[i] myChordGroup];
      if (g != nil && g == [n[j] myChordGroup]) continue;
      if (nh[i] == 1 && nh[j] == 1) 
      {
        pp = n[i]->staffPosition;
        qp = n[j]->staffPosition;
	dp = pp - qp;
	if (dp == 0)
	{
	  k = checkUnison(n[i], n[j]);
	  if (k < 0) vcx[VOICEID(n[i]->voice,sn)] = -k;
	  else vcx[VOICEID(n[j]->voice,sn)] = k;
	  doAccidentals(n, nn);
	  doStems(n, nn, sn, vcx);
	  return;
	}
        else if (dp < 0)
        {
          dp = -dp;
	  if (dp > 7) continue;
	  if (dp > 3) dp = 3;
	  na = n[i];
	  nb = n[j];
	}
	else
	{
	  if (dp > 7) continue;
	  if (dp > 3) dp = 3;
	  na = n[j];
	  nb = n[i];
	}
	if (dp >= 2 && clearPair(na, nb)) continue;
	k = kernValue(kernPairCode(na, nb, dp), na, nb);
      }
      else
      {
	na = n[i];
	nb = n[j];
	dp = chordClearance(na, nb);
	switch(dp)
	{
	  default:
	    continue;
	  case 0:
	    k = kernValue(nestleCode(na, nh[i], nb, nh[j]), na, nb);
	    break;
	  case 1:
	    k = kernValue(kernPairCode(na, nb, 1), na, nb);
	    break;
	  case -1:
	    k = kernValue(kernPairCode(nb, na, 1), nb, na);
	    break;
	}
      }
      if (k < 0) vcx[VOICEID(na->voice,sn)] = -k;
      else vcx[VOICEID(nb->voice,sn)] = k;
      if (dnn) lineupDots(dn, dnn);
      doAccidentals(n, nn);
      doStems(n, nn, sn, vcx);
      return;
    }
  }
  if (dnn) lineupDots(dn, dnn);
  doAccidentals(n, nn);
  doStems(n, nn, sn, vcx);
}
