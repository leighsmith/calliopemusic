/* $Id$ */
#import <AppKit/NSFontManager.h>
#import <Foundation/NSArray.h>
#import "Verse.h"
#import "GNote.h"
#import "System.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "DrawingFunctions.h"
#import "muxlow.h"


@implementation Verse

extern float staffthick[3][3];

+ (void) initialize
{
    if (self == [Verse class]) {
	[Verse setVersion: 3];		/* class version, see read: */
    }
}


- init
{
    self = [super init];
    if(self != nil) {
	vFlags.hyphen = 0;
	font = [[[NSFontManager sharedFontManager] selectedFont] retain];
	offset = 0;
	align = 0;
	verseString = nil;
	note = nil;	
    }
    return self;
}


- (void) dealloc
{
    [verseString release];
    verseString = nil;
    [font release];
    font = nil;
    [super dealloc];
}


- sysInvalid
{
  return [note sysInvalid];
}

- (NSString *) string
{
    return (verseString == nil) ? @"" : [[verseString retain] autorelease];
}

- (int) length
{
    if (verseString == nil)
	return 0;
    return [verseString length];
}

/* return whether a string is a blank verse */
- (BOOL) isBlank
{
    int characterIndex;
    
    if (verseString == nil)
	return YES;
    for (characterIndex = 0; characterIndex < [verseString length]; characterIndex++) 
	if ([verseString characterAtIndex: characterIndex] != ' ')
	    return NO;
    return YES;
}

- (void) setString: (NSString *) newText
{
    [verseString release];
    verseString = [newText retain];
}

- (NSFont *) font
{
    return [[font retain] autorelease];
}

- (void) setFont: (NSFont *) newFont
{
    [font release];
    font = [newFont retain];
}

/* override in case of blank verse */

- recalc
{
    if (verseString == nil || [verseString length] == 0) {
	StaffObj *p = note;
	Staff *sp = [p staff];
	
	if ([sp graphicType] != STAFF) 
	    return self;
	bounds.origin.x = p->x - 6;
	bounds.origin.y = [sp yOfTop] + baseline - 12;
	bounds.size.width = bounds.size.height = 12;
	[sp sysInvalid];
    }
    else 
	[super recalc];
    return self;
}

- (void) setBaseline: (float) newBaseline aboveStaff: (BOOL) yesOrNo
{   
    baseline = newBaseline;
    vFlags.above = yesOrNo;
}

/* for copying verse.  Caller must set the note and alignVerse and recalc */
- copyWithZone: (NSZone *) zone
{
    Verse *newVerse = [super copyWithZone: zone];
    
    newVerse->vFlags = vFlags;
    newVerse->font = font;
    newVerse->offset = offset;
    newVerse->baseline = baseline;
    // I do a deep copy here to imitate earlier behaviour but it is probably unnecessary.
    newVerse->verseString = [verseString copy];
    return newVerse;
}


/* removeObj is sent by the client, who expects Verse to remove itself */
/*sb: FIXME need to check this */

- (void)removeObj
{
    [self retain];
    [note unlinkverse: self];
    [self release];
}


- (BOOL) isFigure
{
    int characterIndex;
  
    if (verseString == nil)
	return NO;
    
    for(characterIndex = 0; characterIndex < [verseString length]; characterIndex++)
	if (!figurechar([verseString characterAtIndex: characterIndex]))
	    return NO;
    return YES;
}


- (BOOL) isContinuation
{
    unichar ch;
    
    if (verseString == nil)
	return NO;
    ch = [verseString characterAtIndex: 0];
    return (ch == CONTHYPH || ch == CONTLINE);
}


- (BOOL) getHandleBBox: (NSRect *) r
{
    NSRect b = bounds;
    
    b = NSInsetRect(b , -3.0 , -3.0);
    *r  = NSUnionRect(b , *r);
    return YES;
}


/*
  Set the versebox caches.  The default alignment depends on the
  justification code (auto=0, left=1, right=2)
*/

/* return half significant width (up to first smile if any) and full width */

static void sigwidthpix(NSString *s, NSFont *f, float *sw, float *w)
{
    float n = 0.0, sn = 0.0, cw;
    
    if (s != nil) {
	int characterIndex;
	BOOL sig = YES;
	
	for (characterIndex = 0; characterIndex < [s length]; characterIndex++) {
	    unichar c = [s characterAtIndex: characterIndex];
	    
	    if (c == TIECHAR)
		sig = NO;
	    cw = DrawWidthOfCharacter(f, c);
	    n += cw;
	    if (sig) 
		sn += cw;
	}	
    }
    *sw = sn * 0.5;
    *w = n;
}

- (int) verseNumber
{
    return vFlags.num;
}

- (void) setVerseNumber: (int) verseNumber
{
    vFlags.num = verseNumber;
}


/*
  set the align and pixlen field based on contents of the string.
  Alignment rule: using only the significant characters
  (those up to the first smile),
  align under first vowel or centre, whichever offset is smaller.
*/

- alignVerse
{
    float vw, hw;
    int characterIndex;
    
    if (verseString == nil) {
	align = 0;
	return self;
    }
    sigwidthpix(verseString, font, &hw, &pixlen);
    vw = 0.0;
    for (characterIndex = 0; characterIndex < [verseString length]; characterIndex++) {
	unichar c = [verseString characterAtIndex: characterIndex];

	if (c == TIECHAR)
	    break;
	vw += charFGW(font, c);
	if (isvowel(c)) 
	    break;
    }
    align = MIN(vw, hw);
    return self;
}


- reShape
{
    return [self alignVerse];
}


/*
  Handle insertion/deletion from a verse.  Complication due to
  needing to redraw preceding hyphen if any, and also resetting
  figure time flags.
  0x80 is the Alt-Space key for inputting a baseline tie.
  If very first char, check it if a figure to set default font.
  cycle... is a state machine to determine the next possible hyphen mode.
*/


- (int) keyDownString: (NSString *) cc
{
    int verseStringLength;
    unichar startingCharacter = [cc characterAtIndex: 0];
    BOOL f = NO;
    
    if ([cc canBeConvertedToEncoding: NSASCIIStringEncoding]) {
	/* NSLog(@"cc = %@\n", cc); */
	if (startingCharacter == 0x80) 
	    startingCharacter = TIECHAR;
	verseStringLength = (verseString == nil) ? -1 : [verseString length];
	if (startingCharacter == 32 && verseString == nil) {
	    NSLog(@"Verse -keyDownString: startingCharacter == 32 && verseString == nil");
	    return 0;
	}
	if (startingCharacter == 127) {
	    if (verseStringLength <= 0) {
		NSLog(@"Verse -keyDownString: verseStringLength <= 0");
		return 0;
	    }
	    [verseString autorelease];
	    verseString = [verseString substringToIndex: verseStringLength - 1];
	    if (verseStringLength == 1) {
		f = YES;
		/* verse has been cleared */
		vFlags.hyphen = 0;
		offset = 0;
	    }
	}
	else if (startingCharacter == HYPHCHAR)
	    vFlags.hyphen = (vFlags.hyphen == 1) ? 0 : 1;
	else if (startingCharacter == '_')
	    vFlags.hyphen = (vFlags.hyphen == 2) ? 0 : 2;
	else {
	    f = YES;
	    [verseString release];
	    if (verseStringLength < 0) {
		verseString = [[NSString stringWithCharacters: &startingCharacter length: 1] retain];
	    }
	    else {
		verseString = [[verseString stringByAppendingString: [NSString stringWithCharacters: &startingCharacter length: 1]] retain];
	    }
	    if (verseStringLength <= 0) {
		font = [[CalliopeAppController currentDocument] getPreferenceAsFont: ([self isFigure]) ? FIGFONT : TEXFONT];
	    }
	    if (startingCharacter == CONTHYPH)
		vFlags.hyphen = 1;
	    else if (startingCharacter == CONTLINE)
		vFlags.hyphen = 2;
	}
    }
    [self reShape];
    [self recalc];
    if (f && [[note staff] graphicType] == STAFF) {
	StaffObj *p = [[note staff] prevVersed: note : [self verseNumber]];
	
	if (p != nil) {
	    Verse *v = [p verseOf: [self verseNumber]];
	    
	    [[p pageView] reDraw: v];
	    [v recalc];
	}
    }
    return 1;
}



- (BOOL) hit: (NSPoint) p
{
  return NSPointInRect(p , bounds);
}



/*
  draw a repeated hyphen to fill space (add extra hyphen if fill to right end)
   just: 0 = centred, 1 = right just, 2 = left just, 3 = left and right just
*/

static void drawrepeat(float x1, float x2, float y, NSFont *f, int just, int m)
{
  int n;
  float inc, x, dx;
  dx = x2 - x1;
  n = ((int) ABS(dx)) / 64 + 1;
  inc = dx / (n + 1);
  x = x1;
  switch(just)
  {
    case 1:
      if (n > 1)
      {
        inc = dx / n;
        x = x1 - DrawWidthOfCharacter(f, HYPHCHAR);
      }
      break;
    case 2:
      if (n > 1)
      {  
        inc = dx / n;
        x = x1 - inc;
      }
      break;
    case 3:
      inc = dx / n;
      x = x1 - inc - DrawWidthOfCharacter(f, HYPHCHAR);
      ++n;
      break;
  }
  while (n--)
  {
    x += inc;
    DrawCharacterCenteredOnXInFont(x, y, HYPHCHAR, f, m);
  }
}


/* draw an extender */

static void drawext(float x1, float y, float x2, Staff *sp, int f, int m)
{
  if (f)
  {
    x1 += 2;
    x2 -= 2;
  }
  if (x2 > x1) cline(x1, y, x2, y, 1.1 * staffthick[sp->flags.subtype][sp->gFlags.size], m);
}


/* return the left edge coordinate of a verse syllable */

- (float) textLeft: (StaffObj *) p
{
  return(p->x + [p verseOrigin] - align + offset);
}


/* display a whole line of continuation (hyphen or melisma) */
- drawContinuation: (int) ch atX: (float) x0 atY: (float) bl onStaff: (Staff *) sp inMode: (int) m
{
    float x1 = [sp xOfEnd];
    
    if (ch == CONTHYPH) 
	drawrepeat(x0, x1, bl, font, 3, m);
    else if (ch == CONTLINE) 
	drawext(x0, bl, x1, sp, 0, m);
    return self;
}


/* display a figure below the y-line */
- drawFigure: (NSString *) figureString atX: (float) x atY: (float) y onStaff: (Staff *) sp inMode: (int) m
{
    float fy, cx, cy, nlead=0.0, centoffy;
    unsigned char c, nc, a=0, ct[3];
    NSFont *f = font;
    NSFont *sf = musicFont[1][1];
    const char *s = [figureString UTF8String];
    
    ct[1] = ct[2] = '\0';
    nlead = fontAscent(f);
    centoffy = 0.5 * charFGH(f, '3') - charFURY(f, '3');
    if (vFlags.above) {
	y -= figHeight(figureString, nlead) - nlead;
    }
    fy = y;
    while (c = *s++) {
	if (c == '1') {
	    ct[0] = c;
	    if (*s != '\0') ct[1] = *s++;
	    // TODO we should convert to a full NSString operation.
	    DrawCenteredText(x, fy, [NSString stringWithUTF8String: (char *) ct], f, m);
	    fy += nlead;
	    ct[1] = ct[2] = '\0';
	}
	else if (c == ' ') {
	    fy += nlead;
	}
	else if (isaccident(c))	{
	    if (c == '!') 
		a = SF_natural;
	    else if (c == '@')
		a = SF_flat;
	    else if (c == '#')
		a = SF_sharp;
	    nc = *s;
	    cy = fy + centoffy;
	    if (nc == '3') {
		s++;
		cx = x;
		fy += nlead;
	    }
	    else if (nc == '\0') {
		cx = x;
		fy += nlead;
	    }
	    else 
		cx = x - charFGW(f, *s);
	    DrawCharacterCenteredOnXInFont(cx, cy + charFCH(sf, a), a, sf, m);
	}
	else {
	    DrawCharacterCenteredOnXInFont(x, fy, c, f, m);
	    /* now look ahead to see if the next char is a + or / */
	    nc = *s;
	    if (nc == '+') {
		DrawCharacterInFont(x + charFCW(f, c), fy, nc, f, m);
		++s;
	    }
	    else if (nc == '/') {
		DrawCharacterCenteredOnXInFont(x, fy, nc, f, m);
		++s;
	    }
	    fy += nlead;
	}
    }
    return self;
}


/*
  Draw the Ith verse of a staff object as the Jth line.
*/
- drawMode: (int) m
{
    int h;
    float bl, cx, ex, mx;
    StaffObj *q;
    StaffObj *p = note;
    Staff *sp = [note staff];

    if ([sp graphicType] != STAFF) 
	return self;
    if (m && [p isSelected] && !p->gFlags.seldrag && p->selver == [self verseNumber])
	[self traceBounds];
    if (verseString == nil || [verseString length] == 0) 
	return self;
    bl = [sp yOfTop] + baseline;
    if ([self isFigure])
	return [self drawFigure: [self string] atX: p->x atY: bl onStaff: sp inMode: m];
    if ([self isContinuation])
	return [self drawContinuation: [verseString characterAtIndex: 0] atX: p->x atY: bl onStaff: sp inMode: m];
    cx = [self textLeft: p];
    DrawTextWithBaselineTies(cx, bl, verseString, font, m);
    if (vFlags.hyphen < 3 && ![sp textedBefore: p : [self verseNumber]]) {
	System *sys = [sp mySystem];

	h = [[sys pageView] prevHyphened: sys : [sp myIndex] : [self verseNumber] : p->voice];
	if (h == 1) {
	    ex = [sp firstTimedBefore: p];
	    mx = 2.0 * charFGW(font, HYPHCHAR);
	    if (cx - ex < mx)
		DrawCharacterCenteredOnXInFont(cx - mx, bl, HYPHCHAR, font, m);
	    else
		drawrepeat(ex, cx, bl, font, 2, m);
	}
	else if (h == 2 && [sp vocalBefore: p : [self verseNumber]]) {
	    ex = [sp xOfHyphmarg];
	    mx = [sp endMelisma: [sp getNote: 0] : [self verseNumber]];
	    drawext(ex, bl, mx, sp, 1, m);
	}
    }
    switch(vFlags.hyphen) {
    case 0:
	break;
    case 1:
	q = [sp nextVersed: p : [self verseNumber]];
	if (q == nil) {
	    drawrepeat(cx + pixlen, [sp xOfEnd], bl, font, 1, m);
	}
	else {
	    drawrepeat(cx + pixlen, [[q verseOf: [self verseNumber]] textLeft: q], bl, font, 0, m);
	}
	break;
    case 2:
	ex = [sp endMelisma: p : [self verseNumber]];
	drawext(cx + pixlen, bl, ex, sp, 1, m);
	break;
    case 3:
	DrawCharacterInFont(cx + pixlen + 2, bl, HYPHCHAR, font, m);
	break;
    case 4:
	ex = cx + pixlen + 2;
	cline(ex, bl, ex + charFGW(font, '_'), bl, 1.1 * staffthick[sp->flags.subtype][sp->gFlags.size], m);
	break;
    case 5:
	ex = cx - charFGW(font, HYPHCHAR) - 2;
	DrawCharacterInFont(ex, bl, HYPHCHAR, font, m);
	break;
    case 6:
	ex = cx - charFGW(font, '_') - 2;
	cline(ex, bl, ex + charFGW(font, '_'), bl, 1.1 * staffthick[sp->flags.subtype][sp->gFlags.size], m);
	break;
    }
    return self;
}


/*
  Assumes that verses are never invisible.  Figures might have invisible notes
*/
- draw
{
  return [self drawMode: [Graphic drawingModeIfSelected: [(Graphic *)note isSelected] ifInvisible: 0]];
}


/*
  Version 1 archives fonts the AppKit way, but still uses fids
*/

struct oldflags		/* for old versions */
{
  unsigned int hyphen : 2;	/* type of hyphen */
  unsigned int line : 3;	/* actual line */
  unsigned int num : 3;		/* verse number */
};


- (id)initWithCoder:(NSCoder *)aDecoder
{
    short len, flen;
    float fs;
    char fn[64];
    struct oldflags ff;
    char *data;
    char b1, b2, b3;
    int v = [aDecoder versionForClassName: @"Verse"];
    
  [super initWithCoder: aDecoder];
  /* NSLog(@"reading Verse v%d\n", v); */
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"sssccff", &ff, &len, &flen, &offset, &align, &fs, &pixlen];
    vFlags.hyphen = ff.hyphen;
    vFlags.line = ff.line;
    vFlags.num = ff.num;
    data = malloc(len + 1);
    [aDecoder decodeArrayOfObjCType:"c" count:len at:data];
    data[len] = '\0';
    [aDecoder decodeArrayOfObjCType:"c" count:flen at:fn];
    fn[flen] = '\0';
    font = [NSFont fontWithName: [NSString stringWithUTF8String:fn] size: fs];
    note = [[aDecoder decodeObject] retain];
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"@@fscc*", &font, &note, &pixlen, &ff, &offset, &align, &data];
    vFlags.hyphen = ff.hyphen;
    vFlags.line = ff.line;
    vFlags.num = ff.num;
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"@@fcc*", &font, &note, &pixlen, &offset, &align, &data];
    [aDecoder decodeValuesOfObjCTypes:"ccc", &b1, &b2, &b3];
    vFlags.hyphen = b1;
    vFlags.line = b2;
    vFlags.num = b3;
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"@@ffcc*", &font, &note, &pixlen, &baseline, &offset, &align, &data];
    [aDecoder decodeValuesOfObjCTypes:"ccc", &b1, &b2, &b3];
    vFlags.hyphen = b1;
    vFlags.line = b2;
    vFlags.num = b3;
  }
    // If the font was encoded with a flipped view, we need to revert to a positive matrix.
    if ([font pointSize] < 0) {
	const CGFloat *matrix = [font matrix];
	CGFloat newFontMatrix[6];
	
	memcpy(newFontMatrix, matrix, 6 * sizeof(float));
	newFontMatrix[3] = -matrix[3]; // Invert the view.
	[font autorelease];
	font = [NSFont fontWithName: [font fontName] matrix: newFontMatrix];
    }

    verseString = [[NSString stringWithCString: data encoding: NSNEXTSTEPStringEncoding] retain];
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    char b1, b2, b3;
    const char *stringData = [verseString cStringUsingEncoding: NSNEXTSTEPStringEncoding];
    
    [super encodeWithCoder:aCoder];
    [aCoder encodeValuesOfObjCTypes:"@@ffcc*", &font, &note, &pixlen, &baseline, &offset, &align, &stringData];
    b1 = vFlags.hyphen;
    b2 = vFlags.line;
    b3 = [self verseNumber];
    [aCoder encodeValuesOfObjCTypes:"ccc", &b1, &b2, &b3];
}

- (void) encodeWithPropertyListCoder: (OAPropertyListCoder *)aCoder
{
    [super encodeWithPropertyListCoder: (OAPropertyListCoder *)aCoder];
    [aCoder setObject: font forKey: @"font"];
    [aCoder setObject: note forKey: @"note"];
    [aCoder setFloat: pixlen forKey: @"pixlen"];
    [aCoder setFloat: baseline forKey: @"baseline"];
    [aCoder setInteger: offset forKey: @"offset"];
    [aCoder setInteger: align forKey: @"align"];
    [aCoder setObject: verseString forKey: @"verseString"];
    [aCoder setInteger: vFlags.hyphen forKey: @"hyphen"];
    [aCoder setInteger: vFlags.line forKey: @"line"];
    [aCoder setInteger: [self verseNumber] forKey: @"num"];
}

@end
