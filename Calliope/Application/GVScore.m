//
//  $Id:$
//  Calliope
//
//  Routines to create and load MusicKit scorefiles.
//  Created by Leigh Smith on 28/11/09.
//  Copyright 2009 Oz Music Code LLC. All rights reserved.
//
#import <MusicKit/MusicKit.h>
#import "CalliopeAppController.h"
#import "GVScore.h"
#import "NoteHead.h"
#import "GNote.h"
#import "Tablature.h"
#import "NeumeNew.h"
#import "SquareNote.h"
#import "Course.h"
#import "Clef.h"
#import "KeySig.h"
#import "Metro.h"
#import "Channel.h"
#import "StaffObj.h"
#import "System.h"
#import "SysAdjust.h"
#import "CallInst.h"
#import "muxlow.h" // for getNumOct().
#import "DrawingFunctions.h" // for ISATIMEDOBJ()

#define MINIMTICK 64.0
#define DURTIME(t) ((t) * (1.0 / MINIMTICK))

// Eventually should be a category of NotationScore(MKScore).
@implementation GraphicView(GVScore)

// Sadly we need these externs. Ideally we'd get them via a class.
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
};

static struct inst instruments[8] =
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

/* for internal orch, the number of a G-MIDI instrument is mapped onto a local instrument */

static char myinst[128] = 
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

static void initEnvelopes()
{
    int i;
    
    for (i = 0; i < NUMENV; i++) {
	MKEnvelope *e = [[MKEnvelope alloc] init];
	int r = 0;
	
	[e setPointCount: envelpts[i] xArray: envxys[r] yArray: envxys[r + 1]];
	r += 2;
	[e setStickPoint: stickpts[i]];
	envelopes[i] = e;
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
    Course *cp = [[instlist tuningForInstrument: n] objectAtIndex: c];
    float f;
    
    if (cp == nil) 
	return 0.0;
    f = notefreq[(int) cp->pitch] * power2[(int) cp->oct] * chromalter[(int) cp->acc];
    if (fret)
	f = transpose(f, fret);
    return f;
}

static void setInst(MKNote *n, int i)
{
    int mi = myinst[i];
    
    [n setPar: MK_ampEnv toEnvelope: envelopes[(int)instruments[mi].envelope]];
    [n setPar: MK_waveform toString: instruments[mi].waveform];
    [n setPar: MK_svibFreq toDouble: instruments[mi].svibFreq];
    [n setPar: MK_svibAmp toDouble: instruments[mi].svibAmp];
    [n setPar: MK_amp toDouble: instruments[mi].amp];
    if (instruments[mi].bright > 0) 
	[n setPar: MK_bright toDouble: instruments[mi].bright];
    [n setPar: MK_programChange toInt: i];
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
 Return the part determined by <voice, notehead, channel>, creating a new part if necessary.
 */
- (MKPart *) partOfScore: (MKScore *) score forVoice: (int) v noteHead: (int) k channel: (int) midiChannel
{
    NSString *partVNCName = [NSString stringWithFormat: @"CalliopePart_%d_%d_%d", v, k, midiChannel];
    MKPart *retrievedPart = [score partNamed: partVNCName];
    
    if (retrievedPart == nil) {
	MKPart *newPart = [[MKPart alloc] init];
	MKNote *partInfoNote = [[MKNote alloc] init];
	
	// Add an info note for the MKPart, mainly to save the MIDI channel.
	[partInfoNote setNoteType: MK_noteUpdate];
	[partInfoNote setPar: MK_synthPatchCount toInt: 1];
	[partInfoNote setPar: MK_midiChan toInt: midiChannel];
	[newPart setInfoNote: partInfoNote];
	[partInfoNote release];
	
	[newPart setPartName: partVNCName];
	[score addPart: newPart];
	return [newPart autorelease];
    }
    else
	return retrievedPart; // is already autoreleased by partNamed:.
}

/* find out where to start */
- (float) earliestTimeStampBetweenSystem: (int) startingSystemIndex 
			       andSystem: (int) endingSystemIndex
{
    /* Find all the parts in the chords and voices */
    float minstamp = MAXFLOAT;
    int systemIndex;
    
    for (systemIndex = startingSystemIndex; systemIndex <= endingSystemIndex; systemIndex++) {
	System *sys = [syslist objectAtIndex: systemIndex];
        float lwhite = [sys leftWhitespace];
        int numberOfStaves = [sys numberOfStaves];
	int staffIndex;
	
        [sys doStamp: numberOfStaves : lwhite];
        for (staffIndex = 0; staffIndex < numberOfStaves; staffIndex++) {
	    Staff *sp = [sys getStaff: staffIndex];
	    
            if (!sp->flags.hidden) {
		NSMutableArray *nl = sp->notes;
		int noteCount = [nl count];
		int j;
		
		for (j = 0; j < noteCount; j++) {
		    GNote *q = [nl objectAtIndex: j];
		    
		    // TODO missing && (!selectedOnly || [q isSelected])
		    if (ISATIMEDOBJ(q) && ![q isInvisible] && (q->stamp < minstamp)) {
			minstamp = q->stamp;
		    }
		}
	    }
        }
    }
    return minstamp;
}

- (MKScore *) scoreBetweenSystem: (int) startingSystemIndex 
		       andSystem: (int) endingSystemIndex
	    onlySelectedGraphics: (BOOL) selectedOnly
{
    int c, ch, j, k, systemIndex, x, noteIndex, mc, d, m, v, pat, trn;
    int partIndex;
    float f=0.0, t, xt, tn, qt, dur, lt, fine, minstamp;
    NSMutableArray *tl = [[NSMutableArray alloc] init];
    NSArray *channelList = [[CalliopeAppController sharedApplicationController] getChanlist];
    NoteHead *h;
    Channel *chan;
    NSString *inst;
    MKScore *newScore;
    MKNote *an;
    MKNote *infoNote; // for the score.
    NSArray *parts;
    char curracc[7], keysig[7], keytmp[7];
    float tempo = 120.0; // kludged for now, retrieve from Metro value.

    initEnvelopes();
    minstamp = [self earliestTimeStampBetweenSystem: startingSystemIndex andSystem: endingSystemIndex];
    if (minstamp == MAXFLOAT) 
	return nil;    

    newScore = [[MKScore alloc] init];
    
    infoNote = [[MKNote alloc] init];
    [infoNote setNoteType: MK_mute];
    [infoNote setPar: MK_samplingRate toDouble: (double) 22050.0];
    [infoNote setPar: MK_tempo toDouble: tempo];
    [newScore setInfoNote: infoNote];
    [infoNote release];
    
    /* Add the notes */
    /* NSLog(@"add notes:\n"); */
    fine = 0.1;  /* allow time to insert channel control changes */
    for (systemIndex = startingSystemIndex; systemIndex <= endingSystemIndex; systemIndex++) {
        System *sys = [syslist objectAtIndex: systemIndex];
        int numberOfStaves = [sys numberOfStaves];
        float lwhite = [sys leftWhitespace];
	int staffIndex;
	
        t = fine;

        for (staffIndex = 0; staffIndex < numberOfStaves; staffIndex++) {
	    int noteCount;
	    Staff *sp = [sys getStaff: staffIndex];
	    
            if (sp->flags.hidden) 
		continue;
            noteIndex = [sp indexOfNoteAfter: lwhite];
            noteCount = [sp->notes count];
            mc = 10;
            for (j = 0; j < 7; j++) {
                keysig[j] = 0;
                curracc[j] = 0;
            }
            while (noteIndex < noteCount) {
		StaffObj *p = [sp->notes objectAtIndex: noteIndex];
		// Metro *mp = [p findMetro];

                if (![p isInvisible]) {
		    switch ([p graphicType]) {
			case CLEF:
			    mc = [(Clef *) p middleC];
			    break;
			case KEY:
			    if (SUBTYPEOF(p) == 2) {
				/* different semantics for molle (augment accidental status) */
				[(KeySig *) p getKeyString: keytmp];
				for (k = 0; k < 7; k++)
				    if (curracc[k] == 0) 
					curracc[k] = keytmp[k];
			    }
			    else {
				[(KeySig *) p getKeyString: keysig];
				for (k = 0; k < 7; k++)
				    curracc[k] = keysig[k];
			    }
			    break;
			case BARLINE:  /* check for Chant rest notation? */
			    if (sp->flags.subtype == 2) {
				/* different semantics for Chant staff */
				for (k = 0; k < 7; k++) 
				    curracc[k] = 0;
			    }
			    else {
				for (k = 0; k < 7; k++)
				    curracc[k] = keysig[k];
			    }
			    break;
			case NOTE:
			    if (!selectedOnly || [p isSelected]) {
				v = [p voiceWithDefault: staffIndex];
				ch = [p getChannel];
				pat = [(GNote *) p getPatch];
				inst = [p getInstrument];
				trn = [instlist transForInstrument: inst];
				tn = DURTIME(((StaffObj *)p)->stamp - minstamp) + t;
				dur = DURTIME(((StaffObj *)p)->duration);
				if ((channelList = [(GNote *) p tiedWith]) != nil) {
				    if ((k = [tl indexOfObject: p]) != NSNotFound) {
					[tl removeObjectAtIndex: k];
					[channelList autorelease];
					break;
				    }
				    else {
					k = [channelList count];
					while (k--) {
					    GNote *q = [channelList objectAtIndex:k];
					    
					    if (((StaffObj *)q)->stamp > ((StaffObj *)p)->stamp) {
						[tl addObject: q];
						dur += DURTIME(((StaffObj *)q)->duration);
					    }
					}
				    }
				}
				k = [(GNote *)p numberOfNoteHeads];
				while (k--) {
				    h = [(GNote *)p noteHead: k];
				    if ([h bodyType] != 4) {
					if ([h myNote] == p) 
					    f = getNoteFreq(p, [h staffPosition], [h accidental], mc, curracc, trn);
					an = newNote(tn, f, dur);
					if (![inst isEqualToString: nullProgChange])
					    setInst(an, pat);
					[[self partOfScore: newScore forVoice: v noteHead: k channel: ch] addNote: an];
				    }
				}
				lt = tn + dur;
				if (lt > fine) 
				    fine = lt;
			    }
			    break;
			case TABLATURE:
			    if (!selectedOnly || [p isSelected]) {
				tn = DURTIME(((StaffObj *)p)->stamp - minstamp) + t;
				dur = DURTIME(((StaffObj *)p)->duration);
				pat = [(Tablature *) p getPatch];
				inst = [p getInstrument];
				v = [p voiceWithDefault: staffIndex];
				ch = [p getChannel];
				k = sp->flags.nlines;
				while (k--) {
				    c = ((Tablature *)p)->chord[k];
				    if (c >= 0) {
					f = getTabFreq((Tablature *) p, inst, k, c);
					if (f > 0) {
					    an = newNote(tn, f, dur);
					    if (![inst isEqualToString: nullProgChange])
						setInst(an, pat);
					    [[self partOfScore: newScore forVoice: v noteHead: k channel: ch] addNote: an];
					}
				    }
				}
				k = ((Tablature *)p)->diapason;
				if (k > 0) {
				    f = getTabFreq((Tablature *) p, inst, k + 5, ((Tablature *)p)->diafret);
				    if (f > 0) {
					an = newNote(tn, f, dur);
					if (![inst isEqualToString: nullProgChange]) 
					    setInst(an, pat);
					[[self partOfScore: newScore forVoice: v noteHead: 6 channel: ch] addNote: an];
				    }
				}
				lt = tn + dur;
				if (lt > fine) 
				    fine = lt;
			    }
			    break;
			case REST:
			    if (!selectedOnly || [p isSelected]) {
				tn = DURTIME(((StaffObj *)p)->stamp - minstamp) + t;
				dur = DURTIME(((StaffObj *)p)->duration);
				lt = tn + dur;
				if (lt > fine) 
				    fine = lt;
			    }
			    break;
			case NEUMENEW:
			case SQUARENOTE:
			    if (!selectedOnly || [p isSelected]) {
				x = 0;
				xt = 0;
				ch = [p getChannel];
				v = [p voiceWithDefault: staffIndex];
				while([(SquareNote *) p getPos: x : &k : &d : &m : &qt]) {
				    if (d) 
					qt *= 2;
				    tn = DURTIME(((StaffObj *)p)->stamp - minstamp) + xt + t;
				    dur = DURTIME(qt);
				    an = newNote(tn, getNoteFreq(p, k, (m != 0), mc, curracc, 0), dur);
				    setInst(an, 52);
				    [[self partOfScore: newScore forVoice: v noteHead: 0 channel: ch] addNote: an];
				    lt = tn + dur;
				    if (lt > fine) 
					fine = lt;
				    xt += dur;
				    ++x;
				}
			    }
			    break;
			default:
			    NSLog(@"-scoreBetweenSystem:andSystem: Unexpected graphicType: %d\n", [p graphicType]);
		    }
		}
		++noteIndex;
            }
        }
    }
    parts = [newScore parts];
    NSLog(@"numParts = %d\n", [parts count]);

    /* add configuration parameters for each part. */
    for (partIndex = 0; partIndex < [parts count]; partIndex++) {
	MKPart *part = [parts objectAtIndex: partIndex];
	MKNote *partInfoNote = [part infoNote];
	MKNote *controlChangeNote = [[MKNote alloc] init];
	
	// Determine the output synth & assign appropriately. Parameters which are MIDI specific are ignored.
	// orchestra
	// [partInfoNote setPar: MK_synthPatch toString: @"DBWave1v" ];
	// scorefile
	// [partInfoNote setPar: MK_synthPatch toString: instruments[1].patch];
	// midi
	[partInfoNote setPar: MK_synthPatch toString: @"midi"];

	// Set MIDI controllers.
	[controlChangeNote setNoteType: MK_noteUpdate];
	[controlChangeNote setTimeTag: 0.0];
	[controlChangeNote setPar: MK_controlChange toInt: 7];
	[controlChangeNote setPar: MK_controlVal toInt: (int) (127 * chan->level)];
	[part addNote: [controlChangeNote copy]];
	[controlChangeNote setTimeTag: 0.01];
	[controlChangeNote setPar: MK_controlChange toInt: 10];
	[controlChangeNote setPar: MK_controlVal toInt: (int) (127 * chan->pan)];
	[part addNote: [controlChangeNote copy]];
	[controlChangeNote setTimeTag: 0.02];
	[controlChangeNote setPar: MK_controlChange toInt: 91];
	[controlChangeNote setPar: MK_controlVal toInt: (int) (127 * chan->reverb)];
	[part addNote: [controlChangeNote copy]];
	[controlChangeNote setTimeTag: 0.03];
	[controlChangeNote setPar: MK_controlChange toInt: 93];
	[controlChangeNote setPar: MK_controlVal toInt: (int) (127 * chan->chorus)];
	[part addNote: [controlChangeNote copy]];
	[controlChangeNote setTimeTag: 0.04];
	[controlChangeNote setPar: MK_controlChange toInt: 1];
	[controlChangeNote setPar: MK_controlVal toInt: (int) (127 * chan->vibrato)];
	[part addNote: [controlChangeNote copy]];
    }
    
    return [newScore autorelease];
}

- (MKScore *) musicKitScore
{
    return [self scoreBetweenSystem: 0 
			  andSystem: [syslist count] - 1
	       onlySelectedGraphics: NO];
}

@end
