package com.madv360.madv.media;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.opengl.EGL14;
import android.opengl.EGLSurface;
import android.opengl.GLES20;
import android.os.Handler;
import android.os.Message;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import com.facebook.drawee.backends.pipeline.Fresco;
import com.facebook.imagepipeline.core.ImagePipeline;
import com.madv360.android.media.MetaData;
import com.madv360.android.media.MetaDataParser;
import com.madv360.android.media.MetaDataParserFactory;
import com.madv360.android.media.ThumbnailExtractor;
import com.madv360.glrenderer.GLFilterCache;
import com.madv360.glrenderer.GLRenderTexture;
import com.madv360.glrenderer.MadvGLRenderer;
import com.madv360.glrenderer.Vec2f;
import com.madv360.madv.common.BackgroundExecutor;
import com.madv360.madv.common.Const;
import com.madv360.madv.connection.AMBACommands;
import com.madv360.madv.connection.AMBARequest;
import com.madv360.madv.connection.AMBAResponse;
import com.madv360.madv.connection.CMDConnectManager;
import com.madv360.madv.connection.MVCameraClient;
import com.madv360.madv.connection.MVCameraDownloadManager;
import com.madv360.madv.connection.MVCameraDownloadManager.FileDownloadTask;
import com.madv360.madv.connection.MVCameraDownloadManager.ThumbnailDownloadTask;
import com.madv360.madv.connection.ambaresponse.AMBAGetMediaInfoResponse;
import com.madv360.madv.connection.ambaresponse.AMBAListResponse;
import com.madv360.madv.gles.EglCore;
import com.madv360.madv.gles.GlUtil;
import com.madv360.madv.gles.MadvTextureRenderer;
import com.madv360.madv.model.MVCameraDevice;
import com.madv360.madv.utils.MediaScannerUtil;
import com.madv360.madv.utils.PathTreeIterator;

import org.jcodec.codecs.h264.H264Decoder;
import org.jcodec.codecs.h264.io.model.Frame;
import org.jcodec.common.model.ColorSpace;
import org.jcodec.common.model.Picture;

import java.io.File;
import java.io.FileInputStream;
import java.lang.ref.WeakReference;
import java.nio.ByteBuffer;
import java.nio.IntBuffer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.LinkedBlockingDeque;

import bootstrap.appContainer.AppStorageManager;
import bootstrap.appContainer.ElephantApp;
import foundation.activeandroid.query.Select;
import foundation.helper.FilesUtils;
import foundation.helper.ImageUtil;
import module.imagepicker.utils.MVBitmapCache;
import uikit.component.Util;

/**
 * Created by qiudong on 16/6/27.
 */
public class MVMediaManagerImpl extends MVMediaManager
        implements PathTreeIterator.Delegate, MVCameraClient.StateListener {

    private static final String RenderThumbnailThreadIdentifier = "RenderThumb";

    private MVMediaManagerImpl() {
        MVCameraClient.getInstance().addStateListener(this);
    }

    @Override
    public void finalize() {
        MVCameraClient.getInstance().removeStateListener(this);
    }

    @Override
    public synchronized void addMediaDataSourceListener(MediaDataSourceListener listener) {
        dataSourceListeners.add(listener);
    }

    @Override
    public synchronized void removeMediaDataSourceListener(MediaDataSourceListener listener) {
        dataSourceListeners.remove(listener);
    }

    @Override
    public void addMediaDownloadStatusListener(MediaDownloadStatusListener listener) {
        downloadListeners.add(listener);
    }

    @Override
    public void removeMediaDownloadStatusListener(MediaDownloadStatusListener listener) {
        downloadListeners.remove(listener);
    }

    @Override
    public boolean isCameraMediaLibraryAvailable() {
        return MVCameraClient.getInstance().connectingCamera() != null;
    }

    private String mCurrentUsbSerialNumber;
    boolean isUDiskModeRefreshing = false;

    @Override
    public List<MVMedia> getCameraMediasOnUDiskMode(boolean forceRefresh) {
        String serialNumber = MVCameraClient.getInstance().connectingCameraOnUDiskSerialNumber();
        if (Util.isNotEmpty(serialNumber)) {
            if (serialNumber.equals(mCurrentUsbSerialNumber)
                    && !forceRefresh && cameraMedias.size() > 0
                    && !isUDiskModeRefreshing) {
                return cameraMedias;
            } else {
                if (serialNumber.equals(mCurrentUsbSerialNumber)) {
                    if (isUDiskModeRefreshing) {
                        return null;
                    }
                }
                mCurrentUsbSerialNumber = serialNumber;
                isUDiskModeRefreshing = true;
                BackgroundExecutor.execute(new BackgroundExecutor.Task("scanUDisk", 0L, "scanUDisk") {
                    @Override
                    public void execute() {
                        cameraMedias.clear();
                        LinkedList<MVMedia> list = new LinkedList<>();
                        String UDiskPath = MVMedia.udiskPathPrefix + MVMedia.albumRootPath;
                        File UDiskPathFile = new File(UDiskPath);
                        if (UDiskPathFile.exists()) {
                            File[] dirFiles = UDiskPathFile.listFiles();
                            for (File dirFile : dirFiles) {
                                if (dirFile.isDirectory()) {
                                    File[] files = dirFile.listFiles();
                                    for (File file : files) {
                                        if (!file.isDirectory()) {
                                            String filePath = file.getAbsolutePath();
                                            if (!filePath.endsWith(MVMedia.ABFileType)) {
                                                String remoteFilePath = MVMedia.getRemotePathFromUDiskPath(filePath);
                                                MVMedia cameraMedia = obtainCameraMedia(mCurrentUsbSerialNumber, remoteFilePath, true);
                                                list.add(cameraMedia);
                                            }
                                        }
                                    }
                                }
                            }

                            synchronized (MVMediaManagerImpl.this) {
                                if (isUDiskModeRefreshing) {
                                    cameraMedias.addAll(list);
                                    list.clear();
                                    sortByCreateDate(cameraMedias);
                                }
                            }
                        }
                        isUDiskModeRefreshing = false;
                        sendCallbackMessage(MsgDataSourceCameraUpdated, 0, 0, cameraMedias);
                    }
                });
                return null;
            }
        }
        return null;
    }

    @Override
    public void cameraDisconnectFromUDiskMode() {
        synchronized (MVMediaManagerImpl.this) {
            cameraMedias.clear();
            isUDiskModeRefreshing = false;
            sendCallbackMessage(MsgDataSourceCameraUpdated, 0, 0, cameraMedias);
        }
    }

    boolean isRefreshing = false;

    @Override
    public synchronized void addNewCameraMedia(MVMedia media) {
        if (!cameraMedias.contains(media)) {
            cameraMedias.add(0, media);
            sendCallbackMessage(MsgDataSourceCameraUpdated, 0, 0, cameraMedias);
        }
    }

    @Override
    public MVMedia obtainCameraMedia(String cameraUUID, String remotePath, boolean willRefreshCameraMediasSoon) {
        Log.e("Feng", "obtainCameraMedia");
        MVMedia media;
        List<MVMedia> medias = MVMedia.querySavedMedias(cameraUUID, remotePath, null);
        if (null == medias || medias.size() == 0) {
            media = MVMedia.create(cameraUUID, remotePath);
            media.save();

            if (!willRefreshCameraMediasSoon) {
                addNewCameraMedia(media);
            }
        } else {
            media = medias.get(0);
            if (!TextUtils.isEmpty(media.getLocalPath())
                    && (media.getDownloadedSize() < media.getSize() || 0 == media.getSize())) {
                media.setDownloadStatus(MVMedia.DownloadStatusStopped);
            } else {
                media.setDownloadStatus(MVMedia.DownloadStatusNone);
            }

            if (!willRefreshCameraMediasSoon) {
                updateCameraMedia(media);
            }
        }

        return media;
    }

    @Override
    public List<MVMedia> getCameraMedias(boolean forceUpdate) {
        Log.d(Const.CallbackLogTag, "getCameraMedias @ MVMediaManagerImpl");
        if (null == MVCameraClient.getInstance().connectingCamera()) {
            return null;
        } else if (justConnected) {
            cameraMediasInvalid = true;
            justConnected = false;
        }

        synchronized (this) {
            Log.d(TAG, "getCameraMedias : cameraMediasInvalid = " + cameraMediasInvalid + ", forceUpdate = " + forceUpdate);
            if (!cameraMediasInvalid && !forceUpdate && cameraMedias.size() > 0) {
                return cameraMedias;
            } else {
                Log.d(TAG, "getCameraMedias : isRefreshing = " + isRefreshing);
                if (isRefreshing) {
                    return null;
                }
                isRefreshing = true;

                BackgroundExecutor.execute(new BackgroundExecutor.Task("", 0L, "") {
                    @Override
                    public void execute() {
                        final LinkedList<MVMedia> list = new LinkedList<>();
                        PathTreeIterator iter = PathTreeIterator.beginFileTraverse("/tmp/SD0/DCIM/", MVMediaManagerImpl.this);
                        PathTreeIterator.Callback callback = new PathTreeIterator.Callback() {
                            @Override
                            public boolean onGotNextFile(String fullPath, boolean isDirectory, boolean notReachEnd) {
                                Log.d(TAG, "getCameraMediasAsync : onGotNextFile('" + fullPath + "', " + isDirectory + ", " + notReachEnd);
                                if (isDirectory)
                                    return false;

                                if (fullPath != null) {
                                    MVCameraDevice currentDevice = MVCameraClient.getInstance().connectingCamera();
                                    MVMedia cameraMedia = obtainCameraMedia(currentDevice.getUUID(), fullPath, true);
                                    list.add(cameraMedia);
                                }

                                if (!notReachEnd) {
                                    synchronized (MVMediaManagerImpl.this) {
                                        cameraMedias.clear();
                                        cameraMedias.addAll(list);
                                        list.clear();
                                        sortByCreateDate(cameraMedias);
                                        cameraMediasInvalid = false;

                                        isRefreshing = false;
                                    }
                                    sendCallbackMessage(MsgDataSourceCameraUpdated, 0, 0, cameraMedias);
                                }
                                return false;
                            }
                        };

                        while (iter.hasNext()) {
                            iter.next(callback);
                        }
                    }
                });
                return null;
            }
        }
    }


    /**
     * 按创建时间降序
     *
     * @param medias
     * @return
     */
    private ArrayList<MVMedia> sortByCreateDate(ArrayList<MVMedia> medias) {
        Collections.sort(medias, new Comparator<MVMedia>() {
            @Override
            public int compare(MVMedia lhs, MVMedia rhs) {
                long start1 = 0;
                long start2 = 0;
                start1 = lhs.getCreateDate().getTime();
                start2 = rhs.getCreateDate().getTime();
                if (start1 - start2 > 0) {
                    return -1;
                } else {
                    return 1;
                }
            }
        });
        return medias;
    }

    /**
     * 按修改时间降序
     *
     * @param medias
     * @return
     */
    private ArrayList<MVMedia> sortByModifyDate(ArrayList<MVMedia> medias) {
        Collections.sort(medias, new Comparator<MVMedia>() {
            @Override
            public int compare(MVMedia lhs, MVMedia rhs) {
                long start1 = 0;
                long start2 = 0;
                start1 = lhs.getModifyDate().getTime();
                start2 = rhs.getModifyDate().getTime();
                if (start1 - start2 > 0) {
                    return -1;
                } else {
                    return 1;
                }
            }
        });
        return medias;
    }

    @Override
    public void invalidateCameraMedias(boolean refresh) {
        synchronized (this) {
            cameraMediasInvalid = true;
        }
        if (refresh) {
            getCameraMedias();
        }
    }

    @Override
    public List<MVMedia> getLocalMedias(boolean forceUpdate) {
        synchronized (this) {
            if (!localMediasInvalid && !forceUpdate) {
                Log.d(TAG, "localMedias Return:" + localMedias);
                return localMedias;
            } else {
                BackgroundExecutor.execute(new BackgroundExecutor.Task("", 0L, "") {
                    @Override
                    public void execute() {
                        List<MVMedia> list = MVMedia.queryDownloadedMedias();
                        if (Util.isNotEmpty(list)){
                            Iterator<MVMedia> iterator = list.iterator();
                            while (iterator.hasNext()){
                                MVMedia media = iterator.next();
                                if (media == null || Util.isNotValidFile(media.getLocalPath())){
                                    iterator.remove();
                                }
                            }
                        }
                        synchronized (MVMediaManagerImpl.this) {
                            localMedias = (ArrayList<MVMedia>) list;
                            sortByModifyDate(localMedias);
                            localMediasInvalid = false;
                        }
                        sendCallbackMessage(MsgDataSourceLocalUpdated, 0, 0, localMedias);
                    }
                });
                return null;
            }
        }
    }

    public void invalidateLocalMedias(boolean refresh) {
        synchronized (this) {
            localMediasInvalid = true;
        }
        if (refresh) {
            getLocalMedias();
        }
    }

    private Set<String> mRenderingThumbnailSet = Collections.synchronizedSet(new HashSet<String>());
    public String getThumbnailLocalPathAsync(MVMedia media) {
        Log.v(TAG, "local getThumbnailLocalPathAsync : " + media);
        try {
            final MVMedia blkMedia = media;

            List<MVMedia> savedMedias = MVMedia.querySavedMedias(media.getCameraUUID(), media.getRemotePath(), media.getLocalPath());
            if (null != savedMedias && 0 < savedMedias.size()) {
                MVMedia savedMedia = savedMedias.get(savedMedias.size() - 1);
                String thumbnailPath = savedMedia.getThumbnailImagePath();
                if (!TextUtils.isEmpty(thumbnailPath)) {
                    if ((new File(thumbnailPath)).exists()) {
                        return thumbnailPath;
                    } else {
                        final String localPath = savedMedia.getLocalPath();
                        if (!TextUtils.isEmpty(localPath) && savedMedia.getDownloadedSize() >= savedMedia.getSize() && savedMedia.getSize() > 0) {
                            Log.e("Feng", String.format("thumbnailPath not exist, will generate, localPath =-> %s", localPath));
                            if (!mRenderingThumbnailSet.contains(localPath)){
                                mRenderingThumbnailSet.add(localPath);
                                final MVMedia blkSavedMedia = savedMedia;
                                BackgroundExecutor.execute(new BackgroundExecutor.Task("", 0L, RenderThumbnailThreadIdentifier) {
                                    @Override
                                    public void execute() {
                                        Bitmap originalBitmap = null;
                                        if (blkSavedMedia.getMediaType() == MVMedia.MediaTypeVideo) {
                                            originalBitmap = getVideoThumbnail(localPath);
                                        } else {
//                                        originalBitmap = ImageUtil.getBitmapWithMinWidthAndHeight(localPath, ThumbnailWidth, ThumbnailHeight);
                                            originalBitmap = ImageUtil.getBitmapWithMinWidthAndHeight(localPath, 360, 360);
                                        }

                                        if (null != originalBitmap) {
//                                        Bitmap thumbnailBitmap = renderBitmap(originalBitmap, ThumbnailWidth, ThumbnailHeight, false, localPath, 0);
                                            Bitmap thumbnailBitmap = renderBitmap(originalBitmap, originalBitmap.getWidth(), originalBitmap.getHeight(), false, localPath, 0);
                                            saveMediaThumbnail(blkSavedMedia, thumbnailBitmap);
                                            Util.recycle(originalBitmap, thumbnailBitmap);
                                        }

                                        updateLocalMedia(blkSavedMedia);
                                        mRenderingThumbnailSet.remove(localPath);
                                        Log.e("Feng", String.format("render finish, path =-> %s", localPath));
                                    }
                                });
                            }

                        }
                    }
                }
            }
            MVCameraDevice connectingDevice = MVCameraClient.getInstance().connectingCamera();
            if (connectingDevice == null || !connectingDevice.getUUID().equals(media.getCameraUUID())) {
                Log.v(TAG, "local getThumbnailLocalPathAsync : return #1. media = " + media);
                return null;
            }

            final String remotePath = media.getRemotePath();
            if (mGetMediaInfoList.contains(remotePath)){        //是否正在获取info

            }else{      //如果没有
                if (MVCameraDownloadManager.getInstance().contains(remotePath)){            //是否正在下载

                }else{      //如果没有在下载
                    if (isDecoding(blkMedia)){          //是否正在解码

                    }else{
                        if (media.getSize() > 0) {
                            downloadMedia(blkMedia);
                        }else {
                            mGetMediaInfoList.add(remotePath);      //没在在获取info没有下载没有解码，则去
                            AMBARequest.ResponseListener getMediaInfoListener = new AMBARequest.ResponseListener() {
                                @Override
                                public void onResponseReceived(AMBAResponse response) {
                                    Log.e("Feng", "getMediaInfoAsync finish =-> " + response.isRvalOK());
                                    if (response.isRvalOK()) {
                                        AMBAGetMediaInfoResponse getMediaInfoResponse = (AMBAGetMediaInfoResponse) response;
                                        if (getMediaInfoResponse.duration > 0)
                                            blkMedia.setVideoDuration(getMediaInfoResponse.duration);
                                        if (getMediaInfoResponse.getSize() > 0)
                                            blkMedia.setSize(getMediaInfoResponse.getSize());
                                        blkMedia.saveCommonFields();
                                        updateCameraMedia(blkMedia);
                                        sendCallbackMessage(MsgMediaInfoFetched, 0, 0, blkMedia);
                                        downloadMedia(blkMedia);
                                    }
                                    mGetMediaInfoList.remove(remotePath);
                                }

                                @Override
                                public void onResponseError(AMBARequest request, int error, String msg) {
                                    mGetMediaInfoList.remove(remotePath);
                                }
                            };
                            AMBARequest getMediaInfoRequest = new AMBARequest(getMediaInfoListener, AMBAGetMediaInfoResponse.class);
                            getMediaInfoRequest.setMsg_id(AMBACommands.AMBA_MSGID_GET_MEDIA_INFO);
                            getMediaInfoRequest.setToken(MVCameraClient.getInstance().getToken());
                            getMediaInfoRequest.setParam(remotePath);
                            CMDConnectManager.getInstance().sendRequest(getMediaInfoRequest);
                        }

                    }
                }
            }
            Log.v(TAG, "local getThumbnailLocalPathAsync : return #END. media = " + media);
            return null;
        } finally {
//            if (media.getMediaType() == MVMedia.MediaTypePhoto)
//            {
//                MVMedia downloaded = MVMedia.obtainDownloadedMedia(media);
////            Log.e(TAG, "DownloadImage : downloaded = " + downloaded + ", this = " + media);
//                if (null == downloaded)
//                {
//                    addDownloading(media);
//                }
//            }
        }
    }

    private boolean isDecoding(MVMedia media){
        synchronized (decodeTasks) {
            for (Iterator<ThumbnailDecodeTask> iter = decodeTasks.iterator(); iter.hasNext(); ) {
                ThumbnailDecodeTask decodeTask = iter.next();
                if (decodeTask.media.isEqualRemoteMedia(media)) {
                    Log.v(TAG, "local getThumbnailLocalPathAsync : return #2. media = " + media);
                    return true;
                }
            }
        }
        return false;
    }

    private void downloadMedia(final MVMedia media){
        ThumbnailDownloadTask.Callback callback = new ThumbnailDownloadTask.Callback() {
            @Override
            public void onCompleted(byte[] data, int bytesReceived) {
                final byte[] blkData = new byte[bytesReceived];
                System.arraycopy(data, 0, blkData, 0, bytesReceived);
                Log.e(TAG, "ThumbnailDownloadTask onCompleted. media = " + media);
                Log.e("Feng", String.format("ThumbnailDownloadTask finish data length =-> %s, blkData length =-> %s", data.length, blkData.length));

                ThumbnailDecodeTask decodeTask = new ThumbnailDecodeTask(media, blkData);
                addThumbnailDecodeTask(decodeTask);
            }

            @Override
            public void onError(String errMsg) {
                Log.e("Feng", String.format("ThumbnailDownloadTask finish =-》 %s", errMsg));
            }
        };
        String remotePath = media.getRemotePath();
        boolean isVideo = media.getMediaType() == MVMedia.MediaTypeVideo;
        ThumbnailDownloadTask task = new ThumbnailDownloadTask(MVCameraDownloadManager.TASK_PRIORITY_HIGH, remotePath, isVideo, callback);
        MVCameraDownloadManager.getInstance().addTask(task, false);
    }

    @Override
    public Bitmap getThumbnailImageAsync(MVMedia media) {
        Log.d(Const.CallbackLogTag, "getThumbnailImageAsync @ MVMediaManagerImpl : media = " + media);
        try {
            final MVMedia blkMedia = media;
            getMediaInfoAsync(media);
            String key = media.storageKey() + ".jpg";
            Bitmap bitmap = MVBitmapCache.sharedInstance().loadThumbnail(key);

            if (null != bitmap) {
                Log.v(TAG, "local getThumbnailImageAsync : return #0. media = " + media);
                return bitmap;
            }

            MVCameraDevice connectingDevice = MVCameraClient.getInstance().connectingCamera();
            if (connectingDevice == null || !connectingDevice.getUUID().equals(media.getCameraUUID())) {
                Log.v(TAG, "local getThumbnailImageAsync : return #1. media = " + media);
                return null;
            }

            synchronized (decodeTasks) {
                for (Iterator<ThumbnailDecodeTask> iter = decodeTasks.iterator(); iter.hasNext(); ) {
                    ThumbnailDecodeTask decodeTask = iter.next();
                    if (decodeTask.media.isEqualRemoteMedia(media)) {
                        Log.v(TAG, "local getThumbnailImageAsync : return #2. media = " + media);
                        return null;
                    }
                }
            }

            ThumbnailDownloadTask.Callback callback = new ThumbnailDownloadTask.Callback() {
                @Override
                public void onCompleted(byte[] data, int bytesReceived) {
                    final byte[] blkData = new byte[bytesReceived];
                    System.arraycopy(data, 0, blkData, 0, bytesReceived);
                    Log.e(TAG, "ThumbnailDownloadTask onCompleted");

                    ThumbnailDecodeTask decodeTask = new ThumbnailDecodeTask(blkMedia, blkData);
                    addThumbnailDecodeTask(decodeTask);
                }

                @Override
                public void onError(String errMsg) {
                }
            };
            ThumbnailDownloadTask task = new ThumbnailDownloadTask(MVCameraDownloadManager.TASK_PRIORITY_HIGH, media.getRemotePath(), media.getMediaType() == MVMedia.MediaTypeVideo, callback);
//            MVCameraDownloadManager.getInstance().addTask(task, true);
            MVCameraDownloadManager.getInstance().addTask(task, false);
            //*/
            Log.v(TAG, "local getThumbnailImageAsync : return #END1. media = " + media);
            return null;
        } finally {
//            if (media.getMediaType() == MVMedia.MediaTypePhoto && null == MVMedia.obtainDownloadedMedia(media))
//            {
//                addDownloading(media);
//            }
        }
    }

    void addThumbnailDecodeTask(final ThumbnailDecodeTask task) {
        synchronized (decodeTasks) {
            decodeTasks.add(task);
            final ThumbnailDecodeTask blkTask = task;
            BackgroundExecutor.execute(new BackgroundExecutor.Task("", 0L, RenderThumbnailThreadIdentifier) {
                @Override
                public void execute() {
                    try {
                        Bitmap originalBitmap, thumbnailBitmap;
                        if (blkTask.media.getMediaType() == MVMedia.MediaTypeVideo) {
                            Picture pic = getThumbPictureFromOneFrame(blkTask.data);
                            thumbnailBitmap = renderYUVPicture(pic, ThumbnailWidth, ThumbnailHeight
                                    , (blkTask.media.getMediaType() == MVMedia.MediaTypeVideo || Const.STITCH_PICTURE)
                                    , null, blkTask.media.getFilterID());
                        } else {
                            originalBitmap = BitmapFactory.decodeByteArray(blkTask.data, 0, blkTask.data.length);
//                            originalBitmap = BitmapFactory.decodeStream(ElephantApp.getInstance().openFileInput(tempPath));
                            thumbnailBitmap = renderBitmap(originalBitmap, ThumbnailWidth, ThumbnailHeight
                                    , (blkTask.media.getMediaType() == MVMedia.MediaTypeVideo || Const.STITCH_PICTURE)
                                    , null, blkTask.media.getFilterID());
                            originalBitmap.recycle();
                            Log.e("QD", "MVMediaManagerImpl :: addThumbnailDecodeTask : originalBitmap recycled " + originalBitmap);
                        }
                        Log.e("Feng", "decode finish");

//                        ElephantApp.getInstance().deleteFile(tempPath);

                        saveMediaThumbnail(blkTask.media, thumbnailBitmap);
                        sendCallbackMessage(MsgThumbnailFetched, 0, 0, blkTask.media);
                    } catch (Exception ex) {
                        ex.printStackTrace();
                    }

                    synchronized (MVMediaManagerImpl.this.decodeTasks) {
                        boolean removed = decodeTasks.remove(blkTask);
                        Log.v(TAG, "decodeTasks.remove(task) = " + removed + ". media = " + blkTask.media);
                    }
                }
            });
        }
    }

    static class ThumbnailDecodeTask {
        public ThumbnailDecodeTask(MVMedia media, byte[] data) {
            this.media = media;
            this.data = data;
        }

        @Override
        public boolean equals(Object o) {
            if (!(o instanceof ThumbnailDecodeTask))
                return false;

            ThumbnailDecodeTask other = (ThumbnailDecodeTask) o;
            if (!TextUtils.isEmpty(media.getRemotePath())) {
                return this.media.isEqualRemoteMedia(other.media);
            } else {
                return TextUtils.equals(media.getLocalPath(), other.media.getLocalPath());
            }
        }

        MVMedia media;
        byte[] data;
    }

    public static Bitmap renderYUVPicture(Picture yuvPic, int dstWidth, int dstHeight, boolean withLUT, String sourceURI, int filterID) {
        try {
            // Render Thumbnail:
            EglCore eglCore = new EglCore(EGL14.eglGetCurrentContext(), EglCore.FLAG_RECORDABLE | EglCore.FLAG_TRY_GLES3);
            EGLSurface eglSurface = eglCore.createOffscreenSurface(dstWidth, dstHeight);
            eglCore.makeCurrent(eglSurface);

            String lutPath = MadvTextureRenderer.lutPathOfSourceURI(sourceURI, withLUT, ElephantApp.getInstance());
            if (withLUT && TextUtils.isEmpty(lutPath)) {
                lutPath = MadvTextureRenderer.lutPathOfSourceURI(AMBACommands.AMBA_CAMERA_RTSP_URL_ROOT, withLUT, ElephantApp.getInstance());
            }
            MadvGLRenderer glRenderer = new MadvGLRenderer(lutPath, new Vec2f(3456, 1728), new Vec2f(3456, 1728));
//            glRenderer.initGL(dstWidth, dstHeight);

            int srcWidth = yuvPic.getWidth(), srcHeight = yuvPic.getHeight();

            Log.e(TAG, "srcWidth = " + srcWidth + ", srcHeight = " + srcHeight);
            IntBuffer bufferY = IntBuffer.wrap(yuvPic.getData()[0]);
            int textureY = GlUtil.createImageTexture(bufferY, srcWidth, srcHeight, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE);
            IntBuffer bufferU = IntBuffer.wrap(yuvPic.getData()[1]);
            int textureU = GlUtil.createImageTexture(bufferU, srcWidth / 2, srcHeight / 2, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE);
            IntBuffer bufferV = IntBuffer.wrap(yuvPic.getData()[2]);
            int textureV = GlUtil.createImageTexture(bufferV, srcWidth / 2, srcHeight / 2, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE);
            int[] yuvTextures = new int[]{textureY, textureU, textureV};
            Log.e(TAG, "textureY = " + textureY + "textureU = " + textureU + "textureV = " + textureV);

            GLRenderTexture renderTexture = null;
            GLFilterCache filterCache = null;
            if (filterID > 0) {
                filterCache = new GLFilterCache();
                renderTexture = new GLRenderTexture(dstWidth, dstHeight);
                renderTexture.blit();
            }

            GLES20.glViewport(0, 0, dstWidth, dstHeight);
            GLES20.glClearColor(1.0f, 1.0f, 0.0f, 1.0f);
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);

            glRenderer.setFlipY(true);
            glRenderer.setIsYUVColorSpace(true);
            glRenderer.setDisplayMode(withLUT ? MadvGLRenderer.PanoramaDisplayModeLUT : 0);
            glRenderer.setSourceYUVTextures(false, yuvTextures, yuvTextures, new Vec2f(srcWidth, srcHeight), new Vec2f(srcWidth, srcHeight), GLES20.GL_TEXTURE_2D, true);
            glRenderer.draw(0, 0, dstWidth, dstHeight);

            if (filterID > 0) {
                renderTexture.unblit();
                filterCache.render(filterID, 0, 0, dstWidth, dstHeight, renderTexture.getTexture(), GLES20.GL_TEXTURE_2D);
            }

            int[] rgbData = new int[dstWidth * dstHeight];
            IntBuffer rgbBuffer = IntBuffer.wrap(rgbData);
            GLES20.glReadPixels(0, 0, dstWidth, dstHeight, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, rgbBuffer);

            GLES20.glDeleteTextures(3, yuvTextures, 0);
            if (filterID > 0) {
                renderTexture.releaseGLObjects();
                filterCache.releaseGLObjects();
            }

            //        glRenderer.releaseGL();
            eglCore.makeNothingCurrent();
            eglCore.releaseSurface(eglSurface);
            eglCore.release();

            Bitmap thumbnailBitmap = Bitmap.createBitmap(rgbData, dstWidth, dstHeight, Bitmap.Config.ARGB_8888);//pix是上面读到的像素
            thumbnailBitmap.copyPixelsFromBuffer(rgbBuffer);
            return thumbnailBitmap;
        } catch (Exception ex) {
            ex.printStackTrace();
            return null;
        }
    }

    public static Bitmap renderBitmap(Bitmap originalBitmap, int dstWidth, int dstHeight, boolean withLUT, String sourceURI, int filterID) {
        // Render Thumbnail:
        EglCore eglCore = new EglCore(EGL14.eglGetCurrentContext(), EglCore.FLAG_RECORDABLE | EglCore.FLAG_TRY_GLES3);
        EGLSurface eglSurface = eglCore.createOffscreenSurface(dstWidth, dstHeight);
        eglCore.makeCurrent(eglSurface);

        String lutPath = MadvTextureRenderer.lutPathOfSourceURI(sourceURI, withLUT, ElephantApp.getInstance());
        withLUT = (withLUT || !TextUtils.isEmpty(lutPath));
        if (withLUT && TextUtils.isEmpty(lutPath)) {
            lutPath = MadvTextureRenderer.lutPathOfSourceURI(AMBACommands.AMBA_CAMERA_RTSP_URL_ROOT, withLUT, ElephantApp.getInstance());
        }
        MadvGLRenderer glRenderer = new MadvGLRenderer(lutPath, new Vec2f(3456, 1728), new Vec2f(3456, 1728));
//        glRenderer.initGL(dstWidth, dstHeight);

        int srcWidth = originalBitmap.getWidth(), srcHeight = originalBitmap.getHeight();
        int sourceTexture = GlUtil.createBitmapTexture(originalBitmap);

        GLRenderTexture renderTexture = null;
        GLFilterCache filterCache = null;
        if (filterID > 0) {
            filterCache = new GLFilterCache();
            renderTexture = new GLRenderTexture(dstWidth, dstHeight);
            renderTexture.blit();
        }

        GLES20.glViewport(0, 0, dstWidth, dstHeight);
        GLES20.glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);

        glRenderer.setIsYUVColorSpace(false);
        glRenderer.setFlipY(true);
        glRenderer.setDisplayMode(withLUT ? MadvGLRenderer.PanoramaDisplayModeLUT : 0);
        glRenderer.setSourceTextures(/*false, */sourceTexture, sourceTexture, new Vec2f(srcWidth, srcHeight), new Vec2f(srcWidth, srcHeight), GLES20.GL_TEXTURE_2D, false);
        glRenderer.draw(0, 0, dstWidth, dstHeight);

        if (filterID > 0) {
            renderTexture.unblit();
            filterCache.render(filterID, 0, 0, dstWidth, dstHeight, renderTexture.getTexture(), GLES20.GL_TEXTURE_2D);
        }

        int[] rgbData = new int[dstWidth * dstHeight];
        IntBuffer rgbBuffer = IntBuffer.wrap(rgbData);
        GLES20.glReadPixels(0, 0, dstWidth, dstHeight, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, rgbBuffer);

        GLES20.glDeleteTextures(1, new int[]{sourceTexture}, 0);
        if (filterID > 0) {
            renderTexture.releaseGLObjects();
            filterCache.releaseGLObjects();
        }
        glRenderer.releaseNativeGLRenderer();

        eglCore.makeNothingCurrent();
        eglCore.releaseSurface(eglSurface);
        eglCore.release();

        Bitmap thumbnailBitmap = Bitmap.createBitmap(rgbData, dstWidth, dstHeight, Bitmap.Config.ARGB_8888);//pix是上面读到的像素
        thumbnailBitmap.copyPixelsFromBuffer(rgbBuffer);

        return thumbnailBitmap;
    }

    void saveMediaThumbnail(MVMedia media, Bitmap thumbnailBitmap) {
        String key = media.storageKey() + ".jpg";
        String thumbnailPath = MVBitmapCache.sharedInstance().getThumbnailLocalPath(key);

        ImagePipeline imagePipeline = Fresco.getImagePipeline();
        imagePipeline.evictFromCache(Uri.parse(thumbnailPath));
        imagePipeline.evictFromDiskCache(Uri.parse(thumbnailPath));

        MVBitmapCache.sharedInstance().putThumbnailToDisk(key, thumbnailBitmap);

        media.setThumbnailImagePath(thumbnailPath);
        Log.v(TAG, "MVMedia.save() @ saveMediaThumbnail#0 : key = " + key + ", media = " + media);
        media.saveCommonFields();
        updateCameraMedia(media);
        invalidateLocalMedias(false);
    }

    private final LinkedBlockingDeque<ThumbnailDecodeTask> decodeTasks = new LinkedBlockingDeque<>();

    public static Picture getThumbPictureFromOneFrame(byte[] frame) {
        int nH264FrameLength = frame.length - 22;//H264_FRAME_DATA_OFFSET_AMBA;
        byte[] data = new byte[nH264FrameLength];

        for (int bb = 0; bb < nH264FrameLength; ++bb) {
            data[bb] = frame[bb + 22/*H264_FRAME_DATA_OFFSET_AMBA*/];
        }

        Log.v(TAG, "start decode one frame");
        ByteBuffer var16 = ByteBuffer.wrap(data);
        H264Decoder decoder = new H264Decoder();
        Picture out = Picture.create(1440, 720, ColorSpace.YUV420);
        Frame real = decoder.decodeFrame(var16, out.getData());
        Log.v(TAG, "end decode one frame");
        return real;
    }

    @Override
    public void importMedias(List<String> paths, boolean isVideo) {
        final List<String> blkPaths = paths;
        final boolean blkIsVideo = isVideo;
        BackgroundExecutor.execute(new BackgroundExecutor.Task("", 0L, RenderThumbnailThreadIdentifier) {
            @Override
            public void execute() {
                for (String path : blkPaths) {
                    importMedia(path, blkIsVideo, false);
                }
                invalidateLocalMedias(true);
            }
        });
    }

    public void importMedia(final String path, boolean isVideo, boolean invalidate) {
        int type = isVideo ? MVMedia.MediaTypeVideo : MVMedia.MediaTypePhoto;
        MVMedia media = MVMedia.create();
        media.setMediaType(type);
        media.setLocalPath(path);
        media.setSize(1);
        media.setDownloadedSize(1);
        media.setDownloadStatus(MVMedia.DownloadStatusFinished);
        Date createDate = MVMedia.dateFromFileName(path.toLowerCase());
        media.setCreateDate(null != createDate ? createDate : new Date());
        media.setModifyDate(media.getCreateDate());
        media.save();

        Bitmap originalBitmap;
        if (isVideo) {
            MetaDataParser parser = MetaDataParserFactory.create(path);
            MetaData metaData = parser.getMetaData();
            int duration = 0;
            if (metaData.containsKey(MetaData.KEY_DURATION)) {
                duration = (int) metaData.getLong(MetaData.KEY_DURATION) / 1000;
            }
            media.setVideoDuration(duration);
            originalBitmap = getVideoThumbnail(path);
        } else {
//            originalBitmap = ImageUtil.getBitmapWithMinWidthAndHeight(path, ThumbnailWidth, ThumbnailHeight);
            originalBitmap = ImageUtil.getBitmapWithMinWidthAndHeight(path, 360, 360);
        }

        if (null != originalBitmap) {
//            Bitmap thumbnailBitmap = renderBitmap(originalBitmap, ThumbnailWidth, ThumbnailHeight, false, path, 0);
            Bitmap thumbnailBitmap = renderBitmap(originalBitmap, originalBitmap.getWidth(), originalBitmap.getHeight(), false, path, 0);
            saveMediaThumbnail(media, thumbnailBitmap);
            if (originalBitmap != thumbnailBitmap) {
                originalBitmap.recycle();
                Log.e("QD", "MVMediaManagerImpl :: importMedia : originalBitmap recycled " + originalBitmap);
            }
        }

        if (invalidate) invalidateLocalMedias(true);
    }

    private List<String> mGetMediaInfoList = Collections.synchronizedList(new ArrayList<String>(3));



    @Override
    public boolean getMediaInfoAsync(MVMedia media) {
        if (media == null) return false;
        if (media.getSize() > 0) return true;
        final String remotePath = media.getRemotePath();
        if (Util.isEmpty(remotePath)) return false;
//        if (mGetMediaInfoList.contains(remotePath)) return false;           //快速滑动的时候，这个方法会多次调用，造成通信频繁，因此需要这个list
//        mGetMediaInfoList.add(remotePath);


        final MVMedia blkMedia = media;
        AMBARequest.ResponseListener getMediaInfoListener = new AMBARequest.ResponseListener() {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                Log.e("Feng", "getMediaInfoAsync finish (getMediaInfoAsync) =-> " + response.isRvalOK());
                if (response.isRvalOK()) {
                    AMBAGetMediaInfoResponse getMediaInfoResponse = (AMBAGetMediaInfoResponse) response;
                    if (getMediaInfoResponse.duration > 0)
                        blkMedia.setVideoDuration(getMediaInfoResponse.duration);
                    if (getMediaInfoResponse.getSize() > 0)
                        blkMedia.setSize(getMediaInfoResponse.getSize());
                    blkMedia.saveCommonFields();
                    Log.v(TAG, "MVMedia.save() @ getMediaInfoAsync#0 : " + blkMedia);
                    updateCameraMedia(blkMedia);
                    invalidateLocalMedias(false);
                    sendCallbackMessage(MsgMediaInfoFetched, 0, 0, blkMedia);
//                    mGetMediaInfoList.remove(remotePath);
                }
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
//                mGetMediaInfoList.remove(remotePath);
            }
        };
        AMBARequest getMediaInfoRequest = new AMBARequest(getMediaInfoListener, AMBAGetMediaInfoResponse.class);
        getMediaInfoRequest.setMsg_id(AMBACommands.AMBA_MSGID_GET_MEDIA_INFO);
        getMediaInfoRequest.setToken(MVCameraClient.getInstance().getToken());
        getMediaInfoRequest.setParam(remotePath);
        CMDConnectManager.getInstance().sendRequest(getMediaInfoRequest);
        return false;
    }


    @Override
    public void deleteCameraMedias(List<MVMedia> medias) {
        for (MVMedia media : medias) {
            List<MVMedia> savedMedias = MVMedia.querySavedMedias(media.getCameraUUID(), media.getRemotePath(), media.getLocalPath());
            if (null != savedMedias) {

                for (MVMedia savedMedia : savedMedias) {
                    if (savedMedia.getDownloadedSize() < savedMedia.getSize() || savedMedia.getSize() == 0) {
                        if (!TextUtils.isEmpty(savedMedia.getLocalPath())) {
                            File localFile = new File(savedMedia.getLocalPath());
                            localFile.delete();
                        }

                        savedMedia.delete();
                    }
                }
            }

            AMBARequest delFileRequest = new AMBARequest(null);
            delFileRequest.setMsg_id(AMBACommands.AMBA_MSGID_DELETE_FILE);
            delFileRequest.setToken(MVCameraClient.getInstance().getToken());
            delFileRequest.setParam(media.getRemotePath());
            CMDConnectManager.getInstance().sendRequest(delFileRequest);

            if (media.getRemotePath().endsWith(MVMedia.AAFileType)) {
                String abFilePath = media.getRemotePath().substring(0, media.getRemotePath().length() - MVMedia.AAFileType.length()) + MVMedia.ABFileType;
                delFileRequest = new AMBARequest(null);
                delFileRequest.setMsg_id(AMBACommands.AMBA_MSGID_DELETE_FILE);
                delFileRequest.setToken(MVCameraClient.getInstance().getToken());
                delFileRequest.setParam(abFilePath);
                CMDConnectManager.getInstance().sendRequest(delFileRequest);

//                String gyroFilePath = media.getRemotePath().substring(0, media.getRemotePath().length() - ".MP4".length()) + ".gyro";
//                delFileRequest = new AMBARequest(null);
//                delFileRequest.setMsg_id(AMBACommands.AMBA_MSGID_DELETE_FILE);
//                delFileRequest.setToken(MVCameraClient.getInstance().getToken());
//                delFileRequest.setParam(gyroFilePath);
//                CMDConnectManager.getInstance().sendRequest(delFileRequest);
            }
            MediaScannerUtil.scanMVMedia(media);
        }

        synchronized (this) {
            for (MVMedia mediaToDelete : medias) {
                for (Iterator<MVMedia> iter = cameraMedias.iterator(); iter.hasNext(); ) {
                    MVMedia media = iter.next();
                    if (mediaToDelete.isEqualRemoteMedia(media))
                        iter.remove();
                }
            }
            cameraMediasInvalid = false;
        }

        MVCameraDevice camera = MVCameraClient.getInstance().connectingCamera();
        if (cameraMedias.size() > 0) {
            if (null != camera) {
                camera.recentMedia = cameraMedias.get(0);
            }
        } else {
            camera.recentMedia = null;
        }
        sendCallbackMessage(MsgDataSourceCameraUpdated, 0, 0, cameraMedias);

        MVCameraClient.getInstance().synchronizeCameraStorageAllState();
    }

    @Override
    public void deleteLocalMedias(List<MVMedia> medias) {
        List<MVMedia> cameraMediasToReplace = new ArrayList<>();

        for (MVMedia media : medias) {
            media = MVMedia.querySavedMedia(media.getCameraUUID(), media.getRemotePath(), media.getLocalPath());
            if (media != null) {
                File file = new File(media.getLocalPath());
                file.delete();
                if (media.getLocalPath().endsWith(MVMedia.AAFileType)) {
                    String abFilePath = media.getLocalPath().substring(0, media.getLocalPath().length() - MVMedia.AAFileType.length()) + MVMedia.ABFileType;
                    File abFile = new File(abFilePath);
                    abFile.delete();
                }

                media.delete();
                MediaScannerUtil.scanMVMedia(media);

                if (!TextUtils.isEmpty(media.getRemotePath())) {
                    // Reload camera media with the same (cameraUUID, remotePath) tuple:
                    List<MVMedia> savedMedias = MVMedia.querySavedMedias(media.getCameraUUID(), media.getRemotePath(), media.getLocalPath());
                    if (null == savedMedias || 0 == savedMedias.size()) {
                        MVMedia tmp = MVMedia.create(media.getCameraUUID(), media.getRemotePath());
                        tmp.copyCommonFields(media);
                        media = tmp;
                    } else {
                        media = savedMedias.get(savedMedias.size() - 1);
                    }
                    //删除之后要重新设置
                    media.setDownloadStatus(MVMedia.DownloadStatusNone);
                    cameraMediasToReplace.add(media);
                }
            }
        }
        invalidateLocalMedias(true);

        if (0 < cameraMediasToReplace.size()) {
            updateCameraMedias(cameraMediasToReplace);
        }
    }

    private void setMediaDownloadStatus(MVMedia media, int newStatus) {
        if (null == media) return;
        Log.v(TAG, "setMediaDownloadStatus:" + MVMedia.StringOfDownloadStatus(newStatus));
        synchronized (media) {
            if (media.getDownloadStatus() == newStatus)
                return;

            media.setDownloadStatus(newStatus);
            Log.v(TAG, "MVMedia.save() @ setMediaDownloadStatus#0 : " + media);
            sendCallbackMessage(MsgDownloadStatusChanged, newStatus, 0, media);
        }
    }

    private synchronized void updateCameraMedias(List<MVMedia> mediasToReplace) {
        Log.e("Feng", "updateCameraMedias");
        if (null != cameraMedias && null != mediasToReplace) {
            for (int i = 0; i < cameraMedias.size(); ++i) {
                MVMedia prevMedia = cameraMedias.get(i);
                for (MVMedia media : mediasToReplace) {
                    if (prevMedia.isEqualRemoteMedia(media)) {
                        cameraMedias.set(i, media);
                        break;
                    }
                }
            }
            sendCallbackMessage(MsgDataSourceCameraUpdated, 1, 0, mediasToReplace);
        }
    }

    private void updateCameraMedia(MVMedia mediaToReplace) {
        List<MVMedia> mediasToReplace = new ArrayList<>();
        mediasToReplace.add(mediaToReplace);
        updateCameraMedias(mediasToReplace);
    }

    private synchronized void updateLocalMedias(List<MVMedia> mediasToReplace) {
        sendCallbackMessage(MsgDataSourceLocalUpdated, 1, 0, mediasToReplace);
    }

    private void updateLocalMedia(MVMedia mediaToReplace) {
        List<MVMedia> mediasToReplace = new ArrayList<>();
        mediasToReplace.add(mediaToReplace);
        updateLocalMedias(mediasToReplace);
    }

    @Override
    public MVMedia addDownloading(MVMedia media) {
        Log.d(TAG, "addDownloading:" + media);
        return addDownloading(media, MVCameraDownloadManager.DownloadInitChunkSize, MVCameraDownloadManager.DownloadChunkSize, false);
    }

    public MVMedia addDownloading(MVMedia media, final int initChunkSize, final int normalChunkSize, boolean addAsFirst) {
        MVCameraDevice connectingDevice = MVCameraClient.getInstance().connectingCamera();
        if (connectingDevice == null || !connectingDevice.getUUID().equals(media.getCameraUUID())) {
            return null;
        }

        FileDownloadTask downloadTask;
        synchronized (this) {
            MVMedia cameraMediaToDownload = null;// An saved MVMedia instance that has not been completely downloaded(If any)
            for (MVMedia cameraMedia : cameraMedias) {
                if (cameraMedia.isEqualRemoteMedia(media)) {
                    cameraMediaToDownload = cameraMedia;
                    break;
                }
            }

            if (null == cameraMediaToDownload) {
                media.setLocalPath(MVMedia.uniqueLocalPath(media.getCameraUUID(), media.getRemotePath()));
                media.save();
                addNewCameraMedia(media);
            } else if (TextUtils.isEmpty(cameraMediaToDownload.getLocalPath())) {// Downloading not been started
                cameraMediaToDownload.setLocalPath(MVMedia.uniqueLocalPath(media.getCameraUUID(), media.getRemotePath()));
                cameraMediaToDownload.save();

                media = cameraMediaToDownload;
            } else if (cameraMediaToDownload.getDownloadedSize() >= cameraMediaToDownload.getSize() && 0 != cameraMediaToDownload.getSize()) {// Only completely downloaded medias. A new media instance should be cloned from it:
                cameraMediaToDownload = MVMedia.create(media.getCameraUUID(), media.getRemotePath());
                cameraMediaToDownload.copyCommonFields(media);
                cameraMediaToDownload.setLocalPath(MVMedia.uniqueLocalPath(media.getCameraUUID(), media.getRemotePath()));
                cameraMediaToDownload.save();

                updateCameraMedia(cameraMediaToDownload);
                media = cameraMediaToDownload;
            } else {// Not completely downloaded:
                media = cameraMediaToDownload;
            }

            long rangeStart, rangeLength;
            if (media.getSize() == 0) {
                rangeStart = 0;
                rangeLength = initChunkSize;
            } else {
                rangeStart = media.getDownloadedSize();
                rangeLength = media.getSize() - media.getDownloadedSize();
                if (rangeLength > normalChunkSize)
                    rangeLength = normalChunkSize;
                else if (rangeLength == 0)
                    return media;
            }

            downloadTask = new FileDownloadTask(MVCameraDownloadManager.TASK_PRIORITY_LOW, media.getRemotePath(), rangeStart, (int) rangeLength, media.getLocalPath(), null);
            if (downloadTasks.contains(downloadTask))
                return media;

            downloadTasks.add(downloadTask);
        }

        setMediaDownloadStatus(media, MVMedia.DownloadStatusPending);


        MediaDownloadCallback callback = new MediaDownloadCallback(media, downloadTask, initChunkSize, normalChunkSize);
        downloadTask.setCallback(callback);
        MVCameraDownloadManager.getInstance().addTask(downloadTask, addAsFirst);

        return media;
    }


    class MediaDownloadCallback implements FileDownloadTask.Callback {

        WeakReference<FileDownloadTask> taskWeakRef;
        MVMedia blkMedia;
        private int initChunkSize, normalChunkSize;

        public MediaDownloadCallback(MVMedia media, FileDownloadTask task, int init, int normal) {
            taskWeakRef = new WeakReference<FileDownloadTask>(task);
            this.initChunkSize = init;
            this.normalChunkSize = normal;
            this.blkMedia = media;
        }

        private void completeDownloading() {
            downloadTasks.remove(taskWeakRef.get());
            if (blkMedia.getSize() <= blkMedia.getDownloadedSize()) {
//                    Bitmap originalBitmap = null;
                if (blkMedia.getMediaType() == MVMedia.MediaTypePhoto) {
//                        originalBitmap = BitmapFactory.decodeFile(blkMedia.getLocalPath());
//                        Log.d(TAG, "ImageFilter : Downloading image done. filterID = " + blkMedia.getFilterID());
//                        if (blkMedia.getFilterID() > 0 || Const.STITCH_PICTURE)
//                        {
//                            Bitmap filteredBitmap = renderBitmap(originalBitmap, originalBitmap.getWidth(), originalBitmap.getHeight(), Const.STITCH_PICTURE, blkMedia.getLocalPath(), blkMedia.getFilterID());
//                            originalBitmap.recycle();
//                            originalBitmap = filteredBitmap;
//                            BufferedOutputStream bos = null;
//                            FileOutputStream fos = null;
//                            try
//                            {
//                                try
//                                {
//                                    File file = new File(blkMedia.getLocalPath());
//                                    file.delete();
//
//                                    fos = new FileOutputStream(blkMedia.getLocalPath());
//                                    bos = new BufferedOutputStream(fos);
//                                    filteredBitmap.compress(Bitmap.CompressFormat.PNG, 100, bos);
//                                }
//                                finally
//                                {
//                                    if (bos != null)
//                                        bos.close();
//                                    if (fos != null)
//                                        fos.close();
//                                }
//                            }
//                            catch (IOException ex)
//                            {
//                                ex.printStackTrace();
//                            }
//                        }
                } else if (blkMedia.getMediaType() == MVMedia.MediaTypeVideo) {
                    Log.d(TAG, "ImageFilter : Downloading VIDEO done. filterID = " + blkMedia.getFilterID());
//                        originalBitmap = getVideoThumbnail(blkMedia.getLocalPath());
                }
                setMediaDownloadStatus(blkMedia, MVMedia.DownloadStatusFinished);
//                    Bitmap thumbnailBitmap = renderBitmap(originalBitmap, ThumbnailWidth, ThumbnailHeight, (blkMedia.getMediaType() == MVMedia.MediaTypeVideo), blkMedia.getLocalPath(), 0);
//                    originalBitmap.recycle();
                blkMedia.setModifyDate(new Date());
//                    saveMediaThumbnail(blkMedia, thumbnailBitmap);
                updateCameraMedia(blkMedia);
                invalidateLocalMedias(true);
//                    sendCallbackMessage(MsgThumbnailFetched, 0,0,blkMedia);
            } else if (!canceled) {
                addDownloading(blkMedia, initChunkSize, normalChunkSize, true);
            }
        }

        @Override
        public void onGotFileSize(long remSize, long totalSize) {
            Log.v(TAG, "FileDownloadTask.Callback : onGotFileSize(" + remSize + ", " + totalSize + ")");
            if (totalSize >= blkMedia.getSize()) {
                blkMedia.setSize(totalSize);
                Log.v(TAG, "MVMedia.save() @ onGotFileSize#1 : " + blkMedia);
                blkMedia.saveCommonFields();
                updateCameraMedia(blkMedia);
                invalidateLocalMedias(false);
                Log.v(TAG, "FileDownloadTask.Callback : After setSize : size = " + blkMedia.getSize() + " @ " + blkMedia);
                sendCallbackMessage(MsgDownloadProgressUpdated, (int) blkMedia.getDownloadedSize(), (int) totalSize, blkMedia);
            }
            setMediaDownloadStatus(blkMedia, MVMedia.DownloadStatusDownloading);
            synchronized (this) {
                gotFileSize = true;
                if (!transferCompleted)
                    return;
            }

            completeDownloading();
        }

        @Override
        public void onCompleted(long bytesReceived) {
            canceled = false;
            onCompletedOrCanceled(bytesReceived);
        }

        @Override
        public void onCanceled(long bytesReceived) {
            canceled = true;
            onCompletedOrCanceled(bytesReceived);
        }

        void onCompletedOrCanceled(long bytesReceived) {
            Log.v(TAG, "FileDownloadTask.Callback : onCompleted(" + bytesReceived + ")");
            if (!canceled) {
                long downloadedSize = bytesReceived + blkMedia.getDownloadedSize();
                if (downloadedSize > blkMedia.getSize() && blkMedia.getSize() > 0) {
                    downloadedSize = blkMedia.getSize();
                }
                blkMedia.setDownloadedSize(downloadedSize);
                Log.v(TAG, "FileDownloadTask.Callback : (downloaded/total) = (" + downloadedSize + "/" + blkMedia.getSize() + ")");
                Log.v(TAG, "MVMedia.save() @ addDownloading#3 : " + blkMedia);
                blkMedia.save();

                sendCallbackMessage(MsgDownloadProgressUpdated, (int) blkMedia.getDownloadedSize(), (int) blkMedia.getSize(), blkMedia);
            }

            synchronized (this) {
                transferCompleted = true;
                if (!gotFileSize)
                    return;
            }

            completeDownloading();
        }

        @Override
        public void onError(String errMsg) {
            Log.e(TAG, "FileDownloadTask.Callback : onError : " + errMsg);
            downloadTasks.remove(taskWeakRef.get());

            if (FileDownloadTask.ErrorCanceled.equals(errMsg)) {
                setMediaDownloadStatus(blkMedia, MVMedia.DownloadStatusStopped);
            } else {
                setMediaDownloadStatus(blkMedia, MVMedia.DownloadStatusError);
            }
        }

        @Override
        public void onProgressUpdated(long totalBytes, long downloadedBytes) {
            if (canceled) return;

            long nowTime = System.currentTimeMillis();
            if (-1 == lastProgressNotifyTime) {
                lastProgressNotifyTime = nowTime;
            } else if (nowTime - lastProgressNotifyTime >= 500) {
                Log.v(TAG, "FileDownloadTask.Callback : onProgressUpdated(" + (int) (blkMedia.getDownloadedSize() + downloadedBytes) + " / " + (int) blkMedia.getSize() + ")");
                sendCallbackMessage(MsgDownloadProgressUpdated, (int) (blkMedia.getDownloadedSize() + downloadedBytes), (int) blkMedia.getSize(), blkMedia);

                lastProgressNotifyTime = nowTime;
            }
        }

        private boolean gotFileSize = false;
        private boolean transferCompleted = false;

        private boolean canceled = false;

        private long lastProgressNotifyTime = -1;
    }


    private FileDownloadTask taskOfMedia(MVMedia media) {
        if (media.getRemotePath() == null || media.getRemotePath().isEmpty())
            return null;

        Iterator<FileDownloadTask> iter = downloadTasks.iterator();
        FileDownloadTask ret = null;
        while (iter.hasNext()) {
            FileDownloadTask task = iter.next();
            if (media.getRemotePath().equals(task.getRemoteFilePath()) && media.getLocalPath().equals(task.getLocalFilePath())) {
                ret = task;
                break;
            }
        }
        return ret;
    }

    @Override
    public void removeDownloading(MVMedia media) {
        FileDownloadTask taskToRemove = taskOfMedia(media);
        if (null != taskToRemove) {
            taskToRemove.cancel();
            MVCameraDownloadManager.getInstance().removeTask(taskToRemove);
            downloadTasks.remove(taskToRemove);
        }

        if (!TextUtils.isEmpty(media.getLocalPath())) {
            File file = new File(media.getLocalPath());
            file.delete();
        }

        MVMedia cameraMediaToRemove = null;
        synchronized (this) {
            for (MVMedia cameraMedia : cameraMedias) {
                if (cameraMedia.isEqualRemoteMedia(media)) {
                    cameraMediaToRemove = cameraMedia;
                    break;
                }
            }
        }

        if (null != cameraMediaToRemove && TextUtils.equals(cameraMediaToRemove.getLocalPath(), media.getLocalPath())) {
            setMediaDownloadStatus(cameraMediaToRemove, MVMedia.DownloadStatusNone);
            cameraMediaToRemove.setLocalPath("");
            cameraMediaToRemove.setDownloadedSize(0);
            cameraMediaToRemove.save();
        } else {
            media.delete();
        }
    }

    @Override
    public boolean restartDownloading(MVMedia media) {
        setMediaDownloadStatus(media, MVMedia.DownloadStatusPending);
        FileDownloadTask taskToRestart = taskOfMedia(media);
        if (null == taskToRestart) {
            addDownloading(media);
        }
        return true;
    }

    @Override
    public void stopDownloading(MVMedia media) {
        setMediaDownloadStatus(media, MVMedia.DownloadStatusStopped);
        FileDownloadTask taskToRemove = taskOfMedia(media);
        Log.d(TAG, "stopDownloading : taskToRemove = " + taskToRemove + ", with media " + media);
        if (null != taskToRemove) {
            MVCameraDownloadManager.getInstance().removeTask(taskToRemove);
            downloadTasks.remove(taskToRemove);
        }
    }

    @Override
    public List<MVMedia> getMediasInDownloader() {
        LinkedList<MVMedia> ret = new LinkedList<>();
        if (cameraMedias == null)
            return ret;
        else {
            synchronized (this) {
                for (MVMedia media : cameraMedias) {
                    int downloadStatus = media.getDownloadStatus();
                    if (//(media.getDownloadedSize() < media.getSize() || 0 == media.getSize()) &&
                            MVMedia.DownloadStatusNone != downloadStatus &&
                                    MVMedia.DownloadStatusFinished != downloadStatus) {
                        ret.add(media);
                    }
                }
            }
        }
        return ret;
//        List<MVMedia> medias = new Select().from(MVMediaImpl.class).where(MVMedia.DB_KEY_SIZE + " = 0 OR " + MVMedia.DB_KEY_SIZE + " > " + MVMedia.DB_KEY_DOWNLOADEDSIZE).execute();
//        return medias;
    }

    @Override
    public void save() {
    }

    @Override
    public void load() {

    }

    // PathTreeIteratorDelegate //

    @Override
    public void fetchContents(String fullPath, final PathTreeIterator.FetchContentsHandler handler, final PathTreeIterator.Callback callback) {
        if (callback == null)
            return;

        AMBARequest.ResponseListener cdListener = new AMBARequest.ResponseListener() {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                Log.d(TAG, "cdListener : onResponseReceived : " + response);
                if (!response.isRvalOK()) {
//                    callback.onGotNextFile(null, false, false);
                    handler.onDirectoryContentsFetched(null, callback);
                    return;
                }

                AMBARequest.ResponseListener lsListener = new AMBARequest.ResponseListener() {
                    @Override
                    public void onResponseReceived(AMBAResponse response) {
                        AMBAListResponse lsResponse = (AMBAListResponse) response;
                        if (null == lsResponse || !lsResponse.isRvalOK())
                            return;

                        LinkedList<String> filesList = new LinkedList<>();
                        for (Map<String, String> item : lsResponse.listing) {
                            Iterator<String> keyIter = item.keySet().iterator();
                            if (keyIter.hasNext()) {
                                filesList.add(keyIter.next());
                            }
                        }
                        String[] files = new String[filesList.size()];
                        files = filesList.toArray(files);
                        if (handler != null) {
                            handler.onDirectoryContentsFetched(files, callback);
                        }
                    }

                    @Override
                    public void onResponseError(AMBARequest request, int error, String msg) {
//                        callback.onGotNextFile(null, false, false);
                        handler.onDirectoryContentsFetched(null, callback);
                    }
                };
                AMBARequest lsRequest = new AMBARequest(lsListener, AMBAListResponse.class);
                lsRequest.setToken(MVCameraClient.getInstance().getToken());
                lsRequest.setMsg_id(AMBACommands.AMBA_MSGID_LS);
                CMDConnectManager.getInstance().sendRequest(lsRequest);
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
//                callback.onGotNextFile(null, false, false);
                handler.onDirectoryContentsFetched(null, callback);
            }
        };
        AMBARequest cdRequest = new AMBARequest(cdListener);
        cdRequest.setToken(MVCameraClient.getInstance().getToken());
        cdRequest.setMsg_id(AMBACommands.AMBA_MSGID_CD);
        cdRequest.setParam(fullPath);
        CMDConnectManager.getInstance().sendRequest(cdRequest);
    }

    @Override
    public boolean isDirectory(String fullPath) {
        if (fullPath != null && !fullPath.isEmpty()) {
            return fullPath.endsWith(PathTreeIterator.PATH_SEPARATOR);
        } else
            return false;
    }

    @Override
    public boolean shouldPassFilter(String fullPath, boolean isDirectory) {
        boolean ret = true;
        try {
            if (null == fullPath) {
                ret = false;
                return ret;
            }

            if (!isDirectory) {
                String lowerFullPath = fullPath.toLowerCase();
                if ((lowerFullPath.endsWith(".mp4") && !lowerFullPath.endsWith(MVMedia.ABFileType.toLowerCase())) || lowerFullPath.endsWith(".jpg")) {
                    int lastIndexOfPathSeparator = lowerFullPath.lastIndexOf(PathTreeIterator.PATH_SEPARATOR);
                    String lastPathComponent = (lastIndexOfPathSeparator >= 0 ? lowerFullPath.substring(lastIndexOfPathSeparator + 1) : lowerFullPath);
                    ret = (!lastPathComponent.startsWith("."));
                    return ret;
                } else {
                    ret = false;
                    return ret;
                }
            } else {
                String lowerFullDir = fullPath.substring(0, fullPath.length() - 1).toLowerCase();
                if (lowerFullDir.startsWith("/tmp/sd0/amba") || lowerFullDir.startsWith("/tmp/sd0/dcim")) {
                    ret = true;
                    return ret;
                }

//            Log.e(TAG, "Not passed, fullPath = '" + fullPath + "'");
                ret = false;
                return ret;
            }
        } finally {
//            Log.e(TAG, "shouldPassFilter = " + ret + " : fullPath = " + fullPath + ", isDirectory = " + isDirectory);
        }
    }

    @Override
    public boolean shouldStop() {
        return false;
    }

    @Override
    public void onFinished(boolean isStopped) {

    }

    private static final int MsgDownloadStatusChanged = 1;
    private static final int MsgDownloadProgressUpdated = 2;
    private static final int MsgDataSourceCameraUpdated = 3;
    private static final int MsgDataSourceLocalUpdated = 4;
    private static final int MsgThumbnailFetched = 5;
    private static final int MsgMediaInfoFetched = 6;

    private void onDownloadProgressUpdated(MVMedia media, long downloadedBytes, long totalBytes) {
        invalidateLocalMedias(false);
        for (MediaDownloadStatusListener downloadListener : downloadListeners) {
            downloadListener.didDownloadProgressChange(media, downloadedBytes, totalBytes);
        }
    }

    private void onDownloadStatusChanged(MVMedia media, int downloadStatus, String errMsg) {
        if (media != null) {
            String path = media.getLocalPath();
            if (Util.isValidFile(path) && downloadStatus == MVMedia.DownloadStatusFinished) {
                MediaScannerUtil.scanMVMedia(media);
            }
        }
        for (MediaDownloadStatusListener downloadListener : downloadListeners) {
            downloadListener.didDownloadStatusChange(media, downloadStatus, errMsg);
        }
    }

    private void onCameraDataSourceUpdated(List<MVMedia> medias, boolean replacingOnly) {
        Log.e("Feng", "onCameraDataSourceUpdated");

        MVCameraDevice camera = MVCameraClient.getInstance().connectingCamera();
        if (cameraMedias.size() > 0) {
            MVMedia recentMedia = cameraMedias.get(0);
            if (null != camera) {
                camera.recentMedia = recentMedia;
            }

            Bitmap recentThumbnail = getThumbnailImageAsync(recentMedia);
            if (null != recentThumbnail) {
                for (MediaDataSourceListener dataSourceListener : dataSourceListeners) {
                    dataSourceListener.didFetchRecentMediaThumbnail(recentMedia, recentThumbnail);
                }
            }
        } else if (null != camera) {
            camera.recentMedia = null;
            for (MediaDataSourceListener dataSourceListener : dataSourceListeners) {
                dataSourceListener.didFetchRecentMediaThumbnail(null, null);
            }
        }

        for (MediaDataSourceListener dataSourceListener : dataSourceListeners) {
            dataSourceListener.didCameraMediasReloaded(medias, replacingOnly);
        }
    }

    private void onLocalDataSourceUpdated(List<MVMedia> medias, boolean replacingOnly) {

        for (MediaDataSourceListener dataSourceListener : dataSourceListeners) {
            dataSourceListener.didLocalMediasReloaded(medias, replacingOnly);
        }
    }

    private void onThumbnailFetched(MVMedia media) {
        if (null == media) return;

        invalidateLocalMedias(false);

        String key = media.storageKey() + ".jpg";
        Bitmap bitmap = MVBitmapCache.sharedInstance().loadThumbnail(key);


        if (cameraMedias.size() > 0 && cameraMedias.get(0).isEqualRemoteMedia(media)) {
            MVCameraDevice camera = MVCameraClient.getInstance().connectingCamera();
            if (null != camera) {
                camera.recentMedia = media;
            }

            for (MediaDataSourceListener dataSourceListener : dataSourceListeners) {
                dataSourceListener.didFetchThumbnailImage(media, bitmap);
                dataSourceListener.didFetchRecentMediaThumbnail(media, bitmap);
            }
        } else {
            for (MediaDataSourceListener dataSourceListener : dataSourceListeners) {
                dataSourceListener.didFetchThumbnailImage(media, bitmap);
            }
        }
    }

    private void onMediaInfoFetched(MVMedia media) {
        invalidateLocalMedias(false);


        for (MediaDataSourceListener dataSourceListener : dataSourceListeners) {
            dataSourceListener.didFetchMediaInfo(media);
        }
    }

    private Handler callbackHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MsgDownloadProgressUpdated:
                    long downloadedBytes = (msg.arg1 < 0 ? (1L << 32) + msg.arg1 : msg.arg1);
                    long totalBytes = (msg.arg2 < 0 ? (1L << 32) + msg.arg2 : msg.arg2);
                    onDownloadProgressUpdated((MVMedia) msg.obj, downloadedBytes, totalBytes);
                    break;
                case MsgDownloadStatusChanged:
                    onDownloadStatusChanged((MVMedia) msg.obj, msg.arg1, null);
                    break;
                case MsgDataSourceCameraUpdated:
                    onCameraDataSourceUpdated((List<MVMedia>) msg.obj, 0 != msg.arg1);
                    break;
                case MsgDataSourceLocalUpdated:
                    onLocalDataSourceUpdated((List<MVMedia>) msg.obj, 0 != msg.arg1);
                    break;
                case MsgThumbnailFetched:
                    onThumbnailFetched((MVMedia) msg.obj);
                    break;
                case MsgMediaInfoFetched:
                    onMediaInfoFetched((MVMedia) msg.obj);
                    break;
            }
        }
    };

    private void sendCallbackMessage(int what, int arg1, int arg2, Object obj) {
        Message msg = callbackHandler.obtainMessage(what, arg1, arg2, obj);
        callbackHandler.sendMessage(msg);
    }

    private static final String TAG = "QD:MVMediaMgr";

    private ConcurrentLinkedQueue<FileDownloadTask> downloadTasks = new ConcurrentLinkedQueue<>();

    private List<MediaDownloadStatusListener> downloadListeners = Collections.synchronizedList(new LinkedList<MediaDownloadStatusListener>());
    private List<MediaDataSourceListener> dataSourceListeners = Collections.synchronizedList(new LinkedList<MediaDataSourceListener>());

    private boolean cameraMediasInvalid = true;
    private ArrayList<MVMedia> cameraMedias = new ArrayList<>();

    private boolean localMediasInvalid = true;
    private ArrayList<MVMedia> localMedias;

    static MVMediaManagerImpl s_sharedInstance = null;

    public static synchronized MVMediaManagerImpl sharedInstance() {
        if (null == s_sharedInstance) {
            s_sharedInstance = new MVMediaManagerImpl();
        }
        return s_sharedInstance;
    }

    public static Bitmap getVideoThumbnail(String filePath) {
        Bitmap bitmap = null;
        String thumbPath = getVideoThumbnailFromMediaStore(filePath);
        if (Util.isValidFile(thumbPath)){
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(thumbPath, options);
            int w = options.outWidth;
            int h = options.outHeight;
            Log.e("Feng", String.format("path =-> %s,outWidth =-> %s, outHeight =-> %s",filePath, w ,h));
            bitmap = BitmapFactory.decodeFile(thumbPath);
        }else {
            MediaMetadataRetriever retriever = new MediaMetadataRetriever();
            try {
                retriever.setDataSource(filePath);
                bitmap = retriever.getFrameAtTime();
            } catch (IllegalArgumentException e) {
                e.printStackTrace();
            } catch (RuntimeException e) {
                e.printStackTrace();
            } finally {
                try {
                    retriever.release();
                } catch (RuntimeException e) {
                    e.printStackTrace();
                }
            }
        }
        return bitmap;
    }

    private static final String[] sVideoProjection = { MediaStore.Video.Media._ID};
    private static final String[] sVideoThumbProjection = {MediaStore.Video.Thumbnails.DATA};
    public static String getVideoThumbnailFromMediaStore(String path){
        return getVideoThumbnailFromMediaStore(ElephantApp.getInstance(), path);
    }


    public static String getVideoThumbnailFromMediaStore(Context context, String path){
        String thumbPath = null;
        ContentResolver cr = context.getContentResolver();
        Cursor cursor = cr.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                sVideoProjection,
                MediaStore.Video.Media.DATA + " =? ",
                new String[]{path},
                null);
        if (cursor != null && cursor.moveToFirst()){
            int idIndex = cursor.getColumnIndex(MediaStore.Video.Media._ID);
            if (idIndex > -1) {
                int id = cursor.getInt(idIndex);
                Cursor thumbCursor = cr.query(
                        MediaStore.Video.Thumbnails.EXTERNAL_CONTENT_URI,
                        sVideoThumbProjection,
                        MediaStore.Video.Thumbnails.VIDEO_ID + "=?",
                        new String[]{String.valueOf(id)},
                        null
                );
                if (thumbCursor != null && thumbCursor.moveToFirst()) {
                    int tIndex = thumbCursor.getColumnIndex(MediaStore.Video.Thumbnails.DATA);
                    if (tIndex > -1) {
                        thumbPath = thumbCursor.getString(tIndex);
                    }
                }
                FilesUtils.close(thumbCursor);
            }
        }
        FilesUtils.close(cursor);
        return thumbPath;
    }

    public void test(Context context) {
        final Context ctx = context;
        class Listener implements MediaDataSourceListener, MediaDownloadStatusListener {
            @Override
            public void didCameraMediasReloaded(List<MVMedia> medias, boolean replacingOnly) {

            }

            @Override
            public void didLocalMediasReloaded(List<MVMedia> medias, boolean replacingOnly) {
                Log.d(TAG, "didLocalMediasReloaded:" + medias);
            }

            @Override
            public void didFetchThumbnailImage(MVMedia media, Bitmap image) {

            }

            @Override
            public void didFetchRecentMediaThumbnail(MVMedia media, Bitmap image) {

            }

            @Override
            public void didFetchMediaInfo(MVMedia media) {

            }

            @Override
            public void didDownloadStatusChange(MVMedia media, int downloadStatus, String errorMessage) {
                Toast.makeText(ctx, "didDownloadStatusChange:" + downloadStatus + " : " + errorMessage, Toast.LENGTH_SHORT).show();
            }

            @Override
            public void didDownloadProgressChange(MVMedia media, long downloadedBytes, long totalBytes) {
//                Log.v(TAG, "didDownloadProgressChange(" + downloadedBytes + "/" + totalBytes + ") @" + media);
            }
        }
        Listener listener = new Listener();
        addMediaDataSourceListener(listener);
        addMediaDownloadStatusListener(listener);

        String[] remotePaths = {"/tmp/SD0/DCIM/140101100/062613AA.MP4", "/tmp/SD0/AMBA/140101100/000807AB.MP4", "/tmp/SD0/AMBA/140101100/000159AB.MP4", "/tmp/SD0/DCIM/140234AA.MP4", "/tmp/SD0/DCIM/TokyoShow.mp4"};
        int[] fileSize = {280350, 1222186, 104844996, 179369338, 146695432};
        String cameraUUID = MVCameraClient.getInstance().connectingCamera().getUUID();
        for (int i = 0; i < 5; ++i) {
            String remotePath = remotePaths[i];
            MVMedia media = new Select().from(MVMediaImpl.class).where(MVMedia.DB_KEY_REMOTEPATH + " = '" + remotePath + "' AND " + MVMedia.DB_KEY_CAMERAUUID + " = '" + cameraUUID + "'").executeSingle();
            Log.d(TAG, "Reload saved media : " + media);
            if (null == media) {
                media = MVMedia.create();
                media.setRemotePath(remotePath);
                media.setCameraUUID(cameraUUID);
                media.setSize(0);
                media.setDownloadedSize(0);
                media.save();
                Log.d(TAG, "Create new media : " + media);
            }
            addDownloading(media);
        }
    }

    public static void testIDRDecoding() {
        new Thread() {
            public void run() {
                File directory = new File(AppStorageManager.getAlbumDir());
                File[] files = directory.listFiles();
                for (File file : files) {
                    String path = file.getAbsolutePath();
                    if (path.endsWith(".thumb")) {
                        Log.v(TAG, "IDR file : " + path);
                        int size = (int) file.length();
                        byte[] idrData = new byte[size];
                        try {
                            FileInputStream fis = new FileInputStream(path);
                            fis.read(idrData);
                            Bitmap bitmap = ThumbnailExtractor.getThumbBitmapFromOneFrame(idrData);
                            Log.v(TAG, "Bitmap decoded : (" + bitmap.getWidth() + ", " + bitmap.getHeight() + ")");
                            fis.close();
                            Log.v(TAG, "Decode IDR to : " + path + ".png");
                        } catch (Exception ex) {
                            ex.printStackTrace();
                        }
                    }
                }
            }
        }.start();
    }

    private boolean justConnected = true;

    @Override
    public void didConnectSuccess(MVCameraDevice device) {
        if (device != null)
            justConnected = true;
    }

    @Override
    public void didConnectFail(String errorMessage) {

    }

    @Override
    public void didSetWifi(boolean success, String errMsg) {

    }

    @Override
    public void didRestartWifi(boolean success, String errMsg) {

    }

    @Override
    public void didDisconnect(int cameraException) {

    }

    @Override
    public void didVoltagePercentChanged(int percent, boolean isCharging) {

    }

    @Override
    public void didCameraModeChange(int mode, int subMode, int param) {

    }

    @Override
    public void didSwitchCameraModeFail(String errMsg) {

    }

    @Override
    public void didBeginShooting() {

    }

    @Override
    public void didBeginShootingError(int error) {

    }

    @Override
    public void didShootingTimerTick(int shootTime, int videoTime) {

    }

    @Override
    public void didEndShooting(String remoteFilePath, int error, String errMsg) {

    }

    @Override
    public void didEndShootingError(int error) {

    }

    @Override
    public void didClippingBegin() {

    }

    @Override
    public void didClippingTimerTick(int secondsLeft) {

    }

    @Override
    public void didClippingEnd(int totalClips) {

    }

    @Override
    public void didReceiveAllSettingItems(int errorCode) {

    }

    @Override
    public void didSettingItemChanged(int optionUID, int paramUID, String errMsg) {

    }

    @Override
    public void didWorkStateChange(int workState) {

    }

    @Override
    public void didStorageMountedStateChanged(boolean mounted) {
        getCameraMedias(true);
    }

    @Override
    public void didStorageStateChanged(int oldState, int newState) {

    }

    @Override
    public void didStorageTotalFreeChanged(int total, int free) {

    }

    @Override
    public void didReceiveCameraNotification(String notification) {

    }
}
