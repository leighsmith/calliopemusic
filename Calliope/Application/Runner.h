#import "winheaders.h"
#import "Graphic.h"
#import "Page.h"

@interface Runner:Graphic
{
@public
  struct
  {
    unsigned int onceonly : 1;	/* once only */
    unsigned int nextpage : 1;	/* start next page */
    unsigned int horizpos : 2;	/* horizontal place */
    unsigned int evenpage : 1;	/* even page */
    unsigned int oddpage  : 1;	/* odd page */
    unsigned int vertpos  : 1;	/* head or foot*/
    unsigned int just     : 2;  /* justification */
  } flags;
  int length;
  NSMutableAttributedString *data;	/* the rich text */
  id client;			/* a System */
}

+ (void)initialize;
+ myInspector;
- init;
- (void)dealloc;
- (void)removeObj;
- (Runner *) newFrom;
- setPageTable: (Page *) p;
- renderMe: (NSRect) r : (NSAttributedString *) stream : (NSSize) ps : (Page *) pg;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- drawMode: (int) m;
- draw;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
