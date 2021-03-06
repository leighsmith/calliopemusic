/* $Id$ */
#import "TuningView.h"
#import "Course.h"
#import "DrawingFunctions.h"
#import "muxlow.h"


@implementation TuningView

extern void posOfNote(int mc, char *ks, int n, int *pos, int *acc);


static unsigned char accidents[6] =
{
    SF_natural, SF_flat, SF_sharp, SF_natural, SF_dbflat, SF_dbsharp
};


- init: p
{
    myTuner = p;
    dragging = -1;
    lastsel = -1;
    [self setNeedsDisplay:YES];
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}


- (BOOL)becomeFirstResponder
{
//#error EventConversion: addToEventMask:NX_MOUSEMOVEDMASK: is obsolete; you no longer need to use the eventMask methods; for mouse moved events, see 'setAcceptsMouseMovedEvents:'
//  [window addToEventMask:NSMouseMovedMask];
    /*sb: removed above line. I don't know whether or not it is necessary. FIXME */
    return YES;
}


#define NAT 3
#define GAP 4
#define XOFF (8*NAT)
#define SIGOFF (3*NAT)
#define LOFF NAT
#define CAPTIONBASE 20

- drawNote: (int) p : (int) a : (float) x : (int) i
{
    int j;
    float dy, my, lw, nx;
    unsigned char ch;
    NSFont *f = musicFont[1][1];
    
    my = 0.5 * [self bounds].size.height;
    lw = charFGW(f, 'w') + 2 * LOFF;
    if (p == 0) 
	dy = 0.0;
    else if (p < 0)
	dy = p * NAT - GAP;
    else 
	dy = p * NAT + GAP;
    nx = x + i * XOFF - 0.5 * charFGW(f, 'w');
    // TODO draw mode needs correcting, currently kludged.
    DrawCharacterInFont(nx, my + dy, 'w', f, 1 /* bogus! */);
    
    /* then ledger lines */
    if (p == 0) {
	NSRectFill(NSMakeRect(nx - LOFF, my + dy, lw, 0.5));
    }
    else if (p >= 12) {
	for (j = 12; j <= p; j += 2) 
	    NSRectFill(NSMakeRect(nx - LOFF, my + (j * NAT + GAP), lw, 0.5));
    }
    else if (p <= -12) {
	for (j = -12; j >= p; j -= 2) 
	    NSRectFill(NSMakeRect(nx - LOFF, my + (j * NAT - GAP), lw, 0.5));
    }
    /* then accidental */
    if (a) {
	DrawCharacterInFont(nx - charFGW(f, ch) - (0.5 * NAT), my + dy, accidents[a], f, 1 /* bogus! */);
    }
    return self;
}


- (BOOL) acceptsFirstMouse: (NSEvent *) theEvent
{
    return YES;
}

static char semitones[7] = {0, 2, 4, 5, 7, 9, 11};

- (void) mouseDown: (NSEvent *) e 
{
    int i=0, k, p, acc, np, no, s; //sb: initted i
    float x, y, dx, my, dy;
    Course *c;
    NSMutableArray *l;
    NSPoint pt;
    char nks[7];
//#error EventConversion: addToEventMask:NX_MOUSEDRAGGEDMASK: is obsolete; you no longer need to use the eventMask methods; for mouse moved events, see 'setAcceptsMouseMovedEvents:'
//  [window addToEventMask:NSLeftMouseDraggedMask];
    pt = [e locationInWindow];
    pt = [self convertPoint:pt fromView:nil];
    my = 0.5 * [self bounds].size.height;
    x = XOFF + SIGOFF;
    if ([myTuner isTablature])
    {
	l = [myTuner selectedList];
	if (l != nil)
	{
	    k = [l count];
	    for (i = 0; i < k; i++)
	    {
		dx = pt.x - (x + i * XOFF);
		if (dx < 0) dx = -dx;
		if (dx < 4)
		{
		    c = [l objectAtIndex:i];
		    p = -(c->pitch) - (7 * (c->oct - 4));
		    if (p == 0) y = 0.0;
		    else if (p < 0) y = p * NAT - GAP;
		    else y = p * NAT + GAP;
		    y += my;
		    dy = pt.y - y;
		    if (dy < 4)
		    {
			dragging = i;
			lastsel = i;
			curp = p;
			[self display];
			return;
		    }
		}
	    }
	}
    }
    else
    {
	dx = pt.x - (x + 5 * XOFF);
	if (dx < 0) dx = -dx;
	if (dx < 4)
	{
	    for (s = 0; s < 7; s++) nks[s] = 0;
	    posOfNote(0, nks, 60 + [myTuner transposition], &p, &acc);
	    if (p == 0) y = 0.0;
	    else if (p < 0) y = p * NAT - GAP;
	    else y = p * NAT + GAP;
	    y += my;
	    dy = pt.y - y;
	    if (dy < 4)
	    {
		dragging = i;
		lastsel = 1;
		curp = p;
		getNumOct(p, 0, &np, &no);
		[myTuner setSelectedTrans: semitones[np] + (no - 4) * 12];
		[self display];
	    }
	}
    }
}


- (void)mouseDragged:(NSEvent *)e 
{
    NSPoint pt;
    int p, np, no;
    float y;
    NSMutableArray *l;
    Course *c;
    float my = 0.5 * [self bounds].size.height;
    if (dragging < 0) return;
    pt = [e locationInWindow];
    pt = [self convertPoint:pt fromView:nil];
    y = pt.y;
    if (y < my - GAP) y += GAP;
    else if (y > my + GAP) y -= GAP;
    p = (y - my) / NAT;
    if (p == curp) return;
    getNumOct(p, 0, &np, &no);
    if ([myTuner isTablature])
    {
	l = [myTuner selectedList];
	if (l != nil)
	{
	    c = [l objectAtIndex:dragging];
	    c->pitch = np;
	    c->oct = no;
	    curp = p;
	}
    }
    else
    {
	[myTuner setSelectedTrans: semitones[np] + (no - 4) * 12];
    }
    [self display];
}


- (void)mouseUp:(NSEvent *)e 
{
//#error EventConversion: removeFromEventMask:NX_MOUSEDRAGGEDMASK: is obsolete; you no longer need to use the eventMask methods; for mouse moved events, see 'setAcceptsMouseMovedEvents:'
//  [window removeFromEventMask:NSLeftMouseDraggedMask];
    /* need to update the tab table */ 
    dragging = -1;
}


static char accalter[3] = {0, -1, 1};

- hitAcc: sender
{
    int a = [sender selectedColumn];
    NSMutableArray *l;
    Course *c;
    if (lastsel < 0) return self;
    if ([myTuner isTablature])
    {
	l = [myTuner selectedList];
	if (l == nil) return nil;
	if (lastsel >= [l count]) return nil;
	c = [l objectAtIndex:lastsel];
	if (c == nil) return nil;
	c->acc = (c->acc == a) ? 0 : a;
    }
    else
    {
	[myTuner setSelectedTrans: [myTuner transposition] + accalter[a]];
    }
    [self setNeedsDisplay:YES];
    return self;
}


#define grayval(_x) ((_x))

- (void) drawRect: (NSRect) r
{
    int i, k, pos, acc, s;
    char nks[7];
    NSMutableArray *l;
    Course *c;
    float x = [self bounds].origin.x, y = [self bounds].origin.y, w = [self bounds].size.width, h = [self bounds].size.height;
    float my = 0.5 * h, sd;
    NSFont *systemFont = [NSFont systemFontOfSize: 10.0];
    NSFont *f = musicFont[1][1];
    
    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(x, y, w, h));
    // PSgsave();
    [[NSColor blackColor] set];

    /* staff lines */
    for (i = 1; i <= 5; i++) {
	sd = i * (2 * NAT);
	NSRectFill(NSMakeRect(x, my + GAP + sd, w, 0.5));
	NSRectFill(NSMakeRect(x, my - GAP - sd, w, 0.5));
    }
    /* clefs */
    DrawCharacterInFont(x + NAT, my - GAP - (2 * NAT), '&', f, 1 /* bogus! */);
    DrawCharacterInFont(x + NAT, my + GAP + (10 * NAT), '?', f, 1 /* bogus! */);

    /* notes */
    x = XOFF + SIGOFF;
    if ([myTuner isTablature])
    {
	l = [myTuner selectedList];
	if (l != nil)
	{
	    k = [l count];
	    for (i = 0; i < k; i++)
	    {
		c = [l objectAtIndex:i];
		if(i == lastsel) // set color to gray value from 0 (black) to 1 (white)
		    [[NSColor darkGrayColor] set];
		else 
		    [[NSColor blackColor] set]; 
		[self drawNote: -(c->pitch) - (7 * (c->oct - 4)) : c->acc : x : i];
	    }
	    for (i = 0; i < k; i++) {
		DrawTextWithBaselineTies(x + i * XOFF, CAPTIONBASE, [NSString stringWithFormat: @"%d", i + 1], systemFont, 1 /* bogus! */);
	    }
	}
    }
    else
    {
	k = [myTuner transposition];
	[self drawNote: 0 : 0 : x : 2];
	for (s = 0; s < 7; s++) 
	    nks[s] = 0;
	posOfNote(0, nks, 60 + k, &pos, &acc);
	[self drawNote: pos : acc : x : 5];
	DrawTextWithBaselineTies(x + 1 * XOFF, CAPTIONBASE, @"Written", systemFont, 1 /* bogus! */);
	DrawTextWithBaselineTies(x + 4 * XOFF, CAPTIONBASE, @"Sounds", systemFont, 1 /* bogus! */);
    }
    // PSgrestore();
}


- preset
{
    BOOL b = [myTuner isTablature];
    [addbutton setEnabled:b];
    [removebutton setEnabled:b];
    if (b)
    {
	[[accmatrix cellAtRow:0 column:1] setImage:[NSImage imageNamed:@"ks1f"]];
	[[accmatrix cellAtRow:0 column:2] setImage:[NSImage imageNamed:@"ks1s"]];
    }
    else
    {
	[[accmatrix cellAtRow:0 column:1] setImage:[NSImage imageNamed:@"arrowdn"]];
	[[accmatrix cellAtRow:0 column:2] setImage:[NSImage imageNamed:@"arrowup"]];
    }
    [self setNeedsDisplay:YES];
    return self;
}


- addCourse: sender
{
    NSMutableArray *l;
    if (![myTuner isTablature])
    {
	NSLog(@"TuningView -addCourse: myTuner is not tablature");
	return self;
    }
    l = [myTuner selectedList];
    if (lastsel == -1 || lastsel >= [l count]) lastsel = [l count];
    [l insertObject:[[Course alloc] init: 0 : 0 : 4] atIndex:lastsel];
    [self setNeedsDisplay:YES];
    return self;
}


- removeCourse: sender
{
    NSMutableArray *l;
    if (![myTuner isTablature] || lastsel == -1)
    {
	NSLog(@"TuningView -removeCourse: myTuner is not tablature");
	return self;
    }
    l = [myTuner selectedList];
    if (lastsel >= [l count])
    {
	NSLog(@"TuningView -removeCourse: lastsel >= selected count");
	return self;
    }
    [l removeObjectAtIndex:lastsel];
    lastsel = -1;
    [self setNeedsDisplay:YES];
    return self;
}


@end
