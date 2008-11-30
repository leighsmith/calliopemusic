#import "winheaders.h"
#import "Hanger.h"

@interface Metro: Hanger
{
@public
    char body[2];
    char dot[2];
    short ticks;
    short pos;
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- proto: (GraphicView *) v : (NSPoint) pt : (Staff *) sp : (System *) sys : (Graphic *) g : (int) i;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) pt : sys : (int) alt;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

/*!
 Assigns the staff position (location on the staff) that the note head resides at.
 */
- (void) setStaffPosition: (int) positionOnStaff;

/*!
 Returns the staff position (location on the staff) that the note head resides at.
 */
- (int) staffPosition;

@end
