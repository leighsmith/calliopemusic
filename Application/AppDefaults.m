/* $Id$ */
#import "AppDefaults.h"
#import "MultiView.h"
#import "CalliopeAppController.h"
#import "OpusDocument.h"
#import "GraphicView.h"
#import "DrawingFunctions.h"
#import "muxlow.h"
#import <AppKit/AppKit.h>

#define INST_VERSION 0		/* for archiving: see readFromFile() */


@implementation AppDefaults

#define boolString(_x) (_x ? @"YES" : @"NO")

BOOL isBool(NSString *s)
{
  if (!s) return NO;
    if (![s length]) return NO;
  switch (*[s UTF8String])
  {
    case '1': case 'T': case 't': case 'Y': case 'y': return YES;
    default: return NO;
  }
  return NO;
}

// Returns nil if the default isn't found.
NSString *stringValueForDefault(NSString *defname)
{
//  NSString *p = (NSString *) [[NSUserDefaults standardUserDefaults] objectForKey:defname];
//  return p;
  return [[NSUserDefaults standardUserDefaults] stringForKey:defname];
}


BOOL boolValueForDefault(NSString *defname)
{
  NSString *p = stringValueForDefault(defname);
  return isBool(p);
}


int intValueForDefault(NSString *defname)
{
    NSString *p = stringValueForDefault(defname);
  return [p intValue];
}


NSColor * colorValueForDefault(NSString *defname)
{
    float r, g, b;
    NSArray *components = [stringValueForDefault(defname) componentsSeparatedByString:@","];
    if ([components count] < 3) return nil;
    r = [[components objectAtIndex:0] floatValue];
    g = [[components objectAtIndex:1] floatValue];
    b = [[components objectAtIndex:2] floatValue];
    return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
}

+ (void)initialize
{
  if (self == [AppDefaults class])
  {
      NSMutableDictionary *callDefaults = [NSMutableDictionary dictionary];
      [callDefaults setObject:@"" forKey:@"InstrumentsPathname"];
      [callDefaults setObject:@"NO" forKey:@"AutoOpenInstruments"];
      [callDefaults setObject:@"NO" forKey:@"AutoSaveInstruments"];
      [callDefaults setObject:@"~/" forKey:@"OpenPath"];
      [callDefaults setObject:@"" forKey:@"BackgroundColor"];
      [callDefaults setObject:@"" forKey:@"InkColor"];
      [callDefaults setObject:@"" forKey:@"MarkerColor"];
      [callDefaults setObject:@"" forKey:@"SelectionColor"];
      [callDefaults setObject:@"" forKey:@"InvisableColor"];
      [callDefaults setObject:@"" forKey:@"Tone1Color"];
      [callDefaults setObject:@"" forKey:@"Tone2Color"];
      [callDefaults setObject:@"YES" forKey:@"ShowVTools"];
      [callDefaults setObject:@"NO" forKey:@"ShowHTools"];
      [callDefaults setObject:@"NO" forKey:@"ShowNewPanel"];
      /* if user does not have units defined in Calliope, use the system-wide one */
      /* if the system-wide one is changed during execution of Calliope, the change is ignored
       * which should be considered a minor bug, I suppose */
      [callDefaults setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"NSMeasurementUnit"] forKey:@"Units"];
      [[NSUserDefaults standardUserDefaults] registerDefaults:callDefaults];
  }
  return;
}

- setView: (int) i
{
  switch(i)
  {
    case 0:
      [multiview replaceView: instpathview];
      break;
    case 1:
      [multiview replaceView: openpathview];
      break;
    case 2:
      [multiview replaceView: colorview];
      break;
    case 3:
      [multiview replaceView: launchview];
      break;
    case 4:
      [multiview replaceView: unitsView];
      break;
  }
  return self;
}


- setPanel: (int) i
{
  switch(i)
  {
    case 0:
        [instpathtext setStringValue:stringValueForDefault(@"InstrumentsPathname")];
      [[instswitches cellAtRow:0 column:0] setState:boolValueForDefault(@"AutoOpenInstruments")];
      [[instswitches cellAtRow:1 column:0] setState:boolValueForDefault(@"AutoSaveInstruments")];
      break;
    case 1:
        [openpathtext setStringValue:stringValueForDefault(@"OpenPath")];
      break;
    case 2:
      if (stringValueForDefault(@"BackgroundColor")) [backwell setColor:colorValueForDefault(@"BackgroundColor")];
      if (stringValueForDefault(@"InkColor")) [inkwell setColor:colorValueForDefault(@"InkColor")];
      if (stringValueForDefault(@"MarkerColor")) [markwell setColor:colorValueForDefault(@"MarkerColor")];
      if (stringValueForDefault(@"SelectionColor")) [selwell setColor:colorValueForDefault(@"SelectionColor")];
      if (stringValueForDefault(@"InvisibleColor")) [invwell setColor:colorValueForDefault(@"InvisibleColor")];
      if (stringValueForDefault(@"Tone1Color")) [t1well setColor:colorValueForDefault(@"Tone1Color")];
      if (stringValueForDefault(@"Tone2Color")) [t2well setColor:colorValueForDefault(@"Tone2Color")];
      break;
    case 3:
      [[launchswitches cellAtRow:0 column:0] setState:boolValueForDefault(@"ShowVTools")];
      [[launchswitches cellAtRow:1 column:0] setState:boolValueForDefault(@"ShowHTools")];
      [[launchswitches cellAtRow:2 column:0] setState:boolValueForDefault(@"ShowNewPanel")];
      break;
    case 4:
        [unitsPopup selectItemWithTitle:stringValueForDefault(@"Units")];
      break;
  }
  return self;
}

static NSString *colorString(int i, NSColor * c)
{
    return [NSString stringWithFormat:@"%f,%f,%f",
        [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] redComponent],
        [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] greenComponent],
        [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] blueComponent]];
}

- setDefaults: (int) i
{
    id newDefaults = [NSUserDefaults standardUserDefaults];
  switch(i)
  {
    case 0:
        [newDefaults setObject:[instpathtext stringValue] forKey:@"InstrumentsPathname"];
        [newDefaults setObject:boolString([[instswitches cellAtRow:0 column:0] state]) forKey:@"AutoOpenInstruments"];
        [newDefaults setObject:boolString([[instswitches cellAtRow:1 column:0] state]) forKey:@"AutoSaveInstruments"];
      break;
    case 1:
        [newDefaults setObject:[openpathtext stringValue] forKey:@"OpenPath"];
      break;
    case 2:
        colorInit(0, [backwell color]);
        colorInit(1, [inkwell color]);
        colorInit(2, [markwell color]);
        colorInit(3, [selwell color]);
        colorInit(4, [invwell color]);
        colorInit(5, [t1well color]);
        colorInit(6, [t2well color]);
        [[CalliopeAppController currentView] setNeedsDisplay:YES];
        [newDefaults setObject:colorString(0, [backwell color]) forKey:@"BackgroundColor"];
        [newDefaults setObject:colorString(1, [inkwell color]) forKey:@"InkColor"];
        [newDefaults setObject:colorString(2, [markwell color]) forKey:@"MarkerColor"];
        [newDefaults setObject:colorString(3, [selwell color]) forKey:@"SelectionColor"];
        [newDefaults setObject:colorString(4, [invwell color]) forKey:@"InvisableColor"];
        [newDefaults setObject:colorString(5, [t1well color]) forKey:@"Tone1Color"];
        [newDefaults setObject:colorString(6, [t2well color]) forKey:@"Tone2Color"];
      break;
    case 3:
        [newDefaults setObject:boolString([[launchswitches cellAtRow:0 column:0] state]) forKey:@"ShowVTools"];
        [newDefaults setObject:boolString([[launchswitches cellAtRow:1 column:0] state]) forKey:@"ShowHTools"];
        [newDefaults setObject:boolString([[launchswitches cellAtRow:2 column:0] state]) forKey:@"ShowNewPanel"];
        break;
    case 4:
        [newDefaults setObject:[unitsPopup stringValue] forKey:@"Units"];
  }

  [[NSUserDefaults standardUserDefaults] synchronize];
  return self;
}


- (void)awakeFromNib
{
    [choicebutton selectItemAtIndex: 0];
    [self setPanel: 0];
    [self setView: 0];
}


- hitChoice: sender
{
    int i = [choicebutton indexOfSelectedItem];
  [self setPanel: i];
  [self setView: i];
  return self;
}


- preset
{
  return [self hitChoice: self];
}


- hitSet: sender
{
    [self setDefaults: [choicebutton indexOfSelectedItem]];
  return self;
}


- hitRevert: sender
{
    return [self setPanel: [choicebutton indexOfSelectedItem]];
}


/*
 * File handling.
 */


BOOL readFromFile(NSString *f)
{
  int version;
  BOOL ok = YES;
  NSData *s;
  NSArchiver *volatile ts;
  if (!f) return NO;
  if (![f length]) return NO;
  s = [[NSData alloc] initWithContentsOfMappedFile:f];
  ts = NULL;
  if (s)
  {
    NS_DURING
      ts = [[NSUnarchiver alloc] initForReadingWithData:s];
      [ts decodeValueOfObjCType:"i" at:&version];
      if (version == INST_VERSION)
      {
        if (instlist) free(instlist);
	[ts decodeValueOfObjCType:"@" at:&instlist];
      }
      else ok = NO;
    NS_HANDLER
      ok = NO;
    NS_ENDHANDLER
    if (ts) [ts release];
  }
  if (ok)
  {
      [s release];
  }
  else
  {
      if (s) [s release];
  }
  return ok;
}


/* write instdata */

BOOL writeToFile(NSString *f)
{
  int version;
  NSArchiver *ts;
  if (!f) return NO;
  if (![f length]) return NO;
  ts = [[NSArchiver alloc] initForWritingWithMutableData:[NSMutableData data]];
  if (ts)
  {
    version = INST_VERSION;
    [ts encodeValueOfObjCType:"i" at:&version];
    [ts encodeRootObject:instlist];
    [[ts archiverData] writeToFile:f atomically:YES];
    [ts release];
    return YES;
  }
  return NO;
}


/* target of the 'OPEN' button */

- open: sender
{
    NSArray *files; //sb
    BOOL p;
    NSArray *ext = [NSArray arrayWithObject:@"inst"];

    id openpanel = [NSOpenPanel openPanel]; [openpanel setAllowsMultipleSelection:NO];

    if ([openpanel runModalForTypes:ext] == NSOKButton)
      {
        files = [openpanel filenames];
        if (files)
            if ([files count])
              {
                p = readFromFile([files objectAtIndex:0]);//sb: was fname
                if (!p)
                  {
                    NSRunAlertPanel(@"Custom Instrument Library", @"Cannot Open.", @"OK", nil, nil);
                  }
                else
                  {
                    [self preset];
                  }
              }
      }
        return self;
}


/* target of SAVE button.  Try field, then preference, then save panel */

- save: sender
{
    id savepanel;
    int i=0;
    NSString *fn = [instpathtext stringValue];
    if (!fn) i=1;
    else if (![fn length]) i=1;
    if (i)
  {
    savepanel = [[CalliopeAppController sharedApplicationController] savePanel: @"inst"];
    if ([savepanel runModal] == NSCancelButton) return self;
    fn = [savepanel filename];
    [instpathtext setStringValue:fn];
  }
  if (!writeToFile(fn))
  {
    NSRunAlertPanel(@"Custom Instrument Library", @"Cannot Save.", @"OK", nil, nil);
  }
  else
  {
  
  }
  return self;
}


/* target of REVERT button */

- revert: sender
{
  NSString *fn;
  BOOL q;
  int i=0;
  fn = [instpathtext stringValue];
  if (!fn) i=1;
  else if (![fn length]) i=1;
  if (i)
  {
    NSRunAlertPanel(@"Custom Instrument Library", @"No file from which to revert", @"OK", nil, nil);
    return self;
  }
  q = readFromFile(fn);
  if (!q) NSRunAlertPanel(@"Custom Instrument Library", @"I/O error.  Cannot Revert.", @"OK", nil, nil);
  else
  {
    [self preset];
  }
  return self;
}


/* called on application open and close */


- checkOpenFromFile
{
  int dummyVariableWhichShouldBeZero = 0;  // but isn't due to stack problems
  NSString *fn = nil;

    NSString *strVal = nil;
    strVal = stringValueForDefault(@"BackgroundColor");
    if (strVal != nil) {
        NSLog(@"for some fucked up reason this is not nil? %x %x\n", strVal, dummyVariableWhichShouldBeZero);
        colorInit(0, colorValueForDefault(@"BackgroundColor"));
    }
    if (stringValueForDefault(@"InkColor") != nil) colorInit(1, colorValueForDefault(@"InkColor"));
    if (stringValueForDefault(@"MarkerColor") != nil) colorInit(2, colorValueForDefault(@"MarkerColor"));
    if (stringValueForDefault(@"SelectionColor") != nil) colorInit(3, colorValueForDefault(@"SelectionColor"));
    if (stringValueForDefault(@"InvisibleColor") != nil) colorInit(4, colorValueForDefault(@"InvisibleColor"));
    if (stringValueForDefault(@"T1Color") != nil) colorInit(5, colorValueForDefault(@"T1Color"));
    if (stringValueForDefault(@"T2Color") != nil) colorInit(6, colorValueForDefault(@"T2Color"));
    if (boolValueForDefault(@"AutoOpenInstruments"))
    {
        fn = stringValueForDefault(@"InstrumentsPathname");
        if (!readFromFile(fn))
            NSRunAlertPanel(@"Custom Instrument Library", [NSString stringWithFormat:@"Cannot Open: %@.",fn], @"OK", nil, nil);
    }
    return self;
}


- checkSaveToFile
{
  NSString *fn;
  if (boolValueForDefault(@"AutoSaveInstruments"))
  {
    fn = stringValueForDefault(@"InstrumentsPathname");
    if (!writeToFile(fn))
        NSRunAlertPanel(@"Custom Instrument Library", [NSString stringWithFormat:@"Cannot Save: %@.",fn], @"OK", nil, nil);
  }
  return self;
}


- (BOOL) checkOpenPanel: (int) i
{
  switch (i)
  {
    case 0:
      return (boolValueForDefault(@"ShowVTools"));
    case 1:
      return (boolValueForDefault(@"ShowHTools"));
    case 2:
      return (boolValueForDefault(@"ShowNewPanel"));
  }
  return NO;
}


- (NSString *) getDefaultOpenPath
{
  return stringValueForDefault(@"OpenPath");
}


@end
