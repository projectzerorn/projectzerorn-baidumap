import React, {Component, PropTypes} from 'react';
import {requireNativeComponent, View, Platform} from 'react-native';

if (Platform.OS === 'ios') {
    var LibBaiduMapView = requireNativeComponent('BaiduMapLibrary', BDMapView);
} else {
    var LibBaiduMapView = requireNativeComponent('RCTBaiduMap', BDMapView, {
        nativeOnly: {
            onMapStatusChangeFinish: true,
            onMapStartMove: true,
            onLongClick: true,
        },
    });
}

class BDMapView extends Component {
    static defaultProps = {
        mode: 1,
        isShowUserLocation: false,
        onMapStatusChangeFinish: () => {},
        onMapStartMove: () => {},
        onMarkerClick: () => {},
        onLongClick: () => {},
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
    onMapStartMove: React.PropTypes.func,
    onMapStatusChangeFinish: React.PropTypes.func,
    onMarkerClick: React.PropTypes.func,
    onLongClick: React.PropTypes.func,
};

export default BDMapView;
