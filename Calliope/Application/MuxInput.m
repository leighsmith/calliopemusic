/*  Code for Input of Mux .def files */

#import "MuxInput.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "System.h"
#import "mux.h"
#import "muxlow.h"
#import <string.h>
#import <stdlib.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSApplication.h>
#import <Foundation/NSArray.h>
#import "Staff.h"
#import "Tie.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "Accent.h"
#import "StaffObj.h"
#import "TimeSig.h"
#import "Runner.h"
#import "Beam.h"
#import "Tuple.h"
#import "GNote.h"
#import "NoteHead.h"
#import "Range.h"
#import "Barline.h"
#import "KeySig.h"
#import "Clef.h"
#import "Tablature.h"
#import "Rest.h"
#import "Metro.h"
#import "TextGraphic.h"
#import "NeumeNew.h"
#import "Bracket.h"

extern float staffheads[3];
extern short restoffs[4][10];

/*
  This code is included as a category of GraphicView for back-compat
  reasons only, and will be removed when .def files vanish from the
  face of the earth.  Several back-versions of .def format are handled.
*/

@implementation GraphicView(MuxInput)

#define MAXMAPTAB 32

struct {int did; NSFont *font;} maptab[MAXMAPTAB];

static int nummaptab;

static float dxoff;

static System *sys;

static char *PSfont[10] =
{
  "NewCenturySchlbk-Roman",
  "NewCenturySchlbk-Italic",
  "NewCenturySchlbk-Bold",
  "NewCenturySchlbk-BoldItalic",
  "Times-Roman",
  "Times-Italic",
  "Times-Bold",
  "Times-BoldItalic",
  "Sonata", NULL,
};

unsigned char tabbodymap[4] = {2, 0, 1, 3};

unsigned char *accentchar = "XF.\255mnoVv>du@!#";

unsigned char accentpose[15] = {0, 0,2,2,0,0,2,2,2,0,0,0,0,0,0 };

unsigned char chartab[32] =
{
  '\251', 160, '\266', 182, '\244', 168, '\340', 213, '\341', 214,
  '\351', 221, '\350', 220, '\354', 224, '\355', 226, '\362', 236,
  '\363', 237, '\366', 240, '\371', 242, '\372', 243, '\375', 247,
  '_',    TIECHAR
};

static char nextchar(unsigned char ch)
{
  int i;
  for (i = 0; i < 32; i+=2) if (ch == chartab[i]) return chartab[i+1];
  return ch;
}


static void convmuxaccent(Accent *p, unsigned char *s)
{
  int i, j, sl;
  unsigned char ch, mch, found;
  sl = strlen(s);
  if (sl > 4) sl = 4;
  for (j = 0; j < sl; j++)
  {
    mch = s[j];
    i = 0;
    found = 0;
    while ((ch = accentchar[i]) && !found)
    {
      if (ch == mch)
      {
        p->sign[j] = i;
	found = 1;
      }
      else ++i;
    }
    if (!found)
    {
      msg("could not find accent character");
      return;
    }
  }
}


/* back compat only:  return whether the string is a figure with no spaces */

static int unspacefig(s)
unsigned char *s;
{
  if (figurechar(s[0]) == 0) return(0);
  while (*s) if (*s++ == ' ') return(0);
  return(1);
}


/* back compat: convert from old to new clef ID */

static int clefid[8] = 
{ (1 << 2) | 0, (0 << 2) | 2, (0 << 2) | 1, (0 << 2) | 0, 
  (1 << 2) | 1, (0 << 2) | 2, (2 << 2) | 0, (2 << 2) | 1};

static int clefstyle[4] = {0, 2, 1, 3}; /* swaps Chant and OldBook A */


/* remap a font from file-id to new-id */

static NSFont *putmapfont(char *name, int s, int did)
{
  int i;
  NSFont *f;
  for (i = 0; i < nummaptab; i++) if (maptab[i].did == did) return(maptab[i].font);
  maptab[nummaptab].did = did;
  if (s == 17) s = 18;
  f = maptab[nummaptab].font = [NSApp readyFont: name : (float) s];
  ++nummaptab;
  return(f);
}

static NSFont *remapdid(int did)
{
  int i;
  for (i = 0; i < nummaptab; i++) if (maptab[i].did == did) return(maptab[i].font);
  fprintf(stderr, "Font DID=%d used before remap table set\n", did);
return nil;
}


/* compat: convert from fontindex/sizeindex format, returning a nid */
/* A did is concocted from f,s guaranteed not to clash with real ones */
/* the tables are cut-down versions of the old ones, and immutable */

static char fontsizes[17] = {0, 18, 20, 14, 0, 34, 24, 14, 18, 18, 18, 18, 18, 18, 17, 0, 0};

static char psnums[17] = {0, 0, 2, 4, 0, 4, 4, 7, 7, 1, 3, 4, 5, 6, 2, 0, 0};

static int textfont[4][8] =
{
  {1, 9, 14, 10, 11, 12, 13, 8},
  {5, 0, 2,  0, 6, 0, 0, 0},
  {0, 0, 0, 0, 3, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0}
};

static NSFont *convertnid(int f, int s)
{
  int i;
  i = textfont[s][f];
  return putmapfont(PSfont[psnums[i]], fontsizes[i], 60 + (f << 2) + s);
}


/* find the true length of a string in *.def format */

static int strlenx(unsigned char *s)
{
  char unsigned c;
  int n = 0;
  while ((c = *s++) != '\0')
  {
    if (c == '\\') s += 3;
    ++n;
  }
  return(n);
}


/*
  Convert from .def format into NeXTencoding.  Caller may use
  same buffer, but that's OK as the converted string is shorter-or-equal!
*/

static void convmuxstr(unsigned char *d, unsigned char *s)
{
  unsigned char c, n, *t;
  t = d;
  while ((c = *s++) != '\0')
  {
    if (c == '\\')
    {
      c = *s;
      if ('0' <= c && c <= '9')
      {
        ++s;
        n = ((c & 3) << 6);
        n += ((*s++ & 7) << 3);
        n += (*s++ & 7);
      }
      else n = '\n';
      c = n;
    }
    *t++ = nextchar(c);
  }
  *t = '\0';
}


/* 
  Return the Nth note on staff S.  If N < 0, then use previous system
  nil for error conditions.  For example, connectors between
  systems that have been written to scrath files and reused, etc.
*/

- getnthnote: (int) n : (int) s
{
  Staff *sp;
  if (n > 0) sp = [sys getstaff: s];
  else if (n < 0)
  {
    sp = [[self getSystem: sys : -1] getstaff: s];
    n = -n;
  }
  else return(nil);
  return [sp->notes objectAtIndex:(n - 1)];
}



#define HASPROP(a, m) ((a) & (m))
#define GETPROP(a, m, s) (((a) & (m)) >> s)
#define PUTPROP(n, a, m, s) (((a) & (~(m))) | ((n) << (s)))
#define PROPINVIS 1	/* object is invisible (blue, non-printing) */
#define PRINVISOFF 0	/* shift offset for invis */
#define PROPSIZE 6	/* mask for size code (100%, 75%, 50%) */
#define PRSIZEOFF 1	/* shift offset for size code */
#define PROPLOCK 8	/* mask for stafflock code */
#define PRLOCKOFF 3	/* shift offset for stafflock */
#define RESTcompat 1	/* old REST format (keep until none exist) */
#define CLEFcompat 3	/* a old format sign */
#define KEYcompat 4	/* an old format key signature */
#define BARmux	2	/* a bar line.  sym field hold kind */
#define TIMEmux	5	/* a time signature */
#define RANGEmux 6	/* a range signature */
#define CLEFmux	7	/* a clef sign */
#define KEYmux	8	/* a key signature */


static void setprops(Graphic *p, int x)
{
  if (HASPROP(x,PROPINVIS)) p->gFlags.invis = 1;
  if (HASPROP(x, PROPLOCK)) p->gFlags.locked = 1;
  p->gFlags.size = GETPROP(x, PROPSIZE, PRSIZEOFF);
}

 
static void setstaff(StaffObj *p, int x, int y, int pos)
{
  p->x = x + dxoff;
  p->y = y;
  p->p = pos;
}

static void setbounds(Graphic *p, int x2, int y2, int t, int u)
{
  p->bounds.origin.x = x2;
  p->bounds.origin.y = y2;
  p->bounds.size.width = t;
  p->bounds.size.height = u;
}

static void setruncode(Runner *p, int x)
{
  int i;
  p->flags.vertpos = x & 1;
  p->flags.evenpage = (x >> 1) & 1;
  p->flags.oddpage = (x >> 2) & 1;
  i = (x >> 3) & 3;
  if (i > 0) --i;
  p->flags.horizpos = i;
  p->flags.onceonly = (x >> 5) & 1;
  p->flags.nextpage = (x >> 6) & 1;  
}

static void setdeftime(TimeSig *p, int s)
{
  ((Graphic *)p)->gFlags.subtype = 4;
  sprintf((char *)(p->numer), "%d", s);
}

static void settriplum(TimeSig *p, int t)
{
  p->dot = (t == 1);
  p->line = (t == 2);
}

- makeclef: (int) st: (int) ks: (int) ot: (int) pos
{
  Clef *p = [Graphic makemux: CLEF];
  p->gFlags.subtype = st;
  p->keycentre = ks;
  p->ottava = ot;
  p->p = [p defaultPos];
  return p;
}


extern unsigned char accidents[4][6];
extern unsigned char headfont[NUMHEADS][10];
extern char btype[4];
extern char stype[4];

void setheadlist(GNote *p, int acc)
{
  NoteHead *h;
  float hw;
  int sz, bt, st;
  NSFont *f;
  p->headlist = [[NSMutableArray alloc] init];
  h = [[NoteHead alloc] init];
  h->pos = p->p;
  h->accidental = acc;
  h->myY = p->y;
  h->myNote = p;
  sz = p->gFlags.size;
  bt = btype[p->gFlags.subtype];
  st = stype[p->gFlags.subtype];
  f = musicFont[headfont[bt][p->time.body]][sz];
  hw = halfwidth[sz][bt][p->time.body];
  h->accidoff = p->x - hw - charFGW(f, accidents[bt][acc]) - 2;
  h->dotoff =  (p->p & 1) ? 0 : -1;
  [p->headlist addObject: h];
}


/*
  Read file in old Mux format.
  All staff numbers must be reduced by 1.
  All getnotenum indices must be reduced by 1.
  All note bodies are increased by 1.
  staff subtypes renumbered as per staffsubtype.
*/

static char staffsubtype[4] = {0, 0, 1, 2};
static char textsubtype[6] = {0, LABEL, STAFFHEAD, 0, TITLE, 0};

- readMux: (char *) name
{
  int ch, page;
  StaffObj *lastobj = nil;
  id p, q;
  Staff *sp;
  Verse *vp;
  FILE *in;
  unsigned char lastperfs[32];
  char unsigned charbuff2[512];
  short x1,y1,x2,y2;
  short r,s,t,u,v,w;
  short g, kn, ks;
  int i;
  int typecount[NUMTYPES];
  float sheight;
  for (i = 0; i < NUMTYPES; i++) typecount[i] = 0;
  for (i = 0; i < 32; i++) lastperfs[i] = 0;
  if ((in = fopen(name,"r")) == NULL) 
  {
    sprintf(charbuff2, "Could not open %s\n", name);
    msg(charbuff2);
    return(nil);
  }
  [NSApp putUpPanel: "Reading old format file..."];
  nummaptab = 0;
  page = 0;
  sys = nil;
  while ((ch = getc(in)) != EOF)
  {
/*
    printf("got %c\n", ch);
*/
    switch(ch)
    {
    case ' ':
    case '\n':
    case '\r':
    case '\t':
      continue;
    case '%':
    case '1':
      while (getc(in) != '\n') ;
      continue;
    case 'F':
      fscanf(in, "%hd %hd %hd %hd %s", &r, &s, &t, &u, charbuff2);
      putmapfont(charbuff2, s, r);
      continue;
    case 'q':
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd %hd %hd", &x1, &y1, &x2, &y2, &r,&s, &t, &u, &v, &w);
      p = [Graphic makemux: BLOCK];
      ++typecount[BLOCK];
      --s;
      setprops(p, x1);
      setstaff(p, x2, y2, r);
      setbounds(p, x2, y2, t, u);
      [[sys getstaff: s] linknote: p];
      continue;
    case 'P':
      fscanf(in, "%hd %hd %hd %hd", &x1, &y1, &x2, &y2);
      continue;
    case 'V':
      fscanf(in, "%hd", &g);
      lastobj->verses = [[NSMutableArray alloc] initWithCapacity:g];
      continue;
    case 'c':
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd", &x1, &y1, &x2, &y2, &r, &s, &t, &u, &v, &w, &kn, &ks);
      --s;
      switch (kn & 0xFF)
      {
        case 0:
	case 1:
	case 2:
	case 4:
	case 5:
// fprintf(stderr, "ignoring TIE of type %d: sys=%d, staff=%d, objs %d - %d\n", kn & 0xFF, page, s, u, v);
          p = [Graphic makemux: TIE];
          ++typecount[TIE];
	  q = ((Tie *)p)->partner;
	  i =  kn & 0xFF;
	  if (i == 2) i = 3;
          ((Graphic *)p)->gFlags.subtype = ((Graphic *)q)->gFlags.subtype = i;
          setprops(p, ks);
	  setprops(q, ks);
          ((Tie *)p)->offset.x = x1;
          ((Tie *)p)->offset.y = y1;
          ((Tie *)q)->offset.x = x2;
          ((Tie *)q)->offset.y = y2;
          ((Tie *)p)->flags.ed = (kn >> 8) & 0x1;
	  ((Tie *)q)->flags.ed = (kn >> 8) & 0x1;
          ((Tie *)p)->client = [self getnthnote: u : s];
          ((Tie *)q)->client = [self getnthnote: v : s];
          if (((Tie *)q)->client == nil || ((Tie *)p)->client == nil) continue;
	  [((Tie *)p)->client linkhanger: p];
	  [((Tie *)q)->client linkhanger: q];
	  break;
	case 3:
	case 6:
          p = [Graphic makemux: TUPLE];
          ++typecount[TUPLE];
          setprops(p, ks);
          [p linkMux: [sys getstaff: s] : (u - 1) : (v - 1) : 0];
	  ((Tuple *)p)->flags.formliga = 1;
	  ((Tuple *)p)->flags.horiz = 1;
	  ((Tuple *)p)->flags.localiga = 2;
	  if (kn & 0xFF == 3)
	  {
	    ((Tuple *)p)->gFlags.subtype = 1;
	    ((Tuple *)p)->uneq1 = w & 0xFF;
	  }
	  else
	  {
	    ((Tuple *)p)->gFlags.subtype = 3;
	    ((Tuple *)p)->uneq1 = ((w >> 10) & 7) + 1;
	    ((Tuple *)p)->uneq2 = (w >> 8) & 3;
	  }
	  break;
      }
      continue;
    case 'r':
      /* compat only */
      fscanf(in, "%hd %hd %hd", &s, &t, &u);
      if ((s & 0xFF) == 2) [sys installLink];
      else
      {
        p = [Graphic makemux: BRACKET];
        ++typecount[BRACKET];
        ((Graphic *)p)->gFlags.subtype = (s & 0xFF) + 1;
        setprops(p, (s >> 8) & 0xFF);
	((Bracket *)p)->level = 1;
        ((Bracket *)p)->client1 = [sys getstaff: t - 1];
        ((Bracket *)p)->client2 = [sys getstaff: u - 1];
        [sys linkobject: p];
      }
      continue;
    case 'R':
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd", &s, &t, &u, &v, &w, &x1, &y1, &x2);
      if (s == 2) [sys installLink];
      else
      {
        p = [Graphic makemux: BRACKET];
        ++typecount[BRACKET];
        ((Graphic *)p)->gFlags.subtype = s + 1;
        setprops(p, v);
	((Bracket *)p)->level = w;
        ((Bracket *)p)->client1 = [sys getstaff: t - 1];
        ((Bracket *)p)->client2 = [sys getstaff: u - 1];
        [sys linkobject: p];
      }
      continue;
    case 'B':
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd", &x1, &y1, &s, &t, &r, &u, &v);
      --s;
      p = [Graphic makemux: BEAM];
      ++typecount[BEAM];
      setprops(p, x1);
      [p linkMux: [sys getstaff: s] : (u - 1) : (v - 1) : 1];
      continue;
    case 'g':
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd",
                   &r, &s, &t, &u, &v, &w, &x1, &y1, &x2, &y2, &g);
      --s;
      if ((w & 0xFF) == 9) /* convert to new format molle */
      {
        p = [Graphic makemux: KEY];
	++typecount[KEY];
        setprops(p, (w >> 8) & 0xFF);
        setstaff(p, r, 0, t);
        ((Graphic *)p)->gFlags.subtype = 2;
      }
      else
      {
        p = [Graphic makemux: NEUMENEW];
        ++typecount[NEUMENEW];
        setprops(p, (w >> 8) & 0xFF);
        setstaff(p, r, 0, t);
        ((NeumeNew *)p)->p2 = u;
        ((NeumeNew *)p)->p3 = v;
        ((Graphic *)p)->gFlags.subtype = w & 0xFF;
        ((NeumeNew *)p)->nFlags.dot = x1;
        ((NeumeNew *)p)->nFlags.vepisema = y1;
        ((NeumeNew *)p)->nFlags.hepisema = x2;
        ((NeumeNew *)p)->nFlags.num = y2 & 3;
        ((NeumeNew *)p)->nFlags.molle = y2 >> 2;
        ((NeumeNew *)p)->nFlags.quilisma = g;
      }
      [[sys getstaff: s] linknote: p];
      lastobj = p;
      continue;
    case 'x':
    case 'U':
      /* compatibility only */
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %s",
        &x1, &y1, &x2, &y2, &r, &s, &t, &u, &v, &w, charbuff2);
      --v;
      if (ch == 'x' && u > 1)
      {
        p = [Graphic makemux: RUNNER];
        ++typecount[RUNNER];
        setprops(p, (x1 >> 8) & 0xFF);
        convmuxstr(charbuff2, charbuff2);
        setruncode(p, u);
	((Runner *)p)->client = sys;
        [sys linkobject: p];
        [p initMux: charbuff2 : convertnid(x1 & 0xFF, y1) : self];
	continue;
      }
      p = [Graphic makemux: TEXTBOX];
      ++typecount[TEXTBOX];
      setprops(p, (x1 >> 8) & 0xFF);
      ((TextGraphic *)p)->just = x2;
      ((TextGraphic *)p)->offset.x = r;
      ((TextGraphic *)p)->offset.y = s;
      convmuxstr(charbuff2, charbuff2);
      if (ch == 'U')
      {
        ((Graphic *)p)->gFlags.subtype = LABEL;
        ((TextGraphic *)p)->horizpos = t;
        ((TextGraphic *)p)->client = [self getnthnote: w : v];
	[((TextGraphic *)p)->client linkhanger: p];
      }
      else if (ch == 'x')
      {
        ((Graphic *)p)->gFlags.subtype = STAFFHEAD;
        ((TextGraphic *)p)->offset.x += dxoff;
        ((TextGraphic *)p)->horizpos = t;
	((TextGraphic *)p)->client = [sys getstaff: 0];
        [sys linkobject: p];
      }
      [p initMux: r : s : charbuff2 : convertnid(x1 & 0xFF, y1)];
      continue;
    case 'W':
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %s",
        &x1, &y1, &x2, &y2, &r, &s, &t, &u, &v, &w, &kn, &ks, &g, charbuff2);
      if (u == 5)
      {
        if (*charbuff2 == '=')
	{
	  p = [Graphic makemux: METRO];
          ++typecount[METRO];
          setprops(p,t);
	  convmuxstr(charbuff2, charbuff2);
	  ((Metro *)p)->body[0] = charbuff2[2] - '0' + 1;
	  ((Metro *)p)->dot[0] = charbuff2[2] - '0';
	  if (charbuff2[5] == 'd')
	  {
	    ((Metro *)p)->gFlags.subtype = 1;
	    ((Metro *)p)->ticks = charbuff2[6];
	  }
	  else
	  {
	    ((Metro *)p)->gFlags.subtype = 0;
	    ((Metro *)p)->body[1] = charbuff2[6] - '0' + 1;
	    ((Metro *)p)->dot[1] = charbuff2[7] - '0';
	  }
	  ((Metro *)p)->client = [self getnthnote: g : ks - 1];
	  [((Metro *)p)->client linkhanger: p];
	  continue;
	}
	else
	{
          p = [Graphic makemux: ACCENT];
          ++typecount[ACCENT];
          setprops(p,t);
	  convmuxstr(charbuff2, charbuff2);
	  convmuxaccent(p, charbuff2);
	  ((Graphic *)p)->gFlags.subtype = (y2 > 0);
	  ((Accent *)p)->client = [self getnthnote: g : ks - 1];
	  [((Accent *)p)->client linkhanger: p];
          ((Accent *)p)->xoff = 0;
	  ((Accent *)p)->yoff = 0;
	  continue;
	}
      }
      if (u == 3)
      {
        p = [Graphic makemux: RUNNER];
        ++typecount[RUNNER];
        setprops(p, t);
        ((Runner *)p)->flags.just = s;
        convmuxstr(charbuff2, charbuff2);
        setruncode(p, v);
	((Runner *)p)->client = sys;
        [sys linkobject: p];
        [p initMux: charbuff2 : (y2 >= 0 ? convertnid(x2, y2) : remapdid(x2)) : self];
	continue;
      }
      p = [Graphic makemux: TEXTBOX];
      ++typecount[TEXTBOX];
      u = textsubtype[u];
      SUBTYPEOF(p) = u;
      setprops(p, t);
      convmuxstr(charbuff2, charbuff2);
      ((TextGraphic *)p)->just = s;
      ((TextGraphic *)p)->offset.x = x1;
      ((TextGraphic *)p)->offset.y = y1;
      switch(u)
      {
        case LABEL:
          ((TextGraphic *)p)->horizpos = v;
	  ((TextGraphic *)p)->client = [self getnthnote: g : ks - 1];
	  [((TextGraphic *)p)->client linkhanger: p];
	  break;
	case STAFFHEAD:
          ((TextGraphic *)p)->offset.x += dxoff;
          ((TextGraphic *)p)->horizpos = v;
	  ((TextGraphic *)p)->client = [sys getstaff: w - 1];
          [sys linkobject: p];
	  break;
	case TITLE:
          ((TextGraphic *)p)->offset.x += dxoff;
          ((TextGraphic *)p)->horizpos = v;
	  ((TextGraphic *)p)->client = sys;
          [sys linkobject: p];
	  break;
      }
      [p initMux: x1 : y1 : charbuff2
                : (y2 >= 0 ? convertnid(x2, y2) : remapdid(x2))];
      continue;
    case 'S':
      fscanf(in, "%hd", &s);
      p = [[System alloc] init: s];
      [self linkSystem: sys : p];
      sys = p;
      sys->sysnum = ++page;
      [sys installLink]; /* back compat */
      continue;
    case 'T':
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd",
        &r, &s, &t, &u, &v, &w, &x1, &x2);
      sys->flags.pgcontrol = 0;
      sys->barnum = s;
      continue;
    case 'a':
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd",
        &r, &s, &t, &u, &v, &w, &x1, &y1, &x2, &y2, &g, &kn);
      --r;
      sp = [sys getstaff: r];
      if (r == 0)
      {
        ks = u + v + kn + t;
	sheight = 32.0 * 595  / ks;
//        [NXApp document])->staffheight = sheight;
	dxoff = u * (32.0 / sheight);
        sys->lindent = kn * (sheight / 32.0);
      }
      sp->y = s;
      sp->flags.hidden = 0;
      if (y1 < 0)
      {
        sp->flags.hidden = 1;
	y1 = -y1;
      }
      sp->flags.nlines = y1;
      sp->flags.spacing = x2;
      sp->flags.subtype = staffsubtype[y2];
      sp->topmarg = staffheads[sp->flags.subtype];
      if (g)
      {
        sp->flags.haspref = 1;
	sp->pref1 = 0.0;
	sp->pref2 = kn;
      }
      else sp->flags.haspref = 0;
      continue;
    case 'A':  /* adds more to the current staff */
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd %hd %hd",
        &r, &s, &t, &u, &v, &w, &x1, &y1, &x2, &y2);
      continue;
    case 'p':
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd",
        &g, &x1, &y1, &w, &r, &s, &t, &u, &v, &x2, &kn, &ks);
      p = [Graphic makemux: NOTE];
      ++typecount[NOTE];
      --y1;
      setprops(p, kn);
      i = (ks & 7);
      if (i != 0)
      {
        ((GNote *)p)->time.body = i + 1;
        [((GNote *)p) setDottingCode: (ks >> 3) & 1];
      }
      else
      {
        ((GNote *)p)->time.body = r + 1;
        [((GNote *)p) setDottingCode: u];
      }
      ((GNote *)p)->time.stemlen = s;
      ((GNote *)p)->time.stemup = (s < 0);
      ((GNote *)p)->time.stemfix = 0;
      setstaff(p, x1, 0, w);
      ((Graphic *)p)->gFlags.subtype = g;
      [[sys getstaff: y1] linknote: p];
      setheadlist(p, v & 7);
      lastobj = p;
      continue;
    case 'e':
      fscanf(in, "%hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd %hd",
        &g, &x1, &y1, &w, &r, &s, &t, &u, &v, &x2, &kn, &ks);
      p = [Graphic makemux: REST];
      ++typecount[REST];
      --y1;
      setprops(p, kn);
      ((Rest *)p)->time.body = r + 1;
      ((Rest *)p)->numbars = s;
      [((Rest *)p) setDottingCode: u];
      ((Graphic *)p)->gFlags.subtype = g;
      setstaff(p, x1, 0, [p defaultPos]);
      /* ((Rest *)p)->p = restoffs[g & 1][r + 1]; */
      lastobj = p;
      [[sys getstaff: y1] linknote: p];
      continue;
    case 't':
      fscanf(in,"%hd %hd %hd %hd %hd %s %hd", &g, &x1, &y1, &t, &u, charbuff2, &v);
      --y1;
      p = [Graphic makemux: TABLATURE];
      ++typecount[TABLATURE];
      setprops(p, (g >> 8) & 0xFF);
      setstaff(p, x1, 0, 0);
      if (t != 7) ((Tablature *)p)->time.body = t + 1;
      [((Tablature *)p) setDottingCode: u & 1];
      ((Tablature *)p)->flags.online = (u >> 1) & 1;
      ((Tablature *)p)->flags.body = tabbodymap[(u >> 2) & 3];
      ((Tablature *)p)->flags.typeface = 0;
      ((Tablature *)p)->flags.prevtime = (t == 7);
      if (g & 0xFF)
      {
        ((Tablature *)p)->flags.direction = 1;
	((Tablature *)p)->flags.cipher = 1;
      }
      else
      {
        ((Tablature *)p)->flags.direction = 0;
	((Tablature *)p)->flags.cipher = 0;
      }
      for (w = 0; w < 6; w++) ((Tablature *)p)->chord[w] = (charbuff2[w] == '~' ? -1 : charbuff2[w] - 'a');
      ((Tablature *)p)->diapason = v;
      [[sys getstaff: y1] linknote: p];
      continue;
    case 'u':
      continue;
    case 'b':
      fscanf(in,"%hd %hd %hd %hd %hd %hd %hd", &g, &x1, &y1, &r, &s, &t, &u);
      --y1;
      switch(r)
      {
	case RESTcompat:
          /* back compatibility only */
          p = [Graphic makemux: REST];
          ++typecount[REST];
          ((Rest *)p)->time.body = s + 1;
          ((Rest *)p)->numbars = 0;
          [((Rest *)p) setDottingCode: t];
          ((Graphic *)p)->gFlags.subtype = u;
      setstaff(p, x1, 0, [p defaultPos]);
	  g = 0;
          break;
	case CLEFcompat:
          /* back compatibility for old clefs and TREBLE8.
	     old system was ambiguous.  b...3 2 0 1 will be translated as
	     backward-C: clef, NOT as modern octave bass clef */
	  if (s == 2 && u == 1)
	  {
            p = [self makeclef: 3 : 1 : 0 : t];
            ++typecount[CLEF];
      setstaff(p, x1, 0, [p defaultPos]);
	    break;
	  }
          if (s == 5) u = 1;
          s = clefid[s];
	case CLEFmux:
          p = [self makeclef: clefstyle[s >> 2] : s & 0x3 : u : t];
          ++typecount[CLEF];
      setstaff(p, x1, 0, [p defaultPos]);
	  break;
        case KEYcompat:
          switch(s)
          {
            case 0:
              t = -t;
	    case 1:
              s = 0;
              break;
            case 2:
              t = -t;
	    case 3:
              s = 1;
              break;
      setstaff(p, x1, 0, 0);
          }
	case KEYmux:
          p = [Graphic makemux: KEY];
          ++typecount[KEY];
//	  ((KeySig *)p)->keynum = t;
	  if (s) ((Graphic *)p)->gFlags.subtype = 3;
//	  ((KeySig *)p)->octave = u;
      setstaff(p, x1, 0, 0);
	  break;
	case BARmux:
	  if (s >= BARGUUP)
	  {
            p = [Graphic makemux: BLOCK];
            ++typecount[BLOCK];
	    ((Graphic *)p)->gFlags.subtype = (s - BARGUUP) + 1;
            setprops(p, g);
            setstaff(p, x1, 0, t);
            lastobj = p;
            [[sys getstaff: y1] linknote: p];
            continue;
	  }
	  else
	  {
            p = [Graphic makemux: BARLINE];
            ++typecount[BARLINE];
	    ((Graphic *)p)->gFlags.subtype = s;
 	    ((Barline *)p)->flags.editorial = u & 0x4;
	    ((Barline *)p)->flags.staff = 1;
	    ((Barline *)p)->flags.bridge = u & 0x1;
	  }
      setstaff(p, x1, 0, 0);
	  break;
	case TIMEmux:
          p = [Graphic makemux: TIMESIG];
     	  ++typecount[TIMESIG];
	  switch(u)
	  {
	    case 0:
	      ((Graphic *)p)->gFlags.subtype = 5;
	      sprintf((char *)(((TimeSig *)p)->numer), "%d", s);
	      sprintf((char *)(((TimeSig *)p)->denom), "%d", t);
	      break;
	    case 1:
	    case 2:
	      if (s == 2 || s == 4)
	      {
	        ((Graphic *)p)->gFlags.subtype = 2;
	      }
	      else setdeftime(p, s);
	      settriplum(p, t);
	      break;
	    case 3:
	      if (s == 0) ((Graphic *)p)->gFlags.subtype = 0;
	      else if (s == 2 || s == 4) ((Graphic *)p)->gFlags.subtype = 1;
	      else setdeftime(p, s);
	      settriplum(p, t);
	      break;
	  }
      setstaff(p, x1, 0, 4);
	  break;
	case RANGEmux:
          p = [Graphic makemux: RANGE];
          ++typecount[RANGE];
	  ((Graphic *)p)->gFlags.subtype = (u >> 2) & 0x3;
	  ((Range *)p)->slant = u & 0x3;
	  ((Range *)p)->line = (u >> 4) & 0x1;
	  ((Range *)p)->p1 = s;
	  ((Range *)p)->p2 = t;
      setstaff(p, x1, 0, 0);
	  break;
      }
      setprops(p, g);
      lastobj = p;
      [[sys getstaff: y1] linknote: p];
      continue;
    case 'w':
      fscanf(in, "%hd %hd %hd %hd %hd %s", &r, &s, &t, &u, &v, charbuff2);
      ++typecount[VERSE];
      vp = [[Verse alloc] init];
      vp->vFlags.hyphen = s;
      vp->offset = t;
      vp->gFlags.subtype = (v >> 8) & 0xF;
      if ((v & 0xF) != 0xF) vp->font = convertnid(u, v & 0xF); else vp->font = remapdid(u);
      vp->data = malloc(strlenx(charbuff2) + 1);
      convmuxstr(vp->data, charbuff2);
      vp->gFlags.invis = (v >> 4) & 0x1;
      vp->note = lastobj;
      [lastobj->verses addObject: vp];
      continue;
    default:
      sprintf(charbuff2,"unrecognized command: 0%o, ", ch);
      msg(charbuff2);
      continue;
  }
  }
  fclose(in);
  for(t = 0; t < NUMTYPES; t++) fprintf(stderr, "type %d count = %d\n", t, typecount[t]);
  [self recalcAllSys];
  [self doPaginate];
  [self renumber: self];
  [self firstPage: self];
  return self;
}

@end
