#import "winheaders.h"
#import "StaffObj.h"

@interface KeySig:StaffObj
{
@public
  char keystr[7];
}

+ (void)initialize;
+ myInspector;
+ myPrototype;

- init;
- (void)dealloc;
- (int) defaultPos;
- newFrom;
- getKeyString: (char *) ks;
- (int) oldKeyNum;
- (int) myKeySymbol;
- (int) myKeyNumber;
- myKeyInfo: (int *) s : (int *) n;
- (BOOL) performKey: (int) c;
- drawMode: (int) m;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
