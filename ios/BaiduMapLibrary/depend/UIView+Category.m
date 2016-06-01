

#import "UIView+Category.h"


@implementation UIView (Category)

- (id) initWithScaleFrame:(CGRect)frame {
    self = [self initWithFrame:frame];
    if (self) {
        
    }
    
    return self;
}

- (void)setWidth:(CGFloat)width {
    CGRect rect = self.frame;
    
    rect.size.width = width;
    
    self.frame = rect;
}

- (void)setHeight:(CGFloat)height {
    CGRect rect = self.frame;
    
    rect.size.height = height;
    
    self.frame = rect;
}

- (void)setTop:(CGFloat)top {
    CGRect rect = self.frame;
    
    rect.origin.y = top;
    
    self.frame = rect;
}

- (void)setLeft:(CGFloat)left {
    CGRect rect = self.frame;
    
    rect.origin.x = left;
    
    self.frame = rect;
}

@end

@implementation UIView (EasyFrame)

#pragma mark - setter
- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (void)setWidth:(CGFloat)width {
    CGSize size = self.size;
    size.width = width;
    self.size = size;
}

- (void)setHeight:(CGFloat)height {
    CGSize size = self.size;
    size.height = height;
    self.size = size;
}

- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (void)setX:(CGFloat)x {
    CGPoint origin = self.origin;
    origin.x = x;
    self.origin = origin;
}

- (void)setY:(CGFloat)y {
    CGPoint origin = self.origin;
    origin.y = y;
    self.origin = origin;
}

- (void)setLeft:(CGFloat)left {
    CGPoint origin = self.origin;
    origin.x = left;
    self.origin = origin;
}

- (void)setTop:(CGFloat)top {
    CGPoint origin = self.origin;
    origin.y = top;
    self.origin = origin;
}

- (void)setBottom:(CGFloat)bottom {
    CGPoint origin = self.origin;
    origin.y = bottom - self.height;
    self.origin = origin;
}

- (void)setRight:(CGFloat)right {
    CGPoint origin = self.origin;
    origin.x = right - self.width;
    self.origin = origin;
}


#pragma mark getter

- (CGSize)size {
    return self.frame.size;
}

- (CGFloat)width {
    return self.size.width;
}

- (CGFloat)height {
    return self.size.height;
}

- (CGPoint)origin {
    return self.frame.origin;
}

- (CGFloat)x {
    return self.origin.x;
}

- (CGFloat)y {
    return self.origin.y;
}

- (CGFloat)left {
    return self.origin.x;
}

- (CGFloat)top {
    return self.origin.y;
}

- (CGFloat)bottom {
    return self.origin.y + self.size.height;
}

- (CGFloat)right {
    return self.origin.x + self.size.width;
}

@end


@implementation UIView (MotionEffect)

NSString *const centerX = @"center.x";
NSString *const centerY = @"center.y";

#pragma mark - Motion Effect
- (void)addCenterMotionEffectsXYWithOffset:(CGFloat)offset {
    
    //    if(!IS_OS_7_OR_LATER) return;
    if(floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) return;
    
    UIInterpolatingMotionEffect *xAxis;
    UIInterpolatingMotionEffect *yAxis;
    
    xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:centerX
                                                            type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    xAxis.maximumRelativeValue = @(offset);
    xAxis.minimumRelativeValue = @(-offset);
    
    yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:centerY
                                                            type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    yAxis.minimumRelativeValue = @(-offset);
    yAxis.maximumRelativeValue = @(offset);
    
    UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
    group.motionEffects = @[xAxis, yAxis];
    
    [self addMotionEffect:group];
}

@end

@implementation UIView (Shake)

- (void) shakeAnimation {
    
    CALayer* layer = [self layer];
    CGPoint position = [layer position];
    CGPoint y = CGPointMake(position.x - 8.0f, position.y);
    CGPoint x = CGPointMake(position.x + 8.0f, position.y);
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setTimingFunction:[CAMediaTimingFunction
                                  functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setFromValue:[NSValue valueWithCGPoint:x]];
    [animation setToValue:[NSValue valueWithCGPoint:y]];
    [animation setAutoreverses:YES];
    [animation setDuration:0.08f];
    [animation setRepeatCount:3];
    [layer addAnimation:animation forKey:nil];
}

@end

@implementation UIView (Screenshot)

- (UIImage*) screenshot {
    
    UIGraphicsBeginImageContext(self.bounds.size);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // helps w/ our colors when blurring
    // feel free to adjust jpeg quality (lower = higher perf)
    NSData *imageData = UIImageJPEGRepresentation(image, 0.75);
    image = [UIImage imageWithData:imageData];
    
    return image;
    
}

- (UIImage *) screenshotForScrollViewWithContentOffset:(CGPoint)contentOffset {
    UIGraphicsBeginImageContext(self.bounds.size);
    //need to translate the context down to the current visible portion of the scrollview
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0f, -contentOffset.y);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // helps w/ our colors when blurring
    // feel free to adjust jpeg quality (lower = higher perf)
    NSData *imageData = UIImageJPEGRepresentation(image, 0.55);
    image = [UIImage imageWithData:imageData];
    
    return image;
}

- (UIImage*) screenshotInFrame:(CGRect)frame {
    UIGraphicsBeginImageContext(frame.size);
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), frame.origin.x, frame.origin.y);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // helps w/ our colors when blurring
    // feel free to adjust jpeg quality (lower = higher perf)
    NSData *imageData = UIImageJPEGRepresentation(image, 0.75);
    image = [UIImage imageWithData:imageData];
    
    return image;
}

@end

