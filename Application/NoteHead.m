/* $Id$ */
#import "NoteHead.h"
#import "System.h"
//#import "draw.h"  // This was generated by the pswrap utility from draw.psw.
#import "DrawingFunctions.h"
#import "muxlow.h"

@implementation NoteHead

+ (void) initialize
{
    if (self == [NoteHead class]) {
	[NoteHead setVersion: 2];	/* class version, see read: */
    }
}


- init
{
    self = [super init];
    if (self != nil) {
	type = 0;
	pos = 0;
	dotoff = 0;
	accidental = 0;
	editorial = NO;
	accidoff = 0.0;
	side = 0;
	myY = 0.0;
	myNote = nil;
    }
    return self;
}


- (void) dealloc
{
    [super dealloc];
}


- (void) moveBy: (float) x : (float) y
{
    myY += y;
}

- (float) y
{
    return myY;
}

- (void) setCoordinateY: (float) newY
{
    myY = newY;
}

- (void) setStaffPosition: (int) positionOnStaff
{
    pos = positionOnStaff;
}

- (int) staffPosition
{
    return pos;
}

- (int) accidental
{
    return accidental;
}

- (void) setAccidental: (int) newAccidental
{
    accidental = newAccidental;
}

- (float) accidentalOffset
{
    return accidoff;
}

- (void) setAccidentalOffset: (float) newOffset
{
    accidoff = newOffset;
}

- (BOOL) isAnEditorial;
{
    return editorial;
}

- (void) setIsAnEditorial: (BOOL) yesOrNo
{
    editorial = yesOrNo;
}

- (BOOL) isReverseSideOfStem
{
    return side;
}

- (void) setReverseSideOfStem: (BOOL) yesOrNo
{
    side = yesOrNo;
}

- (int) dotOffset
{
    return dotoff;
}

- (void) setDotOffset: (int) newDotOffset
{
    dotoff = newDotOffset;
}

- (int) bodyType
{
    return type;
}

- (void) setBodyType: (int) newBodyType
{
    type = newBodyType;
}

- myStaff
{
    return [myNote staff]; // StaffObj reference
}

- (GNote *) myNote
{
    return myNote; // TODO perhaps [[myNote retain] autorelease]; ?
}

- (void) setNote: (GNote *) noteOfNoteHead
{
    myNote = noteOfNoteHead; // Need to check if we should [noteOfNoteHead retain] perhaps a weak link since it can be our parent.
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    int v = [aDecoder versionForClassName: @"NoteHead"];

    if (v == 0) {
	[aDecoder decodeValuesOfObjCTypes:"ccccccf@", &type, &pos, &dotoff, &accidental,
	    &editorial, &side, &myY, &myNote];
	accidoff = 0.0;
	editorial = NO;
    }
    else if (v == 1) {
	[aDecoder decodeValuesOfObjCTypes:"ccccccff@", &type, &pos, &dotoff, &accidental, &editorial, &side, &accidoff, &myY, &myNote];
	editorial = NO;
    }
    else if (v == 2) 
	[aDecoder decodeValuesOfObjCTypes:"ccccccff@", &type, &pos, &dotoff, &accidental, &editorial, &side, &accidoff, &myY, &myNote];
    return self;
}


- (void) encodeWithCoder: (NSCoder *) aCoder
{
    [aCoder encodeValuesOfObjCTypes: "ccccccff@", &type, &pos, &dotoff, &accidental,
        &editorial, &side, &accidoff, &myY, &myNote];
}

- (void) encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [aCoder setInteger: type forKey: @"type"];
    [aCoder setInteger: pos forKey: @"pos"];
    [aCoder setInteger: dotoff forKey: @"dotoff"];
    [aCoder setInteger: accidental forKey: @"accidental"];
    [aCoder setInteger: editorial forKey: @"editorial"];
    [aCoder setInteger: side forKey: @"side"];
    [aCoder setFloat: accidoff forKey: @"accidoff"];
    [aCoder setFloat: myY forKey: @"myY"];
    [aCoder setObject: myNote forKey: @"myNote"];
}

@end