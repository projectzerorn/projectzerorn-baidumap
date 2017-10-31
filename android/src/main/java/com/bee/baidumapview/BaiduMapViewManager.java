package com.bee.baidumapview;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;
import com.baidu.location.BDLocation;
import com.baidu.location.BDLocationListener;
import com.baidu.location.LocationClient;
import com.baidu.location.LocationClientOption;
import com.baidu.mapapi.map.*;
import com.baidu.mapapi.model.LatLng;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import org.json.JSONException;
import org.json.JSONObject;

public class BaiduMapViewManager extends SimpleViewManager<MapView> implements BaiduMap.OnMapLoadedCallback {
    public static final String RCT_CLASS = "RCTBaiduMap";
    public static final String TAG = "RCTBaiduMap";

    private static View mInfoWindow;
    private static TextView mTv;
    private float ruler = 15;
    private ThemedReactContext reactContext;
    private ReactApplicationContext appContext;

    @Override
    public String getName() {
        return RCT_CLASS;
    }

    @Override
    protected MapView createViewInstance(ThemedReactContext reactContext) {
        this.reactContext = reactContext;
        return getMap();
    }

    public BaiduMapViewManager(ReactApplicationContext reactContext) {
        this.appContext = reactContext;
        mInfoWindow = LayoutInflater.from(this.appContext).inflate(R.layout.custom_infowindow, null);
        mTv = (TextView) mInfoWindow.findViewById(R.id.tv_poi_title);
    }

    /**
     * 地图模式
     *
     * @param mapView
     * @param type    1. 普通
     *                2.卫星
     */
    @ReactProp(name = "mode", defaultInt = 1)
    public void setMode(MapView mapView, int type) {
        Log.i(TAG, "mode:" + type);
        mapView.getMap().setMapType(type);
    }

    /**
     * 实时交通图
     *
     * @param mapView
     * @param isEnabled
     */
    @ReactProp(name = "trafficEnabled", defaultBoolean = false)
    public void setTrafficEnabled(MapView mapView, boolean isEnabled) {
        Log.d(TAG, "trafficEnabled:" + isEnabled);
        mapView.getMap().setTrafficEnabled(isEnabled);
    }

    /**
     * 实时道路热力图
     *
     * @param mapView
     * @param isEnabled
     */
    @ReactProp(name = "heatMapEnabled", defaultBoolean = false)
    public void setHeatMapEnabled(MapView mapView, boolean isEnabled) {
        Log.d(TAG, "heatMapEnabled" + isEnabled);
        mapView.getMap().setBaiduHeatMapEnabled(isEnabled);
    }


    /**
     * 显示地理标记
     *
     * @param mapView
     * @param array
     */
    @ReactProp(name = "marker")
    public void setMarker(MapView mapView, ReadableArray array) {
        Log.d(TAG, "marker:" + array);
        if (array != null) {
            for (int i = 0; i < array.size(); i++) {
                ReadableArray sub = array.getArray(i);
                //定义Maker坐标点
                LatLng point = new LatLng(sub.getDouble(0), sub.getDouble(1));
                //构建Marker图标
                BitmapDescriptor bitmap = BitmapDescriptorFactory.fromResource(R.drawable.icon_gcoding);
                //构建MarkerOption，用于在地图上添加Marker
                OverlayOptions option = new MarkerOptions()
                        .position(point)
                        .icon(bitmap)
                        .draggable(true);
                //在地图上添加Marker，并显示
                mapView.getMap().addOverlay(option);
            }
        }
    }

    /**
     * 设置一些amap的属性
     */
    private MapView getMap() {
        final MapView mMapView = new MapView(reactContext);
        mMapView.showZoomControls(false);
        final BaiduMap baiduMap = mMapView.getMap();
        baiduMap.animateMapStatus(MapStatusUpdateFactory.zoomTo(ruler), 1 * 1000);
        baiduMap.setOnMapLoadedCallback(this);

        //监听
        baiduMap.setOnMapStatusChangeListener(new BaiduMap.OnMapStatusChangeListener() {
            /**
             * 手势操作地图，设置地图状态等操作导致地图状态开始改变。
             * @param status 地图状态改变开始时的地图状态
             */
            public void onMapStatusChangeStart(MapStatus status) {
                WritableMap event = Arguments.createMap();
                event.putString("eventType", "onMapStartMove");
                event.putDouble("centerLat", status.target.latitude);
                event.putDouble("centerLng", status.target.longitude);
                event.putDouble("zoom", status.zoom);
                event.putDouble("northeastLat", status.bound.northeast.latitude);
                event.putDouble("northeastLng", status.bound.northeast.longitude);
                event.putDouble("southwestLat", status.bound.southwest.latitude);
                event.putDouble("southwestLng", status.bound.southwest.longitude);

                reactContext.getJSModule(RCTEventEmitter.class)
                        .receiveEvent(mMapView.getId(), "topChange", event);
            }

            public void onMapStatusChangeStart(MapStatus status, int reason) {

            }

            /**
             * 地图状态-变化中
             * @param status 当前地图状态
             */
            public void onMapStatusChange(MapStatus status) {
            }

            /**
             * 地图状态改变结束
             * @param status 地图状态改变结束后的地图状态
             */
            public void onMapStatusChangeFinish(MapStatus status) {
                WritableMap event = Arguments.createMap();
                event.putString("eventType", "onMapStatusChangeFinish");
                event.putDouble("centerLat", status.target.latitude);
                event.putDouble("centerLng", status.target.longitude);
                event.putDouble("zoom", status.zoom);
                event.putDouble("northeastLat", status.bound.northeast.latitude);
                event.putDouble("northeastLng", status.bound.northeast.longitude);
                event.putDouble("southwestLat", status.bound.southwest.latitude);
                event.putDouble("southwestLng", status.bound.southwest.longitude);

                reactContext.getJSModule(RCTEventEmitter.class)
                        .receiveEvent(mMapView.getId(), "topChange", event);
            }
        });

        //标点marker监听
        baiduMap.setOnMarkerClickListener(new BaiduMap.OnMarkerClickListener() {

            @Override
            public boolean onMarkerClick(Marker marker) {
                WritableMap event = Arguments.createMap();
                event.putString("eventType", "onMarkerClick");
                try {//判断是否为json
                    new JSONObject(marker.getTitle());
                } catch (JSONException e) {
                    //非json格式直接出泡泡框来显示文字
                    mTv.setText(marker.getTitle());
                    InfoWindow infoWindow = new InfoWindow(mInfoWindow, marker.getPosition(), -1 * marker.getIcon().getBitmap().getHeight());
                    baiduMap.showInfoWindow(infoWindow);
                    try {
                        mMapView.removeView(mInfoWindow);//RN的坑？ 会有个mInfoWindow显示在左上角  去掉
                    } catch (Exception e1) {

                    }

                }

                //是json格式
                event.putString("title", marker.getTitle());
                reactContext.getJSModule(RCTEventEmitter.class)
                        .receiveEvent(mMapView.getId(), "topChange", event);
                return true;
            }
        });

        //地图长按回调
        baiduMap.setOnMapLongClickListener(new BaiduMap.OnMapLongClickListener() {
            @Override
            public void onMapLongClick(LatLng latLng) {
                WritableMap event = Arguments.createMap();
                event.putString("eventType", "onLongClick");
                event.putDouble("lat", latLng.latitude);
                event.putDouble("lng", latLng.longitude);

                reactContext.getJSModule(RCTEventEmitter.class)
                        .receiveEvent(mMapView.getId(), "topChange", event);
            }
        });

        //标点拖拽监听
        baiduMap.setOnMarkerDragListener(new BaiduMap.OnMarkerDragListener() {
            @Override
            public void onMarkerDrag(Marker marker) {

            }

            @Override
            public void onMarkerDragEnd(Marker marker) {
                WritableMap event = Arguments.createMap();
                event.putString("eventType", "onMarkerDragFinish");
                event.putDouble("lat", marker.getPosition().latitude);
                event.putDouble("lng", marker.getPosition().longitude);

                reactContext.getJSModule(RCTEventEmitter.class)
                        .receiveEvent(mMapView.getId(), "topChange", event);
            }

            @Override
            public void onMarkerDragStart(Marker marker) {

            }
        });

        baiduMap.setOnMapClickListener(new BaiduMap.OnMapClickListener() {

            @Override
            public void onMapClick(LatLng latLng) {
                baiduMap.hideInfoWindow();
            }

            @Override
            public boolean onMapPoiClick(MapPoi mapPoi) {
                return false;
            }
        });

        mMapView.setMapCustomEnable(true);//打开个性化地图
        return mMapView;
    }

    @Override
    public void onMapLoaded() {
        WritableMap params = Arguments.createMap();
        params.putString("result", "OK");
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("MapLoaded", params);
    }


    // 定位相关
    LocationClient mLocClient;

    public class MyLocationListener implements BDLocationListener {//定位SDK监听函数
        MapView mMapView;

        public MyLocationListener(MapView mapView) {
            mMapView = mapView;
        }

        @Override
        public void onReceiveLocation(BDLocation location) {
            // map view 销毁后不在处理新接收的位置
            if (location == null || mMapView == null) {
                return;
            }
            Log.v("jackzhou", String.format("BaiduMapViewManager-onReceiveLocation-%s,%s", location.getLatitude(), location.getLongitude()));
            MyLocationData locData = new MyLocationData.Builder()
                    .accuracy(location.getRadius())
                    // 此处设置开发者获取到的方向信息，顺时针0-360
                    .direction(100).latitude(location.getLatitude())
                    .longitude(location.getLongitude()).build();
            mMapView.getMap().setMyLocationData(locData);
            mLocClient.stop();
        }

        public void onReceivePoi(BDLocation poiLocation) {
        }
    }

    @ReactProp(name = "isShowUserLocation", defaultBoolean = false)
    public void setIsShowUserLocation(MapView mapView, boolean isShowUserLocation) {
        if (isShowUserLocation) {
            mapView.getMap().setMyLocationEnabled(true);//开启
            mLocClient = new LocationClient(reactContext);
            MyLocationListener myListener = new MyLocationListener(mapView);
            mLocClient.registerLocationListener(myListener);
            LocationClientOption option = new LocationClientOption();
            option.setOpenGps(true); // 打开gps
            option.setCoorType("bd09ll"); // 设置坐标类型
            option.setScanSpan(1000);
            mLocClient.setLocOption(option);
            mLocClient.start();
        } else {
            mapView.getMap().setMyLocationEnabled(false);
        }
    }

    @ReactProp(name = "showZoomControls", defaultBoolean = false)
    public void showZoomControls(MapView mapView, boolean showZoomControls) {
        mapView.showZoomControls(showZoomControls);
    }
}
