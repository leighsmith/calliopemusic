/* $Id$ */
#import "KeySig.h"
#import "KeyInspector.h"
#import "GraphicView.h"
#import "Clef.h"
#import "Staff.h"
#import "StaffObj.h"
#import "System.h"
#import "DrawingFunctions.h"
#import "muxlow.h"

/*
  format of keystr entries: b0-2: symbol, b3 octaved
  symbol: 0=blank, 1=flat, 2=sharp, 3=natural.
  The 'key order' is always given by symbol, so cancellation sigs
  (subtype = 3) look at the symbol to tell order.
*/

@implementation KeySig:StaffObj

char symorder[2][7] =
{
  {6, 2, 5, 1, 4, 0, 3},
  {3, 0, 4, 1, 5, 2, 6}
};

static short keypos[2][7] =
{
  {0, -1, -2,  4,  3, 2, 1},
  {0, -1, -2, -3, -4, 2, 1}
};

char nthdeg[2][7] = 
{
  {6, 4, 2, 7, 5, 3, 1},
  {2, 4, 6, 1, 3, 5, 7}
};


static unsigned char keychar[4][3] =
{
  {0, SF_flat, SF_sharp},
  {0, CH_flat, CH_sharp},
  {0, CH_molle, CH_molle},
  {0, SF_natural, SF_natural}
};

/* keytonmaj/min[sym][keynum] gives the tonic (origin C) */

char keytonmaj[4][8] =
{
  {0, 0, 0, 0, 0, 0, 0, 0},
  {0, 3, 6, 2, 5, 1, 4, 0},
  {0, 4, 1, 5, 2, 6, 3, 0},
  {0, 0, 0, 0, 0, 0, 0, 0}
};

char keytonmin[4][8] =
{
  {0, 0, 0, 0, 0, 0, 0, 0},
  {5, 1, 4, 0, 3, 6, 2, 5},
  {5, 2, 6, 3, 0, 4, 1, 5},
  {0, 0, 0, 0, 0, 0, 0, 0}
};

static KeySig *proto;


/* dumb test if a key string represents a conventional signature */

char convstr[14][7];

BOOL stricteq(char *s, char *t)
{
  int i = 7;
  while (i--) if (s[i] != t[i]) return NO;
  return YES;
}


BOOL isConventional(char *s)
{
  int i = 14;
  while (i--) if (stricteq(s, convstr[i])) return YES;
  return NO;
}


int keySymCount(char *s)
{
  int i = 7, k = 0;
  while (i--) if (s[i] & 03) ++k;
  return k;
}


int keySymValue(char *s)
{
  int i = 7, v;
  while (i--)
  {
    v = s[i] & 03;
    if (v) return v;
  }
  return 3;
}


+ (void)initialize
{
  int i, j, k;
  if (self == [KeySig class])
  {
      (void)[KeySig setVersion: 4];		/* class version, see read: NB version 5! */
    proto = [[self alloc] init];
    for (i = 0; i < 7; i++)
    {
      k = i + 1;
      for (j = 0; j < 7; j++)
      {
        convstr[i][j] = (nthdeg[0][j] <= k) ? 1 : 0;
	convstr[i+7][j] = (nthdeg[1][j] <= k) ? 2 : 0;
      }
    }
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [KeyInspector class];
}


- init
{
  int i;
  [super init];
  gFlags.type = KEY;
  gFlags.subtype = 3;
  for (i = 0; i < 7; i++) keystr[i] = 0;
  keystr[6] = 1;
  return self;
}


- (void)dealloc
{
  { [super dealloc]; return; };
}


- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) k
{
  int i;
  [super proto: v : pt : sp : sys : g : k];
  gFlags.subtype = proto->gFlags.subtype;
  for (i = 0; i < 7; i++) keystr[i] = proto->keystr[i];
  return self;
}


/* return pos relative to C for use as a handle */

- (int) keyPos
{
  if ((keystr[7] & 03) == 1) return 1;
  if ((keystr[4] & 03) == 2) return -3;
  return 0;
}


- (int) defaultPos
{
  int ck, cf, koff;
  Clef *cl;
  if (TYPEOF(mystaff) == STAFF && (cl = [mystaff findClef: self]) != nil)
  {
    ck = cl->keycentre;
    cf = cl->gFlags.subtype;
    koff = cl->p - [cl defaultPos];
  }
  else
  {
    ck = 2;
    cf = 0;
    koff = 0;
  }
  return clefcpos[(int)clefuid[ck][cf]] + koff + [self keyPos];
}


- newFrom
{
  int i;
  KeySig *q = [[KeySig alloc] init];
  q->gFlags.subtype = gFlags.subtype;
  q->gFlags.size = gFlags.size;
  q->x = x;
  q->p = p;
  for (i = 0; i < 7; i++) q->keystr[i] = keystr[i];
  return q;
}


/*
  Set the given keysig string.  Also given keynumber, whether cancellation.
  Elements of keysig string are same as accidentals code.
*/


/* ip takes into account the pos offset */

- getKeyString: (char *) key
{
  int i, a;
  BOOL can = (gFlags.subtype == 3);
  for (i = 0; i < 7; i++)
  {
    a = keystr[i] & 03;
    if (a) key[i] = can ? 3 : a;
    else key[i] = 0;
  }
  return self;
}


- (BOOL) getXY: (float *) fx : (float *) fy
{
  *fx = x;
  *fy = [self yOfPos: [self defaultPos] + p];
  return YES;
}


/*
  set string contents to conventional format:
  n s's in order ord.  ord = 0=flats, 1=sharps.
*/


- setKeyString: (int) n : (int) s : (int) ord
{
  int i;
  for (i = 0; i < 7; i++) keystr[i] = 0;
  for (i = 0; i < n; i++) keystr[(int)symorder[ord][i]] = s;
  return self;
}


/* queries:  only work for conventional signatures */

- (int) myKeyNumber
{
  return keySymCount(keystr);
}


- (int) myKeySymbol
{
  return keySymValue(keystr);
}

/* give normalised (s: 0=flat, 1=sharp, n: keynum) info */

int normkey[4] = {-1, 0, 1, -1};

- myKeyInfo: (int *) s : (int *) n
{
  int sym;
  sym = normkey[keySymValue(keystr)];
  if (sym < 0)
  {
    *s = 0;
    *n = 0;
  }
  else
  {
    *s = sym;
    *n = keySymCount(keystr);
  }
  return self;
}


/*
  conversion to old format used by some routines
*/

- (int) oldKeyNum
{
  int i = keySymCount(keystr);
  if (keySymValue(keystr) == 1) i = -i;
  return i;
}


- (BOOL) performKey: (int) c
{
  int i, s;
  BOOL r = NO;
  if (isdigitchar(c))
  {
    i = c - '0';
    s = [self myKeySymbol];
    [self setKeyString: i : s : s - 1];
    r = YES;
  }
  else if (c == '@')
  {
      [self setKeyString: [self myKeyNumber]: 1 : 0];
    if (gFlags.subtype == 3) gFlags.subtype = 0;
    r = YES;
  }
  else if (c == '#')
  {
      [self setKeyString: [self myKeyNumber]: 2 : 1];
    if (gFlags.subtype == 3) gFlags.subtype = 0;
    r = YES;
  }
  else if (c == '!')
  {
    s = [self myKeySymbol];
    if (s == 3) s = 2;
    [self setKeyString: [self myKeyNumber]: s : s - 1];
    gFlags.subtype = 3;
    r = YES;
  }
  if (r)
  {
    [self reShape];
    return YES;
  }
  else return [super performKey: c];
}


/* Caller does the setHangers that matches the markHangers here */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : (System *) sys : (int) alt
{
  int mp, dp;
  float nx = dx + pt.x;
  float ny = dy + pt.y;
  BOOL m = NO, inv;
  if (ABS(ny - y) > 1 || ABS(nx - x) > 1)
  {
    m = YES;
    x = nx;
    y = ny;
    inv = [sys relinknote: self];
    if (TYPEOF(mystaff) == STAFF)
    {
      dp = [self defaultPos];
      if (alt)
      {
        mp = [mystaff findPos: y] - dp;
	if (mp != p)
	{
          p = mp;
          y = [mystaff yOfPos: mp + dp];
	}
      }
      else if (inv)
      {
	y = [mystaff yOfPos: p + dp];
      }
    }
    [self recalc];
    [self markHangers];
    [self setVerses];
  }
  return m;
}


int whichfont[4] = {1, 0, 0, 1};

- drawMode: (int) m
{
  unsigned char symch;
  Clef *cl;
  Staff *sp;
  int ck, cf, i, ip, ss, koff, bp, bpos;
  int s, j, symcode;
  float hw, cx, sy;
  int sz = gFlags.size;
  NSFont *f;
  sp = mystaff;
  if (TYPEOF(sp) == STAFF && (cl = [sp findClef: self]) != nil)
  {
    ck = cl->keycentre;
    cf = cl->gFlags.subtype;
    koff = cl->p - [cl defaultPos];
    ss = sp->flags.spacing;
    bp = [sp posOfBottom];
  }
  else
  {
    ck = 2;
    cf = 0;
    koff = 0;
    ss = 4;
    bp = 8;
  }
  bpos = clefcpos[(int)clefuid[ck][cf]] + koff + p;
  sy = (TYPEOF(sp) == STAFF) ? [sp yOfTop] : y;
  cx = x;
  f = musicFont[whichfont[gFlags.subtype]][sz];
    /* scan sharps, then flats. Works for conventional and mixed */
    s = 2;
    while (s--)
    {
      for (i = 0; i < 7; i++)
      {
        j = symorder[s][i];
	symcode = keystr[j] & 03;
        if (symcode == s + 1)
        {
          symch = keychar[gFlags.subtype][symcode];
          hw = charhalfFGW(f, symch);
          ip = bpos + keypos[s][j];
          if (clefcpos[(int)clefuid[ck][cf]] == 4)
          {
            if (ip < 0) ip += (bp - 1);
            if (ip > bp) ip -= (bp - 1);
          }
          drawCharacterInFont(cx, GETYSP(sy, ss, ip), symch, f, m);
          if (TYPEOF(sp) == STAFF) drawledge(cx + hw, sy, hw, sz, ip, sp->flags.nlines, ss, m);
          if (keystr[j] & 4)
          {
            if (ip < (bp / 2)) ip += (bp - 1); else ip -= (bp - 1);
            drawCharacterInFont(cx, GETYSP(sy, ss, ip), symch, f, m);
            if (TYPEOF(sp) == STAFF) drawledge(cx + hw, sy, hw, sz, ip, sp->flags.nlines, ss, m);
          }
          cx += charFGW(f, symch) + 0.7;
        }
      }
    }
  return self;
}


/*
  convert from old to new format
*/

- upgradeKeystr: (int) kn : (int) oct
{
  int i, j, s;
  for (i = 0; i < 7; i++) keystr[i] = 0;
  if (kn == 0)
  {
    keystr[6] = 1;
    gFlags.subtype = 3;
    return self;
  }
  if (kn < 0)
  {
    kn = -kn;
    s = 0;
  }
  else s = 1;
  for (i = 0; i < kn; i++)
  {
    j = symorder[s][i];
    keystr[j] = s + 1;
    if (oct & (1 << i)) keystr[j] |= 4;
  }
  return self;
}


/* check for some old keynum=0 that slipped through */
/*sb: moved to initWithCoder method */
#if 0
#warning ArchiverConversion: put the contents of your 'awake' method at the end of your 'initWithCoder:' method instead
- awake
{
  int i;
#warning ArchiverConversion: put the contents of your 'awake' method at the end of your 'initWithCoder:' method instead
  for (i = 0; i < 7; i++)  if (keystr[i]) return [super awake];
  keystr[6] = 1;
  gFlags.subtype = 3;
#warning ArchiverConversion: put the contents of your 'awake' method at the end of your 'initWithCoder:' method instead
  return [super awake];
}
#endif


- (id)initWithCoder:(NSCoder *)aDecoder
{
  char c, b1 = 0;
  char keynum, octave;
  int v = [aDecoder versionForClassName:@"KeySig"];
  [super initWithCoder:aDecoder];
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccc", &c, &keynum, &octave];
    [self upgradeKeystr: keynum : octave];
    if (c) gFlags.subtype = 3;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"cc", &keynum, &octave];
    [self upgradeKeystr: keynum : octave];
    p = 0;
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccc", &keynum, &octave, &b1];
    [self upgradeKeystr: keynum : octave];
    p = b1;
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"cc", &keynum, &octave];
    [self upgradeKeystr: keynum : octave];
  }
  else if (v == 4)
  {
    [aDecoder decodeArrayOfObjCType:"c" count:7 at:keystr];
  }
  else if (v == 5)
  {
    /* this included the mode, no longer used. */
    [aDecoder decodeArrayOfObjCType:"c" count:7 at:keystr];
    [aDecoder decodeValueOfObjCType:"c" at:&b1];
  }
  { //sb: the following from the awake method
    int i;
    for (i = 0; i < 7; i++)  if (keystr[i]) return self/*[super awake]*/;
    keystr[6] = 1;
    gFlags.subtype = 3;
//    return /* [super awake] */;
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeArrayOfObjCType:"c" count:7 at:keystr];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:7 forKey:@"NUMKEYSTR"];
    for (i = 0; i < 7; i++) [aCoder setInteger:keystr[i] forKey:[NSString stringWithFormat:@"keystr%d",i]];
}

@end
