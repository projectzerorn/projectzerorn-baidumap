import PropTypes from 'prop-types';
import React, {Component} from 'react';
import ReactNative, {
    requireNativeComponent,
    View,
    Platform,
    AppState,
} from 'react-native';
import BDMapModule from './BDMapModule.js';

if (Platform.OS === 'ios') {
    var LibBaiduMapView = requireNativeComponent('BaiduMapLibrary', BDMapView);
} else {
    var LibBaiduMapView = requireNativeComponent('RCTBaiduMap', BDMapView, {
        nativeOnly: {
            onMapStatusChangeFinish: true,
            onMapStartMove: true,
            onLongClick: true,
            onBlankClick: true,
        },
    });
}

class BDMapView extends Component {
    static defaultProps = {
        mode: 1,
        isShowUserLocation: false,
        onMapStatusChangeFinish: () => {},//地图移动结束事件
        onMapStartMove: () => {},//地图开始移动事件
        onMarkerClick: () => {},//标点点击事件
        onLongClick: () => {},//地图空白处长按事件
        onBlankClick: () => {},//地图空白处点击
        onMarkerDragFinish: () => {},//标点拖拽完成后事件
        initCenter: {lat: 0, lng: 0, zoom: 17},
    };

    constructor(props) {
        super(props);
        this.isAppInBackgroundFlag = false;//app是否按了home键到后台了 用于解决TextureMapView黑线的问题 http://bbs.lbsyun.baidu.com/forum.php?mod=viewthread&tid=126125
    }

    componentWillMount() {
        if (Platform.OS === 'android') {
            //监听状态改变事件
            AppState.addEventListener('change', this._handleAppStateChange);
        }
    }

    render() {
        return (
            <LibBaiduMapView
                ref={'locationMap'}
                {...this.props}
                onChange={this._onChange}/>
        );
    }

    componentWillUnmount() {
        if (Platform.OS === 'android') {
            //删除状态改变事件监听
            AppState.removeEventListener('change', this._handleAppStateChange);
        }
    }

    _handleAppStateChange = (nextAppState) => {
        if (nextAppState != null && nextAppState === 'active') {

            if (this.isAppInBackgroundFlag) {//从后台进入了前台
                BDMapModule.textureMapViewOnResume(
                    ReactNative.findNodeHandle(this.refs.locationMap));
            }

            this.isAppInBackgroundFlag = false;
        } else if (nextAppState != null && nextAppState === 'background') {
            this.isAppInBackgroundFlag = true;
        }
    };

    _onChange = (event: Event) => {
        let eventType = event.nativeEvent.eventType;
        if (eventType && eventType == 'onMarkerClick') {
            let dataStr = event.nativeEvent.title;
            let dataJson;
            try {
                dataJson = JSON.parse(dataStr);//通过title来传递 mark数据 数据结构为json
            } catch (e) {
                dataJson = dataStr;
            }
            this.props.onMarkerClick(dataJson);
        } else if (eventType && eventType == 'onMapStatusChangeFinish') {
            this.props.onMapStatusChangeFinish(event.nativeEvent);
        } else if (eventType && eventType == 'onMapStartMove') {
            this.props.onMapStartMove(event.nativeEvent);
        } else if (eventType && eventType == 'onLongClick') {
            this.props.onLongClick(event.nativeEvent);
        } else if (eventType && eventType == 'onBlankClick') {
            this.props.onBlankClick(event.nativeEvent);
        } else if (eventType && eventType == 'onMarkerDragFinish') {
            this.props.onMarkerDragFinish(event.nativeEvent);
        }
    };
}

BDMapView.propTypes = {
    ...View.propTypes,
    mode: PropTypes.number,
    trafficEnabled: PropTypes.bool,
    heatMapEnabled: PropTypes.bool,
    marker: PropTypes.array,
    isShowUserLocation: PropTypes.bool,
    onMapStartMove: PropTypes.func,
    onMapStatusChangeFinish: PropTypes.func,
    onMarkerClick: PropTypes.func,
    onLongClick: PropTypes.func,
    onBlankClick: PropTypes.func,
    onMarkerDragFinish: PropTypes.func,
    initCenter: PropTypes.object,
};

export default BDMapView;
