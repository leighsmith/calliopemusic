#import "winheaders.h"
#import "GraphicView.h"

@interface GraphicView(NSPasteboard)

#define NUM_TYPES_DRAW_EXPORTS 3

extern NSArray *TypesDrawExports(void);
extern NSString *DrawPasteType(NSArray *types);
extern NSString *ForeignPasteType(NSArray *types);
extern NSString *TextPasteType(NSArray *types);
extern BOOL IncludesType(NSArray *types, NSString *type);
extern NSString *MatchTypes(NSArray *typesToMatch, NSArray *orderedTypes);

+ convert:(NSArchiver *)ts to:(NSString *)type using:(SEL)writer toPasteboard:(NSPasteboard *)pb;
+ (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type;

- writePSToData:(NSMutableData *)stream;
- writePSToData:(NSMutableData *)stream usingList:(NSMutableArray *)aList;
- writeTIFFToData:(NSMutableData *)stream;
- writeTIFFToData:(NSMutableData *)stream usingList:(NSMutableArray *)aList;

- copySelectionAsPSToStream:(NSMutableData *)stream;
- copySelectionAsTIFFToStream:(NSMutableData *)stream;
- copySelectionToStream:(NSMutableData *)stream;

- closeList: l;
- copyToPasteboard: l;
- copyToPasteboard;
- (void)cut:(id)sender;
- (void)copy:(id)sender;
- (void)paste:(id)sender;
- pasteFromPasteboard:pboard;
- pasteFromPasteboard;
- (BOOL) pasteTool: (NSPoint *) pt : g;

@end
