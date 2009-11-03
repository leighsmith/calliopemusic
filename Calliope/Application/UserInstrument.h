/* $Id$ */

#import "winheaders.h"
#import <MusicKit/MusicKit.h>


@interface UserInstrument: MKInstrument
{}

- realizeNote: (MKNote *) n fromNoteReceiver: (MKNoteReceiver *) nr;

@end
