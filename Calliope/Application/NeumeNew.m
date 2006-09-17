/* $Id$ */
#import "NeumeNew.h"
#import "NeumeInspector.h"
#import "KeySig.h"
#import "GraphicView.h"
#import "Staff.h"
#import "System.h"
#import "Neume.h"
#import <AppKit/NSGraphics.h>
//#import "draw.h"  // This was generated by the pswrap utility from draw.psw.
#import "DrawingFunctions.h"
#import "muxlow.h"

@implementation NeumeNew

#define HEPIOFF 2		/* offset of h. episema from centre of space */

float stemWidth[3] = {1.0, 0.75, 0.5};	/* neume stem thickness */
float stemHWidth[3] = {0.5, 0.375, 0.25}; /* half of above */
float porrThick[3] = {2.0, 1.5, 1.0};	/* half-thickness of a porrectus */
float stemLength[3] = {15.0, 11.25, 7.5};/* length of stem */


static NeumeNew *proto;


+ (void)initialize
{
  if (self == [NeumeNew class])
  {
      (void)[NeumeNew setVersion: 1];		/* class version, see read: */
    proto = [[self alloc] init];
  }
  return;
}


+ myInspector
{
  return [NeumeInspector class];
}


+ myPrototype
{
  return proto;
}


- init
{
  [super init];
  gFlags.type = NEUMENEW;
  nFlags.dot = 0;
  nFlags.hepisema = 0;
  nFlags.vepisema = 0;
  nFlags.molle = 0;
  nFlags.num = 0;
  time.body = 4;
  time.dot = 0;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- upgradeFrom: (Neume *) n
{
  NSMutableArray *vl;
  int vk;
  Verse *v;
  nFlags.dot = n->nFlags.dot;
  nFlags.vepisema = n->nFlags.vepisema;
  nFlags.hepisema = n->nFlags.hepisema;
  nFlags.quilisma = n->nFlags.quilisma;
  nFlags.molle = n->nFlags.molle;
  nFlags.num = n->nFlags.num;
  nFlags.halfSize = 0;
  p2 = n->p2;
  p3 = n->p3;
  time.body = 4;
  time.dot = 0;
  time.tight = 0;
  time.stemup = 0;
  time.stemfix = 0;
  time.nostem = 0;
  time.stemlen = 0;
  time.factor = 1.0;
  x = n->x;
  y = n->y;
  p = n->p;
  verses = vl = n->verses;
  vk = [vl count];
  while (vk--)
  {
    v = [vl objectAtIndex:vk];
    v->note = self;
  }
  mystaff = n->mystaff;
  bounds = n->bounds;
  gFlags = n->gFlags;
  gFlags.type = NEUMENEW;
  return self;
}


/* initialise a neume to a standard pose */

static char neumepos[10][2] =
{
  {0, 0},
  {0, 0},
  {0, 0},
  {-2, 0},
  {1, 0},
  {-2, 0},
  {2, 0},
  {2, 0},
  {-1, 0},
  {0, 0}
};

static char neumenum[10] = {1, 1, -1, 2, 2, 2, 2, 3, 3, 1};

- setNeume
{
  p2 = neumepos[gFlags.subtype][0];
  p3 = neumepos[gFlags.subtype][1];
  return self;
}

- (float)verseOrigin
{
  return 0.5 * charFGW(musicFont[0][gFlags.size], CH_punctsqu);
}

/* initialise the prototype neume */

- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  [super proto: v : pt : sp : sys : g : i];
  if (TYPEOF(sp) == STAFF)
  {
    p = [sp findPos: pt.y];
    y = [sp yOfPos: p];
  }
  gFlags.subtype = i;
  [self setNeume];
  return self;
}


- reShape
{
  [self recalc];
  [self setOwnHangers];
  [self setVerses];
  return self;
}


- (BOOL) reCache: (float) sy : (int) ss
{
  float t;
  t = sy + ss * p;
  if (t == y) return NO;
  y = t;
  return YES;
}


/* return ticks for a neume (number of components and dots * body) */

- (float) noteEval: (BOOL) f
{
  int i, b;
  float r;
  float v = tickval(time.body, time.dot);
  int k = neumenum[gFlags.subtype];
  if (k < 0) k = nFlags.num + 1;
  r = k * v;
  b = 1;
  for (i = 0; i < k; i++)
  {
    if (nFlags.dot & b) r += v;
    b <<= 1;
  }
  return r;
}


/* 
  pass back the pos and dot and whether molle'd of ith component
  of neume (origin 0).  Return whether exists.
*/

- (BOOL) getPos: (int) i : (int *) pos : (int *) d : (int *) m : (float *) t
{
  int k;
  *t = tickval(time.body, time.dot);
  if (gFlags.subtype == PUNCTINC)
  {
    k = nFlags.num;
    if (i > k) return NO;
    *pos = p + i;
    *d = nFlags.dot & (1 << i);
    *m = nFlags.molle & (1 << i);
    return YES;
  }
  if (i >= neumenum[gFlags.subtype]) return NO;
  if (i == 0) *pos = p;
  else if (i == 1) *pos = p + p2;
  else if (i == 2) *pos = p + p3;
  *d = nFlags.dot & (1 << i);
  *m = nFlags.molle & (1 << i);
  return YES;
}


extern id lastHit;

- (BOOL) performKey: (int) c
{
  BOOL r = NO;
  switch(c)
  {
    case '.':
      nFlags.dot ^= (1 << gFlags.selend);
      r = YES;
      break;
    case '@':
      nFlags.molle ^= (1 << gFlags.selend);
      r = YES;
      break;
    case '~':
      nFlags.quilisma ^= (1 << gFlags.selend);
      r = YES;
      break;
    case '-':
      nFlags.hepisema ^= (1 << gFlags.selend);
      r = YES;
      break;
    case '|':
      nFlags.vepisema ^= (1 << gFlags.selend);
      r = YES;
      break;
  }
  if (r)
  {
    [self recalc];
    [self setOwnHangers];
    return YES;
  }
  else return [super performKey: c];
}


- (BOOL) hit: (NSPoint) pt;
{
  int i;
  NSRect b = bounds;
  float w, px;
  b = NSInsetRect(b , -2.0 , -2.0);
  if (NSPointInRect(pt , b))
  {
    switch(gFlags.subtype)
    {
      case PUNCTA:
      case VIRGA:
      case MOLLE:
      case PUNCTINC:
        gFlags.selend = 0;
	break;
      case TORCULUS:
        w = b.size.width / 3.0;
        px = pt.x - b.origin.x;
        gFlags.selend = floor((double) px / w);
	break;
      case PODATUS:
      case EPIPHONUS:
        w = b.size.height / 2.0;
        px = pt.y - b.origin.y;
        gFlags.selend = floor((double) px / w);
	gFlags.selend = !gFlags.selend;
        break;
      case CLIVIS:
      case CEPHALICUS:
        w = b.size.height / 2.0;
        px = pt.y - b.origin.y;
        gFlags.selend = floor((double) px / w);
	break;
      case PORRECTUS:
        w = b.size.width / 2.0;
        px = pt.x - b.origin.x;
        i = floor((double) px / w);
	if (i != 0)
	{
          w = b.size.height / 2.0;
          px = pt.y - b.origin.y;
	  i = floor((double) px / w);
	  i = (!i) + 1;
	}
	gFlags.selend = i;
	break;
    }
    return YES;
  }
  gFlags.selend = 0;
  return NO;
}


/* move a neume.  ALT-move individual notes */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : (System *) sys : (int) alt
{
  float nx = dx + pt.x;
  float ny = dy + pt.y;
  BOOL m = NO, inv;
  int op;
  if (alt)
  {
    if (TYPEOF(mystaff) != STAFF) return NO;
    if (ABS(ny - y) > 2.0) switch(gFlags.selend)
    {
      case 0:
	op = p;
        p = [mystaff findPos: ny];
        y = [mystaff yOfPos: p];
	m = (op != p);
	p2 += op - p;
	p3 += op - p;
        break;
      case 1:
	op = [mystaff findPos: ny] - p;
	m = (p2 != op);
	p2 = op;
        break;
      case 2:
	op = [mystaff findPos: ny] - p;
	m = (p3 != op);
	p3 = op;
        break;
    }
  }
  else
  {
    if (ABS(ny - y) > 2 || ABS(nx - x) > 3)
    {
      m = YES;
      x = nx;
      y = ny;
      inv = [sys relinknote: self];
      if (TYPEOF(mystaff) == STAFF)
      {
        p = [mystaff findPos: y];
        y = [mystaff yOfPos: p];
      }
      else p = 0;
    }
  }
  if (m)
  {
    [self recalc];
    [self markHangers];
    [self setVerses];
  }
  return m;
}


/* return y-value for horizontal episema */

- (float) hepiy: (int) ip : (int) hu
{
  int hy, pos;
  if (ip & 1)
  {
    pos = (hu > 0) ? ip - 2 : ip + 2;
    return([self yOfPos: pos]);
  }
  else
  {
    pos = (hu > 0) ? ip - 1 : ip + 1;
    hy = [self yOfPos: pos];
    return ((hu > 0) ? hy - HEPIOFF : hy + HEPIOFF);
  }
}


/* 
  Deal with most combinations individually.  c is the character shape,
  n is which neume of a group (1, 2, 4, 8), p is the position,
  du, vu, hu place to dot, vepisema and hepisema.
  0 means don't (done by caller); 1 means up, -1 means down.
  abs(du) is the x-value of dot (except offset)
  mu gives x-coord for molle.
*/

static void punctadot(float du, int p, float y, float s, NSFont *f, int mode)
{
  float x, dy;
  if (du > 0)
  {
    x = du;
    dy = -s;
  }
  else
  {
    x = -du;
    dy = s;
  }
  if (!(p & 1)) y += dy;
  drawCharacterInFont(x + 1.5 * charFGW(f,CH_punctsqu), y, CH_dot, f, mode);
}


- cpuncta: (float) px : (float) py : (unsigned char) c : (int) n : (int) ip : (float) du : (int) vu : (int) hu : (float) mu : (NSFont *) f : (int) sz : (int) mode;
{
  int ss;
  float hw;
  if (nFlags.quilisma & n) c = CH_quilisma;
  hw = charhalfFGW(f, c);
  drawCharacterInFont(px, py, c, f, mode);
  ss = getSpacing(mystaff);
  if (TYPEOF(mystaff) == STAFF)
  {
    drawledge(px + hw, [self yOfPos: 0], hw, 0, ip, [self getLines], ss, mode);
  }
  if (mu && nFlags.molle & n) drawCharacterInFont(mu, py, CH_molle, f, mode);
  if (du && nFlags.dot & n) punctadot(du, ip, [self yOfPos: ip], ss, f, mode);
  if (vu && nFlags.vepisema & n)
  {
    if (vu < 0)
    {
      py = [self yOfPos: ip + 1] + 1;
      cline(px + hw, py, px + hw, py + 5, stemWidth[sz], mode);
    }
    else
    {
      py = [self  yOfPos: ip - 1] - 1;
      cline(px + hw, py, px + hw, py - 5, stemWidth[sz], mode);
    }
  }
  if (hu && nFlags.hepisema & n)
  {
    py = [self hepiy: ip : hu];
    cline(px, py, px + 2.0 * hw, py, stemWidth[sz], mode);
  }
  return self;
}


- drawMode: (int) mode
{
    float fw=0,fw2=0, pw, cx, cy, mx, x0, x1, y1, x2, y2, y3, hx1, hx2;
  int i, j, ip, sz;
  NSFont *f, *f2 = nil;
  unsigned char ch;
  hx1 = hx2 = 0;
  sz = gFlags.size;
  f = musicFont[0][sz];
  fw = charFGW(f, CH_punctsqu);
  if (nFlags.halfSize) {
      f2 = [NSFont fontWithName:[f fontName] size: [f pointSize]/2];
      fw2 = charFGW(f2, CH_punctsqu);
  }
  cx = x;
  cy = y;
  mx = cx - charFGW(f, CH_molle) - 2.0;
  switch(gFlags.subtype)
  {
    case PUNCTA: /* square puncta */
      [self cpuncta: cx : cy : CH_punctsqu : 1 : p : cx : -1 : 1 : mx : f : sz : mode];
      break;
    case VIRGA: /* virga */
      [self cpuncta: cx : cy : CH_punctsqu : 1 : p : cx : 1 : 1 : mx : f : sz : mode];
      x1 = cx + fw - stemHWidth[sz];
      cline(x1, cy, x1, cy + stemLength[sz], stemWidth[sz], mode);
      break;
    case PUNCTINC: /* puncta inclinata */
      x1 = cx;
      j = 1;
      pw = charFGW(f, CH_punctdia);
      for (i = 0; i <= nFlags.num; i++)
      {
        ip = p + i;
        cy = [self yOfPos: ip];
        [self cpuncta: x1 : cy : CH_punctdia : j : ip : x1 : -1 : 0 : mx : f : sz : mode];
        if (nFlags.hepisema & j) if (hx1) hx2 = x1; else hx1 = hx2 = x1;
        x1 += pw;
        j <<= 1;
      }
      if (nFlags.hepisema)
      {
        y1 = [self hepiy: p : 1];
        cline(hx1, y1, hx2 + fw, y1, stemWidth[sz], mode);
      }
      break;
    case PODATUS: /* podatus */
      i = (ABS(p2) <= 1);
      ch = (i) ? CH_podatusp : CH_podatus;
      [self cpuncta: cx : cy : ch : 1 : p : -cx : -1 : -1 : mx : f : sz : mode];
      ip = p + p2;
      y1 = [self yOfPos: ip];
      ch = (i) ? CH_punctsqup : CH_punctsqu;
        if (nFlags.halfSize) {
          [self cpuncta: cx + (fw - fw2) : y1 : ch : 2 : ip : cx : 1 : 1 : mx : f2 : sz : mode];
          }
        else {
          [self cpuncta: cx : y1 : ch : 2 : ip : cx : 1 : 1 : mx : f : sz : mode];
          }
      x1 = cx + fw - stemHWidth[sz];
      cline(x1, cy, x1, y1, stemWidth[sz], mode);
      break;
    case CLIVIS: /* clivis */
      if (nFlags.hepisema & 1) hx1 = hx2 = cx;
      x0 = cx + stemHWidth[sz];
      cline(x0, cy, x0, cy + stemLength[sz], stemWidth[sz], mode);
      ip = p + p2;
      y1 = [self yOfPos: ip];
      x1 = cx + fw;
      [self cpuncta: cx : cy : CH_punctsqu : 1 : p : x1 : 1 : 0 : mx : f : sz : mode];
        if (nFlags.halfSize) {
          [self cpuncta: x1 : y1 : CH_punctsqu : 2 : ip : -x1 : -1 : 0 : mx : f2 : sz : mode];
          }
        else [self cpuncta: x1 : y1 : CH_punctsqu : 2 : ip : -x1 : -1 : 0 : mx : f : sz : mode];
      if (nFlags.hepisema & 2) if (hx1) hx2 = x1; else hx1 = hx2 = x1;
      x0 = x1 - stemHWidth[sz];
      cline(x0, cy, x0, y1, stemWidth[sz], mode);
      if (nFlags.hepisema)
      {
        y1 = [self hepiy: p : 1];
        cline(hx1, y1, hx2 + fw, y1, stemWidth[sz], mode);
      }
      break;
    case EPIPHONUS: /* epiphonus */
      [self cpuncta: cx : cy : CH_epiph1 : 1 : p : -cx : -1 : -1 : mx : f : sz : mode];
      ip = p + p2;
      y1 = [self yOfPos: ip];
      x2 = cx + charFGW(f, CH_epiph1);
      x1 = x2 - stemHWidth[sz];
      cline(x1, cy, x1, y1, stemWidth[sz], mode);
      [self cpuncta: x2 : y1 : CH_epiph2 : 2 : ip : x2 : 1 : 1 : mx : f : sz : mode];
      break;
    case CEPHALICUS: /* cephalicus */
      [self cpuncta: cx : cy : CH_cepha1 : 1 : p : cx : 1 : 1 : mx : f : sz : mode];
      x0 = cx + stemHWidth[sz];
      cline(x0, cy, x0, cy + stemLength[sz], stemWidth[sz], mode);
      ip = p + p2;
      y1 = [self yOfPos: ip];
      x2 = cx + charFGW(f, CH_cepha1);
      x1 = x2 - stemHWidth[sz];
      cline(x1, cy, x1, y1, stemWidth[sz], mode);
      [self cpuncta: x2 : y1 : CH_cepha2 : 2 : ip : -cx : -1 : -1 : mx : f : sz : mode];
      break;
    case PORRECTUS: /* porrectus */
      x0 = cx + stemHWidth[sz];
      cline(x0, cy, x0, cy + stemLength[sz], stemWidth[sz], mode);
      x1 = cx + 2.0 * fw;
      ip = p + p2;
      y1 = [self yOfPos: ip];
      y3 = y1 - ((y1 - cy) / ((p2 - p3 == 1) ? 8.0 : 4.0));
      x0 = porrThick[sz];
      cslant(cx, cy - x0 - 1.0, x1, y3 - x0, (x0 * 2.0) + 1.0, mode);
      y2 = y1;
      cslant(x1, y3 - x0, x1 + fw, y1 - x0, (x0 * 2.0) + 1, mode);
      ip = p + p3;
      y1 = [self yOfPos: ip];
      ch = (p2 - p3 == 1) ? CH_punctsqup : CH_punctsqu;
        if (nFlags.halfSize) {
          [self cpuncta: x1 + (fw-fw2) : y1 : ch : 4 : ip : x1 : 1 : 1 : mx : f2 : sz : mode];
          }
        else [self cpuncta: x1 : y1 : ch : 4 : ip : x1 : 1 : 1 : mx : f : sz : mode];
      x1 += fw - stemHWidth[sz];
      cline(x1, y2, x1, y1, stemWidth[sz], mode);
      break;
    case MOLLE: /* molle */
      drawCharacterInFont(cx, cy, CH_molle, f, mode);
      break;
    case TORCULUS: /* torculus */
      [self cpuncta: cx : cy : CH_punctsqu : 1 : p : -cx : -1 : 0 : mx : f : sz : mode];
      if (nFlags.hepisema & 1) hx1 = hx2 = cx;
      ip = p + p2;
      y1 = [self yOfPos: ip];
      x1 = cx + fw;
      [self cpuncta: x1 : y1 : CH_punctsqu : 2 : ip : x1 : 1 : 0 : mx : f : sz : mode];
      if (nFlags.hepisema & 2) if (hx1) hx2 = x1; else hx1 = hx2 = x1;
      cline(cx + fw - stemWidth[sz], cy, x1, y1, stemWidth[sz], mode);
      ip = p + p3;
      y2 = [self yOfPos: ip];
      x2 = cx + 2.0 * fw;
        if (nFlags.halfSize) {
          [self cpuncta: x2 : y2 : CH_punctsqu : 4 : ip : x2 : -1 : 0 : mx : f2 : sz : mode];
          }
        else [self cpuncta: x2 : y2 : CH_punctsqu : 4 : ip : x2 : -1 : 0 : mx : f : sz : mode];
      if (nFlags.hepisema & 4) if (hx1) hx2 = x2; else hx1 = hx2 = x2;
      cline(x1 + fw - stemWidth[sz], y1, x2, y2, stemWidth[sz], mode);
      if (nFlags.hepisema)
      {
        y1 = [self hepiy: p + p2 : 1];
        cline(hx1, y1, hx2 + fw, y1, stemWidth[sz], mode);
      }
      break;
  }
  return self;
}


/* archiving */

- (id)initWithCoder:(NSCoder *)aDecoder
{
    char b1, b2, b3, b4, b5, b6, b7;
    int v;
    [super initWithCoder:aDecoder];
    v = [aDecoder versionForClassName:@"NeumeNew"];
    if (v == 0) {
        [aDecoder decodeValuesOfObjCTypes:"cccccccc", &p2, &p3, &b1, &b2, &b3, &b4, &b5, &b6];
        nFlags.halfSize = 0;
    }
    else {
        [aDecoder decodeValuesOfObjCTypes:"cccccccc", &p2, &p3, &b1, &b2, &b3, &b4, &b5, &b6, &b7];
        nFlags.halfSize = b7;
    }
    nFlags.dot = b1;
    nFlags.vepisema = b2;
    nFlags.hepisema = b3;
    nFlags.quilisma = b4;
    nFlags.molle = b5;
    nFlags.num = b6;
    gFlags.type = NEUMENEW;  /* owing to mistake in update function */
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b1, b2, b3, b4, b5, b6, b7;
  [super encodeWithCoder:aCoder];
  b1 = nFlags.dot;
  b2 = nFlags.vepisema;
  b3 = nFlags.hepisema;
  b4 = nFlags.quilisma;
  b5 = nFlags.molle;
  b6 = nFlags.num;
  b7 = nFlags.halfSize;
  [aCoder encodeValuesOfObjCTypes:"ccccccccc", &p2, &p3, &b1, &b2, &b3, &b4, &b5, &b6, &b7];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:p2 forKey:@"p2"];
    [aCoder setInteger:p3 forKey:@"p3"];
    [aCoder setInteger:nFlags.dot forKey:@"dot"];
    [aCoder setInteger:nFlags.vepisema forKey:@"vepisema"];
    [aCoder setInteger:nFlags.hepisema forKey:@"hepisema"];
    [aCoder setInteger:nFlags.quilisma forKey:@"quilisma"];
    [aCoder setInteger:nFlags.molle forKey:@"molle"];
    [aCoder setInteger:nFlags.num forKey:@"num"];
    [aCoder setInteger:nFlags.halfSize forKey:@"halfSize"];
}


@end
