package com.bee.baidumapview;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Handler;
import android.os.Looper;
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
import com.baidu.mapapi.search.core.SearchResult;
import com.baidu.mapapi.search.geocode.*;
import com.baidu.mapapi.search.sug.OnGetSuggestionResultListener;
import com.baidu.mapapi.search.sug.SuggestionResult;
import com.baidu.mapapi.search.sug.SuggestionSearch;
import com.baidu.mapapi.search.sug.SuggestionSearchOption;
import com.bee.baidumapview.utils.ImageUtil;
import com.bee.baidumapview.utils.MapUtils;
import com.bee.baidumapview.utils.clusterutil.clustering.ClusterItem;
import com.bee.baidumapview.utils.clusterutil.clustering.ClusterManager;
import com.facebook.react.bridge.*;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;


public class BaiduMapViewModule extends ReactContextBaseJavaModule implements OnGetSuggestionResultListener {
    public static final String TAG = "RCTBaiduMap";
    private Marker markerAnimation;
//    private Marker tempMarker;
//    List<Marker> markerList = new ArrayList<>();
    private Marker markerPet;
    private Overlay mCircle;
    private LatLng tempLatlng;
    private GeoCoder mSearch;
    private ReactApplicationContext reactContext;
    private SuggestionSearch mSuggestionSearch = null;
    private Bitmap avatarBitmap;
    private Marker markerToOne;
    private HeatMap mHeatmap;

    public BaiduMapViewModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        ImageUtil.init(this.getCurrentActivity(),R.mipmap.default_avatar);
        initSearch();

    }


    @Override
    public String getName() {
        return "BaiduMapModuleManager";
    }



    /**
     * 设置宠物位置头像
     *
     * @param tag
     * @param mLatLngParm
     */
    @ReactMethod
    public void setLocation(int tag, final ReadableMap mLatLngParm) {
        Activity context = this.getCurrentActivity();
        final BaiduMap baiduMap = ((MapView) context.findViewById(tag)).getMap();
        baiduMap.clear();

        MapUtils.getViewBitmap(context, mLatLngParm.getString("avatar"), new MapUtils.GetViewBitmapCallback() {
            @Override
            public void onSuccess(Bitmap bitmap) {
                avatarBitmap = bitmap;
                LatLng mlatLng = new LatLng(mLatLngParm.getDouble("baidu_latitude"), mLatLngParm.getDouble("baidu_longitude"));
                OverlayOptions markerOptions = new MarkerOptions().position(mlatLng)
                        .icon(BitmapDescriptorFactory.fromBitmap(bitmap))
                        .anchor(0.5f, 0.5f);
                baiduMap.animateMapStatus(MapStatusUpdateFactory.newLatLng(mlatLng), 1 * 1000);
                markerPet = (Marker) baiduMap.addOverlay(markerOptions);
            }
        });
    }

    @ReactMethod
    public void animateMapStatus(int tag,final ReadableMap mLatLngParm){
        Activity context = this.getCurrentActivity();
        final BaiduMap baiduMap = ((MapView) context.findViewById(tag)).getMap();
        LatLng mlatLng = new LatLng(mLatLngParm.getDouble("baidu_latitude"), mLatLngParm.getDouble("baidu_longitude"));
        baiduMap.animateMapStatus(MapStatusUpdateFactory.newLatLng(mlatLng), 1 * 1000);
    }

    /**
     * 设置宠头像雷达动画效果
     *
     * @param tag
     * @param mLatLngParm
     */
    @ReactMethod
    public void setLocationAnimation(int tag, ReadableMap mLatLngParm) {
        Activity context = this.getCurrentActivity();
        BaiduMap baiduMap = ((MapView) context.findViewById(tag)).getMap();

        LatLng mlatLng = new LatLng(mLatLngParm.getDouble("baidu_latitude"), mLatLngParm.getDouble("baidu_longitude"));

        OverlayOptions markerAnimationOptions = new MarkerOptions().position(mlatLng)
                .icons(MapUtils.getBitmapDes(context))
                .period(10)
                .anchor(0.5f, 0.5f);

        markerAnimation = (Marker) baiduMap.addOverlay(markerAnimationOptions);
    }

//    /**
//     * 添加锚点
//     *
//     * @param tag
//     * @param pointList
//     */
//    @ReactMethod
//    public void addPoint(int tag, final String avatar, final ReadableArray pointList) {
//        Activity context = this.getCurrentActivity();
//
//
//        markerList.clear();
//
//        if (pointList != null || pointList.size() == 0) {
//            final BaiduMap baiduMap = ((MapView) context.findViewById(tag)).getMap();
//            baiduMap.clear();
//            for (int i = 0; i < pointList.size(); i++) {
//                if (i == pointList.size() - 1) {
//                    final int index = i;
//                    final ReadableMap sub = pointList.getMap(i);
//                    MapUtils.getViewBitmap(context, avatar, new MapUtils.GetViewBitmapCallback() {
//                                @Override
//                                public void onSuccess(Bitmap bitmap) {
//                                    //定义Maker坐标点
//                                    LatLng point = new LatLng(sub.getDouble("latitude"), sub.getDouble("longitude"));
//                                    tempMarker = addMark(index, baiduMap, point, bitmap);
//                                    markerList.add(tempMarker);
//                                    baiduMap.animateMapStatus(MapStatusUpdateFactory.newLatLng(point), 1 * 1000);
//                                }
//                            }
//                    );
//
//                    return;
//                }
//                ReadableMap sub = pointList.getMap(i);
//                //定义Maker坐标点
//                LatLng point = new LatLng(sub.getDouble("latitude"), sub.getDouble("longitude"));
//                markerList.add(addMark(i, baiduMap, point, BitmapFactory
//                        .decodeResource(
//                                context.getResources(),
//                                R.mipmap.im_his_route_marker)));
//            }
//        }
//
//    }

    /**
     * 画轨迹
     * @param tag
     * @param pointList
     */
    @ReactMethod
    public void setDrewLine(int tag, ReadableArray pointList) {
        Activity context = this.getCurrentActivity();
        BaiduMap baiduMap = ((MapView) context.findViewById(tag)).getMap();
        baiduMap.clear();

        if (baiduMap == null || pointList == null || pointList.size() == 0)
            return;
        List<LatLng> pathList = new ArrayList<>();

        for (int i = 0; i < pointList.size(); i++) {
            ReadableMap sub = pointList.getMap(i);
            pathList.add(new LatLng(sub.getDouble("latitude"), sub.getDouble("longitude")));
        }

        // 增加起点开始
        baiduMap.addOverlay(new MarkerOptions()
                .position(pathList.get(0))
//                    .title("起点")
                .icon(BitmapDescriptorFactory.fromBitmap(BitmapFactory
                        .decodeResource(
                                context.getResources(),
                                R.mipmap.nav_route_result_start_point))));

        if (pathList.size() > 1) {
            PolylineOptions polylineOptions = (new PolylineOptions())
                    .points(pathList)
                    .color(context.getResources().getColor(R.color.blue_500)).width(6);
            baiduMap.addOverlay(polylineOptions);
        }

        baiduMap.addOverlay(new MarkerOptions()
                .position(pathList.get(pathList.size() - 1))
//                    .title("终点")
                .icon(BitmapDescriptorFactory.fromBitmap(BitmapFactory
                        .decodeResource(
                                context.getResources(),
                                R.mipmap.nav_route_result_end_point))));
        baiduMap.animateMapStatus(MapStatusUpdateFactory.newLatLng(pathList.get(0)), 1 * 1000);
    }

//    /**
//     * 添加锚点
//     *
//     * @param mlatLng
//     */
//    public Marker addMark(int index, BaiduMap baiduMap, LatLng mlatLng, Bitmap mBitmap) {
//        OverlayOptions markerOptions = new MarkerOptions().position(mlatLng)
//                .icon(BitmapDescriptorFactory.fromBitmap(mBitmap))
//                .anchor(0.5f, 1.0f);
//        // 添加中心位置
//        Marker marker = (Marker) baiduMap.addOverlay(markerOptions);
//        marker.setZIndex(index);
//        return marker;
//    }


//    /**
//     * 设置标尺
//     * @param tag
//     * @param ruler
//     */
//    @ReactMethod
//    public void setRuler(int tag,int ruler){
//        Activity context = this.getCurrentActivity();
//        BaiduMap baiduMap = ((MapView) context.findViewById(tag)).getMap();
//        baiduMap.animateMapStatus(MapStatusUpdateFactory.zoomTo(ruler));
//    }

    /**
     * 添加电子栅栏
     */
    @ReactMethod
    public void addGeoFenceCircle(int tag, final ReadableMap mLatLngParm) {
        Activity context = this.getCurrentActivity();
        //设置按钮显示的数值
        final BaiduMap baiduMap = ((MapView) context.findViewById(tag)).getMap();

        if(tempLatlng != null){
            updateCircle(baiduMap,tempLatlng,mLatLngParm.getInt("range"));
        }else {
            final LatLng mlatLng = new LatLng(mLatLngParm.getDouble("latitude"), mLatLngParm.getDouble("longitude"));
            updateCircle(baiduMap,mlatLng,mLatLngParm.getInt("range"));
        }

        baiduMap.setOnMapClickListener(new BaiduMap.OnMapClickListener() {
            @Override
            public void onMapClick(LatLng latLng) {
                tempLatlng = latLng;
                updateCircle(baiduMap, latLng, mLatLngParm.getInt("range"));
            }

            @Override
            public boolean onMapPoiClick(MapPoi mapPoi) {
                return false;
            }
        });
    }

    @ReactMethod
    public void seekAddress(String keyWord){
        mSuggestionSearch
                .requestSuggestion((new SuggestionSearchOption())
                        .keyword(keyWord).city(""));
    }

    /**
     * 更新圈圈
     * @param baiduMap
     * @param mlatLng
     * @param range
     */
    private void updateCircle(BaiduMap baiduMap,LatLng mlatLng,int range){
        Activity context = this.getCurrentActivity();
        if (mCircle != null) {
            mCircle.remove();
        }
        // 将地理围栏添加到地图上显示
        CircleOptions circleOptions = new CircleOptions();
        circleOptions.center(mlatLng).radius(range)
                .fillColor(context.getResources().getColor(R.color.blue_transparent))
                .stroke(new Stroke(2, context.getResources().getColor(R.color.red_500)));
        mCircle = baiduMap.addOverlay(circleOptions);
        baiduMap.animateMapStatus(MapStatusUpdateFactory.newLatLng(mlatLng), 1 * 1000);
        getAddres(mlatLng);
    }


    /**
     * 根据经纬度获取地址名
     * @param mlatLng
     */
    public void getAddres(LatLng mlatLng){
        mSearch.setOnGetGeoCodeResultListener(new OnGetGeoCoderResultListener() {
            @Override
            public void onGetGeoCodeResult(GeoCodeResult result) {

            }

            @Override
            public void onGetReverseGeoCodeResult(ReverseGeoCodeResult reverseGeoCodeResult) {
                if (reverseGeoCodeResult == null || reverseGeoCodeResult.error != SearchResult.ERRORNO.NO_ERROR) {
                    return;
                }
                //获取成功
                WritableMap params = Arguments.createMap();
                WritableMap baiMapModule = Arguments.createMap();
                baiMapModule.putDouble("baidu_latitude", reverseGeoCodeResult.getLocation().latitude);
                baiMapModule.putDouble("baidu_longitude", reverseGeoCodeResult.getLocation().longitude);
                baiMapModule.putString("address", reverseGeoCodeResult.getAddress());
                baiMapModule.putInt("range", 0);
                params.putMap("result", baiMapModule);
                reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("FenceInfo", params);
            }
        });
        mSearch.reverseGeoCode(new ReverseGeoCodeOption()
                .location(mlatLng));
    }

    /**
     * 初始化搜索
     */
    private void initSearch(){
        Handler uiHandler = new Handler(Looper.getMainLooper());
        uiHandler.post(new Runnable() {
            @Override
            public void run() {
                mSearch = GeoCoder.newInstance();
                mSuggestionSearch = SuggestionSearch.newInstance();
                mSuggestionSearch.setOnGetSuggestionResultListener(BaiduMapViewModule.this);
            }
        });
    }

    @ReactMethod
    public void onDestroyBDMap(int tag){
        ((MapView) this.getCurrentActivity().findViewById(tag)).onDestroy();
    }



    @Override
    public void onGetSuggestionResult(SuggestionResult suggestionResult) {
        if (suggestionResult == null || suggestionResult.getAllSuggestions() == null) {
            return;
        }
        WritableArray cityArray = Arguments.createArray();
        WritableArray latLngArray = Arguments.createArray();
        WritableMap params = Arguments.createMap();
        for (SuggestionResult.SuggestionInfo tip : suggestionResult.getAllSuggestions()) {
            double lat = tip.pt == null ? 0 : tip.pt.latitude;
            double lon = tip.pt == null ? 0 : tip.pt.longitude;
            WritableArray latLng = Arguments.createArray();
            latLng.pushDouble(lat);
            latLng.pushDouble(lon);
            cityArray.pushString(tip.key);
            latLngArray.pushArray(latLng);
        }
        params.putArray("result_key",cityArray);
        params.putArray("result_pt",latLngArray);
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("SearchResult", params);
    }

    private MapView getMapView(int tag){
        Activity context = this.getCurrentActivity();
        MapView mapView = (MapView) context.findViewById(tag);
        return mapView;
    }

    private BaiduMap getMap(int tag){
        BaiduMap baiduMap = getMapView(tag).getMap();
        return baiduMap;
    }

    @ReactMethod
    public void move(int tag, double lat, double lng, float zoom, boolean isAnimate){
        BaiduMap baiduMap = getMap(tag);

        MapStatus.Builder builder = new MapStatus.Builder();
        if(lat != -1 && lng != -1){
            LatLng latLng = new LatLng(lat, lng);
            builder.target(latLng);
        }
        if(zoom != -1){
            builder.zoom(zoom);
        }

        if(isAnimate){
            baiduMap.animateMapStatus(MapStatusUpdateFactory.newMapStatus(builder.build()));
        }else{
            baiduMap.setMapStatus(MapStatusUpdateFactory.newMapStatus(builder.build()));
        }
    }

    // 定位相关
    LocationClient mLocClient;
    public class MyLocationListener implements BDLocationListener {//定位SDK监听函数
        MapView mMapView;
        boolean mIsAnimate;
        int mtag;
        float mZoom;

        public MyLocationListener(int tag, float zoom, boolean isAnimate){
            mMapView = getMapView(tag);
            mIsAnimate = isAnimate;
            mtag = tag;
            mZoom = zoom;
        }

        @Override
        public void onReceiveLocation(BDLocation location) {
            // map view 销毁后不在处理新接收的位置
            if (location == null || mMapView == null) {
                return;
            }
            Log.v("jackzhou", String.format("BaiduMapViewModule-onReceiveLocation-%s,%s",location.getLatitude(), location.getLongitude()));
            MyLocationData locData = new MyLocationData.Builder()
                    .accuracy(location.getRadius())
                    // 此处设置开发者获取到的方向信息，顺时针0-360
                    .direction(100).latitude(location.getLatitude())
                    .longitude(location.getLongitude()).build();
            mMapView.getMap().setMyLocationData(locData);

            BaiduMap baiduMap = getMap(mtag);
            LatLng latLng = new LatLng(location.getLatitude(), location.getLongitude());
            MapStatus.Builder builder = new MapStatus.Builder();
            builder.target(latLng).zoom(mZoom);
            if(mIsAnimate){
                baiduMap.animateMapStatus(MapStatusUpdateFactory.newMapStatus(builder.build()));
            }else{
                baiduMap.setMapStatus(MapStatusUpdateFactory.newMapStatus(builder.build()));
            }
            mLocClient.stop();
        }
        public void onReceivePoi(BDLocation poiLocation) {
        }
    }
    @ReactMethod
    public void moveToUserLocation(int tag, float zoom, boolean isAnimate){
        mLocClient = new LocationClient(this.getCurrentActivity());
        MyLocationListener myListener = new MyLocationListener(tag, zoom, isAnimate);
        mLocClient.registerLocationListener(myListener);
        LocationClientOption option = new LocationClientOption();
        option.setOpenGps(true); // 打开gps
        option.setCoorType("bd09ll"); // 设置坐标类型
        option.setScanSpan(1000);
        mLocClient.setLocOption(option);
        mLocClient.start();
    }


    /**
     * 每个Marker点，包含Marker点坐标以及图标
     */
    public class MyItem implements ClusterItem {
        private final LatLng mPosition;
        private String mTitle;

        public MyItem(LatLng latLng) {
            mPosition = latLng;
        }

        public MyItem(LatLng latLng, String title) {
            mPosition = latLng;
            mTitle = title;
        }

        @Override
        public LatLng getPosition() {
            return mPosition;
        }

        @Override
        public BitmapDescriptor getBitmapDescriptor() {
            return getMarkView(mTitle);
        }
    }
    private BitmapDescriptor getMarkView(String title){//获取自定义的markview
        if(title != null && title.length() > 0){
            View view = LayoutInflater.from(getCurrentActivity()).inflate(R.layout.custom_marker_text, null);
            TextView tv = (TextView)view.findViewById(R.id.tv_title);
            tv.setText(title);
            return BitmapDescriptorFactory.fromView(view);
        }else{
            return BitmapDescriptorFactory.fromResource(R.drawable.icon_gcoding);
        }
    }

    @ReactMethod
    public void cluster(int tag, ReadableArray data){
        MapView mapview = getMapView(tag);
        BaiduMap map = mapview.getMap();
        // 初始化点聚合管理类
        ClusterManager mClusterManager = new ClusterManager<>(getCurrentActivity(), map);
        // 向点聚合管理类中添加Marker实例

        if(data == null || data.size() == 0){
            return;
        }

        for (int i = 0; i < data.size(); i++) {
            ReadableArray nodelist = data.getArray(i);
            List<MyItem> items = new ArrayList<>();
            for(int j = 0; j < nodelist.size(); j++){
                ReadableMap node = nodelist.getMap(j);
                items.add(
                        new MyItem(
                                new LatLng(node.getDouble("lat"),node.getDouble("lng")),
                                node.getString("title")
                        )
                );
            }
            mClusterManager.addItems(items);
        }

        // 设置地图监听，当地图状态发生改变时，进行点聚合运算
        map.setOnMapStatusChangeListener(mClusterManager);

        //强制地图状态变化  刷新图标
        MapStatus status = map.getMapStatus();
        map.setMapStatus(MapStatusUpdateFactory.newMapStatus(status));
    }

    @ReactMethod
    public void addMarks(int tag, ReadableArray markslist, boolean isClearMap) {
        if(markslist == null || markslist.size() == 0){
            return;
        }

        BaiduMap map = getMap(tag);
        if(isClearMap){
            map.clear();
        }

        ArrayList<OverlayOptions> optionList = new ArrayList<OverlayOptions>();

        for (int i = 0; i < markslist.size(); i++) {
            ReadableMap mark = markslist.getMap(i);
            MyItem item = new MyItem(new LatLng(mark.getDouble("lat"), mark.getDouble("lng")), mark.getString("title"));

            String markData = null;
            try {
                markData = convertMapToJson(mark).toString();
            } catch (JSONException e) {
                e.printStackTrace();
            }

            OverlayOptions option = new MarkerOptions()
                    .position(item.getPosition())
                    .icon(item.getBitmapDescriptor())
                    .title(markData);//使用title字段传递  标点数据
            optionList.add(option);
        }

        //在地图上添加Marker，并显示
        map.addOverlays(optionList);
    }

    private JSONObject convertMapToJson(ReadableMap readableMap) throws JSONException {
        JSONObject object = new JSONObject();
        ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            switch (readableMap.getType(key)) {
            case Null:
                object.put(key, JSONObject.NULL);
                break;
            case Boolean:
                object.put(key, readableMap.getBoolean(key));
                break;
            case Number:
                object.put(key, readableMap.getDouble(key));
                break;
            case String:
                object.put(key, readableMap.getString(key));
                break;
            case Map:
                object.put(key, convertMapToJson(readableMap.getMap(key)));
                break;
            case Array:
                object.put(key, convertArrayToJson(readableMap.getArray(key)));
                break;
            }
        }
        return object;
    }

    private JSONArray convertArrayToJson(ReadableArray readableArray) throws JSONException {
        JSONArray array = new JSONArray();
        for (int i = 0; i < readableArray.size(); i++) {
            switch (readableArray.getType(i)) {
            case Null:
                break;
            case Boolean:
                array.put(readableArray.getBoolean(i));
                break;
            case Number:
                array.put(readableArray.getDouble(i));
                break;
            case String:
                array.put(readableArray.getString(i));
                break;
            case Map:
                array.put(convertMapToJson(readableArray.getMap(i)));
                break;
            case Array:
                array.put(convertArrayToJson(readableArray.getArray(i)));
                break;
            }
        }
        return array;
    }

    @ReactMethod
    public void clearMap(int tag) {
        BaiduMap baidumap = getMap(tag);

        if(baidumap != null){
            baidumap.clear();
        }

        if(mHeatmap != null){
            mHeatmap.removeHeatMap();
        }
    }

    @ReactMethod
    public void addHeatMap(int tag, ReadableArray list) {
        if(list == null || list.size() == 0){
            return;
        }

        BaiduMap baiduMap = getMap(tag);
        List<LatLng> heatPointList = new ArrayList<LatLng>();
        for (int i = 0; i < list.size(); i++) {
            ReadableMap heatPointRNMap = list.getMap(i);
            double lat = heatPointRNMap.getDouble("lat");
            double lng = heatPointRNMap.getDouble("lng");
            heatPointList.add(new LatLng(lat, lng));
        }

        mHeatmap = new HeatMap.Builder().data(heatPointList).build();
        baiduMap.addHeatMap(mHeatmap);
    }
}



