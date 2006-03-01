#import "winheaders.h"
#import <AppKit/NSResponder.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSPageLayout.h>
#import <AppKit/NSMenuItem.h>
//#import <Foundation/NSCompatibility.h>
#import "PrefBlock.h"

/* Preferences Codes */

#define BARNUMSURROUND 0
#define BARNUMPLACE 1
#define TABCROTCHET 2
#define UNITS 3
#define BARNUMFIRST 4
#define BARNUMLAST 5
#define BARFONT 6
#define TABFONT 7
#define FIGFONT 8
#define TEXFONT 9
#define STAFFHEIGHT 10
#define STYLEPATH 11
#define MINSYSGAP 12
#define MAXBALGAP 13
#define USESTYLE 14
#define RUNFONT 15
#define BAREVERY 16

#define Notify(title, msg) NSRunAlertPanel(title, msg, @"OK", nil, nil)

@interface DrawDocument : NSDocument
{
@public
    id view;			/* the document's GraphicView */
    id window;			/* the window the GraphicView is in */
    id printInfo;
    id prefInfo;		/* the prefBlock */
    NSString *name;			/* the name of the document */ //sb: FIXME need to check archiving of name and directory
    NSString *directory;		/* the directory it is in */
    BOOL haveSavedDocument;	/* whether document has associated disk file */
}

/* Very private instance method needed by factory methods */

- (BOOL)loadDocument:(NSData *)stream frameSize:(NSRect *)frame frameString: (NSString**) frameString;

/* Factory methods */

+ (void)initialize;
+ new;
+ newFromStream:(NSData *)stream;
+ newFromFile:(NSString *)file andDisplay: (BOOL) d;

/* Public methods */

- newFrom;
- (void)dealloc;
- initCopy: (NSString *) name andDirectory: (NSString *) dir;
- printInfo;
- resetScrollers;
- gview;
- changeSize: (float) width : (float) height : (NSPoint)origin;

/* Target/Action methods */

- changeLayout:sender;
- (id) save:sender;
- saveAs:sender;
- revertToSaved:sender;
- showTextRuler:sender;
- hideRuler:sender;

/* Document name and file handling methods */

- (NSString *) askForFile: (NSString *) ext;
- (NSString *)filename;
- (NSString *)directory;
- (NSString *)name;
- setName:(NSString *)name andDirectory:(NSString *)directory;
- setName:(NSString *)name;
- save;
- (BOOL)needsSaving;
- (int) getPreferenceAsInt: (int) i;
- (float) getPreferenceAsFloat: (int) i;
- (NSFont *) getPreferenceAsFont: (int) i;
- setPreferenceAsInt: (int) v at: (int) i;
- prefInfo;
- installPrefInfo: (PrefBlock *) p;
- (NSSize)paperSize;
- zeroScale;
- useViewScale;
- (float) viewScale;
- (float) staffScale;

/* Services menu methods */

- registerForServicesMenu;
- validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType;
- writeSelectionToPasteboard:pboard types:(NSArray *)types;

/* Window delegate methods */

- windowWillClose:sender action:(NSString *)action;

- (BOOL)windowShouldClose:(id)sender;

- (void)windowDidBecomeMain:(NSNotification *)notification;
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)size;

/* Menu command validation method */

- (BOOL)validateMenuItem:(NSMenuItem *)menuCell;

/* Cursor setting */

- resetCursor;
- sendCharacter: (int) c;

@end

