#import "StaffTrans.h"
#import "Staff.h"
#import "mux.h"
#import "GNote.h"
#import "GNChord.h"
#import "NoteHead.h"
#import "Clef.h"
#import "KeySig.h"
#import "System.h"
#import <Foundation/NSArray.h>


@implementation Staff(StaffTrans)

/*
  given a note name n, nthdeg[][n] tells the order in which this name
  is added to a keysig.  nthdeg[0] for flats, [1] for sharps.
*/

static char nthdeg[2][7] =
{
  {6, 4, 2, 7, 5, 3, 1},
  {2, 4, 6, 1, 3, 5, 7}
};

/*
  Given the keysigns for the old and new degrees of the staff,
  return a code number that will index into chooseacc.
  A -1 means no change.
*/

static char oldnew[3][3] =
{
  { -1, 0, 1},
  { 2, -1, 3},
  { 4, 5, -1},
};

/*
  Given the old accidental a and an old/new degree code index,
  chooseacc[a][on] gives a code for updating the accidental
*/

static char chooseacc[5][6] =
{
  { 4, 3, 3, 2, 0, 0},
  { 3, 5, 0, 0, 3, 1},
  { 1, 2, 2, 5, 1, 4},
  { 0, 0, 1, 3, 0, 0},
  { 0, 0, 0, 0, 2, 3}
};

/*
  Given keynumber + 7, posoff[] is the relative offset from C Maj
*/

static char posoff[15] =
{
  0, 4, 1, 5, 2, 6, 3, 0, 4, 1, 5, 2, 6, 3, 0
};

/* transpose according to a change in key signature */


extern int noteNameNum(int i);

- transKey: n : (int) okn : (int) nkn : (int) oct
{
  Clef *r;
  GNote *q;
  NSMutableArray *hl;
  NoteHead *h;
  short hk, off, mc, oks, nks, osd[7], nsd[7], j, k, acc, pos, a, b;
  BOOL f = NO;
  off = oct + posoff[okn + 7] - posoff[nkn + 7];
  r = [self findClef: n];
  mc = [r middleC];
  if (okn < 0) { oks = 0; okn = -okn; } else oks = 1;
  if (nkn < 0) { nks = 0; nkn = -nkn; } else nks = 1;
  for (j = 0; j < 7; j++)
  {
    osd[j] = (okn && nthdeg[oks][j] <= okn) ? oks + 1 : 0;
    nsd[j] = (nkn && nthdeg[nks][j] <= nkn) ? nks + 1 : 0;
  }
  j = [notes indexOfObject:n] + 1;
  k = [notes count];
  while (!f && j < k)
  {
    q = [notes objectAtIndex:j];
    if (TYPEOF(q) == KEY) f = YES;
    else if (TYPEOF(q) == NOTE)
    {
      hl = q->headlist;
      hk = [hl count];
      while (hk--)
      {
        h = [hl objectAtIndex:hk];
        if (acc = h->accidental)
        {
          pos = h->pos;
 	  a = oldnew[osd[noteNameNum(mc - pos)]][nsd[noteNameNum(mc - (pos + off))]];
	  if (a != -1)
	  {
	    if (b = chooseacc[acc - 1][a]) h->accidental = b;
	  }
        }
        if (off)
        {
          h->pos += off;
          h->myY = [self yOfPos: h->pos];
	}
      }
      [q resetChord];
    }
    ++j;
  }
  [self resizeNotes: 0];
  [[self measureStaff] resetStaff: y];
  return self;
}


/* transpose according to a change in clef */

- transClef: n : (int) off
{
  GNote *q;
  NSMutableArray *hl;
  NoteHead *h;
  int j, k, hk;
  BOOL f = NO;
  k = [notes count];
  j = [notes indexOfObject:n] + 1;
  while (!f && j < k)
  {
    q = [notes objectAtIndex:j];
    if (TYPEOF(q) == CLEF) f = YES;
    else if (TYPEOF(q) == NOTE)
    {
      hl = q->headlist;
      hk = [hl count];
      while (hk--)
      {
        h = [hl objectAtIndex:hk];
        h->pos += off;
        h->myY = [self yOfPos: h->pos];
      }
      [q resetChord];
    }
    ++j;
  }
  [self resizeNotes: 0];
  [[self measureStaff] resetStaff: y];
  return self;
}

@end
