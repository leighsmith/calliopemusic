/*!
  $Id$ 

  @class Hanger
  @brief
 */
#import "winheaders.h"
#import "Graphic.h"
//#import "TimedObj.h"
#import <CalliopePropertyListCoders/OAPropertyListCoders.h>

@class Tie; // Needed for Tie upgrade code.

@interface Hanger:Graphic
{
@protected
    NSMutableArray *client; // TODO rename to clients.
@public
  int UID;
  struct
  {
    unsigned int split : 2;	/* whether split to left b10 or right b01 (or both) */
      unsigned int level : 8;	/* the level */ // TODO is now private.
  } hFlags;
}

- (BOOL) hit: (NSPoint) p : (int) i : (int) j;
- (float) hitDistance: (NSPoint) p : (int) i : (int) j;

/*!
  @brief Return the maximum group level of all clients.
*/
- (int) maxLevel;

/*!
  @brief Return the level of this Hanger.
  This needs to be overridden by Hanger subclasses without level.
*/
- (int) myLevel;

/*!
  @brief Sets a new level for this Hanger.
 */
- (void) setLevel: (int) newLevel;

/*!
  @brief Return the staff scale associated with the clients System.
 */
- (float) staffScale;

- (BOOL) canSplit;
- newFrom;
- haveSplit: a : b : (float) x0 : (float) x1;
- haveSplit: a : b;
- (BOOL) isDangler;
- (BOOL) needSplit: (float) s0 : (float) s1;
- (NSMutableArray *) willSplit;
- (BOOL) needSplitList: (float) s0 : (float) s1;
- (NSMutableArray *) splitMe: (float) s0 : (float) s1 : (int) d;
- mergeMe: (Hanger *) h;

/*!
  @brief Return the first client in the Hanger.
 */
- firstClient;

/*!
  @brief Assign a new client to the Hanger.
 */
- (void) setClient: (id) newClient;

/*! 
  @brief remove from clients anything not in l 
 */
- closeClients: (NSMutableArray *) l;

/*!
  @brief Return all the clients in this Hanger.
 */
- (NSArray *) clients;

/*!
  @brief Abstract implementation that is usually overriden.
  If exectuted, it messages sysInvalid on the first item on the client list.
*/
- sysInvalid;

/*!
  @brief Set all systems of the clients invalid.
  TODO should be renamed invalidateSystems
 */
- sysInvalidList;
- setHanger;
- setHanger: (BOOL) a : (BOOL) b;
- (void)removeObj;
- removeGroup;
- sortNotes: (NSMutableArray *) l; 		/* a general service for some hangers */
- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;

/*
 Declared for subclasses to override.
 */
- proto: (Tie *) t1 : (Tie *) t2;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
/*sb added following: */
- presetHanger;

@end
