#import "GVPasteboard.h"
#import "GVFormat.h"
#import "GVSelection.h"
#import "GraphicView.h"
#import "ImageGraphic.h"
#import "System.h"
#import <AppKit/AppKit.h>
#import "muxlow.h"

@implementation GraphicView(NSPasteboard)

int numPastes = 0;

/* Methods to search through Pasteboard types lists. */

BOOL IncludesType(NSArray *types, NSString *type)
{
//    if (types) while (*types) if (*types++ == type) return YES;
//    return NO;
    return [types containsObject:type];
}

NSString *MatchTypes(NSArray *typesToMatch, NSArray *orderedTypes)
{
    if (orderedTypes && typesToMatch) {
        int n=[orderedTypes count];
        int i;
        for (i=0;i<n;i++) {
            if ([typesToMatch containsObject:[orderedTypes objectAtIndex:i]]) return [orderedTypes objectAtIndex:i];
        }
    }
    return nil;
}

NSString *TextPasteType(NSArray *types)
/*
 * Returns the pasteboard type in the passed list of types which is preferred
 * by the Draw program for pasting.  The Draw program prefers PostScript over TIFF.
 */
{
    if ([types containsObject: NSRTFPboardType]) return NSRTFPboardType;
    if ([types containsObject: NSStringPboardType]) return NSStringPboardType;
    return nil;
}

NSString * ForeignPasteType(NSArray *types)
/*
 * Returns the pasteboard type in the passed list of types which is preferred
 * by the Draw program for pasting.  The Draw program prefers PostScript over TIFF.
 */
{
    NSString *retval = TextPasteType(types);
//#error StringCoversion: return type of imagePasteboardTypes is now an NSArray of NSStrings (used to be NXAtom *).  Change your variable declaration.
    return retval ? retval : MatchTypes(types, [NSImage imagePasteboardTypes]);
}

NSString *DrawPasteType(NSArray *types)
/*
 * Returns the pasteboard type in the passed list of types which is preferred
 * by the Draw program for pasting.  The Draw program prefers its own type
 * of course, then it prefers Text, then something NXImage can handle.
 */
{
//    if (IncludesType(types, DrawPboardType)) return DrawPboardType;
    if ([types containsObject:DrawPboardType]) return DrawPboardType;
    return ForeignPasteType(types);
}

//sb: the following function does not seem to be used anywhere.
NSArray *TypesDrawExports(void)
{
    static NSArray *exportList = NULL;
    if (!exportList) {
        exportList = [[NSArray arrayWithObjects:DrawPboardType,NSPostScriptPboardType,NSTIFFPboardType,nil] retain];
//	exportList = malloc((NUM_TYPES_DRAW_EXPORTS) * sizeof(NXAtom));
//	exportList[0] = DrawPboardType;
//	exportList[1] = [NSPostScriptPboardType cString];
//	exportList[2] = [NSTIFFPboardType cString];
    }
    return exportList;
}

/* Lazy Pasteboard evaluation handler */

/*
 * IMPORTANT: The pasteboard:provideData: method is a factory method since the
 * factory object is persistent and there is no guarantee that the INSTANCE of
 * GraphicView that put the Draw format into the Pasteboard will be around
 * to lazily put PostScript or TIFF in there, so we keep one around (actually
 * we only create it when we need it) to do the conversion (scrapper).
 *
 * If you find this part of the code confusing, then you need not even
 * use the provideData: mechanism--simply put the data for all the different
 * types your program knows how to put in the Pasteboard in at the time
 * that you declareTypes:.
 */

/*
 * Converts the data in the Pasteboard from internal format to
 * either PostScript or TIFF using the writeTIFFToData: and writePSToData:
 * methods.  It sends these messages to the scrapper (a GraphicView cached
 * to perform this very function).  Note that the scrapper view is put in
 * a window, but that window is off-screen, has no backing store, and no
 * title (and is thus very cheap).
 */

+ convert:(NSArchiver *)ts to:(NSString *)type using:(SEL)writer toPasteboard:(NSPasteboard *)pb
{
    NSWindow *w;
    NSMutableArray *list;
    NSZone *zone;
    NSMutableData *stream=[NSMutableData data];
    GraphicView *scrapper;
    NSRect scrapperFrame = {{0.0, 0.0}, {11.0*72.0, 14.0*72.0}};

    if (!ts) return self;

    zone = NSCreateZone(NSPageSize(), NSPageSize(), NO);
    NSSetZoneName(zone, @"Scrapper");
    scrapper = [[GraphicView allocWithZone:zone] initWithFrame:scrapperFrame];
    [ts setObjectZone:(NSZone *)zone];
    list = [[ts decodeObject] retain];
    graphicListBBox(&scrapperFrame, list);
    scrapperFrame.size.width += scrapperFrame.origin.x;
    scrapperFrame.size.height += scrapperFrame.origin.y;
    scrapperFrame.origin.x = scrapperFrame.origin.y = 0.0;
    [scrapper setFrameSize:NSMakeSize(scrapperFrame.size.width, scrapperFrame.size.height)];
    w = [[NSWindow allocWithZone:zone] initWithContentRect:scrapperFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreNonretained defer:NO];
    [w setContentView:scrapper];

    [scrapper performSelector:writer withObject:(id)stream withObject:list];
    [pb setData:stream forType:type];

    [list removeAllObjects];
    [list autorelease];
    [w release];
    NSRecycleZone(zone);

    return self;
}


/*
 * Called by the Pasteboard whenever PostScript or TIFF data is requested
 * from the Pasteboard by some other application.  The current contents of
 * the Pasteboard (which is in the Draw internal format) is taken out and loaded
 * into a stream, then convert:to:using:toPasteboard: is called.  This
 * returns self if successful, nil otherwise.
 */

+ (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
    id retval = nil;
    NSData *stream;
    NSArchiver *ts;

    if (([type isEqualToString:NSPostScriptPboardType]) || ([type isEqualToString:NSTIFFPboardType])) {
        if (stream = [sender dataForType:DrawPboardType]) {
	    if (ts = [[NSUnarchiver alloc] initForReadingWithData:stream]) {
		retval = self;
		if ([type isEqualToString:NSPostScriptPboardType]) {
		    [self convert:ts to:type using:@selector(writePSToData:usingList:) toPasteboard:sender];
		} else if ([type isEqualToString:NSTIFFPboardType]) {
                    [self convert:ts to:type using:@selector(writeTIFFToData:usingList:) toPasteboard:sender];
		} else {
		    retval = nil;
		}
		[ts release];
	    }
	}
    }

//    return retval;
}

/* Writing data in different forms (other than the internal Draw format) */

/*
 * Writes out the PostScript generated by drawing all the objects in the
 * glist.  The bounding box of the generated encapsulated PostScript will
 * be equal to the bounding box of the objects in the glist (NOT the
 * bounds of the view).
 */

- writePSToData:(NSMutableData *)stream
{
  NSRect bb;
  if (stream)
  {
    graphicListBBox(&bb, slist);
    [self deselectAll: self];

    [stream appendData:[self dataWithEPSInsideRect:bb]];
  }
  return self;
}


/*
 * This is the same as writePSToData:, but it lets you specify the list
 * of Graphics you want to generate PostScript for (does its job by swapping
 * the glist for the list you provide temporarily).
 */

- writePSToData: (NSMutableData *)stream usingList: (NSMutableArray *) ul
{
    NSMutableArray *sl = slist;
    slist = ul;
    [self writePSToData:stream];
    slist = sl;
    return self;
}

/*
 * Images all of the objects in the glist and writes out the result in
 * the Tagged Image File Format (TIFF).  The image will not have alpha in it.
 */

- writeTIFFToData:(NSMutableData *)stream
{
    NSRect sb;
    NSBitmapImageRep *bm;
    if (!stream) return self;
    [self selectionBBox: &sb];
    [self lockFocus];
    bm = [[NSBitmapImageRep alloc] initWithFocusedViewRect:sb];
    [self unlockFocus];
    [stream appendData: [bm TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:TIFF_COMPRESSION_FACTOR]];
    [bm release];
    return self;
}

/*
 * This is the same as writeTIFFToData:, but it lets you specify the list
 * of Graphics you want to generate TIFF for (does its job by swapping
 * the glist for the list you provide temporarily).
 */

- writeTIFFToData:(NSMutableData *)stream usingList: (NSMutableArray *)ul
{
    NSMutableArray *sl = slist;
    slist = ul;
    [self writeTIFFToData:stream];
    slist = sl;
    return self;
}

/* Writing the selection to a stream */

- copySelectionAsPSToStream:(NSMutableData *)stream
{
    return (stream && [slist count]) ? [self writePSToData:stream usingList:slist] : nil;
}

- copySelectionAsTIFFToStream:(NSMutableData *)stream
{
    return (stream && [slist count]) ? [self writeTIFFToData:stream usingList:slist] : nil;
}



- copy: (NSMutableArray *) l toStream: (NSMutableData *) stream
{
  NSArchiver *ts;
  if ([l count])
  {
//#warning ArchiverConversion: '[[NSUnarchiver alloc] init...]' used to be 'NXOpenTypedStream(...)'; stream should be converted to 'NSMutableData *'.
    ts = [[NSArchiver alloc] initForWritingWithMutableData:stream];
    [ts encodeRootObject:l];
    [ts release];
  } 
  else return nil;
  return self;
}


- copySelectionToStream:(NSMutableData *)stream
{
  return [self copy: slist toStream: stream];
}



/* Methods to write to/read from the pasteboard */

/*
 * Puts all the objects in the slist into the Pasteboard by archiving
 * the slist itself.  Also registers the PostScript and TIFF types since
 * the GraphicView knows how to convert its internal type to PostScript
 * or TIFF via the write{PS,TIFF}ToStream: methods.
 */

/* Must record position where copied so paste can know where it goes */
  
- saveCopyLocation
{
  int k;
  StaffObj *o;
  k = [slist count];
  while (k--)
  {
    o = [slist objectAtIndex:k];
    if (ISASTAFFOBJ(o)) [o getXY: &(o->x) : &(o->y)];
  }
  return self;
}


- copy: (NSMutableArray *) l toPasteboard: (NSPasteboard *) pboard types: (NSArray *) typesList
{
//  char *data;
  NSMutableData *stream = [NSMutableData data];
  NSMutableArray *types = [NSMutableArray array];
//  int /*i = 0,*/ length, maxlen;
  if ([l count])
  {
      //sb: the following could be a bit dangerous. What happens if typesList is nil? Will this ever happen?
      [types addObject:DrawPboardType];
      if (![typesList count] || [typesList containsObject:NSPostScriptPboardType]) [types addObject:NSPostScriptPboardType];
      if (![typesList count] || [typesList containsObject:NSTIFFPboardType]) [types addObject:NSTIFFPboardType];
//#error StringConversion: Pasteboard types are now stored in an NSArray of NSStrings (used to use char**).  Change your variable declaration.
    [pboard declareTypes:types owner:[self class]];
//    stream = NXOpenMemory(NULL, 0, NX_WRITEONLY);
    [self copy: l toStream: stream];
//    NXGetMemoryBuffer(stream, &data, &length, &maxlen);
    [pboard setData:stream forType:DrawPboardType];
//    NXCloseMemory(stream, NX_FREEBUFFER);
    return self;
  }
  return nil;
}


- copyToPasteboard: (NSMutableArray *) l
{
  return [self copy: (NSMutableArray *) l toPasteboard: [NSPasteboard generalPasteboard] types: NULL];
}


- copyToPasteboard
{
  if ([self copy: slist toPasteboard: [NSPasteboard generalPasteboard] types: NULL])
  {
    [self saveCopyLocation];
    return self;
  }
  return nil;
}

/*
  Remove/modify any hangers that refer to staffobjects not in the list.
  This tricky thing needs to be done in case only some of a hanger's
  clients are put into cut buffer.
*/

- closeList: (NSMutableArray *) l
{
  StaffObj *p;
  int k;
  k = [l count];
  while (k--)
  {
    p = [l objectAtIndex:k];
    if (ISASTAFFOBJ(p)) [p closeHangers: l];
  }
  return self;
}


/*
  Pastes any type available from the specified Pasteboard into a list.
  Caller expecting staff objects must ensure the list is closed (self closeList) before used.
  Returns a list of the pasted objects (caller must free).
*/

- pasteFromPasteboard: pboard
{
  NSData *data;
  int i /*, length */;
  NSString *type;
//  NSData *stream;
  NSArchiver *ts;
  id g = nil;
  NSMutableArray *pblist = nil;
//#error StringCoversion: return type of types is now an NSArray of NSStrings (used to be NXAtom *).  Change your variable declaration.
  type = DrawPasteType([pboard types]);
  if (type)
  {
//#error StreamConversion: 'dataForType:' (used to be 'readType:data:length:') returns an NSData instance
    data = [pboard dataForType:type];
//    stream = NXOpenMemory(data, length, NX_READONLY);
    if (type == DrawPboardType)
    {
//#warning ArchiverConversion: '[[NSUnarchiver alloc] init...]' used to be 'NXOpenTypedStream(...)'; stream should be converted to 'NSData *'.
      ts = [[NSUnarchiver alloc] initForReadingWithData:data];
      pblist = [[ts decodeObject] retain];
      i = [pblist count];
      if (i) [self dirty];
      else
      {
          [pblist autorelease];
	pblist = nil;
      }
      [ts release];
    }
    else
    {
      if ([type isEqualToString:NSPostScriptPboardType] || [type isEqualToString:NSTIFFPboardType])
      {
        g = [[Graphic allocInit: IMAGE] protoFromPasteboard: pboard : self];
	if (g)
	{
	  pblist = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:1];
	  [pblist addObject:g];
	}
      }
    }
//    NXCloseMemory(stream, NX_FREEBUFFER);
  }
  return pblist;
}


/* the usual entry from things using slist */

- pasteFromPasteboard
{
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
//#error StringCoversion: return type of types is now an NSArray of NSStrings (used to be NXAtom *).  Change your variable declaration.
  if (DrawPasteType([pb types]))
  {
    if ([slist count])
    {
      [self deselectAll:self];
      [[self window] flushWindow];
    }
    return [self pasteFromPasteboard: pb];
  }
  return nil;
}


/* Pasteboard-related target/action methods */

/* Calls copy: then delete: */

- (void)cut:(id)sender
{
  if ([slist count] > 0)
  {
    [self copy:sender];
    [self delete:sender];
  }
  else
  {
    NSLog(@"GVPasteboard cut: slist count <= 0");
  }
}


- (void)copy:(id)sender
{
  if ([slist count])
  {
    [self copyToPasteboard];
    numPastes = 0;
  }
}


/*
  Could be anything in pasteboard list.
    StaffObjs get pasted in.
    Single Hangers get attached to selection.
    SYSTEMs etc are ignored
*/

extern char *typename[NUMTYPES];

- (void) paste: (id) sender
{
    StaffObj *g;
    NSMutableArray *pblist, *slcopy;
    int i, k, sk;
    BOOL didstob = NO, didhang = NO;
    NSRect bbox;
    
    slcopy = [slist mutableCopy];
    sk = [slist count];
    graphicListBBox(&bbox, slist);
    pblist = [self pasteFromPasteboard];
    [self closeList: pblist];
    if (pblist == nil) return;
    i = k = [pblist count];
    while (i--)
    {
	g = [pblist objectAtIndex: i];
	if (ISASTAFFOBJ(g))
	{
	    g->x += 10 * (numPastes + 1);
	    [g linkPaste: self];
	    [self selectObj: g];
	    didstob = YES;
	}
	else if (ISAHANGER(g) || TYPEOF(g) == TEXTBOX || TYPEOF(g) == ENCLOSURE)
	{
	    if (k == 1 && sk > 0) didhang |= [g linkPaste: self : slcopy];
	}
    }
    if (didstob)
    {
	[self terminateMove];
	[self drawSelectionWith: NULL];
	++numPastes;
    }
    else if (didhang)
    {
	[self drawSelectionWith: &bbox];
	numPastes = 0;
    }
    else 
	NSLog(@"GVPasteboard -paste: !didstob && !didhang");
    [pblist autorelease];
    [slcopy autorelease];
}


/*
  the Paste Tool.  two tricky bits:  closeList (in case dangling pointers)
  and linkPaste (because new objects have no mystaff)
    StaffObjs get pasted in.
    Single Hangers try to attach to something that was hit (passed in p) (same idea as addNote).
*/

- (BOOL) pasteTool: (NSPoint *) pt : (StaffObj *) p
{
  StaffObj *g, *org;
  int i, k;
  float x=0.0, y=0.0;
  NSMutableArray *pblist, *sl;
  BOOL didstob = NO, didhang = NO;
  
  pblist = [self pasteFromPasteboard];
  [self closeList: pblist];
  if (pblist == nil) return NO;
  sl = [[NSMutableArray alloc] init];
  [sl addObject: p];
  i = k = [pblist count];
  org = [self isListLeftmost: pblist];
  if (org != nil)
  {
    x = org->x;
    y = org->y;
  }
  while (i--)
  {
    g = [pblist objectAtIndex:i];
    if (ISASTAFFOBJ(g))
    {
      g->x = pt->x + (g->x - x);
      g->y = pt->y + (g->y - y);
      [g linkPaste: self];
      [self selectObj: g];
      didstob = YES;
    }
    else if (ISAHANGER(g) || TYPEOF(g) == TEXTBOX || TYPEOF(g) == ENCLOSURE)
    {
      if (k == 1 && [sl count] == 1) didhang |= [g linkPaste: self : sl];
    }
  }
  [pblist autorelease];
  [sl autorelease];
  if (didstob) [self terminateMove];
//  [NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(updateWindows) object:nil], [NSApp performSelector:@selector(updateWindows) withObject:nil afterDelay:(1) / 1000.0];
  return (didstob || didhang);
}



@end
