/* $Id$ */
#import <AppKit/AppKit.h>
#import <Foundation/NSArray.h>
#import <objc/List.h>
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>
#import "DrawDocument.h"
#import "DrawApp.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVSelection.h"
#import "GVCommands.h"
#import "SyncScrollView.h"
#import "Page.h"
#import "System.h"
#import "CallPageLayout.h"
#import "mux.h"
#import "CalliopeWindow.h"

extern NSColor * backShade;

@implementation DrawDocument
/*
 * This class is used to keep track of a Draw document.
 */

#define DOC_VERSION 3  /*sb: bumped up from 2 for OS conversion. Reading old formats now more difficult. Must used mixed object graphs. */

/*
 margins are stored here.  All margins are in units of points,
 and are converted when read.
 Whenever margins change, the systems need to be recalc'd.
 */

#define MIN_WINDOW_WIDTH 50.0
#define MIN_WINDOW_HEIGHT 75.0
#define SCROLLVIEW_BORDER NSNoBorder

extern BOOL marginFlag;
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
    *contentSize = [SyncScrollView frameSizeForContentSize:viewFrame.size hasHorizontalScroller:YES hasVerticalScroller:YES borderType:SCROLLVIEW_BORDER];
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
    sV = [[SyncScrollView allocWithZone:[view zone]] initWithFrame:*r];
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
    if (self == [DrawDocument class]) {
	[DrawDocument setVersion: DOC_VERSION];	/* class version, see read: */
    }
}

/* Very private methods needed by factory methods */

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
    
    ts = [[NSUnarchiver alloc] initForReadingWithData:stream];
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
	    frameString = [[NSString stringWithCString: s] retain]; //sb: was strcpy(frameString, s);
	    free(s);
	    view = [[ts decodeObject] retain];
	    prefInfo->staffheight = staffheight;
	    [view updateMargins: headerbase : footerbase : printInfo];
	}
	else if (version == 2)
	{
	    NSSize checkSize;
	    printInfo = [[ts decodeObject] retain];
	    prefInfo= [[ts decodeObject] retain];
	    NSLog(@"Paper width %g height %g\n",[NSPrintInfo sizeForPaperName:[printInfo paperName]].width,[NSPrintInfo sizeForPaperName:[printInfo paperName]].height);
	    checkSize = [printInfo paperSize];
	    if (NSEqualSizes(checkSize,NSZeroSize)) {
		checkSize = [NSPrintInfo sizeForPaperName:[printInfo paperName]];
		[printInfo setPaperSize:checkSize];
		checkSize = [printInfo paperSize];
		NSLog(@"Check width %g height %g\n",checkSize.width, checkSize.height);
	    }
	    [ts decodeValueOfObjCType:"*" at:&s];
	    frameString = [[NSString stringWithCString: s] retain]; //sb: was strcpy(frameString, s);
	    free(s);
	    view = [[ts decodeObject] retain];
	}
	else if (version == DOC_VERSION)
	{
	    NSString *newS;
	    printInfo = [[ts decodeObject] retain];
	    prefInfo = [[ts decodeObject] retain];
	    newS = [ts decodeObject];
	    frameString = [newS retain]; //sb: was strcpy(frameString, s);
	    view = [[ts decodeObject] retain];
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
	    view = [[ts decodeObject] retain];
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
	if (p) [self installPrefInfo: p];
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
- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) aType
{
    NSLog(@"loadDataRepresentation: Received type %@ data %@\n", aType, data);
    if([aType isEqualToString: FILE_EXT]) {
	if(![self loadDocument: data]) // if unable to load the document normally, try the old versionless method.
	    return [self loadOldDocument: data];
	return YES;
    }
    else {
	// TODO load from XML music format.
	NSLog(@"Should be loading from XML music format!\n");
    }
    return NO;
}


/* Factory methods */

/*
 * We reuse zones since it doesn't cost us anything to have a
 * zone lying around (e.g. if we open ten documents at the start
		      * then don't use 8 of them for the rest of the session, it doesn't
		      * cost us anything except VM (no real memory cost)), and it is
 * risky business to go around NSDestroy()'ing zones since if
 * your application accidentally allocates some piece of global
 * data into a zone that gets destroyed, you could have a pointer
 * to freed data on your hands!  We use the List object since it
 * is so easy to use (which is okay as long as 'id' remains a
		      * pointer just like (NSZone *) is a pointer!).
 *
 * Note that we don't implement alloc and allocFromZone: because
 * we create our own zone to put ourselves in.  It is generally a
 * good idea to "notImplemented:" those methods if you do not allow
 * an object to be alloc'ed from an arbitrary zone (other examples
						    * include Application and all of the Application Kit panels
						    * (which allocate themselves into their own zone).
						    */

static List *zoneList = nil;

+ (NSZone *)newZone
{
    if (!zoneList || ![zoneList count]) {
        return NSCreateZone(NSPageSize(), NSPageSize(), YES);
    } else {
        return (NSZone *)[zoneList removeLastObject];
    }
}

+ (void)reuseZone:(NSZone *)aZone
{
    if (!zoneList) zoneList = [List new];
    [zoneList addObject:(id)aZone];
    NSSetZoneName(aZone, @"Unused");
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
	// [self registerForServicesMenu]; // LMS Necessary?
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
 * Creates a new, empty, document.
 *
 * create a view of default papersize, creates a window for that view;
 sets self
 * as the window's delegate; orders the window front; registers the window
 * with the Workspace Manager
 */

+ new
{
    NSZone *zone;
    NSRect frameRect = NSZeroRect;
    NSSize frameSize;
    
#if 0
    DrawDocument *doc = [[DrawDocument alloc] init];
#endif
    
    DrawDocument *doc;
    zone = [self newZone];
    doc = [super allocWithZone:zone];
    [doc registerForServicesMenu];
    doc->printInfo = [[NSPrintInfo alloc] init];
    doc->prefInfo = [[PrefBlock alloc] init];
    [doc setDefaultFormat];
//  [doc paperRect: &frameRect];
    frameSize = [doc paperSize];
    frameRect.size = frameSize;
    doc->view = [[GraphicView allocWithZone:zone] initWithFrame:frameRect];
//#error ViewConversion: 'setClipping:' is obsolete. Views always clip to their bounds. Use PSinitclip instead.
//  [doc->view setClipping:NO];			/* since it is in a ClipView */
    doc->documentWindow = createWindowFor(doc->view, NULL, nil);
    [(NSWindow *)doc->documentWindow setDelegate:doc];
    [doc zeroScale];
    [doc setName: nil andDirectory: nil];
    [doc->view firstPage:doc];
    
    [(NSWindow *)doc->documentWindow makeKeyAndOrderFront:doc];
    return doc;
}
#endif

/*
 * Creates a new document from what is in the passed stream.
 */

+ newFromStream:(NSData *)stream
{
    NSZone *zone;
    NSRect contFrame = NSZeroRect;
    DrawDocument *doc;
    zone = [self newZone];
    doc = [super allocWithZone:zone];
    [doc registerForServicesMenu];
    if (stream && [doc loadDocument: stream]) {
	NSString *frameString = [doc frameString];
	
        paperSize = [doc paperSize];
        [Page initPage];
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

+ newOldFromStream:(NSData *)stream
{
    NSZone *zone;
    DrawDocument *doc;
    zone = [self newZone];
    doc = [super allocWithZone:zone];
    [doc registerForServicesMenu];
    if (stream && [doc loadOldDocument: stream])
    {
	NSRect contFrame = [doc frameSize];
	doc->documentWindow = createWindowFor(doc->view, &contFrame, nil);
	[(NSWindow *)doc->documentWindow setDelegate:doc];
	
	[doc->view firstPage:doc];
	
	[doc resetScrollers];
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
    DrawDocument *doc;
    
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
		[(GraphicView *)doc->view paginate: self];
		[(GraphicView *)doc->view firstPage: self];
		[(GraphicView *)doc->view formatAll: self];
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

// TODO should become copyWithZone: 
- newFrom
{
    NSZone *zone;
    NSRect frameRect = NSZeroRect;
    NSSize frameSize;
    DrawDocument *doc;
    GraphicView *v;
    zone = [DrawDocument newZone];
    doc = [DrawDocument allocWithZone:zone];
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


- (void)dealloc
{
    [printInfo release];
    [prefInfo release];
    [documentWindow release];
    if (name) [name autorelease];
    if (directory) [directory autorelease];
    [[self class] reuseZone:(NSZone *)[self zone]];
    [super dealloc];
//  return [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(100) / 1000.0];
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
    if (!registered)
    {
	registered = YES;
	validSendTypes = [NSArray arrayWithObject:NSFilenamesPboardType];
	[NSApp registerServicesMenuSendTypes:validSendTypes returnTypes:nil];
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
                    if (save == NSAlertDefaultReturn) [self save];
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
	if ([[NSString stringWithCString:*types] isEqualToString:NSFilenamesPboardType])
	    break;
	else types++;
    if (types && *types) {
	if ([view isDirty]) {
	    save = NSRunAlertPanel(@"Service", @"Do you wish to save this document before your request is serviced?", @"Save", @"Don't Save", nil);
	    if (save == NSAlertDefaultReturn) [self save];
	}
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
	[pboard writeType:NSFilenamesPboardType data:[[self filename] cString] length:[[self filename] length]+1];
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


- setPreferenceAsInt: (int) v at: (int) i
{
    if (prefInfo) [prefInfo setIntValue: v at: i];
    else NSLog(@"PrefBlock missing!\n");
    return self;
}


- setPreferenceAsFloat: (float) v at: (int) i
{
    if (prefInfo) [prefInfo setFloatValue: v at: i];
    else NSLog(@"PrefBlock missing!\n");
    return self;
}


- prefInfo
{
    return prefInfo;
}


- installPrefInfo: (PrefBlock *) p
{
    if (prefInfo) [prefInfo release];
    prefInfo = p;
    return self;
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
//  id scrollView;
    NSSize conSize;
    NSRect conRect, winFrame;
    BOOL doRuler = NO;
    if (documentWindow)
    {
	winFrame = [documentWindow frame];
	conRect = [[documentWindow class] contentRectForFrameRect:winFrame styleMask:[documentWindow styleMask]];
// scrollView = [documentWindow contentView];
	getContentSizeForView(view, &conSize);
	if ([scrollView rulersVisible])
	{
	    conSize.height += [scrollView frame].size.height;
	    conSize.width += [scrollView frame].size.width;
	    doRuler = YES;
	}
	if (conRect.size.width >= conSize.width || conRect.size.height >= conSize.height)
	{
	    conSize.width = MIN(conRect.size.width, conSize.width);
	    conSize.height = MIN(conRect.size.height, conSize.height);
	    [documentWindow setContentSize:conSize];
	}
	[scrollView setPageNum: [view getPageNum]];
	[scrollView setScaleNum: [view getScaleNum]];
	if (doRuler) [scrollView updateRuler];
    }
    return self;
}


/* Returns the GraphicView associated with this document. */

- gview
{
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


/* Target/Action methods */

/*
 Puts up a PageLayout panel.  Document is repaginated to the new
 choices of paper size, margins, etc.
 */

- changeLayout:sender
{
    float w, h, ss, vs;
    NSSize opr = [self paperSize];
    CallPageLayout * pl;
    BOOL p;
#ifndef WIN32
    //this forces the page layout panel to use the units that we have defined in Calliope app preferences
    NSString * tempUnit = [[[NSUserDefaults standardUserDefaults] stringForKey:@"NSMeasurementUnit"] retain];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NSMeasurementUnit"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSApp unitString]
                                              forKey:@"NSMeasurementUnit"];
    pl = [NSApp newPageLayout];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NSMeasurementUnit"];
    if (tempUnit)
        [[NSUserDefaults standardUserDefaults] setObject:tempUnit
                                                  forKey:@"NSMeasurementUnit"];
#else
    pl = [NSApp pageLayout];
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
    [NSApp inspectPreferences: NO];
    return self;
}

#if 0
- close:sender
{
    [documentWindow endEditingFor:self];
    [documentWindow performClose:self];
    return self;
}


/*
 * Saves the file.  If this document has never been saved to disk,
 * then a SavePanel is put up to ask for the file name.
 */

- (id) save:sender
{
    id savepanel;
    if (!haveSavedDocument)
    {
	savepanel = [NSApp savePanel: FILE_EXT];
	if ([savepanel runModalForDirectory:@"" file:@""])
	{
	    [self setName:[savepanel filename]];
	} else return self;
    }
    [self save];
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
 * Panels a filename of the given extension
 */

- (NSString *) askForFile: (NSString *) ext
{
    id savepanel;
    savepanel = [NSApp savePanel: ext];
    if (![savepanel runModalForDirectory:directory file:[name stringByDeletingPathExtension]]) return nil;
    return [savepanel filename];
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
//    stream = NXMapFile([[self filename] cString], NX_READONLY);
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
	    file = [[NSApp currentDocument] askForFile: [NSString stringWithCString:typeExts[type]]];
	    if (file)
	    {
		s = [self dataWithEPSInsideRect:*region];
		[s writeToFile:file atomically:YES];
	    }
		break;
	case 2:
	    file = [[NSApp currentDocument] askForFile: [NSString stringWithCString:typeExts[type]]];
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

- showTextRuler: sender
{
//  SyncScrollView *scrollView = [documentWindow contentView];
    if ([scrollView rulersVisible])
    {
//    [scrollView showHorizontalRuler:NO];
	[sender toggleRuler:sender];
    }
    return self;
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

- hideRuler:sender
{
//    id scrollView = [documentWindow contentView];
    id fe = [documentWindow fieldEditor:NO forObject:NSApp];
    if (!sender && [scrollView rulersVisible])
    {
        [fe toggleRuler:sender];
//        [scrollView toggleRuler:nil];//huh?
//    if ([scrollView verticalRulerIsVisible]) [scrollView showHorizontalRuler:YES];
        [scrollView resizeSubviewsWithOldSize:NSZeroSize];
        [scrollView setNeedsDisplay:YES];//sb
    }
    else if (sender)
    {
        [fe toggleRuler:sender];
        [scrollView showHideRulers:self];
#if 0 // TODO Disabled until we figure out why we attempt to toggle scrollView rulers? LMS
        if ([scrollView rulersVisible]) {
            if (![fe window]) [scrollView toggleRuler:nil];//huh?
        }
        else
            [scrollView toggleRuler:nil];//huh?
#endif
    }
//  [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return self;
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
	directory = @"."; // LMS TODO [[NSApp currentDirectory] retain];
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

- save
{
    NSString *s;
    int version = DOC_VERSION;
    NSArchiver *ts;
    OAPropertyListArchiver *tsO;
    
    NSString *filename = [self filename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *backupFilename = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:BACKUP_EXT];
    
    if ([view isDirty])
    {
	if (([fileManager fileExistsAtPath:backupFilename] && ![fileManager removeFileAtPath:backupFilename handler:[self class]]) ||
	    ([fileManager fileExistsAtPath:filename] && ![fileManager movePath:filename toPath:backupFilename handler:[self class]])) {
	    NSRunAlertPanel(@"Calliope", @"CANT_CREATE_BACKUP", nil, nil, nil);
	}
	
	ts = [[NSArchiver alloc] initForWritingWithMutableData:[NSMutableData data]];
	if (ts && [fileManager isWritableFileAtPath:[filename stringByDeletingLastPathComponent]])
        {
	    NS_DURING
		[documentWindow makeFirstResponder:view];
		[(GraphicView *)view deselectAll: self];
		[ts encodeValueOfObjCType:"i" at:&version];
		[ts encodeRootObject:printInfo];
		[ts encodeRootObject:prefInfo];
		s = [documentWindow stringWithSavedFrame];
		[ts encodeObject:s];
		[ts encodeRootObject:view];
		
		/* PROPERTY LIST ENCODING */
		tsO = [OAPropertyListArchiver propertyListWithRootObject:view];
		[[tsO description] writeToFile:[filename stringByAppendingPathExtension:@"ppl"] atomically:YES];
		/* END PROPERTY LIST CODING */
        //NSLog(@"Description: %s\n",[[tsO description] cString]);
		
		if (![[ts archiverData] writeToFile:filename atomically:YES]) {
		    Notify(@"Save", @"Error writing file. Check disk space at save location, or save to a different location.");
		    haveSavedDocument = NO;
		}
		else haveSavedDocument = YES;
		
		[ts release];
		[prefInfo backup];
	    NS_HANDLER
		Notify(@"Save", @"Unknown error writing file.");
	    NS_ENDHANDLER
        }
	else Notify(@"Save", @"Cannot write file to this location. Check permissions on the directory you were trying to save to.");
    }
//    [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil];
//    [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return self;
}

// Used for writing
// For applications targeted for Tiger or later systems, you should use the new Tiger API -dataOfType:error:.  In this case you can also choose to override -writeToURL:ofType:error:, -fileWrapperOfType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
- (NSData *) dataRepresentationOfType: (NSString *) docType
{
    NSLog(@"dataRepresentationOfType:\n");
    // return [NSData data];
    return nil;
}


- (BOOL) needsSaving
{
    return ([view isDirty] && (haveSavedDocument || ![view isEmpty]));
}



/* Window delegate methods. */

- (void) windowControllerDidLoadNib: (NSWindowController *) primaryWindowController
{
    [super windowControllerDidLoadNib: primaryWindowController];
    documentWindow = [[primaryWindowController window] retain];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    [documentWindow setDelegate: self]; // Hmm
    [view firstPage: self];
    [self zeroScale];
}

#if 0

/*
 * If the GraphicView has been edited, then this asks the user if she
 * wants to save the changes before closing the window.  When the window
 * is closed, the DrawDocument itself must be freed.  This is accomplished
 * via Application's delayedFree: mechanism.  Unfortunately, by the time
 * delayedFree: frees the DrawDocument, the window and view instance variables
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
    [NSApp inspectApp];
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

extern int partlistflag;

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
    // [NSApp presetPrefsPanel]; // TODO should be [DrawApp presetPrefsPanel]; eventually DrawApp should just become a preferences controller.
    // [NSApp inspectApp]; // TODO must rewrite.
    ++partlistflag;
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
//    SyncScrollView *scrollView = [documentWindow contentView];
    
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

- (void)windowDidMiniaturize:(NSNotification *)notification
{
//    NSWindow *theWindow = [notification object];
//    [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil];
//    [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
    return;
}


/*Icon dragging methods */

/*put code here for 3.0 */


/*
 * Validates whether a menu command that DrawDocument responds to
 * is valid at the current time.
 */

- (BOOL)validateMenuItem:(NSMenuItem *)menuCell
{
    int tag = [menuCell tag];
    switch (tag)
    {
        default:
            break;
        case 39:
            return [view isDirty];
        case 40:
            return (haveSavedDocument || ![view isEmpty]);
        case 41:
            return ![view isEmpty];
        case 44:
            return ([view isDirty] && haveSavedDocument);
        case 46:
#if 1 // TODO LMS disabled until we sort out the IBOutlet for the SyncScrollView
            if ([scrollView rulersVisible] )
                [menuCell setTitle:@"Hide Ruler"];
            else
                [menuCell setTitle:@"Show Ruler"];
            [menuCell setEnabled:NO];
#endif
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

- resetCursor
{
    id fr;
    NSCursor *cursor = [DrawApp cursor];
    
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
    if (!fr) [documentWindow makeFirstResponder:view];
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

