/* $Id$ */
#import "winheaders.h"
#import <AppKit/AppKit.h>

@interface AppDefaults: NSPanel
{
  id choicebutton;
  id multiview;
  id revertbutton;
  id setbutton;
  
  id instpathview;	/* for instrument */
  id instpathtext;
  id instswitches;
  
  id openpathview;	/* for open path */
  id openpathtext;
  id colorview;		/* for colours */
  id backwell;
  id inkwell;
  id markwell;
  id selwell;
  id invwell;
  id t1well;
  id t2well;
  
  id launchview;	/* for launch */
  id launchswitches;

  id unitsView;
  id unitsPopup;
}

- hitChoice: sender;
- hitSet: sender;
- hitRevert: sender;

- open:sender;		/* for instrument */
- save: sender;
- revert: sender;

- checkOpenFromFile;
- checkSaveToFile;

- (BOOL) checkOpenPanel: (int) i;
- (NSString *) getDefaultOpenPath;

@end

