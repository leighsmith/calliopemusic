/* $Id$ */
#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#import "CalliopeAppController.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVGlobal.h"
#import "GVSelection.h"
#import "Graphic.h"
#import "TextGraphic.h"
#import "CastInspector.h"
#import "PlayInspector.h"
#import "SysInspector.h"
#import "TextVarCell.h"
#import "AppDefaults.h"
#import "Preferences.h"
#import "LayBarInspector.h"
#import "DrawingFunctions.h"
#import "muxlow.h"

#if defined (WIN32)
// TODO this is probably unnecessary.
#import <AppKit/obsoleteNSCStringText.h>
#endif

#import "MyNSMutableAttributedString.h"

#define USEGOOD 0

#ifdef USEGOOD

/* needed for good_size */

#import "GNote.h"
#import "Tablature.h"
#import "Barline.h"
#import "Staff.h"

#endif

#define FONT_VERSION @"002.004" /* version of the Calliope Font */

int currentTool = 0;		/* the current tool number */
int escapedTool = 0;		/* the escaped tool */
int needUpgrade = 0;		/* whether to call upgrade */
GraphicView *playView = nil;

extern int fontflag;

@implementation CalliopeAppController

NSModalSession alertSession;

// Allows returning a Singleton.
CalliopeAppController *sharedApplicationController = nil;

/*
 * setAutoupdate:YES means that updateWindows will be called after
 * every event is processed (this is how we keep our inspector and
 * our menu items up to date).
 * All other setup code goes here...right?
 */

/* force a nid to be associated with a particular font */
static BOOL loadFont(int nid, NSString *name, float size, NSString *fv)
{
    NSFont *f = fontdata[nid] = [[NSFont fontWithName: name size: size] retain];
    
    if (f == nil) {
	NSRunAlertPanel(@"Calliope", @"Font: %@ not installed", @"OK", nil, nil, name);
	return NO;
    }
    return YES;
}


static BOOL initFonts()
{
    int i;
    
    for (i = 0; i < NUMCALFONTS; i++) 
	fontdata[i] = nil;
    if(!loadFont(FONTSON,  @"Sonata",      32.0, nil))
	return NO;
    if(!loadFont(FONTSSON, @"Sonata",      24.0, nil))
	return NO;
    if(!loadFont(FONTHSON, @"Sonata",      16.0, nil))
	return NO;
    if(!loadFont(FONTMUS,  @"Calliope",    32.0, FONT_VERSION))
	return NO;
    if(!loadFont(FONTSMUS, @"Calliope",    24.0, FONT_VERSION))
	return NO;
    if(!loadFont(FONTHMUS, @"Calliope",    16.0, FONT_VERSION))
	return NO;
    if(!loadFont(FONTTEXT, @"Times-Roman", 18.0, nil))
	return NO;
    if(!loadFont(FONTSTMR, @"Times-Roman", 16.0, nil))
	return NO;
    [[NSFontManager sharedFontManager] setSelectedFont: fontdata[FONTTEXT] isMultiple: NO];
    return YES;
}

extern void colorInit(int i, NSColor * c);

- init
{
    if ((self = [super init]) != nil) {
	colorInit(0, [NSColor lightGrayColor]);
	colorInit(1, [NSColor blackColor]);
	colorInit(2, [NSColor darkGrayColor]);
	colorInit(3, [NSColor whiteColor]);
	colorInit(4, [NSColor darkGrayColor]);
	colorInit(5, [NSColor darkGrayColor]);
	colorInit(6, [NSColor lightGrayColor]);
	if(!initFonts()) {
	    NSLog(@"Exiting due to font problems");
	    exit(1);	
	}
	muxlowInit();
        // TODO this is probably better done by the nib file or from the menu.
        // if (!(a->appdefaults))  [NSBundle loadNibNamed:@"AppDefaults.nib" owner:a];
        // [a->appdefaults checkOpenFromFile];	
        cpl = nil;
	if(sharedApplicationController == nil)
	    sharedApplicationController = self; // Assign the Singleton returned by the class method.
    }
    return self;
}


/* Private C functions used to implement methods in this class. */


/*
 * Checks to see if the passed window's delegate is a OpusDocument.
 * If it is, it returns that document, otherwise it returns nil.
 */

static OpusDocument *documentInWindow(id window)
{
    id document;
    if (!window) {
        return nil;
    }
    document = [window delegate];
    return [document isKindOfClass:[OpusDocument class]] ? document : nil;
}


+ (CalliopeAppController *) sharedApplicationController
{
    return sharedApplicationController;
}

/* General application status and information querying/modifying methods. */

// TODO Probably become a OpusDocument class method?
+ (OpusDocument *) currentDocument
{
    NSDocumentController *sdc = [NSDocumentController sharedDocumentController];
    
    return [sdc currentDocument];
//    return [[NSDocumentController sharedDocumentController] currentDocument];
}

+ (GraphicView *) currentView
{
    return [[[self class] currentDocument] graphicView];
}


- (NSString *)currentDirectory
{
    NSString *retval = [[[self class] currentDocument] directory];
    
//    if (!retval || !*retval) retval = [[[NSOpenPanel openPanel] directory] UTF8String];
//sb: changed the following to retrieve current directory from application rather than openpanel, which is no longer shared.
    if (!retval) retval = [[NSFileManager defaultManager] currentDirectoryPath];
    else if (![retval length]) retval = [[NSFileManager defaultManager] currentDirectoryPath];
    return retval;
}

- print:sender
{
    BOOL printSuccess;
    OpusDocument *doc = [[self class] currentDocument];
    
    if (doc && ![[doc graphicView] isEmpty])
    {
        printSuccess = [[NSPrintOperation printOperationWithView:[doc graphicView]
						       printInfo:[doc printInfo]] runOperation];
    }
    return self;
}

/* Application-wide shared panels */

/* clicks the appropriate button on the Matrix */

- selectFontSelection: (int) i
{
    [fontAccMatrix selectCellAtRow:i column:0];
    return fontAccMatrix;
}


- orderFontPanel: sender
{
    GraphicView *v = [[self class] currentView];
    if (v == nil)
    {
	NSLog(@"orderFontPanel: currentView is nil");
	return self;
    }
    if ([NSApp keyWindow] == [v window])
    {
	if ([[v selectedGraphics] count] == 0) [v setFontSelection: 3 : 0];
	else [v setFontSelection: 0 : 2];
    }
    else
    {
	fontflag = -1;
	clearMatrix(fontAccMatrix);
	/* now need to select the font in the thing */
    }
    [[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
    return self;
}

- newPageLayout
{
    [cpl release];
    cpl = nil;
    return [self pageLayout];
}

- pageLayout
    /*
     * Returns the application-wide CallPageLayout panel.
     */
{
    if (!cpl) {
        cpl = [[CallPageLayout pageLayout] retain];
    }
    return cpl;
}

/*  Returns a SavePanel of given extension (or none if NULL) */

- savePanel: (NSString *) ext
{    
    id p = [self mySavePanel];
    if (ext) [p setRequiredFileType:ext];
    return p;
}

- (NSSavePanel *)mySavePanel
{
    static NSSavePanel* thePanel = nil;
    if (!thePanel) thePanel = [[NSSavePanel savePanel] retain];
    return thePanel;
}


- help:sender
{
    return self;
}


/*
 * Brings up the information panel.
 */

- info:sender
{
    if (!infoPanel) {
	NSString *applicationVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"]; // CFBundleShortVersionString
	
	if (![NSBundle loadNibNamed:@"InfoPanel.nib" owner:self])  {
	    NSLog(@"Failed to load InfoPanel.nib");
	    return nil;
	}
	[version setStringValue: applicationVersion];
    }
    [infoPanel orderFront:self];
    return self;
}


/* Launches Inspector Panels */

- launchIt: p
{
    if (!p) return self;
    /* [p setFloatingPanel:YES]; */
    [p preset];
    [p makeKeyAndOrderFront:self];
    return self;
}


- (int) getLayBarNumber;
{
    int r = 0;
    if (!laybarInspector) [NSBundle loadNibNamed:@"LayBarInspector.nib" owner:self];
    [[laybarform cellAtIndex:0] setIntValue:1];
    [laybarform selectTextAtIndex:0];
    [laybarInspector makeKeyAndOrderFront:self];
    if ([NSApp runModalForWindow:laybarInspector] == NSRunStoppedResponse) r = [[laybarform cellAtIndex:0] intValue];
    [(LayBarInspector *)laybarInspector close];
    return r;
}


- presetPrefsPanel
{
    if (preferences && [preferences isVisible])
    {
	[preferences preset];
	[preferences makeKeyAndOrderFront:self];
    }
    return self;
}


- orderPreferencePanel: sender
{
    if (!preferences)
    {
	[NSBundle loadNibNamed:@"Preferences.nib" owner:self];
    }
    [preferences preset];
    [preferences makeKeyAndOrderFront:self];
    return self;
}


- inspectPreferences: (BOOL) b
{
    if (b) [self orderPreferencePanel: self];
    if (preferences) [preferences reflectSelection];
    return self;
}

- thePreferences
{
    if (!preferences)
    {
	[NSBundle loadNibNamed:@"Preferences.nib" owner:self];
    }
    return preferences;
}

float unitFactor[4] =
{
    0.013889, 0.035278, 1.0, 0.083333
};

- (float)pointToCurrentUnitFactor
{
    return unitFactor[[self unitNum]];
}

- (NSString *)unitString
{
//sb: I feel I should take note of the (global) NSMeasurementUnit default, but
//for now I am going to totally ignore it. I could take the value of NSMeasurementUnit
// in AppDefaults when I set the registration defaults, for MACH ONLY!
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"Units"];
    
}

- (int)unitNum
{
    NSString *unit = [[self unitString] lowercaseString];
    if ([unit isEqualToString:@"inches"]) return 0;
    if ([unit isEqualToString:@"centimeters"]) return 1;
    if ([unit isEqualToString:@"centimetres"]) return 1;
    if ([unit isEqualToString:@"points"]) return 2;
    if ([unit isEqualToString:@"picas"]) return 3;
    return 4; /* should not happen */
}

- orderAppDefPanel: sender
{
    if (!appdefaults)  [NSBundle loadNibNamed:@"AppDefaults.nib" owner:self];
    [appdefaults preset];
    [appdefaults makeKeyAndOrderFront:self];
    return self;
}


- orderTabTuner: sender
{
    if (!tabTuner)  [NSBundle loadNibNamed:@"TabTuner.nib" owner:self];
    [tabTuner preset];
    [tabTuner makeKeyAndOrderFront:self];
    return self;
}

- orderVoiceInspector: sender
{
    if (!voiceInspector)  [NSBundle loadNibNamed:@"VoiceInspector.nib" owner:self];
    [voiceInspector preset];
    [voiceInspector makeKeyAndOrderFront:self];
    return self;
}


- orderPlayInspector: sender
{
    if (!perfInspector)  [NSBundle loadNibNamed:@"PlayInspector.nib" owner:self];
    [perfInspector makeKeyAndOrderFront:self];
    return self;
}

/* get the play inspector */

- thePlayInspector
{
    if (!perfInspector)  [NSBundle loadNibNamed:@"PlayInspector.nib" owner:self];
    return perfInspector;
}


- orderCastInspector: sender
{
    if (!castInspector)  [NSBundle loadNibNamed:@"CastInspector.nib" owner:self];
    [castInspector makeKeyAndOrderFront:self];
    return self;
}


/* tries to inspect whatever is open */


- inspectAppWithMe: g loadInspector: (BOOL) launch : (int) fontseltype
{
    GraphicView *v;
    if (castInspector) [castInspector reflectSelection];
    if (perfInspector) [perfInspector reflectSelection];
    if (preferences) [preferences reflectSelection];
    [self inspectClass: [SysInspector class] loadInspector: NO];
    v = [[self class] currentView];
    if (v != nil)
    {
	if ([[v selectedGraphics] count] > 0)
	{
	    [v inspectSelWithMe: g : launch : fontseltype];
	    [v setFontSelection: fontseltype : 0];
	}
	else
	{
	    [v setFontSelection: 3 : 0];
	}
    }
    return self;
}


- inspectApp
{
    return [self inspectAppWithMe: nil loadInspector: NO : 0];
}


/* the progress panel */



/*
 Given a Class, look for its inspector.
 Throw up the inspector for the given object (return nil if none)
 Load .nib file if necessary.
 */
- getInspectorForClass: (Class) c loadInspector: (BOOL) cmd
{
    NSString *buff;
    id p = nil;
    int k = [insplist count];
    BOOL f = NO;
    
    while (k-- && !f) {
	p = [insplist objectAtIndex: k];
	if ([p class] == c) f = YES;
    }
    if (!f) {
	if (!cmd) 
	    return nil;
	buff = [NSString stringWithFormat:@"%@.nib", NSStringFromClass([c class])];
	inspector = nil;
	[NSBundle loadNibNamed: buff owner:self];
	p = inspector;
	if (!p) 
	    NSLog(@"Cannot get named object %@\n", buff);
	else 
	    [insplist addObject: p];
    }
    return p;
}


/* if cmd, then force it to launch if it is not already visible */

- inspectClass: (Class) c loadInspector: (BOOL) cmd
{
    id p = [self getInspectorForClass: c loadInspector: cmd];
    if (cmd)
    {
	if (p) [self launchIt: p];
	else NSLog(@"Couldn't find inspector\n");
    }
    else if (p && [p isVisible] && !([p respondsToSelector:@selector(isBusy)] && [p isBusy])) [p preset];
    return self;
}


- inspectMe: g loadInspector: (BOOL) cmd
{
    id p;
    if ([g myInspector] == nil) return g;
    p = [self getInspectorForClass: [g myInspector] loadInspector: cmd];
    if (cmd)
    {
	if (p) [self launchIt: p];
	else NSLog(@"Couldn't find inspector\n");
    }
    else if (p)
    {
	if ([p isVisible]) [p preset];
	if (HASAVOICE(g))
	{
	    if (voiceInspector && [voiceInspector isVisible]) [voiceInspector preset];
	}
    }
    return g;
}


/* return the current partlist, channel list, style list */

- (NSMutableArray *) getPartlist
{
    OpusDocument *d = [[self class] currentDocument];
    if (d == nil) return scratchlist;
    if ([d graphicView] == nil) return scratchlist;
    return [[d graphicView] partList];
}


- (NSArray *) getChanlist
{
    OpusDocument *d = [[self class] currentDocument];
    if (d == nil) return nil;
    if ([d graphicView] == nil) return nil;
    return [[d graphicView] channels];
}


- (NSMutableArray *) getStylelist
{
    OpusDocument *d = [[self class] currentDocument];
    if (d == nil) return scrstylelist;
    if ([d graphicView] == nil) return nil;
    return [[d graphicView] styles];
}

- thePlayView
{
    return playView;
}

- thePlayView: v
{
    playView = v;
    return v;
}


/*
 * Application object delegate methods.
 * Since we don't have an application delegate, messages that would
 * normally be sent there are sent to the Application object itself instead.
 */
static void handleMKError(NSString *msg)
{
    if (![MKConductor performanceThread]) { /* Not performing */
        if (!NSRunAlertPanel(@"MKError", msg, @"OK", nil, nil, NULL))
            return; //[NSApp terminate:NSApp];
    }
    else {  
	/* When we're performing in a separate thread, we can't bring
	   up a panel because the Application Kit is not thread-safe.
	   This may no longer be the case, but we use NSLog() since we
           can nowdays be reasonably assured it is thread safe.
	    
	   An alternative would be to use mach messaging to signal the
	   App thread that there's a panel to be displayed.
	 */
	NSLog(@"MusicKit Error: %@\n", msg);
    }
}

- initCharsPanel
{
    int i, j;
    char s[2];
    s[0] = 32;
    s[1] = '\0';
    [(NSPanel *)[charmatrix window] setBecomesKeyOnlyIfNeeded:YES];
    [(NSPanel *)[charmatrix window] setFloatingPanel:YES];
    for (i = 0; i < 14; i++)
    {
	for (j = 0; j < 16; j++)
	{
	    [[charmatrix cellAtRow:i column:j] setTitle:[NSString stringWithUTF8String:s]];
	    s[0]++;
	}
    }
    return self;
}


/* Check for files to open specified on the command line. */


- (void) applicationDidFinishLaunching: (NSNotification *) notification
{
//  NSApplication *theApplication = [notification object];
    
    MKSetErrorProc(handleMKError); // TODO this needs updating to latest MK error handling delegate messages.
    
//sb: The following is for reading old runners. Not used for new documents.
#if 0 // TODO LMS: Commented this out until we find a means to fake NSCStringText out
    [NSCStringText registerDirective:@"TextVarCell" forClass:[TextVarCell class]];
#endif

    [(NSPanel *)[tools window] setBecomesKeyOnlyIfNeeded: YES];
    [(NSPanel *)[toolsH window] setBecomesKeyOnlyIfNeeded: YES];
    [(NSPanel *)[tools window] setFloatingPanel: YES];
    [(NSPanel *)[toolsH window] setFloatingPanel: YES];
    /* [[perfInspector window] setFloatingPanel:YES]; */
    if ([appdefaults checkOpenPanel: 0]) [[tools window] orderFront: self];
    if ([appdefaults checkOpenPanel: 1]) [[toolsH window] orderFront: self];
    // if ([appdefaults checkOpenPanel: 2]) [self orderNewPanel: self];
    [self initCharsPanel];
//  [[[NSFontManager sharedFontManager] fontPanel:YES] setAccessoryView: fontAccessory];
    // Is this necessary? Only if fontAccessory points to a special font selection?
    [[NSFontPanel sharedFontPanel] setAccessoryView: fontAccessory];
    
#ifdef WIN32
    [MenuBar setMenu: [NSApp mainMenu]];
    [MenuBar orderFront];
#endif
}


#if 0
/* Automatic update methods */

- (BOOL)validateMenuItem:(NSMenuItem *)menuCell
{
    
    SEL action = [menuCell action];
    if (action == @selector(saveAll:) || ([menuCell tag] == 26) ) {
        return findDocument(nil) ? YES : NO;
    }
    
    return YES;
}
#endif


// All of the tool methods should be factored into their own class.
/*
 Set and reset the current tool (an integer). 
 */
struct toolData toolCodes[NUMTOOLS] =
{
    {2,	0,		0,	0},		/* 0 arrow */
    {0,	100,		0,	0},		/* 1 paste (1000) */
    {0,	102,		0,	0},		/* 2 staff (1002) */
    {0,	BRACKET,	0,	1},		/* 3 bracket */
    {0,	KEY,		0,	2},		/* 4 keysig */
    {0,	TIMESIG,	0,	2},		/* 5 timesig */
    {0,	CLEF,		0,	2},		/* 6 clef */
    {0,	BLOCK,		0,	2},		/* 7 block */
    {0,	RANGE,		0,	2},		/* 8 range */
    {0,	TEXTBOX,	TITLE,	1},		/* 9 sys header */
    {1,	TEXTBOX,	LABEL,	0},		/* 10 text label */
    {0,	TEXTBOX,	STAFFHEAD, 1},		/* 11 staff header */
    {1,	TUPLE,		0,	0},		/* 12 tuple */
    {1,	BEAM,		0,	0},		/* 13 beam */
    {1,	BEAM,		2,	0},		/* 14 tremolo */
    {1,	TIENEW,		0,	0},		/* 15 tie */
    {1,	GROUP,		0,	0},		/* 16 notegroup */
    {1,	ENCLOSURE,	0,	0},		/* 17 enclosure */
    {0,	BARLINE,	0,	2},		/* 18 barline */
    {0,	101,		0,	0},		/* 19 add note */
    {1,	GROUP,		4,	0},		/* 20 notegroup (arpeggio) */
    {1,	ACCENT,		0,	0},		/* 21 accent */
    {1,	METRO,		0,	0},		/* 22 metro */
    {1,	GROUP,		15,	0},		/* 23 notegroup(volta) */
    {0,	NEUMENEW,	0,	2},		/* 24 neume 1 */
    {0,	NEUMENEW,	4,	2},		/* 25 neume 2 */
    {0,	NEUMENEW,	8,	2},		/* 26 neume 3 */
    {0,	NOTE,		7,	2},		/* 27 whole note */
    {0,	REST,		7,	2},		/* 28 whole rest */
    {0,	TABLATURE,	7,	2},		/* 29 whole tab */
    {0,	NOTE,		6,	2},		/* 30 half note */
    {0,	REST,		6,	2},		/* 31 half rest */
    {0,	TABLATURE,	6,	2},		/* 32 half tab */
    {0,	NOTE,		5,	2},		/* 33 quarter note */
    {0,	REST,		5,	2},		/* 34 quarter rest */
    {0,	TABLATURE,	5,	2},		/* 35 quarter tab */
    {0,	NOTE,		4, 	2},		/* 36 eighth note */
    {0,	REST,		4,	2},		/* 37 eighth rest */
    {0,	TABLATURE,	4,	2},		/* 38 eighth tab */
    {0,	NOTE,		3,	2},		/* 39 16th note */
    {0,	REST,		3,	2},		/* 40 16th rest */
    {0,	TABLATURE,	3,	2},		/* 41 16th tab */
    {0,	NOTE,		2,	2},		/* 42 32nd note */
    {0,	REST,		2,	2},		/* 43 32nd rest */
    {0,	TABLATURE,	2,	2},		/* 44 32nd tab */
    {0,	SQUARENOTE,	0,	2},		/* 45 square */
    {0,	SQUARENOTE,	1,	2},		/* 46 maxima */
    {0,	SQUARENOTE,	2,	2},		/* 47 oblique */
    {1,	TIENEW,		1,	0},		/* 48 slur */
    {1,	LIGATURE,	1,	0},		/* 49 ligature */
    {1,	GROUP,		12,	0}		/* 50 notegroup (cresc) */
};


/* should return cursor depending on currentTool */

+ cursor
{
    return (toolCodes[currentTool].press) ? [NSCursor arrowCursor] : [Graphic cursor];
}


/* target of the Tools panels */
- setCurrentTool: sender
{
    OpusDocument *currdoc = documentInWindow([NSApp mainWindow]);
    id sel = [sender selectedCell];
    int flags = [sel mouseDownFlags];
    
    currentTool = [sel tag];
    if (flags & NSCommandKeyMask) { // Command clicked the tool.
	id inspectorClass = [Graphic getInspector: toolCodes[currentTool].type];
	
	if (inspectorClass == nil) 
	    NSLog(@"setCurrentTool: inspectorClass is nil");
	else {
	    id p = [self getInspectorForClass: inspectorClass loadInspector: YES];
	    
	    if (p) {
		[p makeKeyAndOrderFront:self];
		[p presetTo: toolCodes[currentTool].arg1];
	    }
	    else 
		NSLog(@"Couldn't find inspector\n");
	}
	[self resetTool];
    }
    else {
	if (toolCodes[currentTool].press != 1) 
	    [currdoc resetCursor];
	else {
	    [[currdoc graphicView] pressTool: toolCodes[currentTool].type withArgument: toolCodes[currentTool].arg1];
	    [self resetTool];
	}
    }
    return self;
}


/* target of the Menu tools */
- setToolByMenu: sender
{
    OpusDocument *currdoc = documentInWindow([NSApp mainWindow]);
    
    currentTool = [[sender selectedCell] tag];
    if (toolCodes[currentTool].press != 1) 
	[currdoc resetCursor];
    else {
	[[currdoc graphicView] pressTool: toolCodes[currentTool].type withArgument: toolCodes[currentTool].arg1];
	[self resetTool];
    }
    return self;
}


- resetToolTo: (int) t
{
    [tools selectCellWithTag: t];
    [toolsH selectCellWithTag: t];
    currentTool = t;
    [documentInWindow([NSApp mainWindow]) resetCursor];
//  [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil];
//  [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return self;
}


- resetTool
{
    return [self resetToolTo: 0]; 
} 


// TODO should become +currentSystem?
- currentSystem
{
    return [[documentInWindow([NSApp mainWindow]) graphicView] currentSystem];
    // TODO should become: [[[[NSDocumentController sharedDocumentController] currentDocument] graphicView] currentSystem]
}


- pressCharacter: sender
{
    [documentInWindow([NSApp mainWindow]) sendCharacter: ([sender selectedRow] + 2) * 16 + [sender selectedColumn]];
//    [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil];
//    [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return self;
}

@end
