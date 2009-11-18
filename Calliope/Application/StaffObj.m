/* $Id$ */
#import <Foundation/Foundation.h>
#import "StaffObj.h"
#import "Staff.h"
#import "System.h"
#import "Hanger.h"
#import "Beam.h"
#import "Accent.h"
#import "KeySig.h"
#import "Clef.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "GVSelection.h"
#import "GVFormat.h"
#import "Verse.h"
#import "Metro.h"
#import "CallPart.h"
#import "CallInst.h"
#import "TextGraphic.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "FileCompatibility.h"


int protoVox;

@implementation StaffObj


+ (void)initialize
{
  if (self == [StaffObj class])
  {
      (void)[StaffObj setVersion: 7]; /* class version, see read: */ /*sb: bumped up to 7 for OS conversion */
  }
  return;
}

- init
{
    self = [super init];
    if(self != nil) {
	hangers = nil;
	verses = nil;
	mystaff = nil;
	isGraced = 0;
	versepos = 0;
	part = nil;	
    }
    return self;
}

- (void) dealloc
{
    [hangers release];
    hangers = nil;
    [verses release];
    verses = nil;
    [part release];
    part = nil;
    [super dealloc];
}


- sysInvalid
{
  return [mystaff sysInvalid];
}


- (int) barCount
{
  return 0;
}


/* left and right bearing (all relative to self's x) option to include any enclosure */

- (float) leftBearing: (BOOL) enc
{
  Graphic *q;
  int k;
  float r, b;
  r = x - bounds.origin.x;
  if (enc)
  {
    k = [enclosures count];
    while (k--)
    {
      q = [enclosures objectAtIndex:k];
      b = x - LEFTBOUND(q);
      if (b > r) r = b;
    }
  }
  return r;
}


- (float) rightBearing: (BOOL) enc
{
  Graphic *q;
  int k;
  float r, b;
  r = bounds.origin.x + bounds.size.width - x;
  if (enc)
  {
    k = [enclosures count];
    while (k--)
    {
      q = [enclosures objectAtIndex:k];
      b = RIGHTBOUND(q) - x;
      if (b > r) r = b;
    }
  }
  return r;
}



- (void)moveBy:(float)dx :(float)dy
{
  int k;
  if (!gFlags.morphed) return;
  x += dx;
  y += dy;
  k = [hangers count];
  while (k--) [[hangers objectAtIndex:k] moveBy:dx :dy];
  k = [verses count];
  while (k--) [[verses objectAtIndex:k] moveBy:dx :dy];
  [super moveBy:dx :dy];
}


- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  staffPosition = 0;
  selver = 0;
  x = pt.x;
  y = pt.y;
  mystaff = sp;
  gFlags.size = sp->gFlags.size;
  return self;
}


- reShape
{
  [self recalc];
  [self setOwnHangers];
  [self setVerses];
  return self;
}


- rePosition
{
  return self;
}


/*
  find right place in current page to link an object having valid y but no mystaff.
  Does recache and recalc here.
*/

- (BOOL) linkPaste: (GraphicView *) v
{
  Staff *sp;
  System *sys = [v findSys: y];
  sp = [sys findOnlyStaff: y];
  [sp linknote: self];
  [self rePosition];
  [self reCache: [sp yOfTop] : sp->flags.spacing];
  [self recalc];
  return YES;
}


/*
  Starting at self, scan along mystaff, unioning bounds, until the
  object of type t is encountered.  Used for updating transposed sections.
  sender inits b to self's bounds.
*/

- transBounds: (NSRect *) b : (int) t;
{
  int j, k;
  NSMutableArray *nl;
  StaffObj *q;
  NSRect qb;
  BOOL f = NO;

  nl = mystaff->notes;
  k = [nl count];
  j = [nl indexOfObject:self] + 1;
  while (j < k && !f)
  {
    q = [nl objectAtIndex:j];
    if ([q graphicType] == t) f = YES;
    else
    {
      graphicBBox(&qb, q);
      *b  = NSUnionRect(qb , *b);
    }
    ++j;
  }
  return self;
}


- (BOOL) reCache: (float) sy : (int) ss
{
  if (sy == y) return NO;
  y = sy;
  return YES;
}


/* put all components into the (context dependent) default state */

- reDefault
{
  float sy = [mystaff yOfTop];
  [self reCache: sy : getSpacing(mystaff)];
  return [self reShape];
}


/* return x, y for mover */
 
- (BOOL) getXY: (float *) rx : (float *) ry
{
  *rx = x;
  *ry = y;
  return YES;
}


- (float) headY: (int) n
{
  return y;
}

/* catch if subclass cannot handle */

- (float) noteEval: (BOOL) f
{
  return 0;
}

- (float) verseOrigin
{
  return 0.0;
}

/* various relays to self's staff */

- (int) getSpacing
{
    if (mystaff != nil)
	return mystaff->flags.spacing;
    else 
	return 4;
}

- (int) getLines
{
    if (mystaff != nil)
	return mystaff->flags.nlines;
    else
	return 5;
}

/* find the keysym, num and middleC of the controlling key signature and clef */

- (void)getKeyInfo: (int *) s : (int *) n : (int *) c
{
  KeySig *ks;
  Clef *cl;
  if (mystaff == nil)
  {
    *s = 0;
    *n = 0;
    *c = 10;
    return;
  }
  ks = [mystaff searchType: KEY : self];
  if (ks == nil)
  {
    *s = 0;
    *n = 0;
  }
  else [ks myKeyInfo: s : n];
  cl = [mystaff searchType: CLEF : self];
  if (cl == nil)
  {
    *c = 10;
  }
  else
  {
    *c = [cl middleC];
  }
  return;
}


/* the default, used for calculating beam direction */

- (int) midPosOff
{
  return staffPosition - ([self getLines] - 1);
}


- (float) yMean
{
  return bounds.origin.y + 0.5 * bounds.size.height;
}


/* return positions at extremities (a = above) (the catchall) */


- (BOOL) validAboveBelow: (int) a
{
  return YES;
}


- (int) posAboveBelow: (int) a
{
  if (a) return [mystaff findPos: bounds.origin.y];
  return [mystaff findPos: bounds.origin.y + bounds.size.height];
}

/* by default the next three are identical */

- (float) yAboveBelow: (int) a
{
  if (a) return bounds.origin.y;
  return bounds.origin.y + bounds.size.height;
}


- (float) boundAboveBelow: (int) a
{
  if (a) return bounds.origin.y;
  return bounds.origin.y + bounds.size.height;
}


- (float) wantsStemY: (int) a
{
  if (a) return bounds.origin.y;
  return bounds.origin.y + bounds.size.height;
}


- (int) posOfY: (float) sy
{
  return [mystaff findPos: sy];
}


- (float) yOfPos: (int) ip
{
  return [mystaff yOfPos: ip];
}


- (float) yOfTopLine
{
  return [mystaff yOfTop];
}


- (float) yOfBottomLine
{
  return [mystaff yOfBottom];
}


/* return system the receiver is associated with */
- (System *) mySystem
{
    return mystaff->mysys;
}


/* return view self is associated with */

- (GraphicView *) pageView
{
    return [[self mySystem] pageView];
}

- (Staff *) staff
{
    return mystaff;
}

- (void) setStaff: (Staff *) newStaff
{
    mystaff = newStaff; // weakly held. Don't retain since it is a backpointer.
}

/* return index of system on which object appears */
- (int) sysNum
{
    GraphicView *v = [self pageView];
    
    return [[v allSystems] indexOfObject: [self mySystem]];
}


/* return index of staff notes I am in */

- (int) myIndex
{
  return [mystaff->notes indexOfObject: self];
}


- (NSString *) getInstrument
{
  if (part == nil) return [mystaff getInstrument];
  if (part == nullPart) return [mystaff getInstrument];
  return [[[CalliopeAppController sharedApplicationController] getPartlist] instrumentForPart: part];
}


- (int) whereInstrument
{
  return (part == nil) ? 2 : 1;
}


- (NSString *) getPart
{
  if (part == nil) return [mystaff getPart];
  if (part == nullPart) return [mystaff getPart];
  return part;
}


- (int) getChannel
{
  if (part == nil) return [mystaff getChannel];
  if (part == nullPart) [mystaff getChannel];
  return [[[CalliopeAppController sharedApplicationController] getPartlist] channelForPart: part];
}


- makeName: (int) i
{
  TextGraphic *t;
  NSString *s = nil;
  NSString *n = [self getPart];
  CallPart *cp;
  CallInst *ci;
  Staff *sp;
  float ty;
  cp = [[[CalliopeAppController sharedApplicationController] getPartlist] partNamed: n];
  if (cp == nil) return nil;
  switch(i)
  {
    case 0:
      s = n;
      break;
    case 1:
      s = cp->abbrev;
      break;
    case 2:
      ci = [instlist instNamed: cp->instrument];
      if (ci == nil) return nil;
      s = ci->name;
      break;
    case 3:
      ci = [instlist instNamed: cp->instrument];
      if (ci == nil) return nil;
      s = ci->abbrev;
      break;
  }
  if (s == nil) return nil;
  if (![s length]) return nil;
  sp = mystaff;
  t = [[TextGraphic alloc] init];
  SUBTYPEOF(t) = LABEL;
  t->just = 0;
  t->horizpos = 0;
  t->client = self;
  t->offset.x = 0;
  ty = bounds.origin.y;
  if ([sp yOfTop] < ty) ty = [sp yOfTop];
  t->offset.y = (ty - 10) - y;
  [self linkhanger: t];
  [t initFromString: s : [[CalliopeAppController currentDocument] getPreferenceAsFont: TEXFONT]];
  t->offset.x = -(t->bounds.size.width + 8);
  t->offset.y -= (t->bounds.size.height);
  return t;
}


/* return left or right end of staff depending on e */

- (float) xOfStaffEnd: (BOOL) e
{
  id sp = mystaff;
  return e ? [sp xOfEnd] : [sp xOfHyphmarg] + 2 * ((Staff *)sp)->flags.spacing;
}


/*
  very tricky.  removeObj removes the hanger, but also causes
  self to be called back via unlinkhanger to alter hangers.  Hence loop
  counting from end should work.
*/

- (void)removeObj
{
    int k;
    [self retain]; // TODO highly suspicious
    k = [enclosures count];
    while (k--) [[enclosures objectAtIndex:k] removeObj];
    k = [hangers count];
    while (k--) [[hangers objectAtIndex:k] removeObj];
    k = [verses count];
    while (k--) [[verses objectAtIndex:k] removeObj];
    [mystaff unlinknote: self];
    [self release];  // TODO highly suspicious
}


- linkhanger: q
{
  if (hangers == nil) hangers = [[NSMutableArray alloc] init];
  [hangers addObject: q];
  return self;
}


- unlinkhanger: q
{
    int theLocation = [hangers indexOfObject:q];
    if (theLocation != NSNotFound) [hangers removeObjectAtIndex: theLocation];
    return self;
}


- (BOOL) hasHanger: h
{
  return ([hangers indexOfObject:h] != NSNotFound);
}


- (int) hasHangers
{
  return [hangers count];
}


- recalcVerses
{
  Verse *v;
  int k = [verses count];
  while (k--)
  {
    v = [verses objectAtIndex:k];
    [v recalc];
    [v recalcHangers];
  }
  return self;
}


- setVerses
{
  int i, j, k;
  Verse *v;
  k = [verses count];
  j = -1;
  for (i = 0; i < k; i++)
  {
    v = [verses objectAtIndex:i];
    v->vFlags.num = i;
    if (!ISINVIS(v)) ++j;
    v->vFlags.line = j;
    v->note = self;
    [v reShape];
    [v recalc];
  } 
  return self;
}


- justVerses
{
  Verse *v, *a;
  int n = [verses count];
  int sn = selver;
  int i, l;
  if (n > 0 && sn >= 0 && sn < n)
  {
    a = [verses objectAtIndex:sn];
    for (i = 0; i < n; i++) if (i != sn)
    {
      v = [verses objectAtIndex:i];
      v->gFlags.subtype = a->gFlags.subtype;
      v->offset = 0;
      [v alignVerse];
    }
    switch(gFlags.subtype)
    {
      case 0:
        break;
      case 1:
        l = a->align - a->offset;
        for (i = 0; i < n; i++) if (i != sn)
        {
          v = [verses objectAtIndex:i];
          v->offset = -l + v->align;
        }
        break;
      case 2:
        l = a->pixlen - a->align + a->offset;
        for (i = 0; i < n; i++) if (i != sn)
        {
          v = [verses objectAtIndex:i];
          v->offset = l - (v->pixlen - v->align + v->offset);
        }
        break;
    }
  }
  return self;
}


- verseWidths: (float *) tb : (float *) ta
{
  Verse *v;
  int k;
  float tat, tbt, mta, mtb;
  mta = mtb = 0;
  if (verses != nil)
  {
    k = [verses count];
    while (k--)
    {
      v = [verses objectAtIndex:k];
      if (ISINVIS(v)) continue;
      tat = v->pixlen;
      tbt = v->align;
      tat -= tbt;
      tat += charFGW(v->font, HYPHCHAR);
      if (v->vFlags.hyphen == 1) tat += charFGW(v->font, HYPHCHAR);
      if (v->offset)
      {
        tbt -= v->offset;
        tat += v->offset;
      }
      if (tat > mta) mta = tat;
      if (tbt > mtb) mtb = tbt;
    }
  }
  *ta = mta;
  *tb = mtb;
  return self;
}


/* return a suitable selver for g knowing self's selver (= corresp visible verse) */

- (int) verseNeighbour: (StaffObj *) g
{
  Verse *v=nil;
  int n, k;
  NSMutableArray *gl;
  if (selver >= 0 && selver < [verses count]) v = [verses objectAtIndex:selver];
  if (v == nil) return selver;
  n = v->vFlags.line;
  gl = g->verses;
  k = [gl count];
  while (k--)
  {
    v = [gl objectAtIndex:k];
    if (v->vFlags.line <= n) return k;
  }
  return selver;
}


/*
  propagate the selected bit to each of the hangers, enclosures and verses.
*/

- (BOOL)selectHangers:(id)sl : (int) b
{
  int k;
  Graphic *g;
  BOOL slChanged = NO;
  if ([super selectHangers:sl : b]) slChanged = YES;
  if (hangers != nil)
  {
    k = [hangers count];
    while (k--)
    {
        g = [hangers objectAtIndex:k];
        if ([g selectHangers:sl : b]) slChanged = YES;  /* any enclosed hangers */
//      g->gFlags.selected = b;
        if ([g selectMe:sl :0 :b]) slChanged = YES;
    }
  }
  if (verses != nil)
  {
    k = [verses count];
    while (k--)
    {
        g = [verses objectAtIndex:k];
        if ([g selectHangers:sl : b]) slChanged = YES;  /* any enclosed hangers */
        g->gFlags.selected = b;
    }
  }
  return slChanged;
}

/* remove/modify any hangers that have clients not on l */

- closeHangers: (NSMutableArray *) l
{
  Hanger *q;
  int k = [hangers count];
  [super closeHangers: l];
  while (k--) 
  {
    q = [hangers objectAtIndex:k];
    if (![q isClosed: l]) [q removeObj];
  }
  return self;
}


/* find first metronome mark */

- findMetro
{
  Metro *q;
  int k = [hangers count];
  while (k--)
  {
    q = [hangers objectAtIndex:k];
    if ([q graphicType] == METRO) return q;
  }
  return nil;
}


- (BOOL) hasVoltaBesides: (NoteGroup *) v
{
  NoteGroup *q;
  int k = [hangers count];
  while (k--)
  {
    q = [hangers objectAtIndex:k];
    if ([q graphicType] == GROUP && SUBTYPEOF(q) == GROUPVOLTA && q != v) return YES;
  }
  return NO;
}


- (BOOL) hasCrossingBeam
{
  Beam *b;
  int k = [hangers count];
  while (k--)
  {
    b = [hangers objectAtIndex:k];
    if ([b graphicType] == BEAM && [b isCrossingBeam]) return YES;
  }
  return NO;
}


/* return whether p has a hanging accidental (used for editorial accidentals) */

- (int) hangerAcc
{
  int k, s;
  Accent *q;
  if (hangers == nil) return 0;
  k = [hangers count];
  while (k--)
  {
    q = [hangers objectAtIndex:k];
    if ([q graphicType] == ACCENT)
    {
      s = [q hasAccidental];
      if (s) return s;
    }
  }
  return 0;
}


- (BOOL) hangerAccSticks
{
  int k;
  Accent *q;
  if (hangers == nil) return NO;
  k = [hangers count];
  while (k--)
  {
    q = [hangers objectAtIndex: k];
    if ([q graphicType] == ACCENT && q->accstick) return YES;
  }
  return NO;
}


/* return whether p has a hanging ottava */

- (int) hangerOtt
{
  int k, s;
  Accent *q;
  if (hangers == nil) return 0;
  k = [hangers count];
  while (k--)
  {
    q = [hangers objectAtIndex:k];
    if ([q graphicType] == ACCENT)
    {
      s = [q hasOttava];
      if (s) return s;
    }
  }
  return 0;
}


- unlinkverse: v
{
    int theLocation = [verses indexOfObject:v];
    if (theLocation != NSNotFound) [verses removeObjectAtIndex: theLocation];
    return self;
}

- (BOOL) hasAnyVerse
{
    Verse *v;
    int k = [verses count];
    
    while (k--) {
	v = [verses objectAtIndex: k];
	if (![v isBlank]) 
	    return YES;
    }
    return NO;
}


/* remove verses below the lowest non-blank line */

- trimVerses
{
    Verse *v;
    int k = [verses count];
    
    while (k--) {
	v = [verses objectAtIndex: k];
	if (![v isBlank])
	    return self;
	[verses removeObjectAtIndex: k];
	if (selver >= k) 
	    selver = k - 1;
    }
    return self;
}


/* default: doesn't stop verse */

- (BOOL) stopsVerse
{
  return NO;
}


/* note that a hit on a verse returns the staff obj */
- (void) searchFor: (NSPoint) pt inObjects: (NSMutableArray *) arr
{
  id q = nil;
  int k = [hangers count];
  [super searchFor: pt inObjects: arr];
  while (k--)
  {
    q = [hangers objectAtIndex:k];
    if ([q hit: pt])
        if (![arr containsObject:q])
            [arr addObject:q];
    [q searchFor: pt inObjects: arr];
  }
  k = [verses count];
  while (k--)
  {
    q = [verses objectAtIndex:k];
    if (!ISINVIS(q))
    {
      if ([q hit: pt])
      {
        selver = k;
        gFlags.selbit = 1;
        if (![arr containsObject:q])
            [arr addObject:q];
      }
        [q searchFor: pt inObjects: arr];
    }
  }
  return;
}


- (Verse *) verseOf: (int) i
{
  if (verses == nil) return nil;
    if ([verses count] <= i || i < 0) return NO;
  return [verses objectAtIndex:i];
}


- (BOOL) hasVerseText: (int) i
{
    Verse *v;
    
    if (verses == nil) 
	return NO;
    if ([verses count] <= i || i < 0)
	return NO;
    v = [verses objectAtIndex: i];
    if (v == nil) 
	return NO;
    return(![v isBlank]);
}

- (BOOL) continuesLine: (int) i
{
    Verse *v;
    
    if (verses == nil) 
	return NO;
    if ([verses count] <= i || i < 0) 
	return NO;
    v = [verses objectAtIndex: i];
    if (v == nil) 
	return NO;
    if ([v isBlank])
	return NO;
    return([[v string] characterAtIndex: 0] == CONTLINE);
}


- (int) verseHyphenOf: (int) i
{
  Verse *v;
  if (verses == nil) return -1;
  if ([verses count] <= i || i < 0) return -1;
  v = [verses objectAtIndex:i];
  if (v == nil) return -1;
  if ([v isBlank]) return -1;
  return v->vFlags.hyphen;
}


- copyVerseFrom: (StaffObj *) q
{
  int i, kpv;
  NSMutableArray *pv;
  Staff *sp;
  if (verses != nil)
  {
    while ([verses count]) [[verses lastObject] removeObj];
      [verses autorelease];
    verses = nil;
  }
  pv = q->verses;
  kpv = [pv count];
  if (kpv == 0) return [self setVerses];
  verses = [[NSMutableArray alloc] init];
  for (i = 0; i < kpv; i++) [verses addObject: [[pv objectAtIndex:i] newFrom]];
  [self setVerses];
  sp = mystaff;
  [[mystaff measureStaff] resetStaff: [sp yOfTop]];
  return self;
}



/* tries all visible verses until wraparound */

- (int) incSelver: (int) i : (int) k
{
  Verse *v;
  int s, t;
  BOOL nf = YES;
  s = t = selver;
  do
  {
    s += i;
    if (s < 0) s = k - 1; else if (s >= k) s = 0;
    if (s == t) return t;
    v = [verses objectAtIndex:s];
    nf = v->gFlags.invis;
  } while(nf);
  return s;
}


static char cycleHyphen[7] = {0, 3, 4, 5, 6, 1, 2};

- (BOOL) performKey: (int) c
{
  GraphicView *view;
  Verse *v=nil,*vv=nil;
  BOOL r = NO;
  switch(c)
  {
    case '[':
        if (verses == nil) break;
        view = [self pageView];
        [view deselectAll: self];
        if (selver >= 0 && selver < [verses count]) vv = [verses objectAtIndex:selver];
        [view selectObj: vv];
        [view pressTool: ENCLOSURE withArgument: 0];
        r = YES;
        break;
    case 'r':
        if (verses == nil) break;
        if (selver >= 0 && selver < [verses count]) v = [verses objectAtIndex:selver];
        if (!v) break;
        v->vFlags.hyphen = cycleHyphen[v->vFlags.hyphen];
        r = YES;
        break;
  }
  if (r)
  {
    [self reShape];
    [self recalc];
    [self setOwnHangers];
    return YES;
  }
  else return [super performKey: c];
}


- (int) keyDownString: (NSString *) cc
{
    int k, r;
    Verse *v = nil;
    Staff *sp;
    
//  if (cs == NX_SYMBOLSET)
//  if ([cc canBeConvertedToEncoding:NSSymbolStringEncoding])
    if (![cc canBeConvertedToEncoding:NSNEXTSTEPStringEncoding]) {
	if (verses == nil) 
	    return -1;
	r = -1;
	k = [verses count];
	switch([cc characterAtIndex: 0]) {
	    case NSUpArrowFunctionKey:
		selver = [self incSelver: -1 : k];
		r = 1;
		break;
	    case NSDownArrowFunctionKey:
		selver = [self incSelver: 1 : k];
		r = 1;
		break;
	    case NSLeftArrowFunctionKey:
		if (selver < k && selver >= 0) v = [verses objectAtIndex:selver];
		if (v != nil) {
		    v->offset--;
		    [v recalc];
		}
		r = 1;
		break;
	    case NSRightArrowFunctionKey:
		if (selver < k && selver >= 0) v = [verses objectAtIndex:selver];
		if (v != nil) {
		    v->offset++;
		    [v recalc];
		}
		r = 1;
		break;
	}
	return r;
    }
    /* check if deleting a verse or character */
    v = nil;
    k = [verses count];
    if (*[cc UTF8String] == 127) {
	if (verses == nil) {
	    NSLog(@"keyDownString: verses = nil"); 
	    return 0; 
	}
	if (selver >= 0 && (selver < k))  
	    v = [verses objectAtIndex: selver];
	if (v == nil) {
	    NSLog(@"keyDownString: v = nil");
	    return 0;
	}
	
	if ([v isBlank]) {
	    [self unlinkverse: v];
	    k = [verses count];
	    if (selver >= k) selver = k - 1;
	    sp = mystaff;
	    [[sp measureStaff] resetStaff: [sp yOfTop]];
	    return 1;
	}
	else { /*sb: what a gross hack. All to convert to NSASCIIStringEncoding. Bah. */
	    char temp[2];
	    temp[0] = 127;
	    temp[1] = 0;
	    return [v keyDownString:[[[NSString alloc] initWithData:[NSData dataWithBytes:temp length:1] encoding:NSASCIIStringEncoding] autorelease]];
	}
    }
    /* check if adding a verse or character */
    v = nil;
    if (verses == nil) 
	verses = [[NSMutableArray alloc] init];
    else {
	if (selver >= 0 && selver < [verses count])
	    v = [verses objectAtIndex:selver];
    }
    if (v == nil || *[cc UTF8String] == '\n' || *[cc UTF8String] == '\r') {
	k = [verses count];
	if (k + 1 >= MAXTEXT) {
	    NSLog(@"k + 1 >= MAXTEXT");
	    return 0; 
	}
	v = [[Verse alloc] init];
	[verses addObject: v];
	v->note = self;
	if (k == 0) 
	    [v keyDownString: cc];
	[self setVerses];
	v->gFlags.selected = 1;
	selver = [verses indexOfObject:v];
	sp = mystaff;
	[[sp measureStaff] resetStaff: [sp yOfTop]];
    }
    else {
	return [v keyDownString:cc];
    }
    return 1;
}


- (NSFont *) getVFont
{
    Verse *v=nil;
    NSFont *r = nil;
    if (verses) {
        if ([verses count] > selver && selver >= 0) v = [verses objectAtIndex:selver];
    }
    if (v != nil) r = v->font;
    else r = [[CalliopeAppController currentDocument] getPreferenceAsFont: TEXFONT];
    return r;
}


- (BOOL) changeVFont: (NSFont *) f : (BOOL) all
{
  Verse *v=nil;
  int k;
  BOOL r = NO;
  if (all)
  {
    k = [verses count];
    while (k--)
    {
      v = [verses objectAtIndex:k];
      v->font = f;
      r = YES;
    }
  }
  else
  {
    if (selver >= 0 && selver < [verses count]) v = [verses objectAtIndex:selver];
    if (v != nil)
    {
      v->font = f;
      r = YES;
    }
  }
  return r;
}


/* Caller does the setHangers that matches the markHangers here */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : (System *) sys : (int) alt
{
  float nx = dx + pt.x;
  float ny = dy + pt.y;
  BOOL m = NO, inv;
  if (abs(ny - y) > 1 || abs(nx - x) > 1)
  {
    m = YES;
    x = nx;
    y = ny;
    inv = [sys relinknote: self];
    [self recalc];
    [self markHangers];
    [self setVerses];
  }
  return m;
}


/* a very important little step */

- moveFinished: (GraphicView *) v
{
  return [self setHangers];
}


/* Hangers are recalc'd, reset, drawn in two passes to prevent multiple work */

- markHangers
{
  int k;
  Hanger *h;
  Verse *v;
  [super markHangers];
  k = [hangers count];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    [h markHangers];  /* for any enclosed hangers */
    h->gFlags.morphed = 1;
  }
  k = [verses count];
  while (k--)
  {
    v = [verses objectAtIndex:k];
    [v markHangers];  /* for any enclosed hangers */
    v->gFlags.morphed = 1;
  }
  return self;
}


- markHangersExcept: (Hanger *) q
{
  int k;
  Hanger *h;
  Verse *v;
  
  [super markHangersExcept: q];
  k = [hangers count];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    if (h != q)
    {
      [h markHangersExcept: q];
      h->gFlags.morphed = 1;
    }
  }
  k = [verses count];
  while (k--)
  {
    v = [verses objectAtIndex:k];
    if (v != q) // LMS TODO very troubling! Verse != Hanger?
    {
      [v markHangersExcept: q];
      v->gFlags.morphed = 1;
    }
  }
  return self;
}


- recalcHangers
{
  Hanger *h;
  Verse *v;
  int k = [hangers count];
  [super recalcHangers];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    if (h->gFlags.morphed)
    {
      [h recalc];
      [h recalcHangers];
      h->gFlags.morphed = 0;
    }
  }
  k = [verses count];
  while (k--)
  {
    v = [verses objectAtIndex:k];
    if (v->gFlags.morphed)
    {
      [v recalc];
      [v recalcHangers];
      v->gFlags.morphed = 0;
    }
  }
  return self;
}

/* setSize clears morphed */

- resizeHangers: (int) ds
{
  Hanger *h;
  int k = [hangers count];
  [super resizeHangers: ds];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    [h resizeHangers: ds];
    if (h->gFlags.morphed) [h setSize:ds];
  }
  return self;
}


- setHangersOnly: (int) t
{
  Hanger *h;
  int k = [hangers count];
  [super setHangersOnly: t];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    if (h->gFlags.morphed && [h graphicType] == t)
    {
      [h setHanger];
      h->gFlags.morphed = 0;
    }
    [h setHangersOnly: t];
  }
  return self;
}


- setHangersExcept: (int) t
{
  Hanger *h;
  int k = [hangers count];
  [super setHangersExcept: t];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    if (h->gFlags.morphed && [h graphicType] != t)
    {
      [h setHanger];
      h->gFlags.morphed = 0;
    }
    [h setHangersExcept: t];
  }
  return self;
}


/* assumes that markHangers has been called first */

- setHangers
{
  [self setHangersOnly: BEAM];
  [self setHangersExcept: BEAM];
  return self;
}


/* this is called only when markHangers has not been called first. */

- setOwnHangers
{
  Hanger *h;
  int k, c = [hangers count];
  k = c;
  [super setOwnHangers];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    if ([h graphicType] == BEAM)
    {
      [h setHanger];
      [h setOwnHangers];
    }
  }
  k = c;
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    if ([h graphicType] != BEAM)
    {
      [h setHanger];
      [h setOwnHangers];
    }
  }
  return self;
}

/* code for dealing with the level of hangers */

- (int) maxGroupLevel
{
  int i, m = -1;
  int k = [hangers count];
  while (k--)
  {
    i = [[hangers objectAtIndex:k] myLevel];
    if (i > m) m = i;
  }
  return m;
}


/* Groups are marked before renumbering to prevent duplicity */

- markGroups
{
  int k;
  Hanger *h;
  k = [hangers count];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    h->gFlags.morphed = 1;
  }
  return self;
}


/* all Group levels above lev are decremented */

- renumberGroups: (int) lev
{
    int k = [hangers count];

    while (k--) {
	Hanger *h = [hangers objectAtIndex: k];

	if (h->gFlags.morphed) {
	    int i = [h myLevel];

	    if (i > lev) 
		[h setLevel: i - 1];
	    h->gFlags.morphed = 0;
	}
    }
    return self;
}





- drawHangers: (NSRect) r nonSelectedOnly: (BOOL) nso
{
  Hanger *h;
  int k = [hangers count];
  [super drawHangers: r nonSelectedOnly: nso];
  while (k--)
  {
    h = [hangers objectAtIndex:k];
    if (h->gFlags.morphed)
    {
      [h drawHangers: r nonSelectedOnly: nso];
      [h draw: r nonSelectedOnly: nso];
      h->gFlags.morphed = 0;
    }
  }
  return self;
}


- drawVerses: (NSRect) r nonSelectedOnly: (BOOL) nso
{
  Verse *v;
  int k;
  if (verses != nil)
  {
    k = [verses count];
    while (k--)
    {
      v = [verses objectAtIndex:k];
      if (!ISINVIS(v))
      {
        [v drawHangers: r nonSelectedOnly: nso];
        [v draw: r nonSelectedOnly: nso];
      }
    }
  }
  return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    char c1;
    int v = [aDecoder versionForClassName:@"StaffObj"];

    [super initWithCoder:aDecoder];
    /* NSLog(@"reading StaffObj v%d\n", v); */
    part = nil;
    
    mystaff = [[aDecoder decodeObject] retain];
    if ([mystaff graphicType] != STAFF) {
	NSLog(@"mystaff != STAFF, need to convert!");
	// TODO I think earlier versions can decode this as System, not a Staff. Need to handle accordingly and based on file version number.
    }
    
    if (v < 2)
    {
	[aDecoder decodeValuesOfObjCTypes:"@@ccff", &hangers, &verses, &staffPosition, &selver, &x, &y];
	voice = 0;
    }
    else if (v == 2)
    {
	[aDecoder decodeValuesOfObjCTypes:"@@cccff", &hangers, &verses, &staffPosition, &selver, &isGraced, &x, &y];
	voice = 0;
    }
    else if (v == 3)
    {
	[aDecoder decodeValuesOfObjCTypes:"@@ccccfff", &hangers, &verses, &staffPosition, &selver, &isGraced, &voice, &x, &y, &stamp];
    }
    else if (v == 4)
    {
	[aDecoder decodeValuesOfObjCTypes:"ccccc", &staffPosition, &selver, &isGraced, &voice, &versepos];
	[aDecoder decodeValuesOfObjCTypes:"@@", &hangers, &verses];
	[aDecoder decodeValuesOfObjCTypes:"ff", &x, &y];
    }
    else if (v == 5)
    {
	[aDecoder decodeValuesOfObjCTypes:"cccccc", &staffPosition, &selver, &isGraced, &voice, &versepos, &c1];
	part = [NSString stringWithFormat: @"%d", c1];
	[aDecoder decodeValuesOfObjCTypes:"@@", &hangers, &verses];
	[aDecoder decodeValuesOfObjCTypes:"ff", &x, &y];
    }
    else if (v == 6)
    {
	char *partChar = NULL;
	[aDecoder decodeValuesOfObjCTypes:"ccccc", &staffPosition, &selver, &isGraced, &voice, &versepos];
//    [aDecoder decodeValuesOfObjCTypes:"@@%", &hangers, &verses, &part];
	[aDecoder decodeValuesOfObjCTypes:"@@%", &hangers, &verses, &partChar];
	[aDecoder decodeValuesOfObjCTypes:"ff", &x, &y];
	if (partChar) part = [[NSString stringWithUTF8String:partChar] retain]; else part = nil;
    }
    else if (v == 7)
    {
	[aDecoder decodeValuesOfObjCTypes:"ccccc", &staffPosition, &selver, &isGraced, &voice, &versepos];
	[aDecoder decodeValuesOfObjCTypes:"@@@", &hangers, &verses, &part];
	[aDecoder decodeValuesOfObjCTypes:"ff", &x, &y];
	[part retain];
    }
    [hangers retain];
    [verses retain];
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeConditionalObject:mystaff];
  [aCoder encodeValuesOfObjCTypes:"ccccc", &staffPosition, &selver, &isGraced, &voice, &versepos];
//  [aCoder encodeValuesOfObjCTypes:"@@%", &hangers, &verses, &part];
  [aCoder encodeValuesOfObjCTypes:"@@@", &hangers, &verses, &part];
  [aCoder encodeValuesOfObjCTypes:"ff", &x, &y];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setObject:mystaff forKey:@"mystaff"];
    [aCoder setInteger:staffPosition forKey:@"p"];
    [aCoder setInteger:selver forKey:@"selver"];
    [aCoder setInteger:isGraced forKey:@"isGraced"];
    [aCoder setInteger:voice forKey:@"voice"];
    [aCoder setInteger:versepos forKey:@"versepos"];

    [aCoder setObject:hangers forKey:@"hangers"];
    [aCoder setObject:verses forKey:@"verses"];
    [aCoder setObject:part forKey:@"part"];

    [aCoder setFloat:x forKey:@"x"];
    [aCoder setFloat:y forKey:@"y"];
}

@end
