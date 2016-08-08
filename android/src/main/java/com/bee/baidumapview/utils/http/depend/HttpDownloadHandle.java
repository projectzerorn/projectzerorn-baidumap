package com.bee.baidumapview.utils.http.depend;

import java.io.File;

public interface HttpDownloadHandle {

    public void onStart(File file);
    public void onDownLoading(long downloaded, long total);
    public void onFailure(Exception e);
    public void onSuccess(File file);
}
