/* 
  Routines for performing using the MusicKit.
*/

#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVPerform.h"
#import "Staff.h"
#import "StaffObj.h"
#import "System.h"
#import "SysAdjust.h"
#import "NoteHead.h"
#import "GNote.h"
#import "Tablature.h"
#import "NeumeNew.h"
#import "SquareNote.h"
#import "Clef.h"
#import "KeySig.h"
#import "Accent.h"
#import "Beam.h"
#import "Tuple.h"
#import "Page.h"
#import "Rest.h"
#import "TimeSig.h"
#import "Verse.h"
#import "Metro.h"
#import "KeyboardFilter.h"
#import "PlayInspector.h"
#import "UserInstrument.h"
#import "CallInst.h"
#import "Channel.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import <MusicKit/MusicKit.h>

#import <AppKit/AppKit.h>

@implementation GraphicView(GVPerform)


extern int playmode;
extern float notefreq[7];
extern float chromalter[8];
extern int power2[12];
extern NSString *nullProgChange;

struct inst
{
  NSString *name; /* not used at present */
  NSString *patch;
  NSString *waveform;
  char envelope; /* vox, bow, pluck */
  double svibAmp, svibFreq, amp, bright;
} instruments[8] =
{
  {@"piano", @"DBWave1v", @"PN", 4, 0.0, 1, 0.7, 0.5},
  {@"8' flute", @"DBWave1v", @"SU", 0, 0.0074, 5.3, 0.9, 0.0},
  {@"gut string", @"DBWave1v", @"VNA" /* "VCA" */, 2, 0.0, 1, 0.7, 0.01},
  {@"wire string", @"DBWave1v", @"TR", 3, 0.0, 1, 0.7, 0.9},
  {@"violin", @"DBWave1v", @"VNA", 1, 0.0033, 5.2, 0.7, 0.7},
  {@"viola", @"DBWave1v", @"VNA", 1, 0.0032, 5.1, 0.7, 0.1},
  {@"cello", @"DBWave1v", @"VCA", 1, 0.0031, 5.0, 0.7, 0.1},
  {@"soprano", @"DBWave1v", @"SA", 0, 0.0073, 5.3, 0.9, 0.0}
};

int numParts;
struct performer player[NUMPARTPERFORM];
MKOrchestra *anOrch;
MKMidi *midi;
KeyboardFilter *kf;



/* for internal orch, the number of a G-MIDI instrument is mapped onto a local instrument */

char myinst[128] = 
{
  0, 0, 0, 0, 0, 0, 3, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  1, 1, 1, 1, 1, 1, 1, 1,
  2, 2, 2, 2, 2, 2, 2, 2,
  2, 2, 2, 2, 2, 2, 2, 2,
  4, 5, 6, 6, 6, 6, 2, 2,
  6, 6, 6, 6, 7, 7, 7, 7,
  4, 4, 4, 4, 4, 4, 4, 4,
  4, 4, 4, 4, 4, 4, 4, 4,
  1, 1, 1, 1, 1, 1, 1, 1,
  4, 4, 4, 4, 4, 4, 4, 4,
  4, 4, 4, 4, 4, 4, 4, 4,
  4, 4, 4, 4, 4, 4, 4, 4,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0
};

/* envelopes: 0=vox, 1=bow, 2=gut, 3=wire, 4=piano */

#define NUMENV 5
#define NUMPTS 6

/* static */ MKEnvelope *envelopes[NUMENV];

static double envxys[2 * NUMENV][NUMPTS] =
{
  {0.0, 0.1,  0.5, 1.0, 0.0, 0.0},  /* vox x */
  {0.0, 1.0,  0.5, 0.0, 0.0, 0.0},  /* vox y */
  {0.0, 0.05, 0.5, 1.0, 0.0, 0.0},  /* bow x */
  {0.0, 1.0,  0.5, 0.0, 0.0, 0.0},  /* bow y */
  {0.0, 0.05, 0.5, 2.0, 0.0, 0.0},  /* gut x */
  {0.0, 1.0,  0.3, 0.0, 0.0, 0.0},  /* gut y */
  {0.0, 0.2,  0.5, 2.0, 0.0, 0.0},  /* wire x */
  {1.0, 0.5,  0.3, 0.0, 0.0, 0.0},  /* wire y */
  {0.0, 0.05, 0.2, 0.5, 8.0, 8.15},  /* piano x */
  {0.0, 1.0,  0.5, 0.3, 0.0, 0.0},  /* piano y */
};

static char envelpts[NUMENV] = {4, 4, 4, 4, 6};
static char stickpts[NUMENV] = {2, 2, 3, 3, 4};

void initPlayTables()
{
    MKEnvelope *e;
    int i, r;
    r = 0;
    for (i = 0; i < NUMENV; i++)
    {
	e = [[MKEnvelope alloc] init];
	[e setPointCount: envelpts[i] xArray: envxys[r] yArray: envxys[r + 1]];
	r += 2;
	[e setStickPoint: stickpts[i]];
	envelopes[i] = e;
    }
    for (i = 0; i < NUMPARTPERFORM; i++)
    {
	player[i].part = nil;
	player[i].performer = nil;
    }
}


static float transpose(float f, int s)
{
    int i;
    
    if (s < 0)
    {
	s = -s;
	for (i = 0; i < s; i++) f *= chromalter[1];
    }
    else if (s > 0)
    {
	for (i = 0; i < s; i++) f *= chromalter[2];
    }
    return f;
}

/* account for accidental, sticking hanger accidental, nonsticking, ottava */
static float getNoteFreq(id p, int pos, int acc, int mc, char *acctable, int trn)
{
    int num, oct;
    float f;
    getNumOct(pos, mc, &num, &oct);
    f = notefreq[num] * power2[oct];
    if (acc)
    {
	f *= chromalter[acc];
	acctable[num] = acc;
    }
    else if (acc = [p hangerAcc])
    {
	f *= chromalter[acc];
	if ([p hangerAccSticks]) acctable[num] = acc;
    }
    else f *= chromalter[(int)acctable[num]];
    if (acc = [p hangerOtt]) f *= chromalter[acc];
    if (trn) f = transpose(f, trn);
    return f;
}


/* return frequency for tablature note for instrument i on course c, fret f */
static float getTabFreq(Tablature *p, NSString *n, int c, int fret)
{
    Course *cp;
    float f;
    cp = [[instlist tuningForInstrument: n] objectAtIndex:c];
    if (cp == nil) return 0.0;
    f = notefreq[(int)cp->pitch] * power2[(int)cp->oct] * chromalter[(int)cp->acc];
    if (fret) f = transpose(f, fret);
    return f;
}


void setInst(MKNote *n, int i)
{
    int mi;
    switch(playmode)
    {
	case 0:
	case 1:
	    mi = myinst[i];
	    [n setPar: MK_ampEnv toEnvelope: envelopes[(int)instruments[mi].envelope]];
	    [n setPar: MK_waveform toString: instruments[mi].waveform];
	    [n setPar: MK_svibFreq toDouble: instruments[mi].svibFreq];
	    [n setPar: MK_svibAmp toDouble: instruments[mi].svibAmp];
	    [n setPar: MK_amp toDouble: instruments[mi].amp];
	    if (instruments[mi].bright > 0) 
		[n setPar: MK_bright toDouble: instruments[mi].bright];
	    break;
	case 2:
	case 3:
	case 4:
	    [n setPar: MK_programChange toInt: i];
	    break;
    }
}


static MKNote *newNote(float tn, float f, float dur)
{
    MKNote *p = [[MKNote alloc] initWithTimeTag: (double) tn];
    
    // NSLog(@"added note freq %f at %f lasting %f\n", f, tn, dur);
    [p setNoteType: MK_noteDur];
    [p setPar: MK_freq toDouble: (double) f];
    [p setDur: (double) dur];
    return p;
}


/*
 add a note to the part determined by <voice, notehead, channel>, creating
 a new part if necessary.  Reserve player[0] for the user interface.
 */
static void addNote(int v, int k, int ch, MKNote *n)
{
    struct performer *p;
    int i, j = numParts;
    for (i = 1; i < j; i++)
    {
	p = &(player[i]);
	if (p->thread == v && p->notehead == k && p->channel == ch)
	{
	    [p->part addNote: n];
	    return;
	}
    }
    p = &(player[numParts]);
    p->thread = v;
    p->notehead = k;
    p->channel = ch;
    p->part = [[MKPart alloc] init];
    [p->part addNote: n];
    numParts++;
}


- deactivatePlayers
{
    int i;
    for (i = 0; i < numParts; i++)
	if ([player[i].performer status] != MK_inactive) [player[i].performer deactivate];
    return self;
}


- pausePlayers
{
    int i;
    for (i = 0; i < numParts; i++) [player[i].performer pause];
    return self;
}


- resumePlayers
{
    int i;
    for (i = 0; i < numParts; i++) [player[i].performer resume];
    return self;
}

// TODO This should be factored into using GVScore's 
// [self scoreBetweenSystem: sj andSystem: sk onlySelectedGraphics: selonly];
// then wiring up the MusicKit playing & synthesis appartus.
- play: (int) sj : (int) sk : (int) selonly : (int) noprogch
{
    int c, ch, i, j, k, si, n, x, nix, nk, mc, d, m, v, pat, pn, spn, trn;
    float f=0.0, mm, mt, t, xt, tn, qt, dur, lt, fine, minstamp, lwhite;
    System *sys;
    Staff *sp;
    NSMutableArray *nl, *tl;
    NSArray *channelList;
    NoteHead *h;
    GNote *q;
    Metro *mp;
    Channel *chan;
    NSString *inst;
    NSString *fname,*oldname;
    MKScore *as;
    MKSynthInstrument *synth;
    MKPartPerformer *partPerformer;
    PlayInspector *pi = [[CalliopeAppController sharedApplicationController] thePlayInspector];
    struct performer *perf;
    // TODO p should be declared a Graphic.
    id p, an;
    char curracc[7], keysig[7], keytmp[7];
    
    tl = [[NSMutableArray alloc] init];
    /* Find all the parts in the chords and voices */
    minstamp = MAXFLOAT;
    /* find out where to start */
    for (si = sj; si <= sk; si++)
    {
        sys = [syslist objectAtIndex: si];
        lwhite = [sys leftWhitespace];
        n = [sys numberOfStaves];
        [sys  doStamp: n : lwhite];
        for (i = 0; i < n; i++)
        {
            sp = [sys getStaff: i];
            if (sp->flags.hidden) continue;
            nl = sp->notes;
            nk = [nl count];
            for (j = 0; j < nk; j++)
            {
                q = [nl objectAtIndex:j];
                if (ISATIMEDOBJ(q) && ![q isInvisible] && (!selonly || [(Graphic *) q isSelected]))
                {
                    if (q->stamp < minstamp) minstamp = q->stamp;
                }
            }
        }
    }
    if (minstamp == MAXFLOAT) return self;
    /* initialise the parts */
    for (i = 0; i < NUMPARTPERFORM; i++)
    {
        perf = &(player[i]);
        if (perf->part)
        {
            [perf->part release];
            perf->part = nil;
        }
        if (perf->performer)
        {
            [perf->performer release];
            perf->performer = nil;
        }
    }
    numParts = 1;
    player[0].part = [[MKPart alloc] init];  /* the user interface part */
    /* Add the notes */
    /* NSLog(@"add notes:\n"); */
    pn = [currentPage pageNumber];
    fine = 0.1;  /* allow time to insert channel control changes */
    for (si = sj; si <= sk; si++)
    {
        t = fine;
        sys = [syslist objectAtIndex:si];
        spn = [sys pageNumber];
        if (spn < 0) spn = -spn;
        if (spn != pn)  /* take 1 second to turn the page */
        {
            pn = [sys pageNumber];
            if (pn < 0) pn = -pn;
            an = [[MKNote alloc] initWithTimeTag: (double) t - 1.0];
            [an setNoteType: MK_mute];
            [an setPar: [MKNote parTagForName: @"CAL_page"] toInt: pn];
            [player[0].part addNote: an];
        }
        lwhite = [sys leftWhitespace];
        n = [sys numberOfStaves];
        for (i = 0; i < n; i++)
        {
            sp = [sys getStaff: i];
            if (sp->flags.hidden) continue;
            nix  = [sp indexOfNoteAfter: lwhite];
            nk = [sp->notes count];
            mc = 10;
            for (j = 0; j < 7; j++)
            {
                keysig[j] = 0;
                curracc[j] = 0;
            }
            while (nix < nk)
            {
                p = [sp->notes objectAtIndex:nix];
                mp = [p findMetro];
                if (mp != nil)
                {
                    tn = DURTIME(((StaffObj *)p)->stamp - minstamp) + t;
                    an = [[MKNote alloc] initWithTimeTag: (double) tn];
                    [an setNoteType: MK_mute];
                    mt = tickval(mp->body[0], mp->dot[0]);
                    if (mp->gFlags.subtype)
                    {
                        mm = (mp->ticks * DURTIME(mt));
                        [an setPar: [MKNote parTagForName: @"CAL_setTempo"] toDouble: (double) mm];
                    }
                    else
                    {
                        mm = tickval(mp->body[1], mp->dot[1]) / mt;
                        [an setPar: [MKNote parTagForName: @"CAL_changeTempo"] toDouble: (double) mm];
                    }
                    [player[0].part addNote: an];
                }
                if (![p isInvisible])
		    switch ([p graphicType])  {
                    case CLEF:
                        mc = [p middleC];
                        break;
                    case KEY:
                        if (SUBTYPEOF(p) == 2)
                        {
                        /* different semantics for molle (augment accidental status) */
                            [p getKeyString: keytmp];
                            for (k = 0; k < 7; k++) if (curracc[k] == 0) curracc[k] = keytmp[k];
                        }
                        else
                        {
                            [p getKeyString: keysig];
                            for (k = 0; k < 7; k++) curracc[k] = keysig[k];
                        }
                        break;
                    case BARLINE:  /* check for Chant rest notation? */
                        if (sp->flags.subtype == 2)
                        {
                            /* different semantics for Chant staff */
                            for (k = 0; k < 7; k++) curracc[k] = 0;
                        }
                        else
                        {
                            for (k = 0; k < 7; k++) curracc[k] = keysig[k];
                        }
                        break;
                    case NOTE:
                        if (!selonly || [(Graphic *)p isSelected])
                        {
                            v = VOICEID(((StaffObj *)p)->voice, i);
                            ch = [p getChannel];
                            pat = [p getPatch];
                            inst = [p getInstrument];
                            trn = [instlist transForInstrument: inst];
                            tn = DURTIME(((StaffObj *)p)->stamp - minstamp) + t;
                            dur = DURTIME(((StaffObj *)p)->duration);
                            if ((channelList = [p tiedWith]) != nil)
                            {
                                if ((k = [tl indexOfObject:p]) != NSNotFound)
                                {
                                    [tl removeObjectAtIndex:k];
                                    [channelList autorelease];
                                    break;
                                }
                                else
                                {
                                    k = [channelList count];
                                    while (k--)
                                    {
                                        q = [channelList objectAtIndex:k];
                                        if (((StaffObj *)q)->stamp > ((StaffObj *)p)->stamp)
                                        {
                                            [tl addObject: q];
                                            dur += DURTIME(((StaffObj *)q)->duration);
                                        }
                                    }
                                }
                            }
                            k = [(GNote *)p numberOfNoteHeads];
                            while (k--)
                            {
                                h = [(GNote *)p noteHead: k];
                                if ([h bodyType] != 4)
                                {
                                    if ([h myNote] == p) f = getNoteFreq(p, [h staffPosition], [h accidental], mc, curracc, trn);
                                    an = newNote(tn, f, dur);
                                    if (![inst isEqualToString: nullProgChange] && !noprogch) setInst(an, pat);
                                    addNote(v, k, ch, an);
                                }
                            }
                            lt = tn + dur;
                            if (lt > fine) fine = lt;
                        }
                        break;
                    case TABLATURE:
                        if (!selonly || [(Graphic *)p isSelected])
                        {
                            tn = DURTIME(((StaffObj *)p)->stamp - minstamp) + t;
                            dur = DURTIME(((StaffObj *)p)->duration);
                            pat = [p getPatch];
                            inst = [p getInstrument];
                            v = VOICEID(((StaffObj *)p)->voice, i);
                            ch = [p getChannel];
                            k = sp->flags.nlines;
                            while (k--)
                            {
                                c = ((Tablature *)p)->chord[k];
                                if (c >= 0)
                                {
                                    f = getTabFreq(p, inst, k, c);
                                    if (f > 0)
                                    {
                                        an = newNote(tn, f, dur);
                                        if (![inst isEqualToString: nullProgChange] && !noprogch) setInst(an, pat);
                                        addNote(v, k, ch, an);
                                    }
                                }
                            }
                            k = ((Tablature *)p)->diapason;
                            if (k > 0)
                            {
                                f = getTabFreq(p, inst, k + 5, ((Tablature *)p)->diafret);
                                if (f > 0)
                                {
                                an = newNote(tn, f, dur);
                                    if (![inst isEqualToString: nullProgChange] && !noprogch) setInst(an, pat);
                                addNote(v, 6, ch, an);
                                }
                            }
                            lt = tn + dur;
                            if (lt > fine) fine = lt;
                        }
                        break;
                    case REST:
                        if (!selonly || [(Graphic *)p isSelected])
                        {
                            tn = DURTIME(((StaffObj *)p)->stamp - minstamp) + t;
                            dur = DURTIME(((StaffObj *)p)->duration);
                            lt = tn + dur;
                            if (lt > fine) fine = lt;
                        }
                        break;
                    case NEUMENEW:
                    case SQUARENOTE:
                        if (!selonly || [(Graphic *)p isSelected])
                        {
                            x = 0;
                            xt = 0;
                            ch = [p getChannel];
                            v = VOICEID(((StaffObj *)p)->voice, i);
                            while([p getPos: x : &k : &d : &m : &qt])
                            {
                                if (d) qt *= 2;
                                tn = DURTIME(((StaffObj *)p)->stamp - minstamp) + xt + t;
                                dur = DURTIME(qt);
                                an = newNote(tn, getNoteFreq(p, k, (m != 0), mc, curracc, 0), dur);
                                if (!noprogch) setInst(an, 52);
                                addNote(v, 0, ch, an);
                                lt = tn + dur;
                                if (lt > fine) fine = lt;
                                xt += dur;
                                ++x;
                            }
                        }
                        break;
		    default:
			NSLog(@"play: Unexpected graphicType: %d\n", [p graphicType]);
                }
                ++nix;
            }
        }
    }
    // NSLog(@"numParts = %d\n", numParts);
    switch(playmode) {
        case 0: /* start orchestra */
        if (!anOrch) anOrch = [MKOrchestra new];
        if (![anOrch open])
        {
            NSRunAlertPanel(@"Perform", @"Cannot open DSP", @"OK", nil, nil, NULL);
            return self;
        }
        /* [MKOrchestra setHeadroom: -0.5]; */
        [MKOrchestra setSamplingRate: 44100.0];
        [MKOrchestra setTimed: MK_TIMED];
        [MKPartPerformer setFastActivation: YES];
        for (i = 0; i < numParts; i++)
        {
            an = [[MKNote alloc] init];
            [an setNoteType: MK_noteUpdate];
            [an setPar: MK_synthPatch toString: @"DBWave1v" ];
            if (numParts <= 10) [an setPar: MK_synthPatchCount toInt: 1];
            [player[i].part setInfoNote: an];
            [an release];
            partPerformer = player[i].performer = [[MKPartPerformer alloc] init];
            [partPerformer setPart: player[i].part];
            [partPerformer activate];
            if (i == 0) [[partPerformer noteSender] connect: [[[UserInstrument alloc] init] noteReceiver]];
            else
            {
                synth = [[MKSynthInstrument alloc] init];
                [synth setSynthPatchClass: NSClassFromString(instruments[1].patch)];
                if (numParts <= 10) [synth setSynthPatchCount: 1];
                [[partPerformer noteSender] connect: [synth noteReceiver]];
            }
        }
        [[MKConductor defaultConductor] setTempo: [pi getTempo]];
//          [MKConductor setFinishWhenEmpty: NO]; // LMS ahh, actually we do want to finish when we have emptied the MKPartPerformer
        [MKConductor setFinishWhenEmpty: YES];
        [[MKConductor defaultConductor] sel: @selector(clickStop) to: self atTime: fine + 2.0 argCount:0];
        MKSetDeltaT(1.0);
        [MKConductor useSeparateThread: YES];
        [MKConductor setClocked: YES];
        [MKConductor setThreadPriority: 1.0];
        [anOrch run];
        // [NSAutoreleasePool enableDoubleReleaseCheck:YES];
        [MKConductor startPerformance];
    //        [NSAutoreleasePool showPools];
        break;
        case 1: /* write a ScoreFile */
            as = [[MKScore alloc] init];
            for (i = 1; i < numParts; i++) {
                an = [[MKNote alloc] init];
                [an setNoteType: MK_noteUpdate];
                [an setPar: MK_synthPatch toString: instruments[1].patch];
                if (numParts <= 10) [an setPar: MK_synthPatchCount toInt: 1];
                [player[i].part setInfoNote: an];
                [an release];
                [as addPart: player[i].part];
            }
            an = [[MKNote alloc] init];
            [an setNoteType: MK_mute];
            [an setPar: MK_samplingRate toDouble: (double) 22050.0];
            [an setPar: MK_tempo toDouble: [pi getTempo]];
            [as setInfoNote: an];
            [an release];
            fname = [[CalliopeAppController currentDocument] filename];
            if ([[fname pathExtension] length])
                fname = [[fname stringByDeletingPathExtension] stringByAppendingPathExtension:@"score"];
            oldname = [fname stringByAppendingString:@"~"];
            [[NSFileManager defaultManager] removeFileAtPath:oldname handler:nil];
            [[NSFileManager defaultManager] linkPath:fname toPath:oldname handler:nil];
            [[NSFileManager defaultManager] removeFileAtPath:fname handler:nil];
            [as writeScorefile: fname];
            [as release];
            for (i = 0; i < numParts; i++) player[i].part = nil;
            [self clickStop];
            break;
        case 4: /* write a MIDI file */
            as = [[MKScore alloc] init];
            channelList = [[CalliopeAppController sharedApplicationController] getChanlist];
            i = 16;
            while (i--) ((Channel *)[channelList objectAtIndex:i])->flag = 0;
            for (i = 0; i < numParts; i++)
            {
                ch = player[i].channel;
                an = [[MKNote alloc] init];
                [an setNoteType: MK_noteUpdate];
                [an setPar: MK_synthPatch toString: @"midi"];
                [an setPar: MK_midiChan toInt: ch];
                [an setPar: MK_synthPatchCount toInt: 1];
                [player[i].part setInfoNote: an];
                [an release];
                [as addPart: player[i].part];
            }
            an = [[MKNote alloc] init];
            for (i = 0; i < numParts; i++) {
                ch = player[i].channel;
                chan = [channelList objectAtIndex:ch];
                if (!chan->flag) {
                    chan->flag = 1;
                    [an setNoteType: MK_noteUpdate];
                    [an setTimeTag: 0.0];
                    [an setPar: MK_controlChange toInt: 7];
                    [an setPar: MK_controlVal toInt: (int) (127 * chan->level)];
                    [player[i].part addNote: [an copy]];
                    [an setTimeTag: 0.01];
                    [an setPar: MK_controlChange toInt: 10];
                    [an setPar: MK_controlVal toInt: (int) (127 * chan->pan)];
                    [player[i].part addNote: [an copy]];
                    [an setTimeTag: 0.02];
                    [an setPar: MK_controlChange toInt: 91];
                    [an setPar: MK_controlVal toInt: (int) (127 * chan->reverb)];
                    [player[i].part addNote: [an copy]];
                    [an setTimeTag: 0.03];
                    [an setPar: MK_controlChange toInt: 93];
                    [an setPar: MK_controlVal toInt: (int) (127 * chan->chorus)];
                    [player[i].part addNote: [an copy]];
                    [an setTimeTag: 0.04];
                    [an setPar: MK_controlChange toInt: 1];
                    [an setPar: MK_controlVal toInt: (int) (127 * chan->vibrato)];
                    [player[i].part addNote: [an copy]];
                }
            }
            [an release];
            an = [[MKNote alloc] init];
            [an setNoteType: MK_mute];
            [an setPar: MK_tempo toDouble: [pi getTempo]];
            [as setInfoNote: an];
            [an release];
            fname = [[CalliopeAppController currentDocument] filename];
            if ([[fname pathExtension] length])
                fname = [[fname stringByDeletingPathExtension] stringByAppendingPathExtension:@"midi"];
            oldname = [fname stringByAppendingString:@"~"];
            [[NSFileManager defaultManager] removeFileAtPath:oldname handler:nil];
            [[NSFileManager defaultManager] linkPath:fname toPath:oldname handler:nil];
            [[NSFileManager defaultManager] removeFileAtPath:fname handler:nil];
            [as writeMidifile:fname];
            [as release];
            for (i = 0; i < numParts; i++) player[i].part = nil;
            [self clickStop];
            break;
        case 2:
        case 3:
            [MKPartPerformer setFastActivation: YES];
            midi = [MKMidi midiOnDevice: ((playmode == 2) ? @"midi0" : @"midi1")];
            [midi openOutputOnly];         /* No need for Midi input. */
                [midi setConductor: [MKConductor defaultConductor]];
            [midi setOutputTimed: NO];
            [midi acceptSys: MK_sysStart];
            [midi acceptSys: MK_sysContinue];
            [midi acceptSys: MK_sysStop];
            channelList = [[CalliopeAppController sharedApplicationController] getChanlist];
            i = 16;
            while (i--) ((Channel *)[channelList objectAtIndex:i])->flag = 0;
                an = [[MKNote alloc] init];
            for (i = 0; i < numParts; i++) {
                ch = player[i].channel;
                chan = [channelList objectAtIndex:ch];
                if (!chan->flag)
                {
                chan->flag = 1;
                [an setNoteType: MK_noteUpdate];
                [an setTimeTag: 0.0];
                [an setPar: MK_controlChange toInt: 7];
                [an setPar: MK_controlVal toInt: (int) (127 * chan->level)];
                [player[i].part addNote: [an copy]];
                [an setTimeTag: 0.01];
                [an setPar: MK_controlChange toInt: 10];
                [an setPar: MK_controlVal toInt: (int) (127 * chan->pan)];
                [player[i].part addNote: [an copy]];
                [an setTimeTag: 0.02];
                [an setPar: MK_controlChange toInt: 91];
                [an setPar: MK_controlVal toInt: (int) (127 * chan->reverb)];
                [player[i].part addNote: [an copy]];
                [an setTimeTag: 0.03];
                [an setPar: MK_controlChange toInt: 93];
                [an setPar: MK_controlVal toInt: (int) (127 * chan->chorus)];
                [player[i].part addNote: [an copy]];
                [an setTimeTag: 0.04];
        /*  */	  [an setPar: MK_controlChange toInt: 1];
                [an setPar: MK_controlVal toInt: (int) (127 * chan->vibrato)];
                [player[i].part addNote: [an copy]];
                }
                partPerformer = player[i].performer = [[MKPartPerformer alloc] init];
                [partPerformer setPart: player[i].part];
                [partPerformer activate];
                if (i == 0) [[partPerformer noteSender] connect: [[[UserInstrument alloc] init] noteReceiver]];
                else [[partPerformer noteSender] connect: [midi channelNoteReceiver: ch]];
            }
            [an release];
            [[MKConductor defaultConductor] setTempo: [pi getTempo]];
//          [MKConductor setFinishWhenEmpty: NO]; // LMS ahh, actually we do want to finish when we have emptied the MKPartPerformer
            [MKConductor setFinishWhenEmpty: YES];
            [[MKConductor defaultConductor] sel: @selector(clickStop) to: self atTime: fine argCount:0];
            MKSetDeltaT(1.0);
            [MKConductor useSeparateThread: YES];
            [MKConductor setClocked: YES];
            [MKConductor setThreadPriority: 1.0];
            [midi run];
            [MKConductor startPerformance];
        break;
    }
    return self;
}

/* i=start,j=end: 0=system, 1=page, 2=doc */
- playChoice: (int) i : (int) j : (int) selonly : (int) noprogch
{
    Page *p = currentPage;
    switch(i)
    {
	case 0:
	    i = [syslist indexOfObject:currentSystem];
	    break;
	case 1:
	    i = [p topSystemNumber];
	    break;
	case 2:
	    i = 0;
	    break;
    }
    switch(j)
    {
	case 0:
	    j = [syslist indexOfObject:currentSystem];
	    break;
	case 1:
	    j = [p bottomSystemNumber];
	    break;
	case 2:
	    j = [syslist count] - 1;
	    break;
    }
    if (i == NSNotFound || j == NSNotFound) {
	return self;
    }
    [self flowTimeSig: [syslist objectAtIndex:j]];
    [[CalliopeAppController sharedApplicationController] thePlayView: self];
    [self play: i : j : selonly : noprogch];
    return self;
}


- clickStop
{
    [MKConductor sendMsgToApplicationThreadSel: @selector(clickStopButton) to: [[CalliopeAppController sharedApplicationController] thePlayInspector] argCount: 0];
    return self;
}


/* Retrieve a score or midi file from the specified file path */

char *ntypename[5] = {"dur", "on", "off", "update", "mute"};

- dumpNote: (MKNote *) n
{
    void *s = MKInitParameterIteration(n);
    int par;
    NSString *str;
    NSLog(@"tag:%d, type:%s, time:%f, dur:%f", [n noteTag], ntypename[[n noteType] - 257], [n timeTag], [n dur]);
    while ((par = MKNextParameter(n, s)) != MK_noPar)
    {
	str = [n parAsString: par];
	NSLog(@"  [%s:  %s]", [[MKNote parNameForTag: par] UTF8String], [str UTF8String]);
    }
    return self;
}


- (BOOL) getScoreFile: (NSString *) path
{
    int i, j, count, level = 0, fileTempo = MAXINT;
    id parts, /*info,*/ note;
    MKPart *part;
    MKScore *newScore = [[MKScore alloc] init];
    BOOL isMIDIFile = NO;
    BOOL hasGlobalPart = NO;
    if ([[path pathExtension] isEqualToString:@"midi"])
    {
	level = 1;
	if (![newScore readMidifile: path])
	{
	    [newScore release];
	    return NO;
	}
	isMIDIFile = YES;
	count = [newScore partCount];
	if (count > 0)
	{
	    /* Get info of last part. */
	    MKNote *partInfo = [(MKPart *)[[newScore parts] objectAtIndex:count - 1] infoNote];
	    
	    if (partInfo) level = MKIsNoteParPresent(partInfo, MK_track) ? 1 :
		(MKIsNoteParPresent(partInfo, MK_sequence) ? 2 : 0);
	}
	if ([[newScore infoNote] isParPresent:MK_tempo])
	    fileTempo = MKGetNoteParAsInt([newScore infoNote], MK_tempo);
	parts = [newScore parts];
    }
    else
    {
	/* Must be a scorefile */
	if (![newScore readScorefile:path])
	{
	    [newScore release];
	    return NO;
	}
	if ([[newScore infoNote] isParPresent:MK_tempo]) fileTempo = MKGetNoteParAsInt([newScore infoNote], MK_tempo);
	parts = [newScore parts];
	if ([parts count])
	    hasGlobalPart = [MKGetObjectName([parts objectAtIndex:0]) isEqualToString:@"allParts"];
	else hasGlobalPart = NO;
    }
    NSLog(@"level %d MIDI file\n", level);
    NSLog(@"info note:");
    [self dumpNote: [newScore infoNote]];
    NSLog(@"\n");
    count = [parts count];
    for (i = 0; i < count; i++)
    {
	NSArray *notes;
	int noteCount;
	
	part = [parts objectAtIndex:i];
	noteCount = [part noteCount];
	NSLog(@"  part %d has %d notes. info:\n", i, noteCount);
	[self dumpNote: [part infoNote]];
	NSLog(@"\n");
	notes = [part notes];
	for (j = 0; j < noteCount; j++)
	{
	    note = [notes objectAtIndex:j];
	    NSLog(@"    note %d:", j);
	    [self dumpNote: note];
	    NSLog(@"\n");
	}
	[notes autorelease]; // Careful here when working with MK...
    }
    [parts release];
    [newScore release];
    return YES;
}


/* Get a score file name from the user and load it. */

- openScoreFile: sender
{
    NSString *file;
    BOOL p = NO;
    NSArray* ext = [NSArray arrayWithObjects:@"midi",@"score",nil];
    
    id openpanel = [NSOpenPanel openPanel]; [openpanel setAllowsMultipleSelection:NO];
    if ([openpanel runModalForTypes:ext] == NSOKButton)
    {
	file = [openpanel filename];
	if (file) p = [self getScoreFile: file];
    }
    if (!p) NSRunAlertPanel(@"Score/MIDI File", @"Cannot Open.", @"OK", nil, nil);
    return self;
}


@end
