/*
  Various constants ported from mux
  $Id$
*/
  
#ifndef MUX_H
#define MUX_H 

#import <AppKit/AppKit.h>
#import "winheaders.h"
#import "sonata.h"
#import "musfont.h"

#define NS_VERSION 3

/* various constants */

/* the "built-in" fonts known to reside at fontdata[index] */

#define NUMCALFONTS 20
#define FONTTEXT 1		/* our id for text font */
#define FONTSTMR  3		/* our id for figures font */
#define FONTSON 17		/* our if for Sonata */
#define FONTSSON 18		/* our id for small Sonata */
#define FONTHSON 19		/* our id for half-sized Sonata */
#define FONTMUS  0		/* our ID for musical symbols font */
#define FONTSMUS 15		/* our id for small music font */
#define FONTHMUS 16		/* our id for half-sized music font */

/* type codes index array of short bitcodes */

#define TC_HANGER   1
#define TC_STAFFOBJ 2
#define TC_TIMEDOBJ 4
#define TC_SIG 8
#define TC_BLOCKSYM 16
#define TC_SOUNDS 32
#define TC_SIGBLOCK 64
#define TC_VOICED 128
#define TC_TWIN 256

#define ISAHANGER(p) (typecode[[p graphicType]] & TC_HANGER)
#define ISASTAFFOBJ(p) (typecode[[p graphicType]] & TC_STAFFOBJ)
#define ISATIMEDOBJ(p) (typecode[[p graphicType]] & TC_TIMEDOBJ)
#define ISASIG(p) (typecode[[p graphicType]] & TC_SIG)
#define ISABLOCKSYM(p) (typecode[[p graphicType]] & TC_BLOCKSYM)
#define ISASIGBLOCK(p) (typecode[[p graphicType]] & TC_SIGBLOCK)
#define ISAVOCAL(p) (typecode[[p graphicType]] & TC_SOUNDS)
#define HASAVOICE(p) (typecode[[p graphicType]] & TC_VOICED)
#define ISATWIN(p) (typecode[[p graphicType]] & TC_TWIN)


/*
  Head styles: 0=none, 1=modern, 2=oldbook, 3=harmonic, 4=speech, 5=oldbook coloured, 6=shapenote
  Stem styles: 0=modern, 1=oldbook, 2=tabstraight, 3=tabcurve
  Accidentals: unused, flat, sharp, natural, d-flat, d-sharp, 3q-flat, 1q-flat, 3q-sharp, 1q-sharp
*/


#define NUMHEADS 7
#define NUMSTEMS 4
#define NUMACCS 10
#define CROTCHET 5		/* body designation */
#define QUAVER 4

/* bitmasks for charclasses */

#define CHPUNCT 1
#define CHVOWEL 2
#define CHEDBRA 4
#define CHOPBRA 8
#define CHACCID 16
#define CHDIGIT 32
#define CHTABLE 64
#define CHALFAB 128
#define CHACOUT 256		/* an out-of-staff accent */
#define CHFIGURE 512

#define ispunctuation(c) (charclass[(int)c & 0xFF] & CHPUNCT)
#define isvowel(c) (charclass[(int)c & 0xFF] & CHVOWEL)
#define isedbrack(c) (charclass[(int)c & 0xFF] & CHEDBRA)
#define isopenbrack(c) (charclass[(int)c & 0xFF] & CHOPBRA)
#define isaccident(c) (charclass[(int)c & 0xFF] & CHACCID)
#define isdigitchar(c) (charclass[(int)c & 0xFF] & CHDIGIT)
#define istabchar(c) (charclass[(int)c & 0xFF] & CHTABLE)
#define isalfabeto(c) (charclass[(int)c & 0xFF] & CHALFAB)
#define figurechar(c) (charclass[(int)c & 0xFF] & CHFIGURE)
#define ISOUTACCENT(c) (charclass[(int)c & 0xFF] & CHACOUT)

/* text justification */

#define JLEFT 0
#define JCENTRE 1
#define JRIGHT 2



/* soft limit number of staves and voices on a system */

#define NUMSTAVES 32
#define NUMVOICES 256

/* used by inspectors */

#define NUMATTR 32
#define ALLSAME(i, num)  (acount[i] == num)
#define ALLVAL(i) (aval[i])
#define ALLSAMEFLOAT(i, num)  (facount[i] == num)
#define ALLVALFLOAT(i) (faval[i])
#define ALLSAMEATOM(i, num)  (aacount[i] == num)
#define ALLVALATOM(i) (aaval[i])

/* various useful constants functions */

#define HYPHCHAR (45)		/* the one thing NeXTEncoding got right */
#define UPARROW 173
#define DOWNARROW 175
#define LEFTARROW 172
#define RIGHTARROW 174
#define TIECHAR (198)		/* use as baseline tie char */
#define PTPMM 2.834646		/* points per mm */
#define DEGpRAD (180.0 / 3.1415926) /* degrees per radian */
#define TOLFLOATEQ(f1, f2, t) (ABS((f1)-(f2)) <= t)
#define GETYSP(y, ss, pos) ((y) + ((ss) * (pos)))
//#warning SB: the bounding rect for font may be giving rel vals where abs are required
//#define fontAscent(f) ([f pointSize] * [f metrics]->fontBBox[3])
//#define fontAscent(f) ([f pointSize] * ([f boundingRectForFont].size.height - [f boundingRectForFont].origin.y))
#define fontAscent(f) ([f boundingRectForFont].size.height + [f boundingRectForFont].origin.y)
//#warning SB: the bounding rect for font may be giving rel vals where abs are required
//#define fontDescent(f) ([f pointSize] * [f metrics]->fontBBox[1])
//#define fontDescent(f) ([f pointSize] * [f boundingRectForFont].origin.y)
#define fontDescent(f) ([f boundingRectForFont].origin.y)
#define HANDSIZE 4		/* handle half-width */


/* various globals */

extern BOOL dragflag;

extern int currentTool;

extern int drawmode[2][4];	/* drawmode[selected][invis] */
extern int markmode[2];		/* markmode[selected] */

extern NSFont *musicFont[2][3];
extern NSFont *fontdata[NUMCALFONTS];
extern float DrawWidthOfCharacter(NSFont *f, int ch);
extern float charFLLY(NSFont *f, int ch);
extern float charFURY(NSFont *f, int ch);
extern float charFLLX(NSFont *f, int ch);
extern float charFURX(NSFont *f, int ch);
extern float charFGH(NSFont *f, int ch);
extern float charFGW(NSFont *f, int ch);
extern float charFCW(NSFont *f, int ch);
extern float charFCH(NSFont *f, int ch);
extern float charhalfFGW(NSFont *f, int ch);


extern short typecode[];
extern char nature[3];
extern float pronature[3];
extern char smallersz[3];
extern char largersz[3];
extern unsigned char bodies[4][10];
extern unsigned char bodyfont[4][10];
extern char edbrackets[];
extern float stemthicks[3];
extern float linethicks[3];
extern float barwidth[3][3]; 
extern char stemlens[2][3];
extern float staffthick[3][3];
extern unsigned short charclass[256];


/* character metric globals */


/* for inspectors */

extern int acount[NUMATTR];
extern int aval[NUMATTR];
extern int facount[NUMATTR];
extern float faval[NUMATTR];
extern int aacount[NUMATTR];
extern NSString *aaval[NUMATTR];
extern void initassay();
extern void assay(int i, int val);
extern void assayAsFloat(int i, float val);
extern void assayAsAtom(int i, NSString *val);
extern void clearMatrix(NSMatrix *p);

/* global routines */

float convertFrom(int u, float x, int r);
float convertTo(int u, float x, int r);
void DrawInit();
void colorInit(int i, NSColor * c);
extern void bbinit();
extern NSRect getbb();

/*!
  @brief draw a character in font f. 
 */
void DrawCharacterInFont(float x, float y, int ch, NSFont *f, int mode);

/*!
  @brief Draw a string, in a given font, inserting baseline ties where needed. 
 */
void DrawTextWithBaselineTies(float x, float y, NSString *stringToDisplay, NSFont *textFont, int mode);

//sb: changed the following from cString to CAcString to avoid confusion.
void CAcString(float x, float y, const char *s, NSFont *f, int mode);

/*!
  @brief Draw text centered around the point x,y in the given font.
 */
extern void DrawCenteredText(float x, float y, NSString *s, NSFont *f, int mode);

/*!
  @brief Draw text justified.
 */
extern void DrawJustifiedText(float x, float y, NSString *s, NSFont *f, int j, int mode);

/*!
 @brief draw a character centred on x and y.
 */
extern void DrawCharacterCenteredInFont(float x, float y, int ch, NSFont *f, int mode);

/*!
 @brief draw a character centred on x only 
 */
extern void DrawCharacterCenteredOnXInFont(float x, float y, int ch, NSFont *f, int mode);

/*!
  @brief Assigns the dash pattern (in number of points of the dash portion) to be used when drawing.
  */
void csetdash(BOOL drawWithDash, float pattern);

extern void cstrokeline(float width, int mode);
extern void cline(float x1, float y1, float x2, float y2, float width, int mode);
extern void cmakeline(float x1, float y1, float x2, float y2, int mode);
extern void coutrect(float x, float y, float w, float h, float lw, int mode);
extern void chandle(float x, float y, int mode);
extern void crect(float x, float y, float w, float h, int mode);

/*!
  @function ccircle
  @brief draw (part of) a circle centred on x and y.
 */
void ccircle(float x, float y, float r, float a1, float a2, float w, int mode);

/*! 
  @brief draw a full ellipse.
 */
void cellipse(float cx, float cy, float rx, float ry, float w, int mode);

/*!
  @function cslant
  @brief draw a filled slant, starting at x1, y1 slanting to x2, y2 of dy thickness.
 */
void cslant(float x1, float y1, float x2, float y2, float dy, int mode);

/*!
  @function coutslant
  @brief draw an outline slant, starting at x1, y1 slanting to x2, y2 of dy thickness, the outline lw wide.
 */ 
extern void coutslant(float x1, float y1, float x2, float y2, float dy, float lw, int mode);

/*!
  @function cbrace
  @brief draw a brace.
  @param flourishThickness is max allowed thickness of the flourish.
 */
void cbrace(float x0, float y0, float xn, float yn, float flourishThickness, int mode);

/*!
  @function ccurve
  @brief Draw a curve forward and backward, potentially altering the curve at each stage.
  @param x0, y0 point to draw from.
  @param x3, y3 point to draw to.
  @param x1, y1 forward control point 1.
  @param x2, y2 forward control point 2.
  @param x4, y4 reverse control point 2.
  @param x5, y5 reverse control point 1.
 */ 
void ccurve(float x0, float y0, float x3, float y3, float x1, float y1, float x2, float y2, float x4, float y4, float x5, float y5, float th, int dash, int mode);

/*!
  @function cflat
 */ 
void cflat(float x0, float y0, float x1, float y1, float c1x, float c1y, float c2x, float c2y, float th, int dash, int m);

#if 0 // obsolete
/*!
  @function ctie
 */ 
void ctie(float cx, float cy, float d, float h, float th, float a, float f, int dash, int mode);
#endif

/*!
  @function cfillrect
 */ 
void cfillrect(float x, float y, float w, float h, float lw, int mode);

/*!
  @function cbrack
 */ 
void cbrack(int i, int p, float px, float py, float qx, float qy, float th, float d, int sz, int m);

/*!
  @function cdashhjog
 */ 
void cdashhjog(float x0, float y, float x1, int a, float nat, float th, int m);

/*!
  @function cenclosure
 */ 
void cenclosure(int i, float px, float py, float qx, float qy, float th, int sz, int m);

#endif // MUX_H
