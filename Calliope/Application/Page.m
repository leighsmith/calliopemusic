/* $Id$ */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Page.h"
#import "Runner.h"
#import "Margin.h"
#import "GVFormat.h"
#import "mux.h"
#import "muxlow.h"
#import "DrawApp.h"
#import "OpusDocument.h"

@implementation Page

// TODO This is totally bogus and has to be removed.
extern NSSize paperSize;

+ (void) initialize
{
    if (self == [Page class]) {
	[Page setVersion: 2];	/* class version, see read: */
    }
}

#if 0
- (void) dealloc
{
    [super dealloc];
}
#endif

- initWithPageNumber: (int) n topSystemNumber: (int) s0 bottomSystemNumber: (int) s1
{
    self = [super init];
    if(self != nil) {
	topsys = s0;
	botsys = s1;
	num = n;
	alignment = 0;
	format = 0;	
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
// TODO should become copyWithZone:
- prevTable: (Page *) p
{
    int i = 12;
    if (p == nil)
    {
	while (i--)
	{
	    headfoot[i] = nil;
	    hfinfo[i] = 0;
	}
	i = MaximumMarginTypes;
	while (i--) 
	    margin[i] = 0;
	alignment = format = 0;
    }
    else
    {
	while (i--)
	{
	    headfoot[i] = p->headfoot[i];
	    hfinfo[i] = 0;
	}
	i = MaximumMarginTypes;
	while (i--) 
	    margin[i] = p->margin[i];
	alignment = p->alignment;
	format = p->format;
    }
    return self;
}

/* margin = margin + binding margin */
- (float) leftMargin
{
    float m = margin[0];
    m += (num & 1) ? margin[8] : margin[6];
    return m / [[DrawApp currentDocument] staffScale];
}


- (float) rightMargin
{
    float m = margin[1];
    m += (num & 1) ? margin[9] : margin[7];
    return m / [[DrawApp currentDocument] staffScale];
}


- (float) leftBinding
{
    float m;
    m = (num & 1) ? margin[8] : margin[6];
    return m / [[DrawApp currentDocument] staffScale];
}


- (float) rightBinding
{
    float m;
    m = (num & 1) ? margin[9] : margin[7];
    return m / [[DrawApp currentDocument] staffScale];
}


- (float) topMargin
{
    return margin[4] / [[DrawApp currentDocument] staffScale];
}


- (float) bottomMargin
{
    return margin[5] / [[DrawApp currentDocument] staffScale];
}

- (float) headerBase
{
    return margin[2] / [[DrawApp currentDocument] staffScale];
}

- (float) footerBase
{
    return margin[3] / [[DrawApp currentDocument] staffScale];
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

- (void) setMarginType: (MarginType) marginType toSize: (float) newMarginValue
{
    margin[marginType] = newMarginValue;
}

- (void) setRunner: (Runner *) newRunner
{
    int j = newRunner->flags.horizpos;
    
    if (newRunner->flags.vertpos)
	j += 3;
    if (newRunner->flags.evenpage) {
	headfoot[j] = newRunner;
	hfinfo[j] = 1;
    }
    if (newRunner->flags.oddpage) {
	j += 6;
	headfoot[j] = newRunner;
	hfinfo[j] = 1;
    }
}

static void drawSlants(float x, float y, float hw, float th)
{
    float xa, xb, ya, yb;
    
    xa = x - hw;
    xb = x + hw;
    ya = y;
    yb = y - 3 * th;
    cslant(xa, ya, xb, yb, th, drawmode[0][0]);
    ya += 1.75 * th;
    yb += 1.75 * th;
    cslant(xa, ya, xb, yb, th, drawmode[0][0]);
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



- (void) drawRect: (NSRect) r
{
    {
	int i, a, b;
	
	a = 0;
	if ([self pageNumber] & 1) // Check for even/odd pages.
	    a = 6;
	b = a + 6;
	for (i = a; i < b; i++)	{
	    Runner *p = headfoot[i];
	    
	    if (p == nil)
		continue;
	    if (p->flags.onceonly && hfinfo[i] == 0) 
		continue;
	    if (p->flags.nextpage && hfinfo[i]) 
		continue;
	    [p renderMe: r : p->data : paperSize : self];
	}	
    }
}

//extern int needUpgrade;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    int i, v;
    float t, b;
    
    v = [aDecoder versionForClassName:@"Page"];
    if (v == 0)
    {
        [aDecoder decodeValuesOfObjCTypes:"ifffss", &num, &t, &fillheight, &b, &topsys, &botsys];
        margin[4] = t;
        margin[5] = b;
        for (i = 0; i < 12; i++) headfoot[i] = [[aDecoder decodeObject] retain];
        [aDecoder decodeArrayOfObjCType:"c" count:12 at:hfinfo];
        //needUpgrade |= 4;
        format = alignment = 0;
    }
    else if (v == 1)
    {
        [aDecoder decodeValuesOfObjCTypes:"ifss", &num, &fillheight, &topsys, &botsys];
        for (i = 0; i < 12; i++) headfoot[i] = [[aDecoder decodeObject] retain];
        [aDecoder decodeArrayOfObjCType:"c" count:12 at:hfinfo];
        [aDecoder decodeArrayOfObjCType:"f" count:MaximumMarginTypes at:margin];
        format = alignment = 0;
    }
    else if (v == 2)
    {
        [aDecoder decodeValuesOfObjCTypes:"ifsscc", &num, &fillheight, &topsys, &botsys, &format, &alignment];
        for (i = 0; i < 12; i++) headfoot[i] = [[aDecoder decodeObject] retain];
        [aDecoder decodeArrayOfObjCType:"c" count:12 at:hfinfo];
        [aDecoder decodeArrayOfObjCType:"f" count:MaximumMarginTypes at:margin];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    int i;
    
    [aCoder encodeValuesOfObjCTypes:"ifsscc", &num, &fillheight, &topsys, &botsys, &format, &alignment];
    for (i = 0; i < 12; i++) [aCoder encodeConditionalObject:headfoot[i]];
    [aCoder encodeArrayOfObjCType:"c" count:12 at:hfinfo];
    [aCoder encodeArrayOfObjCType:"f" count:MaximumMarginTypes at:margin];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    int i;
//    [super encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder];
    
    [aCoder setInteger:num forKey:@"num"];
    [aCoder setFloat:fillheight forKey:@"fillheight"];
    [aCoder setInteger:topsys forKey:@"topsys"];
    [aCoder setInteger:botsys forKey:@"botsys"];
    [aCoder setInteger:format forKey:@"format"];
    [aCoder setInteger:alignment forKey:@"alignment"];
    
    for (i = 0; i < 12; i++) [aCoder setObject:headfoot[i] forKey:[NSString stringWithFormat:@"hf%d",i]];
    for (i = 0; i < 12; i++) [aCoder setInteger:hfinfo[i] forKey:[NSString stringWithFormat:@"hfinfo%d",i]];
    [aCoder setInteger:MaximumMarginTypes forKey:@"nummargins"];
    for (i = 0; i < MaximumMarginTypes; i++) [aCoder setFloat:margin[i] forKey:[NSString stringWithFormat:@"margin%d",i]];
}

@end
