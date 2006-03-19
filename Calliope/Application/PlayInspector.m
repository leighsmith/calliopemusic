#import "PlayInspector.h"
#import "KeyboardFilter.h"
#import "DrawApp.h"
#import "DrawDocument.h"
#import "GraphicView.h"
#import "GVPerform.h"
#import "GVSelection.h"
#import "Staff.h"
#import "SoundEffect.h"
#import "MultiView.h"
#import "Channel.h"
#import "mux.h"
#import "muxlow.h"
#import <MusicKit/MusicKit.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSSliderCell.h>
#ifdef WIN32
#import <SndKit/SndKit.h>
#endif

@implementation PlayInspector

#define MM 72.0
#define MAXSLIDER 144.0

extern MKMidi *midi;
extern KeyboardFilter *kf;

int playmode;			/* 0 = internal orchestra, 1 = scorefile, 2 = MIDI-A, 3 = MIDI-B, 4 = MIDI file */
MKPerformerStatus status;	/* The status of a performance */

#if !defined(WIN32) && !defined(__APPLE__)
SoundEffect *tickSound = nil;
#else
Snd *tickSound = nil;
#endif

NSTimer *timer, *blinker;
BOOL canRecord[5] = {NO, NO, YES, YES, NO};
NSString *midiDev[5] = {nil, nil, @"midi0", @"midi1", nil};

float tempoFactor[2] = {1.0, 2.0};


/* click the metronome */
- (void)tickTock:(NSTimer *)theTimer
{
    [tickSound play];
}

/* blink the insertion point */
/* state: <0 disabled, 0/1 blink, 2 desire switch off */

static int blinkstate = -1;
static float bx, by, bdy;
static Staff *bsp;

static void blinkOn(GraphicView *v)
{
  if (![v getBlinkX: &bx : &bsp]) return;
  by = bsp->y;
  bdy = [bsp staffHeight];
  [v lockFocus];
  cline(bx, by, bx, by + bdy, 0, 7);
  [v unlockFocus];
  [[v window] flushWindow];
}


static void blinkOff(GraphicView *v)
{
  NSRect r;
  r.origin.x = bx - 1;
  r.origin.y = by - 1;
  r.size.width = 4;
  r.size.height = bdy + 1;
  [v cache: r];
  [[v window] flushWindow];
}

- (void) blinkBlink:(NSTimer *)theTimer
{
    GraphicView *v;
    if (blinkstate < 0) return;
    v = [[DrawApp currentDocument] graphicView];
    if ([[NSApp keyWindow] firstResponder] != v) return;
    switch (blinkstate)
    {
      case 0:
        blinkOn(v);
        blinkstate = 1;
        break;
      case 1:
        blinkOff(v);
        blinkstate = 0;
        break;
     case 2:
        [blinker invalidate]; [blinker release];;
        if (blinkstate == 1) blinkOff(v);
        blinkstate = -1;
    }
}

- setView: (int) i
{
  switch(i)
  {
    case 0:
      [multiview replaceView: outputview];
      break;
    case 1:
      if ([NSApp getChanlist] == nil) [multiview replaceView: nodocview];
      else [multiview replaceView: channelview];
      break;
    case 2:
      [multiview replaceView: recordview];
      break;
  }
  return self;
}


- (void)awakeFromNib
{
    [self preset: MM];
#if !defined(WIN32) && !defined(__APPLE__)
    tickSound = [[SoundEffect allocWithZone:[self zone]] initFromMainBundle:@"tick"];
#else
//    tickSound = [[Snd allocWithZone:[self zone]] initFromMainBundle:@"tick"];
    tickSound = [[Snd allocWithZone:[self zone]] init];
#endif
    [self setView: 0];
}


- (void)dealloc
{
    [tickSound release];
    [super dealloc];
}


- hitChannel: sender
{
  int c = [[channelmatrix selectedCell] tag];
  Channel *ch;
  NSMutableArray *cl = [NSApp getChanlist];
  if (cl == nil) return self;
  ch = [cl objectAtIndex:c];
  [[slidermatrix cellAtRow:0 column:0] setFloatValue:ch->level];
  [[slidermatrix cellAtRow:1 column:0] setFloatValue:ch->pan];
  [[slidermatrix cellAtRow:2 column:0] setFloatValue:ch->reverb];
  [[slidermatrix cellAtRow:3 column:0] setFloatValue:ch->chorus];
  [[slidermatrix cellAtRow:4 column:0] setFloatValue:ch->vibrato];
  return self;
}


- hitSlider: sender
{
  id cell = [sender selectedCell];
  int s = [cell tag];
  int c = [[channelmatrix selectedCell] tag];
  float f = [sender floatValue];
  Channel *ch;
  NSMutableArray *cl = [NSApp getChanlist];
  if (cl == nil) return self;
  ch = [cl objectAtIndex:c];
  switch(s)
  {
    case 0:
      ch->level = f;
      break;
    case 1:
      ch->pan = f;
      break;
    case 2:
      ch->reverb = f;
      break;
    case 3:
      ch->chorus = f;
      break;
    case 4:
      ch->vibrato = f;
      break;
  }
  [[[DrawApp currentDocument] graphicView] dirty];
  return self;
}


- hitOption: sender
{
    [self setView: [multipopup indexOfSelectedItem]];
  return self;
}

- hitPause:sender
{
  if ([sender state])
  {
    if (status == MK_inactive)
    {
        [MKConductor sendMsgToApplicationThreadSel: @selector(unsetPauseButton) to: self argCount: 0];
      return self;
    }
    status = MK_paused;
      [MKConductor lockPerformance];
      [MKConductor pausePerformance];
    [[[DrawApp currentDocument] graphicView] pausePlayers];
    if (![pausebutton state]) [pausebutton setState:1];
    [MKConductor unlockPerformance];
  }
  else
  {
    if (status != MK_paused) return self;
    status = MK_active;
    [MKConductor sendMsgToApplicationThreadSel: @selector(unsetPauseButton) to: self argCount: 0];
    [MKConductor lockPerformance];
    [[[DrawApp currentDocument] graphicView] resumePlayers];
    [MKConductor resumePerformance];
    [MKConductor unlockPerformance];
  }
  return self;
}


- unsetPauseButton
{
  if ([pausebutton state]) [pausebutton setState:0];
  // PSWait();
  return self;
}


- unsetStopButton
{
  if ([stopbutton state]) [stopbutton setState:0];
  // PSWait();
  return self;
}


- clickStopButton
{
  [stopbutton performClick:self];
  // PSWait();
  return self;
}


- hitStop:sender
{
    if (status == MK_inactive)
    {
        [self unsetStopButton];
        return self;
    }
    blinkstate = 2;
    if (![stopbutton state]) [stopbutton setState:1];
    [MKConductor lockPerformance];
    [[[DrawApp currentDocument] graphicView] deactivatePlayers];
    [MKConductor unlockPerformance];
    [playbutton setState:0];
    [playbutton setEnabled:YES];
    [pausebutton setEnabled:YES];
    [pausebutton setState:0];
    [recordbutton setEnabled:YES];
    [recordbutton setState:0];
    [stopbutton setState:0];
    // PSWait();
    if (status != MK_inactive)
    {
        [MKConductor lockPerformance];
        [MKConductor finishPerformance];
        [MKConductor unlockPerformance];
        [midi allNotesOff];
        [midi stop];
        [midi abort];
        [MKOrchestra abort];
        status = MK_inactive;
    }
    [NSApp thePlayView: nil];
    return self;
}


/* reset times in sec units */

- resetTimers: (float) t
{
    if ([metrobutton state])
    {
        [timer invalidate];
        [timer release];
        timer = [[NSTimer scheduledTimerWithTimeInterval:t
                                                  target:self
                                                selector:@selector(tickTock:)
                                                userInfo:self
                                                 repeats:YES] retain];
    }
    if (blinkstate >= 0 && blinkstate < 2)
    {
        [blinker invalidate];
        [blinker release];
        blinker = [[NSTimer scheduledTimerWithTimeInterval:0.5 * t
                                                    target:self
                                                  selector:@selector(blinkBlink:)
                                                  userInfo:self
                                                   repeats:YES] retain];
    }
    return self;
}


- hitTempo: sender
{
  float t = MAXSLIDER * [tempoSlider floatValue];
  [tempoText setIntValue:(int) (t + 0.5)];
  [[MKConductor defaultConductor] setTempo: t / tempoFactor[[tempoButton state]]];
  [self resetTimers: (60.0 / t)];
  return self;
}


- hitTempoText: sender
{
  float t = [tempoText floatValue];
  [tempoSlider setFloatValue:t / MAXSLIDER];
  [[MKConductor defaultConductor] setTempo: t / tempoFactor[[tempoButton state]]];
  [self resetTimers: (60.0 / t)];
  return self;
}


- hitPlay:sender
{
  int i, j;
  if ([pausebutton state]) return self;
  if ([MKConductor inPerformance]) return self;
  i = [startlist indexOfItemWithTitle:[startlist title]];
  j = [endlist indexOfItemWithTitle:[endlist title]];
  status = MK_active;
  if (![playbutton state]) [playbutton setState:1];
  // PSWait();
  [MKConductor lockPerformance];
  [MKConductor finishPerformance];
  [MKConductor unlockPerformance];
  playmode = [[outputmatrix selectedCell] tag];
  [playbutton setEnabled:NO];
  [[[DrawApp currentDocument] graphicView] playChoice: i : j : [selectswitch state] : [progchbutton state]];
  return self;
}


- hitRecord:sender
{
  if ([pausebutton state]) return self;
    if ([MKConductor inPerformance]) return self;
  playmode = [[outputmatrix selectedCell] tag];
  if (!canRecord[playmode]) return self;
  // MKSetErrorProc(handleMKError); /* Intercept Music Kit errors. */
  status = MK_active;
  if (![recordbutton state]) [recordbutton setState:1];
  // PSWait();
  midi = [MKMidi midiOnDevice: midiDev[playmode]];
  [midi setUseInputTimeStamps:YES]; 
  [midi open];
  if (!kf) kf = [[KeyboardFilter alloc] init];
  if (![[midi channelNoteSender: 1] isConnected: [kf noteReceiver]])
  	[[midi channelNoteSender: 1] connect: [kf noteReceiver]];
  if (![[kf noteSender] isConnected: [midi channelNoteReceiver: 1]])
  	[[kf noteSender] connect: [midi channelNoteReceiver: 1]];
  [MKConductor setThreadPriority: 1.0];
  [MKConductor setFinishWhenEmpty: NO];   
  [recordbutton setEnabled:NO];
  [midi run];
  [MKConductor startPerformance];
  blinkstate = 0;

  blinker = [[NSTimer scheduledTimerWithTimeInterval:0.5 * (60.0 / [self getTempo])
                                              target:self
                                            selector:@selector(blinkBlink:)
                                            userInfo:self
                                             repeats:YES] retain];
  return self;
}


/* The complication here is achieving a consistent state for interaction of tempo slider */

- hitMetro: sender
{
#if !defined(WIN32) && !defined(__APPLE__)
    if ([metrobutton state]) {
        [SoundEffect setSoundEnabled: YES];
        if ([SoundEffect soundEnabled])
          {
            [tickSound play];
            timer = [[NSTimer scheduledTimerWithTimeInterval:60.0 / [self getTempo]
                                                      target:self
                                                    selector:@selector(tickTock:)
                                                    userInfo:self
                                                     repeats:YES] retain];
          }
        else [metrobutton setState:NO];
    }
    else
      {
        if ([SoundEffect soundEnabled])
          {
            [SoundEffect setSoundEnabled: NO];
            [timer invalidate];
            [timer release];
          }
      }
#endif
    return self;
}


- setTempo: (int) t
{
  float f = ((float) t)  * tempoFactor[[tempoButton state]];
  if (f > MAXSLIDER)
  {
    [tempoButton setState:0];
  }
  else if (f < 30)
  {
    [tempoButton setState:1];
  }
  f = ((float) t)  * tempoFactor[[tempoButton state]];
  [tempoSlider setFloatValue:(f / MAXSLIDER)];
  [tempoText setIntValue: (int) f];
  return self;
}


- preset: (float) m
{
  if (m > 0)
  {
    m *= tempoFactor[[tempoButton state]];
    [tempoSlider setFloatValue:(float) (m / MAXSLIDER)];
    [tempoText setIntValue:(int) (m + 0.5)];
  }
  else
  {
    [playbutton setState:0];
    [pausebutton setState:0];
    [stopbutton setState:0];
  }
  return self;
}


- loadView: (int) i
{
  switch(i)
  {
    case 0:
      break;
    case 1:
      [self hitChannel: self];
      break;
    case 2:
      break;
  }
  return self;
}


- reflectSelection
{
    int i = [multipopup indexOfSelectedItem];
  [self loadView: i];
  [self setView: i];
  return self;
}


- (float) getTempo
{
  return [tempoSlider floatValue] * MAXSLIDER / tempoFactor[[tempoButton state]];
}


- (BOOL) getFeedback
{
  return [feedbackswitch state];
}


- (int) getRecordType
{
    return [durchoicematrix indexOfItemWithTitle:[durchoicematrix title]];
}

@end
