#import "KeyInspector.h"
#import "KeySig.h"
#import "DrawApp.h"
#import "StaffTrans.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVSelection.h"
#import <AppKit/AppKit.h>
#import "DrawingFunctions.h"

@implementation KeyInspector

extern int keySymCount(char *s);
extern int keySymValue(char *s);
extern BOOL isConventional(char *s);
extern char symorder[2][7];

NSImage *keyimages[4];


+ (void)initialize
{
  if (self == [KeyInspector class])
  {
    keyimages[0] = nil;
    keyimages[1] = [[NSImage imageNamed:@"ks1f"] retain];
    keyimages[2] = [[NSImage imageNamed:@"ks1s"] retain];
  }
  return;
}


/*
  prevents creation of 0-symbol sig
*/

- setClient: (KeySig *) p
{
  int i, k, n, t;
  n = 0;
  for (i = 0; i < 7; i++)
  {
    t = [[signmatrix cellAtRow:0 column:i] tag];
    p->keystr[i] = t;
    n += t;
    k = [[octavematrix cellAtRow:0 column:i] state];
    if (k) p->keystr[i] |= 4;
  }
  if (n == 0)
  {
    p->gFlags.subtype = 3;
    p->keystr[6] = 1;
  }
  else p->gFlags.subtype = [styleswitch selectedColumn];
  return self;
}


- setProto: sender
{
  return [self setClient: [KeySig myPrototype]];
}


- set:sender
{
  int i, j, k;
  NSRect b, tb;
  KeySig *p;
  id sl, v = [DrawApp currentView];
  int sk, okn=0;
  BOOL dotrans;
  if ([v startInspection: KEY : &b : &sl])
  {
    sk = [sl count];
    while (sk--) if ((p = [sl objectAtIndex:sk]) && TYPEOF(p) == KEY)
    {
      dotrans = ([transswitch state] && (TYPEOF(p->mystaff) == STAFF));
      if (dotrans)
      {
        tb = p->bounds;
        [p transBounds: &tb : KEY];
	okn = [p oldKeyNum];
	if (p->gFlags.subtype == 3) okn = 0;
      }
      [self setClient: p];
      [p recalc];
      if (dotrans)
      {
	if (p->gFlags.subtype == 3) i = 0;
	else i = [p oldKeyNum];
        k = [octavebutton indexOfItemWithTitle:[octavebutton title]];
	j = 0;
	if (k == 1) j = -7; else if (k == 2) j = 7;
        [p->mystaff transKey: p : okn : i : j];
        b  = NSUnionRect(tb , b);
      }
    }
    [v endInspection: &b];
  }
  return self;
}


/* called when panel is opened.  Load values from inspector */


- updatePanel: (KeySig *) p
{
  int i, j;
  NSButton *b;
  [styleswitch selectCellAtRow:0 column:p->gFlags.subtype];
  for (i = 0; i < 7; i++)
  {
    j = p->keystr[i];
    b = [signmatrix cellAtRow:0 column:i];
    [b setTag:j & 03];
    [b setImage:keyimages[j & 03]];
    [octavematrix setState:(j & 4) atRow:0 column:i];
  }
  if (isConventional(p->keystr))
  {
    [nummatrix selectCellAtRow:[p myKeySymbol] - 1 column:[p myKeyNumber] - 1];
  }
  else
  {
    clearMatrix(nummatrix);
  }
  [octavebutton selectItemAtIndex: 0];
  return self;
}


- preset
{
  int n;
  GraphicView *v = [DrawApp currentView];
  KeySig *p = [v canInspect: KEY : &n];
  if (n == 0) return nil;
  [self updatePanel: p];
  return self;
}


- presetTo: (int) i
{
  return [self updatePanel: [KeySig myPrototype]];
}


/*
  make a conventional choice, then reflect in the custom matrix
*/

- setConvChoice: sender
{
  NSButton *b;
  char keystr[7];
  int ord = [nummatrix selectedRow];
  int i = ord + 1;
  int j = [nummatrix selectedColumn] + 1;
  int k;
  for (k = 0; k < 7; k++) keystr[k] = 0;
  for (k = 0; k < j; k++) keystr[(int)symorder[ord][k]] = i;
  for (k = 0; k < 7; k++)
  {
    b = [signmatrix cellAtRow:0 column:k];
    [b setTag:keystr[k]];
    [b setImage:keyimages[(int)keystr[k]]];
  }
  return self;
}


/*
  make a custom choice, then reflect it in the conventional matrix
*/

- setCustChoice: sender
{
  int i;
  char choice[7];
  NSButton *b = [signmatrix selectedCell];
  int n = ([b tag] + 1) % 3;
  [b setTag:n];
  [b setImage:keyimages[n]];
  for (i = 0; i < 7; i++) choice[i] = [[signmatrix cellAtRow:0 column:i] tag];
  if (isConventional(choice))
  {
    [nummatrix selectCellAtRow:keySymValue(choice) - 1 column:keySymCount(choice) - 1];
  }
  else
  {
    clearMatrix(nummatrix);
  }
  return self;
}


@end
