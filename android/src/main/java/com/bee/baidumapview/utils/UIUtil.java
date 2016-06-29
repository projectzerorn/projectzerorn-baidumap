package com.bee.baidumapview.utils;

import android.content.Context;
import android.graphics.Bitmap;
import android.view.View;
import android.view.View.MeasureSpec;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.widget.ListAdapter;
import android.widget.ListView;
import android.widget.RelativeLayout;

import java.util.ArrayList;
import java.util.List;

public class UIUtil {

    /**
     * view中单位换算 px转dip
     * 
     * @param context
     * @param pxValue
     * @return
     */
    public static int px2dip(Context context, float pxValue) {
        final float scale = context.getResources().getDisplayMetrics().density;
        return (int) (pxValue / scale + 0.5f);
    }

    /**
     * view中单位换算 dip转px
     * 
     * @param context
     * @param dipValue
     * @return
     */
    public static int dip2px(Context context, float dipValue) {
        final float scale = context.getResources().getDisplayMetrics().density;
        return (int) (dipValue * scale + 0.5f);
    }

    // 此方法直接照搬自网络上的一个下拉刷新的demo，此处是“估计”headView的width以及height
    /**
     * 测量View的宽和高
     * 
     * 例： measureView(headView); headContentHeight = headView.getMeasuredHeight(); headContentWidth = headView.getMeasuredWidth();
     * 
     * @param child
     */
    public static void measureView(View child) {
        LayoutParams p = child.getLayoutParams();
        if (p == null) {
            p = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        }
        int childWidthSpec = ViewGroup.getChildMeasureSpec(0, 0 + 0, p.width);
        int lpHeight = p.height;
        int childHeightSpec;
        if (lpHeight > 0) {
            childHeightSpec = MeasureSpec.makeMeasureSpec(lpHeight, MeasureSpec.EXACTLY);
        } else {
            childHeightSpec = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED);
        }
        child.measure(childWidthSpec, childHeightSpec);
    }

    /**
     * 得到所有叶子节点的View列表
     * 
     * @param root
     * @return
     */
    public static List<View> getViewGroupAllLeafs(ViewGroup root) {

        List<View> ret = new ArrayList<View>();

        if (root.getChildCount() != 0) {

            for (int i = 0; i < root.getChildCount(); i++) {

                try {
                    ViewGroup node = (ViewGroup) root.getChildAt(i);
                    ret.addAll(getViewGroupAllLeafs(node));
                } catch (Exception e) {// 非ViewGroup 为View
                    ret.add(root.getChildAt(i));
                }
            }
        }
        return ret;
    }

    /**
     * 得到所有子节点的View列表 (包括中间节点)
     * 
     * @param root
     * @return
     */
    public static List<View> getViewGroupAll(ViewGroup root) {

        List<View> ret = new ArrayList<View>();

        if (root.getChildCount() != 0) {

            for (int i = 0; i < root.getChildCount(); i++) {

                try {
                    ret.add(root.getChildAt(i));
                    ViewGroup node = (ViewGroup) root.getChildAt(i);
                    ret.addAll(getViewGroupAll(node));
                } catch (Exception e) {// 非ViewGroup 为View
                    ret.add(root.getChildAt(i));
                }
            }
        }
        return ret;
    }

    /**
     * 将view转化为bitmap
     * 
     * @param view
     * @return
     */
    public static Bitmap convertViewToBitmap(View view) {

        if (view.getLayoutParams() == null) {
            view.setLayoutParams(new LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT,
                    RelativeLayout.LayoutParams.WRAP_CONTENT));
        }

        measureView(view);
        view.layout(0, 0, view.getMeasuredWidth(), view.getMeasuredHeight());
        view.destroyDrawingCache();
        view.buildDrawingCache();

        return view.getDrawingCache();
    }

    /**
     * 获取屏幕高度
     * 
     * @param context
     * @return
     */
    public static int getWindowHeight(Context context) {
        return context.getResources().getDisplayMetrics().heightPixels;
    }

    /**
     * 获取屏幕宽度
     * 
     * @param context
     * @return
     */
    public static int getWindowWidth(Context context) {
        return context.getResources().getDisplayMetrics().widthPixels;
    }

    /**
     * 获取屏幕像素密度
     * 
     * @param context
     * @return
     */
    public static int getWindowDensity(Context context) {
        return context.getResources().getDisplayMetrics().densityDpi;
    }

    public static int getListViewMesureHeight(ListView lv) {
        int height = 0;
        try {
            ListAdapter la = lv.getAdapter();
            int count = la.getCount();
            for (int i = 0; i < count; i++) {
                View listItem = la.getView(i, null, lv);
                listItem.measure(MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED),
                        MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED));
                height += listItem.getMeasuredHeight();
            }
            height += lv.getDividerHeight() * (count - 1);
        } catch (Exception e) {
        }
        return height;
    }

    /**
     * px转换sp
     * @param context
     * @param px
     * @return
     */
    public static float px2sp(Context context, float px) {
        float scaledDensity = context.getResources().getDisplayMetrics().scaledDensity;
        return px / scaledDensity;
    }

    /**
     * sp转换px
     * @param context
     * @param sp
     * @return
     */
    public static float sp2px(Context context, float sp) {
        float scaledDensity = context.getResources().getDisplayMetrics().scaledDensity;
        return sp * scaledDensity;
    }



    public static int width(View view) {
        int width = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED);
        int height = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED);
        view.measure(width, height);
        int width1 = view.getMeasuredWidth();
        return width1;
    }
}
