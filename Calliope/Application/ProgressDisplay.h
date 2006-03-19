//
//  $Id:$
//  Calliope
//
//  Created by Leigh Smith on 19/03/06.
//  Copyright 2006 Leigh Smith. All rights reserved.
//

#import "winheaders.h"
#import <AppKit/AppKit.h>

@interface ProgressDisplay: NSObject
{
    IBOutlet NSPanel *progressPanel;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSTextField *titleTextField;
}

/*!
  @brief Creates an autoreleased ProgressDisplay.
 */
+ (ProgressDisplay *) progressDisplayWithTitle: (NSString *) titleOfProgressingActivity;

/*!
  @brief Initialises an autoreleased ProgressDisplay.
 */
- initWithTitle: (NSString *) titleOfProgressingActivity;

/*!
  @brief Assigns the displayed title of the ProgressDisplay.
 */
- (void) setProgressTitle: (NSString *) s;

/*!
  @brief Updates the progress of the ProgressDisplay instance.
  @param ratio A value between 0.0 (no progress) and 1.0 (completed).
 */
- (void) setProgressRatio: (float) ratio;

/*!
  @brief Closes the display panel.
 */
- (void) closeProgressDisplay;

@end

