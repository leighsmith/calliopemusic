/*
  This is an 'instrument' that 'performs' various user interface concerns that
  should happen during a performance, such as tempo changes and page turning
*/

#import "DrawApp.h"
#import "DrawDocument.h"
#import "GraphicView.h"
#import "GVFormat.h"
#import "UserInstrument.h"
#import "PlayInspector.h"
#import <MusicKit/MusicKit.h>

@implementation UserInstrument


/* Give it an input port */

- init
{ 
  [super init];
  [self addNoteReceiver: [[MKNoteReceiver alloc] init]];
  return self;
}


/* realise a choice based on various parameter settings */

- realizeNote: n fromNoteReceiver: nr
{
  if ([n isParPresent: [MKNote parTagForName: @"CAL_setTempo"]])
  {
    PlayInspector *pi = [NSApp thePlayInspector];
      float t = [n parAsDouble: [MKNote parTagForName: @"CAL_setTempo"]];
      [[MKConductor defaultConductor] setTempo: t];
      [MKConductor sendMsgToApplicationThreadSel: @selector(setTempo:) to: pi argCount: 1 , (int) t];
  }
    if ([n isParPresent: [MKNote parTagForName: @"CAL_changeTempo"]])
  {
    PlayInspector *pi = [NSApp thePlayInspector];
        float t = [n parAsDouble: [MKNote parTagForName: @"CAL_changeTempo"]] * [[MKConductor defaultConductor] tempo];
        [[MKConductor defaultConductor] setTempo: t];
        [MKConductor sendMsgToApplicationThreadSel: @selector(setTempo:) to: pi argCount: 1 , (int) t];
  }
    else if ([n isParPresent: [MKNote parTagForName: @"CAL_page"]])
  {
    GraphicView *v = [NSApp thePlayView];
        if (v != nil) [MKConductor sendMsgToApplicationThreadSel: @selector(gotoPage::) to: v argCount: 2 , [n parAsInt: [MKNote parTagForName: @"CAL_page"]] , 2];
  }
  return self;
}


@end
