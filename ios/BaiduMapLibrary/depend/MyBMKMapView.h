

#import <BaiduMapAPI_Map/BMKMapView.h>
#import <React/RCTComponent.h>

@interface MyBMKMapView : BMKMapView

@property (nonatomic, copy) RCTDirectEventBlock onChange;

@end
