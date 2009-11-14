/*!
  $Id$ 

  @class Runner
  @brief Represents the text which runs along the header or footer of each page.
 */

#import "winheaders.h"
#import "Graphic.h"

@class Page;

@interface Runner: Graphic
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
    id client;			/* a System */
@private
    NSMutableAttributedString *richText;	/* the rich text */
}

+ (void)initialize;
+ myInspector;
- init;
- (void)dealloc;
- (void)removeObj;
- (Runner *) newFrom;

/*!
  @brief Renders the given text on the given page of the given paper size.
 */
- (void) renderInRect: (NSRect) r text: (NSAttributedString *) textString paperSize: (NSSize) ps onPage: (Page *) pg;

/*!
  @brief Renders the runner text on the given page of the given paper size.
 */
- (void) renderTextInRect: (NSRect) r paperSize: (NSSize) ps onPage: (Page *) pg;

/*!
  @brief Set text used for the runner.
 */
- (void) setRunnerText: (NSAttributedString *) textString;

/*!
  @brief Returns the text used for the runner.
 */
- (NSAttributedString *) runnerText;

- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- drawMode: (int) m;
- draw;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
