/* $Id$ */
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "NoteGroup.h"
#import "NoteGroupInspector.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "GNote.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "System.h"
#import "Staff.h"
#import "Tie.h"
#import "Volta.h"
#import "FileCompatibility.h"

/* note groups can have >= 1 staff objects in the group */

@implementation NoteGroup

static NoteGroup *proto;


+ (void)initialize
{
  if (self == [NoteGroup class])
  {
      (void)[NoteGroup setVersion: 4];		/* class version, see read: */
    proto = [[NoteGroup alloc] init];
  }
  return;
}


+ myPrototype
{
  return proto;
}


+ myInspector
{
  return [NoteGroupInspector class];
}


- init
{
  int i;
  [super init];
  [self setTypeOfGraphic: GROUP];
  client = nil;
  flags.fixed = 0;
  flags.position = 0;
  flags.bit0 = 0;
  for (i = 0; i < 4; i++)  mark[i] = '\0';
  return self;
}


- (void)dealloc
{
  [client release];
  { [super dealloc]; return; };
}


- sysInvalid
{
  return [super sysInvalidList];
}

- copyWithZone: (NSZone *) zone
{
    NoteGroup *t = [super copyWithZone: zone];
    int i = 3; // TODO must ensure this matches the length of mark[].
    
    t->x1 = x1;
    t->y1 = y1;
    t->x2 = x2;
    t->y2 = y2;
    t->flags = flags;
    while (i--) 
	t->mark[i] = mark[i];
    return t;
}


- (BOOL) needSplit: (float) s0 : (float) s1
{
  return [super needSplitList: s0 : s1];
}



/* set caches according to flags sn to sort, off to set default offsets */

extern void graphicListBBoxExVolta(NSRect *b, NSMutableArray *l);
extern void graphicListBBoxEx(NSRect *b, NSMutableArray *l, Graphic *p);

- setGroup: (int) sn : (int) off
{
  float d, sy;
  StaffObj *p, *q;
  Staff *sp;
  NSRect b;
  if (sn) [super sortNotes: client];
  if (!off) return self;
  d = 2 * nature[gFlags.size];
  p = [client objectAtIndex:0];
  q = [client lastObject];
  if (gFlags.subtype == GROUPVOLTA)
  {
    graphicListBBoxExVolta(&b, client);
    sp = [p staff];
    d = 0 /* 0.5 * barwidth[sp->flags.subtype][sp->gFlags.size] */;
    x1 = p->bounds.origin.x + p->bounds.size.width - d;
    x1 -= p->bounds.origin.x;
    x2 = (![q hasVoltaBesides: self]) ? q->bounds.origin.x + q->bounds.size.width - d : [q x];
    x2 -= q->bounds.origin.x;
    sy = [p yOfStaffPosition: -6];
    if (b.origin.y < sy) sy = b.origin.y;
    y1 = sy - 2 * nature[gFlags.size] - p->bounds.origin.y;
    y2 = b.origin.y + b.size.height - q->bounds.origin.y;
  }
  else
  {
    graphicListBBoxEx(&b, client, self);
    x1 = b.origin.x - d - p->bounds.origin.x;
    y1 = b.origin.y - d - p->bounds.origin.y;
    x2 = b.origin.x + b.size.width + d - q->bounds.origin.x;
    y2 = b.origin.y + b.size.height + d - q->bounds.origin.y;
  }
  return self;
}



- setHanger
{
  [self setGroup: 1 : !flags.fixed];
  return [self recalc];
}

- setHanger: (BOOL) f1  : (BOOL) f2
{
  [self setGroup: f1 : f2];
  return [self recalc];
}


char defpos[NUMNOTEGROUPS] = {0, 0, 0, 0, 2, 4, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0};

- linkGroup: (NSMutableArray *) l
{
  int k, lk, bk = 0;
  StaffObj *q;
  lk = [l count];
  k = lk;
  while (k--)
  {
    q = [l objectAtIndex:k];
    if (ISASTAFFOBJ(q)) ++bk;
  }
  if (bk < 1) return nil;
  client = [[NSMutableArray alloc] init];
  k = lk;
  while (k--)
  {
    q = [l objectAtIndex:k];
    if (ISASTAFFOBJ(q)) [(NSMutableArray *)client addObject: q];
  }
  [self setLevel: [self maxLevel] + 1];
  k = bk;
  while (k--) [[client objectAtIndex:k] linkhanger: self];
  return self;
}

- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i
{
  if ([self linkGroup: [v selectedGraphics]] == nil) return nil;
  gFlags.subtype = i;
  if (i == GROUPVOLTA)
  {
    mark[0] = '1';
    mark[1] = '.';
    mark[2] = '\0';
  }
  flags.position = defpos[i];
  [self setGroup: 1 : 1];
  return self;
}


- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl
{
  if ([self linkGroup: sl] == nil) return NO;
  [self setHanger: 1 : 1];
  [v selectObj: self];
  return YES;
}  

/* special case for upgrading old format.  might be nil, to indicate split. */
//*sb: moved this to top of file: #import "Tie.h" */

- proto: (Tie *) t1 : (Tie *) t2
{
  StaffObj *p, *q;
  client = [[NSMutableArray alloc] init];
  if (t1 != nil)
  {
    p = [t1 firstClient];
    [(NSMutableArray *)client addObject: p];
    [p linkhanger: self];
  }
  if (t2 != nil)
  {
    q = [t2 firstClient];
    [(NSMutableArray *)client addObject: q];
    [q linkhanger: self];
  }
  if (t1 == nil) t1 = t2;
  gFlags.subtype = mapTieSubtype[t1->gFlags.subtype];
  return [self setHanger];
}

/*sb: moved the following to top of file:#import "Volta.h" */

- proto: (Volta *) t
{
  int i;
  StaffObj *p;
  client = [[NSMutableArray alloc] init];
  if (t != nil)
  {
    p = [t firstClient];
      [(NSMutableArray *)client addObject: p];
    [p linkhanger: self];
    p = t->endpoint;
    [(NSMutableArray *)client addObject: p];
    [p linkhanger: self];
  }
  flags.bit0 = t->gFlags.subtype;
  gFlags.subtype = GROUPVOLTA;
  for (i = 0; i < 4; i++) mark[i] = t->mark[i];
  return [self setHanger];
}


/* remove from client anything not on list l.  Return whether an OK tuple. */

- (BOOL) isClosed: (NSMutableArray *) l
{
  [super closeClients: l];
  return ([client count] > 0);
}


- (void)removeObj
{
    [self retain];
    [super removeGroup];
    [self release];
}


/* return (x,y) of handle i */

char corner[2][4] =
{
  {0, 1, 1, 2},
  {2, 3, 0, 3}
};


- coordsForHandle: (int) i  asX: (float *) x  andY: (float *) y
{
  Graphic *p, *q;
  switch(corner[i][flags.position])
  {
    case 0:
      p = [client objectAtIndex:0];
      *x = p->bounds.origin.x + x1;
      *y = p->bounds.origin.y + y1;
     break;
    case 1:
      p = [client objectAtIndex:0];
      q = [client lastObject];
      *x = p->bounds.origin.x + x1;
      *y = q->bounds.origin.y + y2;
      break;
    case 2:
      p = [client objectAtIndex:0];
      q = [client lastObject];
      *x = q->bounds.origin.x + x2;
      *y = p->bounds.origin.y + y1;
      break;
    case 3:
      q = [client lastObject];
      *x = q->bounds.origin.x + x2;
      *y = q->bounds.origin.y + y2;
     break;
  }
  return self;
}


- (BOOL) getHandleBBox: (NSRect *) r
{
  float x, y;
  NSRect b;
  [self coordsForHandle: 0  asX: &x  andY: &y];
  *r = NSMakeRect(x - HANDSIZE, y - HANDSIZE, 2 * HANDSIZE, 2 * HANDSIZE);
  [self coordsForHandle: 1  asX: &x  andY: &y];
  b = NSMakeRect(x - HANDSIZE, y - HANDSIZE, 2 * HANDSIZE, 2 * HANDSIZE);
  *r  = NSUnionRect(b , *r);
  return YES;
}



/* override hit to find handles */

- (BOOL) hit: (NSPoint) p
{
    return [super hit: p : 0 : 1];
}

- (float) hitDistance: (NSPoint) p
{
  return [super hitDistance: p : 0 : 1];
}

/* override move */

- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
  StaffObj *n;
  switch(corner[gFlags.selend][flags.position])
  {
    case 0:
      n = [client objectAtIndex:0];
      x1 = p.x - n->bounds.origin.x;
      y1 = p.y - n->bounds.origin.y;
      break;
    case 1:
      n = [client objectAtIndex:0];
      x1 = p.x - n->bounds.origin.x;
      n = [client lastObject];
      y2 = p.y - n->bounds.origin.y;
      break;
    case 2:
      n = [client lastObject];
      x2 = p.x - n->bounds.origin.x;
      n = [client objectAtIndex:0];
      y1 = p.y - n->bounds.origin.y;
      break;
    case 3:
      n = [client lastObject];
      x2 = p.x - n->bounds.origin.x;
      y2 = p.y - n->bounds.origin.y;
      break;
  }
  flags.fixed = 1;
  [self recalc];
  return YES;
}


- (int)keyDownString:(NSString *)cc
{
  if (gFlags.subtype != GROUPVOLTA) return -1;
//  if (cs == NX_SYMBOLSET) return -1;
    if (![cc canBeConvertedToEncoding:NSASCIIStringEncoding]) return -1;
    if ([cc isEqualToString:@"|"]) flags.bit0 ^= 1;
  else if (isdigitchar(*[cc UTF8String]))
  {
      mark[0] = *[cc UTF8String];
    mark[1] = '.';
    mark[2] = '\0';
  }
  else return -1;
  return 1;
}

static void doDashJog(float x, float y, float x1, int j, int a, int sz, int m)
{
  float th = staffthick[0][sz];
    
  csetdash(YES, nature[sz] * 3);
  cline(x, y, x1, y, th, m);
  csetdash(NO, 0.0);

  if (j) {
    float sw = nature[sz] * (a ? 3 : -3);
    cline(x1, y, x1, y + sw, th, m);
  }
}


float fontsize[3] = { 12, 8, 6};

- drawMode: (int) m
{
    StaffObj *p, *q;
    Staff *sp;
    int sz, above, ss;
    NSFont *f, *ft;
    float px, py, qx, qy, th;
    char buff[16];
    BOOL splitLeftOnly = [self splitToLeft] && ![self splitToRight];
    BOOL noSplits = ![self splitToLeft] && ![self splitToRight];
    
    /* assume client sorted by the time we arrive here */
    sz = gFlags.size;
    p = [client objectAtIndex:0];
    q = [client lastObject];
    if (gFlags.selected && !gFlags.seldrag) {
	[self coordsForHandle: 0  asX: &px  andY: &py];
	chandle(px, py, m);
	[self coordsForHandle: 1  asX: &px  andY: &py];
	chandle(px, py, m);
    }
    px = p->bounds.origin.x + x1;
    py = p->bounds.origin.y + y1;
    qx = q->bounds.origin.x + x2;
    qy = q->bounds.origin.y + y2;
    switch(gFlags.subtype)
    {
	case 0: /* 8 --- */
	    if (flags.position != 0)
		py = qy;
	    if(![self splitToLeft]) {
		f = musicFont[1][sz];
		buff[0] = 165;
		buff[1] = '\0';
		CAcString(px, py + 0.5 * charFGH(f, 165), buff, f, m);
		doDashJog(px + nature[sz] + [f widthOfString: [NSString stringWithUTF8String: buff]], py, qx, noSplits, (flags.position == 0), sz, m);		  
	    }
	    else {
		doDashJog(px, py, qx, splitLeftOnly, (flags.position == 0), sz, m);
	    }
	    break;
	case 1: /* 15 --- */
	    if (flags.position != 0)
		py = qy;
	    if(![self splitToLeft]) {
		f = musicFont[1][sz];
		buff[0] = 193;
		buff[1] = 176;
		buff[2] = '\0';
		CAcString(px, py + 0.5 * charFGH(f, 165), buff, f, m);
		doDashJog(px + nature[sz] + [f widthOfString: [NSString stringWithUTF8String: buff]], py, qx, noSplits, (flags.position == 0), sz, m);
	    }
	    else {
		doDashJog(px, py, qx, splitLeftOnly, (flags.position == 0), sz, m);
	    }
	    break;
	case 2: /* coll' 8 */
	    if (flags.position != 0) 
		py = qy;
	    if(![self splitToLeft]) {
		f = musicFont[1][sz];
		// Replace with [[self client] staffScale]
		ft = [NSFont fontWithName:@"Times-Italic" size:fontsize[sz] / [[CalliopeAppController currentDocument] staffScale]];
		CAcString(px, py + 0.5 * charFGH(ft, '8'), "coll' 8", ft, m);
		doDashJog(px + nature[sz] + [ft widthOfString:@"coll' 8"], py, qx, noSplits, (flags.position == 0), sz, m);
	    }
	    else {
		doDashJog(px, py, qx, splitLeftOnly, (flags.position == 0), sz, m);
	    }
	    break;
	case 3: /* trill */
	    above = (flags.position == 0);
	    if(![self splitToLeft]) {
		f = musicFont[1][sz];
		DrawCharacterInFont(px, (above ? py : qy), 96, f, m);
		cbrack(6, flags.position, px + DrawWidthOfCharacter(f, 96), py, qx, qy, 0, 0, sz, m);
	    }
	    else {
		cbrack(6, flags.position, px, py, qx, qy, 0, 0, sz, m);
	    }
	    break;
	case 4:  /* arpegg */
	    cbrack(6, flags.position, px, py, qx, qy, 0, 0, sz, m);
	    break;
	case 5:  /* square bracket */
	    if(![self splitToLeft]) {
		if(![self splitToRight])
		    cbrack(0, flags.position, px, py, qx, qy, staffthick[0][sz], 0.1, sz, m);
		else
		    cbrack(9, flags.position, px, py, qx, qy, staffthick[0][sz], 0.1, sz, m);
	    } 	   
	    else {
		if(![self splitToRight])
		    cbrack(10, flags.position, px, py, qx, qy, staffthick[0][sz], 0.1, sz, m);
		else
		    cbrack(4, flags.position, px, py, qx, qy, staffthick[0][sz], 0, sz, m);		
	    }
	    break;
	case 6:  /* round bracket */
	    cbrack(1, flags.position, px, py, qx, qy, nature[sz] * 0.5, 0, sz, m);
	    break;
	case 7:  /* curly bracket */
	    cbrack(2, flags.position, px, py, qx, qy, 2 * nature[sz], 0, sz, m);
	    break;
	case 8:  /* angle bracket */
	    cbrack(3, flags.position, px, py, qx, qy, staffthick[0][sz], 0.1, sz, m);
	    break;
	case 9:  /* solid line */
	    cbrack(4, flags.position, px, py, qx, qy, staffthick[0][sz], 0, sz, m);
	    break;
	case 10:  /* dashed line */
	    cbrack(5, flags.position, px, py, qx, qy, staffthick[0][sz], 2 * nature[sz], sz, m);
	    break;
	case 11:  /* pedal */
	    cbrack(7, flags.position, px, py, qx, qy, staffthick[0][sz], 2 * nature[sz], sz, m);
	    break;
	case GROUPCRES:  /* crescendo */
	    if (flags.position == 0)
	    {
		cmakeline(px, py, qx, py - nature[sz], m);
		cmakeline(px, py, qx, py + nature[sz], m);
	    }
	    else
	    {
		cmakeline(px, qy, qx, qy - nature[sz], m);
		cmakeline(px, qy, qx, qy + nature[sz], m);
	    }
	    cstrokeline(staffthick[0][sz], m);
	    break;
	case GROUPDECRES:  /* decrescendo */
	    if (flags.position == 0)
	    {
		cmakeline(px, py - nature[sz], qx, py, m);
		cmakeline(px, py + nature[sz], qx, py, m);
	    }
	    else
	    {
		cmakeline(px, qy - nature[sz], qx, qy, m);
		cmakeline(px, qy + nature[sz], qx, qy, m);
	    }
	    cstrokeline(staffthick[0][sz], m);
	    break;
	case 14: /* flat bow */
	    cbrack(8, flags.position, px, py, qx, qy, 0.75 * nature[sz], 0, sz, m);
	    break;
	case 15: /* volta */
	    sp = [p staff];
	    th = barwidth[sp->flags.subtype][sp->gFlags.size];
	    ss = sp->flags.spacing;
	    qy = py + 5 * ss;
	    if(![self splitToLeft]) {
		CAcString(px + ss, qy, mark, fontdata[FONTTEXT], m);
		cmakeline(px, py, qx, py, m);
		cmakeline(px, py, px, qy, m);
		if (flags.bit0 && ([self splitToLeft] || ![self splitToRight])) 
		    cmakeline(qx, py, qx, qy, m);
	    }
	    else {
		cmakeline(px, py, qx, py, m);
		// Check that not splitting both ends.
		if (flags.bit0 && (![self splitToLeft] || ![self splitToRight]))
		    cmakeline(qx, py, qx, qy, m);
	    }
	    cstrokeline(th, m);
    }
    return self;
}


/* Archiving */

- (id)initWithCoder:(NSCoder *)aDecoder
{
  char b1, b2, b3;
  int v;
  [super initWithCoder:aDecoder];
  v = [aDecoder versionForClassName:@"NoteGroup"];
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"@ccffff", &client, &b1, &b2, &x1, &y1, &x2, &y2];
    flags.fixed = b1;
    flags.position = b2;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccffff", &b1, &b2, &x1, &y1, &x2, &y2];
    flags.fixed = b1;
    flags.position = b2;
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"icccffff", &UID, &b1, &b2, &b3, &x1, &y1, &x2, &y2];
    flags.fixed = b1;
    flags.position = b2;
      [self setSplitToLeft: (b3 & 2) == 2];
      [self setSplitToRight: (b3 & 1) == 1];

  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"ccffff", &b1, &b2, &x1, &y1, &x2, &y2];
    flags.fixed = b1;
    flags.position = b2;
  }
  else if (v == 4)
  {
    [aDecoder decodeArrayOfObjCType:"c" count:4 at:mark];
    [aDecoder decodeValuesOfObjCTypes:"cccffff", &b1, &b2, &b3, &x1, &y1, &x2, &y2];
    flags.fixed = b1;
    flags.position = b2;
    flags.bit0 = b3;
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  char b1, b2, b3;
  [super encodeWithCoder:aCoder];
  b1 = flags.fixed;
  b2 = flags.position;
  b3 = flags.bit0;
  [aCoder encodeArrayOfObjCType:"c" count:4 at:mark];
  [aCoder encodeValuesOfObjCTypes:"cccffff", &b1, &b2, &b3, &x1, &y1, &x2, &y2];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    [aCoder setInteger:flags.fixed forKey:@"fixed"];
    [aCoder setInteger:flags.position forKey:@"position"];
    [aCoder setInteger:flags.bit0 forKey:@"bit0"];
    [aCoder setInteger:4 forKey:@"NUMMARK"];
    for (i = 0; i < 4; i++) [aCoder setInteger:mark[i] forKey:[NSString stringWithFormat:@"mark%d",i]];
    [aCoder setFloat:x1 forKey:@"x1"];
    [aCoder setFloat:y1 forKey:@"y1"];
    [aCoder setFloat:x2 forKey:@"x2"];
    [aCoder setFloat:y2 forKey:@"y2"];
}


@end
