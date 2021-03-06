/* $Id$ */
#import "winheaders.h"
#import "GraphicView.h"
#import "System.h"

@interface GraphicView(GVCommands)

- renameStyle: (NSString *) s : (NSString *) t;
- flushStyle: (System *) st;
- lock:sender;
- unlock:sender;
- showVerse: sender;
- shuffleAllMarginsByScale: (float) oss : (float) nss;
- recalcAllSys;
- (int) gotoPage: (int) n;
- (BOOL) showMargins;

/*
  @brief Find or make the next system of same number of staves as prototypeSystem.
  @return Returns the next system;
  @param didCreate Pass back whether next system was created.
 */
- (System *) nextSystem: (System *) prototypeSystem didCreate: (BOOL *) didCreate;
- hideSystemVerse: sender;
- hideStaffVerse: sender;
- wantVerse: sender;
- copyVerseFrom: p;
- (void)changeFont:(id)sender;
- whichFont: sender;
- doToSelection: (int) c : (int) a;
- objInspect: sender;
- objSmaller: sender;
- objLarger: sender;
- objVisible: sender;
- objInvisible: sender;
- objTight: sender;
- objNotTight: sender;
- objGrace: sender;
- objBackward: sender;
- objNotGrace: sender;
- paginate : sender;
- newRunner: sender;
- alignColumn: sender;
- formatPage: sender;
- balancePage: sender;
- packLeft: sender;
- sizeAllSys: sender;
- hiddenAllSys: sender;
- setTablature: sender;
- unsetTablature: sender;
//- delAll3rdStaves: sender; /* this is for my own use in converting old files */
- toggleStaffDisp: sender;
- reShapeAllSys: sender;

/*!
    @brief Duplicate current system, and make it current. 
 
    TODO This should become part of NotationScore.
 */
- duplicateSystem: sender;
- spillBar: sender;
- grabBar: sender;
- layBarlines: sender;
- deleteSys: sender;
- renumber: sender;
- deleteStaves: sender;
- delAllHidden: sender;
- cutSys: sender;
- copySys: sender;
- pasteSys: sender;
- mergeSys: sender;
- doPartAdjust: sender;
- doFullAdjust: sender;
- testPoint1: sender;
- testPoint2: sender;

/*sb: added these from .m file to prevent compiler warnings */
- upgradeNeumes;
- upgradeParts;
- upgradeTies;
- formatAll: sender;

@end
