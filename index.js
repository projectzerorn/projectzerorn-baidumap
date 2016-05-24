import React,{ requireNativeComponent, Component, PropTypes, View, Platform } from 'react-native';

if (Platform.OS === 'ios') {
    var LibBaiduMapView = requireNativeComponent('BaiduMapLibrary', BDMapView);
} else {
    var LibBaiduMapView = requireNativeComponent('RCTBaiduMap', BDMapView, {
        nativeOnly: {
            onMapStatusChangeFinish: true,
        },
    });
}

class BDMapView extends Component {
    constructor(props) {
        super(props);
    }

    render() {

        return (
            <LibBaiduMapView {...this.props} onChange={this._onChange}/>
        );
    }

    _onChange = (event:Event)=> {
        this.props.onMapStatusChangeFinish(event.nativeEvent);
    };
}

BDMapView.propTypes = {
    ...View.propTypes,
    mode: PropTypes.number,
    trafficEnabled: PropTypes.bool,
    heatMapEnabled: PropTypes.bool,
    marker: PropTypes.array,
    isShowUserLocation: PropTypes.bool,

    onMapStatusChangeFinish: React.PropTypes.func,
}

export default BDMapView;
