
#import "MyBMKAnnotation.h"
#import "MyBMKAnnotationView.h"
#import "CRBubbleView.h"
#import "UIView+Category.h"
#import "JsonUtil.h"
#import "HexColors.h"

#define kSpacing 5
#define ANNOTATION_FRAME    (CGRectMake(0, 0, 60., 60.))

@interface MyBMKAnnotationView () {
    UILabel* _oneLineLabel;
    UIView * _MarkView;
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
    
    if (_MarkView) {
        [_MarkView removeFromSuperview];
    }
    
    //设置颜色
    if([annotation.backgroundType rangeOfString:@"Red"].location != NSNotFound){//包含
        annotation.bgColor = [UIColor hx_colorWithHexString:@"#ea4c40"];
    }else if([annotation.backgroundType rangeOfString:@"Orange"].location != NSNotFound){
        annotation.bgColor = [UIColor hx_colorWithHexString:@"#f26521"];
    }else if([annotation.backgroundType rangeOfString:@"Yellow"].location != NSNotFound){
        annotation.bgColor = [UIColor hx_colorWithHexString:@"#fbaf5c"];
    }else if([annotation.backgroundType rangeOfString:@"Green"].location != NSNotFound){
        annotation.bgColor = [UIColor hx_colorWithHexString:@"#10aa9a"];
    }else if([annotation.backgroundType rangeOfString:@"Gray"].location != NSNotFound){
        annotation.bgColor = [UIColor hx_colorWithHexString:@"#918892"];
    }
    
    if([annotation.backgroundType rangeOfString:@"Bubble"].location != NSNotFound){//包含
        _MarkView = [[CRBubbleView alloc] initWithAttachedView:nil title:@"" description:@"" arrowPosition:CRArrowPositionBottom andColor:annotation.bgColor];
        
        CRBubbleView* bubbleView = (CRBubbleView*)_MarkView;
        [self addSubview:bubbleView];
        [self sendSubviewToBack:bubbleView];
        
        NSDictionary* dic = [JsonUtil dictionaryWithJsonString:annotation.title];//annotation.title传递的是整个节点所有数据
        NSString* title = [dic objectForKey:@"title"];
        _oneLineLabel.text = title;
        
        CGRect rect = [[NSString stringWithFormat:@"%@", _oneLineLabel.text] boundingRectWithSize:CGSizeMake(_oneLineLabel.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:10]} context:nil];
        CGFloat width = rect.size.width;
        CGFloat height = rect.size.height;
        
        bubbleView.viewWidth     = width? (width + 15) :60;
        bubbleView.viewHeight    = height? (height + 25) : 60;
        bubbleView.frame         = CGRectMake(0, 0, bubbleView.viewWidth, bubbleView.viewHeight);
        
        _oneLineLabel.width       = width? (width + 15) :60;
        _oneLineLabel.height      = height? (height + 25) : 60;
        _oneLineLabel.frame       = CGRectMake(0, -7, _oneLineLabel.width, _oneLineLabel.height);
        
        self.frame = CGRectMake(0, 0, bubbleView.viewWidth, bubbleView.viewHeight);
        
    }else if([annotation.backgroundType rangeOfString:@"Circle"].location != NSNotFound){
        
        NSDictionary* dic = [JsonUtil dictionaryWithJsonString:annotation.title];//annotation.title传递的是整个节点所有数据
        NSString* title = [dic objectForKey:@"title"];
        _oneLineLabel.text = title;
        
        CGRect rect = [[NSString stringWithFormat:@"%@", _oneLineLabel.text] boundingRectWithSize:CGSizeMake(_oneLineLabel.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:10]} context:nil];
        CGFloat width = rect.size.width;
        CGFloat height = rect.size.height;
        
        float max = MAX(width?(width + 10):60, height?(height + 25):60);
        _oneLineLabel.width       = max;
        _oneLineLabel.height      = max;
        _oneLineLabel.frame       = CGRectMake(0, 0, _oneLineLabel.width, _oneLineLabel.height);
        _oneLineLabel.backgroundColor = annotation.bgColor;
        
        
        _oneLineLabel.layer.cornerRadius = _oneLineLabel.bounds.size.width/2;
        _oneLineLabel.layer.masksToBounds=YES;
        
    }else if([annotation.backgroundType rangeOfString:@"MarkRed"].location != NSNotFound){
        self.image = [UIImage imageNamed:@"mapapi.bundle/images/mark_red.png"];
    }else if([annotation.backgroundType rangeOfString:@"MarkGreen"].location != NSNotFound){
        self.image = [UIImage imageNamed:@"mapapi.bundle/images/mark_green.png"];
    }else if([annotation.backgroundType rangeOfString:@"MarkGray"].location != NSNotFound){
        self.image = [UIImage imageNamed:@"mapapi.bundle/images/mark_gray.png"];
    }
 
}


@end
