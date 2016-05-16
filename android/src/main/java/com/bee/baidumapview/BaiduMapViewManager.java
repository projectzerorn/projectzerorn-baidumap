package com.bee.baidumapview;

import android.app.Activity;
import android.util.Log;
import com.baidu.location.BDLocation;
import com.baidu.location.BDLocationListener;
import com.baidu.location.LocationClient;
import com.baidu.location.LocationClientOption;
import com.baidu.mapapi.map.*;
import com.baidu.mapapi.model.LatLng;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.LayoutShadowNode;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.baidu.location.LocationClientOption.LocationMode;

public class BaiduMapViewManager extends SimpleViewManager<MapView> implements BaiduMap.OnMapLoadedCallback {
    public static final String RCT_CLASS = "RCTBaiduMap";
    public static final String TAG = "RCTBaiduMap";

    private static Activity mActivity;
    private float ruler = 15;
    private ThemedReactContext reactContext;



    @Override
    public LayoutShadowNode createShadowNodeInstance() {
        return new BaiduMapShadowNode();
    }

    @Override
    public Class getShadowNodeClass() {
        return BaiduMapShadowNode.class;
    }

    public BaiduMapViewManager(Activity activity) {

        mActivity = activity;

    }

    /**
     * 地图模式
     *
     * @param mapView
     * @param type
     *  1. 普通
     *  2.卫星
     */
    @ReactProp(name="mode", defaultInt = 1)
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
    @ReactProp(name="trafficEnabled", defaultBoolean = false)
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
    @ReactProp(name="heatMapEnabled", defaultBoolean = false)
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
    @ReactProp(name="marker")
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

    @Override
    public String getName() {
        return RCT_CLASS;
    }

    @Override
    protected MapView createViewInstance(ThemedReactContext reactContext) {
        this.reactContext = reactContext;
        return getMap();
    }

    /**
     * 设置一些amap的属性
     */
    private MapView getMap() {
        MapView mMapView = new MapView(mActivity);
        mMapView.showZoomControls(false);
        BaiduMap baiduMap = mMapView.getMap();
        baiduMap.animateMapStatus(MapStatusUpdateFactory.zoomTo(ruler), 1 * 1000);
        baiduMap.setOnMapLoadedCallback(this);
        return mMapView;
    }

    @Override
    public void onMapLoaded() {
        WritableMap params = Arguments.createMap();
        params.putString("result","OK");
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("MapLoaded", params);
    }


    // 定位相关
    boolean isFirstLoc = true; // 是否首次定位
    LocationClient mLocClient;
    public class MyLocationListener implements BDLocationListener {//定位SDK监听函数
        MapView mMapView;

        public MyLocationListener(MapView mapView){
            Log.v("jackzhou", "1111-MyLocationListener");
            mMapView = mapView;
        }

        @Override
        public void onReceiveLocation(BDLocation location) {
            Log.v("jackzhou", "1111-onReceiveLocation" + location.getLatitude() + " - " + location.getLongitude());

            try{
                System.loadLibrary("liblocSDK6a");
            }catch (UnsatisfiedLinkError e){
                Log.e("jackzhou","1111-"+e);
                e.printStackTrace();
            }


            // map view 销毁后不在处理新接收的位置
            if (location == null || mMapView == null) {
                return;
            }
            MyLocationData locData = new MyLocationData.Builder()
                    .accuracy(location.getRadius())
                    // 此处设置开发者获取到的方向信息，顺时针0-360
                    .direction(100).latitude(location.getLatitude())
                    .longitude(location.getLongitude()).build();
            mMapView.getMap().setMyLocationData(locData);
            if (isFirstLoc) {
                isFirstLoc = false;
                LatLng ll = new LatLng(location.getLatitude(),
                        location.getLongitude());
                MapStatus.Builder builder = new MapStatus.Builder();
                builder.target(ll).zoom(18.0f);
                mMapView.getMap().animateMapStatus(MapStatusUpdateFactory.newMapStatus(builder.build()));
            }
        }

        public void onReceivePoi(BDLocation poiLocation) {
        }
    }

    @ReactProp(name="isShowUserLocation", defaultBoolean = false)
    public void setIsShowUserLocation(MapView mapView, boolean isShowUserLocation) {
        if(isShowUserLocation){
            Log.v("jackzhou", "1111-isShowUserLocation- 1");
            mapView.getMap().setMyLocationEnabled(true);//开启
            mLocClient = new LocationClient(mActivity);
            MyLocationListener myListener = new MyLocationListener(mapView);
            mLocClient.registerLocationListener(myListener);
            LocationClientOption option = new LocationClientOption();
            option.setOpenGps(true); // 打开gps
            option.setCoorType("bd09ll"); // 设置坐标类型
            option.setScanSpan(1000);
            mLocClient.setLocOption(option);
            mLocClient.start();
        }else{
            mapView.getMap().setMyLocationEnabled(false);
        }
    }
}
