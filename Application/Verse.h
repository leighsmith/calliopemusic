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
	unsigned int above : 1;	    /*!< YES if the Verse is above the Staff */
	unsigned int hyphen : 3;    /* type of hyphen */
	unsigned int line : 4;	    /* actual line */
	unsigned int num : 4;	    /* verse number */
    } vFlags;
    char offset;
    char align;
    float pixlen;
    /*! @var note a backpointer to the note the verse is assigned to. */
    StaffObj *note;
@private    
    /*! @var baseline Vertical offset from the Staff to draw the Verse. */
    float baseline;
    /*! @var font The font to draw the text with */
    NSFont *font;
    /*! @var data The string TODO should be a NSString */
    NSString *verseString;
}

+ (void) initialize;
- init;
- copyWithZone: (NSZone *) zone;

- recalc;
- (void) removeObj;
- (BOOL) isFigure;
- reShape;
- alignVerse;

/*!
  @brief Assign the vertical baseline offset of the Verse from the Staff (either above or below).
 */
- (void) setBaseline: (float) newBaseline aboveStaff: (BOOL) yesOrNo;

- (float) textLeft: (StaffObj *) p;
- (int) keyDownString:(NSString *)cc;
- (BOOL) hit: (NSPoint) p;
- drawMode: (int) m;
- draw;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

/*!
  @brief Returns the Font used to draw the Verse.
 */
- (NSFont *) font;

/*!
  @brief Assigns the Font used to draw the Verse.
 */
- (void) setFont: (NSFont *) newFont;

/*!
  @brief Return the verse number (number of times the verse is sung) of this Verse.
*/
- (int) verseNumber;

/*!
  @brief Assign the verse number, which describes on which repeat of the verse this Verse's text will be sung.
*/
- (void) setVerseNumber: (int) verseNumber;

/*!
  @brief Returns the text constituting the verse as an immutable NSString.
 */
- (NSString *) string;

/*!
  @brief Assigns the text constituting the verse.
 */
- (void) setString: (NSString *) newText;

/*! 
  @brief Return YES if the Verse is a blank string. 
 */
- (BOOL) isBlank;

@end
