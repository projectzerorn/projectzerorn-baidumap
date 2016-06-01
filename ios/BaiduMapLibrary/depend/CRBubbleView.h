

#import <UIKit/UIKit.h>

@interface CRBubbleView : UIView

typedef enum {
    CRArrowPositionTop,
    CRArrowPositionBottom,
    CRArrowPositionRight,
    CRArrowPositionLeft
} CRArrowPosition;

@property (nonatomic, strong) UIView            * attachedView;
@property (nonatomic, strong) NSString          * title;
@property (nonatomic, strong) NSString          * sDescription;
@property (nonatomic, assign) CRArrowPosition   arrowPosition;
@property (nonatomic, strong) UIColor           * color;
@property (nonatomic, strong) NSString          * fontName;
@property (nonatomic, assign) float             viewWidth;

@property (nonatomic, assign) BOOL              isShort;

-(id)initWithAttachedView:(UIView*)view title:(NSString*)title description:(NSString*)description arrowPosition:(CRArrowPosition)arrowPosition andColor:(UIColor*)color;

-(CGSize)size;
-(CGRect)frame;

@end
