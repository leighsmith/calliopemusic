#import <Foundation/Foundation.h>

void PStie(float cx, float cy, float dy, float rh, float hw, float mh, float ln, float a)
{
    NSLog(@"Called PStie(), needs implementation\n");
/*
 % ratio halfwidth minheight tie
 
 /tie
 {
     scale
     newpath
     0 0 1 10 170 arc
     1 exch scale
     0 0 1 170 10 arcn
 } bind def
 
 
 defineps PStie(float cx, cy, dy, rh, hw, mh, ln, a)
 matrix currentmatrix
 cx cy moveto
 currentpoint translate
 a rotate
 0 dy rmoveto
 currentpoint translate
 hw 1 ln add div mh scale
 newpath
 ln 0 1 10 90 arc
 ln neg 0 1 90 170 arc
 1 rh scale
 ln neg 0 1 170 90 arcn
 ln 0 1 90 10 arcn
 setmatrix
 endps 
*/     
}

void PStiedash(float cx, float cy, float dy, float hw, float mh, float ln, float a)
{
    NSLog(@"Called PStiedash(), needs implementation\n");
/*
 defineps PStiedash(float cx, cy, dy, hw, mh, ln, a)
 matrix currentmatrix
 cx cy moveto
 currentpoint translate
 a rotate
 0 dy rmoveto
 currentpoint translate
 hw 1 ln add div mh scale
 newpath
 ln 0 1 10 90 arc
 ln neg 0 1 90 170 arc
 setmatrix
 endps
*/ 
}

void PStietext(float gap, float maxToMinHeighRatio, float halfWidth, float minHeight, float halfGap, float drop)
{
    NSLog(@"Called PStietext(), needs implementation\n");
/*
 %Gap MaxHeight/MinHeight HalfWidth MinHeight Gap/2 Drop tietext
 
 /tietext
 {
     gsave
       currentpoint
       3 -1 roll add exch 3 -1 roll add exch
       newpath
       gsave
         translate
         scale
         0 0 1 5 175 arc
         1.0 exch scale
         0 0 1 175 5 arcn
         fill
       grestore
     grestore
     0 rmoveto
 } bind def
 
 endps
*/ 
}

void PSsetorigin(float cx, float cy, float a)
{
    NSLog(@"Called PSsetorigin(), needs implementation\n");
/*
defineps PSsetorigin(float cx, cy, a)
 matrix currentmatrix
 cx cy moveto
 currentpoint translate
 a rotate
endps
*/ 
}

void PSresetorigin( void )
{
    NSLog(@"Called PSresetorigin(), needs implementation\n");
/*
 defineps PSresetorigin()
 setmatrix
 endps
*/ 
}


