/* $Id$ */
#import "winheaders.h"
#import "GNote.h"
#import "Staff.h"
#import "NoteHead.h"

@interface GNote(GNChord)

- (NSString *) describeChordHeads;

- normaliseChord;
- resetChord;
- reshapeChord;
- (BOOL) newHeadOnStaff: (Staff *) sp atHeight: (float) y accidental: (int) acc;
- deleteHead: (int) i;
- (BOOL) insertHead: (NoteHead *) h;
- relinkHead: (int) i;
- reverseHeads;
- resetSides;
- resetDots;
- resetStemdir: (int) i;
- resetStemlen;
- resetStemlenUsing: (int) i;
- resetAccidentals;
- drawLedgerAt: (float) dx size: (int) sz mode: (int) mode;

@end
