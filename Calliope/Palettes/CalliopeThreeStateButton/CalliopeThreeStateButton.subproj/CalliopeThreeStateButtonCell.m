
#import "CalliopeThreeStateButtonCell.h"
#import "CalliopeThreeStateButton.h"
#define ALLOWABLE_HIGHLIGHTS (NSNoCellMask|NSPushInCellMask|NSChangeGrayCellMask|NSChangeBackgroundCellMask)


@implementation CalliopeThreeStateButtonCell
-(void) _loadImages
{
    NSString	*path;
    NSImage	*image;
    NSBundle	*bundle = [NSBundle mainBundle];

    path = [bundle pathForImageResource:@"off.tiff"];
    if (path) { image = [[NSImage alloc] initByReferencingFile:path];
    [self setFirstImage:image];
    [image release]; } else firstImage = nil;

    path = [bundle pathForImageResource:@"mustHave.tiff"];
    if (path) { image = [[NSImage alloc] initByReferencingFile:path];
    [self setSecondImage:image];
    [image release]; } else secondImage = nil;

    path = [bundle pathForImageResource:@"mustNotHave.tiff"];
    if (path) { image = [[NSImage alloc] initByReferencingFile:path];
    [self setThirdImage:image];
    [image release]; } else thirdImage = nil;
}
- (id)init
{
    [super init];
    [self _loadImages];
    cyclic = NO;
    altClicked = NO;
    [self setType:NSToggleButton];
    [self setImagePosition:NSImageOnly];
    [self setBezeled:NO];
    [self setBordered:NO];
    [self setAlignment:NSLeftTextAlignment];
    [self setImage:[self firstImage]];
    [super setHighlightsBy:([self highlightsBy] & ALLOWABLE_HIGHLIGHTS)];

    return self;
}
-(void) awakeFromNib
{
//    [self _loadImages];
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
        [super encodeWithCoder:aCoder];
    [aCoder encodeObject:firstImage];
    [aCoder encodeObject:secondImage];
    [aCoder encodeObject:thirdImage];
    [aCoder encodeValuesOfObjCTypes:"ii", &threeState, &cyclic];
        return;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
        self = [super initWithCoder:aDecoder];
    firstImage = [[aDecoder decodeObject] retain];
    secondImage = [[aDecoder decodeObject] retain];
    thirdImage = [[aDecoder decodeObject] retain];
    [aDecoder decodeValuesOfObjCTypes:"ii", &threeState, &cyclic];
    altClicked = NO;

        // Disallow NX_CONTENTS as highlight mode  -Carl
//	[super setHighlightsBy:([self highlightsBy] & ALLOWABLE_HIGHLIGHTS)];

        return self;
}

-(void) dealloc
{
    if (firstImage)[firstImage release];
    if (secondImage)[secondImage release];
    if (thirdImage)[thirdImage release];
    [super dealloc];
}
- copyWithZone:(NSZone *)zone
{
    CalliopeThreeStateButtonCell * newClass = [super copyWithZone:zone];
#ifdef DEBUG
    printf("copyWithZone\n");
#endif
    if (firstImage) newClass->firstImage = [firstImage retain];
    else newClass->firstImage = nil;
    if (secondImage) newClass->secondImage = [secondImage retain];
    else newClass->secondImage = nil;
    if (thirdImage) newClass->thirdImage = [thirdImage retain];
    else newClass->thirdImage = nil;

    newClass->threeState = [self threeState];
    [newClass setCyclic:[self cyclic]];
#ifdef DEBUG
    printf("copied WithZone\n");
#endif
    return newClass;
}
#define ALTKEY ([theEvent modifierFlags] & NSAlternateKeyMask)

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)_untilMouseUp
{
#ifdef DEBUG
    printf("trackMouse \n");
#endif
       altClicked = (ALTKEY)? YES:NO;
    return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:_untilMouseUp];
}
-(int) state
{
    if (threeState)
        return (YES);
    else
        return (NO);
}
-(int) threeState
{
    return (threeState);
}
-(void) setState:(int)aState
{
#ifdef DEBUG
    printf("setState  \n");
#endif
    if (cyclic) [self incState];
    else {
        if (altClicked) [self setThreeState:2];
        else [self toggleState];
    }
    altClicked = NO;
}
-(void) setThreeState:(int) newState;
{
    if (newState < BUTTON_THREESTATE_OFF)
        newState = BUTTON_THREESTATE_MUSTNOTHAVE;

    if (newState > BUTTON_THREESTATE_MUSTNOTHAVE)
        newState = BUTTON_THREESTATE_OFF;

    threeState = newState;

    [self _setImage];
}
-(void) toggleState
{
    if (threeState == 2) threeState = 0;
    else if (threeState == 0) threeState = 1;
    else if (threeState == 1) threeState = 0;
    [self _setImage];
}

-(int) incState
{
    [self setThreeState:[self threeState] + 1];
    return (threeState);
}
-(int) decState
{
    [self setThreeState:[self threeState] - 1];
    return (threeState);
}

-(NSImage *) firstImage
{
    return (firstImage);
}
-(void) setFirstImage:(NSImage *) newValue
{
    [newValue retain];
    if (firstImage) [firstImage release];
    firstImage = newValue;
}
-(NSImage *) secondImage
{
    return (secondImage);
}
-(void) setSecondImage:(NSImage *) newValue
{
    [newValue retain];
    if (secondImage) [secondImage release];
    secondImage = newValue;
}
-(NSImage *) thirdImage
{
    return (thirdImage);
}
-(void) setThirdImage:(NSImage *) newValue
{
    [newValue retain];
    if (thirdImage) [thirdImage release];
    thirdImage = newValue;
}
-(void) _setImage;
{
#ifdef DEBUG
    printf("_setImage %d \n",[self threeState]);
#endif
    switch ([self threeState])
    {
        case BUTTON_THREESTATE_OFF :
            [self setImage:[self firstImage]];
            break;

        case BUTTON_THREESTATE_MUSTHAVE :
            [self setImage:[self secondImage]];
            break;

        case BUTTON_THREESTATE_MUSTNOTHAVE :
            [self setImage:[self thirdImage]];
            break;

        default:
            break;
            //[NSException internal consistancy error]
    }

    [(NSControl *) [self controlView] updateCell:self];
}

- (void)setHighlightsBy:(int)aType;
{
    [super setHighlightsBy:(aType & ALLOWABLE_HIGHLIGHTS)];
    return;
}

- (void)setCyclic:(int)value;
{
    cyclic = value;
}
- (int)cyclic
{
    return cyclic;
}

@end
