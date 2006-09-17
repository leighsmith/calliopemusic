/* $Id$ */
#import "MarginInspector.h"
#import "Margin.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "GVCommands.h"
#import "GVSelection.h"
#import "System.h"
#import "DrawApp.h"
#import "OpusDocument.h"
#import "DrawingFunctions.h"
#import "muxlow.h"

@implementation MarginInspector

NSString *unitname[4] =
{
    @"Inches", @"Centimeters", @"Points", @"Picas"
};


- preset
{
    int n;
    float conv;
    GraphicView *v = [DrawApp currentView];
    Margin *margin = [v canInspect: MARGIN : &n];
    Page *page = [v currentPage];
    
    if (n == 0)
	return nil;
    conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
//  [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
    [[lbindform cellAtIndex: 0] setFloatValue: conv * [margin marginOfType: MarginLeftEvenBinding]];
    [[lbindform cellAtIndex: 1] setFloatValue: conv * [margin marginOfType: MarginLeftOddBinding]];
    [[rbindform cellAtIndex: 0] setFloatValue: conv * [margin marginOfType: MarginRightEvenBinding]];
    [[rbindform cellAtIndex: 1] setFloatValue: conv * [margin marginOfType: MarginRightOddBinding]];
    [lmargcell setFloatValue: conv * [margin leftMargin]];
    [rmargcell setFloatValue: conv * [margin rightMargin]];
    [[vertmargform cellAtIndex: 0] setFloatValue: conv * [margin headerBase]];
    [[vertmargform cellAtIndex: 1] setFloatValue: conv * [margin topMargin]];
    [[vertmargform cellAtIndex: 2] setFloatValue: conv * [margin bottomMargin]];
    [[vertmargform cellAtIndex: 3] setFloatValue: conv * [margin footerBase]];
    [unitcell setStringValue: [[DrawApp sharedApplicationController] unitString]];
    [formatbutton selectItemAtIndex: [page format]];
    [[alignmatrix cellAtRow: 0 column: 0] setState: [page alignToTopSystem]];
    [[alignmatrix cellAtRow: 1 column: 0] setState: [page alignToBottomSystem]];
    return self;
}

#define UPDATE(lv, rv) if ([margin marginOfType: (lv)] != (rv)) { [margin setMarginType: lv toSize: rv]; didChange = YES; }

- set: sender
{
    int n;
    float f, conv;
    BOOL didChange = NO;
    System *sys;
    GraphicView *v = [DrawApp currentView];
    Margin *margin = [v canInspect: MARGIN : &n];
    Page *page = [v currentPage];

    if (n == 0) {
	NSLog(@"MarginInspector -set: n == 0");
	return nil;
    }
    [v saveSysLeftMargin];
    [page setFormat: [formatbutton indexOfItemWithTitle: [formatbutton title]]];
    if ([[alignmatrix cellAtRow: 0 column: 0] state])
	[page setAlignToTopSystem];
    if ([[alignmatrix cellAtRow: 1 column: 0] state])
	[page setAlignToBottomSystem];
    conv = [[DrawApp sharedApplicationController] pointToCurrentUnitFactor];
    // [[[DrawApp sharedApplicationController] pageLayout] convertOldFactor:&conv newFactor:&anon];
    f = [[lbindform cellAtIndex: 0] floatValue] / conv;
    UPDATE(MarginLeftEvenBinding, f);
    f = [[lbindform cellAtIndex: 1] floatValue] / conv;    
    UPDATE(MarginLeftOddBinding, f);
    f = [[rbindform cellAtIndex: 0] floatValue] / conv;    
    UPDATE(MarginRightEvenBinding, f);
    f = [[rbindform cellAtIndex: 1] floatValue] / conv;    
    UPDATE(MarginRightOddBinding, f);
    f = [lmargcell floatValue] / conv;    
    UPDATE(MarginLeft, f);
    f = [rmargcell floatValue] / conv;    
    UPDATE(MarginRight, f);
    f = [[vertmargform cellAtIndex: 0] floatValue] / conv;    
    UPDATE(MarginHeader, f);
    f = [[vertmargform cellAtIndex: 1] floatValue] / conv;    
    UPDATE(MarginTop, f);
    f = [[vertmargform cellAtIndex: 2] floatValue] / conv;    
    UPDATE(MarginBottom, f);
    f = [[vertmargform cellAtIndex: 3] floatValue] / conv;    
    UPDATE(MarginFooter, f);
    sys = [margin client];
    if (didChange) 
	[v setRunnerTables];
    [v shuffleIfNeeded];
    [v recalcAllSys];
    [v paginate: self];
    [v dirty];
    [v setNeedsDisplay: YES];
    return self;
}

@end
