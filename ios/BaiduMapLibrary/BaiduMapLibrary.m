#import "BaiduMapLibrary.h"


#import "UIImage+XG.h"
#import "MyBMKAnnotationView.h"
#import "MyBMKAnnotation.h"
#import "MyBMKMapView.h"
#import "JsonUtil.h"
#import "HexColors.h"

#define ANNOTATION_TYPE_OTHER 0
#define ANNOTATION_TYPE_TEXT 1
#define ANNOTATION_TYPE_SYSTEM 2

@implementation BaiduMapLibrary{
    MyBMKMapView *mapView_mk;
    NSString *imageUrl;
    NSMutableArray *pointDataArray;
    NSMutableArray *pointViewArray;
    BOOL     circleFlag;  //点击画圆的标识
    BMKPointAnnotation *anno;
    BMKLocationService *_locService;
    RCTResponseSenderBlock callb;
    
    Boolean moveToUserLocationFlag;//是否调用过moveToUserLocation方法
    float moveToUserLocationZoom;
    NSNumber * moveToUserLocationReactTag;
    Boolean moveToUserLocationisAnimate;
    int AnnotationType;
    UIImage* mIconImage;
}

@synthesize methodQueue = _methodQueue;
@synthesize geoSearcher;
@synthesize sugestionSearch;
@synthesize touchAddress;
@synthesize search_AddressArray;
@synthesize search_Coordinate2DArray;
@synthesize callback_RCT;
@synthesize isEnableClicked;
@synthesize range;
@synthesize fenceDic;
@synthesize iconStr;
@synthesize operationQueue;
@synthesize iconImage;
@synthesize waveTimer;
@synthesize tempArray;
@synthesize startPointFlag;
@synthesize endPointFlag;
@synthesize poisearch;

RCT_EXPORT_MODULE()     //必须导入Native的该宏，想当于声明这个类要实现自定义模块的功能

RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(showMapScaleBar,BOOL)

RCT_CUSTOM_VIEW_PROPERTY(region, MKCoordinateRegion, RCTMap){
    [view setRegion:json ? [RCTConvert MKCoordinateRegion:json] : defaultView.region animated:NO];
}

RCT_CUSTOM_VIEW_PROPERTY(isEnableClicked, BOOL, BaiduMapLibrary){
    self.isEnableClicked = [json boolValue];
    NSLog(@"self.isEnableClicked = %d",self.isEnableClicked);
}

RCT_CUSTOM_VIEW_PROPERTY(isGesturesEnabled, BOOL, BaiduMapLibrary){
    mapView_mk.gesturesEnabled = [json boolValue];
}

RCT_CUSTOM_VIEW_PROPERTY(range, int, BaiduMapLibrary){
    self.range = [json intValue];
}

RCT_CUSTOM_VIEW_PROPERTY(zoom, int, BaiduMapLibrary){
    mapView_mk.zoomLevel = [json intValue];
}

#pragma mark -------------------------------------------------- 是否显示用户位置标点
RCT_CUSTOM_VIEW_PROPERTY(isShowUserLocation, BOOL, BaiduMapLibrary){
    Boolean isShowUserLocation = [json boolValue];
    if(isShowUserLocation){
        //初始化BMKLocationService
        _locService = [[BMKLocationService alloc]init];
        _locService.delegate = self;
        //启动LocationService
        [_locService startUserLocationService];
        mapView_mk.showsUserLocation = NO;//先关闭显示的定位图层
        mapView_mk.userTrackingMode = BMKUserTrackingModeNone;//设置定位的状态
        mapView_mk.showsUserLocation = YES;//显示定位图层
    }
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

- (UIView *)view{
    MyBMKMapView *map = [[MyBMKMapView alloc] init];
    mapView_mk = map;
    map.delegate = self;
    [map setMapType:BMKMapTypeStandard];
    map.userTrackingMode = BMKUserTrackingModeFollow;
    map.zoomLevel = 17;//5;
    map.zoomEnabledWithTap = true;
    self.geoSearcher = [[BMKGeoCodeSearch alloc]init];
    self.geoSearcher.delegate = self;
    self.sugestionSearch = [[BMKSuggestionSearch alloc]init];
    self.sugestionSearch.delegate = self;
    self.iconImage = nil;
    self.startPointFlag = NO;
    self.endPointFlag = NO;
//    UITapGestureRecognizer *tapgesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(drawCrile:)];
//    tapgesture.delegate = self;
//    [map addGestureRecognizer:tapgesture];
    
    //初始化检索对象
    self.poisearch =[[BMKPoiSearch alloc]init];
    self.poisearch.delegate = self;
    
    return map;
}

#pragma mark -------------------------------------------------- 地图上画圆
- (void)drawCrile:(UITapGestureRecognizer *)gesture{
    if(self.isEnableClicked == YES){
        return;
    }
    self.touchAddress = nil;
    self.fenceDic = [[NSMutableDictionary alloc] init];
    
    UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gesture;
    MyBMKMapView *bk = (MyBMKMapView *)gesture.view;
    CGPoint point = [tap locationInView:bk];
    CLLocationCoordinate2D coord1 = [bk convertPoint:point
                                toCoordinateFromView:mapView_mk];
    CLLocationCoordinate2D  pt = (CLLocationCoordinate2D){coord1.latitude, coord1.longitude};
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];//初始化反编码请求
    reverseGeocodeSearchOption.reverseGeoPoint = pt;//设置反编码的店为pt
    BOOL flag = [self.geoSearcher reverseGeoCode:reverseGeocodeSearchOption];//发送反编码请求.并返回是否成功
    if(flag){
        NSLog(@"反geo检索发送成功 手势点击事件 pt = %f  %f",pt.latitude,pt.longitude);
        NSNumber *number1 = [NSNumber numberWithFloat:pt.latitude];
        NSNumber *number2 = [NSNumber numberWithFloat:pt.longitude];
        [self.fenceDic setObject:number1 forKey:@"baidu_latitude"];
        [self.fenceDic setObject:number2 forKey:@"baidu_longitude"];
        [bk setCenterCoordinate:coord1 animated:YES];
        BMKCircle *cir = [BMKCircle circleWithCenterCoordinate:coord1 radius:self.range];
        [bk removeOverlays:bk.overlays];
        [bk addOverlay:cir];
    }
    else{
        NSLog(@"反geo检索发送失败");
    }
    
}

#pragma mark -------------------------------------------------- 画圆 画线
- (BMKOverlayView *)mapView:(MyBMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay{
    if ([overlay isKindOfClass:[BMKCircle class]]){
        BMKCircleView* polygonView = [[BMKCircleView alloc] initWithOverlay:overlay];
        polygonView.strokeColor = [[UIColor yellowColor] colorWithAlphaComponent:0.1];
        polygonView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        polygonView.lineWidth = 2.0;
        return polygonView;
    }
    else if ([overlay isKindOfClass:[BMKPolyline class]]){
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.strokeColor = [[UIColor colorWithRed:0x2a/255. green:0xaf/255. blue:0xe7/255. alpha:1.0] colorWithAlphaComponent:1];
        polylineView.lineWidth = 2.0;
        return polylineView;
    }
    return nil;
}


#pragma mark -------------------------------------------------- 实现相关delegate 处理位置信息更新
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    [mapView_mk updateLocationData:userLocation];
}

#pragma mark -------------------------------------------------- 处理位置坐标更新
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    [mapView_mk updateLocationData:userLocation];
    
    if(moveToUserLocationFlag){
        dispatch_async(self.bridge.uiManager.methodQueue,^{
            [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
                id view = viewRegistry[moveToUserLocationReactTag];
                MyBMKMapView *bk = (MyBMKMapView *)view;
                
                float userLat = _locService.userLocation.location.coordinate.latitude;
                float userLng = _locService.userLocation.location.coordinate.longitude;
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake(userLat, userLng);
                
                BMKMapStatus* mapStatus = [bk getMapStatus];
                mapStatus.fLevel = moveToUserLocationZoom;
                mapStatus.targetGeoPt = center;
                [bk setMapStatus:mapStatus withAnimation:moveToUserLocationisAnimate];

            }];
        });

    }
    
    [_locService stopUserLocationService];
}


#pragma mark -------------------------------------------------- 接收反向地理编码结果
-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (error == 0) {
        NSMutableArray *data=[NSMutableArray arrayWithCapacity:result.poiList.count];
        for (BMKPoiInfo *info in result.poiList) {
            NSDictionary *dict=@{@"name":info.name,
                                 @"city":info.city,
                                 @"address":info.address};
            [data addObject:dict];
            self.touchAddress = info.address;
            NSLog(@"点击的地址为 ---> %@",self.touchAddress);
            [self.fenceDic setObject:self.touchAddress forKey:@"address"];
            NSNumber *ra = [NSNumber numberWithInt:self.range];
            [self.fenceDic setObject:ra forKey:@"radius"];
//            [[PetGlobal shareInstance].rootView.bridge.eventDispatcher sendDeviceEventWithName:@"FenceInfo" body:@{@"result":self.fenceDic}];
            [self.bridge.eventDispatcher sendDeviceEventWithName:@"FenceInfo" body:@{@"result":self.fenceDic}];
            break;
        }
    }
    else {
        NSLog(@"抱歉，未找到结果");
    }
}


#pragma mark -------------------------------------------------- 联想关键词搜索代理
- (void)onGetSuggestionResult:(BMKSuggestionSearch*)searcher result:(BMKSuggestionResult*)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        NSMutableArray *tempArr = [[NSMutableArray alloc] init];
        for(int i=0;i<result.ptList.count;i++){
            NSValue *v = result.ptList[i];
            CLLocationCoordinate2D coord1;
            [v getValue:&coord1];
            float f1 = coord1.latitude;
            float f2 = coord1.longitude;
            NSNumber *number1 = [NSNumber numberWithFloat:f1];
            NSNumber *number2 = [NSNumber numberWithFloat:f2];
            NSArray *arr = [[NSArray alloc] initWithObjects:number1,number2, nil];
            [tempArr addObject:arr];
        }
        
        [self.bridge.eventDispatcher sendDeviceEventWithName:@"SearchResult" body:@{@"result_pt":tempArr,@"result_key":result.keyList}];
    }
    else {
        NSLog(@"抱歉，未找到结果");
    }
}


#pragma mark -------------------------------------------------- 搜索地址
- (void)mapViewDidFinishLoading:(MyBMKMapView *)mapView{
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"MapLoaded" body:@{@"result":@"OK"}];
}

#pragma mark -------------------------------------------------- 销毁地图
RCT_EXPORT_METHOD(onDestroyBDMap:(nonnull NSNumber *)reactTag){
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            for(int i=0;i<self.tempArray.count;i++){
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waveFun:) object:[self.tempArray objectAtIndex:i]];
            }
            id view = viewRegistry[reactTag];
            if(view == NULL){
                return;
            }
            self.geoSearcher.delegate = nil;
            self.sugestionSearch.delegate = self;
            MyBMKMapView *bk = (MyBMKMapView *)view;
            [bk removeOverlays:bk.overlays];
            [bk removeAnnotations:bk.annotations];
            bk.delegate = nil;
            bk = nil;
        }];
    });
}

#pragma mark -------------------------------------------------- 搜索地址
RCT_EXPORT_METHOD(seekAddress:(NSString *)address){
    self.search_AddressArray = [[NSMutableArray alloc] init];
    self.search_Coordinate2DArray = [[NSMutableArray alloc] init];
    BMKSuggestionSearchOption* option = [[BMKSuggestionSearchOption alloc] init];
    option.keyword = address;
    BOOL _flag = [self.sugestionSearch suggestionSearch:option];
    if(_flag){
        NSLog(@"建议检索发送成功");
    }
    else{
        NSLog(@"建议检索发送失败");
    }
}

#pragma mark -------------------------------------------------- 放大 ／ 缩小地图
RCT_EXPORT_METHOD(setRuler:(nonnull NSNumber *)reactTag int:(int)level){
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            MyBMKMapView *bk = (MyBMKMapView *)view;
            bk.zoomLevel = level;
        }];
    });
}

#pragma mark - 定位定波纹闪动
- (void)waveFun:(NSArray *)data{
    dispatch_async(dispatch_get_main_queue(), ^{
        MyBMKMapView *mview = (MyBMKMapView *)[data objectAtIndex:0];
        float f1 = [[data objectAtIndex:1] floatValue];
        float f2 = [[data objectAtIndex:2] floatValue];
        float r  = [[data objectAtIndex:3] intValue];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1, f2);
        BMKCircle *cir = [BMKCircle circleWithCenterCoordinate:center radius:r];
        [mview removeOverlays:mview.overlays];
        [mview addOverlay:cir];
    });
}

- (void)showWave:(NSArray *)data{
    int r = 0;
    int count =0;
    if(self.tempArray.count > 0){
        [self.tempArray removeAllObjects];
    }
    else{
        self.tempArray = [[NSMutableArray alloc] init];
    }
    for(int i=1;i<4;i++){
        for(int j=1;j<8;j++){
            if(j==1)
                r = 20;
            else if (j==2)
                r = 25;
            else if (j==3)
                r = 30;
            else if (j==4)
                r = 35;
            else if (j==5)
                r = 40;
            else if (j==6)
                r = 45;
            else if (j==7)
                r = 50;
            count++;
            NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:data];
            [self.tempArray addObject:temp];;
            [temp addObject:[NSNumber numberWithInt:r]];
            [self performSelector:@selector(waveFun:) withObject:temp afterDelay:count*0.3];
        }
    }
    [self performSelector:@selector(removeWave:) withObject:[data objectAtIndex:0] afterDelay:count*0.3+1];
}

- (void)removeWave:(id)map{
    MyBMKMapView *mv = (MyBMKMapView *)map;
    [mv removeOverlays:mv.overlays];
}


#pragma mark - 设置坐标点动画
RCT_EXPORT_METHOD(setLocationAnimation:(nonnull NSNumber *)reactTag data:(id)data){
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            NSObject *obj = data;
            if([obj isKindOfClass:[NSDictionary class]]){
                NSDictionary *dic = (NSDictionary *)obj;
                id view = viewRegistry[reactTag];
                MyBMKMapView *bk = (MyBMKMapView *)view;
                float f1_1 = [dic[@"baidu_latitude"] floatValue];
                float f1_2 = [dic[@"baidu_longitude"] floatValue];
                NSArray *arr = [[NSArray alloc] initWithObjects:bk,
                                [NSNumber numberWithFloat:f1_1],
                                [NSNumber numberWithFloat:f1_2],nil];
                for(int i=0;i<self.tempArray.count;i++){
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waveFun:) object:[self.tempArray objectAtIndex:i]];
                }
                [self performSelector:@selector(showWave:) withObject:arr afterDelay:.1];
                
                
                
                BMKPointAnnotation *anno1 = [[BMKPointAnnotation alloc] init];
                anno1.title = @"1";
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake(22.1234, 113.4321);
                anno1.coordinate = center;
                [bk setCenterCoordinate:center animated:NO];
                [bk addAnnotation:anno1];
                
            }
            
            
        }];
        
        
        
        
    });
}


#pragma mark -------------------------------------------------- 提供给JS使用，在地图上标记锚点
RCT_EXPORT_METHOD(setLocation:(nonnull NSNumber *)reactTag data:(id)data)
{
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            MyBMKMapView *bk = (MyBMKMapView *)view;
            NSObject *obj = data;
            if([obj isKindOfClass:[NSDictionary class]]){
                NSDictionary *dic = (NSDictionary *)obj;
                
                float f1_1 = [dic[@"baidu_latitude"] floatValue];
                float f1_2 = [dic[@"baidu_longitude"] floatValue];
                self.iconStr = dic[@"avatar"];
                NSArray *annoArr = bk.annotations;
                BOOL tempflag = NO;
                BMKPointAnnotation *temp;
                for(int i=0;i<annoArr.count;i++){
                    temp = [annoArr objectAtIndex:i];
                    if([temp.title intValue] == 1){
                        tempflag = YES;
                        break;
                    }
                }
                if(tempflag == YES){
                    [bk removeAnnotation:temp];
                }
                BMKPointAnnotation *anno1 = [[BMKPointAnnotation alloc] init];
                anno1.title = @"1";
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1_1, f1_2);
                if([dic[@"fristTime"] boolValue] == YES){
                    [bk setCenterCoordinate:center animated:NO];
                }
                else{
                    anno1.coordinate = center;
                    [bk setCenterCoordinate:center animated:NO];
                    [bk addAnnotation:anno1];
                }
            }
            
            else if([obj isKindOfClass:[NSArray class]]){
                [bk removeAnnotations:bk.annotations];
                [bk removeOverlays:bk.overlays];
                NSArray *temp = (NSArray *)obj;
                for(int i=0;i<temp.count;i++){
                    NSDictionary *dic = (NSDictionary *)[temp objectAtIndex:i];
                    float f1_1 = [dic[@"baidu_latitude"] floatValue];
                    float f1_2 = [dic[@"baidu_longitude"] floatValue];
                    self.iconStr = @"im_his_route_marker_ios.png";
                    BMKPointAnnotation *anno1 = [[BMKPointAnnotation alloc] init];
                    anno1.title = dic[@"baidu_latitude"];
                    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1_1, f1_2);
                    if([dic[@"fristTime"] boolValue] == YES){
                        [bk setCenterCoordinate:center animated:NO];
                    }
                    else{
                        anno1.coordinate = center;
                        [bk setCenterCoordinate:center animated:NO];
                        [bk addAnnotation:anno1];
                    }
                }
            }
        }];
    });
}

#pragma mark -------------------------------------------------- 当拉动滑条改变围栏半径是，调用此方法，需将围栏的经纬度传过来
RCT_EXPORT_METHOD(DrawCircle_ios:(nonnull NSNumber *)reactTag data:(id)data){
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            MyBMKMapView *bk = (MyBMKMapView *)view;
            [bk removeAnnotations:bk.annotations];
            [bk removeOverlays:bk.overlays];
            NSObject *obj = data;
            if([obj isKindOfClass:[NSDictionary class]]){
                NSDictionary *dic = (NSDictionary *)obj;
                if(((NSString *)dic[@"address"]).length < 1)
                    return ;
                float f1_1;
                float f1_2;
                if([dic objectForKey:@"baidu_latitude"]){
                    f1_1 = [dic[@"baidu_latitude"] floatValue];
                    f1_2 = [dic[@"baidu_longitude"] floatValue];
                }
                else{
                    f1_1 = [dic[@"latitude"] floatValue];
                    f1_2 = [dic[@"longitude"] floatValue];
                }
                int ra = [dic[@"range"] floatValue];
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1_1, f1_2);
                [bk setCenterCoordinate:center animated:NO];
                BMKCircle *cir = [BMKCircle circleWithCenterCoordinate:center radius:ra];
                [bk removeOverlays:bk.overlays];
                [bk addOverlay:cir];
            }
        }];
    });
}


#pragma mark -------------------------------------------------- 画历史轨迹
RCT_EXPORT_METHOD(showHistory_ios:(nonnull NSNumber *)reactTag data:(id)data)
{
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            MyBMKMapView *bk = (MyBMKMapView *)view;
            [bk removeAnnotations:bk.annotations];
            [bk removeOverlays:bk.overlays];
            pointDataArray = [[NSMutableArray alloc] init];
            NSObject *obj = data;
            if([obj isKindOfClass:[NSArray class]]){
                NSArray *arr = (NSArray *)obj;
                for(int i=0;i<arr.count;i++){
                    [pointDataArray addObject:arr[i]];
                }
                [self drawLine:pointDataArray mapView:bk];
            }
        }];
    });
}

#pragma mark -------------------------------------------------- 移除地图上添加的锚点、线条
RCT_EXPORT_METHOD(ReSetMapview_ios){
    dispatch_async(dispatch_get_main_queue(), ^{
        [mapView_mk removeAnnotations:mapView_mk.annotations];
        [mapView_mk removeOverlays:mapView_mk.overlays];
    });
}

#pragma mark -------------------------------------------------- 画线函数
- (void)drawLine:(NSMutableArray *)linedata mapView:(MyBMKMapView *)mapview{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(linedata.count == 0)
            return;
        if(linedata.count > 1){
            for(int i=0;i<pointDataArray.count-1;i++){
                NSDictionary *dic1 = [pointDataArray objectAtIndex:i];
                NSDictionary *dic2 = [pointDataArray objectAtIndex:i+1];
                
                float f1_1 = [dic1[@"baidu_latitude"] floatValue];
                float f1_2 = [dic1[@"baidu_longitude"] floatValue];
                
                float f2_1 = [dic2[@"baidu_latitude"] floatValue];
                float f2_2 = [dic2[@"baidu_longitude"] floatValue];
                
                CLLocationCoordinate2D coors[2] = {0};
                coors[0].latitude  = f1_1;
                coors[0].longitude = f1_2;
                coors[1].latitude  = f2_1;
                coors[1].longitude = f2_2;
                BMKPolyline* polyline = [BMKPolyline polylineWithCoordinates:coors count:2];
                [mapview addOverlay:polyline];
            }
            //        for(int i=0;i<1;i++)
            {
                NSDictionary *dic1 = [pointDataArray objectAtIndex:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.startPointFlag = YES;
                    float f1_1 = [dic1[@"baidu_latitude"] floatValue];
                    float f1_2 = [dic1[@"baidu_longitude"] floatValue];
                    BMKPointAnnotation *anno1 = [[BMKPointAnnotation alloc] init];
                    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1_1, f1_2);
                    anno1.coordinate = center;
                    [mapview addAnnotation:anno1];
                });
            }
            {
                NSDictionary *dic1 = [pointDataArray lastObject];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.endPointFlag = YES;
                    float f1_1 = [dic1[@"baidu_latitude"] floatValue];
                    float f1_2 = [dic1[@"baidu_longitude"] floatValue];
                    BMKPointAnnotation *anno1 = [[BMKPointAnnotation alloc] init];
                    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1_1, f1_2);
                    anno1.coordinate = center;
                    [mapview addAnnotation:anno1];
                });
            }
        }
        else{
            NSDictionary *dic1 = [pointDataArray objectAtIndex:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.startPointFlag = YES;
                float f1_1 = [dic1[@"baidu_latitude"] floatValue];
                float f1_2 = [dic1[@"baidu_longitude"] floatValue];
                BMKPointAnnotation *anno1 = [[BMKPointAnnotation alloc] init];
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1_1, f1_2);
                anno1.coordinate = center;
                [mapview addAnnotation:anno1];
            });
            NSDictionary *dic2 = [pointDataArray objectAtIndex:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.endPointFlag = YES;
                float f1_1 = [dic2[@"baidu_latitude"] floatValue];
                float f1_2 = [dic2[@"baidu_longitude"] floatValue];
                BMKPointAnnotation *anno1 = [[BMKPointAnnotation alloc] init];
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1_1, f1_2);
                anno1.coordinate = center;
                [mapview addAnnotation:anno1];
            });
        }
        NSDictionary *dic1 = [pointDataArray lastObject];
        float f1_1 = [dic1[@"baidu_latitude"] floatValue];
        float f1_2 = [dic1[@"baidu_longitude"] floatValue];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1_1, f1_2);
        [mapview setCenterCoordinate:center animated:NO];
    });
}

- (void)drawLineInMainThread:(BMKPolyline *)polyline{
    [mapView_mk addOverlay:polyline];
}

- (void)locationPoint:(NSDictionary *)dic{
    float f1_1 = [dic[@"latitude"] floatValue];
    float f1_2 = [dic[@"longitude"] floatValue];
    
    BMKPointAnnotation *anno1 = [[BMKPointAnnotation alloc] init];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1_1, f1_2);
    anno1.coordinate = center;
    [mapView_mk setCenterCoordinate:center animated:NO];
    [mapView_mk addAnnotation:anno1];
    [pointViewArray addObject:anno1];
}

- (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size{
    UIGraphicsBeginImageContext(size);
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

#pragma mark - 合并两个图片
- (UIImage *)mergeToeImage:(UIImage *)img1 image2:(UIImage *)img2{
    UIImage *img2_ = [UIImage imageWithIconName:img2 borderImage:[UIImage imageNamed:@"home_electri.png"] border:1];
    CGSize size = CGSizeMake(130, 130);
    UIGraphicsBeginImageContext(size);
    [img1 drawInRect:CGRectMake(0, 0, 130, 130)];
    [img2_ drawInRect:CGRectMake(25, 8, 80, 80)];
    UIImage *resultingImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultingImage;
}

#pragma mark -------------------------------------------------- 打点回调函数，自定义图片
- (BMKAnnotationView *)mapView:(MyBMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation{
    if(AnnotationType == ANNOTATION_TYPE_TEXT){
        MyBMKAnnotationView *annotationView = [[MyBMKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        annotationView.canShowCallout = NO;

        return annotationView;
        
    }else if(AnnotationType == ANNOTATION_TYPE_SYSTEM){
        BMKPinAnnotationView *annotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        annotationView.canShowCallout = YES;
        annotationView.image = mIconImage;
        return annotationView;
    }else{
        BMKPinAnnotationView *newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        newAnnotationView.pinColor = BMKPinAnnotationColorGreen;
        newAnnotationView.annotation = annotation;
        if([[annotation title] intValue] == 1){
            newAnnotationView.userInteractionEnabled = NO;
        }
        NSURL *url = [NSURL URLWithString:self.iconStr];
        if(self.startPointFlag == YES || self.endPointFlag == YES){
            if(self.startPointFlag == YES){
                self.startPointFlag = NO;
                newAnnotationView.image = [UIImage imageNamed:@"nav_route_result_start_point_ios.png"];
            }
            if(self.endPointFlag == YES){
                self.endPointFlag = NO;
                newAnnotationView.image = [UIImage imageNamed:@"nav_route_result_end_point_ios.png"];
            }
        }
        else{
            //    if(self.iconImage == nil)
            {
                if(![self.iconStr isEqualToString:@"im_his_route_marker_ios.png"]){
                    UIImage *icon = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
                    
                    UIImage *img1 = [UIImage imageNamed:@"marker_foot_ios.png"];//[UIImage imageNamed:@"MapLocatebakImg.png"];
                    self.iconImage = [self mergeToeImage:img1 image2:icon];
                    
                    self.iconImage = [self scaleToSize:self.iconImage size:CGSizeMake(80, 80)];
                }
                else{
                    self.iconImage = [UIImage imageNamed:self.iconStr];
                }
            }
            
            newAnnotationView.image = self.iconImage;
        }
        return newAnnotationView;
    }
}


- (void)mapView:(MyBMKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    //	NSLog(@"region change = %f",mapView.region.center.latitude);
    //	float f1_1 = mapView.region.center.latitude;
    //	float f1_2 = mapView.region.center.longitude;
    //	BMKPointAnnotation *anno1 = [[BMKPointAnnotation alloc] init];
    //	CLLocationCoordinate2D center = CLLocationCoordinate2DMake(f1_1, f1_2);
    //	anno1.coordinate = center;
    //	[mapView addAnnotation:anno1];
}

#pragma mark -------------------------------------------------- BDMapModule定位到用户坐标
RCT_EXPORT_METHOD(moveToUserLocation:(nonnull NSNumber *)reactTag zoom:(float)zoom isAnimate:(BOOL)isAnimate){
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            MyBMKMapView *bk = (MyBMKMapView *)view;
            
            if(_locService != nil && _locService.userLocation != nil && _locService.userLocation.location.coordinate.latitude != 0){
                float userLat = _locService.userLocation.location.coordinate.latitude;
                float userLng = _locService.userLocation.location.coordinate.longitude;
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake(userLat, userLng);
                
                BMKMapStatus* mapStatus = [bk getMapStatus];
                mapStatus.fLevel = zoom;
                mapStatus.targetGeoPt = center;
                
                [bk setMapStatus:mapStatus withAnimation:isAnimate];
            }else{
                //初始化BMKLocationService
                _locService = [[BMKLocationService alloc]init];
                _locService.delegate = self;
                //启动LocationService
                [_locService startUserLocationService];
                moveToUserLocationFlag = true;
                moveToUserLocationZoom = zoom;
                moveToUserLocationReactTag = reactTag;
                moveToUserLocationisAnimate = isAnimate;
            }
        }];
    });
}

#pragma mark -------------------------------------------------- BDMapModule移动到坐标
RCT_EXPORT_METHOD(move:(nonnull NSNumber *)reactTag lat:(float)lat lng:(float)lng zoom:(float)zoom isAnimate:(BOOL)isAnimate){
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            MyBMKMapView *bk = (MyBMKMapView *)view;
                
            BMKMapStatus* mapStatus = [bk getMapStatus];
            if(zoom != -1){
                mapStatus.fLevel = zoom;
            }
            if(lat != -1 && lng != -1){
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lng);
                mapStatus.targetGeoPt = center;
            }
            
            [bk setMapStatus:mapStatus withAnimation:isAnimate];
        }];
    });
}

#pragma mark -------------------------------------------------- BDMapModule添加标点
RCT_EXPORT_METHOD(addMarks:(nonnull NSNumber *)reactTag data:(NSArray*)data isClearMap:(BOOL)isClearMap backgroundTypeArray:(NSArray*)backgroundTypeArray){
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            MyBMKMapView *bk = (MyBMKMapView *)view;
            AnnotationType = ANNOTATION_TYPE_TEXT;

            if(isClearMap){//clear map
                [bk removeOverlays:bk.overlays];
                [bk removeAnnotations:bk.annotations];
            }
            
            NSMutableArray *annotationList = [[NSMutableArray alloc] init];
            for(int i=0;i<data.count;i++){
                NSDictionary *dic = (NSDictionary *)[data objectAtIndex:i];
                NSString* backgroundType;
                if(data.count > backgroundTypeArray.count){
                    backgroundType = [backgroundTypeArray objectAtIndex:0];
                }else{
                    backgroundType = [backgroundTypeArray objectAtIndex:i];
                }
                
                float lat = [dic[@"lat"] floatValue];
                float lng = [dic[@"lng"] floatValue];
                if(isnan(lat) || isnan(lng)){//数据问题 跳过
                    continue;
                }
                NSString* title = [dic objectForKey:@"title"];
                
                MyBMKAnnotation* annotation = [[MyBMKAnnotation alloc]init];
                CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(lat, lng);
                annotation.coordinate = coor;
                NSString *all = [JsonUtil dictToJsonStr:dic];
                annotation.title = all;//使用title字段传递节点的所有数据
                if([backgroundType rangeOfString:@"Red"].location != NSNotFound){//包含
                    annotation.bgColor = [UIColor hx_colorWithHexString:@"#ed1b23"];
                }else if([backgroundType rangeOfString:@"Orange"].location != NSNotFound){//包含
                    annotation.bgColor = [UIColor hx_colorWithHexString:@"#f26521"];
                }else if([backgroundType rangeOfString:@"Yellow"].location != NSNotFound){//包含
                    annotation.bgColor = [UIColor hx_colorWithHexString:@"#fbaf5c"];
                }else if([backgroundType rangeOfString:@"Green"].location != NSNotFound){//包含
                    annotation.bgColor = [UIColor hx_colorWithHexString:@"#10aa9a"];
                }
                annotation.backgroundType = backgroundType;
                
                
                [annotationList addObject:annotation];
            }
            [bk addAnnotations:annotationList];
        }];
    });
}

#pragma mark -------------------------------------------------- BDMapModule添加周边标点
RCT_EXPORT_METHOD(  addNearPois:
                  (nonnull NSNumber *)reactTag
                            lat:(double)lat
                            lng:(double)lng
                        keyword:(NSString*)keyword
                        iconUrl:(NSString*)iconUrl
                     isClearMap:(BOOL)isClearMap
                             ak:(NSString*)ak
                          mcode:(NSString*)mcode
                    maxWidthDip:(int)maxWidthDip
                         radius:(int)radius
                   pageCapacity:(int)pageCapacity
                  ){
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            MyBMKMapView *bk = (MyBMKMapView *)view;
            
            if(isClearMap){//clear map
                [bk removeOverlays:bk.overlays];
                [bk removeAnnotations:bk.annotations];
            }
            
            //下载icon图片
            //创建异步线程执行队列
            dispatch_queue_t asynchronousQueue = dispatch_queue_create("imageDownloadQueue", NULL);
            //创建异步线程
            dispatch_async(asynchronousQueue, ^{
                //网络下载图片  NSData格式
                NSError *error;
                NSData *imageData = [NSData dataWithContentsOfURL: [NSURL URLWithString:iconUrl] options:NSDataReadingMappedIfSafe error:&error];
                if (imageData) {
                    UIImage* sourceImg = [UIImage imageWithData:imageData];
                    
                    int maxWidthpx;
                    UIScreen *currentScreen = [UIScreen mainScreen];
                    float phoneWidth = currentScreen.applicationFrame.size.width;
                    if(phoneWidth == 320.0f){//iphone5s
                        maxWidthpx = maxWidthDip * 2;
                    }else if(phoneWidth == 375.0f){//iphone6s
                        maxWidthpx = maxWidthDip * 2.5;
                    }else if(phoneWidth == 414.0f){//iphone6s plus
                        maxWidthpx = maxWidthDip * 3.5;
                    }

                    mIconImage = [self imageCompressForWidth:sourceImg targetWidth:maxWidthpx];
                }
                
                //poi搜索
                //搜索周边poi
                NSString* urlStr = [NSString stringWithFormat:
                                    @"http://api.map.baidu.com/place/v2/search?query=%@&location=%f,%f&radius=%d&output=json&ak=%@&mcode=%@",
                                    keyword,
                                    lat,
                                    lng,
                                    radius,
                                    ak,
                                    mcode];
                NSLog(@"%@", urlStr);
                NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0f];
                NSURLResponse *response = nil;
                NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                NSLog(@"%@", dict);
                
                
                //回到主线程更新UI
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if([[dict objectForKey:@"status"] integerValue] == 0){
                        NSMutableArray * resultArray = [dict mutableArrayValueForKey:@"results"];
                        
                        AnnotationType = ANNOTATION_TYPE_SYSTEM;
                        NSMutableArray *annotations = [NSMutableArray array];
                        for (int i = 0; i < resultArray.count; i++) {
                            NSDictionary* poi = [resultArray objectAtIndex:i];
                            BMKPointAnnotation* item = [[BMKPointAnnotation alloc]init];
                            float lat = [[[poi valueForKey:@"location"] valueForKey:@"lat"] floatValue];
                            float lng = [[[poi valueForKey:@"location"] valueForKey:@"lng"] floatValue];
                            item.coordinate = CLLocationCoordinate2DMake(lat,lng);
                            NSString* name = [poi valueForKey:@"name"];
                            NSString* address = [poi valueForKey:@"address"];
                            if([keyword containsString:@"公交站"] || [keyword containsString:@"地铁站"]){
                                item.title = [NSString stringWithFormat:@"%@(%@)", name, address];
                            }else{
                                item.title = name;
                            }
                            
                            [annotations addObject:item];
                        }
                        
                        [bk addAnnotations:annotations];
                    }
                    
                    //百度关键字无法多关键字查找  使用web api替换
//                    //发起poi检索查询
//                    BMKNearbySearchOption *option = [[BMKNearbySearchOption alloc]init];
//                    option.pageIndex = 0;
//                    option.pageCapacity = pageCapacity;
//                    option.location = CLLocationCoordinate2DMake(lat, lng);
//                    option.keyword = keyword;
//                    option.radius = radius;
//                    [self.poisearch poiSearchNearBy:option];
                });
            });
        }];
    });
}


//百度关键字无法多关键字查找  使用web api替换
//#pragma mark -------------------------------------------------- 实现PoiSearchDeleage处理回调结果
//- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)result errorCode:(BMKSearchErrorCode)error
//{
//    if (error == BMK_SEARCH_NO_ERROR) {
//        AnnotationType = ANNOTATION_TYPE_SYSTEM;
//        //在此处理正常结果
//        NSMutableArray *annotations = [NSMutableArray array];
//        for (int i = 0; i < result.poiInfoList.count; i++) {
//            BMKPoiInfo* poi = [result.poiInfoList objectAtIndex:i];
//            BMKPointAnnotation* item = [[BMKPointAnnotation alloc]init];
//            item.coordinate = poi.pt;
//            item.title = poi.name;
//            [annotations addObject:item];
//        }
//        
//        [mapView_mk addAnnotations:annotations];
////        [mapView_mk showAnnotations:annotations animated:YES];
//    }else{
//        NSLog(@"抱歉，未找到结果");
//    }
//}



#pragma mark -------------------------------------------------- BDMapModule清空地图
RCT_EXPORT_METHOD(clearMap:(nonnull NSNumber *)reactTag){
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            MyBMKMapView *bk = (MyBMKMapView *)view;
            
            [bk removeOverlays:bk.overlays];
            [bk removeAnnotations:bk.annotations];
            [bk removeHeatMap];
        }];
    });
}

#pragma mark BMKMapViewDelegate-------------------------------------------------- 地图区域改变完成后会调用此接口
- (void)mapView:(MyBMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    
    float zoom = mapView_mk.getMapStatus.fLevel;
    float lat = mapView_mk.getMapStatus.targetGeoPt.latitude;
    float lng = mapView_mk.getMapStatus.targetGeoPt.longitude;

    CGFloat latitudeDelta = mapView_mk.region.span.latitudeDelta;
    CGFloat longitudeDelta = mapView_mk.region.span.longitudeDelta;
    
    CGFloat northeastLat = lat + (latitudeDelta / 2.0);//northeastLat  maxlat
    CGFloat northeastLng = lng + (longitudeDelta / 2.0);//northeastLng  maxlng
    
    CGFloat southwestLat = lat - (latitudeDelta / 2.0);//southwestLat  minlat
    CGFloat southwestLng = lng - (longitudeDelta / 2.0);//southwestLng  minlng
    
    mapView.onChange(@{
                       @"eventType": @"onMapStatusChangeFinish",
                       @"centerLat": @(lat),
                       @"centerLng": @(lng),
                       @"zoom": @(zoom),
                       @"northeastLat": @(northeastLat),
                       @"northeastLng": @(northeastLng),
                       @"southwestLat": @(southwestLat),
                       @"southwestLng": @(southwestLng)});
}


#pragma mark BMKMapViewDelegate-------------------------------------------------- 点击标点后会调用此接口
- (void)mapView:(MyBMKMapView *)mapView didSelectAnnotationView:(MyBMKAnnotationView *)view{
    
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setObject:@"onMarkerClick" forKey:@"eventType"];
    [dic setObject:view.annotation.title forKey:@"title"];//这里view.annotation.title为节点所有数据
    
    mapView.onChange(dic);
}

#pragma mark -------------------------------------------------- BDMapModule添加热力图
RCT_EXPORT_METHOD(addHeatMap:(nonnull NSNumber *)reactTag data:(NSArray*)data){
    dispatch_async(self.bridge.uiManager.methodQueue,^{
        [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            id view = viewRegistry[reactTag];
            MyBMKMapView *bk = (MyBMKMapView *)view;
            
            //创建热力图数据类
            BMKHeatMap* heatMap = [[BMKHeatMap alloc]init];
            //创建热力图数据数组
            NSMutableArray* heatMapData = [NSMutableArray array];
            for (NSDictionary *dic in data) {
                //创建BMKHeatMapNode
                BMKHeatMapNode* heapmapnode_test = [[BMKHeatMapNode alloc]init];
                CLLocationCoordinate2D coor;
                coor.latitude = [dic[@"lat"] doubleValue];
                coor.longitude = [dic[@"lng"] doubleValue];
                heapmapnode_test.pt = coor;
                heapmapnode_test.intensity = 1;//强度
                //添加BMKHeatMapNode到数组
                [heatMapData addObject:heapmapnode_test];
            }
            
            heatMap.mData = heatMapData;
            [bk addHeatMap:heatMap];
        }];
    });
}


-(UIImage *) imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = height / (width / targetWidth);
    CGSize size = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    if(CGSizeEqualToSize(imageSize, size) == NO){
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }        else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        if(widthFactor > heightFactor){
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }else if(widthFactor < heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContext(size);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil){
        NSLog(@"scale image fail");
    }
    
    UIGraphicsEndImageContext();
    return newImage;
}

@end