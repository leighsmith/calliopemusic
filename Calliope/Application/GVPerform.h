#import "winheaders.h"
#import "GraphicView.h"
#import "Course.h"
#import <Foundation/NSArray.h>
#import <MusicKit/MusicKit.h>

#define WRITESCORE 1
#define NUMTHREADS (NUMSTAVES+NUMVOICES)
#define NUMNOTEHEADS 16
#define NUMTUNINGS 16
#define NUMPARTS (NUMTHREADS*NUMNOTEHEADS)
#define NUMPARTPERFORM 1024
#define NUMCHANNELS 16

#define VOICEID(v, s) (v ? NUMSTAVES + v : s)

#define MINIMTICK 64.0
#define DURTIME(t) ((t) * (1.0 / MINIMTICK))


struct performer
{
  short thread;
  char notehead;
  char channel;
  MKPart *part;
  MKPartPerformer *performer;
};


@interface GraphicView(GVPerform)

- playChoice: (int) i : (int) j : (int) s : (int) np;
- deactivatePlayers;
- pausePlayers;
- resumePlayers;
- clickStop;

@end
