#import "DrawApp.h"
#import "DrawDocument.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVSelection.h"
#import "Graphic.h"
#import "TextGraphic.h"
#import "CastInspector.h"
#import "PlayInspector.h"
#import "ProgressPanel.h"
#import "SysInspector.h"
#import "TextVarCell.h"
#import "AppDefaults.h"
#import "Preferences.h"
#import "LayBarInspector.h"
#import "draw.h"
#import "mux.h"
#import "muxlow.h"
//#include <sys/types.h>
//#include <pwd.h>
#import <AppKit/AppKit.h>


#if defined (WIN32)
#import <AppKit/obsoleteNSCStringText.h>
#elif defined (__APPLE__)
#import <AppKit/obsoleteNSCStringText.h>
#import <MusicKit/MusicKit.h>
#else
#import <MusicKit/MusicKit.h>
#include <libc.h>
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
const int DrawVersion = (NS_VERSION * 1000) + 1128; /* version of the program */ /*sb: bumped up from 1028 to 1128 */

int currentTool = 0;		/* the current tool number */
int escapedTool = 0;		/* the escaped tool */
int needUpgrade = 0;		/* whether to call upgrade */
GraphicView *playView = nil;

extern void muxlowInit();
extern int fontflag;

@implementation DrawApp : NSApplication

NSModalSession alertSession;

/*
 * This class is used primarily to handle the opening of new documents
 * and other application-wide activity (such as responding to messages from
 * the tool palette).  It listens for requests from the Workspace Manager
 * to open a draw-format file as well as target/action messages from the
 * New and Open... menu items.  It also keeps the menus in sync by
 * fielding the menu items' updateActions.
 */

- init
{
    if ((self = [super init])) {
        [self setDelegate:self]; // so that we get NSApp delegation methods
        currentWindow = nil;
        cpl = nil;
    }
    return self;
}

- (void) setCurrentWindow:(id)w
{
    currentWindow = w;
}
- (NSWindow *) currentWindow
{
    return currentWindow;
}

/* Private C functions used to implement methods in this class. */


/*
 * Checks to see if the passed window's delegate is a DrawDocument.
 * If it is, it returns that document, otherwise it returns nil.
 */
 
static id documentInWindow(id window)
{
    id document;
    if (!window) {
        return nil;
    }
    document = [window delegate];
  return [document isKindOfClass:[DrawDocument class]] ? document : nil;
}


/*
 * Searches the window list looking for a DrawDocument with the specified name.
 * Returns the window containing the document if found.
 * If name == NULL then the first document found is returned.
 */
 
static id findDocument(NSString *name)
{
  int count;
    id document, window, windowList;
    windowList = [NSApp windows];
    count = [windowList count];
  while (count--)
  {
      window = [windowList objectAtIndex:count];
    document = documentInWindow(window);
    if (document && (!name || [[document filename] isEqualToString:name])) return window;
  }
  return nil;
}


/*
 * Opens a file with the given name in the specified directory.
 * If we already have that file open, it is ordered front.
 * Returns the document if successful, nil otherwise.
 */

static DrawDocument *openFile(NSString *theDirectory, NSString *theName, BOOL display)
{
  id window;
  NSString *directory,*path;
  if (theName)
  {
    if (!theDirectory)
    {
      directory = @".";
    }
    else if (![theDirectory isAbsolutePath])
    {
      directory = [@"./" stringByAppendingString:theDirectory];
    }
      else directory = theDirectory;
      
    if ([[NSFileManager defaultManager] changeCurrentDirectoryPath:directory])
    {
      path = [directory stringByAppendingPathComponent:theName];
      window = findDocument(path);
      if (window)
      {
	 if (display) [window makeKeyAndOrderFront:window];
	 return [window delegate];
      }
      else
      {
          return [DrawDocument newFromFile: path andDisplay: display];
      }
    }
    else
    {
      NSRunAlertPanel(@"Open", @"Invalid path: %s", @"OK", nil, nil, directory);
    }
  }
  return nil;
}


static DrawDocument *openDocument(NSString *document, BOOL display)
{
    if ([[document pathExtension] isEqualToString:FILE_EXT])
        return openFile([document stringByDeletingLastPathComponent],[document lastPathComponent], display);
    if ([[document pathExtension] isEqualToString:BACKUP_EXT])
        return [NSApp openCopyOf: document reDirect: [document stringByDeletingLastPathComponent]];
    return openFile([document stringByDeletingLastPathComponent],[[document lastPathComponent] stringByAppendingPathExtension:FILE_EXT], display);

}

/* force a nid to be associated with a particular font */

static void jamFont(int nid, NSString *name, float s, NSString *fv)
{
    int e = 0;
    NSString *v;
  NSFont *f = fontdata[nid] = [NSFont fontWithName:name size:s];

  if (!f) NSRunAlertPanel(@"Calliope", @"Cannot find font: %@", @"OK", nil, nil, name);

  if (f != nil)
  {
    if (fv)
    {
        v = [[f afmDictionary] objectForKey:NSAFMVersion];
        if (![fv isEqualToString:v])
      {
          NSRunAlertPanel(@"Calliope", @"You need to install a newer version of the Calliope font", @"OK", NULL, NULL, name);
        e = 1;
      }
    }
  }
  else
  {
      NSRunAlertPanel(@"Calliope", @"Font: %s not installed", @"OK", NULL, NULL, name);
    e = 1;
  }
  if (e) exit(1);

}


static void initFonts()
{
  int i;
  for (i = 0; i < NUMCALFONTS; i++) fontdata[i] = nil;
  jamFont(FONTSON,  @"Sonata",      32.0, nil);
  jamFont(FONTSSON, @"Sonata",      24.0, nil);
  jamFont(FONTHSON, @"Sonata",      16.0, nil);
  jamFont(FONTMUS,  @"Calliope",    32.0, FONT_VERSION);
  jamFont(FONTSMUS, @"Calliope",    24.0, FONT_VERSION);
  jamFont(FONTHMUS, @"Calliope",    16.0, FONT_VERSION);
  jamFont(FONTTEXT, @"Times-Roman", 18.0, nil);
  jamFont(FONTSTMR, @"Times-Roman", 16.0, nil);
  [[NSFontManager sharedFontManager] setSelectedFont:fontdata[FONTTEXT] isMultiple:NO];
}

+ (void)initialize
{
if (self == [DrawApp class])
  {
  
  }
    return;
}


/*
 * PSInit() defines all the PostScript defs we use (see draw.psw).
 * setAutoupdate:YES means that updateWindows will be called after
 * every event is processed (this is how we keep our inspector and
 * our menu items up to date).
   All other setup code goes here...right?
 */


extern colorInit(int i, NSColor * c);

+ (NSApplication *)sharedApplication
{
  NSAutoreleasePool *pool =[[NSAutoreleasePool alloc] init];
  DrawApp *a = [[DrawApp alloc] init]; // LMS this only exists for the duration of this method.
  [NSApplication sharedApplication];   // we ensure we are talking to the window server.
  PSInit();
  colorInit(0, [NSColor lightGrayColor]);
  colorInit(1, [NSColor blackColor]);
  colorInit(2, [NSColor darkGrayColor]);
  colorInit(3, [NSColor whiteColor]);
  colorInit(4, [NSColor darkGrayColor]);
  colorInit(5, [NSColor darkGrayColor]);
  colorInit(6, [NSColor lightGrayColor]);
  a->inspector = nil;
  a->insplist = [[NSMutableArray alloc] init];
  initFonts();
  muxlowInit();
  // LMS this makes no sense, a is only initialised within this method so this is a pointless exercise.
//  if (!(a->appdefaults))  [NSBundle loadNibNamed:@"AppDefaults.nib" owner:a];
  [a->appdefaults checkOpenFromFile];
  [pool release];
  return self;
}



/* General application status and information querying/modifying methods. */

- currentDocument
{
    /* every time a window becomes main, it should register itself as "currentWindow" here.
     * It's safer to do this like this, because it will remain "main" even when app is hidden.
     * this helps prevent PostScript problems caused by drawing images that rely on currentDocument
     * to request it for margins, for example.
     */
    if (currentWindow) return documentInWindow(currentWindow);
    return documentInWindow([self mainWindow]); /* last resort */
}

- document
{
    if (currentWindow) return documentInWindow(currentWindow);
    return documentInWindow([self mainWindow]);
}


- currentView
{
    return [[self currentDocument] gview];
}


- (NSString *)currentDirectory
{
    NSString *retval = [(DrawDocument *)[self currentDocument] directory];

//    if (!retval || !*retval) retval = [[[NSOpenPanel openPanel] directory] cString];
    //sb: changed the following to retrieve current directory from application rather than openpanel, which is no longer shared.
    if (!retval) retval = [[NSFileManager defaultManager] currentDirectoryPath];
    else if (![retval length]) retval = [[NSFileManager defaultManager] currentDirectoryPath];
    return retval;
}

- print:sender
{
    BOOL printSuccess;
    id doc = [self document];
    if (doc && ![[doc gview] isEmpty])
      {
        printSuccess = [[NSPrintOperation printOperationWithView:[doc gview]
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
  GraphicView *v = [self currentView];
  if (v == nil)
  {
    NSBeep();
    return self;
  }
  if ([self keyWindow] == [v window])
  {
    if ([v->slist count] == 0) [v setFontSelection: 3 : 0];
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
  if (!infoPanel)
  {
      if (![NSBundle loadNibNamed:@"InfoPanel.nib" owner:self])  {
          NSLog(@"Failed to load InfoPanel.nib");
          NSBeep();
          return nil;
      }
      [version setIntValue:DrawVersion];
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


- orderNewPanel: sender
{
  if (!newpanel)  [NSBundle loadNibNamed:@"NewPanel.nib" owner:self];
  [newpanel preset];
  [newpanel makeKeyAndOrderFront:self];
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


- orderLog: sender
{
  if (!processLog)  [NSBundle loadNibNamed:@"ProcessLog.nib" owner:self];
  [[processLog window] orderFront:self];
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


- inspectAppWithMe: g : (BOOL) launch : (int) fontseltype
{
  GraphicView *v;
  if (castInspector) [castInspector reflectSelection];
  if (perfInspector) [perfInspector reflectSelection];
  if (preferences) [preferences reflectSelection];
  [NSApp inspectClass: [SysInspector class] : NO];
  v = [self currentView];
  if (v != nil)
  {
    if ([v->slist count] > 0)
    {
      [v inspectSelWithMe: g : launch : fontseltype];
      [v setFontSelection: fontseltype : 0];
    }
    else
    {
      [v setFontSelection: 3 : 0];
    }
  }
//  [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
  return self;
}


- inspectApp
{
   return [self inspectAppWithMe: nil : NO : 0];
}


/* the progress panel */

- orderProgressPanel: sender
{
  if (!progressPanel)  [NSBundle loadNibNamed:@"ProgressPanel.nib" owner:self];
  [progressPanel setFloatingPanel:YES];
  if (progressPanel) [progressPanel preset];
  [progressPanel makeKeyAndOrderFront:self];
  return self;
}

- setProgressTitle: (NSString *) s
{
  [progressPanel setTitle:s];
  return progressPanel;
}


- setProgressRatio: (float) f
{
  return [progressPanel setRatio: f];
}

- takeDownProgress: sender
{
  [progressPanel orderOut:self];
  return self;
}


/*
  Given a Class, look for its inspector.
  Throw up the inspector for the given object (return nil if none)
  Load .nib file if necessary.  (Use NXBundles in future).
*/


- getInspector: c : (BOOL) cmd
{
    NSString *buff;
    id p = nil;
  int k = [insplist count];
  BOOL f = NO;
  while (k-- && !f)
  {
    p = [insplist objectAtIndex:k];
    if ([p class] == c) f = YES;
  }
  if (!f)
  {
    if (!cmd) return nil;
      buff = [NSString stringWithFormat:@"%@.nib",NSStringFromClass([c class])];
    inspector = nil;
    [NSBundle loadNibNamed:buff owner:self];
    p = inspector;
    if (!p) fprintf(stderr, "Cannot get named object %s\n", [buff cString]);
    else [(NSMutableArray *)insplist addObject: p];
  }
  return p;
}


/* if cmd, then force it to launch if it is not already visible */

- inspectClass: c : (BOOL) cmd
{
  id p = [self getInspector: c : cmd];
  if (cmd)
  {
    if (p) [self launchIt: p];
    else fprintf(stderr, "Couldn't find inspector\n");
  }
  else if (p && [p isVisible] && !([p respondsToSelector:@selector(isBusy)] && [p isBusy])) [p preset];
  return self;
}


- inspectMe: g : (BOOL) cmd
{
  id p;
  if ([g myInspector] == nil) return g;
  p = [self getInspector: [g myInspector] : cmd];
  if (cmd)
  {
    if (p) [self launchIt: p];
    else fprintf(stderr, "Couldn't find inspector\n");
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
  DrawDocument *d = [self currentDocument];
  if (d == nil) return scratchlist;
  if ([d gview] == nil) return scratchlist;
  return ((GraphicView *)[d gview])->partlist;
}


- (NSMutableArray *) getChanlist
{
  DrawDocument *d = [self currentDocument];
  if (d == nil) return nil;
  if ([d gview] == nil) return nil;
  return ((GraphicView *)[d gview])->chanlist;
}


- (NSMutableArray *) getStylelist
{
  DrawDocument *d = [self currentDocument];
  if (d == nil) return scrstylelist;
  if ([d gview] == nil) return nil;
  return ((GraphicView *)[d gview])->stylelist;
}


/* write in the log panel */

- log: (NSString *) str
{
  int len;
  long clock;
  struct tm *times;
  NSString *s;
  if (!processLog)  [NSBundle loadNibNamed:@"ProcessLog.nib" owner:self];
//  [[processLog window] setBecomeKeyOnlyIfNeeded: YES];
  len = [[processLog string] length];
  clock = time(0);
  times = localtime(&clock);
  s = [NSString stringWithFormat:@"%02d%02d%02d%02d%02d: %@",
    times->tm_year, times->tm_mon + 1, times->tm_mday,
    times->tm_hour, times->tm_min, str];
  [processLog replaceCharactersInRange:NSMakeRange(len,0) withString:s];
  [processLog scrollRangeToVisible:NSMakeRange(len,0)];
  [[processLog window] orderFront:self];
  return self;
}


- log: (NSString *) str : (float) f
{
    NSString *s = [NSString stringWithFormat:@"%@%f\n", str, f];
  return [self log: s];
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


/* called by openCopy and the New panel */

- (DrawDocument *) openCopyOf: (NSString *) fname reDirect: (NSString *) dir
{
  DrawDocument *doc = nil;
  doc = [DrawDocument newFromFile: fname andDisplay: YES];
  if (doc == nil) return nil;
  [doc initCopy: @"UNTITLED" andDirectory: dir];
//  [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
  return doc;
}


/* Called by pressing Open... */

- (void)open: sender
{
    int i;
    NSString *directory;
    NSArray *files;
    NSArray *drawType = [NSArray arrayWithObject:FILE_EXT];

    NSOpenPanel* openpanel = [NSOpenPanel openPanel];
    [openpanel setAllowsMultipleSelection:YES];
    directory = [(DrawDocument *)[self currentDocument] directory];
    if (directory && [directory isAbsolutePath]) [openpanel setDirectory:directory];
    else [openpanel setDirectory:[appdefaults getDefaultOpenPath]];

    if ([openpanel runModalForTypes:drawType] == NSOKButton)
      {
        files = [openpanel filenames];
        directory = [openpanel directory];
        i = [files count];
        while (i--)
          {
            haveOpenedDoc = openFile([[files objectAtIndex:i]
                stringByDeletingLastPathComponent],
                                     [[files objectAtIndex:i] lastPathComponent],
                                     YES) || haveOpenedDoc;
          }
      }
//  [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil];
//  [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
  return;
}


/* Called by pressing Open Copy... */

- (void)openCopy: sender
{
    NSString *directory;
    NSArray *files;
    NSArray *drawType = [NSArray arrayWithObject:FILE_EXT];
    int i;
  
    id openpanel = [NSOpenPanel openPanel];
    [openpanel setAllowsMultipleSelection:YES];
    directory = [(DrawDocument *)[self currentDocument] directory];
    if (directory) {
        if ([directory isAbsolutePath]) {
            [openpanel setDirectory:directory];
        } else directory = nil;
    }
    if (!directory) [openpanel setDirectory:[appdefaults getDefaultOpenPath]];
    if ([openpanel runModalForTypes:drawType] == NSOKButton)
      {
        files = [openpanel filenames];
        i = [files count];
        while (i--)
          {
            [self openCopyOf: (NSString *)[files objectAtIndex:i] reDirect: [NSApp currentDirectory]];
          }
      }
    return;
}


- saveAll:sender
/*
 * Saves all the documents.
 */
{
    int count;
    id window;

    count = [[self windows] count];
    while (count--) {
	window = [[self windows] objectAtIndex:count];
	[documentInWindow(window) save:self];
    }
//    [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return nil;
}


- (void)terminate:(id)sender
/*
 * Overridden to be sure all documents get an opportunity to be saved
 * before exiting the program.
 */
{
    int count, choice;
    id window, document;

    count = [[self windows] count];
    while (count--) {
	window = [[self windows] objectAtIndex:count];
 	document = [window delegate];
	if ([document respondsToSelector:@selector(needsSaving)] && [document needsSaving]) {
	    choice = NSRunAlertPanel(@"Quit", @"You have unsaved documents.", @"Review Unsaved", @"Quit Anyway", @"Cancel");
	    if (choice == NSAlertOtherReturn)  {
		return;
	    } else if (choice == NSAlertDefaultReturn) {
		count = [[self windows] count];
		while (count--) {
		    window = [[self windows] objectAtIndex:count];
		    document = [window delegate];
		    if ([document respondsToSelector:@selector(windowWillClose:action:)]) {
			if ([document windowWillClose:window action:@"Quit"]) {
			    [(NSWindow *)window close];
			} else {
			    return;
			}
		    }
		}
	    }
	    break;
	}
    }
  if (!appdefaults)  [NSBundle loadNibNamed:@"AppDefaults.nib" owner:self];
  [appdefaults checkSaveToFile];

    [super terminate:sender];

    return;
}
    
/*
 * Application object delegate methods.
 * Since we don't have an application delegate, messages that would
 * normally be sent there are sent to the Application object itself instead.
 */
#ifndef WIN32

static void handleMKError(NSString *msg)
{
    if (![MKConductor performanceThread]) { /* Not performing */
        if (!NSRunAlertPanel(@"MKError", msg, @"OK", nil, nil, NULL))
            return; //[NSApp terminate:NSApp];
    }
    else {  
	/* When we're performing in a separate thread, we can't bring
	   up a panel because the Application Kit is not thread-safe.
	   In fact, neither is standard IO. Therefore, we use write() to
	   stderr here, causing errors to appear on the console.
	   Note that we assume that the App is not also writing to stderr.

	   An alternative would be to use mach messaging to signal the
	   App thread that there's a panel to be displayed.
	 */
	int fd = stderr->_file;
	char *str = "MusicKit Error: ";
	write(fd,str,strlen(str));
	write(fd,[msg cString],strlen([msg cString]));
	str = "\n";
	write(fd,str,strlen(str));
    }
}
#endif


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
      [[charmatrix cellAtRow:i column:j] setTitle:[NSString stringWithCString:s]];
      s[0]++;
    }
  }
  return self;
}


/* Check for files to open specified on the command line. */
 

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
//  NSApplication *theApplication = [notification object];
    int i;
#ifndef WIN32
  MKSetErrorProc(handleMKError);
#endif
//sb: The following is for reading old runners. Not used for new documents.
  [NSCStringText registerDirective:@"TextVarCell" forClass:[TextVarCell class]];
  [(NSPanel *)[tools window] setBecomesKeyOnlyIfNeeded:YES];
  [(NSPanel *)[toolsH window] setBecomesKeyOnlyIfNeeded:YES];
  [(NSPanel *)[tools window] setFloatingPanel:YES];
  [(NSPanel *)[toolsH window] setFloatingPanel:YES];
  /* [[perfInspector window] setFloatingPanel:YES]; */
  if ([appdefaults checkOpenPanel: 0]) [[tools window] orderFront:self];
  if ([appdefaults checkOpenPanel: 1]) [[toolsH window] orderFront:self];
  if ([appdefaults checkOpenPanel: 2]) [self orderNewPanel: self];
  [self initCharsPanel];
//  [[[NSFontManager sharedFontManager] fontPanel:YES] setAccessoryView:fontAccessory];
  [[NSFontPanel sharedFontPanel] setAccessoryView:fontAccessory];

  for (i = 1; i < [[[NSProcessInfo processInfo] arguments] count]; i++) haveOpenedDoc = openDocument([[[NSProcessInfo processInfo] arguments] objectAtIndex:i], YES) || haveOpenedDoc;
#ifdef WIN32
  [MenuBar setMenu:[NSApp mainMenu]];
  [MenuBar orderFront];
#endif
}


/* when a user double clicks on an opus document */

- (int)application:sender openFile:(NSString *)path
{
    if ([path pathExtension] && ([[path pathExtension] isEqualToString:FILE_EXT] || [[path pathExtension] isEqualToString:BACKUP_EXT]))
      {
        if ([[path pathExtension] isEqualToString:BACKUP_EXT])
            Notify(@"Open...",
                   @"About to open backup file. File will be opened as UNTITLED, as backup files are liable to be overwritten if the non-backup version of the file is saved.");
        if (openDocument(path, YES))
          {
            haveOpenedDoc = YES;
            return YES;
          }
      }
    return NO;
}

/* Automatic update methods */

- (BOOL)validateMenuItem:(NSMenuItem *)menuCell
{

    SEL action = [menuCell action];
    if (action == @selector(saveAll:) || ([menuCell tag] == 26) ) {
        return findDocument(nil) ? YES : NO;
    }

    return YES;
}


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

- cursor
{
  return (toolCodes[currentTool].press) ? [NSCursor arrowCursor] : [Graphic cursor];
}


/* target of the Tools panels */

- setCurrentTool: sender
{
  DrawDocument *currdoc = documentInWindow([self mainWindow]);
  id sel = [sender selectedCell];
  int flags = [sel mouseDownFlags];
  id insp, p;
  currentTool = [sel tag];
  if (flags & NSCommandKeyMask)
  {
    insp = [Graphic getInspector: toolCodes[currentTool].type];
    if (insp == nil) NSBeep();
    else
    {
      p = [self getInspector: insp : YES];
      if (p)
      {
        [p makeKeyAndOrderFront:self];
	[p presetTo: toolCodes[currentTool].arg1];
      }
      else fprintf(stderr, "Couldn't find inspector\n");
    }
    [self resetTool];
  }
  else
  {
    if (toolCodes[currentTool].press != 1) [currdoc resetCursor];
    else
    {
      [[currdoc gview] pressTool: toolCodes[currentTool].type : toolCodes[currentTool].arg1];
      [self resetTool];
    }
  }
  return self;
}


/* target of the Menu tools */

- setToolByMenu: sender
{
  DrawDocument *currdoc = documentInWindow([self mainWindow]);
  currentTool = [[sender selectedCell] tag];
  if (toolCodes[currentTool].press != 1) [currdoc resetCursor];
  else
  {
    [[currdoc gview] pressTool: toolCodes[currentTool].type : toolCodes[currentTool].arg1];
    [self resetTool];
  }
  return self;
}


- resetToolTo: (int) t
{
  [tools selectCellWithTag:t];
  [toolsH selectCellWithTag:t];
  currentTool = t;
  [documentInWindow([self mainWindow]) resetCursor];
//  [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil];
//  [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
  return self;
}


- resetTool
{
  return [self resetToolTo: 0]; 
} 


- currentSystem
{
  return [[documentInWindow([self mainWindow]) gview] currentSystem];
}


- pressCharacter: sender
{
    [documentInWindow([self mainWindow]) sendCharacter: ([sender selectedRow] + 2) * 16 + [sender selectedColumn]];
//    [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil];
//    [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return self;
}

@end