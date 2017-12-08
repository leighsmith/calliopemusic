#import "winheaders.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "TabTuner.h"

@interface TuningView:NSView
{
  id accmatrix;
  id addbutton;
  id removebutton;
  int dragging, curp, lastsel;
  TabTuner *myTuner;
}

- init: p;
- (BOOL)isFlipped;
- (BOOL)becomeFirstResponder;
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)e;
- (void)mouseDragged:(NSEvent *)e;
- (void)mouseUp:(NSEvent *)e;
- addCourse: sender;
- removeCourse: sender;
- hitAcc: sender;
- preset;
- (void)drawRect:(NSRect)r;

@end
