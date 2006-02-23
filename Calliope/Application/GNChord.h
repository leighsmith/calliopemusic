#import "winheaders.h"
#import "GNote.h"
#import "Staff.h"
#import "NoteHead.h"

@interface GNote(GNChord)

- printHeads;		/* diagnostics */

- normaliseChord;
- resetChord;
- reshapeChord;
- (BOOL) newHead: (float) y : (Staff *) sp : (int) acc;
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
- drawLedger: (float) dx : (int) sz : (int) mode;

@end
