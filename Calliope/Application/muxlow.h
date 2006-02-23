/* global graphics/timing routines */

#import "winheaders.h"
#import <Foundation/NSArray.h>
#import "StaffObj.h"
#import "Staff.h"
#import <AppKit/NSButton.h>
#import <AppKit/NSPopUpButton.h>
#import "mux.h"

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
extern void selectPopFor(NSPopUpButton *p, NSButton *b, int n);
extern int popSelectionFor(NSPopUpButton *popup);
extern NSString *popSelectionName(NSPopUpButton *b);
extern NSString *popSelectionNameFor(NSPopUpButton *popup);
extern void selectPopNameAt(NSPopUpButton *b, NSString *n);
extern void selectPopNameFor(NSPopUpButton *p, NSButton *b, NSString *n);

extern void initVotes();
extern int votesFor(NSFont *f, int i);
extern int multVotes();
extern NSFont *mostVotes();
extern BOOL findEndpoints(NSMutableArray *l, id *n0, id *n1);
extern float figHeight(unsigned char *s, float n);

extern void getRegion(NSRect *region, const NSPoint *p1, const NSPoint *p2);
extern void graphicBBox(NSRect *bbox, Graphic *g);
extern void listBBox(NSRect *bbox, NSMutableArray *list);
extern void graphicListBBox(NSRect *b, NSMutableArray *l);
extern void graphicHandListBBox(NSRect *b, NSMutableArray *l);

extern float tickNest(NSMutableArray *l, float t);
extern int tickval(int b, int d);
extern int noteNameNum(int i);
extern int noteNameNumRelC(int pos, int mc);
extern void getNumOct(int pos, int mc, int *num, int *oct);

extern int getSpacing(Staff *s);
extern int getLines(Staff *s);

extern void drawledge(float x, float y, float dx, int sz, int p, int nlines, int spacing, int mode);

extern void drawstem(float x, float y, int body, float sl, int sz, int btype, int stype, int dflag);
extern void drawgrace(float x, float y, int body, float sl, int sz, int btype, int stype, int dflag);

extern void drawnotedot(int sz, float x, float y, float dy, float sp, int btype, int dot, int ed, int mode);

extern float getdotx(int sz, int btype, int stype, int body, int beamed, int stemup);

extern void drawdot(int sz, float hw, float x, float y, int dbody, int btype, int stype, int ddot, int ed, int stemup, int b, int mode);

extern void restdot(int sz, float dx, float x, float y, float dy, int dot, int fcode, int mode);

extern void drawnote(int sz, float hw, float x, float y, int body, int htype, int stype, int ton, int b, float sl, int nos, int g, int dflag);

extern int getstemlen(int body, int sz, int style, int sl, int p, int s);

extern void csnote(float cx, float cy, float sl, int body, int dot, int sz, int htype, int stype, int m);
