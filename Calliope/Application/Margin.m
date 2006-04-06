/* $Id$ */
#import "Page.h"
#import "Margin.h"
#import "OpusDocument.h"
#import "MarginInspector.h"
#import "System.h"
#import "Staff.h"
#import "GVFormat.h"
#import "mux.h"

@implementation Margin

#define SIZEBOX 8.0	/* size of the box used to represent a margin */

+ (void) initialize
{
    if (self == [Margin class]) {
	[Margin setVersion: 3];		/* class version, see read:, changed ivars */
    }
}

+ myInspector
{
    return [MarginInspector class];
}


static float defmarg[MaximumMarginTypes] = {36.0, 36.0, 36.0, 36.0, 72.0, 72.0, 0.0, 0.0, 0.0, 0.0};

- init
{
    int i = MaximumMarginTypes;
    
    self = [super init];
    if(self != nil) {
	gFlags.type = MARGIN; // TODO [self setTypeOfGraphic: MARGIN];
	while (i--) 
	    margin[i] = defmarg[i];
	staffScale = 0.0;
    }
    return self;
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ staffScale %f ", [super description], staffScale];
}

- copyWithZone: (NSZone *) zone
{
    Margin *newMargin = [[[self class] allocWithZone: zone] init];
    int marginIndex = MaximumMarginTypes;

    while (marginIndex--)
	newMargin->margin[marginIndex] = margin[marginIndex];
    newMargin->staffScale = staffScale;
    newMargin->client = client;
    return newMargin;
}


/*
  setrunnertables and tidying markers done by delete:
*/

- (void) removeObj
{
    [self retain];
    [client unlinkobject: self];
    [self release];
}

- (void) setStaffScale: (float) newStaffScale
{
    staffScale = newStaffScale;
}

- (float) staffScale
{
    return staffScale;
}

- (void) setClient: (id) newClient
{
    client = newClient; // don't retain to avoid circular retentions.
}

- (id) client
{
    return client;
}

- (float) leftMargin
{
    return margin[MarginLeft] / staffScale;
}

- (void) setLeftMargin: (float) newLeftMargin
{
    margin[MarginLeft] = newLeftMargin;
}

- (float) rightMargin
{
    return margin[MarginRight] / staffScale;
}

- (void) setRightMargin: (float) newRightMargin
{
    margin[MarginRight] = newRightMargin;
}

- (float) headerBase
{
    return margin[MarginHeader] / staffScale;
}

- (void) setHeaderBase: (float) newHeaderMargin
{
    margin[MarginHeader] = newHeaderMargin;
}

- (float) footerBase
{
    return margin[MarginFooter] / staffScale;
}

- (void) setFooterBase: (float) newFooterMargin
{
    margin[MarginFooter] = newFooterMargin;
}

- (float) topMargin
{
    return margin[MarginTop] / staffScale;
}

- (void) setTopMargin: (float) newTopMargin
{
    margin[MarginTop] = newTopMargin;
}

- (float) bottomMargin
{
    return margin[MarginBottom] / staffScale;
}

- (void) setBottomMargin: (float) newBottomMargin
{
    margin[MarginBottom] = newBottomMargin;
}
   
- (float) leftBindingOnOddPage: (BOOL) oddPage
{
    return oddPage ? [self marginOfType: MarginLeftOddBinding] : [self marginOfType: MarginLeftEvenBinding];    
}

- (float) rightBindingOnOddPage: (BOOL) oddPage
{
    return oddPage ? [self marginOfType: MarginRightOddBinding] : [self marginOfType: MarginRightEvenBinding];    
}

- (float) leftMarginWithBindingOnOddPage: (BOOL) oddPage
{
    return [self leftMargin] + [self leftBindingOnOddPage: oddPage];
}

- (float) rightMarginWithBindingOnOddPage: (BOOL) oddPage
{
    return [self rightMargin] + [self rightBindingOnOddPage: oddPage];
}

- (void) setMarginType: (MarginType) marginType toSize: (float) newMarginValue
{
    margin[marginType] = newMarginValue;
}

- (float) marginOfType: (MarginType) marginType
{
    return margin[marginType];
}

- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt
{
    return NO;
}


- drawMode: (int) markedMode
{
    System *s = client;
    Staff *sp = [s firststaff];
    float x = [s leftWhitespace] + s->width + 20;
    float y = [sp yOfTop] + [s whichMarker: self] * (SIZEBOX + 3);
    
    coutrect(x, y, SIZEBOX, SIZEBOX, 0.0, markedMode);
    crect(x, y, (0.25 * SIZEBOX), SIZEBOX, markedMode);
    crect(x + (0.75 * SIZEBOX), y, (0.25 * SIZEBOX), SIZEBOX, markedMode);
    return self;
}


- draw
{
    return [self drawMode: markmode[gFlags.selected]];
}


/* Archiving methods */


- (id)initWithCoder:(NSCoder *)aDecoder
{
    int v = [aDecoder versionForClassName: @"Margin"];
    int format; // No longer required. TODO may need recovery into Page.
    int alignment; // No longer required. TODO may need recovery into Page.
    
    [super initWithCoder: aDecoder];
    if (v == 2)
    {
	[aDecoder decodeValuesOfObjCTypes: "@cc",  &client, &format, &alignment];
	[aDecoder decodeArrayOfObjCType: "f" count: MaximumMarginTypes at: margin];
    }
    else if (v == 1)
    {
	[aDecoder decodeValuesOfObjCTypes: "@c",  &client, &format];
	[aDecoder decodeArrayOfObjCType: "f" count: MaximumMarginTypes at: margin];
	alignment = 0;
    }
    else if (v == 0)
    {
	[aDecoder decodeValuesOfObjCTypes: "@",  &client];
	[aDecoder decodeArrayOfObjCType: "f" count: MaximumMarginTypes at: margin];
	format = 0;
	alignment = 0;
    }
    return self;
}

- (void) encodeWithPropertyListCoder: (OAPropertyListCoder *) aCoder
{
    int marginIndex;
    
    [super encodeWithPropertyListCoder: (OAPropertyListCoder *) aCoder];
    [aCoder setObject: client forKey: @"client"];
    [aCoder setFloat: staffScale forKey: @"staffScale"];
    [aCoder setInteger: MaximumMarginTypes forKey: @"maximumMarginTypes"];
    for (marginIndex = 0; marginIndex < MaximumMarginTypes; marginIndex++)
	[aCoder setFloat: margin[marginIndex] forKey: [NSString stringWithFormat:@"margin%d", marginIndex]];
}

@end
