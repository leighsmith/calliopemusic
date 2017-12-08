/*!
  $Id$

  @class OpusDocument
  @brief This class is used to keep track of an Opus (Calliope .opus) notation document.

  It acts as a Controller in the Model-View-Controller design pattern troika.
  In particular, it is responsible for managing document saved state, responsible for
  retrieving and saving documents to persistent store (load/saving files) and acting as
  a receiver and distributor of action messages from GUI views to the music notation score model.
  In future, it should be responsible for managing the various inspector windows.
 */

#import "winheaders.h"
#import <AppKit/AppKit.h>
#import "PrefBlock.h"
#import "PageScrollView.h"

/* Preferences Codes TODO should be in PrefBlock? */

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
@private
    /*! @var documentWindow The window the GraphicView is in. TODO: we should be able to remove this as we separate out the document from window controlling */
    NSWindow *documentWindow;
    /*! @var view The document's GraphicView */
    IBOutlet GraphicView *view;	
    /*! @var scrollView The view managing the scroll bars */
    IBOutlet PageScrollView *scrollView;
    /*! @var newDocumentSheet the New Document sheet */
    IBOutlet NSWindow *newDocumentSheet;

    // TODO There should actually be a model here! At the moment, GraphicView mixes the view and model. We should have
    // a model which holds the systems, the pages and other elements that define a written musical score, independent from
    // the view which is responsible for displaying them using the ApplicationKit.
    // NotationScore *score;

    // This is what is recovered from unarchiving the file. It is held independent from the ivar view to allow unarchiving hairy old GraphicView versions.
    GraphicView *archiveView;
    /*! @var printInfo TODO: I don't know why this has to be held, it's probably already inherited from NSDocument nowadays and could be removed. */
    NSPrintInfo *printInfo;
    /*! @var prefInfo The block of preferences specific to this document. TODO surely the preferences should be just the state within various class ivars. */
    PrefBlock *prefInfo;
    /*! @var name the name of the document */ //sb: FIXME need to check archiving of name and directory
    NSString *name;
    /*! @var directory the directory it is in */
    NSString *directory;
    /*! @var haveSavedDocument whether document has associated disk file TODO this should be part of NSDocument */
    BOOL haveSavedDocument;

    /*! @var frameString string naming the document frame TODO only part of old document retrieval. */
    NSString *frameString;
    /*! @var frameSize dimensions of the frame TODO only part of old document retrieval. */
    NSRect frameSize;
}

/*!
  @brief Loads a file of the type given by aType from the NSData instance data.
  @result Returns YES if it is able to load a Calliope data file of type aType.
 */
- (BOOL) readFromData: (NSData *) data ofType: (NSString *) aType error: (NSError *) inError;

/* Factory methods */

+ (void)initialize;

/*!
  @brief Generates a NSData representation of the type given by docType.
  @param docType The document type.
  @result Returns an NSData instance containing an XML encoded property list.
 */
- (NSData *) dataOfType: (NSString *) docType error: (NSError **) outError;

/* Public methods */

// TODO should become copyWithZone:
- newFrom;
- initCopy: (NSString *) name andDirectory: (NSString *) dir;

- printInfo;

- resetScrollers;

/*!
  @brief Returns the graphic view displaying this document.
 */
- (GraphicView *) graphicView;

- changeSize: (float) width : (float) height : (NSPoint)origin;

/* Target/Action methods */
- (IBAction) changeLayout: sender;
- (IBAction) showTextRuler: sender;
- (IBAction) hideRuler: sender;

/*!
  @brief Messaged when the new document parameters have been selected.
 */
- (IBAction) closeNewDocumentSheet: (id) sender;

// Display the new document sheet allowing users to choose the number of staves in the document.
- (void) showStaffSelectionSheet: (id) sender;


/* Action methods for updating the current page. */
- (IBAction) prevPage: sender;
- (IBAction) nextPage: sender;
- (IBAction) firstPage: sender;
- (IBAction) lastPage: sender;

/* Document name and file handling methods */
- (NSString *) filename;
- (NSString *) directory;
- (NSString *) name;
- setName: (NSString *) name andDirectory:(NSString *)directory;
- setName: (NSString *) name;

// TODO should just become pasteboard operations.
- (IBAction) saveEPS: sender;
- (IBAction) saveTIFF: sender;

// - (BOOL)needsSaving;

- (int) getPreferenceAsInt: (int) i;
- (float) getPreferenceAsFloat: (int) i;
- (NSFont *) getPreferenceAsFont: (int) i;
- (PrefBlock *) documentPreferences;
- (void) setDocumentPreferences: (PrefBlock *) p;

/*!
  @brief Assigns the number of staves in the document 
 */
- (void) setNumberOfStaves: (int) numOfStaves;

- (NSSize) paperSize;
- (void) zeroScale;
- useViewScale;
- (float) viewScale;
- (float) staffScale;

/* Services menu methods */

- registerForServicesMenu;
- validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType;
- writeSelectionToPasteboard:pboard types:(NSArray *)types;

/* Menu command validation method */
- (BOOL) validateMenuItem: (NSMenuItem *) menuCell;

/* Cursor setting */
- resetCursor;
- sendCharacter: (int) c;

/* Receive GraphicView delegate methods */
- (void) setMessage: (NSString *) message;
- (void) setPageNumber: (int) pageNumber;


- (NSString *) frameString;
- (NSRect) frameSize;

@end

