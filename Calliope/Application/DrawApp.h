#import "winheaders.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSSavePanel.h>
#import "CallPageLayout.h"
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>

@interface DrawApp : NSApplication
{
    id tools;			/* the vertical Tool Palette matrix */
    id toolsH;			/* the horizontal Tool Palette matrix */
    id infoPanel;		/* the Info... panel */
    id version;			/* the version field in the Info... panel */
    id preferences;		/* the Preferences Panel */
    id fontAccessory;
    id fontAccMatrix;
    id inspector;		/* inspectors loaded into here */
    id insplist;		/*    but collected here */
    id laybarInspector;
    id perfInspector;
    id toneTools;
    id tabTuner;		/* the tablature tuning panel */
    id castInspector;
    id appdefaults;		/* application Defaults panel */
    id newpanel;		/* the New panel */
    id tempoSlider;
    id tempoText;
    id laybarform;		/* the form in the layBarsPanel */
    id voiceInspector;
    id processLog;		/* a Text Object */
    id charmatrix;		/* the Characters panel matrix */
    id progressPanel;		/* the progress panel */
    BOOL haveOpenedDoc;		/* whether we have opened a document */
    id currentWindow;
    CallPageLayout *cpl;
    id MenuBar;			/* used for Windows only! */
}

#define FILE_EXT	@"opus"	/* default file extension */
#define BACKUP_EXT	@"opus~"	/* backup file extension */
#define NUMTOOLS 51

struct toolData
{
  char press, type, arg1, arg2;
};

extern int partlistflag;

/* Public methods */

+ (void)initialize;
+ (NSApplication *)sharedApplication;

- (NSWindow *)currentWindow;
- (void)setCurrentWindow:(id)w;//sb
- selectFontSelection: (int) i;
- currentDocument;
- document;
- currentView;
- currentSystem;
- (NSString *)currentDirectory;
- print:sender; /* brought to app level by sb; originally only in graphicView.m */
- getInspector: c : (BOOL) cmd;
- inspectApp;
- inspectAppWithMe: g : (BOOL) launch : (int) fontseltype;
- inspectMe: g : (BOOL) b;
- inspectClass: c : (BOOL) b;
- resetTool;
- resetToolTo: (int) t;
- newPageLayout;
- pageLayout;
- savePanel : (NSString*) ext;
- (NSSavePanel *)mySavePanel;
- launchIt: p;
- orderCastInspector: sender;
- getPartlist;
- getChanlist;
- getStylelist;
- thePlayView;
- thePlayView: v;
- orderPlayInspector: sender;
- orderVoiceInspector: sender;
- orderTabTuner: sender;
- thePlayInspector;
- (int) getLayBarNumber;
- presetPrefsPanel;
- inspectPreferences: (BOOL) b;
- thePreferences;
- orderPreferencePanel: sender;
- (float)pointToCurrentUnitFactor;/* sb: added to get rid of convertOldFactor:newFactor: calls */
- (NSString *)unitString;
- (int)unitNum;
- log: (NSString *) s;
- log: (NSString *) s : (float) f;
- orderProgressPanel: sender;
- setProgressTitle: (NSString *) s;
- setProgressRatio: (float) f;
- takeDownProgress: sender;

- openCopyOf: (NSString *) s reDirect: (NSString *) d;
- setCurrentTool:sender;
- help:sender;
- info:sender;
- (void)open:sender;
- (void)terminate:(id)sender;

/* Application delegate methods */

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (int)application:sender openFile:(NSString *)path;

/* Global cursor setting methods */

- cursor;

/* Menu updating method */

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem;

@end



