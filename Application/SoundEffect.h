#import "winheaders.h"

#if !defined(WIN32) && !defined(__APPLE__)
#import <Foundation/NSObject.h>
#import <AppKit/AppKit.h>
#ifndef __APPLE__
#import <SoundKit/SoundKit.h>
#else
#import <SndKit/SndKit.h>
#endif

@interface SoundEffect:NSObject
{
    Sound *sound;			// The sound data for this sound
    struct {
        unsigned int refCount:24;	// Number of play requests pending
	unsigned int freeWhenDone:1;	// Free when all are done
	unsigned int :7;
    } flags;
}

- initFromMainBundle:(NSString *)sound;
- play;
- play:(float)volume pan:(float)rads;
- (void)dealloc;

+ (void)setSoundEnabled:(BOOL)flag;
+ (BOOL)soundEnabled;

+ (void)setMaxSoundStreams:(unsigned int)max;
+ (unsigned int)maxSoundStreams;

// Internal methods.

+ (NXPlayStream *)soundStream;
+ (void)releaseSoundStream:(NXPlayStream *)soundStream;

@end

#endif //(sb: we can't do all this trick stuff on Windows (yet) */