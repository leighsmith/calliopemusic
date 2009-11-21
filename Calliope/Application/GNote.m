/* $Id$ */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "GNote.h"
#import "NoteInspector.h"
#import "GNChord.h"
#import "GraphicView.h"
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
//extern unsigned char headchars[NUMHEADS][10];
extern unsigned char headfont[NUMHEADS][10];
extern float stemdx[3][NUMHEADS][2][10][2];
extern float stemdy[3][NUMHEADS][2][10][2];
extern unsigned char shapeheads[4][10][2];
extern unsigned char shapefont[4];
extern void drawhead(float x, float y, int bodyType, int body, int shapeID, int su, int size, int drawingMode);

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


+ (void) initialize
{
  if (self == [GNote class])
  {
    proto = [GNote alloc];
    proto->gFlags.subtype = 0;
    proto->gFlags.locked = 0;
    [proto setStemIsUp: YES];
    [proto setStemIsFixed: NO];
    proto->time.tight = 0;
    proto->time.nostem = 0;
    proto->voice = 0;
    proto->instrument = 0;
    proto->isGraced = 0;
    proto->showSlash = 0;
    (void)[GNote setVersion: 9];	/* class version, see read: */ /*sb: left at 9 */
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
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
	staffPosition = 0;
	[self setTypeOfGraphic: NOTE];
	dotdx = 0.0;
	instrument = 0;
	showSlash = 0;	
    }
    return self;
}


- (NSString *) description
{
    return [NSString stringWithFormat: @"%@: x = %f, y = %f %@", [super description], x, y, [self describeChordHeads]];
    // return [NSString stringWithFormat: @"%@: x = %f, y = %f %@", [super description], x, y, headlist];
    // return [NSString stringWithFormat: @"%@: x = %f, y = %f", [super description], x, y];
}


- (void) dealloc
{
    [headlist release];
    headlist = nil;
    [super dealloc];
}


/* override to provide for Chord.  */
// - getX: (float *) fx andY: (float *) fy
- (BOOL) getXY: (float *) fx : (float *) fy
{
  NoteHead *noteHead;
  float dx = 2.0 * nature[gFlags.size];
  noteHead = [headlist objectAtIndex: SELHEADIX(gFlags.selend, [headlist count])];
  if ([noteHead isReverseSideOfStem]) 
      dx = ([self stemIsUp] ? dx : -dx); else dx = 0.0;
  *fx = x + dx;
  *fy = [noteHead y];
  return YES;
}

// - (void) moveByX: (float) dx andY: (float) dy
- (void) moveBy: (float) dx :(float)dy
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

// - yOfNoteHead: (int) n
- (float) headY: (int) n
{
    return [((NoteHead *) [headlist objectAtIndex: n]) y];
}

- (NoteHead *) noteHead: (int) noteHeadIndex
{
    return [headlist objectAtIndex: noteHeadIndex]; // is already autoreleased by objectAtIndex:
}

- (int) numberOfNoteHeads
{
    return [headlist count];
}

- (BOOL) defaultStemup: (System *) sys : (Staff *) sp
{
  int cpos;
    
  if ([self stemIsFixed])
      return([self stemIsUp]);
  cpos = getLines(sp) - 1;
  if (staffPosition < cpos) return(NO);
  if (staffPosition > cpos) return(YES);
  if (staffPosition == cpos) return([sys whereIs: sp] < 0);
  return NO;
}


/* initialise newly created note */
/*
TODO should be named
- noteInView: (GraphicView *) v 
   fromPoint: (NSPoint) pt 
     onStaff: (Staff *) sp 
    inSystem: (System *) sys 
 withGraphic: (Graphic *) g 
    withBody: (int) i;
*/
- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
{
    NoteHead *noteHead;
    
    [super proto: v : pt : sp : sys : g : i];
    gFlags.subtype = proto->gFlags.subtype;
    gFlags.locked = proto->gFlags.locked;
    [self setStemIsUp: [proto stemIsUp]];
    [self setStemIsFixed: [proto stemIsFixed]];
    time.tight = proto->time.tight;
    time.nostem = proto->time.nostem;
    time.body = i;
    voice = proto->voice;
    instrument = proto->instrument;
    showSlash = proto->showSlash;
    isGraced = proto->isGraced;
    noteHead = [headlist lastObject];
    [noteHead setNote: self];
    [noteHead setBodyType: gFlags.subtype];
    if ([sp graphicType] == STAFF) {
	staffPosition = [sp findPos: pt.y];
	y = [sp yOfStaffPosition: staffPosition];
	[noteHead setStaffPosition: staffPosition];
	[noteHead setCoordinateY: y];
	if (![self stemIsFixed]) 
	    [self setStemIsUp: [self defaultStemup: sys : sp]];
    }
    else {
	[noteHead setStaffPosition: staffPosition];
	[noteHead setCoordinateY: y];
	if (![self stemIsFixed]) 
	    [self setStemIsUp: YES];
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
    bounds = NSUnionRect(b, bounds);
  }
  return self;
}


/* obj's staff Y has changed.  Update our Y caches.  Caller recalcs. */

- (BOOL) reCache: (float) sy : (int) ss
{
  int i, k;
  float t=0.0;
  NoteHead *noteHead;
  BOOL mod=NO;
    
  k = [headlist count];
  for (i = 0; i < k; i++)
  {
    noteHead = [headlist objectAtIndex:i];
    t = sy + ss * [noteHead staffPosition];
    if (t != [noteHead y])
    {
      mod = YES;
	[noteHead setCoordinateY: t];
    }
  }
  /* noteHead will be lastobject, with t valid, so check StaffObj's Y */
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
  NoteHead *noteHead;
    
  np = [self staffPositionOfY: y];
  dp = np - staffPosition;
  if (dp == 0) return self;
  staffPosition = np;
  k = [headlist count];
  while (k--)
  {
    noteHead = [headlist objectAtIndex: k];
    [noteHead setStaffPosition: [noteHead staffPosition] + dp];
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
  if (up != [self stemIsUp])
  {
    [self setStemIsUp: up];
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

- (void) setStemLengthTo: (float) s
{
  BOOL up = (s < 0);
    
  if (up != [self stemIsUp])
  {
    [self setStemIsUp: up];
    [self reverseHeads];
    [self reshapeChord];
  }
  [super setStemLengthTo: s];
  [self recalc];
}

/* return the stem base */
- (float) wantsStemY: (int) a
{
  NoteHead *noteHead;
    
  noteHead = ([self stemIsUp] == a) ? [headlist lastObject] : [headlist objectAtIndex: 0];
  return [noteHead y];
}

- (BOOL) showSlash
{
    return showSlash == 0;
}

- (void) setShowSlash: (BOOL) willShowSlash
{
    showSlash = willShowSlash;
}

- (void) setDotOffset: (float) dotOffset
{
    dotdx = dotOffset;
}

- (float) dotOffset
{
    return dotdx;
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
  int i, numOfNoteHeads;
  NoteHead *noteHead;
  float sum = 0.0;
    
  numOfNoteHeads = [headlist count];
  for (i = 0; i < numOfNoteHeads; i++)
  {
    noteHead = [headlist objectAtIndex:i];
    sum += [noteHead y];
  }
  return sum / numOfNoteHeads;
}


- posRange: (int *) pl : (int *) ph
{
  int t0, t1;
    
    t0 = [((NoteHead *)[headlist objectAtIndex: 0]) staffPosition];
    t1 = [((NoteHead *)[headlist lastObject]) staffPosition];
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
  NoteHead *noteHead;
  float sy;
    
  if ([self stemIsUp] == a)
  {
    noteHead = [headlist lastObject];
    sy = [noteHead y];
    if (hasstem[time.body]) sy += [self stemLength];
    pos = [[noteHead myNote] staffPositionOfY: sy];
  }
  else
  {
    noteHead = [headlist objectAtIndex:0];
    pos = [noteHead staffPosition];
  }
 return pos;
}


- (float) boundAboveBelow: (int) a
{
  float ya, ye;
  NoteHead *noteHead;
    
  if ([self stemIsUp] == a)
  {
    noteHead = [headlist lastObject];
    ya = [noteHead y];
    if (hasstem[time.body])
    {
      if ([self hasCrossingBeam])
      {
        ya += getstemlen(time.body, gFlags.size, stype[(int)[noteHead bodyType]], [self stemIsUp], [noteHead staffPosition], [[noteHead myNote] getSpacing]);
      }
      else ya += [self stemLength];
    }
  }
  else
  {
    noteHead = [headlist objectAtIndex:0];
    ye = nature[gFlags.size];
    ya = [noteHead y] + (a ? -ye : ye);
  }
   return ya;
}


- (float) yAboveBelow: (int) a
{
  float ya;
  NoteHead *noteHead;
    
  if ([self stemIsUp] == a)
  {
    noteHead = [headlist lastObject];
    ya = [noteHead y];
    if (hasstem[time.body]) ya += [self stemLength];
  }
  else
  {
    noteHead = [headlist objectAtIndex:0];
    ya = [noteHead y];
  }
   return ya;
}


- (int) midPosOff
{
  int k, r, cpos;
  NoteHead *noteHead;
    
  r = 0;
  k = [headlist count];
  while (k--)
  {
    noteHead = [headlist objectAtIndex:k];
    cpos = [[noteHead myNote] getLines] - 1;
    r += ([noteHead staffPosition] - cpos);
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
        if ([q graphicType] == CHORDGROUP) return q;
    }
    return nil;
}


- (BOOL) selectMe: (NSMutableArray *) sl : (int) d : (int) active
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
    NoteHead *noteHead;
    
    noteHead = [headlist objectAtIndex:SELHEADIX(gFlags.selend, [headlist count])];
    [noteHead setAccidental: ([noteHead accidental] == a) ? 0 : a];
    [self resetChord];
    return self;
}

// - setCurrentHeadToType: (int) a
- setHead: (int) a
{
    NoteHead *noteHead;
    
    noteHead = [headlist objectAtIndex: SELHEADIX(gFlags.selend, [headlist count])];
    [noteHead setBodyType: ([noteHead bodyType] == a) ? 0 : a];
    [self resetChord];
    return self;
}


/* set the accidental keystring, account for hanging accidentals too */

extern void getNumOct(int pos, int mc, int *num, int *oct);

- getKeyString: (int) mc : (char *) ks
{
    int i, k, num, oct, acc;
    NoteHead *noteHead;
    
    for (i = 0; i < 7; i++) ks[i] = 0;
    k = [headlist count];
    while (k--)
    {
        noteHead = [headlist objectAtIndex:k];
        if ([noteHead accidental] && ![noteHead isAnEditorial]) {
            getNumOct([noteHead staffPosition], mc, &num, &oct);
            ks[num] = [noteHead accidental];
        }
    }
    if (acc = [self hangerAcc])
    {
        getNumOct(staffPosition, mc, &num, &oct);
        ks[num] = acc;
    }
    return self;
}

/* Return notes tied to other than self (return nil if obviously a slur) */

- (NSMutableArray *) tiedWith
{
  TieNew *noteHead;
  NSArray *noteArray;
  NSMutableArray *r;
  GNote *q;
  int nk, k = [hangers count];
    
  r = nil;
  while (k--)
  {
    noteHead = [hangers objectAtIndex:k];
    if ([noteHead graphicType] == TIENEW)
    {
      noteArray = [noteHead clients];
      nk = [noteArray count];
      while (nk--)
      {
        q = [noteArray objectAtIndex:nk];
	if ([q graphicType] == NOTE && q != self)
	{
	  if (q->staffPosition != staffPosition)
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
  NoteHead *noteHead;
    
  k = [headlist count];
  while (k--)
  {
    noteHead = [headlist objectAtIndex:k];
    if ([noteHead accidental] && pos == [noteHead staffPosition]) return [noteHead accidental];
  }
  return 0;
}


- (int) getPatch
{
  if (instrument) return instrument - 1;
  return [instlist soundForInstrument: [self getInstrument]];
}

- (void) setPatch: (unsigned char) newPatch
{
    instrument = newPatch;
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

- (BOOL) moveHead: (NoteHead *) noteHead : (BOOL) locked : (float) dy : (System *) sys
{
  float ny = dy + [noteHead y];
  int np = [[noteHead myNote] staffPositionOfY: ny];
    
  if ([noteHead staffPosition] != np)
  {
    [noteHead setStaffPosition: np];
      [noteHead setCoordinateY: [self yOfStaffPosition: [noteHead staffPosition]]];
    return YES;
  }
  return NO;
}


/* handles move and ALT-move for chords and notes */

- (BOOL)  move: (float) dx : (float) dy : (NSPoint) pt : (System *) sys : (int) alt
{
  NoteHead *noteHead;
  int i, k;
  float ndy;
  float nx = dx + pt.x;
  float ny = dy + pt.y;
  BOOL m = NO, inv;
  BOOL lk = gFlags.locked;
    
  i = gFlags.selend;
  noteHead = [headlist objectAtIndex:i];
  if ([self staffPositionOfY: ny] == [noteHead staffPosition] && ABS(nx - x) < 3.0) return NO;
  ndy = ny - [noteHead y];
  if (alt)
  {
    if (self != lastHit) return NO;
    m = [self moveHead: noteHead : lk : ndy : sys];
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
    float tolerance = nature[gFlags.size];
    int k = [headlist count];
    
    while (k--) {
	NoteHead *noteHead = [headlist objectAtIndex: k];
	float dx = [noteHead isReverseSideOfStem] ? ([self stemIsUp] ? tolerance : -tolerance) * 2.0 : 0.0;

	if (TOLFLOATEQ(pt.x, x + dx, tolerance) && TOLFLOATEQ(pt.y, [noteHead y], tolerance)) {
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
  float d, dmin = MAXFLOAT;
  NoteHead *noteHead;
  float dx, tolerance = nature[gFlags.size];
    
  k = [headlist count];
  while (k--)
  {
      noteHead = [headlist objectAtIndex: k];
      if ([noteHead isReverseSideOfStem]) dx = ([self stemIsUp] ? tolerance : -tolerance) * 2.0; else dx = 0.0;
      d = hypot(pt.x - (x + dx), pt.y - [noteHead y]);
      if (d < dmin) dmin = d;
  }
  return dmin;
}


- (BOOL) hitBeamAt: (float *) px : (float *) py
{
    *px = x + stemdx[(int)gFlags.size][(int)gFlags.subtype][0][(int)time.body][(int)[self stemIsUp]];
    *py = y + [self stemLength];
    return YES;
}


- (float) stemXoff: (int) stype
{
    return stemdx[(int)gFlags.size][(int)gFlags.subtype][stype][time.body][[self stemIsUp]];
}

- (float) stemXoffLeft: (int) stype
{
    return stemdx[(int)gFlags.size][(int)gFlags.subtype][stype][time.body][[self stemIsUp]] -  0.5 * stemthicks[gFlags.size];
}


- (float) stemXoffRight: (int) stype
{
    return stemdx[(int)gFlags.size][(int)gFlags.subtype][stype][time.body][[self stemIsUp]] +  0.5 * stemthicks[gFlags.size];
}


- (float) stemYoff: (int) stype
{
  NoteHead *noteHead = [headlist lastObject];
    
  if ([noteHead isReverseSideOfStem]) return 0.0;
  if ([noteHead bodyType] == 4) return 0.0;
  return stemdy[(int)gFlags.size][(int)gFlags.subtype][stype][time.body][[self stemIsUp]];
}


extern void unionCharBB(NSRect *b, float x, float y, int ch, NSFont *f);
extern float staffthick[3][3];

static void drawacc(float x, NoteHead *noteHead, int ht, int size, int m)
{
  NSRect r;
  float dx;
  NSFont *f = musicFont[(int)accifont[ht][(int)[noteHead accidental]]][size];
    
  x += [noteHead accidentalOffset];
  if ([noteHead isAnEditorial]) {
    dx = 0.5 * nature[size];
    x -= dx;
    r = NSZeroRect;
    unionCharBB(&r, x, [noteHead y], accidents[ht][(int)[noteHead accidental]], f);
    cenclosure([noteHead isAnEditorial] - 1, r.origin.x - dx, r.origin.y - dx, r.origin.x + r.size.width + dx,
               r.origin.y + r.size.height + dx, staffthick[0][size], 0, m);
  }
  DrawCharacterInFont(x, [noteHead y], accidents[ht][(int)[noteHead accidental]], f, m);
}


/* Drawing a note or chord */

extern int modeinvis[5];

/* draw only the stem and flags (used for proximal chord's BB) Stemmed body checked by caller */

- drawStem: (int) m
{
  NoteHead *noteHead;
  int sb, stemType, size;
  float sl;
    
  sb = time.body;
  size = gFlags.size;
  stemType = stype[gFlags.subtype];
  sl = [self stemLength];
  noteHead = [headlist lastObject];
  drawstem(x, [noteHead y], sb, sl, size, [noteHead bodyType], stemType, m);
  if (showSlash && isGraced == 1) drawgrace(x, [noteHead y], sb, sl, size, [noteHead bodyType], stemType, m);
  return self;
}

- drawMember: (int) m
{
    int k, bodyType, size, su, shapeID = 1;
    int ksym, knum, midc;
    float halfWidth=0.0, nx;
    BOOL gotsinfo = NO;
    
    size = gFlags.size;
    su = [self stemIsUp];
    k = [self numberOfNoteHeads];
    while (k--) {
	NoteHead *noteHead = [self noteHead: k];
	
	bodyType = [noteHead bodyType];
	if (bodyType == 6) {
	    if (!gotsinfo) {
		[self getKeyInfo: &ksym : &knum : &midc];
		gotsinfo = YES;
	    }
	    shapeID = getShapeID([noteHead staffPosition], ksym, knum, midc);
	}
	halfWidth = [self halfWidthOfNoteHead: noteHead];
	nx = x;
	if (centhead[bodyType])
	    nx -= halfWidth;
	if ([noteHead isReverseSideOfStem])
	    nx += halfWidth * offside[su];
	drawhead(nx, [noteHead y], bodyType, time.body, shapeID, su, size, m);
	if ([noteHead accidental] && [noteHead accidentalOffset] < 0.0) 
	    drawacc(x, noteHead, bodyType, size, m);
	if ([self dottingCode])
	    drawnotedot(size, x + dotdx, [noteHead y], [noteHead dotOffset], [[noteHead myNote] getSpacing], bodyType, [self dottingCode], 0, m);
    }
    [self drawLedgerAt: halfWidth size: size mode: m];
    return self;
}


- drawMode: (int) drawingMode
{
    struct timeinfo *t = &time;
    NoteHead *noteHead = nil, *q;
    int numberOfNotes, body, bodyType = 0, sb, size = gFlags.size, stemType, isBeamed, shapeID = 0;
    int ksym, knum, midc;
    float nx, dy, halfWidth = 0.0;
    BOOL stemup, gotsinfo = NO;
    
    if ([self myChordGroup] != nil) 
	return [self drawMember: drawingMode];
    stemType = stype[gFlags.subtype];
    isBeamed = [self isBeamed];
    q = [headlist lastObject];
    body = t->body; // TODO should become: [self noteCode];
    numberOfNotes = [headlist count];
    stemup = [self stemIsUp];
    if (numberOfNotes == 1) {
	noteHead = q;
	bodyType = [noteHead bodyType];
	if (bodyType == 6) {
	    [self getKeyInfo: &ksym : &knum : &midc];
	    shapeID = getShapeID([noteHead staffPosition], ksym, knum, midc);
	}
	halfWidth = [self halfWidthOfNoteHead: noteHead];
	drawnote(size, halfWidth, x, [noteHead y], body, bodyType, stemType, shapeID, isBeamed, [self stemLength], [self hasNoStem], (showSlash && isGraced == 1), drawingMode);
	if ([noteHead accidental] && [noteHead accidentalOffset] < 0.0)
	    drawacc(x, noteHead, bodyType, size, drawingMode);
	if ([self isDotted])
	    drawnotedot(size, x + dotdx, [noteHead y], [noteHead dotOffset], [[noteHead myNote] getSpacing], bodyType, [self dottingCode], 0, drawingMode);
    }
    else {
	int noteIndex = numberOfNotes;
	
	while (noteIndex--) {
	    noteHead = [headlist objectAtIndex: noteIndex];
	    bodyType = [noteHead bodyType];
	    if (bodyType == 6) {
		if (!gotsinfo) {
		    [self getKeyInfo: &ksym : &knum : &midc];
		    gotsinfo = YES;
		}
		shapeID = getShapeID([noteHead staffPosition], ksym, knum, midc);
	    }
	    halfWidth = [self halfWidthOfNoteHead: noteHead];
	    nx = x;
	    if (centhead[bodyType]) 
		nx -= halfWidth;
	    if ([noteHead isReverseSideOfStem]) 
		nx += halfWidth * offside[(int)stemup];
	    drawhead(nx, [noteHead y], bodyType, body, shapeID, stemup, size, drawingMode);
	    if ([noteHead accidental] && [noteHead accidentalOffset] < 0.0) 
		drawacc(x, noteHead, bodyType, size, drawingMode);
	    if ([self isDotted])
		drawnotedot(size, x + dotdx, [noteHead y], [noteHead dotOffset], [[noteHead myNote] getSpacing], bodyType, [self dottingCode], 0, drawingMode);
	}
	/* Note: noteHead will now be [headlist objectAt: 0], with valid bodyType, f, halfWidth */
	if (hasstem[body] && (!isBeamed || numberOfNotes > 1))	{
	    dy = [q y] - [noteHead y];
	    if (isBeamed) 
		sb = 5;
	    else {
		dy += [self stemLength];
		sb = body;
	    }
	    drawstem(x, [noteHead y], sb, dy, size, bodyType, stemType, drawingMode);
	    if (showSlash && isGraced == 1) 
		drawgrace(x, [q y], sb, [self stemLength], size, bodyType, stemType, drawingMode);
	}
    }
    [self drawLedgerAt: halfWidth size: size mode: drawingMode];
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
  NoteHead *noteHead;
  char b1, b2, b3, b4, b5, b6, b7, acc=0, edacc;
   
  NSLog(@"Reading old GNote format v%d\n", v);
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
    float halfWidth;
    int size, bodyType, stemType;
    NSFont *f;
    struct timeinfo *ti;
    size = gFlags.size;
    bodyType = gFlags.subtype;
    stemType = stype[gFlags.subtype];
    headlist = [[NSMutableArray alloc] init];
    noteHead = [[NoteHead alloc] init];
      [noteHead setBodyType: bodyType];
      [noteHead setStaffPosition: staffPosition];
      [noteHead setAccidental: acc];
      [noteHead setCoordinateY: y];
      [noteHead setNote: self];
    ti = (!(gFlags.selected) && (figtime.body != 0)) ? &figtime : &time;
    f = musicFont[headfont[bodyType][ti->body]][size];
    halfWidth = halfwidth[size][bodyType][ti->body];
    [noteHead setAccidentalOffset: -halfWidth - charFGW(f, accidents[bodyType][(int)acc]) - 2.0];
    [noteHead setDotOffset: (staffPosition & 1) ? 0 : -1];
    dotdx = getdotx(size, bodyType, 0, ti->body, [self isBeamed], ti->stemup);
    [(NSMutableArray *)headlist addObject: noteHead];
  }
  return self;
}

extern void readTimeData2(NSCoder *s, struct timeinfo *t); /*sb; changed from NSArchiver after conversion */

- (id)initWithCoder:(NSCoder *)aDecoder
{
  struct timeinfo figtime;
  int v = [aDecoder versionForClassName:@"GNote"];
    
    // NSLog(@"Before decoding GNote v%d superclass %p\n", v, super);
  [super initWithCoder:aDecoder];
  instrument = 0;
  showSlash = 0;
  if (v == 9) {
      NSLog(@"before GNote %p decoding headlist\n", self);
      headlist = [[aDecoder decodeObject] retain];
      NSLog(@"headlist = %@, retainCount = %d\n", headlist, [headlist retainCount]);
     [aDecoder decodeValuesOfObjCTypes:"fcc", &dotdx, &instrument, &showSlash];
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
    int noteIndex = [headlist count];
    while (noteIndex--) {
	NoteHead *noteHead = [headlist objectAtIndex:noteIndex];
	if ([[noteHead myNote] graphicType] != NOTE) 
	    [noteHead setNote: self];
    }
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:headlist];
  [aCoder encodeValuesOfObjCTypes:"fcc", &dotdx, &instrument, &showSlash];
}

- (void) encodeWithPropertyListCoder: (OAPropertyListCoder *) aCoder
{
    [super encodeWithPropertyListCoder: (OAPropertyListCoder *) aCoder];
    [aCoder setObject: headlist forKey: @"headlist"];
    [aCoder setFloat: dotdx forKey: @"dotdx"];
    [aCoder setInteger: instrument forKey: @"inst"];
    [aCoder setInteger: showSlash forKey: @"slash"];
}


@end
