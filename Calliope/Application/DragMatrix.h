
#import <AppKit/NSMatrix.h>

@interface DragMatrix:NSMatrix
{
    id	matrixCache, cellCache, activeCell;
    id	matrixCacheImage, cellCacheImage;
}

/* instance methods */

- (void)dealloc;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)drawRect:(NSRect)rect;
- setupCacheWindows;
- sizeCacheWindow:(id *)cacheWindow to:(NSSize)windowSize;

@end
