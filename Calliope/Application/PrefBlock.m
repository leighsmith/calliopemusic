#import "DrawApp.h"
#import "DrawDocument.h"
#import "PrefBlock.h"
#import "GraphicView.h"
#import "GVPerform.h"
#import "Preferences.h"
#import "mux.h"
#import "muxlow.h"
#import <AppKit/AppKit.h>

@implementation PrefBlock


+ (void)initialize
{
  if (self == [PrefBlock class])
  {
      (void)[PrefBlock setVersion: 10];	/* class version, see read: */ /* sb: bumped up to 10 for OS conversion */
  }
  return;
}


+ readFromFile: (NSString *) f
{
    NSData *s = [NSData dataWithContentsOfMappedFile:f];
    NSArchiver *volatile ts = NULL;
    PrefBlock *p = nil;
    if (s)
      {
    NS_DURING
        ts = [[NSUnarchiver alloc] initForReadingWithData:s];
        if (ts)  p = [[ts decodeObject] retain];
    NS_HANDLER
        p = nil;
    NS_ENDHANDLER
    if (ts) [ts release];
  }
  return p;
}


- init
{
  [super init];
  tabflag = 0;
  barplace = 3;
  usestyle = 0;
  barsurround = 0;
  barevery = 5;
  unitflag = 0;
  barnumfirst = 0;
  barnumlast = 0;
  pathname = nil;
  stylepath = nil;
  staffheight = 21.259845;
  minsysgap = 6;
  maxbalgap = 12;
  barfont = [[NSFont fontWithName: @"Times-Italic" size: 16.0] retain];
  tabfont = [[NSFont fontWithName: @"Times-Italic" size: 18.0] retain];
  figfont = [[NSFont fontWithName: @"Times-Roman"  size: 16.0] retain];
  texfont = [[NSFont fontWithName: @"Times-Roman"  size: 18.0] retain];
  runfont = [[NSFont fontWithName: @"Times-Roman"  size: 12.0] retain];
  return self;
}


- newFrom
{
  PrefBlock *p = [[PrefBlock alloc] init];
  p->tabflag = tabflag;
  p->barplace = barplace;
  p->barevery = barevery;
  p->usestyle = usestyle;
  p->barsurround = barsurround;
  p->unitflag = unitflag;
  p->barnumfirst = barnumfirst;
  p->barnumlast = barnumlast;
  p->pathname = (pathname == nil) ? nil : [[pathname copy] retain];
  p->stylepath = (stylepath == nil) ? nil : [[stylepath copy] retain];
  p->staffheight = staffheight;
  p->minsysgap = minsysgap;
  p->maxbalgap = maxbalgap;
  p->barfont = barfont;
  p->tabfont = tabfont;
  p->figfont = figfont;
  p->texfont = texfont;
  p->runfont = runfont;
  return p;
}


- (void)dealloc
{
    if (stylepath) [stylepath release];
    if (pathname) [pathname release];
    [super dealloc];
}


/* clumsy but not much choice unless we put an array in the instance? Hmm...*/

- (int)intValueAt:(int)i
{
  switch(i)
  {
    case BARNUMFIRST:
      return barnumfirst;
    case BARNUMLAST:
      return barnumlast;
    case BARNUMPLACE:
      return barplace;
    case TABCROTCHET:
      return tabflag;
    case BARNUMSURROUND:
      return barsurround;
    case UNITS: 
      return unitflag;
    case USESTYLE: 
      return usestyle;
    case BAREVERY: 
      return barevery;
  }          
  return 0;  
}            

- (NSFont *) fontValueAt: (int) i
{
  switch(i)
  {
    case BARFONT:
      return barfont;
    case TABFONT:
      return tabfont;
    case FIGFONT:
      return figfont;
    case TEXFONT:
      return texfont;
    case RUNFONT:
      return runfont;
  }
  return nil;
}

- (float)floatValueAt:(int)i
{
  switch(i)
  {
    case STAFFHEIGHT:
      return staffheight;
    case MINSYSGAP:
      return minsysgap * (staffheight / 4);
    case MAXBALGAP:
      return maxbalgap * (staffheight / 4);
  }
  return 0.0;
}

- setFloatValue:(float)v at:(int)i
{
  switch(i)
  {
    case STAFFHEIGHT:
      staffheight = v;
      break;
  }
  return self;
}

- (NSString *)stringValueAt:(int)i
{
  switch(i)
  {
    case STYLEPATH:
        return stylepath;
  }
  return nil;
}

- setStringValue:(NSString *)v at:(int)i
{
  switch(i)
  {
    case STYLEPATH:
        if (stylepath != NULL) [stylepath autorelease];
      stylepath = [[v copy] retain];
      break;
  }
  return self;
}

- setIntValue:(int)v at:(int)i;
{
  switch(i)
  {
    case BARNUMPLACE:
      barplace = v;
      break;
    case TABCROTCHET:
      tabflag = v;
      break;
    case BARNUMSURROUND:
      barsurround = v;
      break;
    case UNITS: 
      unitflag = v;
      break;
    case USESTYLE: 
      usestyle = v;
      break;
    case BAREVERY: 
      barevery = v;
      break;
  }
  return self;      
}


/* File handling for the PrefBlock */

/* write a PrefBlock to self's pathname, returning self or nil */

- backup
{
    NSArchiver *ts;
    if (!pathname) return nil;
    if (![pathname length]) return nil;
    ts = [[NSArchiver alloc] initForWritingWithMutableData:[NSMutableData data]];
    if (ts)
      {
        [ts encodeRootObject:self];
        [[ts archiverData] writeToFile:pathname atomically:YES];
        [ts release];
        return self;
      }
    return nil;
}


/*
  read a PrefBlock from self's pathname,
  and return a pointer to the new one (or nil if failed).
*/

- revert
{
    if (!pathname) return nil;
    if (![pathname length]) return nil;
  return [PrefBlock readFromFile: pathname];
}


/* see whether to read a shared style file */

- (BOOL) checkStyleFromFile: (GraphicView *) v
{
  if (!usestyle) return YES;
  return [[NSApp thePreferences] getStyleFromFile: stylepath : v];
}


/* The usual read and write */

- (id)initWithCoder:(NSCoder *)aDecoder
{
  int v = [aDecoder versionForClassName:@"PrefBlock"];
    char *p,*s;
//  [super initWithCoder:aDecoder];// sb: unnec
  minsysgap = 6;
  maxbalgap = 12;
  barevery = 5;
  usestyle = 0;
  barfont = nil;
  tabfont = nil;
  figfont = nil;
  texfont = nil;
  runfont = nil;
  if (v == 0)
  {
    [aDecoder decodeValuesOfObjCTypes:"*cccc", &p, &unitflag, &tabflag, &barplace, &barsurround];
      if (p) pathname = [[NSString stringWithCString:p] retain]; else pathname = nil;
  }
  else if (v == 1)
  {
    [aDecoder decodeValuesOfObjCTypes:"*cccc", &p, &unitflag, &tabflag, &barplace, &barsurround];
    [aDecoder decodeValuesOfObjCTypes:"cc@@", &barnumfirst, &barnumlast, &barfont, &tabfont];
    if (p) pathname = [[NSString stringWithCString:p] retain]; else pathname = nil;
  }
  else if (v == 2)
  {
    [aDecoder decodeValuesOfObjCTypes:"*cccc", &p, &unitflag, &tabflag, &barplace, &barsurround];
    [aDecoder decodeValuesOfObjCTypes:"cc@@@", &barnumfirst, &barnumlast, &barfont, &tabfont, &figfont];
    if (p) pathname = [[NSString stringWithCString:p] retain]; else pathname = nil;
  }
  else if (v == 3)
  {
    [aDecoder decodeValuesOfObjCTypes:"*cccc", &p, &unitflag, &tabflag, &barplace, &barsurround];
    [aDecoder decodeValuesOfObjCTypes:"cc@@@@", &barnumfirst, &barnumlast, &barfont, &tabfont, &figfont, &texfont];
    if (p) pathname = [[NSString stringWithCString:p] retain]; else pathname = nil;
  }
  else if (v == 4)
  {
    [aDecoder decodeValuesOfObjCTypes:"*ccccf", &p, &unitflag, &tabflag, &barplace, &barsurround, &staffheight];
    [aDecoder decodeValuesOfObjCTypes:"cc@@@@", &barnumfirst, &barnumlast, &barfont, &tabfont, &figfont, &texfont];
    if (p) pathname = [[NSString stringWithCString:p] retain]; else pathname = nil;
  }
  else if (v == 5)
  {
    [aDecoder decodeValuesOfObjCTypes:"*ccccf", &p, &unitflag, &tabflag, &barplace, &barsurround, &staffheight];
    [aDecoder decodeValuesOfObjCTypes:"cc@@@@", &barnumfirst, &barnumlast, &barfont, &tabfont, &figfont, &texfont];
    [aDecoder decodeValueOfObjCType:"*" at:&s];
    if (p) pathname = [[NSString stringWithCString:p] retain]; else pathname = nil;
    if (s) stylepath = [[NSString stringWithCString:s] retain]; else stylepath = nil;
  }
  else if (v == 6)
  {
    [aDecoder decodeValuesOfObjCTypes:"*ccccf", &p, &unitflag, &tabflag, &barplace, &barsurround, &staffheight];
    [aDecoder decodeValuesOfObjCTypes:"cc@@@@", &barnumfirst, &barnumlast, &barfont, &tabfont, &figfont, &texfont];
    [aDecoder decodeValuesOfObjCTypes:"*ff", &s, &minsysgap, &maxbalgap];
    if (p) pathname = [[NSString stringWithCString:p] retain]; else pathname = nil;
    if (s) stylepath = [[NSString stringWithCString:s] retain]; else stylepath = nil;
  }
  else if (v == 7)
  {
    [aDecoder decodeValuesOfObjCTypes:"*cccccf", &p, &unitflag, &tabflag, &barplace, &barsurround, &usestyle, &staffheight];
    [aDecoder decodeValuesOfObjCTypes:"cc@@@@", &barnumfirst, &barnumlast, &barfont, &tabfont, &figfont, &texfont];
    [aDecoder decodeValuesOfObjCTypes:"*ff", &s, &minsysgap, &maxbalgap];
    if (p) pathname = [[NSString stringWithCString:p] retain]; else pathname = nil;
    if (s) stylepath = [[NSString stringWithCString:s] retain]; else stylepath = nil;
  }
  else if (v == 8)
  {
    [aDecoder decodeValuesOfObjCTypes:"*cccccf", &p, &unitflag, &tabflag, &barplace, &barsurround, &usestyle, &staffheight];
    [aDecoder decodeValuesOfObjCTypes:"cc@@@@@", &barnumfirst, &barnumlast, &barfont, &tabfont, &figfont, &texfont, &runfont];
    [aDecoder decodeValuesOfObjCTypes:"*ff", &s, &minsysgap, &maxbalgap];
    if (p) pathname = [[NSString stringWithCString:p] retain]; else pathname = nil;
    if (s) stylepath = [[NSString stringWithCString:s] retain]; else stylepath = nil;
  }
  else if (v == 9)
  {
    [aDecoder decodeValuesOfObjCTypes:"*cccccf", &p, &unitflag, &tabflag, &barplace, &barsurround, &usestyle, &staffheight];
    [aDecoder decodeValuesOfObjCTypes:"cc@@@@@", &barnumfirst, &barnumlast, &barfont, &tabfont, &figfont, &texfont, &runfont];
    [aDecoder decodeValuesOfObjCTypes:"*ffi", &s, &minsysgap, &maxbalgap, &barevery];
    if (p) pathname = [[NSString stringWithCString:p] retain]; else pathname = nil;
    if (s) stylepath = [[NSString stringWithCString:s] retain]; else stylepath = nil;
  }
  else if (v == 10)
  {
      [aDecoder decodeValuesOfObjCTypes:"@cccccf", &pathname, &unitflag, &tabflag, &barplace, &barsurround, &usestyle, &staffheight];
    [aDecoder decodeValuesOfObjCTypes:"cc@@@@@", &barnumfirst, &barnumlast, &barfont, &tabfont, &figfont, &texfont, &runfont];
    [aDecoder decodeValuesOfObjCTypes:"@ffi", &stylepath, &minsysgap, &maxbalgap, &barevery];
  }
  if (!barfont) barfont = [NSFont fontWithName: @"Times-Italic" size: 16.0];
  if (!tabfont) tabfont = [NSFont fontWithName: @"Times-Italic" size: 18.0];
  if (!figfont) figfont = [NSFont fontWithName: @"Times-Roman"  size: 16.0];
  if (!texfont) texfont = [NSFont fontWithName: @"Times-Roman"  size: 18.0];
  if (!runfont) runfont = [NSFont fontWithName: @"Times-Roman"  size: 12.0];

  return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
//  [super encodeWithCoder:aCoder];//sb: unnec
  [aCoder encodeValuesOfObjCTypes:"@cccccf", &pathname, &unitflag, &tabflag, &barplace, &barsurround, &usestyle, &staffheight];
  [aCoder encodeValuesOfObjCTypes:"cc@@@@@", &barnumfirst, &barnumlast, &barfont, &tabfont, &figfont, &texfont, &runfont];
  [aCoder encodeValuesOfObjCTypes:"@ffi", &stylepath, &minsysgap, &maxbalgap, &barevery];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [aCoder setString:pathname forKey:@"pathname"];
    [aCoder setInteger:unitflag forKey:@"unitflag"];
    [aCoder setInteger:tabflag forKey:@"tabflag"];
    [aCoder setInteger:barplace forKey:@"barplace"];
    [aCoder setInteger:barsurround forKey:@"barsurround"];
    [aCoder setInteger:usestyle forKey:@"usestyle"];
    [aCoder setFloat:staffheight forKey:@"staffheight"];

    [aCoder setInteger:barnumfirst forKey:@"bnfirst"];
    [aCoder setInteger:barnumlast forKey:@"bnlast"];
    [aCoder setObject:barfont forKey:@"barfont"];
    [aCoder setObject:tabfont forKey:@"tabfont"];
    [aCoder setObject:figfont forKey:@"figfont"];
    [aCoder setObject:texfont forKey:@"texfont"];
    [aCoder setObject:runfont forKey:@"runfont"];

    [aCoder setString:stylepath forKey:@"stylepath"];
    [aCoder setFloat:minsysgap forKey:@"minsysgap"];
    [aCoder setFloat:maxbalgap forKey:@"maxbalgap"];
    [aCoder setInteger:barevery forKey:@"barevery"];
}

@end
