/* global graphics/timing routines */

#import "winheaders.h"
#import <Foundation/NSArray.h>
#import "StaffObj.h"
#import "Staff.h"
#import <AppKit/NSButton.h>
#import <AppKit/NSPopUpButton.h>
#import "DrawingFunctions.h"

extern NSMutableArray *instlist;
extern NSMutableArray *scratchlist;
extern NSMutableArray *scrstylelist;
extern int partlistflag;
extern int instlistflag;
extern NSString *nullPart;
extern NSString *nullInstrument;

extern float noteoffset[3]; 
extern float stemleft[2][3];
extern float stemcentre[2][3];
extern float stemright[2][3];
extern float headwidth[3][NUMHEADS][10];
extern float halfwidth[3][NUMHEADS][10];

extern float beamthick[3];
extern float beamsep[3];

void muxlowInit();

void selectPopFor(NSPopUpButton *p, NSButton *b, int n);
int popSelectionFor(NSPopUpButton *popup);
NSString *popSelectionName(NSPopUpButton *b);
NSString *popSelectionNameFor(NSPopUpButton *popup);
void selectPopNameAt(NSPopUpButton *b, NSString *n);
void selectPopNameFor(NSPopUpButton *p, NSButton *b, NSString *n);

void initVotes();
int votesFor(NSFont *f, int i);
int multVotes();
NSFont *mostVotes();
BOOL findEndpoints(NSMutableArray *l, id *n0, id *n1);

/*!
  @brief Given a figure string and a line spacing, find height of figure.
 */
float figHeight(NSString *figureString, float lineSpacing);

void getRegion(NSRect *region, const NSPoint *p1, const NSPoint *p2);
void graphicBBox(NSRect *bbox, Graphic *g);
void listBBox(NSRect *bbox, NSMutableArray *list);
void graphicListBBox(NSRect *b, NSMutableArray *l);
void graphicHandListBBox(NSRect *b, NSMutableArray *l);

float tickNest(NSMutableArray *l, float t);
int tickval(int b, int d);
int noteNameNum(int i);
int noteNameNumRelC(int pos, int mc);
void getNumOct(int pos, int mc, int *num, int *oct);

int getSpacing(Staff *s);
int getLines(Staff *s);

void drawledge(float x, float y, float dx, int sz, int p, int nlines, int spacing, int mode);

void drawstem(float x, float y, int body, float sl, int sz, int btype, int stype, int dflag);
void drawgrace(float x, float y, int body, float sl, int sz, int btype, int stype, int dflag);

void drawnotedot(int sz, float x, float y, float dy, float sp, int btype, int dot, int ed, int mode);

float getdotx(int sz, int btype, int stype, int body, int beamed, int stemup);

void drawdot(int sz, float hw, float x, float y, int dbody, int btype, int stype, int ddot, int ed, int stemup, int b, int mode);

void restdot(int sz, float dx, float x, float y, float dy, int dot, int fcode, int mode);

void drawnote(int sz, float hw, float x, float y, int body, int htype, int stype, int ton, int b, float sl, int nos, int g, int dflag);

int getstemlen(int body, int sz, int style, int sl, int p, int s);

void csnote(float cx, float cy, float sl, int body, int dot, int sz, int htype, int stype, int m);
