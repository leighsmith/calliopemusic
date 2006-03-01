/*
  $Id$
  Various lowlevel drawing routines
  The mode passed to routines is
  	0 for BB
	1 print & display ink
	2 print & display tone 1
	3 print & display tone 2
	4 display only invis objects
	5 display only markers
	6 display only background
	7 display only selection
  modegray[0] is thus never used.
  Only mode 1,2,3 prints on paper.
*/

#import "mux.h"
#import <AppKit/AppKit.h>

#import "DrawApp.h"

#define BRANGLE   (30.0)  /* bracket tilt = BRANGLE * aspect ratio */
#define NOPRINT(m) (![[NSGraphicsContext currentContext] isDrawingToScreen] && noprint[m])

extern NSColor * backShade;
extern NSColor * selShade;
extern NSColor * markShade;
extern NSColor * inkShade;

int linein = 0;

// TODO should be hidden in a class & access controlled to it with labels.
NSFont *fontdata[NUMCALFONTS];  /* known locations for needed fonts */
NSFont *musicFont[2][3];		/* known locations for [which][size] */

short typecode[NUMTYPES] =
{
  0							/* VACANT 0 */,
  0							/* BRACKET 1 */,
  TC_STAFFOBJ | TC_BLOCKSYM				/* BARLINE 2 */,
  TC_STAFFOBJ | TC_SIG | TC_BLOCKSYM | TC_SIGBLOCK	/* TIMESIG 3 */,
  TC_STAFFOBJ | TC_TIMEDOBJ | TC_SOUNDS	| TC_VOICED	/* NOTE 4 */,
  TC_STAFFOBJ | TC_TIMEDOBJ | TC_VOICED			/* REST 5 */,
  TC_STAFFOBJ | TC_SIG | TC_BLOCKSYM | TC_SIGBLOCK	/* CLEF 6 */,
  TC_STAFFOBJ | TC_SIG | TC_BLOCKSYM | TC_SIGBLOCK	/* KEY 7 */,
  TC_STAFFOBJ | TC_SIG | TC_BLOCKSYM | TC_SIGBLOCK	/* RANGE 8 */,
  TC_STAFFOBJ | TC_TIMEDOBJ | TC_SOUNDS			/* TABLATURE 9 */,
  0							/* TEXTBOX 10 */,
  TC_STAFFOBJ | TC_BLOCKSYM | TC_SIGBLOCK		/* BLOCK 11 */,
  TC_HANGER						/* BEAM 12 */,
  TC_HANGER   | TC_TWIN					/* TIE 13 */,
  TC_HANGER						/* METRO 14 */,
  TC_HANGER						/* ACCENT 15 */,
  TC_HANGER						/* TUPLE 16 */,
  TC_STAFFOBJ | TC_TIMEDOBJ | TC_SOUNDS	| TC_VOICED	/* NEUME 17 */,
  0							/* STAFF 18 */,
  0							/* SYSTEM 19 */,
  0							/* RUNNER 20 */,
  TC_HANGER						/* VOLTA 21 */,
  TC_HANGER						/* GROUP 22 */,
  0							/* ENCLOSURE 23 */,
  TC_STAFFOBJ | TC_TIMEDOBJ | TC_SOUNDS | TC_VOICED	/* SQUARENOTE 24 */,
  0							/* CHORDGROUP 25 */,
  TC_HANGER						/* TIENEW 26 */,
  TC_HANGER						/* LIGATURE 27 */,
  TC_STAFFOBJ | TC_TIMEDOBJ | TC_SOUNDS	| TC_VOICED	/* NEUMENEW 28 */,
  0							/* MARGIN 29 */,
  TC_HANGER						/* IMAGE 30 */

};

char sigorder[NUMTYPES] =
{
  9, 9, 9, 3, 9, 9, 1, 2, 4, 9, 9, 0, 9, 9, 9, 9,
  9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
};

char *typename[NUMTYPES] =
{
"VACANT",
"BRACKET", "BARLINE", "TIMESIG", "NOTE", "REST", "CLEF", "KEY", "RANGE", "TABLATURE", "TEXTBOX",
"BLOCK", "BEAM", "TIE", "METRO", "ACCENT", "TUPLE", "NEUME", "STAFF", "SYSTEM", "RUNNER", "VOLTA",
"GROUP", "ENCLOSURE", "SQUARENOTE", "CHORDGROUP", "TIENEW", "LIGATURE", "NEUMENEW", "MARGIN",
"IMAGE"
};

char nature[3] = {4, 3, 2};		/* size constants of Nature */
float pronature[3] = {1.0, 0.75, 0.5};	/* specified proportionally */

char smallersz[3] = {1, 2, 2};
char largersz[3] = {0, 0, 1};

float linethicks[3] = {1.6, 1.2, 0.8};

float barwidth[3][3] = 		/* barwidth[staff type][size] */
{
  {0.6, 0.45, 0.3},
  {0.9, 0.675, 0.45},
  {1.2, 0.9, 0.6}
};


/* Returns a suitable index into modegray[] and noprint[] based on [selected][invisible] */

int drawmode[2][4] =
{
  {1, 4, 3, 2},
  {7, 7, 7, 7}
};

int markmode[2] = {5, 7};


BOOL noprint[8] =
{
  0, 0, 0, 0, 1, 1, 1, 1
};


static NSColor * modegray[8];

BOOL modeprint[] = {};

NSRect bb;	/* to accumulate the bounding box */


void msg(NSString *s)
{
  [NSApp log: s];
}


/* initialise the graphics stuff */

void colorInit(int i, NSColor * c)
{
  modegray[0] = [[NSColor whiteColor] retain]; /* for BB: not used */
  switch(i)
  {
    case 0:  /* background */
      backShade = [c retain];
        modegray[6] = [c retain];
      break;
    case 1:  /* ink */
        inkShade = [c retain];
        modegray[1] = [c retain];
      break;
    case 2:  /* markers */
        markShade = [c retain];
        modegray[5] = [c retain];
      break;
    case 3:  /* selection */
        selShade = [c retain];
        modegray[7] = [c retain];
      break;
    case 4:  /* invis */
        modegray[4] = [c retain];
      break;
    case 5:  /* tone 1 */
        modegray[2] = [c retain];
      break;
    case 6:  /* tone 2 */
        modegray[3] = [c retain];
      break;
  }
}


void PSInit()
{
  PSWrapsInit();
}


float charFWX(NSFont *f, int ch)
{
//    NSRect myRect;
////    NXFontMetrics *fm = [f metrics];
////  return [f pointSize] * (fm->charMetrics[fm->encoding[ch]]).xWidth;
//    myRect = [f boundingRectForGlyph:(NSGlyph)ch];
//    return myRect.size.width;/*sb: should already be scaled */
    return [f advancementForGlyph:ch].width;
}

float charFLLY(NSFont *f, int ch)
{
    NSRect myRect;
//  NXFontMetrics *fm = [f metrics];
//  return [f pointSize] * (fm->charMetrics[fm->encoding[ch]]).bbox[1];
    myRect = [f boundingRectForGlyph:(NSGlyph)ch];
    return myRect.origin.y;/*sb: should already be scaled */
}

float charFURY(NSFont *f, int ch)
{
    NSRect myRect;
//  NXFontMetrics *fm = [f metrics];
//  return [f pointSize] * (fm->charMetrics[fm->encoding[ch]]).bbox[3];
    myRect = [f boundingRectForGlyph:(NSGlyph)ch];
    return myRect.size.height + myRect.origin.y;/*sb: should already be scaled */
}

float charFLLX(NSFont *f, int ch)
{
    NSRect myRect;
//  NXFontMetrics *fm = [f metrics];
//  return [f pointSize] * (fm->charMetrics[fm->encoding[ch]]).bbox[0];
    myRect = [f boundingRectForGlyph:(NSGlyph)ch];
    return myRect.origin.x;/*sb: should already be scaled */
}

float charFURX(NSFont *f, int ch)
{
    NSRect myRect;
//  NXFontMetrics *fm = [f metrics];
//  return [f pointSize] * (fm->charMetrics[fm->encoding[ch]]).bbox[2];
    myRect = [f boundingRectForGlyph:(NSGlyph)ch];
    return myRect.size.width + myRect.origin.x;/*sb: should already be scaled */
}

float charFGH(NSFont *f, int ch)
{
    NSRect myRect;
//  NXFontMetrics *fm = [f metrics];
//  NXCharMetrics *cm = &(fm->charMetrics[fm->encoding[ch]]);
//  return [f pointSize] * (cm->bbox[3] - cm->bbox[1]);
    myRect = [f boundingRectForGlyph:(NSGlyph)ch];
    return myRect.size.height;
}

float charFGW(NSFont *f, int ch)
{
    NSRect myRect;
//  NXFontMetrics *fm = [f metrics];
//  NXCharMetrics *cm = &(fm->charMetrics[fm->encoding[ch]]);
//  return [f pointSize] * (cm->bbox[2] - cm->bbox[0]);
    myRect = [f boundingRectForGlyph:(NSGlyph)ch];
    return myRect.size.width;
}

float charFCW(NSFont *f, int ch)
{
    NSRect myRect;
//  NXFontMetrics *fm = [f metrics];
//  NXCharMetrics *cm = &(fm->charMetrics[fm->encoding[ch]]);
//  return 0.5 * [f pointSize] * (cm->bbox[2] + cm->bbox[0]);
    myRect = [f boundingRectForGlyph:(NSGlyph)ch];
    return (myRect.origin.x + 0.5 * myRect.size.width);
}

float charFCH(NSFont *f, int ch)
{
    NSRect myRect;
//  NXFontMetrics *fm = [f metrics];
//  NXCharMetrics *cm = &(fm->charMetrics[fm->encoding[ch]]);
//  return 0.5 * [f pointSize] * (cm->bbox[1] + cm->bbox[3]);
    myRect = [f boundingRectForGlyph:(NSGlyph)ch];
    return (myRect.origin.y + 0.5 * myRect.size.height);
}

float charhalfFGW(NSFont *f, int ch)
{
    NSRect myRect;
//  NXFontMetrics *fm = [f metrics];
//  NXCharMetrics *cm = &(fm->charMetrics[fm->encoding[ch]]);
//  return 0.5 * [f pointSize] * (cm->bbox[2] - cm->bbox[0]);
    myRect = [f boundingRectForGlyph:(NSGlyph)ch];
    return (0.5 * myRect.size.width);
}


/* Bounding Box routines */

void bbinit()
{
  bb = NSZeroRect;
}


NSRect getbb()
{
  return bb;
}


/* unions the current path (then does a newpath) into bb */

void unionpath()
{
  NSRect r;
  float llx, lly, urx, ury;
  PSpathbbox(&llx, &lly, &urx, &ury);
  /* NSLog(@"unionpath BB = %f %f %f %f\n", llx, lly, urx - llx, ury - lly); */
  PSnewpath();
  /*  --llx; ++urx; --lly; ++ury; */
  r = NSMakeRect(llx, lly, urx - llx, ury - lly);
  bb  = NSUnionRect(r , bb);
}


/* unions the argument into bb */

void unionrect(float x, float y, float w, float h)
{
  NSRect r;
  /* --x; --y; w +=2; h+=2; */
  r = NSMakeRect(x, y, w, h);
  bb  = NSUnionRect(r , bb);
}


/*
  String handling.
*/

/*
  unions the char BB into b
  special handling of the baseline tie (faked by a descender)
  special handling of space (because bbox = 0)
*/

void unionCharBB(NSRect *b, float x, float y, int ch, NSFont *f)
/*sb: seems to union b BELOW (x,y), with the character ch in font. Why? */
{
  NSRect r;
    /*  NXFontMetrics *fm = [f metrics]; */
//  float ps = [f pointSize];
  NSRect cm;
  if (ch == ' ')
  {
    ch = 'x';
//    cm = &(fm->charMetrics[fm->encoding[ch]]);
      cm = [f boundingRectForGlyph:ch];
    r.origin.x = x;
//    r.origin.y = y - ps * cm->bbox[3];
//    r.size.height = ps * (cm->bbox[3] - cm->bbox[1]);
    r.origin.y = y - (cm.origin.y + cm.size.height); //sb:FIXME ????
    r.size.height = cm.size.height;
    ch = ' ';
//    cm = &(fm->charMetrics[fm->encoding[ch]]);
    cm = [f boundingRectForGlyph:ch];
//    r.size.width = ps * cm->xWidth;
//    r.size.width = cm.size.width;
    r.size.width = [f advancementForGlyph:ch].width;
  }
  else
  {
      if (ch == TIECHAR) ch = 'g';
//    cm = &(fm->charMetrics[fm->encoding[ch]]);
      cm = [f boundingRectForGlyph:ch];
//    r.origin.x = ps * cm->bbox[0] + x;
//    r.origin.y = y - ps * cm->bbox[3];
//    r.size.width = ps * (cm->bbox[2] - cm->bbox[0]);
//    r.size.height = ps * (cm->bbox[3] - cm->bbox[1]);
      r.origin.x = x + cm.origin.x;
      r.origin.y = y - (cm.origin.y + cm.size.height);
      r.size.width = cm.size.width;
      r.size.height = cm.size.height;
  }
  *b  = NSUnionRect(r , *b);
}


void unionStringBB(NSRect *b, float x, float y, char *s, NSFont *f, int j)
{
  NSRect r;
//  NXFontMetrics *fm = [f metrics];
//  float ps = [f pointSize];
//  NXCharMetrics *cm;
  NSRect cm;
  char ch;
  
  if (j == JCENTRE) x -= 0.5 * [f widthOfString: [NSString stringWithCString: s]];
  else if (j == JRIGHT) x -= [f widthOfString: [NSString stringWithCString: s]];
  while (ch = *s++)
  {
    if (ch == ' ')
    {
      ch = 'x';
//      cm = &(fm->charMetrics[fm->encoding[ch]]);
//      r.origin.x = x;
//      r.origin.y = y - ps * cm->bbox[3];
//      r.size.height = ps * (cm->bbox[3] - cm->bbox[1]);
//      ch = ' ';
//      cm = &(fm->charMetrics[fm->encoding[ch]]);
//      r.size.width = ps * cm->xWidth;
        cm = [f boundingRectForGlyph:ch];
      r.origin.x = x;
      r.origin.y = y - (cm.origin.y + cm.size.height); //sb:FIXME ????
      r.size.height = cm.size.height;
      ch = ' ';
      cm = [f boundingRectForGlyph:ch];
//      r.size.width = cm.size.width;
      r.size.width = [f advancementForGlyph:ch].width;
    }
    else
    {
      if (ch == TIECHAR) ch = 'g';
//      cm = &(fm->charMetrics[fm->encoding[ch]]);
//      r.origin.x = ps * cm->bbox[0] + x;
//      r.origin.y = y - ps * cm->bbox[3];
//      r.size.width = ps * (cm->bbox[2] - cm->bbox[0]);
//      r.size.height = ps * (cm->bbox[3] - cm->bbox[1]);
      cm = [f boundingRectForGlyph:ch];
      r.origin.x = x + cm.origin.x;
      r.origin.y = y - (cm.origin.y + cm.size.height);
      r.size.width = cm.size.width;
      r.size.height = cm.size.height;
    }
      *b  = NSUnionRect(r , *b);
//      x += ps * cm->xWidth;
//      x += r.size.width;
      x += [f advancementForGlyph:ch].width;
  }
}


/* draw a character in font f. */

void drawCharacterInFont(float x, float y, int ch, NSFont *f, int mode)
{
  char s[2];
  if (NOPRINT(mode)) return;
  if (mode)
  {
    s[0] = ch; s[1] = '\0';
    [f set];
    PSmoveto(x, y);
    [modegray[mode] set];
//NSLog(@"show('%s', %f, %f)\n", s, x, y);
    PSshow(s);
  }
  else unionCharBB(&bb, x, y, ch, f);
}


/* draw a character centred on x and y */

void centChar(float x, float y, int ch, NSFont *f, int mode)
{
  if (NOPRINT(mode)) return;
  drawCharacterInFont(x - charFCW(f, ch), y + charFCH(f, ch), ch, f, mode);
}

/* draw a character centred on x only */

void centxChar(float x, float y, int ch, NSFont *f, int mode)
{
  if (NOPRINT(mode)) return;
  drawCharacterInFont(x - charFCW(f, ch), y, ch, f, mode);
}

/* draw a string, inserting baseline ties where needed.  NOT extern, please */

void cShow(char *s, NSFont *f, int m)
{
  float w, h, pts;
  unsigned char c, t[256], *p;
  w = charFWX(f, TIECHAR);
  pts = [f pointSize];
  h = 0.1 * pts;
  p = t;
  while (c = *s++)
  {
    if (c == TIECHAR)
    {
      *p = '\0';
      PSshow(t);
      p = t;
      PStietext(w, 1.5, 0.3 * pts, 0.15 * pts, 0.5 * w, h);
    }
    else *p++ = c;
  }
  if (p != t)
  {
    *p = '\0';
    PSshow(t);
  } 
}


/* draw a string in font f */
//sb: changed the following from cString to CAcString to avoid confusion.
void CAcString(float x, float y, char *s, NSFont *f, int mode)
{
  if (NOPRINT(mode)) return;
  if (mode)
  {
    PSmoveto(x, y);
    [modegray[mode] set];
    [f set];
// NSLog(@"show(%s, %f, %f)\n", s, x, y);
    cShow(s, f, mode);
  }
  else unionStringBB(&bb, x, y, s, f, 0);
}


void centString(float x, float y, char *s, NSFont *f, int mode)
{
  CAcString(x - 0.5 * [f widthOfString:[NSString stringWithCString:s]], y, s, f, mode);
}

void justString(float x, float y, char *s, NSFont *f, int j, int mode)
{
  if (j == JCENTRE) x -= 0.5 * [f widthOfString:[NSString stringWithCString:s]];
  else if (j == JRIGHT) x -= [f widthOfString:[NSString stringWithCString:s]];
  CAcString(x, y, s, f, mode);
}


/* draw a line. Three routines to: make, stroke, or make&stroke. */

void cmakeline(float x1, float y1, float x2, float y2, int mode)
{
  if (NOPRINT(mode)) return;
    if ((![[NSGraphicsContext currentContext] isDrawingToScreen] && ![[NSPrintOperation currentOperation] isEPSOperation])) {
        PSCmakelinePrint(x1, y1, x2, y2);
    }
    else {
        PSCmakelineDisplay(x1, y1, x2, y2);
    }
  linein = 1;
}


void cstrokeline(float width, int mode)
{
  if (NOPRINT(mode)) return;
  if (linein == 0)
  {
    msg(@"cstrokeline: no line to stroke!\n");
    return;
  }
  if (mode)
  {
    [modegray[mode] set];
    PSsetlinewidth(width);
    PSstroke();
  }
  else
  {
    PSsetlinewidth(width);
    PSstrokepath();
// NSLog(@"strokeline(%f,%d)\n", width, mode);
    unionpath();
  }
  linein = 0;
}


void cline(float x1, float y1, float x2, float y2, float width, int mode)
{
  if (NOPRINT(mode)) return;
    if ((![[NSGraphicsContext currentContext] isDrawingToScreen] && ![[NSPrintOperation currentOperation] isEPSOperation])) {
        PSCmakelinePrint(x1, y1, x2, y2);
    }
    else {
        PSCmakelineDisplay(x1, y1, x2, y2);
    }
  linein = 1;
  cstrokeline(width, mode);
}


/* draw a filled rectangle */

void crect(float x, float y, float w, float h, int mode)
{
  if (NOPRINT(mode)) return;
  if (mode)
  {
    [modegray[mode] set];
    PSrectfill(x, y, w, h);
  }
  else unionrect(x, y, w, h);
}


/* draw a filled rectangle using linewidth (replaces crect) */

void cfillrect(float x, float y, float w, float h, float lw, int mode)
{
  float d;
  if (NOPRINT(mode)) return;
  d = lw * 0.5;
  if (mode)
  {
    [modegray[mode] set];
    PSrectfill(x - d, y - d, w + lw, h + lw);
  }
  else
  {
    unionrect(x - d, y - d, w + lw, h + lw);
  }
}

/* draw an outline rectangle. */

void coutrect(float x, float y, float w, float h, float lw, int mode)
{
  float d;
  if (NOPRINT(mode)) return;
  if (mode)
  {
    [modegray[mode] set];
    PSsetlinewidth(lw);
    PSrectstroke(x, y, w, h);
  }
  else
  {
    d = lw * 0.5;
    unionrect(x - d, y - d, w + lw, h + lw);
  }
}


/* draw a handle */

void chandle(float x, float y, int m)
{
  crect(x - HANDSIZE, y - HANDSIZE, 2*HANDSIZE, 2*HANDSIZE, (m == 7 ? markmode[0] : m));
}


/* draw a filled slant */

void cslant(float x1, float y1, float x2, float y2, float dy, int mode)
{
  if (NOPRINT(mode)) return;
  if (mode)
  {
    [modegray[mode] set];
    PSslant(x2 - x1, dy, y2 - y1, x1, y1);
    PSfill();
  }
  else
  {
    PSslant(x2 - x1, dy, y2 - y1, x1, y1);
    PSsetlinewidth(0);
    PSstrokepath();
// NSLog(@"cslant(%f,...,%d)\n", x1, mode);
    unionpath();
  }
}


/* draw an outline slant */

void coutslant(float x1, float y1, float x2, float y2, float dy, float lw, int mode)
{
  if (NOPRINT(mode)) return;
  if (mode)
  {
    PSslant(x2 - x1, dy, y2 - y1, x1, y1);
    [modegray[mode] set];
    PSsetlinewidth(lw);
    PSstroke();
  }
  else
  {
    PSslant(x2 - x1, dy, y2 - y1, x1, y1);
    PSsetlinewidth(lw);
    PSstrokepath();
// NSLog(@"coutslant(%f,...,%d)\n", x1, mode);
    unionpath();
  }
}


/* draw (part of) a circle centred on x and y */

void ccircle(float x, float y, float r, float a1, float a2, float w, int mode)
{
  if (NOPRINT(mode)) return;
  if (mode)
  {
    PSnewpath();
    PSarc(x, y, r, a1, a2);
    [modegray[mode] set];
    PSsetlinewidth(w);
    PSstroke();
  }
  else
  {
    w *= 0.5;
    unionrect(x - r - w, y - r - w, 2 * r + w, 2 * r + w);
  }
}


/* draw (part of) an ellipse */

void cellipse(float cx, float cy, float rx, float ry, float a1, float a2, float w, int mode)
{
  if (NOPRINT(mode)) return;
  if (mode)
  {
    PSellipse(cx, cy, rx, ry, a1, a2);
    [modegray[mode] set];
    PSsetlinewidth(w);
    PSstroke();
  }
  else
  {
    w *= 0.5;
    unionrect(cx - rx - w, cy - ry - w, 2 * rx + w, 2 * ry + w);
  }
}


/* draw a brace.  th is max allowed thickness of the flourish */


void cbrace(float x0, float y0, float xn, float yn, float th, int mode)
{
  float dx, dy, d, t, u, h, c1x, c1y, c2x, c2y;
  float x1, y1, x2, y2, x3, y3;
  if (NOPRINT(mode)) return;
  dx = xn - x0;
  dy = yn - y0;
  d = hypot(dx, dy);
  h = 0.1 * d;
  if (h > (2 * th)) h = 2 * th;
  th = 0.5 * h;
  t = -(h / d);
  u = -((h - th) / d);
  x3 = x0 + 0.5 * dx - t * dy;
  y3 = y0 + 0.5 * dy + t * dx;
  c2x = 0.5 - 0.05;
  c2y = 0.05;
  c1x = 0.1;
  c1y = t - 0.05;
  x2 = x0 + c2x * dx - c2y * dy;
  y2 = y0 + c2x * dy + c2y * dx;
  x1 = x0 + c1x * dx - c1y * dy;
  y1 = y0 + c1x * dy + c1y * dx;
  PSmoveto(x0, y0);
  PScurveto(x1, y1, x2, y2, x3, y3);
  c1x = 1.0 - 0.1;
  c1y = t - 0.05;
  c2x = 0.5 + 0.05;
  c2y = 0.05;
  x2 = x0 + c2x * dx - c2y * dy;
  y2 = y0 + c2x * dy + c2y * dx;
  x1 = x0 + c1x * dx - c1y * dy;
  y1 = y0 + c1x * dy + c1y * dx;
  PScurveto(x2, y2, x1, y1, xn, yn);
  c1x = 1.0 - 0.1;
  c1y = u - 0.05;
  c2x = 0.5 + 0.05;
  c2y = (u - t) + 0.05;
  x2 = x0 + c2x * dx - c2y * dy;
  y2 = y0 + c2x * dy + c2y * dx;
  x1 = x0 + c1x * dx - c1y * dy;
  y1 = y0 + c1x * dy + c1y * dx;
  PScurveto(x1, y1, x2, y2, x3, y3);
  c2x = 0.5 - 0.05;
  c2y = (u - t) + 0.05;
  c1x = 0.1;
  c1y = u - 0.05;
  x2 = x0 + c2x * dx - c2y * dy;
  y2 = y0 + c2x * dy + c2y * dx;
  x1 = x0 + c1x * dx - c1y * dy;
  y1 = y0 + c1x * dy + c1y * dx;
  PScurveto(x2, y2, x1, y1, x0, y0);
  PSclosepath();
  if (mode)
  {
    [modegray[mode] set];
    PSfill();
  }
  else
  {
    PSflattenpath();
// NSLog(@"cbrace(%f,...,%d)\n", x0, mode);
    unionpath();
  }
}


void ccurve(float x0, float y0, float x3, float y3, float x1, float y1, float x2, float y2, float x4, float y4, float x5, float y5, float th, int dash, int mode)
{
  if (NOPRINT(mode)) return;
  PSmoveto(x0, y0);
  PScurveto(x1, y1, x2, y2, x3, y3);
  if (dash)
  {
    if (mode)
    {
      [modegray[mode] set];
      PSsetlinewidth(th * 0.5);
      PSstroke();
    }
    else
    {
      PSflattenpath();
// NSLog(@"ccurve(dash)(%f,...,%d)\n", x0, mode);
      unionpath();
    }
    return;
  }
  PScurveto(x5, y5, x4, y4, x0, y0);
  PSclosepath();
  if (mode)
  {
    [modegray[mode] set];
    PSfill();
  }
  else
  {
    PSflattenpath();
// NSLog(@"ccurve(nodash)(%f,...,%d)\n", x0, mode);
    unionpath();
  }
}


/*
  Flat curves reinterpret the control points to provide a basis for 4 splines.
*/

void cflat(float x0, float y0, float x1, float y1, float c1x, float c1y, float c2x, float c2y, float th, int dash, int mode)
{
  float dx, dy, d, t;
  float px0, py0, px1, py1, px2, py2, px3, py3;
  if (NOPRINT(mode)) return;
  dx = x1 - x0;
  dy = y1 - y0;
  px1 = x0 - 0.5 * c1y * dy;
  py1 = y0 + 0.5 * c1y * dx;
  px2 = x0 - c1y * dy;
  py2 = y0 + c1y * dx;
  px3 = x0 + c1x * dx - c1y * dy;
  py3 = y0 + c1x * dy + c1y * dx;
  PSmoveto(x0, y0);
  PScurveto(px1, py1, px2, py2, px3, py3);
  px0 = x0 + c2x * dx - c2y * dy;
  py0 = y0 + c2x * dy + c2y * dx;
  px1 = x0 + dx - c2y * dy;
  py1 = y0 + dy + c2y * dx;
  px2 = x0 + dx - 0.5 * c2y * dy;
  py2 = y0 + dy + 0.5 * c2y * dx;
  px3 = x0 + dx;
  py3 = y0 + dy;
  PSlineto(px0, py0);
  PScurveto(px1, py1, px2, py2, px3, py3);
  if (dash)
  {
    if (mode)
    {
      [modegray[mode] set];
      PSsetlinewidth(th * 0.5);
      PSstroke();
    }
    else
    {
      PSflattenpath();
// NSLog(@"cflat(dash)(%f,...,%d)\n", x0, mode);
      unionpath();
    }
    return;
  }
  d = hypot(dx, dy);
  t = (c2y * d - th) / d;
  px0 = x0 + c2x * dx - t * dy;
  py0 = y0 + c2x * dy + t * dx;
  px1 = x0 + dx - t * dy;
  py1 = y0 + dy + t * dx;
  px2 = x0 + dx - 0.5 * t * dy;
  py2 = y0 + dy + 0.5 * t * dx;
  PScurveto(px2, py2, px1, py1, px0, py0);
  t = (c1y * d - th) / d;
  px0 = x0;
  py0 = y0;
  px1 = x0 - 0.5 * t * dy;
  py1 = y0 + 0.5 * t * dx;
  px2 = x0 - t * dy;
  py2 = y0 + t * dx;
  px3 = x0 + c1x * dx - t * dy;
  py3 = y0 + c1x * dy + t * dx;
  PSlineto(px3, py3);
  PScurveto(px2, py2, px1, py1, px0, py0);
  PSclosepath();
  if (mode)
  {
    [modegray[mode] set];
    PSfill();
  }
  else
  {
    PSflattenpath();
// NSLog(@"cflat(nodash)(%f,...,%d)\n", x0, mode);
    unionpath();
  }
}


/*
  This goes when Tie goes.
*/
void ctie(float cx, float cy, float d, float h, float th, float a, float f, int dash, int mode)
{
  float hmin, r, dx, dy;
  if (NOPRINT(mode)) return;
  hmin = h - th;
  r = 0.5 * d;
  dy = r * sin(10.0 / (180.0 * 3.14159));
  dx = r * (1.0 - cos(10.0 / (180.0 * 3.14159)));
  PSgsave();
  if (dash)
  {
    PStiedash(cx, cy, dy, r + dx, hmin, f, a);
    if (mode)
    {
      [modegray[mode] set];
      PSsetlinewidth(th);
      PSstroke();
    }
    else unionpath();
  }
  else
  {
    PStie(cx, cy, dy, (h / hmin), r + dx, hmin, f, a);
    if (mode)
    {
      [modegray[mode] set];
      PSfill();
    }
    else
    {
      unionpath();
    }
  }
  PSgrestore();
}


/* draw strings CHUNKSZ at a time (cheaper than xyshow) */

#define CHUNKSZ 32

static void cwaveh(float x0, float x1, float y, int sz, int m)
{
  char buff[CHUNKSZ];
  NSFont *f = musicFont[1][sz];
  float cw = charFWX(f, 126);
  int i, n;
  n = ((x1 - x0) / cw) + 0.5;
  if (n < 1) n = 1;
  while (n)
  {
    i = 0;
    while (n && i < (CHUNKSZ - 1))
    {
      buff[i++] = 126;
      --n;
    }
    buff[i] = '\0';
    CAcString(x0, y, buff, f, m);
    x0 += i * cw;
  }
}


/* caller ensures y1 > y0 */

static void cwavev(float x, float y0, float y1, int sz, int m)
{
  NSFont *f = musicFont[1][sz];
  float ch = 0.5 * charFGH(f, 103);
  int n;
  n = ((y1 - y0) / ch) + 0.5;
  if (n < 1) n = 1;
  while (n--)
  {
    drawCharacterInFont(x, y1, 103, f, m);
    y1 -= ch;
  }
}


/* control points for a shaded bow */

#define C1U 0.2
#define C1V -0.15
#define C2U 0.8
#define C2V -0.15

static void cspline(float x0, float y0, float x3, float y3, float th, int dash, int mode)
{
  float x1, y1, x2, y2, x4, y4, x5, y5, d, t;
  float dx = x3 - x0;
  float dy = y3 - y0;
  x1 = x0 + C1U * dx - C1V * dy;
  y1 = y0 + C1U * dy + C1V * dx;
  x2 = x0 + C2U * dx - C2V * dy;
  y2 = y0 + C2U * dy + C2V * dx;
  d = hypot(dx, dy);
  t = (C1V * d - th) / d;
  x4 = x0 + C1U * dx - t * dy;
  y4 = y0 + C1U * dy + t * dx;
  t = (C2V * d - th) / d;
  x5 = x0 + C2U * dx - t * dy;
  y5 = y0 + C2U * dy + t * dx;
  ccurve(x0, y0, x3, y3, x1, y1, x2, y2, x4, y4, x5, y5, th, dash, mode);
}


static void cflatbow(float px, float py, float qx, float qy, float th, int m)
{
  float d, t;
  d = hypot(qx - px, qy - py);
  if (d < 5) d = 5;
  t = d * 0.25;
  if (t > 12.0) t = 12.0;
  if (t < 4.0) t = 4.0;
  t /= d;
  t *= -0.75;
  cflat(px, py, qx, qy, 0.25, t, 0.75, t, th, 0, m);
}


/* draw an orthogonal bracket */


void cbrack(int i, int p, float px, float py, float qx, float qy, float th, float d, int sz, int m)
{
  float dpattern[1];
  float dx, dy, ry;
  switch(i)
  {
    case 0:  /* square bracket */
      dx = qx - px;
      dy = qy - py;
      switch(p)
      {
        case 0:
	  dx *= d;
	  dy *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, py, qx, py, m);
          cmakeline(px, py, px, py + d, m);
          cmakeline(qx, py, qx, py + d, m);
          break;
        case 1:
	  dx *= d;
	  dy *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, qy, qx, qy, m);
          cmakeline(px, qy, px, qy - d, m);
          cmakeline(qx, qy, qx, qy - d, m);
          break;
        case 2:
	  dy *= d;
	  dx *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, py, px, qy, m);
          cmakeline(px, py, px + d, py, m);
          cmakeline(px, qy, px + d, qy, m);
          break;
        case 3:
	  dy *= d;
	  dx *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(qx, py, qx, qy, m);
          cmakeline(qx, py, qx - d, py, m);
          cmakeline(qx, qy, qx - d, qy, m);
          break;
      }
      cstrokeline(th, m);
      break;
    case 1:  /* round bracket */
      switch(p)
      {
        case 0:
	  cspline(px, py, qx, py, th, 0, m); 
          break;
        case 1:
	  cspline(qx, qy, px, qy, th, 0, m); 
          break;
        case 2:
	  cspline(px, qy, px, py, th, 0, m); 
          break;
        case 3:
	  cspline(qx, py, qx, qy, th, 0, m); 
          break;
      }
      break;
    case 2:  /* curly bracket */
      switch(p)
      {
        case 0:
	  cbrace(px, py, qx, py, th, m); 
          break;
        case 1:
	  cbrace(qx, qy, px, qy, th, m); 
          break;
        case 2:
	  cbrace(px, qy, px, py, th, m); 
          break;
        case 3:
	  cbrace(qx, py, qx, qy, th, m); 
          break;
      }
      break;
    case 3:  /* angle bracket */
      dx = qx - px;
      dy = qy - py;
      switch(p)
      {
        case 0:
          ry = 0.5 * dx + px;
	  dx *= d;
	  dy *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, py, ry, py - d, m);
          cmakeline(ry, py - d, qx, py, m);
          break;
        case 1:
          ry = 0.5 * dx + px;
	  dx *= d;
	  dy *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, qy, ry, qy + d, m);
          cmakeline(ry, qy + d, qx, qy, m);
          break;
        case 2:
          ry = 0.5 * dy + py;
	  dy *= d;
	  dx *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, py, px - d, ry, m);
          cmakeline(px - d, ry, px, qy, m);
          break;
        case 3:
          ry = 0.5 * dy + py;
	  dy *= d;
	  dx *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(qx, py, qx + d, ry, m);
          cmakeline(qx + d, ry, qx, qy, m);
          break;
      }
      cstrokeline(th, m);      
      break;
    case 4:  /* solid line */
      switch(p)
      {
        case 0:
	  cline(px, py, qx, py, th, m);
	  break;
        case 1:
	  cline(px, qy, qx, qy, th, m);
	  break;
        case 2:
	  cline(px, py, px, qy, th, m);
	  break;
        case 3:
	  cline(qx, py, qx, qy, th, m);
          break;
      }
      break;
    case 5:  /* dashed line */
      dpattern[0] = d;
      PSsetdash(dpattern, 1, 0.0);
      switch(p)
      {
        case 0:
	  cline(px, py, qx, py, th, m);
	  break;
        case 1:
	  cline(px, qy, qx, qy, th, m);
	  break;
        case 2:
	  cline(px, py, px, qy, th, m);
	  break;
        case 3:
	  cline(qx, py, qx, qy, th, m);
          break;
      }
      PSsetdash(dpattern, 0, 0.0);
      break;
    case 6:  /* wavy line */
      switch(p)
      {
        case 0:
          cwaveh(px, qx, py, sz, m);
	  break;
        case 1:
          cwaveh(px, qx, qy, sz, m);
	  break;
        case 2:
          cwavev(px, py, qy, sz, m);
	  break;
        case 3:
	  cwavev(qx, py, qy, sz, m);
          break;
      }
      break;
    case 7:  /* pedal line */
      cmakeline(px, qy, px, qy + d, m);
      cmakeline(px, qy + d, qx, qy, m);
      cmakeline(qx, qy, qx, qy + d, m);
      cstrokeline(th, m);      
      break;
    case 8: /* a 'flat' bow */
      switch(p)
      {
        case 0:
	  cflatbow(px, py, qx, py, th, m); 
          break;
        case 1:
	  cflatbow(qx, qy, px, qy, th, m); 
          break;
        case 2:
	  cflatbow(px, qy, px, py, th, m); 
          break;
        case 3:
	  cflatbow(qx, py, qx, qy, th, m); 
          break;
      }
      break;
    case 9:  /* a bracket having only the first jog */
      dx = qx - px;
      dy = qy - py;
      switch(p)
      {
        case 0:
	  dx *= d;
	  dy *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, py, qx, py, m);
          cmakeline(px, py, px, py + d, m);
          break;
        case 1:
	  dx *= d;
	  dy *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, qy, qx, qy, m);
          cmakeline(px, qy, px, qy - d, m);
          break;
        case 2:
	  dy *= d;
	  dx *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, py, px, qy, m);
          cmakeline(px, py, px + d, py, m);
          break;
        case 3:
	  dy *= d;
	  dx *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(qx, py, qx, qy, m);
          cmakeline(qx, py, qx - d, py, m);
          break;
      }
      cstrokeline(th, m);
      break;
    case 10:  /* a bracket having only the last jog */
      dx = qx - px;
      dy = qy - py;
      switch(p)
      {
        case 0:
	  dx *= d;
	  dy *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, py, qx, py, m);
          cmakeline(qx, py, qx, py + d, m);
          break;
        case 1:
	  dx *= d;
	  dy *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, qy, qx, qy, m);
          cmakeline(qx, qy, qx, qy - d, m);
          break;
        case 2:
	  dy *= d;
	  dx *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(px, py, px, qy, m);
          cmakeline(px, qy, px + d, qy, m);
          break;
        case 3:
	  dy *= d;
	  dx *= 0.25;
	  d = MIN(dx, dy);
          cmakeline(qx, py, qx, qy, m);
          cmakeline(qx, qy, qx - d, qy, m);
          break;
      }
      cstrokeline(th, m);
      break;
  }
}

/* draw one of 7 types of enclosure */

void cenclosure(int i, float px, float py, float qx, float qy, float th, int sz, int m)
{
  float d, dx, dy, rx, ry;
  switch(i)
  {
    case 0:  /* square brackets */
      cbrack(0, 2, px, py, qx, qy, th, 0.1, sz, m);
      cbrack(0, 3, px, py, qx, qy, th, 0.1, sz, m);
      break;
    case 1:  /* round brackets */
      cbrack(1, 2, px, py, qx, qy, th, 0, sz, m);
      cbrack(1, 3, px, py, qx, qy, th, 0, sz, m);
      break;
    case 2:  /* curly brackets */
      d = nature[sz];
      cbrack(2, 2, px, py, qx, qy, d, 0, sz, m);
      cbrack(2, 3, px, py, qx, qy, d, 0, sz, m);
      break;
    case 3:  /* angle brackets */
      cbrack(3, 2, px, py, qx, qy, th, 0.1, sz, m);
      cbrack(3, 3, px, py, qx, qy, th, 0.1, sz, m);
      break;
    case 4:  /* box */
      cmakeline(px, py, qx, py, m);
      cmakeline(qx, py, qx, qy, m);
      cmakeline(px, qy, qx, qy, m);
      cmakeline(px, py, px, qy, m);
      cstrokeline(th, m);
      break;
    case 5:  /* circle */
      dx = 0.5 * (qx - px);
      dy = 0.5 * (qy - py);
      d = (dx > dy) ? dx : dy;
      rx = dx + px;
      ry = dy + py;
      ccircle(rx, ry, d, 0.0, 360.0, th, m);
      break;
    case 6:  /* ellipse */
      dx = 0.5 * (qx - px);
      dy = 0.5 * (qy - py);
      rx = dx + px;
      ry = dy + py;
      cellipse(rx, ry, dx, dy, 0.0, 360.0, th, m);
      break;
  }
}
