/*!
  $Id$ 

  @class NoteHead
  @brief Represents the note head in it's various forms, including it's position.
 */

#import "winheaders.h"
#import "Graphic.h"
#import "Staff.h"
@class GNote;

// TODO perhaps factor out accidental handling into specific Accidental class.
@interface NoteHead : NSObject
{
@private
    /*! staff position. */
    char pos;
    /*! The y position, relative to the page? */
    float myY;
    /*! The accidental code. */
    char accidental;
    /*! Offset from accidental? */
    float accidoff;
    /*! Indicates that the accidental is an "editorial" accidental. */
    BOOL editorial;
    /*! is the note head on the wrong side of the stem? TODO should be a BOOL. */
    BOOL side;
    /*! back reference to the GNote which references the note head. */
    GNote *myNote;
    /*! The body type of the note head, describing it's shape. */
    char type;
    /*! dot offset, seems to be only two values, 0 or -1? */
    char dotoff;
}

+ (void) initialize;
- init;
- (void) dealloc;

- (id) initWithCoder: (NSCoder *) aDecoder;
- (void) encodeWithCoder: (NSCoder *) aCoder;


- (void) moveBy: (float) x : (float) y;

// - (Staff *) myStaff;
- myStaff;

/*!
  Returns the GNote instance that this NoteHead instance belongs to.
 */
- (GNote *) myNote;

/*!
 Assigns the note associated with this NoteHead.
 */
- (void) setNote: (GNote *) noteOfNoteHead;

/*!
 Returns the body type code.
 */
- (int) bodyType;

/*!
  Assigns the body type code.
 */
- (void) setBodyType: (int) newBodyType;

/*!
 Returns the Y coordinate for displaying the note head.
 */
- (float) y;

/*!
 Assigns the Y coordinate for displaying the note head.
 */
- (void) setCoordinateY: (float) newY;

/*!
  Returns the offset of the dot from the note head.
 */
- (int) dotOffset;

/*!
  Assigns the offset of the dot from the note head.
 */
- (void) setDotOffset: (int) newDotOffset;

/*!
  Assigns the staff position (location on the staff) that the note head resides at.
 */
- (void) setStaffPosition: (int) positionOnStaff;

/*!
 Returns the staff position (location on the staff) that the note head resides at.
 */
- (int) staffPosition;

/*!
  Returns the accidental associated with the note head.
 */
- (int) accidental;

/*!
 Sets the accidental associated with the note head.
 */
- (void) setAccidental: (int) newAccidental;

/*!
 Returns the accidental associated with the note head.
 */
- (float) accidentalOffset;

/*!
 Sets the accidental associated with the note head.
 */
- (void) setAccidentalOffset: (float) newOffset;

/*!
  Returns YES if the accidental is an editorial accidental.
 */
- (BOOL) isAnEditorial;

/*!
  Assigns if the accidental is an editorial accidental.
 */
- (void) setIsAnEditorial: (BOOL) yesOrNo;

/*!
 Returns if the note head sits on reverse side of the side.
 */
- (BOOL) isReverseSideOfStem;

/*!
  Assigns the side
 */
- (void) setReverseSideOfStem: (BOOL) yesOrNo;

@end
