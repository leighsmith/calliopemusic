/*
 * SoundEffect.m, class to play sounds
 * Originally by Terry Donahue, modified by Ali Ozer
 *
 * SoundEffect is a class which conveniently groups the 3.0
 * sound stream functionality with sound data using the Sound
 * class.
 *
 *  You may freely copy, distribute and reuse the code in this example.
 *  NeXT disclaims any warranty of any kind, expressed or implied,
 *  as to its fitness for any particular use.
 */

#if !defined(WIN32) && !defined(__APPLE__)

#import "SoundEffect.h"

#import <Foundation/NSArray.h>

@implementation SoundEffect

static BOOL soundEnabled = NO;

#define DEFAULTMAXSOUNDSTREAMS 20

static NSMutableArray *soundStreams = nil;		// Array of currently idle sound streams
static unsigned int soundStreamsAllocated = 0;	// Total number of sound streams allocated
static unsigned int maxSoundStreams = DEFAULTMAXSOUNDSTREAMS;	// Max allowed

// After calling this, you may call soundEnabled to check to see if it was successful.

+ (void)setSoundEnabled:(BOOL)flag
{
    if (flag && !soundEnabled) {
	NXPlayStream *testStream = [self soundStream];
	if (testStream) {
	    soundEnabled = YES;	    
	    [self releaseSoundStream:testStream];
	} else {
	    NSLog(@"Can't enable sounds.");
	}
    } else if (!flag && soundEnabled) {
	soundEnabled = flag;
	soundStreamsAllocated -= [soundStreams count];
	[soundStreams removeAllObjects];
    }
}

+ (BOOL)soundEnabled
{
    return soundEnabled;
}

// These two methods let the client set/get the maximum number of
// sound streams to allocate. If this number is exceeded, sound requests
// are simply not honored until sound streams are freed up.

+ (void)setMaxSoundStreams:(unsigned int)max
{
    maxSoundStreams = max;
}

+ (unsigned int)maxSoundStreams
{
    return maxSoundStreams;
}

// This method returns a sound stream to be used in playing a sound.
// Sound streams allocated through this method should be given back
// via releaseSoundStream:. Note that this is for internal use only;
// it however might be overridden if necessary.

+ (NXPlayStream *)soundStream
{
    static BOOL cantPlaySounds = NO;
    static NXSoundOut *dev = nil;			// We only have one instance of this...
    NXPlayStream *newStream = nil;

    if (cantPlaySounds) return nil;	// If we've tried before and failed, just give up.
    
    if (!dev && !(dev = [[NXSoundOut alloc] init])) {	// We allocate this from the default zone so that
	NSLog(@"Couldn't create NXSoundOut");	//  freeing this zone won't accidentally blast it
	cantPlaySounds = YES;
        return nil;
    }

    if (!soundStreams) {
	soundStreams = [[NSMutableArray alloc] init];
    }

    if (![soundStreams count]) {
	if (soundStreamsAllocated < maxSoundStreams) {
	    newStream = [[NXPlayStream alloc] initOnDevice:dev];
	    soundStreamsAllocated++;
	}
    } else {
        newStream = [[soundStreams lastObject] retain];
        [soundStreams removeLastObject];
    }
    
    if (newStream) {
	if (![newStream isActive] && ([newStream activate] != NX_SoundDeviceErrorNone)) {
	    [newStream release];
	    newStream = nil;
	    soundStreamsAllocated--;
	}
    }

    return newStream;
}

// When a sound stream is released, put it on the idle list unless sounds were disabled;
// then just free it.

+ (void)releaseSoundStream:(NXPlayStream *)soundStream
{
    if ([self soundEnabled]) {
	[soundStreams addObject:soundStream];
    } else {
	[soundStream release];	// This also deactivates.
	soundStreamsAllocated--;
    }
}

// This method lets you create new instances of SoundEffect. If the specified
// sound file does not exist, the allocated instance is freed and nil is returned.

- initFromMainBundle:(NSString *)path
{
    [super init];

    if (!(sound = [Sound findSoundFor:path])) {
        if (!(sound = [Sound addName:path fromBundle:[NSBundle mainBundle]])) {
            NSLog(@"Couldn't load sound from %@", path);
            [self release];
            return nil;
        }
    }

    return self;
}

// Free frees the SoundEffect. If this sound effect is being played at the time,
// the free is delayed and happens as soon as all pending sounds are finished.

- (void)dealloc
{
    if (flags.refCount) {
	flags.freeWhenDone = YES;
	return;
    } else {
        if (sound) [sound release];
	{ [super dealloc]; return; };
    }
}

// These two methods play the sound effect.

- play
{
    return [self play:1.0 pan:0.0];
}

- play:(float)volume pan:(float)pan
{
    float left, right;
    NXPlayStream *soundStream;
    
    if (![[self class] soundEnabled]) {
    	return self;
    }

    if (!(soundStream = [[self class] soundStream])) {
	return self;
    }
    
    [soundStream setDelegate:self];

    left = right = volume;
    if (pan > 0.0) left  *= 1.0 - pan;
    else if (pan < 0.0) right *= 1.0 + pan;
    [soundStream setGainLeft:left right:right];
    if ([soundStream playBuffer:(void *)[sound data]
			    size:(unsigned int)[sound dataSize]
			    tag:0
		    channelCount:(unsigned int)[sound channelCount]
		    samplingRate:[sound samplingRate]] == NX_SoundDeviceErrorNone) {
	flags.refCount++;
    } else {
	[[self class] releaseSoundStream:soundStream];
    }

    return self;
}

// Delegate methods for internal use only.

- (void)soundStream:sender didCompleteBuffer:(int)tag
{
    flags.refCount--;
    [[self class] releaseSoundStream:sender];
    if (flags.freeWhenDone && flags.refCount == 0) {
	[self release];
    }
    return;
}

- (void)soundStreamDidAbort:sender deviceReserved:(BOOL)flag
{
    [self soundStream:sender didCompleteBuffer:0];
}

@end
#endif WIN32 /*sb: we can't do all this tricky stuff on Windows yet */