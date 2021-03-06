/* $Id$ */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Page.h"
#import "Runner.h"
#import "Margin.h"
#import "GVFormat.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"

@implementation Page

NSSize defaultPaperSize = { 0, 0 };

+ (void) initialize
{
    if (self == [Page class]) {
	[Page setVersion: 3];	/* class version, bumped since we now hold Margin instances. */
    }
}

+ (void) setDefaultPaperSize: (NSSize) newDefaultPaperSize
{
    defaultPaperSize = newDefaultPaperSize;
}

- (void) dealloc
{
    [margin release];
    margin = nil;
    // TODO need to release those Runners in headfoot.
    [super dealloc];
}

- initWithPageNumber: (int) n 
     topSystemNumber: (int) newTopSystem 
  bottomSystemNumber: (int) newBottomSystem
	   paperSize: (NSSize) newPaperSize
{
    self = [super init];
    if(self != nil) {
	topsys = newTopSystem;
	botsys = newBottomSystem;
	num = n;
	alignment = 0;
	format = PGAUTO;
	paperSize = newPaperSize;
	margin = [[Margin alloc] init];
    }
    return self;
}

- (int) pageNumber
{
    return num;
}

- (void) setPageNumber: (int) newPageNumber
{
    num = newPageNumber;
}

/* copy page table info from previous page.  p is nil if no previous page */
- copyWithZone: (NSZone *) zone
{
    Page *newPage = [[[self class] allocWithZone: zone] init];
    int runnerIndex = 12;

    while (runnerIndex--) {
	newPage->headfoot[runnerIndex] = [headfoot[runnerIndex] retain];
    }
    newPage->paperSize = paperSize;
    [newPage setMargin: [margin copy]];
    [newPage setAlignment: alignment];
    [newPage setFormat: format];
    return newPage;
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ number %d top system %d bottom system %d",
	[super description], num, topsys, botsys];
}

/* margin = margin + binding margin */
- (float) leftMargin
{
    return [margin leftMarginWithBindingOnOddPage: (num & 1)];
}


- (float) rightMargin
{
    return [margin rightMarginWithBindingOnOddPage: (num & 1)];
}

- (float) leftBinding
{
    return [margin leftBindingOnOddPage: (num & 1)];
}

- (float) rightBinding
{
    return [margin rightBindingOnOddPage: (num & 1)];
}

- (float) topMargin
{
    return [margin topMargin];
}

- (float) bottomMargin
{
    return [margin bottomMargin];
}

- (float) headerBase
{
    return [margin headerBase];
}

- (float) footerBase
{
    return [margin footerBase];
}

/* sums to page height (as screened) */
- (float) fillHeight
{
    return fillheight;
}

- (void) setFillHeight: (float) newHeight
{
    fillheight = newHeight;
}

- (int) topSystemNumber
{
    return topsys;
}

- (int) bottomSystemNumber
{
    return botsys;
}

- (PageFormat) format
{
    return format;
}

- (void) setFormat: (PageFormat) newFormat
{
    format = newFormat;
}

- (BOOL) alignToTopSystem
{
    return alignment & 1;
}

- (BOOL) alignToBottomSystem
{
    return alignment & 2;
}

- (void) setAlignment: (int) newAlignment
{
    alignment = newAlignment;
}

- (void) setAlignToTopSystem
{
    alignment |= 1;
}

- (void) setAlignToBottomSystem
{
    alignment |= 2;
}

- (void) setRunner: (Runner *) newRunner
{
    // This should be a parameter to setRunner:atPosition:, so that Runner doesn't hold
    // where it is located, page should just have a set of NSArrays of various Runners.
    int j = newRunner->flags.horizpos;
    
    if (newRunner->flags.vertpos)
	j += 3;
    if (newRunner->flags.evenpage) {
	headfoot[j] = [newRunner retain];
    }
    if (newRunner->flags.oddpage) {
	j += 6;
	headfoot[j] = [newRunner retain];
    }
}

- (void) setMargin: (Margin *) newMargin
{
    [margin release];
    margin = [newMargin retain];
}

- (Margin *) margin
{
    return [[margin retain] autorelease];
}

static void drawSlants(float x, float y, float hw, float th)
{
    float xa, xb, ya, yb;
    
    xa = x - hw;
    xb = x + hw;
    ya = y;
    yb = y - 3 * th;
    cslant(xa, ya, xb, yb, th, [Graphic drawingModeIfSelected: 0 ifInvisible: 0]);
    ya += 1.75 * th;
    yb += 1.75 * th;
    cslant(xa, ya, xb, yb, th, [Graphic drawingModeIfSelected: 0 ifInvisible: 0]);
}

// drawSystemSeparator
- drawSysSep: (NSRect) r : (System *) s : (GraphicView *) v
{
    int mi = [s myIndex];
    float ym, th, hw;
    
    if (mi == botsys) 
	return self;
    ym = [v yBetween: mi];
    th = beamthick[0];
    hw = 4 * nature[0];
    if (s->flags.syssep & 2) 
	drawSlants([self leftMargin], ym, hw, th);
    if (s->flags.syssep & 1) 
	drawSlants([self leftMargin] + [s leftIndent] + s->width, ym, hw, th);
    return self;
}

- (void) drawRect: (NSRect) rect
{
    int i, a, b;
	
    a = 0;
    if ([self pageNumber] & 1) // Check for even/odd pages.
	a = 6;
    b = a + 6;
    for (i = a; i < b; i++) {
	Runner *runner = headfoot[i];
	
	if (runner == nil)
	    continue;
	if (runner->flags.nextpage) 
	    continue;
	[runner renderTextInRect: rect paperSize: paperSize onPage: self];
    }	
}

//extern int needUpgrade;

- (id) initWithCoder: (NSCoder *) aDecoder
{
    int i;
    float t, b;
    MarginType marginType;
    float marginValues[MaximumMarginTypes];
    char hfinfo[12];	    // Used to be an ivar, now redundant if headfoot just checks for nil values.
    
    // Initialise with the default paper size since earlier versions did not store this.
    [self initWithPageNumber: 0 topSystemNumber: 0 bottomSystemNumber: 0 paperSize: defaultPaperSize];
    if (![aDecoder allowsKeyedCoding]) {
	int v = [aDecoder versionForClassName: @"Page"];
	
	switch(v) {
	    case 0:
		[aDecoder decodeValuesOfObjCTypes: "ifffss", &num, &t, &fillheight, &b, &topsys, &botsys];
		[margin setTopMargin: t];
		[margin setBottomMargin: b];
		for (i = 0; i < 12; i++) headfoot[i] = [[aDecoder decodeObject] retain];
		[aDecoder decodeArrayOfObjCType: "c" count:12 at: hfinfo];
		//needUpgrade |= 4;
		format = alignment = 0;
		break;
	    case 1:
		[aDecoder decodeValuesOfObjCTypes: "ifss", &num, &fillheight, &topsys, &botsys];
		for (i = 0; i < 12; i++) 
		    headfoot[i] = [[aDecoder decodeObject] retain];
		[aDecoder decodeArrayOfObjCType: "c" count: 12 at: hfinfo];
		[aDecoder decodeArrayOfObjCType: "f" count: MaximumMarginTypes at: marginValues];
		format = alignment = 0;
		break;
	    case 2:
		[aDecoder decodeValuesOfObjCTypes:"ifsscc", &num, &fillheight, &topsys, &botsys, &format, &alignment];
		for (i = 0; i < 12; i++) 
		    headfoot[i] = [[aDecoder decodeObject] retain];
		[aDecoder decodeArrayOfObjCType: "c" count: 12 at: hfinfo];
		[aDecoder decodeArrayOfObjCType: "f" count: MaximumMarginTypes at: marginValues];
		
		break;
	    default:
		NSLog(@"Unhandled Page version (%d) during decoding.", v);
	}
	
	if(v != 0) {
	    for(marginType = MarginLeft; marginType < MaximumMarginTypes; marginType++)
		[margin setMarginType: marginType toSize: marginValues[marginType]];	
	}
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *) aCoder
{
    int i;
    
    [aCoder encodeValuesOfObjCTypes:"ifsscc", &num, &fillheight, &topsys, &botsys, &format, &alignment];
    for (i = 0; i < 12; i++)
	[aCoder encodeConditionalObject: headfoot[i]];
    [aCoder encodeObject: margin];

}

- (void) encodeWithPropertyListCoder: (OAPropertyListCoder *) aCoder
{
    int i;
//    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    
    [aCoder setInteger: num forKey: @"num"];
    [aCoder setFloat: fillheight forKey: @"fillheight"];
    [aCoder setInteger: topsys forKey: @"topsys"];
    [aCoder setInteger: botsys forKey: @"botsys"];
    [aCoder setInteger: format forKey: @"format"];
    [aCoder setInteger: alignment forKey: @"alignment"];
    
    for (i = 0; i < 12; i++) 
	[aCoder setObject: headfoot[i] forKey: [NSString stringWithFormat: @"hf%d", i]];
    [aCoder setObject: margin forKey: @"margins"];
}

@end
