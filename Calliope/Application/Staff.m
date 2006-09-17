/* $Id$ */
#import <AppKit/AppKit.h>
#import "StaffObj.h"
#import "Verse.h"
#import "Staff.h"
#import "StaffTrans.h"
#import "System.h"
#import "Clef.h"
#import "KeySig.h"
#import "Rest.h"
#import "GNote.h"
#import "Tablature.h"
#import "Bracket.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "GVFormat.h"
#import "Page.h"
#import "CallPart.h"
#import "Barline.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "FileCompatibility.h"

// TODO Arrgh, so they should be subclasses!!!
/* staff subtypes are 0=staff, 1=tablature, 2=chant */

extern int staffFlag; /* for my own use in doing screen grabs */

extern float brackwidth[3];


/* extra blank space above staff in ss units. */

float staffheads[3] = {3.0, 4.0, 2.0};

/* thickness of staff lines [subtype][size] */

float staffthick[3][3] =
{
  {0.5625, 0.421875, 0.28125},
  {0.6, 0.45, 0.3},
  {0.8, 0.6, 0.4}
};


/* pixels between staff positions [subtype] [size] */

int staffspace[3][3] =
{
  {4, 3, 2},  /* this line must equal the nature size constant */
  {6, 5, 3},
  {6, 5, 3}
};


@implementation Staff

+ (void)initialize
{
    if (self == [Staff class]) {
	[Staff setVersion: 9];	/* class version, see read: */ /*sb: bumped up to 9 for OS conversion */
    }
}

- init
{
    self = [super init];
    if(self != nil) {
	gFlags.type = STAFF;
	flags.subtype = 0;
	flags.nlines = 5;
	flags.spacing = staffspace[0][0];
	gFlags.size = 0;
	flags.haspref = 0;
	flags.hidden = 0;
	y = 0.0;
	voffa = 0;
	voffb = 0;
	vhigha = 0.0;
	vhighb = 0.0;
	pref1 = pref2 = 0.0;
	topmarg = staffheads[0];
	botmarg = 0.0;
	if (notes) 
	    [notes autorelease];
	notes = [[NSMutableArray alloc] init];
	if (part) 
	    [part autorelease];
	part = nullPart;
    }
    return self;
}

- (void) setSystem: (System *) newSystem
{
    mysys = newSystem; /* backpointer. We don't want to autorelease this, in case there is a loop */
}

- sysInvalid
{
  return [mysys sysInvalid];
}


- mark
{
  int k;
  StaffObj *p;
  gFlags.morphed = 1;
  k = [notes count];
  while (k--)
  {
    p = [notes objectAtIndex:k];
    p->gFlags.morphed = 1;
    [p markHangers];
  }
  return self;
}


- (void)moveBy:(float)dx :(float)dy
{
  int k;
  if (!gFlags.morphed) return;
  y += dy;
  k = [notes count];
  while (k--) [[notes objectAtIndex:k] moveBy:dx :dy];
  [super moveBy:dx :dy];
}


/* find out how much space the notes need above the staff.  Note: vhigha needs to be valid */

- (float) getHeadroom
{
  int i, k;
  StaffObj *p;
  float py, miny;
  miny = y - vhigha;
  k = [notes count];
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if (!ISINVIS(p) && [p validAboveBelow: 1])
    {
      py = [p boundAboveBelow: 1];
      if (py < miny) miny = py;
    }
  }
  return (y - miny);
}


/* called before measurestaff, but only when doing a real formatting */

- trimVerses
{
  int k = [notes count];
  while (k--) [(StaffObj *)[notes objectAtIndex:k] trimVerses];
  return self;
}


/*
  Measuring must happen before resetting because vhigha needs to be known before y is found.
  the globals store values between measuring and resetting.
*/

#define TEXTLEADING 0	/* leading between underlay lines */

float textoff[2], baselines[2][MAXTEXT];

- measureStaff
{
  StaffObj *p;
  Verse *v;
  NSFont *f;
  int i, j, k, n, vk, ibl, jbl, vp;
  float maxy, miny, ysize, texta[2][MAXTEXT];
  float textd[2][MAXTEXT], vdepth[2], py=0.0, t=0.0, defFA=0.0, defFD=0.0;
  BOOL hasfig, mod, textau[2][MAXTEXT], textdu[2][MAXTEXT];
  /* find staffobj extents and verse ascent/descent */
  k = [notes count];
  maxy = [self yOfBottom] + 2 * flags.spacing;
  miny = y - 2 * flags.spacing;
  hasfig = NO;
  ysize = 0.0;
  for (i = 0; i <= 1; i++) for (j = 0; j < MAXTEXT; j++)
  {
    texta[i][j] = textd[i][j] = 0.0;
    textau[i][j] = textdu[i][j] = NO;
  }
// NSLog(@"measureStaff: %d\n", [self myIndex]);
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if ([p reCache: y : flags.spacing]) [p recalc];
    if (ISATIMEDOBJ(p) && !ISINVIS(p))
    {
      if ([p validAboveBelow: 0])
      {
        py = [p boundAboveBelow: 0];
        if (py > maxy)
	{
	  maxy = py;
//	  NSLog(@"  obj %d increases maxy to %f\n",  i, maxy);
	}
      }
      if ([p validAboveBelow: 1])
      {
        py = [p boundAboveBelow: 1];
        if (py < miny)
	{
	  miny = py;
//	  NSLog(@"  obj %d reduces miny to %f\n", i, miny);
	}
      }
    }
    if ([p hasAnyVerse])
    {
      n = 0;
      vk = [p->verses count];
      vp = p->versepos;
      for (j = 0; j < vk; j++)
      {
	v = [p verseOf: j];
        if (!ISINVIS(v))
        {
          v->vFlags.line = n;
          ibl = (n < vp);
          jbl = (ibl ? n : n - vp);
	  if ([v isFigure])
	  {
	    hasfig = YES;
	    f = v->font;
            t = fontAscent(f);
	    if (ibl)
	    {
	      /* figures above are in the ascent */
	      py = figHeight(v->data, t);
              if (py > texta[ibl][jbl]) { texta[ibl][jbl] = py; textau[ibl][jbl] = YES; }
              py = -fontDescent(f);
              if (py > textd[ibl][jbl]) { textd[ibl][jbl] = py; textdu[ibl][jbl] = YES; }
	    }
	    else
	    {
	      /* figures below are in the descent  */
              py = t;
              if (py > texta[ibl][jbl]) { texta[ibl][jbl] = py; textau[ibl][jbl] = YES; }
	      py = figHeight(v->data, t) - t;
              if (py > textd[ibl][jbl]) { textd[ibl][jbl] = py; textdu[ibl][jbl] = YES; }
	    }
	  }
          else if ([p hasVerseText: j])
          {
            f = v->font;
              py = fontAscent(f);
            if (py > texta[ibl][jbl]) { texta[ibl][jbl] = py; textau[ibl][jbl] = YES;}
            py = -fontDescent(f);
            if (py > textd[ibl][jbl]) { textd[ibl][jbl] = py; textdu[ibl][jbl] = YES; }
          }
          ++n;
        }
      }
    }
  }
  /* given ascent/descents, find the baselines and the amount of space taken up */
      defFA = fontAscent(fontdata[FONTTEXT]);
      defFD = -fontDescent(fontdata[FONTTEXT]);
      for (i = 0; i <= 1; i++)
  {
    vdepth[i] = 0;
    mod = NO;
    py = ysize = 0.0;
    for (j = 0; j < MAXTEXT; j++)
    {
      if (!textau[i][j]) py += defFA;
      else
      {
        py += texta[i][j];
        ysize += texta[i][j];
      }
      baselines[i][j] = py;
      if (!textdu[i][j]) py += defFD;
      else
      {
        py += textd[i][j];
        ysize += textd[i][j] + TEXTLEADING;
        mod = 1;
      }
      py += TEXTLEADING;
    }
    if (mod) ysize -= TEXTLEADING;
    vdepth[i] = ysize;
  }
  /* calculate the offsets and space taken */
  textoff[0] = maxy + (2 * flags.spacing * voffb) - y;
  textoff[1] = y - miny + (2 * flags.spacing * voffa);
  vhighb = vdepth[0] + textoff[0];
  vhigha = vdepth[1] + textoff[1];
  return self;
}


/*
  Move staff and contents to reflect new y.
  Must take several passes through the staff to get it right.
  Caller must have called measureStaff first.
  Caller must recalc the staff to get new bounds.
*/

- resetStaff: (float) newYPosition
{
  StaffObj *p;
  Verse *v;
  int i, j, k, n, vk, vp;
  
  k = [notes count];
  y = newYPosition;
  /* pass 1 */
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if ([p reCache: y : flags.spacing]) [p recalc]; /* must do this again */
    if (p->hangers != nil) [p markHangers];
  }
  /* pass 2 and 3 */
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if (p->hangers != nil)  [p setHangersOnly: BEAM];
  }
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if (p->hangers != nil)  [p setHangersExcept: BEAM];
    if (p->verses != nil)
    {
      n = 0;
      vk = [p->verses count];
      vp = p->versepos;
      for (j = 0; j < vk; j++)
      {
	v = [p verseOf: j];
        if (!ISINVIS(v))
        {
          if (n < vp)
          {
	    v->baseline = baselines[1][n] - vhigha;
	    v->vFlags.above = 1;
	  }
	  else
	  {
            v->baseline = textoff[0] + baselines[0][n - vp];
	    v->vFlags.above = 0;
	  }
          ++n;
        }
      }
      [p setVerses];
    }
  } 
  return self;
}


- recalc
{
  System *s = mysys;
  float preface, li;
  NSRect r;
  bbinit();
  if (self == [s firststaff]) [self drawBarnumbers: 0];
  if (flags.haspref)
  {
    li = [s leftIndent];
    preface = pref1 * 0.01 * li;
    r.origin.x = [s leftMargin] + preface;
    r.size.width = s->width + li - preface;
  }
  else
  {
    r.origin.x = [s leftWhitespace];
    r.size.width = s->width;
  }
  r.origin.y = y - staffthick[flags.subtype][gFlags.size];
  r.size.height = 2 * (flags.spacing * (flags.nlines - 1) + staffthick[flags.subtype][gFlags.size]);
  bounds = r;
  [mysys sysInvalid];
  return self;
}


- (Staff *) newFrom
{
  Staff *sp = [[Staff alloc] init];
  sp->bounds = bounds;
  sp->gFlags = gFlags;
  sp->flags = flags;
  sp->part = [part retain];
  sp->voffa = voffa;
  sp->voffb = voffb;
  sp->vhigha = vhigha;
  sp->voffb = voffb;
  sp->y = y;
  sp->topmarg = topmarg;
  sp->botmarg = botmarg;
  sp->pref1 = pref1;
  sp->pref2 = pref2;
  sp->mysys = nil;
  sp->notes = nil;
  return sp;
}


- (TextGraphic *) makeName: (BOOL) full
{
  TextGraphic *t;
  NSString *s;
  CallPart *cp;
  if (full) s = part;
    else
  {
    cp = [[[DrawApp sharedApplicationController] getPartlist] partNamed: part];
    if (cp == nil) return nil;
    s = cp->abbrev;
  }
    if (s == nil) return nil;
    if (![s length]) return nil;
  t = [[TextGraphic alloc] init];
  SUBTYPEOF(t) = STAFFHEAD;
  t->just = 0;
  t->horizpos = 7;
  t->client = self;
  [t initFromString: s : [[DrawApp currentDocument] getPreferenceAsFont: TEXFONT]];
  return t;
}


- setHangers
{
  int i, k;
  StaffObj *p;
  k = [notes count];
  for (i = 0; i < k; i++) [[notes objectAtIndex:i] markHangers];
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    [p setHangersOnly: BEAM];
    [p justVerses];
    [p setVerses];
  }
  for (i = 0; i < k; i++) [[notes objectAtIndex:i] setHangersExcept: BEAM];
  return self;
}


- recalcHangers
{
  int i, k;
  StaffObj *p;
  k = [notes count];
  for (i = 0; i < k; i++) [[notes objectAtIndex:i] markHangers];
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    [p recalcHangers];
    /* [p recalcVerses]; */
  }
  return self;
}


/*
  Change the size of each staff object and its hangers by ds clicks.
  Hangers done by marking.  Caller must [staff reset]
*/

- resizeNotes: (int) ds
{
  StaffObj *p;
  int i, k = [notes count];
  int sz;
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if (ds != 0)
    {
      sz = p->gFlags.size + ds;
      if (sz < 0) sz = 0; else if (sz > 2) sz = 2;
      p->gFlags.size = sz;
    }
    [p markHangers];
    [p reShape];
    /* [p recalcVerses]; */
  }
  for (i = 0; i < k; i++) [[notes objectAtIndex:i] resizeHangers: ds];
  return self;
}


/* free objs first because some might point to staff objects */

- (void)dealloc
{
  [notes removeAllObjects];
    [notes autorelease];
  { [super dealloc]; return; };
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ y=%f barbase=%f topmarg=%f botmarg=%f notes=%@", 
	[super description], y, barbase, topmarg, botmarg, notes];
}

- (NSString *) getInstrument
{
  return [[[DrawApp sharedApplicationController] getPartlist] instrumentForPart: part];
}


- (int) getChannel
{
  return [[[DrawApp sharedApplicationController] getPartlist] channelForPart: part];
}


- (NSString *) getPart
{
  if (part == nil) return nullPart;
  return part;
}


- (BOOL) hasAnyPart: (NSMutableArray *) pl
{
  int i, k;
  StaffObj *p;
  if ([pl indexOfPartName: part] >= 0) return YES;
  k = [notes count];
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if ([pl indexOfPartName: [p getPart]] >= 0) return YES;
  }
  return NO;
}


/*
  link StaffObj p into notes NSArray, setting its mystaff and returning p.
  Could be done by binary chop instead!
*/
 
- linknote: (StaffObj *) p
{
  int i, k;
  StaffObj *q;
  
  float px = p->x;
  [p setStaff: self];
  k = [notes count];
  for (i = 0; i < k; i++)
  {
    q = [notes objectAtIndex:i];
    if (q->x > px)
    {
      [notes insertObject:p atIndex:i];
      return p;
    }
  }
  [notes addObject: p];
  return p;
}
 

/*
  like linknotes, except p is already in NSArray, and minimum change is made.
  This is an exchange-sort, where at most one element is out of place.
*/

- staffRelink: p
{
  int i, k;
  float a = -1.0;
  StaffObj *q;
  k = [notes count];
  for (i = 0; i < k; i++)
  {
    q = [notes objectAtIndex:i];
      if (a > q->x) {
          id aNote;
          int theLocation = [notes indexOfObject:p];
          if (theLocation != NSNotFound) {
              aNote = [[[notes objectAtIndex:theLocation] retain] autorelease];
              [notes removeObjectAtIndex:theLocation];
              return [self linknote: aNote];
          }
//          return [self linknote: [notes removeObject: p]];
          return nil;
      }
    a = q->x;
  }
  return p;
}
 
 
/* remove StaffObj from notes list. Caller may then need to reset fields in StaffObj */

- unlinknote: p;
{
    int theLocation = [notes indexOfObject:[[p retain] autorelease]];
    if (theLocation != NSNotFound) [notes removeObjectAtIndex: theLocation];
  return p;
}


/* return the bracket nesting depth of this staff */

- (int) brackLevel
{
  System *s = mysys;
  NSMutableArray *ol = s->objs;
  int i, m = 0, s0, s1, s2;
  Bracket *p;
  i = [ol count];
  s0 = [s->staves indexOfObject:self];
  while (i--)
  {
    p = [ol objectAtIndex:i];
    if (TYPEOF(p) == BRACKET && SUBTYPEOF(p) != LINKAGE)
    {
      s1 = [s->staves indexOfObject:p->client1];
      s2 = [s->staves indexOfObject:p->client2];
      if (s1 < s2)
      {
        if (s0 < s1 || s2 < s0) continue;
      }
      else
      {
        if (s0 < s2 || s1 < s0) continue;
      }
      if (p->level > m) m = p->level;
    }
  }
  return m;
}


- (BOOL) atTopOf: (int) bt
{
  System *s = mysys;
  NSMutableArray *ol = s->objs;
  Bracket *p;
  int i = [ol count];
  while (i--)
  {
    p = [ol objectAtIndex:i];
    if (TYPEOF(p) == BRACKET && SUBTYPEOF(p) == bt && [p atTop: self]) return YES;
  }
  return NO;
}


/* return the note after/before the given one.  Discourage this. */

- nextNote: p
{
    int k = [notes count];
    int indx = [notes indexOfObject:p];
    if (indx == NSNotFound) indx = 0; else indx++;
    return (indx >= 0 && indx < k) ? [notes objectAtIndex:indx] : nil ;
}


- prevNote: p
{
    int k = [notes count];
    int indx = [notes indexOfObject:p];
    indx--;
    return (indx >= 0 && indx < k) ? [notes objectAtIndex:indx] : nil ;
}


- (int) indexOfNoteAfter: (float) x
{
  StaffObj *p;
  int i, k = [notes count];
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if (p->x - x > -0.01) return i;
  }
  return k;
}


- skipObjs: (float) x
{
  StaffObj *p;
  int i, k = [notes count];
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if (p->x >= x) return p;
  }
  return nil;
}

/*
  called only my xOfHyphmarg
  The clef business is to autodetect small clefs that come after an ordinary clef.
*/

- skipSig: (StaffObj *) p : (float) xi : (float *) x;
{
  StaffObj *q = nil;
  BOOL f = NO, fc = NO;
  int i, k;
  if (p != nil)
  {
    k = [notes count];
    i = [notes indexOfObject:p];
    if (i == -1) NSLog(@"SYSTEM ERROR: StaffObj not found by skipSig\n");
    while (i < k && ISASIGBLOCK(p))
    {
      if (TYPEOF(p) == CLEF)
      {
        if (fc == YES && p->gFlags.size != gFlags.size) break;
        fc = YES;
      }
      f = 1;
      q = p;
      ++i;
      p = [notes objectAtIndex:i];
    }
  }
  if (f) *x = q->bounds.origin.x + q->bounds.size.width;
  else *x = xi;
  return p;
}


- (int) skipSigIx: (int) i
{
  int k;
  BOOL fc = NO;
  StaffObj *p;
  k = [notes count];
  while (i < k)
  {
    p = [notes objectAtIndex:i];
    if (!(ISASIGBLOCK(p))) return i;
    if (TYPEOF(p) == CLEF)
    {
      if (fc == YES && p->gFlags.size != gFlags.size) return i;
      fc = YES;
    }
    ++i;
  }
  return k;
}


- (float) xOfHyphmarg
{
  float x;
  System *s = mysys;
  [self skipSig: [notes objectAtIndex:0] : [s leftWhitespace] : &x];
  return x;
}


- (float) xOfEnd
{
  System *s = mysys;
  return [s leftWhitespace] + s->width;
}


- (float) staffHeight
{
  return (flags.spacing << 1) * (flags.nlines - 1);
}


- (float) yOfCentre
{
  return(y + flags.spacing * (flags.nlines - 1));
}


- (float) yOfTop
{
  return y;
}


- (float) yOfBottom;
{
  return(y + (flags.spacing << 1) * (flags.nlines - 1));
}


- (float) yOfBottomPos: (int) p
{
  return(y + flags.spacing * (p + 2 * (flags.nlines - 1)));
}


- (float) yOfPos: (int) p
{
  return(y + (int) flags.spacing * p);
}


- (int) posOfBottom
{
  return 2 * (flags.nlines - 1);
}


/* shift into positive range for consistent roundoff across py - y = 0 */

- (int) findPos: (float) py;
{
  float ss;
  ss = flags.spacing;
  return ((int)((((py + 1000.0 * ss) - y) / ss) + 0.5)) - 1000;
}


- (int) myIndex
{
  return [mysys indexOfObject:self];
}


/* return the note at index i */
    
- getNote: (int) i
{
  return [notes objectAtIndex:i];
}


/* set the part/instrument/tuning fields to default values */

- defaultNoteParts
{
  int k;
  StaffObj *p;
  k = [notes count];
  while (k--)
  {
    p = [notes objectAtIndex:k];
      if (p->part) [p->part autorelease];
    p->part = nil;
    if (TYPEOF(p) == NOTE) ((GNote *)p)->instrument = 0;//sb: instrument here is from GNote, not CallPart
    else if (TYPEOF(p) == TABLATURE) {
        id q = ((Tablature *)p)->tuning;
        if (q) {
            [q release];
            q = nil;
        }
    }
  }
  return self;
}


/*
  Hyphenation.  various complications.
  e.g.    notes rest note    but    notes rest note
           _____      Syl            _______________
           notes rest note    but    notes rest note
           - - - - -  Syl            - - - - - - - -
*/

/* Scan the notes after p to find the right end of a hyphenated word. */

- nextVersed: (StaffObj *) p : (int) vn
{
  StaffObj *q;
  int i, j, k, vc;
  vc = p->voice;
  j = [notes indexOfObject:p] + 1;
  k = [notes count];
  for (i = j; i < k; i++)
  {
    q = [notes objectAtIndex:i];
    if (q->voice == vc && [q hasVerseText: vn]) return q;
  }
  return nil;
}


/*
  Scan the notes before p to find the left end of a hyphenated word
  (returning nil if not hyphened)  Used to improve typein display.
*/

- prevVersed: (StaffObj *) p : (int) vn
{
  StaffObj *q;
  Verse *v;
  int i, vc;
  i = [notes indexOfObject:p];
  vc = p->voice;
  while (i--)
  {
    q = [notes objectAtIndex:i];
    if (q->voice == vc && [q hasVerseText: vn])
    {
      v = [q verseOf: vn];
      return (v->vFlags.hyphen) ? q : nil;
    }
  }
  return nil;
}



/*
  return whether staff starts with a melisma.
  Either first texted is a cont or needs a melisma. 
*/


- (BOOL) startMelisma : (int) vc : (int) vn
{
  StaffObj *q = nil, *r;
  int i, j, k;
  j = [self indexOfNoteAfter: [mysys leftWhitespace]];
  k = [notes count];
  r = nil;
  for (i = j; (i < k); i++)
  {
    q = [notes objectAtIndex:i];
    if ([q continuesLine: vn]) return YES; 
    if (q->voice == vc)
    {
      if ([q hasVerseText: vn]) return NO;
      else if (ISAVOCAL(q)) return YES;
    }
  }
  return YES;
}


/*
  Scan the notes after p to find the right end of a melisma.
  The scanning loop has four termination conditions.
  (fv,r) = NO,nil: nothing on staff
  (fv,r) = NO,q: check next staff to choose end point
  (fv,r) = YES,nil:  melisma to q
  (fv,r) = YES,q: melisma to q but check r.
  Complications: (a) if the melisma ends on a non-texted,
  check in case the next texted (=q) encroaches too much to the left
  (b) if nothing texted after melisma, check the next staff
  to see if it really should go to end, or to q.
*/

- (float) endMelisma: (StaffObj *) p : (int) vn
{
  StaffObj *q = nil, *r;
  Staff *sp;
  System *sys;
  int i, j, k, v;
  float x=0.0, vx;
  BOOL fv = NO;
  j = [notes indexOfObject:p] + 1;
  k = [notes count];
  r = nil;
  v = p->voice;
  for (i = j; (i < k && !fv); i++)
  {
    q = [notes objectAtIndex:i];
    if (q->voice == v)
    {
      if ([q hasVerseText: vn]) fv = YES;
      else if (ISAVOCAL(q)) r = q;
    }
  }
  /* normally melisma goes to r */
  if (r != nil)
  {
    x = r->bounds.origin.x + r->bounds.size.width;
  }
  if (fv)
  {
    vx = [[q verseOf: vn] textLeft: q] - nature[q->gFlags.size];
    /* check encroachment, ensuring x is defined. */
    if (r == nil || vx < x) x = vx;
  }
  else
  {
    /* check if next line starts with a melisma */
    sys = mysys;
    sp = [sys->view nextStaff: sys : [self myIndex]];
    if ([sp startMelisma: v : vn]) x = [self xOfEnd];
  }
  return x;
}


/* return whether there is a texted obj (verse n) on this staff before p */

- (BOOL) textedBefore : (StaffObj *) p : (int) n
{
  StaffObj *q;
  int k = [notes indexOfObject:p];
  int vc = p->voice;
  while (k--)
  {
    q = [notes objectAtIndex:k];
    if (p->voice == vc && [q hasVerseText: n]) return YES;
  }
  return NO;
}


/* return whether there is a vocalised obj (verse n) on this staff before p*/

- (BOOL) vocalBefore: (StaffObj *) p : (int) n
{
  StaffObj *q;
  int vc = p->voice;
  int k = [notes indexOfObject:p];
  while (k--)
  {
    q = [notes objectAtIndex:k];
    if (q->voice == vc && ISAVOCAL(q)) return YES;
  }
  return NO;
}

/* 
  Return the hyphen type of the last texted obj on this staff.
  (-1 if none found).
  If a symbol that "stops" text (e.g. an ending barline) comes after the
  last texted object, then same as hyphen type 0.
*/

- (int) lastHyphen: (int) n : (int) v
{
  int h, k = [notes count];
  StaffObj *p;
  while (k--)
  {
    p = [notes objectAtIndex:k];
    if ([p stopsVerse]) return 0;
    if (p->voice == v)
    {
      h = [p verseHyphenOf: n];
      if (h >= 0) return h;
    }
  }
  return -1;
}


/* return x of first timed object on staff previous to p (if none, return hyphmarg) */

- (float) firstTimedBefore: (StaffObj *) p
{
  int i, vc;
  StaffObj *q;
  int k = [notes indexOfObject:p];
  System *s = mysys;
  i = [self skipSigIx: [self indexOfNoteAfter: [s leftWhitespace]]];
  vc = p->voice;
  while (i < k)
  {
    q = [notes objectAtIndex:i];
    if (q->voice == vc && ISATIMEDOBJ(q)) return q->x;
    ++i;
  }
  return [self xOfHyphmarg];
}


/* hide verse n of all notes in self */

- hideVerse: (int) n
{
  int i, nk, vk;
  StaffObj *p;
  NSMutableArray *vl;
  Verse *v;
  nk = [notes count];
  for (i = 0; i < nk; i++)
  {
    p = [notes objectAtIndex:i];
    if ((vl = p->verses) != nil)
    {
      vk = [vl count];
      if (n < vk)
      {
	v = [vl objectAtIndex:n];
	v->gFlags.invis = 1;
      }
    }
  }
  return self;
}


/* return the last thing of type t before q's x location */

- searchType: (int) t : (StaffObj *) q
{
  int i;
  StaffObj *r, *p;
  int k = [notes count];
  float x = q->x;
  r = nil;
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if (p->x >= x) return r;
    if (p->gFlags.type == t) r = p;
  }
  return r;
}


/* return the clef that affects keysig k */

- findClef: key
{
  int k = [notes indexOfObject:key];
  Clef *p;
  while (k--)
  {
    p = [notes objectAtIndex:k];
    if (p->gFlags.type == CLEF) return p;
  }
  return nil;
}


/* accumulate key information up to and including p */

- (int) getKeyThru: (StaffObj *) p : (char *) curracc;
{
  int i, j, k = [notes count];
  int mc = 10;
  StaffObj *q;
  char ks[7], acc[7];
  for (i = 0; i < 7; i++) curracc[i] = ks[i] = 0;
  for (i = 0; i < k; i++)
  {
    q = [notes objectAtIndex:i];
    switch(TYPEOF(q))
    {
      case CLEF:
        mc = [(Clef *)q middleC];
	break;
      case KEY:
        [(KeySig *)q getKeyString: ks];
        for (j = 0; j < 7; j++) curracc[j] = ks[j];
	break;
      case NOTE:
        [(GNote *)q getKeyString: mc : acc];
        for (j = 0; j < 7; j++) if (acc[j]) curracc[j] = acc[j];
        break;
      case BARLINE:
	for (j = 0; j < 7; j++) curracc[j] = ks[j];
        break;
    }
    if (q == p) break;
  }
  return mc;
}


/* return keycentre of first clef on this staff (or -1 if none) */

- (int) firstClefCentre
{
  int i, j, k;
  Clef *p;
  j = [self indexOfNoteAfter: [mysys leftWhitespace]];
  k = [notes count];
  /* start after indent */
  for (i = j; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if (TYPEOF(p) == CLEF) return p->keycentre;
  }
  /* else try before indent */
  for (i = 0; i < j; i++)
  {
    p = [notes objectAtIndex:i];
    if (TYPEOF(p) == CLEF) return p->keycentre;
  }
  /* else give up */
  return -1;
}


/* pack all the selected objects to the left. Caller needs to resize 0  */

- packLeft
{
  StaffObj *p;
  int i, k = [notes count];
  float vlb, vrb, lb, rb, mx, px = [mysys leftWhitespace];
  for (i = 0; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    [p verseWidths: &vlb : &vrb];
    if (p->gFlags.selected)
    {
      lb = LEFTBEARING(p);
      if (vlb > lb) lb = vlb;
      mx = px + lb;
      MOVE(p, mx);
    }
    rb = RIGHTBEARING(p);
    if (vrb > rb) rb = vrb;
    px = p->x + rb;
  }
  return self;
}


/* look along the staff for a hit on a staff object */

- (void)searchFor: (NSPoint) p :(NSMutableArray *)arr
{
  id q;
  int k = [notes count];
  int i;
  for (i = 0; i < k; i++)
  {
    q = [notes objectAtIndex:i];
      if ([q hit: p])
          if (![arr containsObject:q])
              [arr addObject:q];
      [q searchFor: p :arr];
  }
  return;
}


/* return whether note i is the last visible bar line on the staff */

- (BOOL) isLastBar: (int) i
{
  StaffObj *p;
  int j, k = [notes count];
  for (j = i + 1; j < k; j++)
  {
    p = [notes objectAtIndex:j];
    if (TYPEOF(p) == BARLINE && !(p->gFlags.invis)) return NO;
  }
  return YES;
}


- (BOOL) allRests
{
  int i, j, k;
  StaffObj *p;
  k = [notes count];
  j = [self indexOfNoteAfter: [mysys leftWhitespace]];
  for (i = j; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if (ISAVOCAL(p)) return NO;
  }
  return YES;
}


- (int) countRests
{
  int i, j, k, b = 0;
  StaffObj *p;
  k = [notes count];
  j = [self indexOfNoteAfter: [mysys leftWhitespace]];
  for (i = j; i < k; i++)
  {
    p = [notes objectAtIndex:i];
    if (TYPEOF(p) == BARLINE || TYPEOF(p) == REST) b += [p barCount];
  }
  return b;
}


/* return whether this staff ends with a nocount bar */

- (BOOL) lastBarNoCount
{
  int k, b = YES;
  StaffObj *p;
  k = [notes count];
  while (k--)
  {
    p = [notes objectAtIndex:k];
    if (TYPEOF(p) == BARLINE) return ([p barCount] == 0);
  }
  return b;
}


/*
  Drawing routines
*/


/* display bar numbers */

extern void unionStringBB(NSRect *bb, float x, float y, char *s, NSFont *f, int j);
extern void cenclosure(int i, float px, float py, float qx, float qy, float th, int sz, int m);


static void drawbarnum(int n, float x, float y, NSFont *f, int j, int eb, int mode)
{
  char buf[8];
  NSRect r;
  sprintf(buf, "%d", n);
  justString(x, y, buf, f, j, mode);
  if (eb)
  {
    r = NSZeroRect;
    unionStringBB(&r, x, y, buf, f, j);
    cenclosure(eb - 1, r.origin.x - 2, r.origin.y - 2, r.origin.x + r.size.width + 2, r.origin.y + r.size.height + 2, staffthick[0][0], 0, mode);
  }
}


/* yoff is subtracted from the default */

- drawBarnumbers: (int) mode
{
  float bx, by=0.0;
  int eb, b, i, k, m;
  System *s;
  NSFont *f;
  Barline *p;
  OpusDocument *doc;
  /* if (gFlags.type == 2) return self; */
  doc = [DrawApp currentDocument];
  s = mysys;
  if ([s myIndex] == 0 && ![doc getPreferenceAsInt: BARNUMFIRST]) return self;
  if ([s lastSystem] && ![doc getPreferenceAsInt: BARNUMLAST]) return self;
  eb = [doc getPreferenceAsInt: BARNUMSURROUND];
  b = s->barnum;
  f = [doc getPreferenceAsFont: BARFONT];
  switch([doc getPreferenceAsInt: BARNUMPLACE])
  {
    case 0:
     break;
    case 1:
      if ([[s->view prevStaff: s : [self myIndex]] lastBarNoCount]) break;
      by = y - ((4 + barbase) * flags.spacing);
      drawbarnum(b, [s leftWhitespace], by, f, JLEFT, eb, mode);
      break;
    case 3:
      if ([[s->view prevStaff: s : [self myIndex]] lastBarNoCount]) break;
      bx = [s leftWhitespace] - ([self brackLevel] * (brackwidth[gFlags.size] + (2 * nature[0])));
      bx -= charFGW(f, '3');
        by = y + fontAscent(f) - (barbase * flags.spacing);
      drawbarnum(b, bx, by, f, JRIGHT, eb, mode);
      break;
    case 2:
      by = y - ((2.5 + barbase) * flags.spacing);
      m = [doc getPreferenceAsInt: BAREVERY];
      if ((b % m) == 0 && !([[s->view prevStaff: s : [self myIndex]] lastBarNoCount]))
      {
        drawbarnum(b, [self xOfHyphmarg], by, f, JLEFT, eb, mode);
      }
      k = [notes count];
      i = [self indexOfNoteAfter: [s leftWhitespace]];
      while (i < k)
      {
        p = [notes objectAtIndex:i];
        if (ISATIMEDOBJ(p)) break;
        ++i;
      }
      while (i < k)
      {
        p = [notes objectAtIndex:i];
        if (TYPEOF(p) == BARLINE)
        {
          b += [p barCount];
	  if (p->flags.nonumber == 2 || (b % m == 0 && p->flags.nonumber != 1 && ![self isLastBar: i]))
          {
            drawbarnum(b, p->x, by, f, JLEFT, eb, mode);
          }
        }
        else if (TYPEOF(p) == REST) b += [p barCount];
        ++i;
      }
      break;
  }
  return self;
}


/* draw any subobjects (in this case, staffobjs) */

- draw: (NSRect) r nonSelectedOnly: (BOOL) nso
{
  int i, k;
  if (flags.hidden) return self;
  [super draw: r nonSelectedOnly: nso];
  k = [notes count];
  for (i = 0; i < k; i++) [[notes objectAtIndex:i] draw: r nonSelectedOnly: nso];
  return self;
}


- drawHangers: (NSRect) r nonSelectedOnly: (BOOL) nso
{
  int k;
  if (flags.hidden) return self;
  k = [notes count];
  while (k--) [[notes objectAtIndex:k] drawHangers: r nonSelectedOnly: nso];
  return self;
}


- draw
{
    int i, m;
    float dy, by, bx, th, lm, li;
    
    if (flags.hidden)
	return self;
    if (staffFlag)
	return self;
    lm = [mysys leftMargin];
    li = [mysys leftIndent];
    dy = 2 * flags.spacing;
    bx = lm + li;
    th = staffthick[flags.subtype][gFlags.size];
    by = y - 0.5 * th;
    m = drawmode[0][0];
    i = flags.nlines;
    while (i--) {
	cmakeline(bx, by, bx + mysys->width - th, by, m);
	if (flags.haspref) 
	    cmakeline(lm + pref1 * 0.01 * li, by, lm + pref2 * 0.01 * li, by, m);
	by += dy;
    }
    cstrokeline(th, 1);
    /* draw staff number marker */
    DrawTextWithBaselineTies(bx + mysys->width + 8, [self yOfBottom], [NSString stringWithFormat: @"%d", [mysys->staves indexOfObject: self] + 1], fontdata[FONTSTMR], markmode[0]);
    /* draw bar numbers */
    if ([mysys firststaff] == self || (flags.hasnums && [[DrawApp currentDocument] getPreferenceAsInt: BARNUMPLACE] == 2))
	[self drawBarnumbers: m];
#if 0   // diagnostic
    dy = y - vhigha;
    cline(bx, dy, bx + mysys->width, dy, 0.0, 2);
    dy = y + vhighb;
    cline(bx, dy, bx + mysys->width, dy, 0.0, 2);
#endif
    return self;
}


/* Archiving */

struct oldflags /* for old version */
{
  unsigned int nlines : 3;	/* number of lines */
  unsigned int spacing : 4;	/* pixels between positions */
  unsigned int subtype : 2;	/* type of notation */
  unsigned int size : 2;	/* size code */
  unsigned int haspref : 1;	/* has prefatory staff */
  unsigned int hidden : 1;	/* staff is hidden */
};

extern int needUpgrade;


- (NSString *) checkPart
{
   if (!part)
   {
     NSLog(@"Staff: found part = 0\n");
     return nullPart;
   }
   return part;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  struct oldflags f;
  char b1, b2, b3, b4, b5, b6, b7, b8;
  float textbl[8];
  int v = [aDecoder versionForClassName:@"Staff"];
  [super initWithCoder:aDecoder];
/* NSLog(@"reading Staff v%d\n", v); */
  barbase = 0;
  flags.hasnums = 0;
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"scfffff", &f, &b8, &vhigha, &vhighb, &y, &pref1, &pref2];
    flags.nlines = f.nlines;
    flags.spacing = f.spacing;
    flags.subtype = f.subtype;
    gFlags.size = f.size;
    flags.haspref = f.haspref;
    flags.hidden = f.hidden;
    topmarg = staffheads[flags.subtype];
    needUpgrade |= 8;
    botmarg = 0.0;
    [aDecoder decodeArrayOfObjCType:"f" count:8 at:textbl];
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"scffffff", &f, &b8, &vhigha, &vhighb, &y, &pref1, &pref2, &topmarg];
    flags.nlines = f.nlines;
    flags.spacing = f.spacing;
    flags.subtype = f.subtype;
    gFlags.size = f.size;
    flags.haspref = f.haspref;
    flags.hidden = f.hidden;
    needUpgrade |= 8;
    botmarg = 0.0;
    [aDecoder decodeArrayOfObjCType:"f" count:8 at:textbl];
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b1, &b2, &b3, &b4, &b5, &b6];
    flags.nlines = b1;
    flags.spacing = b2;
    flags.subtype = b3;
    gFlags.size = b4;
    flags.haspref = b5;
    flags.hidden = b6;
    needUpgrade |= 8;
    [aDecoder decodeValuesOfObjCTypes:"cffffff", &b8, &vhigha, &vhighb, &y, &pref1, &pref2, &topmarg , &botmarg];
    [aDecoder decodeArrayOfObjCType:"f" count:8 at:textbl];
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
    flags.nlines = b1;
    flags.spacing = b2;
    flags.subtype = b3;
    gFlags.size = b4;
    flags.haspref = b5;
    flags.hidden = b6;
    flags.topfixed = b7;
    needUpgrade |= 8;
    [aDecoder decodeValuesOfObjCTypes:"fffffff", &vhigha, &vhighb, &y, &pref1, &pref2, &topmarg, &botmarg];
    [aDecoder decodeArrayOfObjCType:"f" count:8 at:textbl];
  }
  else if (v == 4)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
    flags.nlines = b1;
    flags.spacing = b2;
    flags.subtype = b3;
    gFlags.size = b4;
    flags.haspref = b5;
    flags.hidden = b6;
    flags.topfixed = b7;
    needUpgrade |= 8;
    [aDecoder decodeValuesOfObjCTypes:"fffffff", &vhigha, &vhighb, &y, &pref1, &pref2, &topmarg, &botmarg];
  }
  else if (v == 5)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
    flags.nlines = b1;
    flags.spacing = b2;
    flags.subtype = b3;
    gFlags.size = b4;
    flags.haspref = b5;
    flags.hidden = b6;
    flags.topfixed = b7;
    needUpgrade |= 8;
    [aDecoder decodeValuesOfObjCTypes:"fffffffff", &vhigha, &vhighb, &voffa, &voffb, &y, &pref1, &pref2, &topmarg, &botmarg];
  }
  else if (v == 6)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccccc", &b1, &b2, &b3, &b5, &b6, &b7, &b8];
    flags.nlines = b1;
    flags.spacing = b2;
    flags.subtype = b3;
    flags.haspref = b5;
    flags.hidden = b6;
    flags.topfixed = b7;
    {
	// LMS this is very wrong, we need to put it into a temporary storage
	char tempString[2] = {
	    (char) b8, '\0'
	};
	part = [NSString stringWithCString: tempString];
    }
    needUpgrade |= 8;
    [aDecoder decodeValuesOfObjCTypes:"fffffffff", &vhigha, &vhighb, &voffa, &voffb, &y, &pref1, &pref2, &topmarg, &botmarg];
  }
  else if (v == 7)
  {
      char *p;
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b1, &b2, &b3, &b5, &b6, &b7];
    flags.nlines = b1;
    flags.spacing = b2;
    flags.subtype = b3;
    flags.haspref = b5;
    flags.hidden = b6;
    flags.topfixed = b7;
    [aDecoder decodeValuesOfObjCTypes:"fffffffff", &vhigha, &vhighb, &voffa, &voffb, &y, &pref1, &pref2, &topmarg, &botmarg];
    [aDecoder decodeValuesOfObjCTypes:"%", &p];
    if (p) part = [[NSString stringWithCString:p] retain]; else part = nil;
  }
  else if (v == 8)
  {
      char *p;
    [aDecoder decodeValuesOfObjCTypes:"ccccccc", &b1, &b2, &b3, &b5, &b6, &b7, &b8];
    flags.nlines = b1;
    flags.spacing = b2;
    flags.subtype = b3;
    flags.haspref = b5;
    flags.hidden = b6;
    flags.topfixed = b7;
    flags.hasnums = b8;
    [aDecoder decodeValuesOfObjCTypes:"ffffffffff", &vhigha, &vhighb, &voffa, &voffb, &y, &pref1, &pref2, &topmarg, &botmarg, &barbase];
    [aDecoder decodeValuesOfObjCTypes:"%", &p];
    if (p) part = [[NSString stringWithCString:p] retain]; else part = nil;

  }
  else if (v == 9)
    {
      [aDecoder decodeValuesOfObjCTypes:"ccccccc", &b1, &b2, &b3, &b5, &b6, &b7, &b8];
      flags.nlines = b1;
      flags.spacing = b2;
      flags.subtype = b3;
      flags.haspref = b5;
      flags.hidden = b6;
      flags.topfixed = b7;
      flags.hasnums = b8;
      [aDecoder decodeValuesOfObjCTypes:"ffffffffff", &vhigha, &vhighb, &voffa, &voffb, &y, &pref1, &pref2, &topmarg, &botmarg, &barbase];
      [aDecoder decodeValuesOfObjCTypes:"@", &part];
      [aDecoder decodeValuesOfObjCTypes:"@", &notes];
    }

  part = [self checkPart];
  if (v < 9) {
      [aDecoder decodeValuesOfObjCTypes:"@", &notes];
  }
  mysys = [[aDecoder decodeObject] retain];
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b1, b2, b3,/* b4,*/ b5, b6, b7, b8;
  [super encodeWithCoder:aCoder];
  b1 = flags.nlines;
  b2 = flags.spacing;
  b3 = flags.subtype;
  b5 = flags.haspref;
  b6 = flags.hidden;
  b7 = flags.topfixed;
  b8 = flags.hasnums;
  [aCoder encodeValuesOfObjCTypes:"ccccccc", &b1, &b2, &b3, &b5, &b6, &b7, &b8];
  [aCoder encodeValuesOfObjCTypes:"ffffffffff", &vhigha, &vhighb, &voffa, &voffb, &y, &pref1, &pref2, &topmarg, &botmarg, &barbase];
  part = [self checkPart];
  [aCoder encodeValuesOfObjCTypes:"@", &part];
  [aCoder encodeValuesOfObjCTypes:"@", &notes];
  [aCoder encodeConditionalObject:mysys];
}
- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
//    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];

    [aCoder setInteger:flags.nlines forKey:@"nlines"];
    [aCoder setInteger:flags.spacing forKey:@"spacing"];
    [aCoder setInteger:flags.subtype forKey:@"subtype"];
    [aCoder setInteger:flags.haspref forKey:@"haspref"];
    [aCoder setInteger:flags.hidden forKey:@"hidden"];
    [aCoder setInteger:flags.topfixed forKey:@"topfixed"];
    [aCoder setInteger:flags.hasnums forKey:@"hasnums"];

    [aCoder setFloat:vhigha forKey:@"vhigha"];
    [aCoder setFloat:vhighb forKey:@"vhighb"];
    [aCoder setFloat:voffa forKey:@"voffa"];
    [aCoder setFloat:voffb forKey:@"voffb"];
    [aCoder setFloat:y forKey:@"y"];
    [aCoder setFloat:pref1 forKey:@"pref1"];
    [aCoder setFloat:pref2 forKey:@"pref2"];
    [aCoder setFloat:topmarg forKey:@"topmarg"];
    [aCoder setFloat:botmarg forKey:@"botmarg"];
    [aCoder setFloat:barbase forKey:@"barbase"];
    part = [self checkPart];
    [aCoder setString:part forKey:@"part"];
    [aCoder setObject:notes forKey:@"notes"];
    [aCoder setObject:mysys forKey:@"mysys"]; /* should be conditional? */
}


@end
