/* $Id$ */

/*!
  @class OpusDocument

  This class is used to keep track of an Opus (Calliope) notation document.
 */

#import "winheaders.h"
#import <AppKit/AppKit.h>
//#import <Foundation/NSCompatibility.h>
#import "PrefBlock.h"
#import "SyncScrollView.h"

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

@interface OpusDocument : NSDocument
{
@public
    /*! @var documentWindow the window the GraphicView is in. TODO: we should be able to remove this as we separate out the document from window controlling */
    NSWindow *documentWindow;
@protected
    /*! @var view the document's GraphicView */
    IBOutlet GraphicView *view;	
    /*! @var scrollView The view managing the scroll bars */
    IBOutlet SyncScrollView *scrollView;
@private
    /*! @var printInfo TODO: I don't know why this has to be held, it's probably already inherited from NSDocument nowadays */
    NSPrintInfo *printInfo;
    /*! @var prefInfo the prefBlock */
    PrefBlock *prefInfo;
    /*! @var name the name of the document */ //sb: FIXME need to check archiving of name and directory
    NSString *name;
    /*! @var directory the directory it is in */
    NSString *directory;
    /*! @var haveSavedDocument whether document has associated disk file */
    BOOL haveSavedDocument;
    /*! @var frameString string naming the document frame */
    NSString *frameString;
    /*! @var frameSize dimensions of the frame */
    NSRect frameSize;
}

/*!
  @method loadDataRepresentation:ofType: 
  @discussion Loads a file of the type given by aType from the NSData instance data.
  @result Returns YES if it is able to load a Calliope data file of type aType.
 */
- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) aType;

/* Factory methods */

+ (void)initialize;
//+ new;
+ newFromStream:(NSData *)stream;
+ newFromFile:(NSString *)file andDisplay: (BOOL) d;


/*!
  @method dataRepresentationOfType:
  @abstract Generates a NSData representation of the type given by docType.
  @param docType The document type.
  @result Returns an NSData instance containing an XML encoded property list.
 */
- (NSData *) dataRepresentationOfType: (NSString *) docType;


/* Public methods */

- newFrom;
- (void)dealloc;
- initCopy: (NSString *) name andDirectory: (NSString *) dir;
- printInfo;
- resetScrollers;
- (GraphicView *) graphicView;
- changeSize: (float) width : (float) height : (NSPoint)origin;

/* Target/Action methods */

- changeLayout:sender;
#if 0
- (id) save:sender;
- saveAs:sender;
- revertToSaved:sender;
#endif
- showTextRuler:sender;
- hideRuler:sender;

/* Document name and file handling methods */

// - (NSString *) askForFile: (NSString *) ext;
- (NSString *)filename;
- (NSString *)directory;
- (NSString *)name;
- setName: (NSString *) name andDirectory:(NSString *)directory;
- setName: (NSString *) name;
- save;
// - (BOOL)needsSaving;
- (int) getPreferenceAsInt: (int) i;
- (float) getPreferenceAsFloat: (int) i;
- (NSFont *) getPreferenceAsFont: (int) i;
- setPreferenceAsInt: (int) v at: (int) i;
- prefInfo;
- installPrefInfo: (PrefBlock *) p;

/*!
  @brief Assigns the number of staves in the document 
 */
- (void) setNumberOfStaves: (int) numOfStaves;
- (NSSize)paperSize;
- (void) zeroScale;
- useViewScale;
- (float) viewScale;
- (float) staffScale;

/* Services menu methods */

- registerForServicesMenu;
- validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType;
- writeSelectionToPasteboard:pboard types:(NSArray *)types;

/* Window delegate methods */
#if 0
- windowWillClose:sender action:(NSString *)action;

- (BOOL)windowShouldClose:(id)sender;

- (void)windowDidBecomeMain:(NSNotification *)notification;
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)size;
#endif

/* Menu command validation method */

- (BOOL)validateMenuItem:(NSMenuItem *)menuCell;

/* Cursor setting */

- resetCursor;
- sendCharacter: (int) c;

/* Receive GraphicView delegate methods */
- (void) setMessage: (NSString *) message;
- (void) setPageNum: (int) pageNumber;

- (NSString *) frameString;
- (NSRect) frameSize;

@end

