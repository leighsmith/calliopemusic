#import "winheaders.h"
#import "Graphic.h"
#import "TimedObj.h"
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>

@interface Hanger:Graphic
{
@public
  id client;
  int UID;
  struct
  {
    unsigned int split : 2;	/* whether split to left b10 or right b01 (or both) */
    unsigned int level : 8;	/* the level */
  } hFlags;
}

- (BOOL) hit: (NSPoint) p : (int) i : (int) j;
- (float) hitDistance: (NSPoint) p : (int) i : (int) j;
- (int) maxLevel;
- (int) myLevel;
- (BOOL) canSplit;
- newFrom;
- haveSplit: a : b : (float) x0 : (float) x1;
- haveSplit: a : b;
- (BOOL) isDangler;
- (BOOL) needSplit: (float) s0 : (float) s1;
- willSplit;
- (BOOL) needSplitList: (float) s0 : (float) s1;
- splitMe: (float) s0 : (float) s1 : (int) d;
- mergeMe: h;
- closeClients: l;
- sysInvalid;
- sysInvalidList;
- setHanger;
- setHanger: (BOOL) a : (BOOL) b;
- (void)removeObj;
- removeGroup;
- sortNotes: l; 		/* a general service for some hangers */
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
/*sb added following: */
- presetHanger;

@end
