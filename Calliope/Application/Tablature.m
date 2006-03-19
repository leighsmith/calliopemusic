#import "Tablature.h"
#import "TabInspector.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "GVPerform.h"
#import "mux.h"
#import "muxlow.h"
#import "Staff.h"
#import "CallInst.h"
#import <AppKit/AppKit.h>

@implementation Tablature

extern char tabstemlens[3];
extern int getLines(Staff *s);
extern NSString *nullFingerboard;

static Tablature *proto;


+ (void)initialize
{
  if (self == [Tablature class])
  {
      (void)[Tablature setVersion: 6];		/* class version, see read: */ /*sb: bumped up to 6 for OS conversion */
    proto = [Tablature alloc];
    proto->flags.body = 4;
    proto->flags.direction = 0;
    proto->flags.cipher = 0;
    proto->flags.typeface = 0;
    proto->flags.online = 0;
    proto->tuning = nullFingerboard;
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [TabInspector class];
}
 
 
- init
{
  int i;
  [super init];
  gFlags.type = TABLATURE;
  gFlags.subtype = 0;
  flags = proto->flags;
  tuning = nil;
  selnote = -1;
  for (i = 0; i < 6; i++) chord[i] = -1;
  diapason = 0;
  diafret = -1;
  return self;
}


- (void)dealloc
{
    if (tuning) [tuning release];
  { [super dealloc]; return; };
}


- (BOOL) isBeamable
{
  return (time.body - [[DrawApp currentDocument] getPreferenceAsInt: TABCROTCHET] <= 5);
}


/* initialise the prototype note */

- proto: v : (NSPoint) pt : sp : sys : (Graphic *) g : (int) i
{
  [super proto: v : pt : sp : sys : g : i];
  [self setstem: 0];
  time.body = i;
  return self;
}


- recalc
{
  [super recalc];
  if (TYPEOF(mystaff) == STAFF) y = ((Staff *)mystaff)->y;
  return self; 
}

  
/* this is actually used to set basepoint offset of the stem, not the length */
 
- setstem: (int) m
{
  time.stemlen = getSpacing(mystaff) * 3.5;
  return self;
}


- reShape
{
  [self setstem: 0];
  return [super reShape];
}



#define TABOFF 3	/* extra space above top line for stem */

/* tablature strings */

#define NUMFRET 22

char *timesfinger[2][NUMFRET] =
{
  { ".", " ", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t"},
  { ".", " ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14",
  "15", "16", "17", "18", "19"}
};

#define NUMDIAP 9

char *timesdiap[2][NUMDIAP] =
{
  { "void", "",  "/", "//", "///",  "4",  "5",  "6",  "7"},
  { "void", "0", "8",  "9",   "X", "11", "12", "13", "14"}
};

char *olddiap[2][NUMDIAP] =
{
  {"void", "void", "void", "void", "void",    "D",    "E",  "F",  "G"},
  {"void", "0", "8", "9", "\336", "\337", "12", "13", "14"}
};



- (int) tabCount
{
  int i, j;
  j = 0;
  for (i = 0; i < 6; i++) j += (chord[i] != -1);
  j += diapason;
  return(j);
}


/* look back as far a beginning of line to find a tab with a flag */

static Tablature *findPrevFlag(Tablature *t)
{
  int i;
  Tablature *u;
  NSMutableArray *nl;
  Staff *sp = t->mystaff;
  if (TYPEOF(sp) != STAFF) return nil;
  nl = sp->notes;
  i = [nl indexOfObject:t];
  while (i--)
  {
    u = [nl objectAtIndex:i];
    if (TYPEOF(u) == TABLATURE && !(u->flags.prevtime)) return u;
  }
  return nil;
}


- (float) noteEval: (BOOL) f
{
  Tablature *t = self;
  while (t != nil)
  {
    if (!(t->flags.prevtime)) return [super noteEval: f];
    t = findPrevFlag(t);
  }
  return -1.0;
}


- (int) noteCode: (int) a
{
  Tablature *t = self;
  while (t != nil)
  {
    if (!(t->flags.prevtime)) return [super noteCode: a];
    t = findPrevFlag(t);
  }
  return -1;
}


- (int) getPatch
{
  return [instlist soundForInstrument: [self getInstrument]];
}


/* the complication is to return a fingerboard instrument by default */
 
- (NSString *) getInstrument
{
  NSString *i = tuning;
  if (i == nil)
  {
      i = [super getInstrument];
      if ([i isEqualToString: nullInstrument]) i = nullFingerboard;
  }
  return i;
}


- (int) whereInstrument
{
  if (tuning != nil) return 0;
  return [super whereInstrument];
}

/*
  Bounds don't mean much for selection within tablatures.
  set selend 0-5 for line, 6 for diapason, 7 for flags (meaning verse)
*/

static char tabpos[2][15] =
{
  { 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6},
  { 6, 6, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5}
};

- (BOOL) hit: (NSPoint) pt;
{
  int i, j, n;
  gFlags.selend = 0;
  if (TYPEOF(mystaff) == SYSTEM)
  {
    if (NSPointInRect(pt , bounds))
    {
      gFlags.selend = 7;
      gFlags.selbit = 1;
      return YES;
    }
    return NO;
  }
  if (TOLFLOATEQ(pt.x, x, 8.0))
  {
    i = [mystaff findPos: pt.y];
    if (i < -2)
    {
      if (NSPointInRect(pt , bounds))
      {
        gFlags.selend = 7;
        gFlags.selbit = 1;
        return YES;
      }
      return NO;
    }
    n = getLines(mystaff);
    j = 2 * n + 2;
    i += 2;
    if (i > j) return NO;
    gFlags.selend = tabpos[flags.direction][i];
    gFlags.selbit = 1;
    return YES;
  }
  return NO;
}

/* quick estimate just by (squared) distance to the centreline */

- (float) hitDistance: (NSPoint) pt
{
  float d = pt.x - x;
  return d * d;
}

- (BOOL) hitBeamAt: (float *) px : (float *) py
{
  *px = x;
  *py = y - time.stemlen - tabstemlens[gFlags.size];
  return YES;
}


/*
  insert a note into a tablature, accounting for direction and
  two-digit notes (if using numbers)
*/

- (int)keyDownString:(NSString *)cc
{
  int i, n, nl;
    int cst = *[cc cString];
    if (gFlags.selend == 7) return [super keyDownString:cc];
//  if (cs == NX_ASCIISET)
  if ([cc canBeConvertedToEncoding:NSASCIIStringEncoding])
  {
      if (cst == '/')
    {
      if (diapason < 8) diapason++; else diapason = 0;
      [self recalc];
      return 1;
    }
      if (cst == ' ') i = -1;
      else if (cst == '.') i = -2;
      else if (flags.cipher == 0 && istabchar(cst)) i = cst - 'a';
      else if (flags.cipher == 1 && isdigitchar(cst)) i = cst - '0';
    else
    {
      NSBeep();
      return 0;
    }
    if (i == -1 && flags.prevtime && [self tabCount] == 1)
    {
      NSBeep();
      return 0;
    }
    if (gFlags.selend == 6)
    {
      if (i == -1)
      {
        diafret = 0;
	diapason = 0;
      }
      else
      {
        diafret = i;
        if (diapason == 0) diapason++;
      }
    }
    else
    {
      n = gFlags.selend;
      if (flags.direction)
      {
        if (TYPEOF(mystaff) == STAFF) nl = ((Staff *)mystaff)->flags.nlines;
        else
        {
          NSBeep();
	  return 0;
        }
        n = nl - 1 - n;
      }
      if (flags.cipher && i >= 0 && chord[n] == 1) i += 10;
      chord[n] = i;
    }
  }
  [self recalc];
  return 1;
}


/*
  gFlags.subtype: 0 normal, 1 strum up, 2 strum down.
  set mk whether a mark was made (so that beamed tab rests can have
  their bounding box filled with something sensible instead of 0
*/


static BOOL ambig[6][10] = /* whether must draw as other style */
{
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
  {0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
  {0, 0, 0, 0, 0, 0, 0, 1, 1, 1},
  {0, 0, 0, 0, 0, 0, 0, 1, 1, 1}
};

static char usebo[6][10] = /* if ambig, switch to style number */
{
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
  {0, 0, 0, 0, 0, 0, 0, 1, 1, 1},
  {0, 0, 0, 0, 0, 0, 0, 1, 1, 1},
};

static char btype[6] = {0, 1, 4, 4, 4, 4}; /* default head type */
static char stype[6] = {0, 1, 0, 1, 2, 3}; /* default stem type */
static char usesm[6] = {1, 1, 1, 1, 0, 0}; /* whether to use small size as normal size */

/*
  dig 0=letters,1=digits; diafret 0=a, 1=b etc; diapason 0=unused, 1=a, 2=/a, 3=//a etc
*/

- drawDiapason: (float) tx : (float) ty : (int) n : (int) ss : (int) sz : (NSFont *) f : (NSFont *) ft : (int) m
{
  float cy, lh;
  int k, dig, pos, ledge = 0;
  char *s;
  NSFont *outf;
  dig = flags.cipher;
  if (flags.typeface == 0)
  {
    outf = ft;
    if (dig == 0)
    {
        if (diapason >= 5) s = timesdiap[0][(int)diapason];
      else
      {
          ledge = diapason - 1;
        s = timesfinger[0][diafret + 2];
      }
    }
    else
    {
      if (diafret > 0)
      {
        s = timesfinger[1][diafret + 2];
      }
      else
      {
          s = timesdiap[1][(int)diapason];
      }
    }
  }
  else
  {
      outf = f;
    if (dig == 0)
    {
        if (diapason >= 5) s = olddiap[0][(int)diapason];
      else
      {
          ledge = diapason - 1;
          s = timesfinger[0][diafret + 2];
      }     
    }
    else
    {
      if (diapason == 1 && diafret >= 0) s = timesfinger[1][diafret + 2];
        else s = olddiap[1][(int)diapason];
    }
  }
  if (flags.direction)
  {
    pos = 0;
    if (flags.online) pos = -1;
    cy = GETYSP(ty, ss, pos) + charFLLY(f, s[0]) - 2;
  }
  else
  {
      pos = ((n - 1) << 1) + 1;
    if (flags.online) ++pos;
    cy = GETYSP(ty, ss, pos);
    if (ledge > 0)
    {
      lh = charFGH(musicFont[0][sz], CH_tabledger);
      cy += lh;
      for (k = 0; k < ledge; k++)
      {
        centxChar(tx, cy, CH_tabledger, musicFont[0][sz], m);
        cy += lh;
      }
      cy -= lh;
    }
    cy += charFURY(f, s[0]);
  }
  centString(tx, cy, s, outf, m);
  return self;
}


- drawMode: (int) m
{
  Staff *sp;
  NSFont *f;
  DrawDocument *doc;
  int b, n, ss, sz, dsz, i, pos, c, dh, df;
  float cy;
  char *s;
  sz = gFlags.size;
  sp = mystaff;
  if (TYPEOF(sp) != STAFF)
  {
    n = 0;
    ss = 6;
  }
  else
  {
    n = sp->flags.nlines;
    ss = sp->flags.spacing;
  }
  if (gFlags.subtype)
  {
    cy = GETYSP(y, ss, n - 1);
    i = stemlens[0][0] >> 1;
    if (gFlags.subtype == 1) i = -i;
    drawstem(x, cy, time.body, i, sz, 0, 0, m);
    return self;
  }
  if (gFlags.selected && !gFlags.seldrag && gFlags.selend <= 6)
  {
    pos = (gFlags.selend << 1) - 1;
    if (flags.online) ++pos;
    else if (flags.direction) pos += 2;
    if (flags.direction && gFlags.selend == 6) pos = (flags.online) ? -2 : -1;
    cy = GETYSP(y, ss, pos);
    f = fontdata[FONTSTMR];
    centChar(x - 6, cy, '(', f, m);
    centChar(x + 8, cy, ')', f, m);
  }
  if (m == 0 && [self isBeamed] && [self tabCount] == 0)
  {
    /* draw something to fill the BB for an otherwise blank object */
    crect(x, y, 2, 2, m);
    return self;
  }
  if (flags.direction)
  {
    pos = (n << 1) - 1;
    if (flags.online) pos -= 1;
  }
  else
  {
    pos = -1;
    if (flags.online) pos += 1;
  }
  doc = [DrawApp currentDocument];
  f = (flags.typeface) ? musicFont[0][sz] : [doc getPreferenceAsFont: TABFONT];
  for (i = 0; i < n; i++)
  {
    c = chord[i];
    if (c >= 0 && c < NUMFRET)
    {
      s = timesfinger[flags.cipher][c + 2];
      cy = GETYSP(y, ss, pos) + charFCH(f, s[0]);
      centString(x, cy, s, f, m);
    }
    pos += (flags.direction) ? -2 : 2;
  }
  if (!flags.prevtime && ![self isBeamed])
  {
    c = -tabstemlens[sz];
    cy = y - time.stemlen;
    dsz = sz;
    df = time.body - [doc getPreferenceAsInt: TABCROTCHET];
    b = flags.body;
    if (ambig[b][df]) b = usebo[b][df];
    if (usesm[b]) dsz = smallersz[sz];
    dh = btype[b];
    csnote(x, cy, c, df, time.dot, dsz, dh, stype[b], m);
  }
  if (diapason > 0 && diapason < NUMDIAP) [self drawDiapason: x : y : n : ss : sz : f : [doc getPreferenceAsFont: TABFONT] : m];
  return self;
}


/* Archiving */

- upgradeDiap
{
  diafret = 0;
  if (diapason >= 9)
  {
    diafret = diapason - 9;
    diapason = 1;
  }
  return self;
}

extern int needUpgrade;

struct oldtabinfo
{
  unsigned int body : 2;		/* type of flag body */
  unsigned int notehead : 1;		/* whether notehead */
  unsigned int direction : 1;		/* reading top-down or bottum-up */
  unsigned int cipher : 1;		/* whether numbers or letters */
  unsigned int typeface : 1;		/* whether RomanItalic or 17C book */
  unsigned int online : 1;		/* whether on spaces or lines */
  unsigned int prevtime : 1;		/* whether to omit flag */
};

static char newhead[2][4] =
{
  {2, 3, 4, 5},
  {0, 1, 4, 5}
};


- (id)initWithCoder:(NSCoder *)aDecoder
{
  char  b1, b2, b3, b4, b5, b6, b7;
  int v = [aDecoder versionForClassName:@"Tablature"];
  struct oldtabinfo i;
  [super initWithCoder:aDecoder];
  tuning = nil;
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccc", &i, &diapason, &selnote];
    [aDecoder decodeArrayOfObjCType:"c" count:6 at:chord];
    flags.body = newhead[i.notehead][i.body];
    flags.direction = i.direction;
    flags.cipher = i.cipher;
    flags.typeface = i.typeface;
    flags.online = i.online;
    flags.prevtime = i.prevtime;
    [self upgradeDiap];
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b2, &b3, &b4, &b5, &b6, &b7];
    [aDecoder decodeValuesOfObjCTypes:"cc", &diapason, &selnote];
    [aDecoder decodeArrayOfObjCType:"c" count:6 at:chord];
    flags.body = b2;
    flags.direction = b3;
    flags.cipher = b4;
    flags.typeface = b5;
    flags.online = b6;
    flags.prevtime = b7;
    [self upgradeDiap];
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b2, &b3, &b4, &b5, &b6, &b7];
    [aDecoder decodeValuesOfObjCTypes:"ccc", &diapason, &selnote, &b1];
    [aDecoder decodeArrayOfObjCType:"c" count:6 at:chord];
    flags.body = b2;
    flags.direction = b3;
    flags.cipher = b4;
    flags.typeface = b5;
    flags.online = b6;
    flags.prevtime = b7;
    [self upgradeDiap];
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b2, &b3, &b4, &b5, &b6, &b7];
    [aDecoder decodeValuesOfObjCTypes:"cccc", &diapason, &diafret, &selnote, &b1];
    [aDecoder decodeArrayOfObjCType:"c" count:6 at:chord];
    flags.body = b2;
    flags.direction = b3;
    flags.cipher = b4;
    flags.typeface = b5;
    flags.online = b6;
    flags.prevtime = b7;
  }
  else if (v == 4)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b2, &b3, &b4, &b5, &b6, &b7];
    [aDecoder decodeValuesOfObjCTypes:"cccc", &diapason, &diafret, &selnote, &b1];
    [aDecoder decodeArrayOfObjCType:"c" count:6 at:chord];
    flags.body = b2;
    flags.direction = b3;
    flags.cipher = b4;
    flags.typeface = b5;
    flags.online = b6;
    flags.prevtime = b7;
  }
  else if (v == 5)
  {
      char *t;
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b2, &b3, &b4, &b5, &b6, &b7];
    [aDecoder decodeValuesOfObjCTypes:"ccc", &diapason, &diafret, &selnote];
//    [aDecoder decodeValuesOfObjCTypes:"%", &tuning];
    [aDecoder decodeValuesOfObjCTypes:"%", &t];
    [aDecoder decodeArrayOfObjCType:"c" count:6 at:chord];
    flags.body = b2;
    flags.direction = b3;
    flags.cipher = b4;
    flags.typeface = b5;
    flags.online = b6;
    flags.prevtime = b7;
    if (t) tuning = [[NSString stringWithCString:t] retain];
  }
  else if (v == 6)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b2, &b3, &b4, &b5, &b6, &b7];
    [aDecoder decodeValuesOfObjCTypes:"ccc", &diapason, &diafret, &selnote];
//    [aDecoder decodeValuesOfObjCTypes:"%", &tuning];
    [aDecoder decodeValuesOfObjCTypes:"@", &tuning];
    [aDecoder decodeArrayOfObjCType:"c" count:6 at:chord];
    flags.body = b2;
    flags.direction = b3;
    flags.cipher = b4;
    flags.typeface = b5;
    flags.online = b6;
    flags.prevtime = b7;
  }

  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b2, b3, b4, b5, b6, b7;
  [super encodeWithCoder:aCoder];
  b2 = flags.body;
  b3 = flags.direction;
  b4 = flags.cipher;
  b5 = flags.typeface;
  b6 = flags.online;
  b7 = flags.prevtime;
  [aCoder encodeValuesOfObjCTypes:"cccccc", &b2, &b3, &b4, &b5, &b6, &b7];
  [aCoder encodeValuesOfObjCTypes:"ccc", &diapason, &diafret, &selnote];
  [aCoder encodeValuesOfObjCTypes:"@", &tuning];
  [aCoder encodeArrayOfObjCType:"c" count:6 at:chord];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:flags.body forKey:@"body"];
    [aCoder setInteger:flags.direction forKey:@"direction"];
    [aCoder setInteger:flags.cipher forKey:@"cipher"];
    [aCoder setInteger:flags.typeface forKey:@"typeface"];
    [aCoder setInteger:flags.online forKey:@"online"];
    [aCoder setInteger:flags.prevtime forKey:@"prevtime"];                                      
    [aCoder setInteger:diapason forKey:@"diapason"];
    [aCoder setInteger:diafret forKey:@"diafret"];
    [aCoder setInteger:selnote forKey:@"selnote"];

    [aCoder setObject:tuning forKey:@"tuning"];

    for (i = 0; i < 6 ; i++) [aCoder setInteger:chord[i] forKey:[NSString stringWithFormat:@"chord%d",i]];
}


@end
