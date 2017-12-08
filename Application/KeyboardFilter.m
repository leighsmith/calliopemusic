
/*
  A very simple MKNoteFilter that ambushes whatever the user types.
  Enharmonic naming of pitches is done here also.
*/

#import "KeyboardFilter.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVPerform.h"
#import "GVSelection.h"
#import "GVFormat.h"
#import "GVCommands.h"
#import "PlayInspector.h"
#import "Clef.h"
#import "KeySig.h"
#import "Staff.h"
#import "System.h"
#import "GNote.h"
#import "GNChord.h"
#import "NoteHead.h"
#import "DrawingFunctions.h"

#import <Foundation/NSArray.h>

@implementation KeyboardFilter : MKNoteFilter

extern id lastHit;

static GNote *cbase, *pencil[128];

- init
{
   [super init]; 
   [self addNoteReceiver:[[MKNoteReceiver alloc] init]];
   [self addNoteSender:[[MKNoteSender alloc] init]];
   return self;
 }


/* choice selects an enharmonic spelling */

/* poff[choice][cardinal] gives -offset from mc for cardinal */

char poff[2][12] =
{
  { -1, 0, 1, 1, 2, 2, 3, 4, 4, 5, 5, 6},
  {  0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6, 7}
};

/* accn[choice][cardinal] gives accidental code for cardinal */

char accn[2][12] =
{
  { 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 2, 0},
  { 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1}
};


static float ticksincode[10] =
{
  1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0, 128.0, 256.0, 512.0
};

int noteFromTicks(float t)
{
  int i;
  float x;
  if (t < 0.75) return 1;
  for (i = 0; i < 10; i++)
  {
    x = ticksincode[i];
    if (0.75 * x <= t && t <= 1.75 * x) return i;
  }
  return 9;
}


int dotsFromTicks(float t, int i)
{
  float x = ticksincode[i];
  return (1.25 * x <= t && t <= 1.75 * x);
}


/*
  given a note name n, nthdeg[k][n] tells the order in which this name
  is added to a keysig. k is an accidental code.
*/

static char nthdeg[6][7] =
{
  {0, 0, 0, 0, 0, 0, 0},
  {6, 4, 2, 7, 5, 3, 1},
  {2, 4, 6, 1, 3, 5, 7},
  {0, 0, 0, 0, 0, 0, 0},
  {8, 8, 8, 8, 8, 8, 8},
  {8, 8, 8, 8, 8, 8, 8}
};

static int midiOct(int n)
{
  return 7 * ((n / 12) - 5);
}


extern int noteNameNum(int i);

/* skey is key of note's staff degree, nacc is note's accidental */

void posOfNote(int mc, char *ks, int n, int *pos, int *acc)
{
  int i, d, card, nnam0, nnam1, skey0, skey1, nacc0, nacc1;
  char nks[7];
  card = n % 12;
  for (i = 0; i < 7; i++) nks[i] = (ks[i] == 3) ? 0 : ks[i]; /* neutralise naturals */
  /* find an enharmonic spelling that matches the current keysig/accidentals */
  nnam0 = noteNameNum(poff[0][card]);
  skey0 = nks[nnam0];
  nacc0 = accn[0][card];
  nnam1 = noteNameNum(poff[1][card]);
  skey1 = nks[nnam1];
  nacc1 = accn[1][card];
  if (skey0 == nacc0)
  {
    *pos = mc - nnam0 - midiOct(n);
    *acc = 0;
    return;
  }
  if (skey1 == nacc1)
  {
    *pos = mc - nnam1 - midiOct(n);
    *acc = 0;
    return;
  }
  /* or find the one that naturalises the keysig */
  if (skey0 && !nacc0)
  {
    *pos = mc - nnam0 - midiOct(n);
    *acc = 3;
    ks[nnam0] = 3;
    return;
  }
  if (skey1 && !nacc1)
  {
    *pos = mc - nnam1 - midiOct(n);
    *acc = 3;
    ks[nnam1] = 3;
    return;
  }
  /* or find the one whose accidental is added first */
  d = nthdeg[nacc0][nnam0] - nthdeg[nacc1][nnam1];
  if (d < 0)
  {
    *pos = mc - nnam0 - midiOct(n);
    *acc = nacc0;
    ks[nnam0] = nacc0;
    return;
  }
  if (d > 0)
  {
    *pos = mc - nnam1 - midiOct(n);
    *acc = nacc1;
    ks[nnam1] = nacc1;
    return;
  }
  else  /* this is the horrible ambiguous case */
  {
    *pos = mc - nnam0 - midiOct(n);
    *acc = nacc0;
    ks[nnam0] = nacc0;
    return;
  }
}


static void setAccidental(GNote *p, int a)
{
    NoteHead *h;
    if (![p numberOfNoteHeads]) 
	return;
    h = [p noteHead: 0];
    [h setAccidental: a];
}


extern void setkeysig(KeySig *p, char *key);

- realizeNote: n fromNoteReceiver: r
{
  int i, c, mc, pos, acc, tb, td;
  char ks[7];
  float mm, t, dur;
  GraphicView *v = nil;
  TimedObj *p;
  GNote *q;
  NSPoint pt;
  Staff *sp;
  OpusDocument *doc = [CalliopeAppController currentDocument];
  PlayInspector *player = [[CalliopeAppController sharedApplicationController] thePlayInspector];
  
  if (doc) v = [doc graphicView]; else return self;
  i = [n noteTag] & 127;
  if (i < 0 || i > 127) return self;
  if (![player getFeedback]) [[self noteSender] sendNote: n];
  switch([n noteType])
  {
    case MK_noteOn:
      if (v && [[v selectedGraphics] count])
      {
        if (cbase && ([n timeTag] - cbase->stamp < 0.1))
	{
	  q = cbase;
	  sp = [q staff];
	  mc = [sp getKeyThru: q : ks];
	  posOfNote(mc, ks, [n keyNum], &pos, &acc);
	  [q newHeadOnStaff: sp atHeight: [sp yOfStaffPosition: pos] accidental: acc];
	  [v reShapeAndRedraw: q];
	}
	else
	{
	  [v getInsertionX: &(pt.x) : &sp : &p : &tb : &td];
	  mc = [sp getKeyThru: p : ks];
	  posOfNote(mc, ks, [n keyNum], &pos, &acc);
	  pt.y = [sp yOfStaffPosition: pos];
	  q = [[[GNote alloc] init] autorelease];
	  [q proto: v : pt : sp : [sp mySystem] : nil : 5];
	  if (acc) setAccidental(q, acc);
          [sp linknote: q];
	  q->time.body = tb;
	  [q setDottingCode: td];
	  q->stamp = [n timeTag];
	  pencil[i] = q;
	  lastHit = q;
	  cbase = q;
	  [q reShape];
          [v dirty];
          [v deselectAll: v];
          [v selectObj: q];
          [v drawSelectionWith: NULL];
	}
      }
      else NSLog(@"realizeNote: v empty");
      break;
    case MK_noteOff:
      q = pencil[i];
      if (q != nil)
      {
        pencil[i] = nil;
	if ([player getRecordType] == 0)
	{
          mm = [player getTempo];
          dur = [n timeTag] - q->stamp;
          t = MINIMTICK * (mm / 60.0) * dur;
          c = noteFromTicks(t);
	  q->time.body = c;
	  [q setDottingCode: dotsFromTicks(t, c)];
	}
	lastHit = q;
	if (q == cbase) cbase = nil;
        [v reShapeAndRedraw: q];
      }
      break;
    case MK_noteDur:
    case MK_noteUpdate:
    case MK_mute:
      break;
  }
  return self;
}

@end

