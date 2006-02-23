#import "winheaders.h"
#import "Graphic.h"
#import "Staff.h"
#import "System.h"

/* BRACKET gFlags.subtype */

#define LINKAGE 0
#define BRACK 1
#define BRACE 2


@interface Bracket:Graphic
{
@public
  char level;			
  id client1, client2;		/* clients (can be nil or Staff or System) */
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- newFrom: (System *) sys;
- (void)dealloc;
- (void)removeObj;
- mySystem;
- (BOOL) atBottom: (Staff *) s;
- (BOOL) atTop: (Staff *) s;
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end

