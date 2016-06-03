
#import "MyBMKAnnotation.h"
#import "MyBMKAnnotationView.h"
#import "CRBubbleView.h"
#import "UIView+Category.h"
#import "JsonUtil.h"

#define kSpacing 5
#define ANNOTATION_FRAME    (CGRectMake(0, 0, 60., 60.))

@interface MyBMKAnnotationView () {
    UILabel* _oneLineLabel;
    CRBubbleView * _bubbleView;
}
@end

@implementation MyBMKAnnotationView

- (instancetype)initWithAnnotation:(id <BMKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    if (self=[super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.annotation = annotation;
        [self layoutUI];
    }

    return self;
}

-(void)layoutUI{
    //背景
    self.backgroundColor    = [UIColor clearColor];
    self.frame              = ANNOTATION_FRAME;
    
    _oneLineLabel                 = [[UILabel alloc] init];
    _oneLineLabel.lineBreakMode   = UILineBreakModeWordWrap;
    _oneLineLabel.numberOfLines   = 0;
    _oneLineLabel.frame           = CGRectMake(kSpacing, kSpacing+1, 100, 15);
    _oneLineLabel.font            = [UIFont systemFontOfSize:12];
    _oneLineLabel.textAlignment   = NSTextAlignmentCenter;
    _oneLineLabel.backgroundColor = [UIColor clearColor];
    _oneLineLabel.textColor       = [UIColor whiteColor];
    
    [self addSubview:_oneLineLabel];
    

}

-(void)setAnnotation:(MyBMKAnnotation *)annotation{
    [super setAnnotation:annotation];
    
    if (_bubbleView) {
        [_bubbleView removeFromSuperview];
    }
    _bubbleView = [[CRBubbleView alloc] initWithAttachedView:nil title:@"" description:@"" arrowPosition:CRArrowPositionBottom andColor:annotation.bgColor];
    [self addSubview:_bubbleView];
    [self sendSubviewToBack:_bubbleView];
    
    NSDictionary* dic = [JsonUtil dictionaryWithJsonString:annotation.title];//annotation.title传递的是整个节点所有数据
    NSString* title = [dic objectForKey:@"title"];
    _oneLineLabel.text = title;
//    _bubbleView.isShort = YES;
    
    CGRect rect = [[NSString stringWithFormat:@"%@", _oneLineLabel.text] boundingRectWithSize:CGSizeMake(_oneLineLabel.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]} context:nil];
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    _bubbleView.viewWidth     = width? (width + 10) :60;
    _bubbleView.viewHeight    = height? (height + 20) : 60;
    _bubbleView.frame         = CGRectMake(0, 0, _bubbleView.viewWidth, _bubbleView.viewHeight);
    
    _oneLineLabel.width       = width? (width + 10) :60;
    _oneLineLabel.height      = height? (height + 20) : 60;
    _oneLineLabel.frame       = CGRectMake(0, -7, _oneLineLabel.width, _oneLineLabel.height);
    
    self.frame = CGRectMake(0, 0, _bubbleView.viewWidth, _bubbleView.viewHeight);
}


@end
