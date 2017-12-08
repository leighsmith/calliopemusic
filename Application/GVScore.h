//
//  $Id:$
//  Calliope
//
//  @brief Category of GraphicView (Eventually with be the NotationScore model) to handle MusicKit score conversion.
//  Created by Leigh Smith on 29/11/09.
//  Copyright 2009 Oz Music Code LLC. All rights reserved.
//

#import <MusicKit/MusicKit.h>
#import "GraphicView.h"

@interface GraphicView(GVScore)

/*!
  @brief Returns an autoreleased MKScore instance encoding a range of Systems, either only the selected graphics, or all.
 */
- (MKScore *) scoreBetweenSystem: (int) startingSystemIndex 
		       andSystem: (int) endingSystemIndex
	    onlySelectedGraphics: (BOOL) selectedOnly;

/*!
  @brief Returns an autoreleased MKScore instance encoding all Systems.
 */
- (MKScore *) musicKitScore;

@end
