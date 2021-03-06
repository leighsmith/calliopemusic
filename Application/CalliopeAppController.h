/*!
  $Id$

  @class CalliopeAppController
  @brief Handles opening of new documents and other application wide activity.

  This class is used primarily to handle the opening of new documents
  and other application-wide activity (such as responding to messages from
  the tool palette).  It listens for requests from the Workspace Manager
  to open a draw-format file as well as target/action messages from the
  New and Open... menu items.  It also keeps the menus in sync by
  fielding the menu items' updateActions.
 */
#import "winheaders.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSSavePanel.h>
#import "CallPageLayout.h"
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>
#import "OpusDocument.h"

@interface CalliopeAppController : NSObject
{
    IBOutlet NSMatrix *tools;			/* the vertical Tool Palette matrix */
    IBOutlet NSMatrix *toolsH;			/* the horizontal Tool Palette matrix */
    IBOutlet id infoPanel;		/* the Info... panel */
    IBOutlet id version;			/* the version field in the Info... panel */
    IBOutlet id preferences;		/* the Preferences Panel */
    id fontAccessory;
    id fontAccMatrix;
    id inspector;		/* inspectors loaded into here */
    NSMutableArray *insplist;		/*    but collected here */
    id laybarInspector;
    id perfInspector;
    id toneTools;
    id tabTuner;		/* the tablature tuning panel */
    id castInspector;
    id appdefaults;		/* application Defaults panel */
    id tempoSlider;
    id tempoText;
    id laybarform;		/* the form in the layBarsPanel */
    id voiceInspector;
    IBOutlet NSMatrix *charmatrix;		/* the Characters panel matrix */
    
    BOOL haveOpenedDoc;		/* whether we have opened a document */
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

- selectFontSelection: (int) i;

+ (CalliopeAppController *) sharedApplicationController;

+ (OpusDocument *) currentDocument;
+ (GraphicView *) currentView;

- currentSystem;
- (NSString *) currentDirectory;
- print:sender; /* brought to app level by sb; originally only in graphicView.m */
- getInspectorForClass: (Class) c loadInspector: (BOOL) cmd;
- inspectApp;
- inspectAppWithMe: g loadInspector: (BOOL) launch : (int) fontseltype;
- inspectMe: g loadInspector: (BOOL) b;
- inspectClass: (Class) c loadInspector: (BOOL) cmd;
- resetTool;
- resetToolTo: (int) t;
- newPageLayout;
- pageLayout;
- savePanel : (NSString*) ext;
- (NSSavePanel *)mySavePanel;
- launchIt: p;
- (NSMutableArray *) getPartlist;
- (NSArray *) getChanlist;
- (NSMutableArray *) getStylelist;
- thePlayView;
- thePlayView: v;

// action methods.
- orderCastInspector: sender;
- orderPlayInspector: sender;
- orderVoiceInspector: sender;
- orderTabTuner: sender;
- orderAppDefPanel: sender;
- orderPreferencePanel: sender;

- thePlayInspector;
- (int) getLayBarNumber;
- presetPrefsPanel;
- inspectPreferences: (BOOL) b;
- thePreferences;
- (float)pointToCurrentUnitFactor;/* sb: added to get rid of convertOldFactor:newFactor: calls */
- (NSString *)unitString;
- (int)unitNum;

- setCurrentTool:sender;
- help:sender;
- info:sender;

/* Application delegate methods */
- (void) applicationDidFinishLaunching: (NSNotification *) notification;

/* Global cursor setting methods */
+ cursor;

@end



