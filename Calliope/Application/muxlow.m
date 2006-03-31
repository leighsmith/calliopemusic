/* $Id$ */
#import "mux.h"
#import "muxlow.h"
#import <Foundation/NSArray.h>
#import "Graphic.h"
#import "Staff.h"
#import "StaffObj.h"
#import "NoteGroup.h"
#import "Tuple.h"
#import "GVPerform.h"
#import "Course.h"
#import "CallInst.h"
#import "CallPart.h"
#import <AppKit/AppKit.h>

void selectPopFor(NSPopUpButton *p, NSButton *b, int n)
{
    [p selectItemAtIndex:n];
    [b setTitle:[p titleOfSelectedItem]];
//#warning PopUpConversion: This message should be sent to an NSPopUpButton, but is probably being sent to an NSPopUpList
//#warning PopUpConversion: Consider NSPopUpButton methods instead of using itemMatrix to access items in a pop-up list.
//  NSMatrix *m = [p itemMatrix];
//  [m selectCellAt: n : 0];
//  [b setTitle:[[m cellAt: n : 0] title]];
}


void selectPopNameAt(NSPopUpButton *b, NSString *n)
{
    if ([b itemWithTitle:n])
        [b selectItemWithTitle:n];
}


void selectPopNameFor(NSPopUpButton *p, NSButton *b, NSString *n)
{
    if ([p itemWithTitle:n])
        [b setTitle:n];
}

int popSelectionFor(NSPopUpButton *popup)
{
    return [popup indexOfSelectedItem];
}


NSString *popSelectionName(NSPopUpButton *b)
{
  return [b titleOfSelectedItem];
}


NSString *popSelectionNameFor(NSPopUpButton *popup)
{
  return [popup titleOfSelectedItem];
}

/* utilities and storage for tuning */

NSString *GeneralMidiSounds[128] = {
 /* Piano */
					@"Acoustic Grand Piano",
					@"Bright Acoustic Piano",
					@"Electric Grand Piano",
					@"Honky-tonk Piano",
					@"Electric Piano 1",
					@"Electric Piano 2",
					@"Harpsichord",
					@"Clavichord",
 /* Chromatic Percussion */
					@"Celesta",
					@"Glockenspiel",
					@"Music Box",
					@"Vibraphone",
					@"Marimba",
					@"Xylophone",
					@"Tubular Bells",
					@"Dulcimer",
 /* Organ */
					@"Drawbar Organ",
					@"Percussive Organ",
					@"Rock Organ",
					@"Church Organ",
					@"Reed Organ",
					@"Accordion",
					@"Harmonica",
					@"Tango Accordion",
 /* Guitar */
					@"Acoustic Guitar (nylon)",
					@"Acoustic Guitar (steel)",
					@"Electric Guitar (jazz)",
					@"Electric Guitar (clean)",
					@"Electric Guitar (muted)",
					@"Overdriven Guitar",
					@"Distortion Guitar",
					@"Guitar Harmonics",
 /* Bass */
					@"Acoustic Bass",
					@"Electric Bass (finger)",
					@"Electric Bass (pick)",
					@"Fretless Bass",
					@"Slap Bass 1",
					@"Slap Bass 2",
					@"Synth Bass 1",
					@"Synth Bass 2",
 /* Strings */
					@"Violin",
					@"Viola",
					@"Cello",
					@"Contrabass",
					@"Tremolo Strings",
					@"Pizzicato Strings",
					@"Orchestral Harp",
					@"Timpani",
 /* Ensemble */
					@"String Ensemble 1",
					@"String Ensemble 2",
					@"SynthStrings 1",
					@"SynthStrings 2",
					@"Choir Aahs",
					@"Voice Oohs",
					@"Synth Voice",
					@"Orchestra Hit",
 /* Brass */
					@"Trumpet",
					@"Trombone",
					@"Tuba",
					@"Muted Trumpet",
					@"French Horn",
					@"Brass Section",
					@"SynthBrass 1",
					@"SynthBrass 2",
 /* Reed */
					@"Soprano Sax",
					@"Alto Sax",
					@"Tenor Sax",
					@"Baritone Sax",
					@"Oboe",
					@"English Horn",
					@"Bassoon",
					@"Clarinet",
 /* Pipe */
					@"Piccolo",
					@"Flute",
					@"Recorder",
					@"Pan Flute",
					@"Blown Bottle",
					@"Shakuhachi",
					@"Whistle",
					@"Ocarina",
 /* Synth Lead */
					@"Lead 1 (square)",
					@"Lead 2 (sawtooth)",
					@"Lead 3 (calliope)",
					@"Lead 4 (chiff)",
					@"Lead 5 (charang)",
					@"Lead 6 (voice)",
					@"Lead 7 (fifths)",
					@"Lead 8 (bass+lead)",
 /* Synth Pad */
					@"Pad 1 (new age)",
					@"Pad 2 (warm)",
					@"Pad 3 (polysynth)",
					@"Pad 4 (choir)",
					@"Pad 5 (bowed)",
					@"Pad 6 (metallic)",
					@"Pad 7 (halo)",
					@"Pad 8 (sweep)",
 /* Synth Effects */
					@"FX 1 (rain)",
					@"FX 2 (soundtrack)",
					@"FX 3 (crystal)",
					@"FX 4 (atmosphere)",
					@"FX 5 (brightness)",
					@"FX 6 (goblins)",
					@"FX 7 (echoes)",
					@"FX 8 (sci-fi)",
 /* Ethnic */
					@"Sitar",
					@"Banjo",
					@"Shamisen",
					@"Koto",
					@"Kalimba",
					@"Bad pipe",
					@"Fiddle",
					@"Shanai",
 /* Percussive */
					@"Tinkle Bell",
					@"Agogo",
					@"Steel Drums",
					@"Woodblock",
					@"Taiko Drum",
					@"Melodic Tom",
					@"Synth Drum",
					@"Reverse Cymbal",
 /* Sound Effects */
					@"Guitar Fret Noise",
					@"Breath Noise",
					@"Seashore",
					@"Bird Tweet",
					@"Telephone Ring",
					@"Helicopter",
					@"Applause",
					@"Gunshot"
};

NSMutableArray *instlist = nil; 		/* a Array of CallInst */
NSMutableArray *scratchlist = nil;	/* used for partlist in case there is no view */
NSMutableArray *scrstylelist = nil;	/* used for scratchlist in case no view */
int partlistflag = 0;		/* whether partlist is valid */
int instlistflag = 0;		/* whether instlist is valid */
NSString *nullPart;		/* NXUniqueString("unassigned") */
NSString *nullInstrument;
NSString *nullFingerboard;
NSString *nullProgChange;

float notefreq[7] =
  {16.35125, 18.35375, 20.601875, 21.826875, 24.499375, 27.5, 30.868125};

/* no-op, flat, sharp, natural, doubleflat, doublesharp,
   3qflat, 1qflat, 3qsharp, 1qsharp, octave low, octave high */
float chromalter[NUMACCS + 2] =
  {1.0, 0.943849, 1.059491, 1.0, 0.943849 * 0.943849, 1.059491 * 1.059491,
     0.943849 * 0.971531, 0.971531, 1.059491 * 1.029302, 1.029302, 0.5, 2.0};
  
int power2[12] = {1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048};


/* creating tuning lists from handmade string */

NSMutableArray *listFromString(NSString *t)
{
    NSMutableArray *l;
    char oct=0, acc = 0, p=0, j;
    int i;
    NSString *ch;
    l = [[NSMutableArray alloc] init];
    for (j = 0; j < [t length]; j++) {
        ch = [t substringWithRange:NSMakeRange(j,1)];
        if ((i = [@"012345678" rangeOfString:ch].location) != NSNotFound) oct = i;
        else if ((i = [@"cdefgab" rangeOfString:ch].location) != NSNotFound) p = i;
        else if ((i = [@"!@#" rangeOfString:ch].location) != NSNotFound) acc = i;
        else if ([ch isEqualToString: @"."])
        {
            [l addObject: [[Course alloc] init: p : acc : oct]];
            acc = 0;
        }
        else
        {
            [l removeAllObjects];
            [l autorelease];
            return nil;
        }
      }
    return l;
}


/* various things to initialise */

extern void initPlayTables();

void initScratchlist()
{
    CallPart *theCallPart = [[CallPart alloc] init: nullPart : NULL : 1 : nullInstrument];
    if (scratchlist) [scratchlist release];
  scratchlist = [[NSMutableArray alloc] init];
  [scratchlist addObject: theCallPart];
  [theCallPart release];
}


void initScrStylelist()
{
    if (scrstylelist) [scrstylelist release];
    scrstylelist = [[NSMutableArray alloc] init];
}


static BOOL setInst(NSString *n, NSString *a, char tr, char ch, char tab, NSString *t, int snd)
{
    NSMutableArray *tl;
    tl = (t == NULL ? nil : listFromString(t));
    [instlist addObject: [[CallInst alloc] init: n : a : tr : ch : tab : snd : tl]];
    return YES;
}


void initTabTable()
{
  if (instlist != nil) return;  /* if so, defaults read it in first */
  instlist = [[NSMutableArray alloc] init];
  setInst(@"Piano", @"Pno", 0, 1, 0, nil, 0);
  setInst(@"Organ", @"Org.", 0, 1, 0, nil, 16);
  setInst(@"Harpsichord", @"Hpschd", 0, 1, 0, nil, 6);
  setInst(@"Celesta", @"Cel.", 0, 1, 0, nil, 8);
  setInst(@"Violin", @"Vln", 0, 1, 0, nil, 40);
  setInst(@"Viola", @"Vla", 0, 1, 0, nil, 41);
  setInst(@"Cello", @"C.", 0, 1, 0, nil, 42);
  setInst(@"Contrabass", @"B.", -12, 1, 0, nil, 43);
  setInst(@"Trumpet in Bb", @"Bb Trpt", -2, 1, 0, nil, 56);
  setInst(@"Trumpet in C", @"C Trpt", 0, 1, 0, nil, 56);
  setInst(@"Trombone", @"Tmbn", 0, 1, 0, nil, 57);
  setInst(@"Horn in F", @"Horn", -7, 1, 0, nil, 60);
  setInst(@"Tuba", @"Tuba", 0, 1, 0, nil, 58);
  setInst(@"Piccolo", @"Picc.", 12, 1, 0, nil, 74);
  setInst(@"Flute", @"Fl.", 0, 1, 0, nil, 73);
  setInst(@"Alto Flute in G", @"Alt.Fl.", -5, 1, 0, nil, 73);
  setInst(@"Clarinet in Bb", @"Bb Cl.", -2, 1, 0, nil, 71);
  setInst(@"Clarinet in A", @"A Cl.", -3, 1, 0, nil, 71);
  setInst(@"Clarinet in Eb", @"Eb Cl.", 3, 1, 0, nil, 71);
  setInst(@"Alto Clarinet in Eb", @"Alt.Cl.", -9, 1, 0, nil, 71);
  setInst(@"Bass Clarinet in Bb", @"B.Cl.", -2, 1, 0, nil, 71);
  setInst(@"Contrabass Clarinet in Bb", @"Bb Cnt.Cl.", -14, 1, 0, nil, 71);
  setInst(@"Contrabass Clarinet in Eb", @"Eb Cnt.Cl.", -21, 1, 0, nil, 71);
  setInst(@"Soprano Saxophone in Bb", @"Sop.Sax.", -2, 1, 0, nil, 64);
  setInst(@"Alto Saxophone in Eb", @"Alt.Sax.", -9, 1, 0, nil, 65);
  setInst(@"Tenor Saxophone in Bb", @"Ten.Sax.", -14, 1, 0, nil, 66);
  setInst(@"Baritone Saxophone in Eb", @"Bar.Sax.", -21, 1, 0, nil, 67);
  setInst(@"Bass Saxophone in Bb", @"Bass Sax.", -26, 1, 0, nil, 67);
  setInst(@"Oboe", @"Oboe", 0, 1, 0, nil, 68);
  setInst(@"English Horn in F", @"Cor Ang.", -7, 1, 0, nil, 69);
  setInst(@"Bassoon", @"Bsn", 0, 1, 0, nil, 70);
  setInst(@"Soprano", @"S.", 0, 1, 0, nil, 52);
  setInst(@"Alto", @"A.", 0, 1, 0, nil, 52);
  setInst(@"Tenor", @"T.", 0, 1, 0, nil, 52);
  setInst(@"Bass", @"B.", 0, 1, 0, nil, 52);
  setInst(@"Lute in G", @"Lute", 0, 1, 1, @"g4.d4.a3.f3.c3.g2.f2.e2.d2.c2.", 46);
  setInst(@"Theorbo in A", @"Thbo", 0, 1, 1, @"a3.e3.b3.g3.d3.a2.g2.f2.e2.d2.c2.b1.a1.g1.", 46);
  setInst(@"Cittern", @"Cit.", 0, 1, 1, @"e4.d4.g3.b3.", 6);
  setInst(@"Bandora", @"Bnda", 0, 1, 1, @"a3.e3.c3.g2.d2.c2.a1.g1.", 6);
  setInst(@"Lute in Dm", @"Lute", 0, 1, 1, @"f4.d4.a3.f3.d3.a2.g2.f2.e2.d2.c2.b1.a1.g1.", 46);
  setInst(@"Modern Guitar", @"Guit.", 0, 1, 1, @"e4.b3.g3.d3.a2.e2.", 46);
  setInst(@"Baroque Guitar", @"Guit.", 0, 1, 1, @"e4.b3.g3.d3.a2.", 46);
  setInst(@"Harp", @"Hp.", 0, 1, 0, nil, 46);
  setInst(@"Remote Synthesizer", @"Synth", 0, 1, 0, nil, 54);
  [instlist sortInstlist];
}



/* utilities for assaying fonts in selections */
/* give i votes for the NUMPOP first distinct f's and return the number of votes */

#define NUMPOP 16

static NSFont *fontlist[NUMPOP];
static int fontcount[NUMPOP];


void initVotes()
{
  int i;
  for (i = 0; i < NUMPOP; i++)
  {
    fontlist[i] = nil;
    fontcount[i] = 0;
  }
}


int votesFor(NSFont *f, int i)
{
  int j;
  if (f == nil) return 0;
  for (j = 0; j < NUMPOP; j++)
  {
    if (f == fontlist[j]) return (fontcount[j] += i);
  }
  if (i) for (j = 0; j < NUMPOP; j++)
  {
    if (fontlist[j] == nil)
    {
      fontlist[j] = f;
      fontcount[j] = i;
      return i;
    }
  }
  return 0;
}


int multVotes()
{
  int i, a = 0;
  for (i = 0; i < NUMPOP; i++)
  {
    if (fontcount[i]) a++;
    if (a > 1) return 1;
  }
  return 0;
}


NSFont *mostVotes()
{
  int i, k = 0;
  NSFont *f = nil;
  for (i = 0; i < NUMPOP; i++)
  {
    if (fontcount[i] > k)
    {
      f = fontlist[i];
      k = fontcount[i];
    }
  }
  return f;
}


/* used by inspectors for assaying the selection list */

int acount[NUMATTR], facount[NUMATTR], aval[NUMATTR], aacount[NUMATTR];
float  faval[NUMATTR];
NSString *aaval[NUMATTR];


void initassay()
{
  int i;
  for (i = 0; i < NUMATTR; i++)
  {
    acount[i] = 0;
    facount[i] = 0;
    aacount[i] = 0;
  }
}


void assay(int i, int val)
{
  if (acount[i] == 0)
  {
    aval[i] = val;
    acount[i] = 1;
  }
  else if (aval[i] == val) acount[i]++;
}


void assayAsFloat(int i, float val)
{
  if (facount[i] == 0)
  {
    faval[i] = val;
    facount[i] = 1;
  }
  else if (faval[i] == val) facount[i]++;
}


void assayAsAtom(int i, NSString *val)
{
  if (aacount[i] == 0)
  {
    aaval[i] = val;
    aacount[i] = 1;
  }
    else if ([aaval[i] isEqualToString: val]) aacount[i]++;
}


void clearMatrix(NSMatrix *p)
{
#if (NS_VERSION < 3)
  [p allowEmptySel: YES];
#else
  [p setAllowsEmptySelection:YES];
#endif
  [p selectCellAtRow:-1 column:-1];
}



/* given a figure string and a line spacing, find height of figure */

float figHeight(unsigned char *s, float n)
{
  unsigned char c;
  float r = 0;
  while (c = *s++)
  {
    if (isedbrack(c))
    {
      /* do something here */
    
      /* do something here */
    }
    else if (c == '1')
    {
      if (*s != '\0') ++s;
      r += n;
    }
    else if (c == ' ') r += n;
    else if (isaccident(c))
    {
      c = *s;
      if (c == '3')
      {
        ++s;
        r += n;
      }
      else if (c == '\0') r += n;
    }
    else r += n;
  }
  return r;
}


/* NSArray l contains things of which to find endpoints */

BOOL findEndpoints(NSMutableArray *l, id *n0, id *n1)
{
  int i, bk = 0;
  float minx, maxx;
  StaffObj *q;
  int k = [l count];
  minx = MAXFLOAT;
  maxx = MINFLOAT;
  *n0 = nil;
  *n1 = nil;
  for (i = 0; i < k; i++)
  {
    q = [l objectAtIndex:i];
    if (ISASTAFFOBJ(q))
    {
      if (q->x < minx)
      {
        *n0 = q;
	minx = q->x;
      }
      if (q->x > maxx)
      {
        *n1 = q;
	maxx = q->x;
      }
      ++bk;
    }
  }
  return (minx < MAXFLOAT && maxx > MINFLOAT && *n0 != *n1);
}

/* pass back rect enclosing points */

void getRegion(NSRect *r, const NSPoint *p1, const NSPoint *p2)
{
  r->size.width = p1->x - p2->x;
  r->size.height = p1->y - p2->y;
  if (r->size.width < 0.0)
  {
    r->origin.x = p2->x + r->size.width;
    r->size.width = ABS(r->size.width);
  }
  else r->origin.x = p2->x;
  if (r->size.height < 0.0)
  {
    r->origin.y = p2->y + r->size.height;
    r->size.height = ABS(r->size.height);
  } else r->origin.y = p2->y;
}


/* Pass back a rectangle enclosing list of items */

void listBBox(NSRect *b, NSMutableArray *l)
{
  int k;
  Graphic *g;
  k = [l count];
  *b = NSZeroRect;
  while (k--)
  {
    g = [l objectAtIndex:k];
    *b  = NSUnionRect((g->bounds) , *b);
  }
}


/*  The BB routines are meant to be fast "message unrolled" versions */

static void doList(NSRect *b, NSMutableArray *pl)
{
  Graphic *p;
  int pk;
  if (pl != nil && (pk = [pl count]))
  {
    while (pk--)
    {
      p = [pl objectAtIndex:pk];
      *b  = NSUnionRect((p->bounds) , *b);
    }
  }
}

static void doHandList(NSRect *b, NSMutableArray *pl)
{
  Graphic *p;
  NSRect h;
  int pk;
  h = NSZeroRect;
  if (pl != nil && (pk = [pl count]))
  {
    while (pk--)
    {
      p = [pl objectAtIndex:pk];
      *b  = NSUnionRect((p->bounds) , *b);
      if ([p getHandleBBox: &h]) *b  = NSUnionRect(h , *b);
    }
  }
}

static void doHangers(NSRect *b, NSMutableArray *pl)
{
  Graphic *p;
  int pk;
  if (pl != nil && (pk = [pl count]))
  {
    while (pk--)
    {
      p = [pl objectAtIndex:pk];
      *b  = NSUnionRect((p->bounds) , *b);
      doList(b, p->enclosures);
    }
  }
}

static void doHandHangers(NSRect *b, NSMutableArray *pl)
{
  Graphic *p;
  NSRect h;
  int pk;
  h = NSZeroRect;
  if (pl != nil && (pk = [pl count]))
  {
    while (pk--)
    {
      p = [pl objectAtIndex:pk];
      *b  = NSUnionRect((p->bounds) , *b);
      if ([p getHandleBBox: &h]) *b  = NSUnionRect(h , *b);
      doHandList(b, p->enclosures);
    }
  }
}


/* pass back BB of an object and its hangers and verses */

void graphicBBox(NSRect *b, Graphic *g)
{
  *b = g->bounds;
  doList(b, g->enclosures);
  if (ISASTAFFOBJ(g))
  {
    doHangers(b, ((StaffObj *)g)->hangers);
    doHangers(b, ((StaffObj *)g)->verses);
  }
}


/* bbox of list of objects, hangers, verses */

void graphicListBBox(NSRect *b, NSMutableArray *l)
{
  int k;
  StaffObj *g;
  k = [l count];
  *b = NSZeroRect;
  while (k--)
  {
    g = [l objectAtIndex:k];
    *b  = NSUnionRect((g->bounds) , *b);
    doList(b, g->enclosures);
    if (ISASTAFFOBJ(g))
    {
      doHangers(b, ((StaffObj *)g)->hangers);
      doHangers(b, ((StaffObj *)g)->verses);
    }
  }
}


/* like above, but include handles */

void graphicHandListBBox(NSRect *b, NSMutableArray *l)
{
  int k;
  StaffObj *g;
  NSRect h;
  k = [l count];
  *b = NSZeroRect;
  h = NSZeroRect;
  while (k--)
  {
    g = [l objectAtIndex:k];
    *b  = NSUnionRect((g->bounds) , *b);
    if ([g getHandleBBox: &h]) *b  = NSUnionRect(h , *b);
    doHandList(b, g->enclosures);
    if (ISASTAFFOBJ(g))
    {
      doHandHangers(b, ((StaffObj *)g)->hangers);
      doHandHangers(b, ((StaffObj *)g)->verses);
    }
  }
}


/* bbox of list of objects and hangers, but exclude ex and verses from consideration */

void graphicListBBoxEx(NSRect *b, NSMutableArray *l, Graphic *ex)
{
  int k, pk, ek;
  StaffObj *g;
  Graphic *p;
  NSMutableArray *pl, *el;
  k = [l count];
  *b = NSZeroRect;
  while (k--)
  {
    g = [l objectAtIndex:k];
      if (g != (StaffObj *)ex) *b  = NSUnionRect((g->bounds) , *b); //sb: typed the (StaffObj *) for compiler warnings
    pl = g->enclosures;
    if (pl != nil && (pk = [pl count]))
    {
      while (pk--)
      {
	p = [pl objectAtIndex:pk];
        if (p != ex) *b  = NSUnionRect((p->bounds) , *b);
      }
    }
    if (ISASTAFFOBJ(g))
    {
      pl = g->hangers;
      if (pl != nil &&  (pk = [pl count]))
      {
	while (pk--)
	{
	  p = [pl objectAtIndex:pk];
          if (p != ex) *b  = NSUnionRect((p->bounds) , *b);
	  el = p->enclosures;
	  if (el != nil && (ek = [el count]))
          {
            while (ek--)
            {
              p = [el objectAtIndex:ek];
              if (p != ex) *b  = NSUnionRect((p->bounds) , *b);
            }
          }
	}
      }
    }
  }
}

#define ISVOLTA(p) (TYPEOF(p) == GROUP && SUBTYPEOF(p) == GROUPVOLTA)

void graphicListBBoxExVolta(NSRect *b, NSMutableArray *l)
{
  int k, pk, ek;
  StaffObj *g;
  Graphic *p;
  NSMutableArray *pl, *el;
  k = [l count];
  *b = NSZeroRect;
  while (k--)
  {
    g = [l objectAtIndex:k];
    if (!ISVOLTA(g)) *b  = NSUnionRect((g->bounds) , *b);
    pl = g->enclosures;
    if (pl != nil && (pk = [pl count]))
    {
      while (pk--)
      {
	p = [pl objectAtIndex:pk];
        if (!ISVOLTA(p)) *b  = NSUnionRect((p->bounds) , *b);
      }
    }
    if (ISASTAFFOBJ(g))
    {
      pl = g->hangers;
      if (pl != nil &&  (pk = [pl count]))
      {
	while (pk--)
	{
	  p = [pl objectAtIndex:pk];
          if (!ISVOLTA(p)) *b  = NSUnionRect((p->bounds) , *b);
	  el = p->enclosures;
	  if (el != nil && (ek = [el count]))
          {
            while (ek--)
            {
              p = [el objectAtIndex:ek];
              if (!ISVOLTA(p)) *b  = NSUnionRect((p->bounds) , *b);
            }
          }
	}
      }
    }
  }
}


/* note body shapes for each time value */

float stemthicks[3] = {0.8, 0.6, 0.4};

float ostemthicks[3] = {1.0, 0.75, 0.5};

char stemlens[2][3] =
{
  { 27, 20, 13},
  { 28, 21, 14}
};

char stemshorts[3] = {23, 17, 11};

char tabstemlens[3] = {20, 15, 10};

float beamthick[3] = {4.0, 3.0, 2.0};
float beamsep[3] = {2.0, 2.0, 2.0};

unsigned char bodies[4][10] =
{
  {SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_hnote, SF_wnote, SF_breve, CH_longa},
  {CH_oqnote, CH_oqnote, CH_oqnote, CH_oqnote, CH_oqnote, CH_oqnote, CH_ohnote, CH_ownote, CH_longa, CH_longa},
  { 152, 146, 148, 147, 140, 143, 60, CH_ownote, CH_longa, CH_longa}, /* line flags */
  { 141, 136, 139, 130, 138, 131, 60, CH_ownote, CH_longa, CH_longa} /* curve flags */
};

unsigned char headchars[NUMHEADS][10] =
{
  {SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_hnote, SF_wnote, SF_breve, CH_longa},
  {CH_oqnote, CH_oqnote, CH_oqnote, CH_oqnote, CH_oqnote, CH_oqnote, CH_ohnote, CH_ownote, CH_longa, CH_longa},
  {SF_harm, SF_harm, SF_harm, SF_harm, SF_harm, SF_harm, SF_harm, SF_harm, SF_harm, SF_harm},
  {SF_vox, SF_vox, SF_vox, SF_vox, SF_vox, SF_vox, SF_vox, SF_vox, SF_vox, SF_vox},
  {SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_hnote, SF_wnote, SF_breve, CH_longa},
  {CH_ocqnote, CH_ocqnote, CH_ocqnote, CH_ocqnote, CH_ocqnote, CH_ocqnote, CH_ochnote, CH_ocwnote, CH_clonga, CH_clonga},
  {SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_qnote, SF_hnote, SF_wnote, SF_breve, CH_longa}
    
};


unsigned char bodyfont[4][10] =
{
  {1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
};

unsigned char headfont[NUMHEADS][10] =
{
  {1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  {1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
  {1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
  {1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  {1, 1, 1, 1, 1, 1, 1, 1, 1, 0}
};


unsigned char fullbody[2][10] =
{
  {SF_n128u, SF_n64u, SF_n32u, SF_n16u, SF_n8u, SF_n4u, SF_n2u, SF_wnote, SF_breve, 0},
  {SF_n128d, SF_n64d, SF_n32d, SF_n16d, SF_n8d, SF_n4d, SF_n2d, SF_wnote, SF_breve, 0}
};

/* shapeheads[tonic][time][stemdn] */

unsigned char shapeheads[4][10][2] =
{
  {{CH_shtrupcl, CH_shtrdncl}, {CH_shtrupcl, CH_shtrdncl}, {CH_shtrupcl, CH_shtrdncl}, {CH_shtrupcl, CH_shtrdncl}, {CH_shtrupcl, CH_shtrdncl}, {CH_shtrupcl, CH_shtrdncl}, {CH_shtrupop, CH_shtrdnop}, {CH_shtrupop, CH_shtrdnop}, {CH_shtrupop, CH_shtrdnop}, {CH_shtrupop, CH_shtrdnop}},
  {{SF_qnote, SF_qnote}, {SF_qnote, SF_qnote}, {SF_qnote, SF_qnote}, {SF_qnote, SF_qnote}, {SF_qnote, SF_qnote}, {SF_qnote, SF_qnote}, {SF_hnote, SF_hnote}, {SF_wnote, SF_wnote}, {SF_breve, SF_breve}, {CH_longa, CH_longa}},
  {{CH_shsqcl, CH_shsqcl}, {CH_shsqcl, CH_shsqcl}, {CH_shsqcl, CH_shsqcl}, {CH_shsqcl, CH_shsqcl}, {CH_shsqcl, CH_shsqcl}, {CH_shsqcl, CH_shsqcl}, {CH_shsqop, CH_shsqop}, {CH_shsqop, CH_shsqop}, {CH_shsqop, CH_shsqop}, {CH_shsqop, CH_shsqop}},
  {{CH_shdicl, CH_shdicl}, {CH_shdicl, CH_shdicl}, {CH_shdicl, CH_shdicl}, {CH_shdicl, CH_shdicl}, {CH_shdicl, CH_shdicl}, {CH_shdicl, CH_shdicl}, {CH_shdiop, CH_shdiop}, {CH_shdiop, CH_shdiop}, {CH_shdiop, CH_shdiop}, {CH_shdiop, CH_shdiop}}
};

unsigned char shapefont[4] = {0, 1, 0, 0};

unsigned char hasstem[10] =
{
  1, 1, 1, 1, 1, 1, 1, 0, 0, 1
};

unsigned char hasflag[10] = /* a 2 means flags that grow stemlen */
{
  2, 2, 2, 1, 1, 0, 0, 0, 0, 0
};

unsigned char numflags[10] =
{
  5, 4, 3, 2, 1, 0, 0, 0, 0, 0
};


/* flags, new and old */

/* m/o flag[upstem/dnstem][body] */

unsigned char mflag[2][5] =
{
  { 221, 219, 218, 216, 217 },
  { 215, 213, 214, 154, 150 }
};

char mflagoff[3][5] =
{
  {24, 20, 16, 12, 8},
  {18, 15, 12, 9, 6},
  {12, 10,  8,  6, 4}
};

unsigned char oflag[2][5] =
{
  { 244, 242, 243, 239, 240 },
  { 238, 236, 237, 231, 229 }
};

/* these tables use [stemlen<0][size] */

float noteoffset[3];	/* offset from nominal x */
float stemleft[2][3];	/* offset from nominal x */
float stemcentre[2][3];	/* offset from nominal x */
float stemright[2][3];	/* offset from nominal x */


float headwidth[3][NUMHEADS][10];	/* head width: [size][headtype][timecode] */
float halfwidth[3][NUMHEADS][10];	/* head half: [size][headtype][timecode] */
float stemdx[3][NUMHEADS][2][10][2];	/* [size][headtype][stemtype (only 0/1)][timecode][stemup] */
float stemdy[3][NUMHEADS][2][10][2];	/* [size][headtype][stemtype (only 0/1)][timecode][stemup] */
float flagdx[3][NUMHEADS][10][2];	/* [size][headtype][timecode][stemup] */

float stemyoff[NUMHEADS] = /* in nature units */
{
    2.0, 5.0, 0.0, 4.0, 0.0, 5.0, 0.0
};

BOOL stemxoff[NUMHEADS] =
{
    YES, NO, YES, YES, NO, NO, YES
};

/* init some useful tables for stem and beam x-offsets*/

int mfontid[3] = {FONTMUS, FONTSMUS, FONTHMUS};
int sfontid[3] = {FONTSON, FONTSSON, FONTHSON};

void muxlowInit()
{
  int i, j, sz, stype, stemup;
  float hw, dx, w, sdx, sdy, fdx=0.0;
  NSFont *f, *fh;
//  nullPart = NXUniqueString("unassigned");
//  nullInstrument = NXUniqueString("Piano");
//  nullFingerboard = NXUniqueString("Lute in G");
//  nullProgChange = NXUniqueString("Remote Synthesizer");
  nullPart = @"unassigned";
  nullInstrument = @"Piano";
  nullFingerboard = @"Lute in G";
  nullProgChange = @"Remote Synthesizer";

  initPlayTables();
  initTabTable();
  initScratchlist();
  initScrStylelist();
  for (sz = 0; sz <= 2; sz++)
  {
    musicFont[0][sz] = fontdata[mfontid[sz]];
    musicFont[1][sz] = fontdata[sfontid[sz]];
    f = musicFont[1][sz];
    hw = charhalfFGW(f, bodies[0][0]);
    dx = charFWX(f, SF_stemsp);
    noteoffset[sz] = hw;
    stemleft[0][sz] = -hw;
    stemcentre[0][sz] = -hw + 0.5 * stemthicks[sz];
    stemright[0][sz] = hw - dx;
    stemleft[1][sz] =  -hw + dx;
    stemcentre[1][sz] = -hw + dx + 0.5 * stemthicks[sz];
    stemright[1][sz] = hw;
    for (i = 0; i < NUMHEADS; i++)
    {
      for (j = 0; j < 10; j++)
      {
        fh = musicFont[headfont[i][j]][sz];
	w = charFGW(fh, headchars[i][j]);
        headwidth[sz][i][j] = w;
	hw = 0.5 * w;
	halfwidth[sz][i][j] = hw;
	for (stype = 0; stype <= 1; stype++)
	{
	  for (stemup = 0; stemup <= 1; stemup++)
	  {
	    if (stype == 0)
            {
              sdy = stemyoff[i] * pronature[sz];
              if (stemup)
              {
	        sdy = -sdy;
                if (j == 9)
	        {
	          sdx = hw - (0.5 * stemthicks[sz]);
	        }
                else if (stemxoff[i])
	        {
                  fdx = -hw + charFWX(f, SF_stemsp);
	          sdx = fdx + 0.5 * stemthicks[sz];
	        }
	        else
	        {
	          sdx = 0.0;
	          fdx = -0.5 * stemthicks[sz];
	        }
              }
              else
              {
                if (j == 9)
	        {
                  sdx = -hw + 0.5 * stemthicks[sz];
	        }
                else if (stemxoff[i])
	        {
                  fdx = -hw;
                  sdx = fdx + 0.5 * stemthicks[sz];
	        }
	        else
	        {
	          sdx = 0.0;
	          fdx = -0.5 * stemthicks[sz];
	        }
              }
	      flagdx[sz][i][j][stemup] = fdx;
            }
            else
            {
              if (stemup)
              {
                sdx = (j == 9) ? hw - (0.5 * ostemthicks[sz]) : 0.0;
                sdy = -hw;
              }
              else
              {
                sdx = (j == 9) ? -hw + (0.5 * ostemthicks[sz]) : 0.0;
                sdy = hw;
              }
	    }
	    stemdx[sz][i][stype][j][stemup] = sdx;
	    stemdy[sz][i][stype][j][stemup] = sdy;
	  }
        }
      }
    }
  }
}


/* safely getting at spacing, frequently needed */

int getSpacing(Staff *s)
{
  if (s == nil) return 4;
  else if (TYPEOF(s) == STAFF) return s->flags.spacing;
  else return 4;
}


int getLines(Staff *s)
{
  if (s == nil) return 5;
  else if (TYPEOF(s) == STAFF) return s->flags.nlines;
  else return 5;
}


/*
  Given any int indicating an +- offset from middle C,
  return its note name 0..6
*/

static char nnback[7] = {0, 6, 5, 4, 3, 2, 1};

int noteNameNum(int i)
{
  if (i == 0) return(0);
  else if (i > 0) return(i % 7);
  else return( nnback[(-i) % 7] );
}

int noteNameNumRelC(int pos, int mc)
{
  int i = mc - pos;
  if (i == 0) return(0);
  else if (i > 0) return(i % 7);
  else return( nnback[(-i) % 7] );
}

void getNumOct(int pos, int mc, int *num, int *oct)
{
  int j = mc - pos;
  if (j == 0)
  {
    *num = 0;
    *oct = 4 + j / 7;
  }
  else if (j > 0)
  {
    *num = j % 7;
    *oct = 4 + j / 7;
  }
  else
  {
    *num = nnback[(-j) % 7];
    *oct = 4 + (-((-(j + 1)) / 7)) - 1;
  }
}



/* computing tick factors through nested tuples and tremolos */

float tickNest(NSMutableArray *l, float t)
{
  int k = [l count];
  Hanger *h;
  while (k--)
  {
    h = [l objectAtIndex:k];
    t = [h modifyTick: t];
  }
  return t;
}

/* return an x-spacing in notewidth units based on duration in ticks */

float ctimex(float dur)
{
  float s, k, b, d;
  d = dur / 128.0;
  if (d < 0.5) s = 13.714 * d + 0.7857;
  else
  {
    k = 7.0;
    b = 0.222;
    s = k * pow(d, b);
  }
  return s;
}

/* ticks for body and dots.  dot=3 means the new :-notation */

int tickval(int b, int d)
{
  int t, n;
  n = power2[b];
  if (d == 3)
  {
    n += (n >> 1);
    n += (n >> 1);
  }
  else
  {
    t = n;
    while (d)
    {
      n += (t >> d);
      --d;
    }
  }
  return(n);
}


/* calculate stem length */

int getstemlen(int body, int sz, int style, int su, int p, int s)
{
  int r=0;
  if (!(hasstem[body])) return(su ? -1 : 1);
  if (style == 0)
  {
    if (su)
    {
      if (p > 11) r = s * (p - 4);
      else
      {
        r = (p <= 3) ? stemshorts[sz] : stemlens[0][sz];
	if (hasflag[body] == 2) r += (3 - body) * s;
      }
    }
    else
    {
      if (p < -2) r = s * (4 - p);
      else
      {
        if (hasflag[body])
	{
	  r = stemlens[0][sz] + (s >> 1);
	  if (hasflag[body] == 2) r += (3 - body) * s;
	}
	else r = (p >= 5) ? stemshorts[sz] :  stemlens[0][sz];
      }
    }
  }
  else if (style == 1)
  {
    r = stemlens[1][sz];
    if (hasflag[body] == 2) r += (3 - body) * s;
  }
  return( su ? -r : r);
}


/* draw ledger lines (used for notes, neumes, ranges, keysigs, guides, squarenotes) */

float ledgethicks[3] = {0.8, 0.6, 0.4};
float ledgedxs[3] = {3.0, 2.0, 1.5};

void drawledge(float x, float y, float dx, int sz, int p, int nlines, int spacing, int mode)
{
  int i;
  float ly;
  BOOL f = NO;
  dx += ledgedxs[sz];
  if (p < -1)
  {
    for (i = -2; i >= p; i -= 2)
    {
      ly = y + spacing * i;
      cmakeline(x - dx, ly, x + dx, ly, mode);
      f = YES;
    }
  }
  else if (p >= (nlines << 1))
  {
    for (i = (nlines << 1); i <= p; i += 2)
    {
      ly = y + spacing * i;
      cmakeline(x - dx, ly, x + dx, ly, mode);
      f = YES;
    }
  }
  if (f) cstrokeline(ledgethicks[sz], mode);
}


/*
  Draw stem and flags.  x is the beat line.
  Depends on head style and stem style.  Now table driven.
  Note exceptions for longas, because the char ought to be centred in the
  font but isn't.
*/

void drawgrace(float x, float y, int body, float sl, int sz, int btype, int stype, int dflag)
{
  float nx, dy, gy, dx;
  int stemup = (sl < 0);
  dy = halfwidth[sz][0][4];
  gy = y + 0.5 * sl;
  if (stemup)
  {
    cline(x, gy + dy, x + 3 * dy, gy - 2 * dy, stemthicks[sz], dflag);
  }
  else
  {
    nx = x + stemdx[sz][btype][stype][body][stemup];
    dx = 0.5 * dy;
    cline(nx - dx, gy + dy, nx + 3 * dy - dx, gy - 2 * dy, stemthicks[sz], dflag);
  }
}


void drawstem(float x, float y, int body, float sl, int sz, int btype, int stype, int dflag)
{
  float nx, ny, dy = y + sl;
  float sdx, sdy, fdx;
  int stemup = (sl < 0);
  switch(stype)
  {
    case 0:
        sdx = stemdx[sz][btype][stype][body][stemup];
        sdy = stemdy[sz][btype][stype][body][stemup];
        fdx = flagdx[sz][btype][body][stemup];
        nx = x + sdx;
        ny = y + sdy;
        cline(nx, ny, nx, dy, stemthicks[sz], dflag);
        if (hasflag[body])
      {
        ny = mflagoff[sz][body];
	if (!stemup) ny = -ny;
        drawCharacterInFont(x + fdx, dy + ny, mflag[(!stemup)][body], musicFont[0][sz], dflag);
      }
      break;
    case 1:
      nx = x + stemdx[sz][btype][stype][body][stemup];
      ny = y + stemdy[sz][btype][stype][body][stemup];
      cline(nx, ny, nx, dy, ostemthicks[sz], dflag);
      if (hasflag[body]) drawCharacterInFont(x, dy, oflag[(!stemup)][body], musicFont[0][sz], dflag);
      break;
    case 2:
    case 3:
      cline(x, y, x, dy, ostemthicks[sz], dflag);
      drawCharacterInFont(x, dy, bodies[stype][body], musicFont[0][sz], dflag);
      break;
  }
}


/*
  Draw a dot (or dots).
  A function of position, stemlength, beamed, flagged, style, etc.
*/

/* code: 0=after head; 1=after stem; 2=after flag; 3=default modern; 4:after flag */
unsigned char dotcode[4][10] =
{
  {3, 3, 3, 3, 3, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  {2, 2, 2, 2, 2, 4, 1, 0, 0, 0},
  {2, 2, 2, 2, 2, 4, 1, 0, 0, 0}
};

unsigned char dotchar[NUMHEADS] = {SF_dot, CH_dot, SF_dot, SF_dot, SF_dot, CH_dot, SF_dot};
unsigned char dotfont[NUMHEADS] = {1, 0, 1, 1, 1, 0, 1};


float getdotx(int sz, int btype, int stype, int body, int beamed, int stemup)
{
  int ch;
  NSFont *df, *bf;
  float dw, dx=0.0;
  ch = dotchar[btype];
  df = musicFont[dotfont[btype]][sz];
  dw = charFGW(df, ch);
  switch (dotcode[stype][body])
  {
    case 0:
      dx = halfwidth[sz][btype][body] + dw;
      break;
    case 1:
      dx = 0.5 * stemthicks[sz] + dw;
      break;
    case 2:
      bf = musicFont[bodyfont[stype][body]][sz];
      dx = charFURX(bf, bodies[stype][body]) + 0.75 * dw;
      break;
    case 3:
      dx = halfwidth[sz][btype][body];
      if (!beamed && stemup) dx += charFURX(musicFont[0][sz], mflag[0][body]);
      if (body == 4) dx -= 0.5 * dw;
      dx += dw;
      break;
    case 4:
      bf = musicFont[bodyfont[stype][body]][sz];
      dx = charFURX(bf, bodies[stype][body]);
      break;
  }
  return dx;
}


void drawnotedot(int sz, float x, float y, float dy, float sp, int btype, int dot, int ed, int mode)
{
  float di;
  int i, ch;
  NSFont *df;
  ch = dotchar[btype];
  df = musicFont[dotfont[btype]][sz];
  di = 2.0 * charFGW(df, ch);
  if (dot == 3)
  {
    drawCharacterInFont(x, y + (dy * sp), ch, df, mode);
    drawCharacterInFont(x, y + ((dy + 2) * sp), ch, df, mode);
  }
  else
  {
    y += (dy * sp);
    for (i = 0; i < dot; i++) drawCharacterInFont(x + (di * i), y, ch, df, mode);
  }
}


void drawdot(int sz, float hw, float x, float y, int body, int btype, int stype, int dot, int ed, int stemup, int b, int mode)
{
  if (dot == 0) return;
  x += getdotx(sz, btype, stype, body, b, stemup);
  drawnotedot(sz, x, y, 0, 0, btype, dot, ed, mode);
}



/* Draw easy dots */

unsigned char rdotchar[2] = {CH_dot, SF_dot};

void restdot(int sz, float dx, float x, float y, float dy, int dot, int code, int mode)
{
  int i, ch;
  float di, dw;
  NSFont *f;
  if (dot == 0) return;
  ch = rdotchar[code];
  f = musicFont[!code][sz];
  dw = charFGW(f, ch);
  x += dx + 1.75 * dw;
  di = 2.0 * dw;
  if (dot == 3)
  {
    drawCharacterInFont(x, y, ch, f, mode);
    drawCharacterInFont(x, y + dy, ch, f, mode);
  }
  else for (i = 0; i < dot; i++) drawCharacterInFont(x + (di * i), y, ch, f, mode);
}


/*  Draw a note body and stem. See whether to use standard note chars. */

BOOL centhead[NUMHEADS] = {1, 0, 1, 1, 1, 0, 1}; /* whether to offset head */

int modeinvis[5] = {0, 2, 2, 2, 4};

/* sid is defined only when bt == 6 */

void drawhead(float x, float y, int bt, int body, int sid, int su, int sz, int m)
{
  if (bt == 6) drawCharacterInFont(x, y, shapeheads[sid][body][!su], musicFont[shapefont[sid]][sz], m);
  else if (bt == 4)
  {
    if (m != 0) return;
    drawCharacterInFont(x, y, headchars[0][body], musicFont[headfont[0][body]][sz], 0);
  }
  else drawCharacterInFont(x, y, headchars[bt][body], musicFont[headfont[bt][body]][sz], m);
}


void drawnote(int sz, float hw, float x, float y, int body, int btype, int stype, int sid, int b, float sl, int nos, int g, int dflag)
{
  float nx;
  BOOL quick = NO;
  nx = x;
  if (centhead[btype] || headchars[btype][body] == CH_longa) nx -= hw;
  if (!nos && !b && !btype && !stype)
  {
    quick = YES;
    if (fullbody[0][body] && TOLFLOATEQ(sl, -stemlens[0][sz], 0.5))
      drawCharacterInFont(nx, y, fullbody[0][body], musicFont[1][sz], dflag);
    else if (fullbody[1][body] && TOLFLOATEQ(sl, stemlens[0][sz], 0.5))
      drawCharacterInFont(nx, y, fullbody[1][body], musicFont[1][sz], dflag);
    else quick = NO;
  }
  if (quick)
  {
    if (g) drawgrace(x, y, body, sl, sz, btype, stype, dflag);
  }
  else
  {
      drawhead(nx, y, btype, body, sid, (sl < 0), sz, dflag);
    if (!nos && !b && hasstem[body])
    {
      drawstem(x, y, body, sl, sz, btype, stype, dflag);
      if (g) drawgrace(x, y, body, sl, sz, btype, stype, dflag);
    }
  }
}


/*
  Display single notes from data for special purposes:
  tablature, unequal note group, metronome marks, etc.
*/

void csnote(float cx, float cy, float sl, int body, int dot, int sz, int btype, int stype, int m)
{
    float hw = halfwidth[sz][btype][body];
    drawnote(sz, hw, cx, cy, body, btype, stype, 1, 0, sl, 0, 0, m);
    if (dot)
      {
        if (btype == 4) cy += 0.5 * sl;
        drawdot(sz, hw, cx, cy, body, btype, stype, dot, 0, (sl < 0), 0, m);
      }
}
