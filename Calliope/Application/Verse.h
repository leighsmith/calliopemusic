#import "winheaders.h"
#import <AppKit/NSFont.h>
#import <AppKit/NSGraphics.h>
#import "Graphic.h"
// #import "StaffObj.h"

@class StaffObj;

/*
  The gFlags.invis bit is used for invisible verses.
  The gFlags.subtype bit is used for the justification code
*/

/*
  hyphens are now complicated.
  0 no hyphens
  1 automatic hyphens
  2 automatic baseline extender
  3 hanging hyphen right
  4 hanging baseline right
  5 hanging hyphen left
  6 hanging baseline left
*/

#define CONTHYPH (0xb1)
#define CONTLINE (0xd0)

@interface Verse: Graphic
{
@public
    struct
    {
	unsigned int above : 1;
	unsigned int hyphen : 3;	/* type of hyphen */
	unsigned int line : 4;	/* actual line */
	unsigned int num : 4;	/* verse number */
    } vFlags;
    char offset;
    char align;
    NSFont *font;
    float pixlen;
    float baseline;
    id note;				/* a backpointer */
@private    
    char *data;		/* the string TODO should be a NSString */
}

+ (void)initialize;
- init;
- recalc;
- newFrom;
- (void) removeObj;
- (BOOL) isFigure;
- reShape;
- alignVerse;
- (float) textLeft: (StaffObj *) p;
- (int) keyDownString:(NSString *)cc;
- (BOOL) hit: (NSPoint) p;
- drawMode: (int) m;
- draw;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

/*!
  @brief Returns the text constituting the verse as an immutable NSString.
 */
- (NSString *) string;

/*!
  @brief Assigns the text constituting the verse.
 */
- (void) setString: (NSString *) newText;

/* return whether a string is a blank verse */
- (BOOL) isBlank;

@end
