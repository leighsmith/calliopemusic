#import "winheaders.h"
#import "Graphic.h"
#import <AppKit/NSFont.h>
#import <AppKit/NSTextView.h>

@interface NSTextView(CellFont)

- (NSFont *) fontOfCell: c;
- (int) posOfCell: c;

@end

@interface TextVarCell : NSTextAttachmentCell <NSTextAttachmentCell>
{
@public
    char type;
    id  theAttribString; //sb: backpointer to retrieve font info
    NSFont *theFont;
    BOOL highlighted;
}

+ (void)initialize;
- init: (int) t;
- (NSSize)cellSize;
- (NSPoint)cellBaselineOffset;
- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)rect ofView:(NSView *)view untilMouseUp:(BOOL)_untilMouseUp;
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- readRichText:(NSString *)stream forView:view;
- (NSString *)richTextForView:(NSView *)view;
- (BOOL)wantsToTrackMouse;
- (void)setAttachment:(NSTextAttachment *)anObject;
- (NSTextAttachment *)attachment;
- (void)setFont:(NSFont *)aFont;
- (NSFont *)font;

@end
