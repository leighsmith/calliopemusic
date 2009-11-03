/* $Id$ */
/* Generated by Interface Builder */

#import <AppKit/AppKit.h>
#import "CallInst.h"
#import "FileCompatibility.h"

extern NSString *nullInstrument;

@implementation NSMutableArray(InstCell)


- (NSString *) instNameForInt: (int) i 
{
  if (i < 0 || i > [self count]) return nullInstrument;
  return ((CallInst *)[self objectAtIndex:i])->name;
}


- (CallInst *) instNamed: (NSString *) inst
{
  CallInst *ci;
  int k = [self count];
  while (k--)
  {
    ci = [self objectAtIndex:k];
      if ([ci->name isEqualToString:inst]) return ci;
  }
  return nil;
}


- (int) indexOfInstName: (NSString *) inst
{
  CallInst *ci;
  int k = [self count];
  while (k--)
  {
    ci = [self objectAtIndex:k];
      if ([ci->name isEqualToString:inst]) return k;
  }
  return -1;
}


- (int) indexOfInstString: (NSString *) inst
{
  CallInst *ci;
  int k = [self count];
  while (k--)
  {
    ci = [self objectAtIndex:k];
      if ([ci->name isEqualToString:inst]) return k;
  }
  return -1;
}


- (int) soundForInstrument: (NSString *) inst
{
  CallInst *ci;
  int k = [self count];
  while (k--)
  {
    ci = [self objectAtIndex:k];
      if ([ci->name isEqualToString:inst]) return ci->sound;
  }
  return 0;
}


- (NSMutableArray *) tuningForInstrument: (NSString *) inst
{
  CallInst *ci;
  int k = [self count];
  while (k--)
  {
    ci = [self objectAtIndex:k];
      if ([ci->name isEqualToString:inst]) return ci->tuning;
  }
  return nil;
}


- (int) transForInstrument: (NSString *) inst
{
  CallInst *ci;
  int k = [self count];
  while (k--)
  {
    ci = [self objectAtIndex:k];
      if ([ci->name isEqualToString:inst]) return ci->trans;
  }
  return 0;
}


/*
  The sort is required to be fastest when elements are in order. Shellsort.
*/

#define STRIDE_FACTOR 3

- sortInstlist
{
  int c, d, f, s, k;
  CallInst *p;
  k = [self count];
  s = 1;
  while (s <= k) s = s * STRIDE_FACTOR + 1;
  while (s > (STRIDE_FACTOR - 1))
  {
    s = s / STRIDE_FACTOR;
    for (c = s; c < k; c++)
    {
      f = NO;
      d = c - s;
      while ((d >= 0) && !f)
      {
//        if (strcmp(((CallInst *)[self objectAt: d + s])->name, ((CallInst *)[self objectAt: d])->name) < 0)
          if ([((CallInst *)[self objectAtIndex:d + s])->name compare:((CallInst *)[self objectAtIndex:d])->name] == NSOrderedAscending)
	{
	  p = [[self objectAtIndex:d] retain];
	  [self replaceObjectAtIndex:d withObject:[self objectAtIndex:d + s]];
	  [self replaceObjectAtIndex:d + s withObject:p];
          [p release];
	  d -= s;
	}
	else f = YES;
      }
    }
  }
  return self;
}

@end



@implementation CallInst:NSObject


+ (void)initialize
{
  if (self == [CallInst class])
  {
      (void)[CallInst setVersion: 2];	/* class version, see read: */ /*sb: bumped up to 2 for OS conversion */
  }
  return;
}

/* NB: ch used to be channel, but is now vacant */

- init: (NSString *) n : (NSString *) a : (int) tr : (int) ch : (int) tab : (int) snd : (NSMutableArray *) tl
{
    [super init];
//    name = NXUniqueString(n);
    name = [n retain];
    if (a == nil) abbrev = nil; else abbrev = [a retain];
    trans = tr;
    istab = tab;
    sound = snd;
    tuning = [tl retain];
    return self;
}


- update:  (NSString *) n : (NSString *) a : (int) tr : (int) ch : (int) tab : (int) snd
{
//  name = NXUniqueString(n);
    [name autorelease];
    name = [n retain];

    if (abbrev) [abbrev autorelease];
    if (a) abbrev = [a retain];

    trans = tr;
    istab = tab;
    sound = snd;
    return self;
}


- (void) dealloc
{
    [abbrev release];
    abbrev = nil;
    [name release];
    name = nil;
    [super dealloc];  
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    int v;
    char * n,*a;
    v = [aDecoder versionForClassName:@"CallInst"];
    if (v == 0)
      {
//      [aDecoder decodeValuesOfObjCTypes:"**@cccc", &name, &abbrev, &tuning, &trans, &channel, &istab, &sound];
        [aDecoder decodeValuesOfObjCTypes:"**@cccc", &n, &a, &tuning, &trans, &channel, &istab, &sound];
//    name = NXUniqueStringNoCopy(name);
        if (n) name = [[NSString stringWithUTF8String:n] retain]; else name = nil;
        if (a) abbrev = [[NSString stringWithUTF8String:a] retain]; else abbrev = nil;
      }
    else if (v == 1)
      {
//      [aDecoder decodeValuesOfObjCTypes:"%*@cccc", &name, &abbrev, &tuning, &trans, &channel, &istab, &sound];
        [aDecoder decodeValuesOfObjCTypes:"%*@cccc", &n, &a, &tuning, &trans, &channel, &istab, &sound];
        if (n) name = [[NSString stringWithUTF8String:n] retain]; else name = nil;
        if (a) abbrev = [[NSString stringWithUTF8String:a] retain]; else abbrev = nil;
      }
    else if (v == 2)
      {
        [aDecoder decodeValuesOfObjCTypes:"@@@cccc", &name, &abbrev, &tuning, &trans, &channel, &istab, &sound];
      }

    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
//  [super encodeWithCoder:aCoder]; //sb: don't think this is necessary
//  [aCoder encodeValuesOfObjCTypes:"%*@cccc", &name, &abbrev, &tuning, &trans, &channel, &istab, &sound];
    [aCoder encodeValuesOfObjCTypes:"@@@cccc", &name, &abbrev, &tuning, &trans, &channel, &istab, &sound];
}

- (void)encodeWithPropertyListCoder:(OAPropertyListCoder *)aCoder
{
    [aCoder setString:name forKey:@"name"];
    [aCoder setString:abbrev forKey:@"abbrev"];
    [aCoder setObject:tuning forKey:@"tuning"];
    [aCoder setInteger:trans forKey:@"trans"];
    [aCoder setInteger:channel forKey:@"channel"];
    [aCoder setInteger:istab forKey:@"istab"];
    [aCoder setInteger:sound forKey:@"sound"];
}

@end
