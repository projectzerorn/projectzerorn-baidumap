package com.bee.baidumapview.utils.http;

import android.content.Context;
import android.content.res.AssetManager;
import com.bee.baidumapview.utils.http.depend.HttpDownloadHandle;
import com.bee.baidumapview.utils.http.depend.HttpRequest;
import com.bee.baidumapview.utils.http.depend.HttpResponseHandle;
import com.bee.baidumapview.utils.http.depend.HttpUploadHandle;

import javax.net.ssl.*;
import java.io.*;
import java.net.HttpURLConnection;
import java.net.Proxy;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.util.Map;
import java.util.Map.Entry;


/**
 * http工具类<br>
 * 提供http及https相关get、post方法使用及上传下载文件方法（提供自定义handle处理下载进度等）
 *  * <br>
 * https添加服务器白名单步骤：<br>
 * 1. HttpUtil.httpsInit()添加域名白名单<br>
 * 2. 在assets中放入crt证书<br>
 * <br>
 *
 * ps.关于电子证书可参见：http://blog.csdn.net/googling/article/details/6698255
 *
 *
 * @author jackzhou
 * 
 */
public class HttpUtil {

    /** 默认连接超时时间 单位：毫秒 */
    final static int     CONNECT_TIME_OUT = 10 * 1000;
    /** 默认读取超时时间 单位：毫秒 */
    final static int     READ_TIME_OUT    = 20 * 1000;
    /** 默认url是否encode */
    final static boolean IS_ENCODE        = true;
    /** 默认传输是否gzip */
    final static boolean IS_GZIP          = true;

    private static HostnameVerifier TRUSTED_VERIFIER;
    /** api白名单 */
    private static String[] trusted_host_array;

    private static Context mContext;
    private static final String NOT_INITIALIZE_ERROR_STRING = HttpUtil.class.getSimpleName()
            + " not initialize. Please run "
            + HttpUtil.class.getSimpleName()
            + ".httpsInit() first !";

    /**
     * 使用https请求需要先初始化
     * @param context
     */
    public static void httpsInit(Context context, String [] trustedHost) {
        mContext = context;
        trusted_host_array = trustedHost;
    }

    /**
     * 简单get方法，请求失败、超时等返回null
     *
     * @param url
     *            请求地址
     * @return
     */
    public static String getMethod(String url) {
        return getMethod(url, null, null, IS_ENCODE, IS_GZIP, null);
    }

    /**
     * get方法
     *
     * @param url
     *            请求地址
     * @param handle
     *            自定义回调
     * @return
     */
    public static String getMethod(String url, HttpResponseHandle handle) {
        return getMethod(url, null, null, IS_ENCODE, IS_GZIP, handle);
    }

    /**
     * 简单get方法，请求失败、超时等返回null
     *
     * @param url
     *            请求地址
     * @param paramter
     *            自定义回调
     * @return
     */
    public static String getMethod(String url, Map<String, String> paramter) {
        return getMethod(url, null, paramter, IS_ENCODE, IS_GZIP, null);
    }

    /**
     * get方法
     *
     * @param url
     * @param header
     * @param paramter
     * @param handle
     * @return
     */
    public static String getMethod(String url, Map<String, String> header, Map<String, String> paramter,
            HttpResponseHandle handle) {
        return getMethod(url, header, paramter, IS_ENCODE, IS_GZIP, handle);
    }

    /**
     * get方法
     *
     * @param url
     *            请求地址
     * @param paramter
     *            请求参数
     * @param handle
     *            自定义回调
     * @return
     */
    public static String getMethod(String url, Map<String, String> paramter, HttpResponseHandle handle) {
        return getMethod(url, null, paramter, IS_ENCODE, IS_GZIP, handle);
    }

    /**
     * get方法
     * 
     * @param url
     *            请求地址
     * @param header
     *            请求头
     * @param paramter
     *            请求参数
     * @param encode
     *            url是否encode
     * @param gzip
     *            传输是否gzip压缩
     * @param handle
     *            自定义回调
     * @return
     */
    public static String getMethod(String url, Map<String, String> header, Map<String, String> paramter,
            boolean encode, boolean gzip, HttpResponseHandle handle) {
        httpRequestInit();

        String ret = null;
        HttpRequest request = HttpRequest.get(url, paramter, encode);
        if(url.startsWith("https")){
            trustCertsAndHosts(request);
        }

        // 是否压缩
        if (gzip) {
            request.acceptGzipEncoding().uncompress(true);
        }

        // 设置header
        if (header != null && header.size() > 0) {
            for (Entry<String, String> temp : header.entrySet()) {
                request.header(temp);
            }
        }
        
        try {
            if (request.ok()) {
                ret = request.body();
                if (handle != null) {
                    handle.onSuccess(ret, request.code());
                }
            }
        } catch (HttpRequest.HttpRequestException exception) {
            if (handle != null && SocketTimeoutException.class.isInstance(exception.getCause())) {
                handle.onTimeOut();
            } else if (handle != null) {
                handle.onFailure(exception.getCause());
            }
            exception.printStackTrace();
            ret = null;
        }
        return ret;
    }

    /**
     * 简单post方法，请求失败、超时等返回null
     * 
     * @param url
     *            请求地址
     * @param form
     *            表单数据
     * @return
     */
    public static String postMethod(String url, Map<String, String> form) {
        return postMethod(url, null, null, form, IS_ENCODE, null);
    }

    /**
     * post方法
     * 
     * @param url
     *            请求地址
     * @param form
     *            表单数据
     * @param handle
     *            自定义回调
     * @return
     */
    public static String postMethod(String url, Map<String, String> form, HttpResponseHandle handle) {
        return postMethod(url, null, null, form, IS_ENCODE, handle);
    }

    /**
     * 简单post方法，请求失败、超时等返回null
     * 
     * @param url
     *            请求地址
     * @param paramter
     *            请求url上的参数
     * @param form
     *            表单数据
     * @return
     */
    public static String postMethod(String url, Map<String, String> paramter, Map<String, String> form) {
        return postMethod(url, null, paramter, form, IS_ENCODE, null);
    }

    /**
     * post方法
     * 
     * @param url
     *            请求地址
     * @param paramter
     *            请求url上的参数
     * @param form
     *            表单数据
     * @param handle
     *            自定义回调
     * @return
     */
    public static String postMethod(String url, Map<String, String> paramter, Map<String, String> form,
            HttpResponseHandle handle) {
        return postMethod(url, null, paramter, form, IS_ENCODE, handle);
    }

    /**
     * 简单post方法，请求失败、超时等返回null
     * 
     * @param url
     *            请求地址
     * @param header
     *            请求头
     * @param paramter
     *            请求url上的参数
     * @param form
     *            表单数据
     * @return
     */
    public static String postMethod(String url, Map<String, String> header, Map<String, String> paramter,
            Map<String, String> form) {
        return postMethod(url, header, paramter, form, IS_ENCODE, null);
    }

    /**
     * post方法
     * 
     * @param url
     *            请求地址
     * @param header
     *            请求头
     * @param paramter
     *            请求url上的参数
     * @param form
     *            表单数据
     * @param handle
     *            自定义回调
     * @return
     */
    public static String postMethod(String url, Map<String, String> header, Map<String, String> paramter,
            Map<String, String> form, HttpResponseHandle handle) {
        return postMethod(url, header, paramter, form, IS_ENCODE, handle);
    }

    /**
     * post方法
     * 
     * @param url
     *            请求地址
     * @param header
     *            请求头
     * @param paramter
     *            请求url上的参数
     * @param form
     *            表单数据
     * @param encode
     *            url是否encode
     * @param handle
     *            自定义回调
     * @return
     */
    public static String postMethod(String url, Map<String, String> header, Map<String, String> paramter,
            Map<String, String> form, boolean encode, HttpResponseHandle handle) {
        httpRequestInit();

        String ret = null;
        HttpRequest request = HttpRequest.post(url, paramter, encode);

        // 设置header
        if (header != null && header.size() > 0) {
            for (Entry<String, String> temp : header.entrySet()) {
                request.header(temp);
            }
        }

        try {
            // form数据
            if (form != null && form.size() > 0) {
                request.form(form);
            }

            // 设置参数
            if (paramter != null && paramter.size() > 0) {
                request.form(paramter);
            }

            if (request.ok()) {
                ret = request.body();
                if (handle != null) {
                    handle.onSuccess(ret, request.code());
                }
            }
        } catch (HttpRequest.HttpRequestException exception) {
            if (handle != null && SocketTimeoutException.class.isInstance(exception.getCause())) {
                handle.onTimeOut();
            } else if (handle != null) {
                handle.onFailure(exception.getCause());
            }
            exception.printStackTrace();
            ret = null;
        }

        return ret;
    }

    /**
     * 下载文件，保存在内部存储空间中context.getFilesDir(): /data/data/com.yourpackage/files
     * 
     * @param url
     *            下载文件的url
     * @param fileName
     *            保存的文件名
     * @param context
     * @return
     */
    public static File download(String url, String fileName, Context context) {
        return download(url, new File(context.getFilesDir(), fileName), null);
    }

    /**
     * 下载文件，保存在内部存储空间中context.getFilesDir(): /data/data/com.yourpackage/files
     * 
     * @param url
     *            下载文件的url
     * @param fileName
     *            保存的文件名
     * @param context
     * @param handle
     *            自定义回调
     * @return
     */
    public static File download(String url, String fileName, Context context, HttpDownloadHandle handle) {
        return download(url, new File(context.getFilesDir(), fileName), handle);
    }

    /**
     * 下载文件
     * 
     * @param url
     *            下载文件的url
     * @param file
     *            指定本地文件
     * @return
     */
    public static File download(String url, File file) {
        return download(url, file, null);
    }

    private static long totalWritten = 0;

    /**
     * 下载文件
     * 
     * @param url
     *            下载文件的url
     * @param file
     *            指定本地文件
     * @param handle
     *            自定义回调
     * @return
     */
    public static File download(String url, File file, final HttpDownloadHandle handle) {
        httpRequestInit();

        HttpRequest request = HttpRequest.get(url);

        FileOutputStream outputstream = null;
        try {
            if (handle != null) {
                handle.onStart(file);
            }
            if (request.ok()) {
                totalWritten = 0;
                final int length = request.getConnection().getContentLength();// 获取文件大小

                outputstream = new FileOutputStream(file) {
                    @Override
                    public void write(byte[] buffer, int byteOffset, int byteCount) throws IOException {
                        super.write(buffer, byteOffset, byteCount);
                        totalWritten += byteCount;
                        if (handle != null) {
                            handle.onDownLoading(totalWritten, length);
                        }
                    }
                };
                request.receive(outputstream);

                if (handle != null) {
                    handle.onSuccess(file);
                }
            }
        } catch (HttpRequest.HttpRequestException exception) {
            exception.printStackTrace();
            file = null;
            if (handle != null) {
                handle.onFailure(exception.getCause());
            }
        } catch (IOException e) {
            e.printStackTrace();
            file = null;
            if (handle != null) {
                handle.onFailure(e);
            }
        } finally {
            if (outputstream != null) {
                try {
                    outputstream.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return file;
    }

    /**
     * 上传文件
     * 
     * @param url
     *            上传地址
     * @param fileKey
     *            上传文件的key
     * @param file
     *            上传文件
     * @return
     */
    public static String upload(String url, String fileKey, File file) {
        return upload(url, fileKey, file, null, null, null);
    }

    /**
     * 上传文件
     * 
     * @param url
     *            上传地址
     * @param fileKey
     *            上传文件的key
     * @param file
     *            上传文件
     * @param uploadHandle
     *            自定义回调
     * @return
     */
    public static String upload(String url, String fileKey, File file, HttpUploadHandle uploadHandle) {
        return upload(url, fileKey, file, null, null, uploadHandle);
    }

    /**
     * 上传文件
     * @param url
     * @param fileKey
     * @param file
     * @param header
     * @param form
     * @param handle
     * @return
     */
    public static String upload(String url, String fileKey, File file, Map<String, String> header,
            Map<String, String> form, final HttpUploadHandle handle) {
        String ret = null;

        HttpRequest request = HttpRequest.post(url);

        try {
            // 设置header
            if (header != null && header.size() > 0) {
                for (Entry<String, String> temp : header.entrySet()) {
                    request.header(temp);
                }
            }

            if (handle != null) {
                handle.onStart();
                request.progress(new HttpRequest.UploadProgress() {
                    @Override
                    public void onUpload(long uploaded, long total) {
                        handle.onUpLoading(uploaded, total);
                    }
                });
            }

            request.part(fileKey, file.getName(), file);
            if (form != null && form.size() > 0) {
                for (String key : form.keySet()) {
                    String value = form.get(key);
                    request.part(key, value);
                }
            }

            if (request.ok()) {
                ret = request.body();
                if (handle != null) {
                    handle.onSuccess(ret);
                }
            }
        } catch (HttpRequest.HttpRequestException exception) {
            exception.printStackTrace();
            file = null;
            if (handle != null) {
                handle.onFailure(exception.getCause());
            }

        }

        return ret;
    }

//    public static byte[] loadByteFromNetwork(String url) throws ClientProtocolException, IOException {
//        byte[] ret = null;
//        httpRequestInit();
//
//        HttpRequest request = HttpRequest.get(url);
//
//        if (request.ok()) {
//            BufferedInputStream in = new BufferedInputStream(request.getConnection().getInputStream());
//            ByteArrayOutputStream out = new ByteArrayOutputStream();
//            byte[] buf = new byte[8192];
//            while (true) {
//                int len = in.read(buf);
//                if (len < 0) {
//                    break;
//                }
//                out.write(buf, 0, len);
//            }
//            out.close();
//            in.close();
//            ret = out.toByteArray();
//        }
//
//        return ret;
//    }

    /**
     * 初始化HttpRequest
     */
    private static void httpRequestInit() {
        HttpRequest.setConnectionFactory(sConnectionFactory);
    }

    /**
     * 默认连接的设置
     */
    private static HttpRequest.ConnectionFactory sConnectionFactory = new HttpRequest.ConnectionFactory() {
        public HttpURLConnection create(URL url) throws IOException {
            HttpURLConnection ret = (HttpURLConnection) url
                    .openConnection();
            ret.setConnectTimeout(CONNECT_TIME_OUT);
            ret.setReadTimeout(READ_TIME_OUT);
            return ret;
        }

        public HttpURLConnection create(URL url, Proxy proxy)
                throws IOException {
            HttpURLConnection ret = (HttpURLConnection) url
                    .openConnection(proxy);
            ret.setConnectTimeout(CONNECT_TIME_OUT);
            ret.setReadTimeout(READ_TIME_OUT);
            return ret;
        }
    };

    private static void trustCertsAndHosts(HttpRequest request) {

        final HttpURLConnection connection = request.getConnection();
        if (connection instanceof HttpsURLConnection) {
            ((HttpsURLConnection) connection).setSSLSocketFactory(getTrustedFactory());
            ((HttpsURLConnection) connection).setHostnameVerifier(getTrustedVerifier());
        }
    }

    private static SSLSocketFactory getTrustedFactory() throws HttpRequest.HttpRequestException {
        if (mContext == null) {
            throw new RuntimeException(NOT_INITIALIZE_ERROR_STRING);
        }

        SSLSocketFactory ret = null;
        // http://developer.android.com/training/articles/security-ssl.html#Concepts
        try {
            // Load CAs from an InputStream
            CertificateFactory cf = CertificateFactory.getInstance("X.509");

            // Create a KeyStore containing our trusted CAs
            String keyStoreType = KeyStore.getDefaultType();
            KeyStore keyStore = KeyStore.getInstance(keyStoreType);
            keyStore.load(null, null);


            //遍历
            AssetManager am = null;
            am = mContext.getAssets();
            String[] fileList = mContext.getAssets().list("");
            for(String temp: fileList){
                if(temp.endsWith(".crt")){
                    InputStream caInput = am.open(temp);
                    try {
                        Certificate ca = cf.generateCertificate(caInput);
                        keyStore.setCertificateEntry(temp, ca);
                    } catch (CertificateException e) {
                        e.printStackTrace();
                    } catch (KeyStoreException e) {
                        e.printStackTrace();
                    }finally {
                        try {
                            caInput.close();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }
                }
            }

            // Create a TrustManager that trusts the CAs in our KeyStore
            String tmfAlgorithm = TrustManagerFactory.getDefaultAlgorithm();
            TrustManagerFactory tmf = TrustManagerFactory.getInstance(tmfAlgorithm);
            tmf.init(keyStore);

            // Create an SSLContext that uses our TrustManager
            SSLContext context = SSLContext.getInstance("TLS");
            context.init(null, tmf.getTrustManagers(), null);
            ret = context.getSocketFactory();
        } catch (CertificateException e) {
            e.printStackTrace();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (KeyStoreException e) {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (KeyManagementException e) {
            e.printStackTrace();
        }

        return ret;
    }

    private static HostnameVerifier getTrustedVerifier() {
        if (TRUSTED_VERIFIER == null)
            TRUSTED_VERIFIER = new HostnameVerifier() {

                public boolean verify(String hostname, SSLSession session) {
                    boolean ret = false;
                    for (String host : trusted_host_array) {
                        if (host.equalsIgnoreCase(hostname)) {
                            ret = true;
                        }
                    }
                    return ret;
                }
            };

        return TRUSTED_VERIFIER;
    }
}
