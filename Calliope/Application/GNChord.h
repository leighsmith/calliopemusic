#import "winheaders.h"
#import "GNote.h"

@interface GNote(GNChord)

- printHeads;		/* diagnostics */

- normaliseChord;
- resetChord;
- reshapeChord;
- (BOOL) newHead: (float) y : sp : (int) acc;
- deleteHead: (int) i;
- (BOOL) insertHead: h;
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