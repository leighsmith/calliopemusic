#import "winheaders.h"
#import "Graphic.h"

@interface NoteHead : NSObject
{
@private
    // staff position.
    char pos;
    // The y position, relative to the page?
    float myY;
    // The accidental code.
    char accidental;
    // Offset from accidental?
    float accidoff;
@public
  char type;
  char dotoff;
  char editorial;
  char side;
  id myNote;
}

+ (void) initialize;
- init;
- (void) dealloc;

- (void) moveBy: (float) x : (float) y;

// - (Staff *) myStaff;
- myStaff;

- (id) initWithCoder: (NSCoder *) aDecoder;
- (void) encodeWithCoder: (NSCoder *) aCoder;

/*!
 Returns the Y coordinate for displaying the note head.
 */
- (float) y;

/*!
 Assigns the Y coordinate for displaying the note head.
 */
- (void) setCoordinateY: (float) newY;

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
 Returns the side.
 */
- (int) side;

@end
