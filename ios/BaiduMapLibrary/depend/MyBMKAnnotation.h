

#import <UIKit/UIKit.h>
#import <BaiduMapAPI_Map/BMKPointAnnotation.h>

@interface MyBMKAnnotation : BMKPointAnnotation

@property (nonatomic, strong) UIColor           * bgColor;
@property (nonatomic, retain) NSString          * backgroundType;//标点样式

@end
