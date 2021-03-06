/* $Id$ */
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "System.h"
#import "SysInspector.h"
#import "SysAdjust.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVSelection.h"
#import "SysCommands.h"
#import "OpusDocument.h"
#import "CalliopeAppController.h"
#import "Staff.h"
#import "StaffObj.h"
#import "Bracket.h"
#import "Clef.h"
#import "KeySig.h"
#import "TextGraphic.h"
#import "Margin.h"
#import "Page.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "FileCompatibility.h"


#define LEDGERLIMIT 5	/* how close to a staff and still be mystaff */
#define SIZEBOX 8	/* size of proxy box */

// TODO these should be removed, they create unnecessary binding between classes.
// TODO could retrieve paper size from [CalliopeAppController currentDocument] or from Page.
extern NSSize paperSize;
extern float brackwidth[3];

NSImage *markpage;

@implementation System

static int invalidEnabled = 1;

static float titleRoom(NSMutableArray *o)
{
  int k;
  TextGraphic *p;
  float h, mh;
  mh = 0.0;
  k = [o count];
  while (k--)
  {
    p = [o objectAtIndex:k];
    if ([p graphicType] == TEXTBOX && SUBTYPEOF(p) == TITLE)
    {
      h = [p topMargin];
      if (h > mh) mh = h;
    }
  }
  return mh;
}


static float staffheadRoom(NSMutableArray *o, Staff *sp)
{
  int k = [o count];
  float h, mh;
  TextGraphic *p;
  mh = 0.0;
  while (k--)
  {
    p = [o objectAtIndex:k];
    if ([p graphicType] == TEXTBOX && SUBTYPEOF(p) == STAFFHEAD && ((TextGraphic *)p)->client == sp)
    {
      h = [p topMargin];
      if (h > mh) mh = h;
    }
  }
  return mh;
}


- (BOOL) bottomGroup: (Staff *) sp
{
  Staff *nsp = [self nextstaff: sp];
  if (nsp == nil) return NO;
  if (![self hasBracket: sp] && ![self hasBracket: nsp]) return NO;
  if ([self spanningBracket: sp : nsp]) return NO;
  return YES;
}


+ (void)initialize
{
    if (self == [System class])
    {
	[System setVersion: 112];	/* class version, see read: */ /*sb: increased to 112 from 12 for List conversion */
	markpage = [[NSImage imageNamed:@"markPage"] retain];
    }
}


+ myInspector
{
  return [SysInspector class];
}


- sysInvalid
{
  if (invalidEnabled) height = 0;
  return self;
}

// TODO should be named - (unsigned int) indexWithinScore
- (int) myIndex
{
  return [[view allSystems] indexOfObject: self];
}

- (BOOL) lastSystem
{
    NSArray *allSystems = [view allSystems];
    
    if (![allSystems count]) 
	return NO;
    return [allSystems lastObject] == self; 
// TODO return [[allSystems lastObject] isEqual: self];
}

- (GraphicView *) pageView
{
    return view; // not retained so we don't release it here.
}

- (void) setPageView: (GraphicView *) newPageView
{
    view = newPageView;
}

/*
  Main vertical formatter.  System becomes vertically compressed. 
  Even hidden staves need to be processed, because their bounds are used for adjustment.
  Caller must recalcObjs and recalcBars after sysheight.
*/
- (float) systemHeight: (float) verticalPositionOfSystem
{
    int staveIndex, staveCount;
    float y, maxHeight, h, ss, titleOffset;
    unsigned int numberOfVisibleStaves;
    BOOL b = NO;
    
    staveCount = [self numberOfStaves];
    numberOfVisibleStaves = 0;
    titleOffset = titleRoom(nonStaffGraphics);
    y = verticalPositionOfSystem;
    for (staveIndex = 0; staveIndex < staveCount; staveIndex++) {
	Staff *staff = [staves objectAtIndex: staveIndex];
	
	[staff trimVerses];
	if (staff->flags.hidden) {
	    [[staff measureStaff] resetStaff: y];
	    [staff recalc];
	    continue;
	}
	++numberOfVisibleStaves;
	[staff measureStaff];
	ss = staff->flags.spacing * 2.0;
	maxHeight = staff->topmarg * ss;
	if (!(staff->flags.topfixed)) {
	    if (numberOfVisibleStaves == 1) {
		if (titleOffset > maxHeight) 
		    maxHeight = titleOffset;
		h = [fontdata[FONTTEXT] pointSize] + ss; /* enough for bar numbers etc */
		if (h > maxHeight) 
		    maxHeight = h;
	    }
	    h = staffheadRoom(nonStaffGraphics, staff);
	    if (h > maxHeight) 
		maxHeight = h;
	    h = [staff getHeadroom]; /* only valid because measureStaff sets vhigha */
	    if (h > maxHeight) 
		maxHeight = h;
	}
	y += maxHeight;
	if (numberOfVisibleStaves == 1) 
	    headroom = maxHeight;
	staff->botmarg = 0.0;
	[staff resetStaff: y];
	[staff recalc];
	if (!b)	{
	    b = YES;
	    bounds = NSMakeRect(staff->bounds.origin.x + staff->bounds.size.width + 8, y, SIZEBOX, SIZEBOX);
	}
	y += staff->vhighb;
    }
    height = y - verticalPositionOfSystem;
    NSLog(@"Height of sys %d = %f, start from %f\n", [self myIndex], height, verticalPositionOfSystem);
    return height;
}


/* apply any specified alteration:  expansion, equal distance, or separated groups */

- (float) alterSpacing
{
  int i, ns = [staves count];
  Staff *sp;
  float dy;
  BOOL doExp, doGrp, doEqu;
  if (ns == 1) return height;
  doExp = !TOLFLOATEQ(expansion, 1.0, 0.001);
  doGrp = !TOLFLOATEQ(groupsep, 0.0, 0.001);
  doEqu = flags.equidist;
  if (!doExp && !doGrp && !doEqu) return height;
  if (doEqu || doExp) [self expandSys];
  dy = 0.0;
  [self mark];
  for (i = 0; i < ns; i++)
  {
    sp = [staves objectAtIndex:i];
    if (sp->flags.hidden) continue;
    [sp moveBy:0.0 :dy];
    dy += sp->botmarg;
    if (!doEqu && doGrp && [self bottomGroup: sp]) dy += groupsep * 2.0 * sp->flags.spacing;
  }
  height += dy;
  return height;
}


- recalcObjs
{
  int ns = [nonStaffGraphics count];
  while (ns--) [[nonStaffGraphics objectAtIndex:ns] recalc];
  return self;
}


/*
  After the spacing between staves has been altered, it is necessary to recalc anything that
  may span staves (bars, nonStaffGraphics).  Even hidden staves because of adjust.
*/

- resetSpanners
{
  int ns, nn;
  Staff *sp;
  NSMutableArray *nl;
  StaffObj *p;
  ns = [self numberOfStaves];
  while (ns--)
  {
    sp = [staves objectAtIndex:ns];
    nl = sp->notes;
    nn = [nl count];
    while (nn--)
    {
      p = [nl objectAtIndex:nn];
      if ([p graphicType] == BARLINE) [p recalc];
    }
  }
  [self recalcObjs];
  return self;
}


- resetSys
{
    Staff *topMostStaff = [self firststaff];
    
    if (topMostStaff != nil) {
	invalidEnabled = NO;		/* so that height is not smashed while we reset */
	[self systemHeight: [topMostStaff yOfTop]];	/* find compressed vertical format */
	[self alterSpacing];		/* apply any expansion */
	[self resetSpanners];		/* update what is affected */
	invalidEnabled = YES;		/* height now free to be smashed */
    }
    return self;
}


/* find height of self, validating cache if necessary */

- (float) myHeight
{
  if (height == 0) [self resetSys];
  return height;
}


/* move a system: mark roots from here */


- mark
{
  int k = [staves count];
  gFlags.morphed = 1;
  while (k--) [[staves objectAtIndex:k] mark];
  k = [nonStaffGraphics count];
  while (k--) [[nonStaffGraphics objectAtIndex:k] mark];
  return self;
}


- (void)moveBy:(float)dx :(float)dy
{
  int k;
  lindent += dx;
  rindent -= dx;
  k = [staves count];
  while (k--) [[staves objectAtIndex:k] moveBy:dx :dy];
  k = [nonStaffGraphics count];
  while (k--) [[nonStaffGraphics objectAtIndex:k] moveBy:dx :dy];
  [super moveBy:dx :dy];
}


- moveTo: (float) y
{
  Staff *topMostStaff = [self firststaff];
  if (topMostStaff != nil)
  {
    [self mark];
    [self moveBy:0.0 :(y + headroom) - [topMostStaff yOfTop]];
  }
  return self;
}




/*
  Initialise a system of n staves.
  At this point the staff details are unknown.
*/

- init
{
    NSLog(@"System -init called, initialising with very little info");
    return [self initWithStaveCount: 0 onGraphicView: nil];
}


- initWithStaveCount: (int) n onGraphicView: (GraphicView *) v
{
    self = [super init];
    if(self != nil) {
	[self setTypeOfGraphic: SYSTEM];
	view = v; /* backpointer -- no retain */
	flags.nstaves = n;
	pagenum = barnum = 0;
	flags.newbar = 0;
	flags.newpage = 0;
	flags.pgcontrol = 0;
	flags.equidist = 0;
	flags.disjoint = 0;
	lindent = rindent = 0.0;
	expansion = 1.0;
	groupsep = 0.0;
	height = 0;
	page =  nil; /* backpointer -- no retain */
	style = nullPart;
	nonStaffGraphics = [[NSMutableArray alloc] init];
	staves = [[NSMutableArray arrayWithCapacity: n] retain];
	while (n--) {
	    Staff *aStaff = [[Staff alloc] init];
	    
	    [aStaff setSystem: self];
	    [staves addObject: aStaff];
	    [aStaff release];   /*sb: the array will hold the single retain */
	}
    }
    return self;
}


/*
  Initialise system details and link in now that staff details are known.
  This should be factored into - initWithSystem: (System *) oldSystem; and staff setting methods.
*/

- initsys
{
    // newSystem = [self initWithStaveCount: [self numberOfStaves] onGraphicView: view];
    System *cursys = [view currentSystem];
    
    if (cursys == nil) {
	Margin *margin = [[Margin alloc] init];
	
	[margin setClient: self];
	[self linkobject: margin];
	[margin release];
	page = nil;
    }
    else {
	Margin *currentMargin = [[cursys margin] copy];
	
	[currentMargin setClient: self];
	[self linkobject: currentMargin];
	page = [cursys page];	
    }
    [self recalc];
    return self;
}


/*
  Make and return a new system using self as a template.
  TODO should become copyWithZone:?
*/
- (System *) newFormattedSystem
{
    int staffIndex;
    int systemObjectsCount;
    System *newSystem;
    
    newSystem = [[System alloc] initWithStaveCount: [self numberOfStaves] onGraphicView: view];
    [newSystem setPage: page];
    newSystem->lindent = 0.0;
    newSystem->rindent = 0.0;
    newSystem->expansion = 1.0;
    newSystem->groupsep = groupsep;
    newSystem->barbase = 0.0;
    newSystem->height = height;
    newSystem->headroom = headroom;
    newSystem->style = style;
    for (staffIndex = 0; staffIndex < [self numberOfStaves]; staffIndex++) {
	Clef *lastClef;
	KeySig *lastKeySignature;
	Staff *sp = [newSystem getStaff:  staffIndex];
	Staff *op = [staves objectAtIndex: staffIndex];
	
	sp->flags = op->flags;
	sp->flags.haspref = 0;
	sp->gFlags.size = op->gFlags.size;
	[sp setPartName: [op partName]];
	sp->pref1 = sp->pref2 = 0.0;
	sp->voffa = op->voffa;
	sp->voffb = op->voffb;
	sp->vhigha = op->vhigha;
	sp->vhighb = op->vhighb;
	sp->topmarg = op->topmarg;
	sp->botmarg = op->botmarg;
	lastClef = [view lastObject: self : staffIndex : CLEF : YES];
	if (lastClef != nil) 
	    [sp linknote: [lastClef newFrom]];
	lastKeySignature = [view lastObject: self : staffIndex : KEY : NO];
	if (lastKeySignature != nil) 
	    [sp linknote: [lastKeySignature newFrom]];
    }
    systemObjectsCount = [nonStaffGraphics count];
    while (systemObjectsCount--) {
	id p = [nonStaffGraphics objectAtIndex: systemObjectsCount];
	
	if ([p graphicType] == BRACKET) 
	    [newSystem linkobject: [(Bracket *) p newFrom: newSystem]];
    }
    [newSystem initsys];
    [newSystem sigAdjust];
    return [newSystem autorelease];
}


- newExtraction: (GraphicView *) v : (int) sn
{
    System *sys = [[System alloc] init];
    [sys setTypeOfGraphic: SYSTEM];
    sys->flags = flags;
    sys->flags.nstaves = sn;
    [sys setPageView: v];
    [sys setPage: nil];
    sys->lindent = lindent;
    sys->rindent = rindent;
    sys->expansion = expansion;
    sys->groupsep = groupsep;
    sys->barbase = barbase;
    sys->height = height;
    sys->headroom = headroom;
    sys->style = style;
    sys->nonStaffGraphics = [[NSMutableArray alloc] init];
    sys->staves = [[NSMutableArray alloc] init];
    return sys;
}


- copyStyleTo: (System *) sys
{
  int i;
  Staff *sp, *op;
  sys->flags = flags;
  sys->gFlags.subtype = gFlags.subtype;
  sys->gFlags.size = gFlags.size;
  sys->lindent = lindent;
  sys->rindent = rindent;
  sys->expansion = expansion;
  sys->groupsep = groupsep;
  sys->barbase = barbase;
  sys->height = height;
  sys->width = width;
  sys->headroom = headroom;
  sys->style = style;
  for (i = 0; i < [self numberOfStaves]; i++)
  {
    sp = [sys getStaff: i];
    op = [staves objectAtIndex:i];
    sp->flags = op->flags;
    sp->gFlags.subtype = op->gFlags.subtype;
    sp->gFlags.size = op->gFlags.size;
    [sp setPartName: [op partName]];
    sp->voffa = op->voffa;
    sp->voffb = op->voffb;
    sp->vhigha = op->vhigha;
    sp->vhighb = op->vhighb;
    sp->topmarg = op->topmarg;
    sp->botmarg = op->botmarg;
    sp->pref1 = op->pref1;
    sp->pref2 = op->pref2;
    [sp defaultNoteParts];
  }
  return self;
}


- makeNames: (BOOL) full : (GraphicView *) v
{
    int k = [staves count];
    
    while (k--) {
	Staff *sp = [staves objectAtIndex: k];
	
	if (![[sp partName] isEqualToString: nullPart])	{
	    TextGraphic *t = [sp makeName: full];
	    
	    [nonStaffGraphics addObject: t];
	    [t recalc];
	    [v selectObj: t];
	}
    }
    return self;
}


/* remove things not wanted on copied system */

- closeSystem
{
  Graphic *p;
  int k = [nonStaffGraphics count];
  while (k--)
  {
    p = [nonStaffGraphics objectAtIndex:k];
    if ([p graphicType] == MARGIN) [nonStaffGraphics removeObjectAtIndex:k];
  }
  return self;
}

- (float) staffScale
{
    return [[self pageView] staffScale];
}

/*  return if self has a margin object */

- margin
{
    Margin *p;
    int k = [nonStaffGraphics count];
    
    while (k--) {
	p = [nonStaffGraphics objectAtIndex: k];
	if ([p graphicType] == MARGIN) 
	    return p;
    }
    return nil;
}


/* find margins depending on what is there */

- (float) leftMargin
{
    Margin *m;
    
    if (page) 
	return [page leftMargin];
    m = [self margin];
    if (m) 
	return [m leftMargin];
    return 36.0 / [self staffScale];
}


- (float) rightMargin
{
  Margin *m;
  if (page) return [page rightMargin];
  m = [self margin];
  if (m) return [m rightMargin];
  return 36.0 / [self staffScale];
}


- (float) headerBase
{
  Margin *m;
  if (page) return [page headerBase];
  m = [self margin];
  if (m) return [m headerBase];
  return 18.0 / [self staffScale];
}


- (float) footerBase
{
  Margin *m;
  if (page) return [page footerBase];
  m = [self margin];
  if (m) return [m footerBase];
  return 18.0 / [self staffScale];
}


- (float) leftIndent
{
  if (lindent == 0.0) return 0.0;  /* common shortcut */
  return lindent / [self staffScale];
}


- (float) leftWhitespace
{
  if (lindent == 0.0) return [self leftMargin];  /* common shortcut */
  return [self leftMargin] + [self leftIndent];
}


- (float) rightIndent
{
  if (rindent == 0.0) return 0.0;  /* common shortcut */
  return rindent / [self staffScale];
}


/* 
  recalc width before calling sysheight, because sysheight does
  recalc for each staff, and each staff needs to know width.
  Because Barlines and Brackets need to know staff heights, they are done next.
*/

- recalc
{
    //   TODO [[CalliopeAppController currentDocument] paperSize];
    width = ((paperSize.width - lindent - rindent) / [self staffScale]) - ([self leftMargin] + [self rightMargin]);
    return [self resetSys];
}

- measureSys: (NSRect *) r
{
  int k;
  float y, miny, maxy;
  Staff *sp;
  miny = MAXFLOAT;
  maxy = MINFLOAT;
  k = [staves count];
  r->origin.x = [self leftWhitespace];
  r->size.width = width;
  while (k--)
  {
    sp = [staves objectAtIndex:k];
    if (sp->flags.hidden) continue;
    y = [sp yOfTop];
    if (y < miny) miny = y;
    y += sp->bounds.size.height;
    if (y > maxy) maxy = y;
  }
  r->origin.y = miny;
  r->size.height = maxy - miny;
  return self;
}


- (BOOL) hasTitles
{
  int k;
  TextGraphic *p;
  k = [nonStaffGraphics count];
  while (k--)
  {
    p = [nonStaffGraphics objectAtIndex:k];
    if ([p graphicType] == TEXTBOX && SUBTYPEOF(p) == TITLE) return YES;
  }
  return NO;
}

- setHangers
{
  int k = [staves count];
  while (k--) [[staves objectAtIndex:k] setHangers];
  return self;
}


- recalcHangers
{
  int k = [staves count];
  while (k--) [[staves objectAtIndex:k] recalcHangers];
  return self;
}


/* this is done by resizing by 0 clicks */

- reShape
{
  int k = [staves count];
  while (k--) [[staves objectAtIndex:k] resizeNotes: 0];
  return self;
}


/*
  Routines for handling the system linkage bar and brackets 
*/


/* Several callers need to try to make a new link into self. */

- installLink
{
  Bracket *p;
  if (![self hasLinkage])
  {
    p = [[Bracket alloc] init];
    p->client1 = self;
    [p recalc];
    [self linkobject: p];
  }
  return self;
}


- (BOOL) hasLinkage
{
  int i = [nonStaffGraphics count];
  Bracket *p;
  while (i--)
  {
    p = [nonStaffGraphics objectAtIndex:i];
    if (p->gFlags.type == BRACKET && p->gFlags.subtype == LINKAGE) return YES;
  }
  return NO;
}


- (BOOL) hasBracket: (Staff *) sp
{
  int i = [nonStaffGraphics count];
  Bracket *p;
  while (i--)
  {
    p = [nonStaffGraphics objectAtIndex:i];
    if (p->gFlags.type == BRACKET && p->gFlags.subtype != LINKAGE && (sp == p->client1 || sp == p->client2)) return YES;
  }
  return NO;
}


- (BOOL) spanningBracket: (Staff *) sp1 : (Staff *) sp2
{
  int k, i1, i2, i3, i4, t;
  Bracket *p;
  k = [nonStaffGraphics count];
  i1 = [staves indexOfObject:sp1];
  i2 = [staves indexOfObject:sp2];
  while (k--)
  {
    p = [nonStaffGraphics objectAtIndex:k];
    if ([p graphicType] == BRACKET && SUBTYPEOF(p) != LINKAGE)
    {
      i3 = [staves indexOfObject:p->client1];
      i4 = [staves indexOfObject:p->client2];
      if (i4 < i3)
      {
        t = i3;
	i3 = i4;
	i4 = t;
      }
      if (i3 <= i1 && i1 <= i4 && i3 <= i2 && i2 <= i4) return YES;
    }
  }
  return NO;
}


/* for titles, etc, to account for width of brackets and prefatory staff */

- (float) leftPlace
{
  Staff *sp;
  float x, lm, li, mx = MAXFLOAT;
  int k = [staves count];
  li = [self leftIndent];
  lm = [self leftMargin];
  while (k--)
  {
    sp = [staves objectAtIndex:k];
    if (!(sp->flags.hidden))
    {
      x = lm + li - [sp brackLevel] * (brackwidth[sp->gFlags.size] + nature[0]);
      if (x < mx) mx = x;
      if (sp->flags.haspref)
      {
        x = lm + sp->pref1 * 0.01 * li;
	if (x < mx) mx = x;
      }
    }
  }
  return (mx == MAXFLOAT ? 0.0 : mx);
}


- (float) getBracketX: (Bracket *) b : (int) sz
{
  int bl = b->level;
  float x = [self leftWhitespace];
  x -= (bl * (brackwidth[sz] + (2 * nature[0])));
  x += nature[0];
  return x;
}


/* put something on the nonStaffGraphics list */

- linkobject: p
{
  [nonStaffGraphics addObject: p];
  return p;
}


- unlinkobject: p
{
    int theLocation = [nonStaffGraphics indexOfObject:[[p retain] autorelease]];
    if (theLocation != NSNotFound) [nonStaffGraphics removeObjectAtIndex: theLocation];
  return p;
}


/*
  Utility Routines 
*/

- (int) numberOfStaves
{
    return flags.nstaves; // TODO should replace this with [staves count];
}

- newStaff: (float) ny
{
    Staff *sp = [self findOnlyStaff: ny];
    Staff *nsp = [[Staff alloc] init];
    int i = [staves indexOfObject: sp];
    int n = [self numberOfStaves] + 1;
    
    [nsp setSystem: self];
    if (ny > [sp yOfTop])
	++i;
    [staves insertObject: nsp atIndex: i];
    flags.nstaves = n;
    [self sysInvalid];
    return self;
}

- (NSArray *) staves
{
    return [[staves retain] autorelease];
}

- (Staff *) getStaff: (int) n
{
  return [staves objectAtIndex: n];
}


- getVisStaff: (int) n
{
  Staff *s = [staves objectAtIndex:n];
  if (s == nil) return nil;
  if (s->flags.hidden) return nil; else return s;
}


- (unsigned int) indexOfStaff: (Staff *) s
{
    return [staves indexOfObject: s];
}

- (void) deleteHiddenStaves
{
    int i, j;
    
    i = [self numberOfStaves];
    while (i--) {
	Staff *sp = [self getStaff: i];
	
	if (sp->flags.hidden) {
	    [staves removeObjectAtIndex: i];
	    --flags.nstaves;
	    j = [nonStaffGraphics count];
	    while (j--) {
		id p = [nonStaffGraphics objectAtIndex: j];
		
		if ([p graphicType] == TEXTBOX && SUBTYPEOF(p) == STAFFHEAD) 
		    [p removeObj];
		else if ([p graphicType] == BRACKET && SUBTYPEOF(p) != LINKAGE) {
		    if (sp == ((Bracket *)p)->client1 || sp == ((Bracket *)p)->client2)
			[p removeObj];
		}
	    }
	}
    }
}

- (void) addStaff: (Staff *) newStaff
{
    [staves addObject: newStaff];
    flags.nstaves++; // This should be eventually removed and just use -numberOfStaves
}

- (void) orderStavesBy: (char *) order
{
    int j;
    int sn = [self numberOfStaves];
    NSMutableArray *nsl = [[NSMutableArray alloc] init];
    
    for (j = 0; j < sn; j++) 
	[nsl addObject: [self getStaff: order[j]]];
    [staves release];
    staves = nsl;
}


/*
  Return whether staff is near the top or bottom of system.
  Used for deciding the direction of stems for notes on the middle line.
*/

- (int) whereIs: (Staff *) sp
{
 return ([staves indexOfObject:sp] - ([self numberOfStaves] >> 1));
}
 

/*
  return the staff of this system which is at the same place
  as the arg staff is in its system
*/
 
- sameStaff: (Staff *) sp
{
  return [staves objectAtIndex:[sp myIndex]];
}


/*
  relink a StaffObj either to another staff in self,
  or to same staff, depending on x,y,mystaff.  reset mystaff.
  return whether p->p is now invalid (i.e. whether moved to new staff).
  Old format notes may have mystaff set to a system.
*/

- (BOOL) relinknote : (StaffObj *) p
{
  int inv = NO;
  Staff *sp, *ms = [p staff];
  
  if (p->gFlags.locked)
  {
    [ms staffRelink: p];
    return NO;
  }
  sp = [self findOnlyStaff: [p y]];
  inv = (sp != ms);
  if ([ms graphicType] == SYSTEM)
  {
    [sp staffRelink: [(System *) ms unlinkobject: p]];
  }
  else
  {
    if (inv) [sp linknote: [ms unlinknote: p]];
    else [sp staffRelink: p];
  }
  return inv;
}


/* scan for next visible staff after and including index j */

- scanvis: (int) j
{
  int i, k;
  Staff *s;
  k = [self numberOfStaves];
  for (i = j; i < k; i++)
  {
    s = [staves objectAtIndex:i];
    if (!(s->flags.hidden)) return(s);
  }
  return nil;
}


/* return first visible staff */

- firststaff
{
  return [self scanvis: 0];
}


/* return last visible staff */

- lastStaff
{
  int k;
  Staff *s;
  k = [self numberOfStaves];
  while (k--)
  {
    s = [staves objectAtIndex:k];
    if (!(s->flags.hidden)) return(s);
  }
  return nil;
}

  
/* return next visible staff after self */

- nextstaff: s
{
  return [self scanvis: ([staves indexOfObject:s] + 1)];
}


/* return the nearest staff to y however far away it is */

- (Staff *) findOnlyStaff: (float) y
{
  int k;
  Staff *s, *ms;
  float dy, mindy;
  mindy = MAXFLOAT;
  ms = nil;
  k = [self numberOfStaves];
  while (k--)
  {
    s = [staves objectAtIndex:k];
    if (s->flags.hidden) continue;
    dy = ([s yOfTop] + s->flags.spacing * (s->flags.nlines - 1)) - y;
    if (dy < 0) dy = -dy;
    if (dy < mindy)
    {
      mindy = dy;
      ms = s;
    }
  }
  return ms;
}


/* look in the system for a hit on any object (and obj's enclosures) */
// TODO we should be returning an autoreleased NSArray rather than modifying one passed in.
- (void) searchFor: (NSPoint) p inObjects: (NSMutableArray *) arr
{
    int numOfStaves = [self numberOfStaves];
    int numOfObjects;
    
    if (NSPointInRect(p, bounds)) {
	if (![arr containsObject: self])
	    [arr addObject: self];
	return;
    }
    while (numOfStaves--) {
	// staves seems to already be released, causing an EXC_BAD_ACCESS.
	Staff *s = [staves objectAtIndex: numOfStaves];
	
	if (s->flags.hidden) continue;
	[s searchFor: p inObjects: arr];
    }
    numOfObjects = [nonStaffGraphics count];
    while (numOfObjects--) {
	// Graphic *q?
	id q = [nonStaffGraphics objectAtIndex: numOfObjects];
	
	if ([q hit: p])
	    if (![arr containsObject: q])
		[arr addObject: q];
	
	[q searchFor: p inObjects: arr];  /* does enclosures */
    }
}

/* free nonStaffGraphics first because some might point to staff objects */
- (void) dealloc
{
    NSLog(@"deallocating System %p\n", self);
    [style release];
    style = nil;
    [nonStaffGraphics release];
    nonStaffGraphics = nil;
    [staves release];
    staves = nil;
    [super dealloc];
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ Page=%p staves=%@ nonStaffGraphics=%@", 
	[super description], page, staves, nonStaffGraphics];
}

/* return which marker a given obj is */

- (int) whichMarker: (Graphic *) p
{
  Graphic *q;
  int j = 0, k = [nonStaffGraphics count];
  while (k--)
  {
    q = [nonStaffGraphics objectAtIndex:k];
    if ([q graphicType] == RUNNER || [q graphicType] == MARGIN)
    {
      if (q == p) return j;
      ++j;
    }
  }
  return -1;
}


/*
  Drawing routines
*/


/* draw any subobjects (in this case, staves, nonStaffGraphics, marker, bar numbers) */

- draw: (NSRect) r nonSelectedOnly: (BOOL) nso
{
    int staveIndex;
    int objectsCount;
    
    for (staveIndex = 0; staveIndex < [self numberOfStaves]; staveIndex++) 
	[[staves objectAtIndex: staveIndex] draw: r nonSelectedOnly: nso];
    objectsCount = [nonStaffGraphics count];
    while (objectsCount--) 
	[[nonStaffGraphics objectAtIndex: objectsCount] draw: r nonSelectedOnly: nso];
    // draw a box for access in different colours based on it's selection.
    crect(bounds.origin.x, bounds.origin.y, 8, 8, markmode[gFlags.selected]);
    if (flags.pgcontrol) 
	crect(bounds.origin.x + 24, bounds.origin.y, 8, 12, markmode[0]);
    if (flags.syssep && page != nil && ![self lastSystem]) 
	[page drawSysSep: r : self : view];
    return self;
}


- drawHangers: (NSRect) r nonSelectedOnly: (BOOL) nso
{
    int i;
    
    for (i = 0; i < [self numberOfStaves]; i++)
	[[staves objectAtIndex:i] drawHangers: r nonSelectedOnly: nso];
    i = [nonStaffGraphics count];
    while (i--)
	[[nonStaffGraphics objectAtIndex:i] drawHangers: r nonSelectedOnly: nso];
    return self;
}


/* draw system-specific */
- draw
{
  return self;
}

- (float) headroom
{
    return headroom;
}

- (int) pageNumber
{
    // TODO should become return [page pageNumber];
    return pagenum;
}

- (void) setPageNumber: (int) newPageNumber
{
    // Should become [page setPageNumber: newPageNumber];
    pagenum = newPageNumber;
}

- (void) setPage: newPage
{
    [page release];
    page = [newPage retain];
}

- (Page *) page
{
    return [[page retain] autorelease];
}

/*
  Archiving Methods
  Remember super reads in syslist, so no need to link systems in.
*/

struct oldflags /* for old version */
{
  unsigned int nstaves : 6;	/* number of staves */
  unsigned int rastral : 3;	/* rastral number (origin 0) */
  unsigned int pgcontrol : 3;	/* page break code */
  unsigned int haslink : 1;	/* staff linkage bar */
};

static int hasold = 0;
static float lmarg, rmarg, sheight;  /* for conversion of old types */
static float shmm[8] =		/* staff height in mm, given rastral number  */
{
  8.0, 7.5, 7.0, 6.5, 6.0, 5.5, 5.0, 4.0
};

+ (int) oldSizeCount { return hasold; }

+ getOldSizes: (float *) lm : (float *) rm : (float *) sh
{
  *lm = lmarg;
  *rm = rmarg;
  *sh = sheight;
  return self;
}

/* change to new format for number sequence changes */

- updateNumbering
{
  if (barnum < 0)
  {
    barnum = -barnum;
    flags.newbar = 1;
  }
  if (pagenum < 0)
  {
    pagenum = -pagenum;
    flags.newpage = 1;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v;
  char b1, b2, b3, b4, b5=0, b6=0, b7=0, b8=0;
  struct oldflags f;
  char *oldstyle = NULL;
  
  [super initWithCoder:aDecoder];
  v = [aDecoder versionForClassName:@"System"];
  if (v == 112)
  {
      [aDecoder decodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
    flags.nstaves = b1;
    flags.syssep = b2;
    flags.pgcontrol = b3;
    flags.haslink = b4;
    flags.equidist = b5;
    flags.disjoint = b6;
    flags.newbar = b7;
    flags.newpage = b8;
    [aDecoder decodeValuesOfObjCTypes:"ssfffffffff", &pagenum, &barnum, &barbase, &width, &lindent, &rindent, &groupsep, &expansion, &height, &headroom, &oldleft];
    [aDecoder decodeValuesOfObjCTypes:"@@@", &staves, &nonStaffGraphics, &style];
    view = [[aDecoder decodeObject] retain];
    page = [[aDecoder decodeObject] retain];
    [[page margin] setClient: self];
    return self;
  }
  if (v == 12)
  {
      [aDecoder decodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
    flags.nstaves = b1;
    flags.syssep = b2;
    flags.pgcontrol = b3;
    flags.haslink = b4;
    flags.equidist = b5;
    flags.disjoint = b6;
    flags.newbar = b7;
    flags.newpage = b8;
    [aDecoder decodeValuesOfObjCTypes:"ssfffffffff", &pagenum, &barnum, &barbase, &width, &lindent, &rindent, &groupsep, &expansion, &height, &headroom, &oldleft];
    // TODO staves, nonStaffGraphics decoded without full initialisation, causing later crash?
    [aDecoder decodeValuesOfObjCTypes:"@@%", &staves, &nonStaffGraphics, &oldstyle];
    if (oldstyle) style = [[NSString stringWithUTF8String:oldstyle] retain]; else style = nil;
    view = [[aDecoder decodeObject] retain];
    page = [[aDecoder decodeObject] retain];
      [[page margin] setClient: self];
    return self;
  }
  if (v == 11)
  {
      [aDecoder decodeValuesOfObjCTypes:"cccccc", &b1, &b2, &b3, &b4, &b5, &b6];
    flags.nstaves = b1;
    flags.syssep = b2;
    flags.pgcontrol = b3;
    flags.haslink = b4;
    flags.equidist = b5;
    flags.disjoint = b6;
    flags.newbar = b7;
    flags.newpage = b8;
    [aDecoder decodeValuesOfObjCTypes:"ssfffffffff", &pagenum, &barnum, &barbase, &width, &lindent, &rindent, &groupsep, &expansion, &height, &headroom, &oldleft];
    [self updateNumbering];
    [aDecoder decodeValuesOfObjCTypes:"@@%", &staves, &nonStaffGraphics, &oldstyle];
    [staves retain];
    [nonStaffGraphics retain];
    if (oldstyle) 
	style = [[NSString stringWithUTF8String: oldstyle] retain]; 
      else
	  style = nil;
    view = [[aDecoder decodeObject] retain];
    page = [[aDecoder decodeObject] retain];
    [[page margin] setClient: self];
    return self;
  }
  if (v == 10)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b1, &b2, &b3, &b4, &b5, &b6];
    flags.nstaves = b1;
    flags.pgcontrol = b3;
    flags.haslink = b4;
    flags.equidist = b5;
    flags.disjoint = b6;
    [aDecoder decodeValuesOfObjCTypes:"ssffffffff", &pagenum, &barnum, &barbase, &width, &lindent, &rindent, &groupsep, &expansion, &height, &headroom];
    [self updateNumbering];
    [aDecoder decodeValuesOfObjCTypes:"@@%", &staves, &nonStaffGraphics, &oldstyle];
    if (oldstyle) style = [[NSString stringWithUTF8String:oldstyle] retain]; else style = nil;
    view = [[aDecoder decodeObject] retain];
    page = [[aDecoder decodeObject] retain];
      [[page margin] setClient: self];

    return self;
  }
  style = nullPart;
  if (v == 9)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b1, &b2, &b3, &b4, &b5, &b6];
    flags.nstaves = b1;
    flags.pgcontrol = b3;
    flags.haslink = b4;
    flags.equidist = b5;
    flags.disjoint = b6;
    [aDecoder decodeValuesOfObjCTypes:"ssffffffff", &pagenum, &barnum, &barbase, &width, &lindent, &rindent, &groupsep, &expansion, &height, &headroom];
    [self updateNumbering];
    [aDecoder decodeValuesOfObjCTypes:"@@", &staves, &nonStaffGraphics];
    view = [[aDecoder decodeObject] retain];
    page = [[aDecoder decodeObject] retain];
      [[page margin] setClient: self];
    return self;
  }
  else if (v == 8)
  {
    [aDecoder decodeValuesOfObjCTypes:"cccccc", &b1, &b2, &b3, &b4, &b5, &b6];
      flags.nstaves = b1; if (b3 == 4) b3 = 0;
    flags.pgcontrol = b3;
    flags.haslink = b4;
    flags.equidist = b5;
    flags.disjoint = b6;
    [aDecoder decodeValuesOfObjCTypes:"ssffffffff", &pagenum, &barnum, &barbase, &width, &lindent, &rindent, &groupsep, &expansion, &height, &headroom];
    [self updateNumbering];
    [aDecoder decodeValuesOfObjCTypes:"@@", &staves, &nonStaffGraphics];
    view = [[aDecoder decodeObject] retain];
    return self;
  }
  if (v == 7)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccc", &b1, &b2, &b3, &b4, &b5];
    flags.nstaves = b1;
    flags.pgcontrol = b3;
    flags.haslink = b4;
    flags.equidist = b5;
    [aDecoder decodeValuesOfObjCTypes:"ssffffffff", &pagenum, &barnum, &barbase, &width, &lindent, &rindent, &groupsep, &expansion, &height, &headroom];
    [self updateNumbering];
    [aDecoder decodeValuesOfObjCTypes:"@@", &staves, &nonStaffGraphics];
    view = [[aDecoder decodeObject] retain];
    return self;
  }
  if (v == 6)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccc", &b1, &b2, &b3, &b4, &b5];
    flags.nstaves = b1;
    flags.pgcontrol = b3;
    flags.haslink = b4;
    flags.equidist = b5;
    [aDecoder decodeValuesOfObjCTypes:"ssffffff", &pagenum, &barnum, &barbase, &width, &lindent, &rindent, &groupsep, &expansion];
    [self updateNumbering];
    [aDecoder decodeValuesOfObjCTypes:"@@", &staves, &nonStaffGraphics];
    view = [[aDecoder decodeObject] retain];
    return self;
  }
  else if (v >= 4)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccccc", &b1, &b2, &b3, &b4, &b5];
    flags.nstaves = b1;
    flags.pgcontrol = b3;
    flags.haslink = b4;
    flags.equidist = b5;
    [aDecoder decodeValuesOfObjCTypes:"ssfffff", &pagenum, &barnum, &width, &lindent, &rindent, &groupsep, &expansion];
    [self updateNumbering];
    [aDecoder decodeValuesOfObjCTypes:"@@", &staves, &nonStaffGraphics];
    view = [[aDecoder decodeObject] retain];
    return self;
  }
  hasold++;
  if (v == 0)
  {
      [aDecoder decodeValuesOfObjCTypes:"sssffff", &f, &pagenum, &barnum, &lindent, &width, &lmarg, &rmarg];
      [self updateNumbering];
    flags.nstaves = f.nstaves;
    flags.pgcontrol = f.pgcontrol;
    flags.haslink = f.haslink;
    sheight = shmm[f.rastral] * 2.834646;
  }
  else
  {
    [aDecoder decodeValuesOfObjCTypes:"cccc", &b1, &b2, &b3, &b4];
    flags.nstaves = b1;
    sheight = shmm[(int)b2] * 2.834646;
    flags.pgcontrol = b3;
    flags.haslink = b4;
    [aDecoder decodeValuesOfObjCTypes:"ssffff", &pagenum, &barnum, &lindent, &width, &lmarg, &rmarg];
    [self updateNumbering];
  }
  expansion = 1.0;
  if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"fc", &expansion, &b5];
    flags.equidist = b5;
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"ffc", &groupsep, &expansion, &b5];
    flags.equidist = b5;
  }
  [aDecoder decodeValuesOfObjCTypes:"@@", &staves, &nonStaffGraphics];
  view = [[aDecoder decodeObject] retain];
  lindent *= (sheight / 32.0);
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b1,b2, b3, b4, b5, b6, b7, b8;
  [super encodeWithCoder:aCoder];
  b1 = [self numberOfStaves];
  b2 = flags.syssep;
  b3 = flags.pgcontrol;
  b4 = flags.haslink;
  b5 = flags.equidist;
  b6 = flags.disjoint;
  b7 = flags.newbar;
  b8 = flags.newpage;
  [aCoder encodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
  [aCoder encodeValuesOfObjCTypes:"ssfffffffff", &pagenum, &barnum, &barbase, &width, &lindent, &rindent, &groupsep, &expansion, &height, &headroom, &oldleft];
  [aCoder encodeValuesOfObjCTypes:"@@@", &staves, &nonStaffGraphics, &style];
  [aCoder encodeConditionalObject:view];
  [aCoder encodeConditionalObject:page];
}
- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
//    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];

    [aCoder setInteger:[self numberOfStaves] forKey:@"nstaves"];
    [aCoder setInteger:flags.syssep forKey:@"syssep"];
    [aCoder setInteger:flags.pgcontrol forKey:@"pgcontrol"];
    [aCoder setInteger:flags.haslink forKey:@"haslink"];
    [aCoder setInteger:flags.equidist forKey:@"equidist"];
    [aCoder setInteger:flags.disjoint forKey:@"disjoint"];
    [aCoder setInteger:flags.newbar forKey:@"newbar"];
    [aCoder setInteger:flags.newpage forKey:@"newpage"];

    [aCoder setInteger:pagenum forKey:@"pagenum"];
    [aCoder setInteger:barnum forKey:@"barnum"];
    [aCoder setFloat:barbase forKey:@"barbase"];
    [aCoder setFloat:width forKey:@"width"];
    [aCoder setFloat:lindent forKey:@"lindent"];
    [aCoder setFloat:rindent forKey:@"rindent"];
    [aCoder setFloat:groupsep forKey:@"groupsep"];
    [aCoder setFloat:expansion forKey:@"expansion"];
    [aCoder setFloat:height forKey:@"height"];
    [aCoder setFloat:headroom forKey:@"headroom"];
    [aCoder setFloat:oldleft forKey:@"oldleft"];
    
    [aCoder setObject:staves forKey:@"staves"];
    [aCoder setObject:nonStaffGraphics forKey:@"objs"];
    [aCoder setString:style forKey:@"style"];
    [aCoder setObject:view forKey:@"view"]; /* should be conditional? */
    [aCoder setObject:view forKey:@"page"]; /* should be conditional? */
}

@end
