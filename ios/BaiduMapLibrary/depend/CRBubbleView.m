

#import "CRBubbleView.h"
#import "UIView+Category.h"

#define CR_ARROW_SPACE 8
#define CR_ARROW_SIZE 8

#define CR_PADDING 8
#define CR_RADIUS 6
#define COLOR_GLUE_BLUE [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]
#define COLOR_DARK_GRAY [UIColor colorWithWhite:0.13 alpha:1.0]
#define CR_TITLE_FONT_SIZE 17
#define CR_DESCRIPTION_FONT_SIZE 14

@interface CRBubbleView () {
    NSArray     *stringArray;
    int         maxWidth;
    CGPoint     isMoving;
    int         swipeXPosition;
    int         swipeYPosition;
    
    UILabel     *titleLabel;
}

@end

@implementation CRBubbleView

@synthesize fontName;

#pragma mark - Constructor

-(id)initWithAttachedView:(UIView*)view title:(NSString*)title description:(NSString*)description arrowPosition:(CRArrowPosition)arrowPosition andColor:(UIColor*)color
{
    self = [super init];
    if(self)
    {
        if(color!=nil)
            self.color=color;
        else
            self.color=COLOR_GLUE_BLUE;
        self.attachedView = view;
        self.title = title;
        self.sDescription = description;
        self.arrowPosition = arrowPosition;
        [self setBackgroundColor:[UIColor clearColor]];
        if(fontName==NULL)
            fontName=@"ArilMT";
        
        UIFont *titleFont = [UIFont systemFontOfSize:CR_TITLE_FONT_SIZE];
        NSMutableAttributedString *showString = nil;
//        if (title.trim.length>0) {
//            showString = [NSMutableAttributedString generateString:title font:titleFont color:[UIColor blackColor]];
//            if (description.trim.length>0) {
//                NSString *desString = [NSString stringWithFormat:@"%@",description];
//                [showString appendAttributedString:[NSMutableAttributedString generateString:desString font:[UIFont systemFontOfSize:14.0] color:[UIColor blackColor]]];
//            }
//        }
        
        
        float actualXPosition = [self offsets].width;
        float actualWidth =self.size.width;
        float actualHeight = CR_TITLE_FONT_SIZE;
        float actualYPosition = (self.size.height-CR_TITLE_FONT_SIZE)/2;
        
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(actualXPosition, actualYPosition, actualWidth, actualHeight)];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        [titleLabel setAttributedText:showString];
        titleLabel.numberOfLines = 0;
        [titleLabel setBackgroundColor:[UIColor clearColor]];
        [self addSubview:titleLabel];
        
        [self setFrame:[self frame]];
        [self setNeedsDisplay];
        
    }
    
    return self;
}

#pragma mark - Customs methods
-(void)setFontName:(NSString *)theFontName
{
    fontName=theFontName;
    [titleLabel setFont:[UIFont fontWithName:fontName size:CR_TITLE_FONT_SIZE]];
    
}

#pragma mark - Drawing methods
-(CGRect)frame
{
    //Calculation of the bubble position
    float x = self.attachedView.frame.origin.x;
    float y = self.attachedView.frame.origin.y;
    
    if(self.arrowPosition==CRArrowPositionLeft||self.arrowPosition==CRArrowPositionRight)
    {
        y+=self.attachedView.frame.size.height/2-[self size].height/2;
        x+=(self.arrowPosition==CRArrowPositionLeft)? CR_ARROW_SPACE+self.attachedView.frame.size.width : -(CR_ARROW_SPACE*2+[self size].width);
        
    }else if(self.arrowPosition==CRArrowPositionTop||self.arrowPosition==CRArrowPositionBottom)
    {
        x+=self.attachedView.frame.size.width/2-[self size].width/2;
        y+=(self.arrowPosition==CRArrowPositionTop)? CR_ARROW_SPACE+self.attachedView.frame.size.height : -(CR_ARROW_SPACE*2+[self size].height);
    }
    
    return CGRectMake(x, y, [self size].width, [self size].height+CR_ARROW_SIZE);
}

-(CGSize)size
{
    //Cacultation of the bubble size
    float height = self.viewHeight? self.viewHeight :60;//CR_PADDING*3
    float width = self.viewWidth ? self.viewWidth : 60;//CR_PADDING*3
    
    titleLabel.width    = self.viewWidth;
    titleLabel.left = width/2;
    titleLabel.top  = 10;
    [titleLabel sizeToFit];
    float titleHeight   = titleLabel.bounds.size.height;
    float titleWidth    = titleLabel.bounds.size.width;
    
    if(self.title && ![self.title isEqual:@""])
    {
        height+=titleHeight+CR_PADDING;
        
    }
    height-=CR_DESCRIPTION_FONT_SIZE;
    float descriptionWidth=0;
    
    if (descriptionWidth>titleWidth) {
        width+=descriptionWidth;
    }else{
        width+=titleWidth;
    }
    
    return CGSizeMake(width, height);
}

-(CGSize) offsets
{
    return CGSizeMake((self.arrowPosition==CRArrowPositionLeft)? CR_ARROW_SIZE : 0, (self.arrowPosition==CRArrowPositionTop)? CR_ARROW_SIZE : 0);
}

- (void)drawRect:(CGRect)rect
{
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    
    CGPathRef clippath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake([self offsets].width,[self offsets].height, [self size].width, [self size].height) cornerRadius:CR_RADIUS].CGPath;
    
    CGContextSetFillColorWithColor(ctx, self.color.CGColor);
    CGContextAddPath(ctx, clippath);
    CGContextFillPath(ctx);
    CGContextClosePath(ctx);
    
    [[UIColor clearColor] setStroke];//[UIColor colorFromHexRGB:@"cccccc"]
    CGContextSetLineWidth(ctx, 0.7);
    CGContextAddPath(ctx, clippath);
    CGContextStrokePath(ctx);
    CGContextClosePath(ctx);
    
    [self.color set];
    
    CGPoint startPoint = CGPointMake(0, CR_ARROW_SIZE);
    CGPoint thirdPoint = CGPointMake(CR_ARROW_SIZE/2, 0);
    CGPoint endPoint = CGPointMake(CR_ARROW_SIZE, CR_ARROW_SIZE);
    
    //小三角
    CGAffineTransform rot = CGAffineTransformMakeRotation(M_PI);
    CGAffineTransform trans = CGAffineTransformMakeTranslation([self size].width/2+(CR_ARROW_SIZE)/2, [self size].height+CR_ARROW_SIZE);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:startPoint];
    [path addLineToPoint:thirdPoint];
    [path addLineToPoint:endPoint];
    [path addLineToPoint:startPoint];
    
    [path applyTransform:rot];
    [path applyTransform:trans];
    
    [path closePath]; // Implicitly does a line between p4 and p1
    [path fill]; // If you want it filled, or...
    [path stroke]; // ...if you want to draw the outline.
    
    //给小三角画线
    UIBezierPath *pathLine = [UIBezierPath bezierPath];
    [pathLine moveToPoint:startPoint];
    [pathLine addLineToPoint:thirdPoint];
    [pathLine addLineToPoint:endPoint];
    pathLine.lineWidth = 0.7;
    
    
    [pathLine applyTransform:rot];
    [pathLine applyTransform:trans];
    
    [[UIColor clearColor] setStroke];// [UIColor colorFromHexRGB:@"cccccc"]
    [pathLine stroke]; // ...if you want to draw the outline.
    
    CGContextRestoreGState(ctx);
    
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowRadius = 3.;
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowOpacity = 1;
    UIBezierPath * shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(self.width/3. - 2, self.height + 8, self.width/3. + 4, 3)];
    self.layer.shadowPath = shadowPath.CGPath;
}


@end
