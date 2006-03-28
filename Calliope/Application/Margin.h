#import "winheaders.h"
#import "Graphic.h"

// Differnt types of margins.
typedef enum {
    MarginLeft = 0,
    MarginRight = 1,
    MarginHeader = 2,
    MarginFooter = 3,
    MarginTop = 4,
    MarginBottom = 5,
    MarginLeftEvenBinding = 6,
    MarginRightEvenBinding = 7,
    MarginLeftOddBinding = 8,
    MarginRightOddBinding = 9,
    MaximumMarginTypes
} MarginType;

@interface Margin: Graphic
{
@public
    float margin[10];
    /* PageFormat */ char format;
    char alignment;
@private
    id client;			/* a System */
    float staffScale;
}

+ (void) initialize;
+ myInspector;
- init;
- (void) removeObj;

/*!
  @brief Assigns the scale of the staff to the margin.
 */
- (void) setStaffScale: (float) newStaffScale;

/*!
  @brief Returns the current scale of the staff.
 */
- (float) staffScale;

/*!
  @brief Assigns the client to the margin.
 */
- (void) setClient: (id) newClient;

/*!
  @brief Returns the current margin client.
 */
- (id) client;

- (float) leftMargin;
- (void) setLeftMargin: (float) newLeftMargin;
- (float) rightMargin;
- (void) setRightMargin: (float) newRightMargin;
- (float) headerBase;
- (void) setHeaderBase: (float) newHeaderMargin;
- (float) footerBase;
- (void) setFooterBase: (float) newFooterMargin;
- (float) topMargin;
- (void) setTopMargin: (float) newTopMargin;
- (float) bottomMargin;
- (void) setBottomMargin: (float) newBottomMargin;

/*!
  @brief Assigns the given margin.
 */
- (void) setMarginType: (MarginType) marginType toSize: (float) newMarginValue;

/*!
  @brief Returns the given margin.
 */
- (float) marginOfType: (MarginType) marginType;

- (BOOL) move: (float) dx : (float) dy : (NSPoint) p : sys : (int) alt;
- drawMode: (int) m;
- draw;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


@end
