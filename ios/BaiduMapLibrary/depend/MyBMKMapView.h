

#import <BaiduMapAPI_Map/BMKMapView.h>
#import "RCTComponent.h"

@interface MyBMKMapView : BMKMapView

@property (nonatomic, copy) RCTDirectEventBlock onChange;

@end
