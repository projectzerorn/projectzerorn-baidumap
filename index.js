import React,{ requireNativeComponent, Component, PropTypes, View, Platform } from 'react-native';

if(Platform.OS === 'ios'){
  var LibBaiduMapView = requireNativeComponent('BaiduMapLibrary', BDMapView);
}else{
  var LibBaiduMapView = requireNativeComponent('RCTBaiduMap', BDMapView);
}

class BDMapView extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
        <LibBaiduMapView {...this.props}/>
    );
  }
}

BDMapView.propTypes = {
  ...View.propTypes,
  mode: PropTypes.number,
  trafficEnabled: PropTypes.bool,
  heatMapEnabled: PropTypes.bool,
  marker:PropTypes.array,
  isShowUserLocation: PropTypes.bool,

}

export default BDMapView;
