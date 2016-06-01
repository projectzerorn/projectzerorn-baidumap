
#import "MyAnnotation.h"
#import "MyAnnotationView.h"
#import "CRBubbleView.h"
#import "UIView+Category.h"

#define kSpacing 5
#define ANNOTATION_FRAME    (CGRectMake(0, 0, 60., 60.))

@interface MyAnnotationView () {
    UILabel* _oneLineLabel;
    CRBubbleView * _bubbleView;
}
@end

@implementation MyAnnotationView

-(instancetype)init{
    if(self=[super init]){
        [self layoutUI];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self=[super initWithFrame:frame]) {
        [self layoutUI];
    }
    return self;
}

-(void)layoutUI{
    //背景
    self.backgroundColor    = [UIColor clearColor];
    self.frame              = ANNOTATION_FRAME;
//    self.centerOffset       = CGPointMake(self.centerOffset.x, self.centerOffset.y - 25);
    
    _oneLineLabel                 = [[UILabel alloc] init];
    _oneLineLabel.frame           = CGRectMake(kSpacing, kSpacing+1, 100, 15);
    _oneLineLabel.font            = [UIFont systemFontOfSize:12];
    _oneLineLabel.textAlignment   = NSTextAlignmentCenter;
    _oneLineLabel.backgroundColor = [UIColor clearColor];
    _oneLineLabel.textColor       = [UIColor whiteColor];
    
    [self addSubview:_oneLineLabel];
    

}

-(void)setAnnotation:(MyAnnotation *)annotation{
    [super setAnnotation:annotation];
    
    if (_bubbleView) {
        [_bubbleView removeFromSuperview];
    }
    _bubbleView = [[CRBubbleView alloc] initWithAttachedView:nil title:@"" description:@"" arrowPosition:CRArrowPositionBottom andColor:annotation.bgColor];
    [self addSubview:_bubbleView];
    [self sendSubviewToBack:_bubbleView];
    
    _oneLineLabel.text = annotation.title;
    _bubbleView.isShort = YES;
    
    CGRect rect = [[NSString stringWithFormat:@"%@", _oneLineLabel.text] boundingRectWithSize:CGSizeMake(_oneLineLabel.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]} context:nil];
    CGFloat width = rect.size.width;
    _bubbleView.viewWidth     = width? (width + 20) :60;
    _oneLineLabel.width       = width? (width + 10) :60;
    _bubbleView.frame         = CGRectMake(0, 0, width? (width + 20) :60, 40);
    self.frame = CGRectMake(0, 0, width? (width + 20) :60, 40.);
}

@end
