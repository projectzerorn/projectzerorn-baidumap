/**
 * dialog
 * Author:honaf
 */
'use strict';

import React from 'react';
import {NativeModules, Platform,} from 'react-native';

let MyMapModule = undefined;
let plat = Platform.OS;
if (plat === 'ios') {
    MyMapModule = NativeModules.BaiduMapLibrary;
} else {
    MyMapModule = NativeModules.BaiduMapModuleManager;
}

let BDMapModule = {
    /**
     * ref:React.findNodeHandle(this.refs.history)
     */
    onDestroyBDMap(ref) {
        if (ref == undefined) {
            return;
        }
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.onDestroyBDMap(ref);
    },

    ///**
    // *距离
    // */
    //setRuler(ref,ruler){
    //    MyMapModule.setRuler(ref,ruler);
    //},

    ///**
    // * 打点
    // */
    //addPoint(ref,avatar,itemArray){
    //    if(plat === 'ios'){
    //        MyMapModule.setLocation(ref,itemArray);
    //    }else{
    //        MyMapModule.addPoint(ref,avatar,itemArray);
    //    }
    //},

    /**
     * 连线
     */
    setDrewLine(ref, itemArray) {
        if (plat === 'ios') {
            MyMapModule.showHistory_ios(ref, itemArray);
        } else {
            MyMapModule.setDrewLine(ref, itemArray);
        }
    },

    animateMapStatus(ref, value) {
        if (plat === 'ios') {
            MyMapModule.setLocation(ref, value);
        } else {
            MyMapModule.animateMapStatus(ref, value);
        }
    },

    setLocation(ref, value) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.setLocation(ref, value);
    },

    setLocationAnimation(ref, value) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.setLocationAnimation(ref, value);
    },

    seekAddress(address) {
        MyMapModule.seekAddress(address);
    },

    addGeoFenceCircle(ref, msg) {
        if (Platform.OS === 'ios') {
            MyMapModule.DrawCircle_ios(ref, msg);
        } else {
            MyMapModule.addGeoFenceCircle(ref, msg);
        }
    },

    move(ref, lat, lng, zoom, isAnimate) {//lat,lng,zoom传入-1 为不改变
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.move(ref, lat, lng, zoom, isAnimate);
    },

    zoom(ref, zoom, isAnimate = false) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.move(ref, -1, -1, zoom, isAnimate);
    },

    /**
     * //zoom++  3~19
     * @param ref
     * @param isAnimate
     */
    zoomAdd(ref, isAnimate = true) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.zoomAdd(ref, isAnimate);
    },

    /**
     * //zoom--  3~19
     * @param ref
     * @param isAnimate
     */
    zoomSub(ref, isAnimate = true) {//zoom--
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.zoomSub(ref, isAnimate);
    },

    moveToUserLocation(ref, zoom, isAnimate) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.moveToUserLocation(ref, zoom, isAnimate);
    },

    cluster(ref, data) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.cluster(ref, data);
    },

    textureMapViewOnResume(ref) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.textureMapViewOnResume(ref);
    },
    textureMapViewOnPause(ref) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.textureMapViewOnPause(ref);
    },
    textureMapViewOnDestroy(ref) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.textureMapViewOnDestroy(ref);
    },
    killApp() {
        MyMapModule.killApp();
    },

    /**
     *
     * @param ref
     * @param data
     * @param isClearMap
     * @param backgroundTypeArray
     */
    addMarks(
        ref, data, isClearMap = true, backgroundTypeArray = ['BubbleRed']) {
        if (ref == null) {//异常处理
            return;
        }

        if (!(backgroundTypeArray instanceof Array)) {//兼容以前代码，若为string则将其转化为array
            backgroundTypeArray = [backgroundTypeArray];
        }
        MyMapModule.addMarks(ref, data, isClearMap, backgroundTypeArray);
    },

    replaceMark(ref, lat, lng, backgroundType) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.replaceMark(ref, lat, lng, backgroundType);
    },

    //ak:百度地图的key
    //mcode:ak为app端的时候需要这个参数，为字符串，对应为百度地图key中的安全码
    //maxWidthDip:为图片等比缩放后宽度，注意下，调试时更换图片大小需要杀掉下app进程，不然有缓存调整的大小无效
    //radius"半径，单位：米
    //pageCapacity:搜索结果上限数
    addNearPois(
        ref, lat, lng, keyword, iconUrl, isClearMap = true, ak = '', mcode = '',
        maxWidthDip = 30, radius = 1000, pageCapacity = 50) {

        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.addNearPois(ref, lat, lng, keyword, iconUrl, isClearMap, ak,
            mcode, maxWidthDip, radius, pageCapacity);
    },

    clearMap(ref) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.clearMap(ref);
    },

    /**
     * 热力图
     * @param ref
     * @param datalist  数据
     * @param color1    自定义热力图渐变色
     * @param color2    自定义热力图渐变色
     * @param color3    自定义热力图渐变色
     */
    addHeatMap(ref, datalist, color1, color2, color3) {
        if (ref == null) {//异常处理
            return;
        }
        MyMapModule.addHeatMap(ref, datalist, color1, color2, color3);
    },
};

module.exports = BDMapModule;