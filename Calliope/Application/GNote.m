/* $Id$ */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "GNote.h"
#import "NoteInspector.h"
#import "GNChord.h"
#import "GraphicView.h"
#import "NoteHead.h"
#import "Hanger.h"
#import "ChordGroup.h"
#import "Staff.h"
#import "System.h"
#import "TieNew.h"
#import "CallInst.h"
#import "DrawingFunctions.h"
#import "muxlow.h"

/*
  Legend for headlist indices:
  objectAt:0 is away from the stem direction.  The lastObject is the one nearest the flag.
*/


#define SELHEADIX(s, k)  (((s) < (k)) ? (s) : 0)

extern unsigned char hasstem[10];
extern BOOL centhead[NUMHEADS];
extern unsigned char headchars[NUMHEADS][10];
extern unsigned char headfont[NUMHEADS][10];
extern float stemdx[3][NUMHEADS][2][10][2];
extern float stemdy[3][NUMHEADS][2][10][2];
extern unsigned char shapeheads[4][10][2];
extern unsigned char shapefont[4];
extern void drawhead(float x, float y, int bt, int body, int sid, int su, int sz, int m);

float offside[2] = {-2.0, +2.0};
char stype[NUMHEADS] = {0, 1, 0, 0, 0, 1, 0}; /* gFlags.subtype -> stem 0=modern, 1=centred */

int noteNameNumRelC(int pos, int mc);

@implementation GNote:TimedObj

extern id lastHit;

static GNote *proto;

unsigned char accidents[NUMHEADS][NUMACCS] =
{
  {SF_natural, SF_flat, SF_sharp, SF_natural, SF_dbflat, SF_dbsharp, CH_3qflat, CH_1qflat, CH_3qsharp, CH_1qsharp},
  {SF_natural, CH_flat, CH_sharp, SF_natural, SF_dbflat, SF_dbsharp, CH_3qflat, CH_1qflat, CH_3qsharp, CH_1qsharp},
  {SF_natural, SF_flat, SF_sharp, SF_natural, SF_dbflat, SF_dbsharp, CH_3qflat, CH_1qflat, CH_3qsharp, CH_1qsharp},
  {SF_natural, SF_flat, SF_sharp, SF_natural, SF_dbflat, SF_dbsharp, CH_3qflat, CH_1qflat, CH_3qsharp, CH_1qsharp},
  {SF_natural, SF_flat, SF_sharp, SF_natural, SF_dbflat, SF_dbsharp, CH_3qflat, CH_1qflat, CH_3qsharp, CH_1qsharp},
  {SF_natural, CH_flat, CH_sharp, SF_natural, SF_dbflat, SF_dbsharp, CH_3qflat, CH_1qflat, CH_3qsharp, CH_1qsharp},
  {SF_natural, SF_flat, SF_sharp, SF_natural, SF_dbflat, SF_dbsharp, CH_3qflat, CH_1qflat, CH_3qsharp, CH_1qsharp},
};

unsigned char accifont[NUMHEADS][NUMACCS] =
{
  {1, 1, 1, 1, 1, 1, 0, 0, 0, 0},
  {1, 0, 0, 1, 1, 1, 0, 0, 0, 0},
  {1, 1, 1, 1, 1, 1, 0, 0, 0, 0},
  {1, 1, 1, 1, 1, 1, 0, 0, 0, 0},
  {1, 1, 1, 1, 1, 1, 0, 0, 0, 0},
  {1, 0, 0, 1, 1, 1, 0, 0, 0, 0},
  {1, 1, 1, 1, 1, 1, 0, 0, 0, 0},
};


+ (void)initialize
{
  if (self == [GNote class])
  {
    proto = [GNote alloc];
    proto->gFlags.subtype = 0;
    proto->gFlags.locked = 0;
    proto->time.stemup = 1;
    proto->time.stemfix = 0;
    proto->time.tight = 0;
    proto->time.nostem = 0;
    proto->voice = 0;
    proto->instrument = 0;
    proto->isGraced = 0;
    proto->showslash = 0;
    (void)[GNote setVersion: 9];	/* class version, see read: */ /*sb: left at 9 */
  }
  return;
}


+ myPrototype
{
  return proto;
}


+  myInspector
{
  return [NoteInspector class];
}


- init
{
    self = [super init];
    if(self != nil) {
	NoteHead *h = [[NoteHead alloc] init];

	headlist = [[NSMutableArray alloc] init];
	[headlist addObject: h]; // start with a single note-head.
	[h release];
	gFlags.subtype = 0;
	p = 0;
	gFlags.type = NOTE;
	dotdx = 0.0;
	instrument = 0;
	showslash = 0;	
    }
    return self;
}


- (NSString *) description
{
    return [NSString stringWithFormat: @"%@: x = %f, y = %f %@", [super description], x, y, [self describeChordHeads]];
}


- (void)dealloc
{
  if (headlist)
  {
    [headlist removeAllObjects];
    [headlist release];
    headlist = nil;
  }
  { [super dealloc]; return; };
}


/* override to provide for Chord.  */

- (BOOL) getXY: (float *) fx : (float *) fy
{
  NoteHead *h;
  float dx = 2.0 * nature[gFlags.size];
  h = [headlist objectAtIndex:SELHEADIX(gFlags.selend, [headlist count])];
  if (h->side) dx = (time.stemup ? dx : -dx); else dx = 0.0;
  *fx = x + dx;
  *fy = h->myY;
  return YES;
}


- (void)moveBy:(float)dx :(float)dy
{
  int k = [headlist count];
    id theObj;
    while (k--)
      {
        theObj = [headlist objectAtIndex:k];
        [theObj moveBy:dx :dy];
      }
    [super moveBy:dx :dy];
}


- (float) headY: (int) n
{
  return ((NoteHead *) [headlist objectAtIndex:n])->myY;
}


- (BOOL) defaultStemup: (System *) sys : (Staff *) sp
{
  int cpos;
  if (time.stemfix) return(time.stemup);
  cpos = getLines(sp) - 1;
  if (p < cpos) return(NO);
  if (p > cpos) return(YES);
  if (p == cpos) return([sys whereIs: sp] < 0);
  return NO;
}


/* initialise newly created note */

- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
{
  NoteHead *h;
  [super proto: v : pt : sp : sys : g : i];
  gFlags.subtype = proto->gFlags.subtype;
  gFlags.locked = proto->gFlags.locked;
  time.stemup = proto->time.stemup;
  time.stemfix = proto->time.stemfix;
  time.tight = proto->time.tight;
  time.nostem = proto->time.nostem;
  time.body = i;
  voice = proto->voice;
  instrument = proto->instrument;
  showslash = proto->showslash;
  isGraced = proto->isGraced;
  h = [headlist lastObject];
  h->myNote = self;
  h->type = gFlags.subtype;
  if (TYPEOF(sp) == STAFF)
  {
    p = [sp findPos: pt.y];
    y = [sp yOfPos: p];
    h->pos = p;
    h->myY = y;
    if (!time.stemfix) time.stemup = [self defaultStemup: sys : sp];
  }
  else
  {
    h->pos = p;
    h->myY = y;
    if (!time.stemfix) time.stemup = 1;
  }
  [self resetStemlen];
  return self;
}


/* modify bounds of proximal chord to include flags */

- recalc
{
  NSRect b;
  ChordGroup *q;
  [super recalc];
  if ([self isBeamed]) return self;
  q = [self myChordGroup];
  if (q != nil && self == [q myProximal] && hasstem[time.body])
  {
    bbinit();
    [self drawStem: 0];
    b = getbb();
    bounds  = NSUnionRect(b , bounds);
  }
  return self;
}


/* obj's staff Y has changed.  Update our Y caches.  Caller recalcs. */

- (BOOL) reCache: (float) sy : (int) ss
{
  int i, k;
  float t=0.0;
  NoteHead *h;
  BOOL mod=NO;
  k = [headlist count];
  for (i = 0; i < k; i++)
  {
    h = [headlist objectAtIndex:i];
    t = sy + ss * h->pos;
    if (t != h->myY)
    {
      mod = YES;
      h->myY = t;
    }
  }
  /* h will be lastobject, with t valid, so check StaffObj's Y */
  if (t != y)
  {
    mod = YES;
    y = t;
  }
  return mod;
}


/*
  This happens after a paste.
  object has a new y and staff, and this may have call for a new p.
*/

- rePosition
{
  int k, np, dp;
  NoteHead *h;
  np = [self posOfY: y];
  dp = np - p;
  if (dp == 0) return self;
  p = np;
  k = [headlist count];
  while (k--)
  {
    h = [headlist objectAtIndex:k];
    h->pos += dp;
  }
  return self;
}


/* put all components into the (context dependent) default state */

- reDefault
{
  [self resetChord];
  return [self reShape];
}


/* recalc caches assuming that state will say as it is */

- reShape
{
  [self reshapeChord];
  return [super reShape];
}


/* sets stem to the default in the specified direction */

- defaultStem: (BOOL) up
{
  if (up != time.stemup)
  {
    time.stemup = up;
    [self reverseHeads];
    [self resetStemlen];
    [self reshapeChord];
  }
  else
  {
    [self resetStemlen];
  }
  [self recalc];
  return self;
}


/* sets stem to specified length */

- setStemTo: (float) s
{
  BOOL up = (s < 0);
  if (up != time.stemup)
  {
    time.stemup = up;
    [self reverseHeads];
    [self reshapeChord];
  }
  time.stemlen = s;
  [self recalc];
  return self;
}

/* return the stem base */

- (float) wantsStemY: (int) a
{
  NoteHead *h;
  h = (time.stemup == a) ? [headlist lastObject] : [headlist objectAtIndex:0];
  return h->myY;
}


/*
  Return positions at extremities (a = whether to return above).
  If note is connected to a beam crossing staves, then the stemlength
  must not be used when boundAboveBelow is used during finding the
  height of a staff.
 */

extern unsigned char hasstem[10];


- (float) yMean
{
  int i, k;
  NoteHead *h;
  float r;
  r = 0.0;
  k = [headlist count];
  for (i = 0; i < k; i++)
  {
    h = [headlist objectAtIndex:i];
    r += h->myY;
  }
  return r / k;
}


- posRange: (int *) pl : (int *) ph
{
  int t0, t1;
  t0 = ((NoteHead *)[headlist objectAtIndex:0])->pos;
  t1 = ((NoteHead *)[headlist lastObject])->pos;
  if (t0 < t1)
  {
    *pl = t0;
    *ph = t1;
  }
  else
  {
    *pl = t1;
    *ph = t0;
  }
  return self;
}


- (int) posAboveBelow: (int) a
{
  int pos;
  NoteHead *h;
  float sy;
  if (time.stemup == a)
  {
    h = [headlist lastObject];
    sy = h->myY;
    if (hasstem[time.body]) sy += time.stemlen;
    pos = [h->myNote posOfY: sy];
  }
  else
  {
    h = [headlist objectAtIndex:0];
    pos = h->pos;
  }
 return pos;
}


- (float) boundAboveBelow: (int) a
{
  float ya, ye;
  NoteHead *h;
  if (time.stemup == a)
  {
    h = [headlist lastObject];
    ya = h->myY;
    if (hasstem[time.body])
    {
      if ([self hasCrossingBeam])
      {
        ya += getstemlen(time.body, gFlags.size, stype[(int)h->type], time.stemup, h->pos, [h->myNote getSpacing]);
      }
      else ya += time.stemlen;
    }
  }
  else
  {
    h = [headlist objectAtIndex:0];
    ye = nature[gFlags.size];
    ya = h->myY + (a ? -ye : ye);
  }
   return ya;
}


- (float) yAboveBelow: (int) a
{
  float ya;
  NoteHead *h;
  if (time.stemup == a)
  {
    h = [headlist lastObject];
    ya = h->myY;
    if (hasstem[time.body]) ya += time.stemlen;
  }
  else
  {
    h = [headlist objectAtIndex:0];
    ya = h->myY;
  }
   return ya;
}


- (int) midPosOff
{
  int k, r, cpos;
  NoteHead *h;
  r = 0;
  k = [headlist count];
  while (k--)
  {
    h = [headlist objectAtIndex:k];
    cpos = [h->myNote getLines] - 1;
    r += (h->pos - cpos);
  }
  return r;
}


- myChordGroup
{
    Hanger *q;
    int k = [hangers count];
    while (k--)
    {
        q = [hangers objectAtIndex:k];
        if (TYPEOF(q) == CHORDGROUP) return q;
    }
    return nil;
}


- (BOOL)selectMe: (NSMutableArray *) sl : (int) d :(int)active
{
    ChordGroup *q = [self myChordGroup];
    return (q == nil) ?  [super selectMe: sl : d :active] : [q selectGroup: sl : d :active];
}

- (BOOL)selectMember: (NSMutableArray *) sl : (int) d :(int)active
{
    return [super selectMe: sl : d :active];
}


- setAccidental: (int) a
{
    NoteHead *h;
    h = [headlist objectAtIndex:SELHEADIX(gFlags.selend, [headlist count])];
    h->accidental = (h->accidental == a) ? 0 : a;
    [self resetChord];
    return self;
}


- setHead: (int) a
{
    NoteHead *h;
    h = [headlist objectAtIndex:SELHEADIX(gFlags.selend, [headlist count])];
    h->type = (h->type == a) ? 0 : a;
    [self resetChord];
    return self;
}


/* set the accidental keystring, account for hanging accidentals too */

extern void getNumOct(int pos, int mc, int *num, int *oct);

- getKeyString: (int) mc : (char *) ks
{
    int i, k, num, oct, acc;
    NoteHead *h;
    for (i = 0; i < 7; i++) ks[i] = 0;
    k = [headlist count];
    while (k--)
    {
        h = [headlist objectAtIndex:k];
        if (h->accidental && !(h->editorial))
        {
            getNumOct(h->pos, mc, &num, &oct);
            ks[num] = h->accidental;
        }
    }
    if (acc = [self hangerAcc])
    {
        getNumOct(p, mc, &num, &oct);
        ks[num] = acc;
    }
    return self;
}

/* Return notes tied to other than self (return nil if obviously a slur) */

- (NSMutableArray *) tiedWith
{
  TieNew *h;
  NSMutableArray *nl, *r;
  GNote *q;
  int nk, k = [hangers count];
  r = nil;
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    if (TYPEOF(h) == TIENEW)
    {
      nl = h->client;
      nk = [nl count];
      while (nk--)
      {
        q = [nl objectAtIndex:nk];
	if (TYPEOF(q) == NOTE && q != self)
	{
	  if (q->p != p)
	  {
              [r autorelease];
	    return nil;
	  }
	  else
	  {
	    if (r == nil) r = [[NSMutableArray alloc] init];
	    [r addObject: q];
	  }
	}
      }
    }
  }
  return r;
}

/* return any accidental on any notehead at pos */

- (int) accAtPos: (int) pos
{
  int k;
  NoteHead *h;
  k = [headlist count];
  while (k--)
  {
    h = [headlist objectAtIndex:k];
    if (h->accidental && pos == h->pos) return h->accidental;
  }
  return 0;
}


- (int) getPatch
{
  if (instrument) return instrument - 1;
  return [instlist soundForInstrument: [self getInstrument]];
}


- (int) whereInstrument
{
  if (instrument) return 0;
  return [super whereInstrument];
}

/* Information for Shape Notes */

/*
  shapesym[x + degree] gives the shapecode for offset x and degree of note.
  The offset is specified by the key info.
  shapeoff[keysym][keynum] mode: 0=flat; 1=sharp. tonic origin from C.
*/

char shapesym[14] = {0, 1, 2, 0, 1, 2, 3, 0, 1, 2, 0, 1, 2, 3};

char shapeoff[2][8] =
{
  {0, 4, 1, 5, 2, 6, 3, 0},
  {5, 3, 6, 2, 5, 1, 4, 0}
};

/*
  Returns a shape code for the note based on its degree relative to the keyinfo
  enum{triangle, oval, square, diamond}.
*/

static int getShapeID(int pos, int s, int n, int c)
{
  return shapesym[noteNameNumRelC(pos, c) + shapeoff[s][n]];
}

/* the big case statement applies only to separate noteheads, hence the test */
- (BOOL) performKey: (int) c
{
    BOOL r = NO;
    
    if (self == lastHit) 
	switch(c) {
	    case '!':
		[self setAccidental: 3];
		r = YES;
		break;
	    case '@':
		[self setAccidental: 1];
		r = YES;
		break;
	    case '#':
		[self setAccidental: 2];
		r = YES;
		break;
	    case '$':
		[self setAccidental: 5];
		r = YES;
		break;
	    case '%':
		[self setAccidental: 4];
		r = YES;
		break;
	    case '/':
		[self setAccidental: 0];
		r = YES;
		break;
	    case '^':
		[self setHead: 0];
		r = YES;
		break;
	    case '&':
		[self setHead: 1];
		r = YES;
		break;
	    case '*':
		[self setHead: 5];
		r = YES;
		break;
	    case '(':
		[self setHead: 2];
		r = YES;
		break;
	    case ')':
		[self setHead: 3];
		r = YES;
		break;
	    case '+':
		[self setHead: 4];
		r = YES;
		break;
	    case ' ':
		if ([headlist count] > 1) [self deleteHead: gFlags.selend];
		r = YES;
		break;
	}
	if (r) {
	    [self recalc];
	    [self setOwnHangers];
	    return YES;
	}
	else 
	    return [super performKey: c];
}


/* move a note.  ALT-move just moves a notehead */

- (BOOL) moveHead: (NoteHead *) h : (BOOL) locked : (float) dy : (System *) sys
{
  float ny = dy + h->myY;
  int np = [h->myNote posOfY: ny];
  if (h->pos != np)
  {
    h->pos = np;
    h->myY = [self yOfPos: h->pos];
    return YES;
  }
  return NO;
}


/* handles move and ALT-move for chords and notes */

- (BOOL)  move: (float) dx : (float) dy : (NSPoint) pt : (System *) sys : (int) alt
{
  NoteHead *h;
  int i, k;
  float ndy;
  float nx = dx + pt.x;
  float ny = dy + pt.y;
  BOOL m = NO, inv;
  BOOL lk = gFlags.locked;
  i = gFlags.selend;
  h = [headlist objectAtIndex:i];
  if ([self posOfY: ny] == h->pos && ABS(nx - x) < 3.0) return NO;
  ndy = ny - h->myY;
  if (alt)
  {
    if (self != lastHit) return NO;
    m = [self moveHead: h : lk : ndy : sys];
    if (m) [self relinkHead: i];
  }
  else
  {
    m = YES;
    x = nx;
    y = ny;
    inv = [sys relinknote: self];
    k = [headlist count];
    while (k--) [self moveHead: [headlist objectAtIndex:k] : lk : ndy : sys];
  }
  if (m)
  {
    [self resetChord];
    [self recalc];
    [self markHangers];
    [self setVerses];
  }
  return m;
}


/* override hit so the selection point is on the notehead */

- (BOOL) hit: (NSPoint) pt
{
  int k;
  NoteHead *h;
  float dx, tol = nature[gFlags.size];
  k = [headlist count];
  while (k--)
  {
    h = [headlist objectAtIndex:k];
    if (h->side) dx = (time.stemup ? tol : -tol) * 2.0; else dx = 0.0;
    if (TOLFLOATEQ(pt.x, x + dx, tol) && TOLFLOATEQ(pt.y, h->myY, tol))
    {
      gFlags.selend = k;
      lastHit = self;
      return YES;
    }
  }
  return NO;
}

- (float) hitDistance: (NSPoint) pt
{
  int k;
  float d, dmin;
  NoteHead *h;
  float dx, tol = nature[gFlags.size];
  dmin = MAXFLOAT;
  k = [headlist count];
  while (k--)
  {
      h = [headlist objectAtIndex: k];
      if (h->side) dx = (time.stemup ? tol : -tol) * 2.0; else dx = 0.0;
      d = hypot(pt.x - (x + dx), pt.y - h->myY);
      if (d < dmin) dmin = d;
  }
  return dmin;
}


- (BOOL) hitBeamAt: (float *) px : (float *) py
{
    *px = x + stemdx[(int)gFlags.size][(int)gFlags.subtype][0][(int)time.body][(int)time.stemup];
  *py = y + time.stemlen;
  return YES;
}


- (float) stemXoff: (int) stype
{
    return stemdx[(int)gFlags.size][(int)gFlags.subtype][stype][time.body][time.stemup];
}

- (float) stemXoffLeft: (int) stype
{
    return stemdx[(int)gFlags.size][(int)gFlags.subtype][stype][time.body][time.stemup] -  0.5 * stemthicks[gFlags.size];
}


- (float) stemXoffRight: (int) stype
{
    return stemdx[(int)gFlags.size][(int)gFlags.subtype][stype][time.body][time.stemup] +  0.5 * stemthicks[gFlags.size];
}


- (float) stemYoff: (int) stype
{
  NoteHead *h = [headlist lastObject];
  if (h->side) return 0.0;
  if (h->type == 4) return 0.0;
  return stemdy[(int)gFlags.size][(int)gFlags.subtype][stype][time.body][time.stemup];
}


extern void unionCharBB(NSRect *b, float x, float y, int ch, NSFont *f);
extern float staffthick[3][3];

static void drawacc(float x, NoteHead *h, int ht, int sz, int m)
{
  NSRect r;
  float dx;
  NSFont *f = musicFont[(int)accifont[ht][(int)h->accidental]][sz];
  x += h->accidoff;
  if (h->editorial)
  {
    dx = 0.5 * nature[sz];
    x -= dx;
    r = NSZeroRect;
    unionCharBB(&r, x, h->myY, accidents[ht][(int)h->accidental], f);
    cenclosure(h->editorial - 1, r.origin.x - dx, r.origin.y - dx, r.origin.x + r.size.width + dx,
               r.origin.y + r.size.height + dx, staffthick[0][sz], 0, m);
  }
  drawCharacterInFont(x, h->myY, accidents[ht][(int)h->accidental], f, m);
}


/* Drawing a note or chord */

extern int modeinvis[5];

/* draw only the stem and flags (used for proximal chord's BB) Stemmed body checked by caller */

- drawStem: (int) m
{
  NoteHead *h;
  int sb, st, sz;
  float sl;
  sb = time.body;
  sz = gFlags.size;
  st = stype[gFlags.subtype];
  sl = time.stemlen;
  h = [headlist lastObject];
  drawstem(x, h->myY, sb, sl, sz, h->type, st, m);
  if (showslash && isGraced == 1) drawgrace(x, h->myY, sb, sl, sz, h->type, st, m);
  return self;
}

- drawMember: (int) m
{
    int k, bt, sz, su, sid = 1;
    int ksym, knum, midc;
    float hw=0.0, nx;
    NSMutableArray *nl;
    NoteHead *h;
    BOOL gotsinfo = NO;
    sz = gFlags.size;
    nl = headlist;
    su = time.stemup;
    k = [nl count];
    while (k--)
  {
    h = [nl objectAtIndex:k];
    bt = h->type;
    if (bt == 6)
    {
      if (!gotsinfo)
      {
        [self getKeyInfo: &ksym : &knum : &midc];
        gotsinfo = YES;
      }
      sid = getShapeID(h->pos, ksym, knum, midc);
    }
    hw = halfwidth[sz][bt][time.body];
    nx = x;
    if (centhead[bt]) nx -= hw;
    if (h->side) nx += hw * offside[su];
    drawhead(nx, h->myY, bt, time.body, sid, su, sz, m);
    if (h->accidental && h->accidoff < 0.0) drawacc(x, h, bt, sz, m);
    if (time.dot) drawnotedot(sz, x + dotdx, h->myY, h->dotoff, [h->myNote getSpacing], bt, time.dot, 0, m);
  }
    [self drawLedgerAt: hw size: sz mode: m];
    return self;
}


- drawMode: (int) m
{
    struct timeinfo *t;
    NSMutableArray *nl;
    NoteHead *h=nil, *q;
    int k, nlk, body, bt=0, sb, sz, st, b, sid = 0;
    int ksym, knum, midc;
    float nx, dy, hw=0.0;
    BOOL stemup,gotsinfo = NO;
    
    if ([self myChordGroup] != nil) return [self drawMember: m];
    t = &time;
    sz = gFlags.size;
    st = stype[gFlags.subtype];
    b = [self isBeamed];
    nl = headlist;
    q = [nl lastObject];
    body = t->body;
    nlk = [nl count];
    stemup = t->stemup;
    k = nlk;
    if (k == 1)
    {
	h = q;
	bt = h->type;
	if (bt == 6)
	{
	    [self getKeyInfo: &ksym : &knum : &midc];
	    sid = getShapeID(h->pos, ksym, knum, midc);
	}
	hw = halfwidth[sz][bt][body];
	drawnote(sz, hw, x, h->myY, body, bt, st, sid, b, t->stemlen, t->nostem, (showslash && isGraced == 1), m);
	if (h->accidental && h->accidoff < 0.0) drawacc(x, h, bt, sz, m);
	if (t->dot) drawnotedot(sz, x + dotdx, h->myY, h->dotoff, [h->myNote getSpacing], bt, t->dot, 0, m);
    }
    else
    {
	while (k--)
	{
	    h = [nl objectAtIndex:k];
	    bt = h->type;
	    if (bt == 6)
	    {
		if (!gotsinfo)
		{
		    [self getKeyInfo: &ksym : &knum : &midc];
		    gotsinfo = YES;
		}
		sid = getShapeID(h->pos, ksym, knum, midc);
	    }
	    hw = halfwidth[sz][bt][body];
	    nx = x;
	    if (centhead[bt]) nx -= hw;
	    if (h->side) nx += hw * offside[(int)stemup];
	    drawhead(nx, h->myY, bt, body, sid, stemup, sz, m);
	    if (h->accidental && h->accidoff < 0.0) drawacc(x, h, bt, sz, m);
	    if (t->dot) drawnotedot(sz, x + dotdx, h->myY, h->dotoff, [h->myNote getSpacing], bt, t->dot, 0, m);
	}
	/* Note: h will now be [nl objectAt: 0], with valid bt, f, hw */
	if (hasstem[body] && (!b || nlk > 1))
	{
	    dy = q->myY - h->myY;
	    if (b) sb = 5;
	    else
	    {
		dy += t->stemlen;
		sb = body;
	    }
	    drawstem(x, h->myY, sb, dy, sz, bt, st, m);
	    if (showslash && isGraced == 1) drawgrace(x, q->myY, sb, t->stemlen, sz, bt, st, m);
	}
    }
    [self drawLedgerAt: hw size: sz mode: m];
    return self;
}


/* Archiving */

extern void readTimeData(NSCoder *s, struct timeinfo *t); /*sb; changed from NSArchiver after conversion */
extern void writeTimeData(NSCoder *s, struct timeinfo *t); /*sb; changed from NSArchiver after conversion */

struct oldflags	/* from old format */
{
  unsigned int accident : 3;
  unsigned int edaccid : 3;
};


/* update old format noteheads */

- readOldFormats: (NSCoder *) s : (int) v /*sb: was NSArchiver after conversion. Changed to retain compatability with initWithCoder */
{
  struct oldtimeinfo t;
  struct oldflags flags;
  struct timeinfo figtime;
  float sl;
  NoteHead *h;
  char b1, b2, b3, b4, b5, b6, b7, acc=0, edacc;
  if (v == 0)
  {
    [s decodeValuesOfObjCTypes:"ssf", &flags, &t, &sl];
    acc = flags.accident;
    edacc = flags.edaccid;
    figtime.body = t.body;
    figtime.dot = t.dot;
    figtime.tight = 0;
    figtime.stemlen = sl;
    figtime.stemup = (sl < 0);
    figtime.stemfix = 0;
    headlist = nil;
  }
  else if (v == 1)
  {
    [s decodeValuesOfObjCTypes:"cc", &b1, &b2];
    acc = b1;
    edacc = b2;
    [s decodeValuesOfObjCTypes:"cccf", &b1, &b2, &b3, &sl];
    figtime.body = b1;
    figtime.dot = b2;
    figtime.tight = b3;
    figtime.stemlen = sl;
    figtime.stemup = (sl < 0);
    figtime.stemfix = 0;
    headlist = nil;
  }
  else if (v == 2)
  {
    [s decodeValuesOfObjCTypes:"cc", &b1, &b2];
    acc = b1;
    edacc = b2;
    [s decodeValuesOfObjCTypes:"cccccf@", &b1, &b2, &b3, &sl, &headlist];
    figtime.body = b1;
    figtime.dot = b2;
    figtime.tight = b3;
    figtime.stemlen = sl;
    figtime.stemup = (sl < 0);
    figtime.stemfix = 0;
  }
  else if (v == 3)
  {
    [s decodeValuesOfObjCTypes:"cccccccf@", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &sl, &headlist];
    acc = b1;
    edacc = b2;
    figtime.body = b3;
    figtime.dot = b4;
    figtime.tight = b5;
    figtime.stemup = b6;
    figtime.stemfix = b7;
    figtime.stemlen = sl;
  }
  /* convert to new format if necessary.  Should be OK because super has been read. */
  if (figtime.body) time = figtime;
  if (headlist == nil)
  {
    float hw;
    int sz, bt, st;
    NSFont *f;
    struct timeinfo *ti;
    sz = gFlags.size;
    bt = gFlags.subtype;
    st = stype[gFlags.subtype];
    headlist = [[NSMutableArray alloc] init];
    h = [[NoteHead alloc] init];
    h->type = bt;
    h->pos = p;
    h->accidental = acc;
    h->myY = y;
    h->myNote = self;
    ti = (!(gFlags.selected) && (figtime.body != 0)) ? &figtime : &time;
    f = musicFont[headfont[bt][ti->body]][sz];
    hw = halfwidth[sz][bt][ti->body];
    h->accidoff = -hw - charFGW(f, accidents[bt][(int)acc]) - 2.0;
    h->dotoff = (p & 1) ? 0 : -1;
    dotdx = getdotx(sz, bt, 0, ti->body, [self isBeamed], ti->stemup);
    [(NSMutableArray *)headlist addObject: h];
  }
  return self;
}

extern void readTimeData2(NSCoder *s, struct timeinfo *t); /*sb; changed from NSArchiver after conversion */

- (id)initWithCoder:(NSCoder *)aDecoder
{
  struct timeinfo figtime;
  int v = [aDecoder versionForClassName:@"GNote"];
  [super initWithCoder:aDecoder];
  instrument = 0;
  showslash = 0;
  if (v == 9)
  {
    headlist = [[aDecoder decodeObject] retain];
    [aDecoder decodeValuesOfObjCTypes:"fcc", &dotdx, &instrument, &showslash];
  }
  else if (v == 8)
  {
    headlist = [[aDecoder decodeObject] retain];
    [aDecoder decodeValuesOfObjCTypes:"fc", &dotdx, &instrument];
  }
  else if (v == 7)
  {
    headlist = [[aDecoder decodeObject] retain];
    [aDecoder decodeValuesOfObjCTypes:"fc", &dotdx, &instrument];
    if (instrument) ++instrument;
  }
  else if (v == 6)
  {
    readTimeData2(aDecoder, &figtime);
    if (figtime.body) time = figtime;
    headlist = [[aDecoder decodeObject] retain];
    [aDecoder decodeValuesOfObjCTypes:"fc", &dotdx, &instrument];
    if (instrument) ++instrument;
  }
  else if (v == 5)
  {
    readTimeData2(aDecoder, &figtime);
    if (figtime.body) time = figtime;
    headlist = [[aDecoder decodeObject] retain];
    [aDecoder decodeValuesOfObjCTypes:"f", &dotdx];
  }
  else if (v == 4)
  {
    readTimeData2(aDecoder, &figtime);
    if (figtime.body) time = figtime;
    headlist = [[aDecoder decodeObject] retain];
    [self resetDots];
  }
  else [self readOldFormats: aDecoder : v];

  { /*sb: this section came from the awake method */
    NoteHead *h;
    int k = [headlist count];
    while (k--)
    {
      h = [headlist objectAtIndex:k];
      if (TYPEOF(h->myNote) != NOTE) h->myNote = self;
    }
//    return [super awake];
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:headlist];
  [aCoder encodeValuesOfObjCTypes:"fcc", &dotdx, &instrument, &showslash];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setObject:headlist forKey:@"headlist"];
    [aCoder setFloat:dotdx forKey:@"dotdx"];
    [aCoder setInteger:instrument forKey:@"inst"];
    [aCoder setInteger:showslash forKey:@"slash"];
}


@end
