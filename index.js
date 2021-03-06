import PropTypes from 'prop-types';
import React, {Component} from 'react';
import {requireNativeComponent, View, Platform} from 'react-native';

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
    }

    render() {

        return (
            <LibBaiduMapView {...this.props} onChange={this._onChange}/>
        );
    }

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
