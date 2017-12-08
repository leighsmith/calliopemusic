#import "winheaders.h"
#import <AppKit/NSPanel.h>

@interface PlayInspector:NSPanel
{
    id	playbutton;
    id	stopbutton;
    id  recordbutton;
    id	startlist;
    id	endlist;
    id	tempoText;
    id	tempoSlider;
    id tempoButton;
    id	pausebutton;
    id  selectswitch;
    id  outputmatrix;
    id durchoicematrix;
    id feedbackswitch;
    id metrobutton;
    id channelmatrix;
    id channelview;
    id customtext;
    id multiview;
    id outputview;
    id slidermatrix;
    id multipopup;
    id recordview;
    id nodocview;
    id progchbutton;
}

- (void)awakeFromNib;
- hitPause:sender;
- hitStop:sender;
- hitTempo:sender;
- hitTempoText:sender;
- hitPlay:sender;
- hitRecord: sender;
- hitMetro: sender;
- hitSlider: sender;
- hitChannel: sender;
- hitOption: sender;
- clickStopButton;
- preset: (float) m;
- (int) getRecordType;
- (float) getTempo;
- (BOOL) getFeedback;

@end
