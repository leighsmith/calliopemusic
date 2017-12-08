/* $Id: OpusDocument.m 67 2006-03-25 19:12:10Z leighsmith $ */
#import <AppKit/AppKit.h>
#import <Foundation/NSArray.h>
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>
#import "OpusDocument.h"
#import "CalliopeAppController.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVSelection.h"
#import "GVCommands.h"
#import "GVScore.h"
#import "PageScrollView.h"
#import "Page.h"
#import "System.h"
#import "CallPageLayout.h"
#import "DrawingFunctions.h"
#import "CalliopeWindow.h"

extern NSColor * backShade;

@implementation OpusDocument

#define DOC_VERSION 3  /*sb: bumped up from 2 for OS conversion. Reading old formats now more difficult. Must used mixed object graphs. */

/*
 margins are stored here.  All margins are in units of points,
 and are converted when read.
 Whenever margins change, the systems need to be recalc'd.
 */

#define MIN_WINDOW_WIDTH 50.0
#define MIN_WINDOW_HEIGHT 75.0
#define SCROLLVIEW_BORDER NSNoBorder

NSSize paperSize;


/*
 * Find the size of the chosen page.
 */

- (NSSize)paperSize
{
    return [printInfo paperSize];
}


/* note internal units are in points */

- setDefaultFormat
{
    if (prefInfo) prefInfo->staffheight = 21.259845; /* an even rastral number */
    
    if (printInfo) {
        [printInfo setLeftMargin:0];
        [printInfo setRightMargin:0];
        [printInfo setTopMargin:0];
        [printInfo setBottomMargin:0];
    }
    return self;
}


/*
 * Calculates the size of the window's contentView by accounting for the
 * existence of the ScrollView around the GraphicView.  No scrollers are
 * assumed since we are interested in the minimum size need to enclose
 * the entire view and, if the entire view is visible, we don't need
 * scroll bars!
 */

static void getContentSizeForView(id view, NSSize *contentSize)
{
    NSRect viewFrame;
    viewFrame = [view frame];
    *contentSize = [PageScrollView frameSizeForContentSize:viewFrame.size hasHorizontalScroller:YES hasVerticalScroller:YES borderType:SCROLLVIEW_BORDER];
}


#define WINDOW_MASK (NSLeftMouseUpMask|NSLeftMouseDraggedMask|NSFlagsChangedMask)


/*
 * Creates a window for the specified view.
 * If windowContentRect (r) is NULL, then a window big enough to fit the whole
 * view is created (unless that would be too big to comfortably fit on the
		    * screen, in which case a smaller window may be allocated).
 * If windowContentRect is not NULL, then it is used as the contentView of
 * the newly created window.
 *
 * setMiniwindowIcon: sets the name of the bitmap which will be used in
 * the miniwindow of the window (i.e. when the window is miniaturized).
 * The icon "drawdoc" was defined in InterfaceBuilder (take a look in
						       * the icon suitcase).
 */
/* sb: here I am creating a new, unflipped nsview to be the document view. This
* view has 1 subview -- the GraphicView. I need this unflipped view because I need
* to composite onto an unflipped view, in the replacement for instance drawing.
* doc->view will still contain the GraphicView, but will have this new superview.
*/
static id createWindowFor(GraphicView* view, NSRect *r, NSString *fS)
{
    NSSize screenSize;
    id sV;
    NSWindow *w;
    NSRect dr;
    if (!r)
    {
	r = &dr;
	getContentSizeForView(view, &r->size);
	screenSize = [[NSScreen mainScreen] frame].size;
	if (r->size.width > screenSize.width / 2.0)
	{
	    r->size.width = floor(screenSize.width / 2.0);
	}
	if (r->size.height > screenSize.height - 20.0)
	{
	    r->size.height = screenSize.height - 20.0;
	}
	r->origin.x = screenSize.width - 85.0 - r->size.width;
	r->origin.y = floor((screenSize.height - r->size.height) / 2.0);
    }
    
    w = [[CalliopeWindow allocWithZone:[view zone]]
	initWithContentRect:*r
		  styleMask:NSResizableWindowMask|(NSClosableWindowMask | NSMiniaturizableWindowMask)
		    backing:NSBackingStoreBuffered
		      defer:NO];
    if (fS) [w setFrameFromString:fS];
    sV = [[PageScrollView allocWithZone:[view zone]] initWithFrame:*r];
    [sV setHasVerticalScroller:YES];
    [sV setHasHorizontalScroller:YES];
    [sV setBorderType:SCROLLVIEW_BORDER];
    [sV setDocumentView:view];//sb: was just 'view' but I have changed it (see above)
	
	[w setContentView:sV];
	[w setBackgroundColor:backShade];
	
	[sV reflectScrolledClipView:[sV contentView]];
	[view setNeedsDisplay:YES];
	
	[w makeFirstResponder:view];
	[w setMiniwindowImage:[NSImage imageNamed:@"CallDocIcon"]];
	return w;
}


+ (void) initialize
{
    if (self == [OpusDocument class]) {
	[OpusDocument setVersion: DOC_VERSION];	/* class version, see read: */
    }
}

/*
 * Loads an archived document from the specified filename.
 */
- (BOOL) loadDocument: (NSData *) stream
{
    int version;
    char *s;
    float headerbase, footerbase, staffheight;
    volatile BOOL retval = YES;
    NSUnarchiver *ts = nil;
//  NS_DURING
    
    [NSUnarchiver decodeClassName: @"List" asClassName: @"ListDecodeFaker"];
    [NSUnarchiver decodeClassName: @"Font" asClassName: @"NSFont"];
    ts = [[NSUnarchiver alloc] initForReadingWithData: stream];
    if (ts)
    {
	[ts setObjectZone:(NSZone *)[self zone]];
	[ts decodeValuesOfObjCTypes:"i", &version];
	if (version == 1)
	{
	    [ts decodeValuesOfObjCTypes:"fff", &headerbase, &footerbase, &staffheight];
	    printInfo = [[ts decodeObject] retain];
	    prefInfo = [[ts decodeObject] retain];
	    [ts decodeValueOfObjCType:"*" at: &s];
	    frameString = [[NSString stringWithUTF8String: s] retain]; //sb: was strcpy(frameString, s);
	    free(s);
	    archiveView = [[ts decodeObject] retain];
	    prefInfo->staffheight = staffheight;
	    [Page setDefaultPaperSize: [self paperSize]]; // assign the default paper size when decoding old formats.
	    [archiveView updateMarginsWithHeader: headerbase footer: footerbase printInfo: printInfo];
	}
	else if (version == 2)
	{
	    NSSize checkSize;
	    printInfo = [[ts decodeObject] retain];
	    prefInfo= [[ts decodeObject] retain];
	    NSLog(@"Paper width %g height %g\n",
		  [[printInfo printer] pageSizeForPaper: [printInfo paperName]].width, 
		  [[printInfo printer] pageSizeForPaper: [printInfo paperName]].height);
	    checkSize = [printInfo paperSize];
	    if (NSEqualSizes(checkSize,NSZeroSize)) {
		checkSize = [[printInfo printer] pageSizeForPaper: [printInfo paperName]];
		[printInfo setPaperSize: checkSize];
		checkSize = [printInfo paperSize];
		NSLog(@"Check width %g height %g\n", checkSize.width, checkSize.height);
	    }
	    [ts decodeValueOfObjCType:"*" at:&s];
	    frameString = [[NSString stringWithUTF8String: s] retain]; //sb: was strcpy(frameString, s);
	    free(s);
	    [Page setDefaultPaperSize: [self paperSize]]; // assign the default paper size when decoding old formats.
	    archiveView = [[ts decodeObject] retain];
	}
	else if (version == DOC_VERSION)
	{
	    NSString *newS;
	    printInfo = [[ts decodeObject] retain];
	    prefInfo = [[ts decodeObject] retain];
	    newS = [ts decodeObject];
	    frameString = [newS retain]; //sb: was strcpy(frameString, s);
	    [Page setDefaultPaperSize: [self paperSize]]; // assign the default paper size when decoding old formats.
	    archiveView = [[ts decodeObject] retain];
	}
	else retval = NO;
    }
    else retval = NO;
//  NS_HANDLER
//    retval = NO;
//  NS_ENDHANDLER
    if (ts) [ts release];
    return retval;
}

- (BOOL) loadOldDocument: (NSData *) stream
{
    volatile BOOL retval = YES;
    NSUnarchiver *ts = NULL;
    PrefBlock *p;
    int oldsysk;
    char *fn;
    char anon;
    
    NSLog(@"NOTE: Loading Old Document format\n");
    oldsysk = [System oldSizeCount];
    [self setDefaultFormat];
    NS_DURING
	ts = [[NSUnarchiver alloc] initForReadingWithData:stream];
	if (ts)
	{
	    [ts setObjectZone:(NSZone *)[self zone]];
	    frameSize = [ts decodeRect];
	    archiveView = [[ts decodeObject] retain];
	    if (![ts isAtEnd])
	    {
		printInfo = [[ts decodeObject] retain];
		[ts decodeValuesOfObjCTypes:"*", &fn]; /* dummy */
		if (![ts isAtEnd])
		{
		    [ts decodeValuesOfObjCTypes:"cccc", &anon, &anon, &anon, &anon]; /* dummies */
		    if (![ts isAtEnd]) 
			prefInfo = [[ts decodeObject] retain];
		}
	    }
	}
	else
	    retval = NO;
    NS_HANDLER
	retval = NO;
    NS_ENDHANDLER
    if (ts) [ts release];
    if (!retval) return retval;
    if (!printInfo)
    {
	printInfo = [[NSPrintInfo alloc] init];
	[self setDefaultFormat];
    }
    if (prefInfo)
    {
	p = [prefInfo revert];
	if (p) [self setDocumentPreferences: p];
    }
    else prefInfo = [[PrefBlock alloc] init];
    /* old system margin format */
    if ([System oldSizeCount] - oldsysk)
    {
	float lm, rm, sh;
	[self setDefaultFormat];
	[System getOldSizes: &lm : &rm : &sh];
	prefInfo->staffheight = sh;
	[self zeroScale];
    }
    else [self useViewScale];

    return retval;
}

// used for reading. Uses loadDocument: and loadOldDocument: to load binary files.
// For applications targeted for Tiger or later systems, you should use the new Tiger API readFromData:ofType:error:.  In this case you can also choose to override -readFromURL:ofType:error: or -readFromFileWrapper:ofType:error: instead.
- (BOOL) readFromData: (NSData *) data ofType: (NSString *) aType error: (NSError *) inError
{
    NSLog(@"readFromData: Received type %@\n", aType);
    if([aType isEqualToString: @"Calliope Legacy Binary"]) {
	if(![self loadDocument: data]) {
	    // if unable to load the document normally, try the old versionless method.
	    if(![self loadOldDocument: data])
		return NO;
	}
	[archiveView firstPage: self];
	[self resetScrollers];
        if (![prefInfo checkStyleFromFile: view])
	    Notify(@"Preferences", @"Cannot Read Shared Style Sheet.");
	return YES;
    }
    else {
	// TODO load from XML music format.
	NSLog(@"Should be loading from XML music format!\n");
    }
    return NO;
}

// Override returning the nib file name of the document
// If you need to use a subclass of NSWindowController or if your document supports
// multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
- (NSString *) windowNibName
{
    return @"MusicNotationDocument";
}

/* Creation methods */

- (id) init
{
    self = [super init];
    if (self != nil) {
	printInfo = [[NSPrintInfo alloc] init];
	prefInfo = [[PrefBlock alloc] init];
	[self setDefaultFormat];
	paperSize = [self paperSize]; // TODO this is fudged, we either need to have a defaultPaperSize or it's an ivar.
#if 0
	documentWindow = createWindowFor(view, NULL, nil); // TODO must incorporate window setup here.
#endif
	[self setName: nil andDirectory: nil];
    }
    return self;
}

#if 0

/*
 * Creates a new document from what is in the passed stream.
 */

+ newFromStream:(NSData *)stream
{
//    NSZone *zone;
    NSRect contFrame = NSZeroRect;
    OpusDocument *doc;
//    zone = [self newZone];
    doc = [[[self class] alloc] init];
    [doc registerForServicesMenu];
    if (stream && [doc loadDocument: stream]) {
	NSString *frameString = [doc frameString];
	
        paperSize = [doc paperSize];
        doc->documentWindow = createWindowFor(doc->view, &contFrame, frameString);
        [(NSWindow *)doc->documentWindow setDelegate:doc];
	
        [doc->view firstPage:doc];
	
        [doc resetScrollers];
        if (![doc->prefInfo checkStyleFromFile: doc->view]) Notify(@"Preferences", @"Cannot Read Shared Style Sheet.");
        doc->haveSavedDocument = YES;
        return doc;
    }
    return nil;
}

/*
 * Opens an existing document from the specified file.
 if an upgrade in class shape is needed, needUpgrade coded as follows:
 bit 0 = 1 if Ties.
 bit 1 = 1 if Neumes.
 bit 2 = 1 if Margins.
 bit 3 = 1 if Parts/Insts
 */

extern int needUpgrade;

+ newFromFile:(NSString *)file andDisplay: (BOOL) d
{
    int want;
    NSData *s;
    OpusDocument *doc;
    
    s = [NSData dataWithContentsOfMappedFile: file];
    needUpgrade = 0;
    if (s) {
	doc = [self newFromStream: s];  /* try new format first */
	if (!doc)
	{
	    doc = [self newOldFromStream: s];
	}
	if (doc) {
	    [doc setName:file];
	    [doc->documentWindow disableFlushWindow];
	    if (d) [doc->documentWindow makeKeyAndOrderFront:doc];
	    
	    [doc->documentWindow enableFlushWindow];
	    
	    if (needUpgrade & 2) {
		NSRunAlertPanel(@"Open", @"File contains old version neumes. Must upgrade to new format", @"OK", nil, nil);
		[(GraphicView *)doc->view upgradeNeumes];
	    }
	    if (needUpgrade & 1) {
		want = NSRunAlertPanel(@"Open", @"File contains old version connectors.  Upgrade to new format?", @"YES", @"NO", nil);
		if (want == NSAlertDefaultReturn) [(GraphicView *)doc->view upgradeTies];
	    }
	    if (needUpgrade & 8) {
		NSRunAlertPanel(@"Open", @"File has old parts/instruments format.  Must upgrade.", @"OK", nil, nil);
		[(GraphicView *)doc->view upgradeParts];
	    }
	    if (needUpgrade & 4) {
		NSRunAlertPanel(@"Open", @"File contains old document format. Must upgrade to new format", @"OK", nil, nil);
		[doc->view paginate: self];
		[doc->view firstPage: self];
		[doc->view formatAll: self];
	    }
	}
	else {
	    Notify(@"Open Document", @"Read error.  Can't open file.");
	    [doc release];
	    return nil;
	}
	return doc;
    }
    return nil;
}
#endif

- (void) showStaffSelectionSheet: (id) sender
{
    [NSApp beginSheet: newDocumentSheet
       modalForWindow: documentWindow
	modalDelegate: self
       didEndSelector: @selector(didEndNewDocumentSheet:returnCode:contextInfo:)
	  contextInfo: nil];
    
    // Sheet is up, return processing to the event loop
}

- (IBAction) closeNewDocumentSheet: (id) sender
{
    [NSApp endSheet: newDocumentSheet];
}

- (void) didEndNewDocumentSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
    int numberOfStaves = 4;
    
    // Retrieve number of staves and call
    [self setNumberOfStaves: numberOfStaves];
    [sheet orderOut: self];
}

// TODO should become copyWithZone: 
- newFrom
{
//    NSZone *zone;
//    NSRect frameRect = NSZeroRect;
//    NSSize frameSize;
    OpusDocument *doc;
    GraphicView *v;
    // zone = [OpusDocument newZone];
    doc = [[[self class] alloc] init];
    [doc registerForServicesMenu];
    doc->printInfo = [[NSPrintInfo alloc] init];
    
    [printInfo setLeftMargin:0];
    [printInfo setRightMargin:0];
    [printInfo setTopMargin:0];
    [printInfo setBottomMargin:0];
    
//  [doc paperRect: &frameRect];
    doc->prefInfo = [prefInfo newFrom];

    // This shouldn't be necessary.
#if 0
    frameSize = [doc paperSize];
    frameRect.size = frameSize;

    doc->view = [[GraphicView allocWithZone:zone] initWithFrame:frameRect];
    [doc->view setScaleFactor: [view getScaleFactor]];
    doc->view->currentFont = view->currentFont;
#endif
    
    doc->documentWindow = createWindowFor(v, NULL, nil);
    [(NSWindow *)doc->documentWindow setDelegate:doc];
    
    [doc->view firstPage:doc];
    
    [doc setName: nil andDirectory: nil];
    doc->haveSavedDocument = NO;
    [doc useViewScale];
    return doc;
}

- (void) dealloc
{
    [printInfo release];
    printInfo = nil;
    [prefInfo release];
    prefInfo = nil;
    [documentWindow release];
    documentWindow = nil;
    [name release];
    name = nil;
    [directory release];
    directory = nil;
    [super dealloc];
}

/* used by openCopy and New... */

- initCopy: (NSString *) n andDirectory: (NSString *) dir
{
    name = [n retain];
    directory = [dir retain];
    [documentWindow setTitleWithRepresentedFilename:[self filename]];
    NSSetZoneName([self zone], [self filename]);
    haveSavedDocument = NO;
    return self;
}


- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ prefInfo %@", [super description], prefInfo];
}

/* Services menu support methods. */

/* Services menu registrar */


- registerForServicesMenu
{
    static BOOL registered = NO;
    NSArray *validSendTypes;
    
    if (!registered) {
	registered = YES;
	validSendTypes = [NSArray arrayWithObject: NSFilenamesPboardType];
	[NSApp registerServicesMenuSendTypes: validSendTypes returnTypes: nil];
    }
    return self;
}


/*
 * Services menu support.
 * We are a valid requestor if the send type is filename
 * and there is no return data from the request.
 */

- validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType
{
    if (haveSavedDocument && sendType) {
        if ([sendType isEqualToString:NSFilenamesPboardType]) {
            if (returnType) {
                if ([returnType isEqualToString:@""]) return self;
            } else return self;
        }
    }
    return nil;
}
//    return (haveSavedDocument && [sendType isEqualToString:NSFilenamesPboardType] && (!returnType || [returnType isEqualToString:@""])) ? self : nil;



- writeSelectionToPasteboard:pboard types:(NSArray *)types
    /*
     * Services menu support.
     * Here we are asked by the Services menu mechanism to supply
     * the filename (which we said we were a valid requestor for
		     * in the above method).
     */
{
//#warning StreamConversion: NSFilenamesPboardType used to be NXFilenamePboardType. Pasteboard data of type NSFilenamesPboardType will be an NSArray of NSString. Use 'setPropertyList:forType:' and 'propertyListForType:'
    int save;
    
    if (haveSavedDocument) {
        if (types)
            if ([types containsObject:NSFilenamesPboardType]) {
                if ([view isDirty]) {
                    save = NSRunAlertPanel(@"Service", @"Do you wish to save this document before your request is serviced?", @"Save", @"Don't Save", nil);
                    if (save == NSAlertDefaultReturn) [self saveDocument: self];
                }
                [pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
                [pboard setPropertyList:[NSArray arrayWithObject:[self filename]]  forType:NSFilenamesPboardType];
                return self;
            }
    }
        return nil;
}




/* sb: replaced the following with the preceding

if (haveSavedDocument) {
    while (types && *types)
	if ([[NSString stringWithUTF8String:*types] isEqualToString:NSFilenamesPboardType])
	    break;
	else types++;
    if (types && *types) {
	if ([view isDirty]) {
	    save = NSRunAlertPanel(@"Service", @"Do you wish to save this document before your request is serviced?", @"Save", @"Don't Save", nil);
	    if (save == NSAlertDefaultReturn) [self save];
	}
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
	[pboard writeType:NSFilenamesPboardType data:[[self filename] UTF8String] length:[[self filename] length]+1];
	return self;
    }
}

return nil;
}
*/

/* Handle various Preferences */


- printInfo
{
    return printInfo;
}

// TODO all these should be within the PrefBlock itself, so the accessor just retrieves:
// [[document documentPreferences] intValueAt: i];
- (int) getPreferenceAsInt: (int) i
{
    if (!prefInfo)
    {
	NSLog(@"PrefBlock missing!\n");
	return 0;
    }
    return [prefInfo intValueAt: i];
}


- (float) getPreferenceAsFloat: (int) i
{
    if (!prefInfo)
    {
	NSLog(@"PrefBlock missing!\n");
	return 0;
    }
    return [prefInfo floatValueAt: i];
}


- (NSFont *) getPreferenceAsFont: (int) i
{
    if (!prefInfo)
    {
	NSLog(@"PrefBlock missing!\n");
	return 0;
    }
    return [prefInfo fontValueAt: i];
}


- (PrefBlock *) documentPreferences
{
    return prefInfo;
}

- (void) setDocumentPreferences: (PrefBlock *) p
{
    if (prefInfo) [prefInfo release];
    prefInfo = [p retain];
}

#if 0
- loadImageFile:(const char *)file at:(const NSPoint *)p allowAlpha:(BOOL)alphaOk
    /*
     * Maps in the specified file and asks the view to load the PostScript in
     * from the resulting NXStream.  The PostScript image will be centered at
     * the point p (in the GraphicView's coordinate system).  This is called
     * from the icon-dragging mechanism (icons dragged from the Workspace into
					 * the document--see registerWindow).
     */
{
    NXStream *stream = NXMapFile(file, NX_READONLY);
    [view loadImageFromStream:stream at:p allowAlpha:alphaOk];
    NXClose(stream);
    return self;
}
#endif

/*
 * Checks to see if the new window size is too large.
 * Called whenever the page layout (either by user action or
 * by the opening or reverting of a file) is changed or
 * the user resizes the window.
 */

- resetScrollers
{
    NSSize conSize;
    NSRect conRect, winFrame;
    BOOL doRuler = NO;
    
    if (documentWindow) {
	winFrame = [documentWindow frame];
	conRect = [[documentWindow class] contentRectForFrameRect:winFrame styleMask:[documentWindow styleMask]];
	getContentSizeForView(view, &conSize);
	if ([scrollView rulersVisible])	{
	    conSize.height += [scrollView frame].size.height;
	    conSize.width += [scrollView frame].size.width;
	    doRuler = YES;
	}
	if (conRect.size.width >= conSize.width || conRect.size.height >= conSize.height) {
	    conSize.width = MIN(conRect.size.width, conSize.width);
	    conSize.height = MIN(conRect.size.height, conSize.height);
	    [documentWindow setContentSize:conSize];
	}
	[scrollView setPageNumber: [view getPageNum]];
	[scrollView setScaleNumber: [view getScaleNum]];
	if (doRuler) 
	    [scrollView updateRuler];
    }
    return self;
}


/* Returns the GraphicView associated with this document. */

- (GraphicView *) graphicView
{
    // return [[view retain] autorelease];
    return view;
}


/* Document format */


- (float) viewScale
{
    return [view getScaleFactor];
}


- (float) staffScale
{
    if (!prefInfo)
    {
	NSLog(@"staffScale cannot find prefBlock\n");
	return 1.0;
    }
    return (prefInfo->staffheight / 32.0);
}


/*
 initialise scales from old format files
 */
- (void) zeroScale
{
    float h, w, m;
    
    m = 1.0 / [self staffScale];
    w = paperSize.width;
    h = paperSize.height;
    [documentWindow disableFlushWindow];
    // TODO LMS I've disabled the resizing of these, since matching MacOS X guidelines, 
    // the user should set the size, which should set the scale of display, not the program.
    //[view setFrameSize: paperSize];
    //[view setBoundsSize: NSMakeSize(paperSize.width * m, paperSize.height * m)];
    [view setScaleFactor: 1.0];
    [self resetScrollers];
    [view setNeedsDisplay: YES];
    [documentWindow enableFlushWindow];
}

- useViewScale
{
    float h, w, ss, vs;
    
    w = paperSize.width;
    h = paperSize.height;
    ss = 1.0 / [self staffScale];
    vs = [view getScaleFactor];
    [documentWindow disableFlushWindow];
    [view setFrameSize:NSMakeSize(w * vs, h * vs)];
    [view setBoundsSize:NSMakeSize(w * ss, h * ss)];
    [self resetScrollers];
    [view setNeedsDisplay:YES];
    [documentWindow enableFlushWindow];
//  [documentWindow flushWindow];
    return documentWindow;
}

// frameSize should be removed entirely, if we need it, we should be asking view
- (NSRect) frameSize
{
    return frameSize;
}

- (NSString *) frameString
{
    return [[frameString retain] autorelease];
}

/*
 Resize the view.
 w and h come in multiplied by any desired change in scale
 */

- changeSize: (float) w : (float) h : (NSPoint)origin
    /* origin is the top left coordinate showing in the view */
{
    id theClipView = [scrollView contentView];
    NSRect initialRect;
    NSPoint initialPoint;
    [documentWindow disableFlushWindow];
    [view setFrameSize:(NSSize){w, h}];
    [self resetScrollers];
    initialRect = [theClipView bounds];
    initialPoint = [theClipView convertPoint:origin fromView:view];
    if (initialPoint.y < 0) initialPoint.y = 0;
    [theClipView setBoundsOrigin:initialPoint];
    [view setNeedsDisplay:YES];
    [documentWindow enableFlushWindow];
    return self;
}

- (void) setNumberOfStaves: (int) numOfStaves
{
    System *newSystem = [[System alloc] initWithStaveCount: numOfStaves onGraphicView: view];
    
    [newSystem initsys];  // [newSystem initWithSystem: [view currentSystem]];
    if (numOfStaves > 1) 
	[newSystem installLink]; // to what?
    [view addSystem: newSystem];
    [view setStaffScale: [self staffScale]]; // TODO perhaps should be elsewhere.
    [view renumSystems];
    [view doPaginate];
    [view renumPages];
    [view setRunnerTables];
    [view balancePages];
    [view firstPage: self]; // This was originally newPanel?
    [view setNeedsDisplay: YES];
}



/* Target/Action methods */

/*
 Puts up a PageLayout panel.  Document is repaginated to the new
 choices of paper size, margins, etc.
 */

- (IBAction) changeLayout:sender
{
    float w, h, ss, vs;
    NSSize opr = [self paperSize];
    CallPageLayout * pl;
    BOOL p;
    
#ifndef WIN32
    //this forces the page layout panel to use the units that we have defined in Calliope app preferences
    NSString * tempUnit = [[[NSUserDefaults standardUserDefaults] stringForKey:@"NSMeasurementUnit"] retain];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NSMeasurementUnit"];
    [[NSUserDefaults standardUserDefaults] setObject:[[CalliopeAppController sharedApplicationController] unitString]
                                              forKey:@"NSMeasurementUnit"];
    pl = [[CalliopeAppController sharedApplicationController] newPageLayout];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NSMeasurementUnit"];
    if (tempUnit)
        [[NSUserDefaults standardUserDefaults] setObject:tempUnit
                                                  forKey:@"NSMeasurementUnit"];
#else
    pl = [[CalliopeAppController sharedApplicationController] pageLayout];
#endif
    if ([pl runModalWithPrintInfo:printInfo] == NSOKButton)
    {
	paperSize = [self paperSize];
	p = (opr.width != paperSize.width || opr.height != paperSize.height);
	NSLog(@"%p\n",pl);
	if (p)
        {
	    w = paperSize.width;
	    h = paperSize.height;
	    ss = 1.0 / [self staffScale];
	    vs = [view getScaleFactor];
	    [view setFrameSize:NSMakeSize(w * vs, h * vs)];
	    [view setBoundsSize:NSMakeSize(w * ss, h * ss)];
	    [self resetScrollers];
	    [view recalcAllSys];
	    [view paginate: self];
        }
	[view dirty];
    }
    [[CalliopeAppController sharedApplicationController] inspectPreferences: NO];
}

- (IBAction) setScale: (id) sender
{	
    float i = [[sender selectedCell] tag];
    
    if (i == 127)
	i = 127.778;
    [scrollView setMessage: @""];
    [view scaleTo: i];
}

- (IBAction) saveEPS: sender
{
    [view deselectAll: view];
    [view setupGrabCursor: 1];
}


- (IBAction) saveTIFF: sender
{
    [view setupGrabCursor: 2];
}


- (IBAction) copyAsEPS: sender
{
    [view deselectAll: view];
    [view setupGrabCursor: 3];
}


- (IBAction) copyAsTIFF: sender
{
    [view setupGrabCursor: 4];
}



#if 0
- close:sender
{
    [documentWindow endEditingFor:self];
    [documentWindow performClose:self];
    return self;
}

/* save under a different name */

- saveAs:sender
{
    [view dirty];
    haveSavedDocument = NO;
    return [self save:sender];
}

/*
 * Revert the document back to what is on the disk.
 Note that reversion is always in new format!
 */ 

- revertToSaved:sender
{
    NSData *stream;
    if (haveSavedDocument && [view isDirty])
    {
	if (NSRunAlertPanel(@"Revert", @"%@ has been edited.  Are you sure you want to undo changes?", @"Revert", @"Cancel", nil, name) != NSAlertDefaultReturn)
	{
	    return self;
	}
    }
    [documentWindow endEditingFor:self];
//    stream = NXMapFile([[self filename] UTF8String], NX_READONLY);
    stream = [NSData dataWithContentsOfMappedFile:[self filename]];
    if (stream && [self loadDocument: stream])
    {
        [[[scrollView documentView] viewWithTag:1] autorelease];
        [[scrollView documentView] autorelease];
        [scrollView setDocumentView:view];
//      [self paperRect: &frame];
        paperSize = [self paperSize];
        [self useViewScale];
        [view firstPage: self];
        [documentWindow makeFirstResponder:view];
	if (![prefInfo checkStyleFromFile: view]) Notify(@"Preferences", @"Cannot read Shared Style Sheet.");
	[documentWindow setDocumentEdited:NO];
//      NXCloseMemory(stream, NX_FREEBUFFER);
    }
    else
    {
//      if (stream) NXCloseMemory(stream, NX_FREEBUFFER);
	Notify(@"Revert", @"I/O error.  Can't revert.");
    }
    return self;
}


- (NSData *) saveRect: (NSRect *) region ofType: (int) type
{
    NSString *file;
//  const char *types[4];
//  int length, maxlen;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
//  char *data;
//  NXStream *s;
    NSData *s;
    NSBitmapImageRep *bm;
    switch(type)
    {
	case 0:
	    return self;
	case 1:
	    file = [[CalliopeAppController currentDocument] askForFile: [NSString stringWithUTF8String:typeExts[type]]];
	    if (file)
	    {
		s = [self dataWithEPSInsideRect:*region];
		[s writeToFile:file atomically:YES];
	    }
		break;
	case 2:
	    file = [[CalliopeAppController currentDocument] askForFile: [NSString stringWithUTF8String:typeExts[type]]];
	    if (file)
	    {
		[self lockFocus];
		bm = [[NSBitmapImageRep alloc] initWithFocusedViewRect:*region];
		[self unlockFocus];
		s = [bm TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:TIFF_COMPRESSION_FACTOR];
		[bm release];
		[s writeToFile:file atomically:YES];
	    }
		break;
	case 3:
	    [pb declareTypes:[NSArray arrayWithObject:NSPostScriptPboardType] owner:[self class]];
	    s = [self dataWithEPSInsideRect:*region]; ;
	    [pb setData:s forType:NSPostScriptPboardType];
	    numPastes = 0;
	    break;
	case 4:
	    [pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:[self class]];
	    [self lockFocus];
	    bm = [[NSBitmapImageRep alloc] initWithFocusedViewRect:*region];
	    [self unlockFocus];
	    s = [bm TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:TIFF_COMPRESSION_FACTOR];
	    [bm release];
	    [pb setData:s forType:NSTIFFPboardType];
	    numPastes = 0;
	    break;
    }
    return self;
}

#endif

/*
 * Sent to cause the Text object ruler to be displayed.
 * Only does anything if the rulers are already visible.
 */

- (IBAction) showTextRuler: sender
{
    if ([scrollView rulersVisible]) {
	// [scrollView showHorizontalRuler:NO];
	[sender toggleRuler:sender];
    }
}


/*
 *sb: this can either be received from the menucell, or from someone else via
 * firstResponder. eg the fe.
 
 * If sender is nil, (eg fe) we assume the sender wants the
 * ruler hidden, otherwise, we toggle the ruler.
 * If sender is the field editor itself, we do nothing
 * (this allows the field editor to demand that the
    * ruler stay up).
 */

- (IBAction) hideRuler: sender
{
    id fieldEditor = [documentWindow fieldEditor:NO forObject:NSApp];
    
    if (!sender && [scrollView rulersVisible])
    {
        [fieldEditor toggleRuler:sender];
//        [scrollView toggleRuler:nil];//huh?
//    if ([scrollView verticalRulerIsVisible]) [scrollView showHorizontalRuler:YES];
        [scrollView resizeSubviewsWithOldSize:NSZeroSize];
        [scrollView setNeedsDisplay:YES];//sb
    }
    else if (sender)
    {
        [fieldEditor toggleRuler:sender];
        [scrollView showHideRulers:self];
#if 0 // TODO Disabled until we figure out why we attempt to toggle scrollView rulers? LMS
        if ([scrollView rulersVisible]) {
            if (![fieldEditor window]) [scrollView toggleRuler:nil];//huh?
        }
        else
            [scrollView toggleRuler:nil];//huh?
#endif
    }
//  [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
}


/* Methods related to naming/saving this document. */

/*
 * Gets the fully specified file name of the document.
 * If directory is NULL, then the currentDirectory is used.
 * If name is NULL, then the default title is used.
 */

- (NSString *)filename
{
    if (!directory && !name) [self setName:nil andDirectory:nil];
    return [directory stringByAppendingPathComponent:name];
}


- (NSString *)directory
{
    return directory;
}


- (NSString *)name
{
    return name;
}


/*
 * Updates the name and directory of the document.
 * newName or newDirectory can be nil, in which case the name or directory
 * will not be changed (unless one is currently not set, in which case
 * a default name will be used).
 //sb: FIXME I have not tried to allocate names in the same zone as the document. Need to do this!
 */
- setName:(NSString *)newName andDirectory:(NSString *)newDirectory
{
    if (!name && !newName) name = @"UNTITLED";
    else if (newName) {
        if (name) [name autorelease];
        name = [newName retain];
    }
    
    if (!directory && !newDirectory) 
	directory = @"."; // LMS TODO [[[CalliopeAppController sharedApplicationController] currentDirectory] retain];
    else {
        if (newDirectory) {
            if (directory) [directory autorelease];
            directory = [newDirectory retain];
        }
    }
    
    // [documentWindow setTitleWithRepresentedFilename:[self filename]];
    NSSetZoneName([self zone], [self filename]);
    
    return self;
}


- setName:(NSString *)file
    /*
     * If file is a full path name, then both the name and directory of the
     * document is updated appropriately, otherwise, only the name is changed.
     */
{
    if (file) {
        if ([file isAbsolutePath]) /*ie absolute path, or at least some path component */
            return [self setName:[file lastPathComponent] andDirectory:[file stringByDeletingLastPathComponent]];
        else return [self setName:file andDirectory:nil];
    }
    return self;
    
}

/*
 */

#define DEMOVERSION 0
+(BOOL)fileManager:(NSFileManager *)manager
      shouldProceedAfterError:(NSDictionary *)errorDict
{
    int result;
    result = NSRunAlertPanel(@"Calliope", @"File operation error:\n%@ with file: %@",
			     @"Proceed", @"Stop", NULL,
			     [errorDict objectForKey:@"Error"],
			     [errorDict objectForKey:@"Path"]);
    
    if (result == NSAlertDefaultReturn)
	return YES;
    else
	return NO;
}

// Used for writing
// For applications targeted for Tiger or later systems, you should use the new Tiger API -dataOfType:error:.  In this case you can also choose to override -writeToURL:ofType:error:, -fileWrapperOfType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
- (NSData *) dataOfType: (NSString *) docType error: (NSError **) outError
{
    NSLog(@"dataRepresentationOfType: %@", docType);

    if([docType isEqualToString: @"MusicKit Scorefile"]) {
	MKScore *fullScore = [view musicKitScore];
	NSMutableData *scorefileData = [[NSMutableData alloc] initWithCapacity: 0];
	
	[fullScore writeScorefileStream: scorefileData];
	return [scorefileData autorelease];
    }
    else if ([docType isEqualToString: @"Standard MIDI File"]) {
	MKScore *fullScore = [view musicKitScore];
	NSMutableData *scorefileData = [[NSMutableData alloc] initWithCapacity: 0];

	[fullScore writeMidifileStream: scorefileData];
	return [scorefileData autorelease];
    }
    else if ([docType isEqualToString: @"Calliope XML"]) {
	// int version = DOC_VERSION;
	OAPropertyListArchiver *tsO = nil;
	// NSKeyedArchiver *ts = [[NSKeyedArchiver alloc] initForWritingWithMutableData: [NSMutableData data]];

#if 0
	[view deselectAll: self];
	[ts encodeValueOfObjCType:"i" at:&version];
	[ts encodeRootObject:printInfo];
	[ts encodeRootObject:prefInfo];
	[ts encodeObject: [documentWindow stringWithSavedFrame]];
	[ts encodeRootObject:view];
	[ts release];
#endif
	
	/* PROPERTY LIST ENCODING */
	// TODO save version number.
	tsO = [OAPropertyListArchiver propertyListWithRootObject: view];
	// [[tsO description] writeToFile: [filename stringByAppendingPathExtension: @"ppl"] atomically: YES];
	/* END PROPERTY LIST CODING */
	//NSLog(@"Description: %@", tsO);
	
	//   [prefInfo backup]; // TODO huh? shouldn't prefInfo be saved along with the document?
	
	return [[tsO description] dataUsingEncoding: NSASCIIStringEncoding];	
    }
    else
	return nil;
}

/* Window delegate methods. */

- (void) windowControllerDidLoadNib: (NSWindowController *) primaryWindowController
{
    [super windowControllerDidLoadNib: primaryWindowController];
    documentWindow = [[primaryWindowController window] retain];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    [documentWindow setDelegate: self]; // TODO Hmm shouldn't be necessary eventually.
    // [self registerForServicesMenu]; // TODO Necessary? Here?
    [view setDelegate: self];
    if (archiveView == nil) {
        [scrollView initialiseControls]; // Connect up the page up & down buttons.
	[self zeroScale]; // TODO is this necessary here?
        // TODO kludged in here for now, it will eventually be created by a "new document sheet".
        [self setNumberOfStaves: 2];
    }
    else {
        [view initWithGraphicView: archiveView];
        [scrollView initialiseControls]; // Connect up the page up & down buttons.
	[self zeroScale]; // TODO is this necessary here?
        [view setNeedsDisplay: YES];
	// Because the archiveView is still pointed to by System, we need to assign both the recovered and the actual view.
	[view setStaffScale: [self staffScale]];
	[archiveView setStaffScale: [self staffScale]];
    }
}

#if 0

- (BOOL) needsSaving
{
    return ([view isDirty] && (haveSavedDocument || ![view isEmpty]));
}

/*
 * If the GraphicView has been edited, then this asks the user if she
 * wants to save the changes before closing the window.  When the window
 * is closed, the OpusDocument itself must be freed.  This is accomplished
 * via Application's delayedFree: mechanism.  Unfortunately, by the time
 * delayedFree: frees the OpusDocument, the window and view instance variables
 * will already have automatically been freed by virtue of the window's being
 * closed.  Thus, those instance variables must be set to nil to avoid their
 * being freed twice.
 *
 * Returning nil from this method informs the caller that the window should
 * NOT be closed.  Anything else implies it should be closed.
 */

- windowWillClose:sender action:(NSString *)action
{
    int save;
    if ([self needsSaving])
    {
	save = NSRunAlertPanel(action, @"%@ has changes. Save them?", @"Save", @"Don't Save", @"Cancel", name);
	if (save != NSAlertDefaultReturn && save != NSAlertAlternateReturn)
	{
	    return nil;
	}
	else
	{
	    [sender endEditingFor:self];	/* terminate any editing */
	    if (save == NSAlertDefaultReturn)
	    {
		[self save:nil];
	    }
	}
    }
    documentWindow = nil;
    view = nil;
    [[CalliopeAppController sharedApplicationController] inspectApp];
//#warning PrintingConversion:  '[NSPrintInfo setSharedPrintInfo:<arg1>]' used to be '[<obj> setPrintInfo:<arg1>]'.  This might want to be [[NSPrintOperation setCurrentOperation:nil] printInfo] or possibly [[PageLayout new] runModalWithPrintInfo:nil]
//#warning SB I can't set this to nil. Maybe get the app object to look after a default NSPrintInfo object.
//  [NSPrintInfo setSharedPrintInfo:nil];
    /* sb: not necessary any more I think. The shared print info holds only paper size, nothing else,
	* and I'm not sending the printinfo from this object to the shared one any more so there's
	* no need to get rid of it like this!
	*/
    [self autorelease];
    return self;
}


- (BOOL)windowShouldClose:(id)sender
{
    return [self windowWillClose:sender action:@"Close"] ? YES : NO;
}

#endif

/*
 * Called when the document window becomes the main window.
 Set the cursor appropriately depending on which tool is currently selected.
 */

//extern int partlistflag;

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    // NSWindow *theWindow = [notification object];
    /*sb: now I need to fool NSApp into thinking that we are the main window. It doesn't think
    * so yet, unfortunately.
    */
    /*sb: following line not necessary, as the printing system will grab our printInfo when it needs
    * it. See above too...
    */
//    [NSPrintInfo setSharedPrintInfo:printInfo];
    [self resetCursor];
    // [[CalliopeAppController sharedApplicationController] presetPrefsPanel]; // TODO should be [CalliopeAppController presetPrefsPanel]; eventually CalliopeAppController should just become a preferences controller.
    // [[CalliopeAppController sharedApplicationController] inspectApp]; // TODO must rewrite.
    //++partlistflag;
}

#if 0
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)size
    /*
     * Constrains the size of the window to never be larger than the
     * GraphicView inside it (including the ScrollView around it).
     */
{
    NSRect fRect, cRect;
    getContentSizeForView(view, &cRect.size);
//    PageScrollView *scrollView = [documentWindow contentView];
    
    fRect = [[documentWindow class] frameRectForContentRect:cRect styleMask:[documentWindow styleMask]];
    if ([scrollView rulersVisible]) {
        fRect.size.height += [[scrollView horizontalRulerView] frame].size.height;
        fRect.size.width += [[scrollView verticalRulerView] frame].size.width;
    }
    size.width = MIN(fRect.size.width, size.width);
    size.height = MIN(fRect.size.height, size.height);
    size.width = MAX(MIN_WINDOW_WIDTH, size.width);
    size.height = MAX(MIN_WINDOW_HEIGHT, size.height);
    return size;
}

- (void)windowDidResize:(NSNotification *)notification
{
//  NSWindow *theWindow = [notification object];
//    [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil];
//    [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return;
}
#endif


- (void)windowWillMiniaturize:(NSNotification *)aNotification
{
    id counterpart = [aNotification object];
    [counterpart setMiniwindowTitle:[[self name] stringByDeletingPathExtension]];
}

- (void) windowDidMiniaturize:(NSNotification *)notification
{
//    NSWindow *theWindow = [notification object];
//    [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil];
//    [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return;
}

- (void) setMessage: (NSString *) message
{
    [scrollView setMessage: message];
}

- (void) setPageNumber: (int) pageNumber
{
    [scrollView setPageNumber: pageNumber];
}


/* action messages from scrollView. */
/* TODO at the moment, the model and view is merged, so for now, we just redirect the message. 
  In the future, we should change the page on the model and then update the view of that model, assuming the model holds
  the concept of a current page. If current page is deemed to be entirely a display attribute, not impacting the model, then
  the target should stay the view.
*/
- (void) prevPage: sender
{
    [view prevPage: sender];
}


- (void) nextPage: sender
{
    [view nextPage: sender];
}


- (void) firstPage: sender
{
    [view firstPage: sender];
}


- (void) lastPage: sender
{
    [view lastPage: sender];
}


/* Icon dragging methods */

/* put code here for 3.0 */


/*
 * Validates whether a menu command that OpusDocument responds to
 * is valid at the current time.
 */
- (BOOL) validateMenuItem: (NSMenuItem *) menuCell
{
    int tag = [menuCell tag];
    switch (tag)
    {
        default:
            break;
        case 46:
            if ([scrollView rulersVisible] )
                [menuCell setTitle:@"Hide Ruler"];
            else
                [menuCell setTitle:@"Show Ruler"];
            [menuCell setEnabled:NO];
            break;
        case 47:
            return [[documentWindow fieldEditor:NO forObject:NSApp] superview] ? YES : NO;
    }
    return YES;
}

/* Cursor-setting method */


/*
 * Sets the document's cursor according to whatever the current graphic is.
 * Makes the graphic view the first responder if there isn't one or if
 * no tool is selected (the cursor is the normal one).
 */
// TODO this plus the tool code from CalliopeAppController should be factored into their own class.
- resetCursor
{
    id fr;
    NSCursor *cursor = [CalliopeAppController cursor];
    
//  id scrollview = [documentWindow contentView];
    [scrollView setDocumentCursor:cursor];
    fr = [documentWindow firstResponder];
    if ([fr class] == [NSTextView class]) 
	return self; /* let field editor keep editing */
    if (!fr || fr == documentWindow || cursor == [NSCursor arrowCursor]) 
	[documentWindow makeFirstResponder:view];
    return self;
}

NSEvent *anEvent;

- sendCharacter: (int) c
{
    id fr = [[NSApp keyWindow] firstResponder];
    NSString *theString = [NSString stringWithFormat:@"%c",c];
    
    if (!fr) 
	[documentWindow makeFirstResponder:view];
    anEvent = [NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0
			      timestamp:(NSTimeInterval)0.0
			   windowNumber:[[NSApp keyWindow] windowNumber]
				context:[NSApp context]
			     characters:theString charactersIgnoringModifiers:theString
			      isARepeat:NO keyCode:1]; /*sb: keyCode is bogus */
//  anEvent.data.key.charCode = c;
//  anEvent.data.key.charSet = NX_ASCIISET;
//  anEvent.flags = 0;
//  anEvent.type = NSKeyDown;
	[fr keyDown:anEvent];
	return self;
}

@end

