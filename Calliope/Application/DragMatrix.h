#import "winheaders.h"
#import <AppKit/NSMatrix.h>

@interface DragMatrix:NSMatrix
{
    id	matrixCache, cellCache, activeCell;
    id	matrixCacheImage, cellCacheImage;
    id  deleg;
}

/* instance methods */
- (void)dealloc;
- setDeleg:sender;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)drawRect:(NSRect)rect;
- setupCacheWindows;
- sizeCacheWindow:(id *)cachingImage :(id *) cachingView to:(NSSize)windowSize;

@end
