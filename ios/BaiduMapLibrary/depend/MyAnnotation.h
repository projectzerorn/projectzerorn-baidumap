

#import <UIKit/UIKit.h>
#import <BaiduMapAPI_Map/BMKAnnotation.h>

@interface MyAnnotation : NSObject <BMKAnnotation>

@property (nonatomic) CLLocationCoordinate2D    coordinate;
@property (nonatomic, copy) NSString            * title;
@property (nonatomic, strong) UIColor           * bgColor;

@end
