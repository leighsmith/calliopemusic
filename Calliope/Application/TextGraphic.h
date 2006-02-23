#import "winheaders.h"
#import "Graphic.h"
#import "GraphicView.h"
#import <AppKit/NSTextView.h>


/* TEXTBOX gFlags.subtype */

#define LABEL 1
#define STAFFHEAD 2
#define TITLE 3


@interface TextGraphic : Graphic
{
@public
  float baseline;		/* baseline for page titles */
  NSPoint offset;		/* the offset relative to client */
  NSData *richTextData;		/*sb: changed this ivar */
  id client;			/* a StaffObj or a Staff or a System */
  int length;			/* the length of data */
  char horizpos;
  char just;
  GraphicView *graphicView;
  NSTextView *fe;		 /* the field editor text object      */
                              /* used for editing between edit:in: */
                              /* and textDidEnd:endChar:           */
  NSRect lastEditingFrame;
}

+ (void)initClassVars;

+ cursor;
+ (void)initialize;
- myInspector;
- init;
- (BOOL) isDangler;
- (BOOL) needSplit: (float) s0 : (float) s1;
- (void)dealloc;
- setHanger;
- presetHanger;
- initFromString: (NSString *) s : (NSFont *) f;
- proto: v : (NSPoint) pt : (Staff *) sp : sys : (Graphic *) g : (int) i;
- (BOOL) linkPaste: (GraphicView *) v : (NSMutableArray *) sl;
- recalc;
- (BOOL) changeVFont: (NSFont *) f : (BOOL) all;
- (BOOL) hit:(NSPoint)p;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- (void)removeObj;
- (TextGraphic *) newFrom;
- (BOOL) isResizable;
- (BOOL) isEditable;
+ hideRuler:view;
- (float) topMargin;

- (BOOL)edit:(NSEvent *)event in:view;
- drawMode: (int) m;
- draw;

/* Text delegate methods */

- (void)textDidEndEditing:(NSNotification *)notification;
- (void)updateEditingViewRect:(NSRect)updateRect;
- (void)editorFrameChanged:(NSNotification *)arg;

/* Archiving methods */

- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
