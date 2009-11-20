#import <AppKit/AppKit.h>
#import "GraphicView.h"
#import "GVMenu.h"
#import "GVCommands.h"
#import "GNote.h"
#import "DrawingFunctions.h"
#import "muxlow.h"

@implementation GraphicView(NSMenu)

extern NSString * DrawPasteType(NSArray *types);

/*
 * Can be called to see if the specified action is valid on this view now.
 * It returns NO if the GraphicView knows that action is not valid now,
 * otherwise it returns YES.  Note the use of the Pasteboard change
 * count so that the GraphicView does not have to look into the Pasteboard
 * every time paste: is validated.
 */
 
/*
  menuCell tags:
 1=smaller, 2=larger, 3=visible, 4=invisible, 5=lock, 6=unlock, 7=tight, 8=not tight,
 9=join chords,
 10=break chords, 11=double time value, 12=halve time value, 13=time back, 14=grace,
 15=not grace/back, 16=hide verse in sys, 17=hide verse in staff, 18= show all verses,
 19=copy verse from, 20=paste systems, 21=cut, 22=copy, 23=paste, 24=pack left, 25=column,
 26=print, 27=new system, 28=new runner, 29 adjust to width, 30=adjust to design, 31, lay bars,
 32=spill bar, 33=grab bar, 34=cut system, 35=copy system, 36=copy all systems
 39=save, 40=save as, 41=save reg eps, 42=save reg tiff, 43=save all, 44=revert,
  45=close, 46 show/hide ruler, 47 show/hide margins, 49 object labelling
  
 39 view dirty
 40 have saved and not empty
 41 !is empty

*/


/* minimal search of selection to prove menuCell validity */

- (BOOL) checkFor: (int) tag
{
  Graphic *p;
  int k = [slist count];
  while (k--)
  {
    p = [slist objectAtIndex:k];
    switch (tag)
    {
      case 1:
        if (p->gFlags.size < 2) return YES;
	break;
      case 2:
        if (p->gFlags.size > 0) return YES;
	break;
      case 3:
        if ([p isInvisible]) return YES;
	break;
      case 4:
        if (![p isInvisible]) return YES;
	break;
      case 5:
        if (ISASTAFFOBJ(p) && !(p->gFlags.locked)) return YES;
	break;
      case 6:
        if (ISASTAFFOBJ(p) && p->gFlags.locked) return YES;
	break;
      case 7:
        if (ISATIMEDOBJ(p) && !(((TimedObj *)p)->time.tight)) return YES;
	break;
      case 8:
        if (ISATIMEDOBJ(p) && ((TimedObj *)p)->time.tight) return YES;
	break;
      case 9:
        if ([p graphicType] == NOTE && [((GNote *)p) myChordGroup] == nil) return YES;
	break;
      case 10:
        if ([p graphicType] == NOTE && [((GNote *)p) myChordGroup] != nil) return YES;
        break;
      case 11:
      case 12:
        if (ISATIMEDOBJ(p)) return YES;
	break;
      case 13:
        if (ISATIMEDOBJ(p) && ((TimedObj *)p)->isGraced != 2) return YES;
        break;
      case 14:
        if (ISATIMEDOBJ(p) && ((TimedObj *)p)->isGraced != 1) return YES;
        break;
      case 15:
        if (ISATIMEDOBJ(p) && ((TimedObj *)p)->isGraced != 0) return YES;
        break;
      case 24:
      case 25:
        if (ISASTAFFOBJ(p)) return YES;
	break;
      case 49:
        if (HASAVOICE(p)) return YES;
    }
  }
  return NO;
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuCell
{
  NSPasteboard *pb;
  int count;
  int tag = [menuCell tag];
  static BOOL hasType = NO;
  static int cachedCount = 0;
  switch (tag)
  {
      case 0:
      default:
        return YES;
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
      case 13:
      case 14:
      case 15:
      case 24:
      case 25:
      case 49:
        return [self checkFor: tag];
      case 21:
        return ([slist count] > 0);
      case 16:
      case 26:
        return (currentSystem != nil);
      case 20:
	pb = [NSPasteboard generalPasteboard];
	count = [pb changeCount];
	if (count != cachedCount)
	{
	    cachedCount = count;
//#error StringCoversion: return type of types is now an NSArray of NSStrings (used to be NXAtom *).  Change your variable declaration.
	    hasType = (DrawPasteType([pb types]) != nil);
	}
	return hasType;
      case 48:
        if ([self showMargins] && ![[menuCell title] isEqualToString:@"Hide Margins"])
	{
	  [menuCell setTitle:@"Hide Margins"];
	  [menuCell setEnabled:NO];
	}
          else if (![self showMargins] && ![[menuCell title] isEqualToString:@"Show Margins"])
	{
	  [menuCell setTitle:@"Show Margins"];
	  [menuCell setEnabled:NO];
	}
        break;
  }
  return YES;
}

@end
