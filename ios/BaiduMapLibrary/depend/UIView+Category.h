

#import <UIKit/UIKit.h>


@interface UIView (Category)
- (id) initWithScaleFrame:(CGRect)frame;

- (void)setWidth:(CGFloat)width;
- (void)setHeight:(CGFloat)height;
- (void)setTop:(CGFloat)top;
- (void)setLeft:(CGFloat)left;

@end

@interface UIView (EasyFrame)

@property (nonatomic, assign) CGSize size;

@property (nonatomic, assign) CGFloat width;

@property (nonatomic, assign) CGFloat height;

@property (nonatomic, assign) CGPoint origin;

@property (nonatomic, assign) CGFloat x;

@property (nonatomic, assign) CGFloat y;

@property (nonatomic, assign) CGFloat left;

@property (nonatomic, assign) CGFloat top;

@property (nonatomic, assign) CGFloat bottom;

@property (nonatomic, assign) CGFloat right;

@end


@interface UIView (MotionEffect)
- (void) addCenterMotionEffectsXYWithOffset:(CGFloat)offset;
@end


@interface UIView (Shake)
- (void) shakeAnimation;
@end


@interface UIView (Screenshot)
- (UIImage*) screenshot;
- (UIImage*) screenshotForScrollViewWithContentOffset:(CGPoint)contentOffset;
- (UIImage*) screenshotInFrame:(CGRect)frame;
@end


