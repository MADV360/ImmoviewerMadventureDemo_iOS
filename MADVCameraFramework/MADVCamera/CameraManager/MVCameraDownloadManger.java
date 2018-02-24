package com.madv360.madv.connection;

import com.madv360.madv.connection.ambarequest.AMBAGetFileRequest;
import com.madv360.madv.connection.ambaresponse.AMBACancelFileTransferResponse;
import com.madv360.madv.connection.ambaresponse.AMBAFileDownloadResultResponse;
import com.madv360.madv.connection.ambaresponse.AMBAGetFileResponse;
import com.madv360.madv.connection.ambaresponse.AMBAGetThumbnailResponse;
import com.madv360.madv.model.MVCameraDevice;
import com.madv360.madv.utils.FileUtil;
import com.madv360.madv.utils.MD5Util;

import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;

import android.os.Environment;
import android.util.Log;

import module.mediaeditor.utils.BackgroundExecutor;

/**
 * Created by qiudong on 16/6/24.
 */
public class MVCameraDownloadManger implements DATAConnectManager.DataConnectionObserver {
    public static final int TASK_PRIORITY_EMERGENCY = 3;
    public static final int TASK_PRIORITY_HIGH = 2;
    public static final int TASK_PRIORITY_LOW = 1;
    public static final int TASK_PRIORITY_TRIVIAL = 0;
    public static final int TASK_PRIORITYS = 4;

    public static final int DownloadInitChunkSize = 1024;//1024*10240;//
    public static final int DownloadChunkSize = 1024*1024;//1024*10240;//

    private static final int DefaultBufferSize = (DownloadInitChunkSize > DownloadChunkSize ? DownloadInitChunkSize : DownloadChunkSize);

    private static final String TAG = "QD:MVCameraDownloadMgr";

    public static abstract class DownloadTask extends DATAConnectManager.DataReceiver {
        public DownloadTask(int priority) {
            this.priority = priority;
        }

        public abstract void start();

        public void cancel() {
//            DATAConnectManager.getInstance().closeConnection();
            finish();
        }

        protected int priority = TASK_PRIORITY_HIGH;
    }

    public synchronized void addTask(DownloadTask task, boolean addAsFirst) {
        DATAConnectManager.getInstance().openConnection();

        if (currentDownloadingTask == null)
        {
            Log.v(TAG, "executeTask @ addTask : currentDownloadingTask = " + currentDownloadingTask + ", task = " + task);
            currentDownloadingTask = task;
            executeTask(task);
        }
        else
        {
            Log.v(TAG, "Try enqueue task @ addTask : currentDownloadingTask = " + currentDownloadingTask + ", task = " + task);
            for (int i=downloadTaskQueues.length-1; i>=0; --i)
            {
                if (downloadTaskQueues[i].contains(task))
                    return;
            }

            if (currentDownloadingTask.equals(task))
                return;

            Log.v(TAG, "Enqueue task @ addTask : currentDownloadingTask = " + currentDownloadingTask + ", task = " + task);
            if (addAsFirst)
                downloadTaskQueues[task.priority].addFirst(task);
            else
                downloadTaskQue== TASK_PRIORITY_EMERGENCY || currentDownloadingTask.priority == TASK_PRIORITY_TRIVIAL)
                    && (curreues[task.priority].add(task);

            if ((task.priority ntDownloadingTask.priority < task.priority))
            {
                currentDownloadingTask.cancel();
                if (addAsFirst)
                    downloadTaskQueues[currentDownloadingTask.priority].add(1, currentDownloadingTask);
                else
                    downloadTaskQueues[currentDownloadingTask.priority].add(currentDownloadingTask);
            }
        }
    }

    private void executeTask(DownloadTask task) {
        final DownloadTask theTask = task;
        BackgroundExecutor.execute(new BackgroundExecutor.Task("", 0L, "") {
            @Override
            public void execute() {
                Log.d(TAG, "executeTask : Before waiting");
                DATAConnectManager.getInstance().waitForState(DATAConnectManager.SOCKET_STATE_READY);
                MVCameraClient.getInstance().waitForState(MVCameraClient.CameraClientStateConnected);
                Log.d(TAG, "executeTask : After waiting");
                DATAConnectManager.getInstance().setDataReceiver(theTask);
                theTask.start();
            }
        });
//        new Thread() {
//            @Override
//            public void run() {
//
//            }
//        }.start();

    }

    public synchronized void removeTask(DownloadTask task) {
        Log.d(TAG, "removeTask : currentDownloadingTask = " + currentDownloadingTask + ", task = " + task);
        if (currentDownloadingTask == task)
        {
            task.cancel();
            currentDownloadingTask = null;
        }
        for (int i=0; i<TASK_PRIORITYS; ++i)
        {
            downloadTaskQueues[i].remove(task);
        }
    }

    public void pollTask() {
        DownloadTask task = null;
        for (int i=TASK_PRIORITY_EMERGENCY; i>=TASK_PRIORITY_TRIVIAL; --i)
        {
            synchronized (this)
            {
                if (!downloadTaskQueues[i].isEmpty())
                {
                    task = downloadTaskQueues[i].pollFirst();
                    if (null != task) break;
                }
            }
        }

        synchronized (this)
        {
            Log.v(TAG, "pollTask @ addTask : task = " + task + ", currentDownloadingTask = " + currentDownloadingTask);
            currentDownloadingTask = task;
            if (task != null)
            {
//                Log.v(TAG, "executeTask @ onReceiverEmptied");
                executeTask(task);
            }
        }
    }

    public static synchronized MVCameraDownloadManger getInstance() {
        if (null == instance)
        {
            instance = new MVCameraDownloadManger();
        }
        return instance;
    }

    private MVCameraDownloadManger() {
        DATAConnectManager.getInstance().addObserver(this);
    }

    public void finalize() {
        DATAConnectManager.getInstance().removeObserver(this);
    }

    private static MVCameraDownloadManger instance = null;

    private LinkedList<DownloadTask>[] downloadTaskQueues = new LinkedList[] {
        new LinkedList<>(),new LinkedList<>(),new LinkedList<>(),new LinkedList<>()
    };

    private DownloadTask currentDownloadingTask = null;

    private byte[] sharedBuffer = new byte[DefaultBufferSize];

    private synchronized byte[] resizeSharedBufferIfNecessary(long newSize) {
        if (newSize > sharedBuffer.length)
        {
            sharedBuffer = new byte[(int)newSize];
        }
        return sharedBuffer;
    }

    private synchronized byte[] sharedBuffer() {
        return sharedBuffer;
    }

    @Override
    public void onDataConnectionStateChanged(int newState, int oldState, Object object) {

    }

    @Override
    public void onReceiverEmptied() {
    }

    ////////////
    //{"rval":0,"msg_id":1025,"size":296690,"type":"idr","md5sum":"392436603f8e1a71e355616c0ab996ea"}
    public static class ThumbnailDownloadTask extends DownloadTask implements CMDConnectManager.CMDConnectionObserver {
        public interface Callback {
            void onCompleted(byte[] data, int bytesReceived);

            void onError(String errMsg);
        }

        public ThumbnailDownloadTask(int priority, String remoteVideoPath, boolean isVideo, Callback callback) {
            super(priority);
            if (remoteVideoPath.toUpperCase().endsWith("AA.MP4"))
            {
                remoteVideoPath = remoteVideoPath.substring(0, remoteVideoPath.length() - "AA.MP4".length()) + "AB.MP4";
            }
            this.remoteVideoPath = remoteVideoPath;
            this.isVideo = isVideo;
            this.callback = callback;
        }

        @Override
        public void onConnectionStateChanged(int newState, int oldState, Object object) {

        }

        @Override
        public void onReceiveCameraResponse(AMBAResponse response) {

        }

        @Override
        public void start() {
            MVCameraDownloadManger.getInstance().resizeSharedBufferIfNecessary(BUFFER_SIZE);
//            buffer = new byte[BUFFER_SIZE];

            CMDConnectManager.getInstance().addObserver(this);

            AMBARequest.ResponseListener getThumbListener = new AMBARequest.ResponseListener() {
                @Override
                public void onResponseReceived(AMBAResponse response) {
                    AMBAGetThumbnailResponse getThumbnailResponse = (AMBAGetThumbnailResponse) response;
                    if (getThumbnailResponse == null) return;

                    if (!getThumbnailResponse.isRvalOK())
                    {
                        invokeCallbackAndExit("Request Failed");
                        return;
                    }

                    bytesToReceive = getThumbnailResponse.size;
                    remoteMD5 = getThumbnailResponse.md5sum;

                    if (isFinished())
                    {
                        synchronized (this)
                        {
                            if (localMD5 == null)
                            {
                                localMD5 = MD5Util.md5OfData(MVCameraDownloadManger.getInstance().sharedBuffer(), 0, bytesToReceive);
                            }
                        }

                        if (localMD5.equals(remoteMD5))
                        {
                            Log.v(TAG, "Thumbnail MD5 check#0 Passed: Local=" + localMD5 + ", Remote=" + remoteMD5);
                            invokeCallbackAndExit(null);
                        }
                        else
                        {
                            Log.v(TAG, "Thumbnail MD5 check#0 Failed: Local=" + localMD5 + ", Remote=" + remoteMD5);
                            invokeCallbackAndExit("MD5 check failed#0: Local=" + localMD5 + ", Remote=" + remoteMD5);
                        }
                    }
                }

                @Override
                public void onResponseError(AMBARequest request, int error, String msg) {
                    invokeCallbackAndExit("Request Failed Or Timeout");
                }
            };
            AMBARequest getThumbRequest = new AMBARequest(getThumbListener, AMBAGetThumbnailResponse.class);
            getThumbRequest.setToken(MVCameraClient.getInstance().getToken());
            getThumbRequest.setType(isVideo ? "idr":"thumb");
            getThumbRequest.setParam(remoteVideoPath);
            getThumbRequest.setMsg_id(AMBACommands.AMBA_MSGID_GET_THUMB);
            CMDConnectManager.getInstance().sendRequest(getThumbRequest);
        }

        @Override
        protected int onDataReceived(byte[] data, int offset, int length) {
            if (null == data)
                return 0;

            System.arraycopy(data, offset, MVCameraDownloadManger.getInstance().sharedBuffer(), bytesReceived, length);
            bytesReceived += length;

            if (isFinished())
            {
                synchronized (this) {
                    if (null == localMD5)
                    {
                        localMD5 = MD5Util.md5OfData(MVCameraDownloadManger.getInstance().sharedBuffer(), 0, bytesToReceive);
                    }
                }

                if (remoteMD5 != null)
                {
                    if (localMD5.equals(remoteMD5))
                    {
                        Log.v(TAG, "Thumbnail MD5 check#1 Passed: Local=" + localMD5 + ", Remote=" + remoteMD5);
                        invokeCallbackAndExit(null);
                    }
                    else
                    {
                        Log.v(TAG, "Thumbnail MD5 check#1 Failed: Local=" + localMD5 + ", Remote=" + remoteMD5);
                        invokeCallbackAndExit("MD5 check failed#1: Local=" + localMD5 + ", Remote=" + remoteMD5);
                    }
                }
            }

            return bytesReceived;
        }

        @Override
        protected boolean isFinished() {
            return (bytesToReceive > 0 && bytesToReceive <= bytesReceived);
        }

        @Override
        protected void onError(int error, String errMsg) {
            invokeCallbackAndExit(errMsg);
        }

        private synchronized boolean checkCallbackInvoked() {
            Log.d(TAG, "ThumbnailDownloadTask : checkCallbackInvoked : " + callbackInvoked);
            if (callbackInvoked)
                return true;

            callbackInvoked = true;
            return false;
        }

        private void invokeCallbackAndExit(String errMsg) {
            Log.d(TAG, "ThumbnailDownloadTask : invokeCallbackAndExit : " + errMsg + ", this = " + this);
            if (checkCallbackInvoked()) return;

            CMDConnectManager.getInstance().removeObserver(this);

            if (errMsg != null)
            {
                callback.onError(errMsg);
            }
            else
            {
                callback.onCompleted(MVCameraDownloadManger.getInstance().sharedBuffer(), bytesReceived);
            }

            DATAConnectManager.getInstance().removeDataReceiver(ThumbnailDownloadTask.this);
            MVCameraDownloadManger.getInstance().pollTask();
        }

//        @Override
//        public int hashCode() {
//            return ("ThumbnailDownloadTask" + remoteVideoPath).hashCode();
//        }

        @Override
        public boolean equals(Object o) {
            if (!(o instanceof ThumbnailDownloadTask))
                return false;

            ThumbnailDownloadTask other = (ThumbnailDownloadTask) o;
            if (remoteVideoPath == null)
                return other.remoteVideoPath == null || other.remoteVideoPath.isEmpty();
            else
                return (remoteVideoPath.equals(other.remoteVideoPath)
                    && isVideo == other.isVideo);
        }

        @Override
        public String toString() {
            return "DownloadTask(" + hashCode() + ") : remoteVideoPath='" + remoteVideoPath + "', isVideo=" + isVideo + "";
        }

        private String remoteVideoPath;
        private boolean isVideo = true;
        private Callback callback;

//        private byte[] buffer;
        private static final int BUFFER_SIZE = 1024*2048;

        private boolean callbackInvoked = false;

        private String localMD5 = null;
        private String remoteMD5 = null;

        private int bytesToReceive = 0;

        private int bytesReceived = 0;
    }

    public static class FileDownloadTask extends DownloadTask implements CMDConnectManager.CMDConnectionObserver {
        public static final String ErrorMD5CheckFailed = "ErrorMD5CheckFailed";
        public static final String ErrorRequestFailed = "ErrorRequestFailed";
        public static final String ErrorTransferring = "ErrorTransferring";
        public static final String ErrorReceiving = "ErrorReceiving";
        public static final String ErrorTimeout = "ErrorTimeout";
        public static final String ErrorCanceled = "ErrorCanceled";

        public interface Callback {
            void onGotFileSize(long remSize, long totalSize);

            void onCompleted(long bytesReceived);

            void onCanceled(long bytesReceived);

            void onError(String errMsg);

            void onProgressUpdated(long totalBytes, long downloadedBytes);
        }

        public FileDownloadTask(int priority, String remoteFilePath, long fileOffset, int chunkSize, String localFilePath, Callback callback) {
            super(priority);
            this.remoteFilePath = remoteFilePath;
            this.localFilePath = localFilePath;
            this.fileOffset = fileOffset;
            this.chunkSize = chunkSize;

            this.bytesToReceive = chunkSize;
            this.bytesReceived = 0;

            this.callback = callback;
        }

        @Override
        public void onConnectionStateChanged(int newState, int oldState, Object object) {
        }

        @Override
        public void onReceiveCameraResponse(AMBAResponse response) {
            Log.d(TAG, "FileDownloadTask : onReceiveCameraResponse(" + response + ")");
            if (response instanceof AMBAFileDownloadResultResponse)
            {
                AMBAFileDownloadResultResponse resultResponse = (AMBAFileDownloadResultResponse) response;
                bytesToReceive = resultResponse.getBytesSent();
                remoteMD5 = resultResponse.getMD5();
                Log.d(TAG, "FileDownloadTask : onDataReceived : RemoteMD5 = " + remoteMD5);
                if (resultResponse.type.equals("get_file_complete"))
                {
                    if (localMD5 != null)
                    {
                        if (localMD5.equals(remoteMD5))
                        {
                            invokeCallbackAndExit(null);
                        }
                        else
                        {
                            Log.d(TAG, "MD5 check failed @ onReceiveCameraResponse#0: localMD5 = " + localMD5 + ", remoteMD5 = " + remoteMD5);
                            invokeCallbackAndExit(ErrorMD5CheckFailed);
                        }
                    }
                    else
                    {
                        if (isFinished())
                        {
                            synchronized (this)
                            {
                                if (localMD5 == null)
                                {
                                    localMD5 = MD5Util.md5OfData(MVCameraDownloadManger.getInstance().sharedBuffer(), 0, bytesToReceive);
                                }
                            }
                            Log.d(TAG, "FileDownloadTask : onReceiveCameraResponse#0.5 : Save data to (" + fileOffset + ", " + bytesToReceive + "), MD5 = " + localMD5);

                            if (localMD5.equals(remoteMD5))
                            {
                                invokeCallbackAndExit(null);
                            }
                            else
                            {
                                Log.d(TAG, "MD5 check failed @ onReceiveCameraResponse#0.5: localMD5 = " + localMD5 + ", remoteMD5 = " + remoteMD5);
                                invokeCallbackAndExit(ErrorMD5CheckFailed);
                            }
                        }
                    }
                }
                else if (resultResponse.type.startsWith("get_file_fail"))
                {
                    if (localMD5 != null)
                    {
                        if (localMD5.equals(remoteMD5))
                        {
                            invokeCallbackAndExit(ErrorTransferring);
                        }
                        else
                        {
                            Log.d(TAG, "MD5 check failed @ onReceiveCameraResponse#1: localMD5 = " + localMD5 + ", remoteMD5 = " + remoteMD5);
                            invokeCallbackAndExit(ErrorMD5CheckFailed);
                        }
                    }
                    else
                    {
                        errMsg = ErrorTransferring;
                        if (isFinished())
                        {
                            synchronized (this)
                            {
                                if (localMD5 == null)
                                {
                                    localMD5 = MD5Util.md5OfData(MVCameraDownloadManger.getInstance().sharedBuffer(), 0, bytesToReceive);
                                }
                            }
                            Log.d(TAG, "FileDownloadTask : onReceiveCameraResponse#1.5 : Save data to (" + fileOffset + ", " + bytesToReceive + "), MD5 = " + localMD5);

                            if (localMD5.equals(remoteMD5))
                            {
                                invokeCallbackAndExit(errMsg);
                            }
                            else
                            {
                                Log.d(TAG, "MD5 check failed @ onReceiveCameraResponse#1.5: localMD5 = " + localMD5 + ", remoteMD5 = " + remoteMD5);
                                invokeCallbackAndExit(ErrorMD5CheckFailed);
                            }
                        }
                    }
                }
            }
            else if (response instanceof AMBACancelFileTransferResponse)
            {
                AMBACancelFileTransferResponse cancelResponse = (AMBACancelFileTransferResponse) response;
                bytesToReceive = cancelResponse.getBytesSent();
                remoteMD5 = cancelResponse.getMD5();

                if (localMD5 != null)
                {
                    if (localMD5.equals(remoteMD5))
                    {
                        invokeCallbackAndExit(ErrorCanceled);
                    }
                    else
                    {
                        Log.d(TAG, "MD5 check failed @ onReceiveCameraResponse#2: localMD5 = " + localMD5 + ", remoteMD5 = " + remoteMD5);
//                        invokeCallbackAndExit(ErrorMD5CheckFailed);
                    }
                }
                else
                {
                    errMsg = ErrorCanceled;
                    if (isFinished())
                    {
                        synchronized (this) {
                            if (localMD5 == null)
                            {
                                localMD5 = MD5Util.md5OfData(MVCameraDownloadManger.getInstance().sharedBuffer(), 0, bytesToReceive);
                            }
                        }
                        Log.d(TAG, "FileDownloadTask : onReceiveCameraResponse#2.5 : Save data to (" + fileOffset + ", " + bytesToReceive + "), MD5 = " + localMD5);

                        if (localMD5.equals(remoteMD5))
                        {
                            invokeCallbackAndExit(errMsg);
                        }
                        else
                        {
                            Log.d(TAG, "MD5 check failed @ onReceiveCameraResponse#2.5: localMD5 = " + localMD5 + ", remoteMD5 = " + remoteMD5);
//                            invokeCallbackAndExit(ErrorMD5CheckFailed);
                        }
                    }
                }
            }
        }

        @Override
        public void start() {
            MVCameraDownloadManger.getInstance().resizeSharedBufferIfNecessary(bytesToReceive <= 0 ? DownloadChunkSize : bytesToReceive);
//            buffer = new byte[bytesToReceive <= 0 ? DownloadChunkSize : bytesToReceive];

            CMDConnectManager.getInstance().addObserver(this);

            AMBARequest.ResponseListener getFileListener = new AMBARequest.ResponseListener() {
                @Override
                public void onResponseReceived(AMBAResponse response) {
                    Log.d(TAG, "FileDownloadTask : getFileListener onResponseReceived(" + response + ")");
                    AMBAGetFileResponse getFileResponse = (AMBAGetFileResponse) response;
                    if (getFileResponse != null)
                    {
                        if (!getFileResponse.isRvalOK())
                        {
                            invokeCallbackAndExit(ErrorRequestFailed);
                        }
                        else if (callback != null && !canceled)
                        {
                            callback.onGotFileSize(getFileResponse.getRemSize(), getFileResponse.getSize());
                        }
                    }
                }

                @Override
                public void onResponseError(AMBARequest request, int error, String msg) {
                    Log.d(TAG, "FileDownloadTask : getFileListener onResponseError(" + error + ", " + msg + ")");
                    invokeCallbackAndExit(ErrorRequestFailed);
                }
            };
            AMBAGetFileRequest getFileRequest = new AMBAGetFileRequest(getFileListener);
            getFileRequest.setMsg_id(AMBACommands.AMBA_MSGID_GET_FILE);
            getFileRequest.setToken(MVCameraClient.getInstance().getToken());
            getFileRequest.setParam(remoteFilePath);
            getFileRequest.offset = fileOffset;
            getFileRequest.fetch_size = chunkSize;
            CMDConnectManager.getInstance().sendRequest(getFileRequest);
        }

        @Override
        protected int onDataReceived(byte[] data, int offset, int length) {
            Log.v(TAG, "FileDownloadTask : onDataReceived(" + offset + ", " + length + ")");
            try {
                System.arraycopy(data, offset, MVCameraDownloadManger.getInstance().sharedBuffer(), (int)bytesReceived, length);
            }
            catch (Exception ex) {
                ex.printStackTrace();
                Log.e(TAG, "onDataReceived Exception : " + ex.getMessage());
            }
            bytesReceived += length;

            if (callback != null)
            {
                callback.onProgressUpdated(this.chunkSize, bytesReceived);
            }

            if (isFinished())
            {
                synchronized (this) {
                    if (localMD5 == null)
                    {
                        localMD5 = MD5Util.md5OfData(MVCameraDownloadManger.getInstance().sharedBuffer(), 0, bytesToReceive);
                    }
                }
                Log.d(TAG, "FileDownloadTask : onDataReceived : Save data to (" + fileOffset + ", " + bytesToReceive + "), MD5 = " + localMD5);

                if (remoteMD5 != null)
                {
                    if (localMD5.equals(remoteMD5))
                    {
                        invokeCallbackAndExit(errMsg);
                    }
                    else
                    {
                        Log.d(TAG, "MD5 check failed @ onDataReceived#0: localMD5 = " + localMD5 + ", remoteMD5 = " + remoteMD5);
                        invokeCallbackAndExit(ErrorMD5CheckFailed);
                    }
                }
            }
            return length;
        }

        @Override
        protected boolean isFinished() {
            Log.v(TAG, "FileDownloadTask : isFinished : " + bytesReceived + "/" + bytesToReceive);
            return (bytesToReceive > 0 && bytesToReceive <= bytesReceived);
        }

        @Override
        protected void onError(int error, String errMsg) {
            Log.d(TAG, "FileDownloadTask : onError(" + error + ", " + errMsg + ")");
            if (error == DATAConnectManager.ERROR_RECEIVING_TIMEOUT)
            {
                invokeCallbackAndExit(ErrorTimeout);
            }
            else if (error == DATAConnectManager.ERROR_SOCKET_EXCEPTION)
            {
                invokeCallbackAndExit(ErrorReceiving);
            }
        }

        @Override
        public void cancel() {
            Log.d(TAG, "FileDownloadTask : cancel (setMediaDownloadStatus)");
            /*
            AMBARequest.ResponseListener cancelTransferListener = new AMBARequest.ResponseListener() {
                @Override
                public void onResponseReceived(AMBAResponse response) {
                    AMBACancelFileTransferResponse cancelFileResponse = (AMBACancelFileTransferResponse) response;
                    if (null != cancelFileResponse && cancelFileResponse.isRvalOK())
                    {
                        bytesToReceive = cancelFileResponse.getBytesSent();
                        if (isFinished())
                        {
                            invokeCallbackAndExit(ErrorCanceled);
                        }
                    }
                    else
                    {
                        invokeCallbackAndExit(ErrorCanceled);
                    }
                }

                @Override
                public void onResponseError(AMBARequest request, int error, String msg) {

                }
            };
            AMBARequest cancelTransferRequest = new AMBARequest(cancelTransferListener, AMBACancelFileTransferResponse.class);
            cancelTransferRequest.setMsg_id(AMBACommands.AMBA_MSGID_CANCEL_FILE_TRANSFER);
            cancelTransferRequest.setToken(MVCameraClient.getInstance().getToken());
            cancelTransferRequest.setParam(remoteFilePath);
            CMDConnectManager.getInstance().sendRequest(cancelTransferRequest);
            /*/
            canceled = true;
            //*/
        }

        private synchronized boolean checkCallbackInvoked() {
            Log.d(TAG, "FileDownloadTask : checkCallbackInvoked : " + callbackInvoked);
            if (callbackInvoked)
                return true;

            callbackInvoked = true;
            return false;
        }

        private void invokeCallbackAndExit(String errMsg) {
            Log.d(TAG, "FileDownloadTask : invokeCallbackAndExit : " + errMsg + ", this = " + this);
            if (checkCallbackInvoked()) return;

            FileUtil.saveFileChunk(localFilePath, fileOffset, MVCameraDownloadManger.getInstance().sharedBuffer(), 0, bytesToReceive);

            CMDConnectManager.getInstance().removeObserver(this);

            if (errMsg != null)
            {
                callback.onError(errMsg);
            }
            else if (canceled)
            {
                callback.onCanceled(bytesReceived);
            }
            else
            {
                callback.onCompleted(bytesReceived);
            }

            DATAConnectManager.getInstance().removeDataReceiver(FileDownloadTask.this);
            MVCameraDownloadManger.getInstance().pollTask();
        }

        @Override
        public boolean equals(Object o) {
            if (!(o instanceof FileDownloadTask))
                return false;

            FileDownloadTask other = (FileDownloadTask)o;
            if (remoteFilePath == null)
                return ((other.remoteFilePath == null || other.remoteFilePath.isEmpty()) && fileOffset == other.fileOffset && chunkSize == other.chunkSize && localFilePath.equals(other.localFilePath));

            return (remoteFilePath.equals(other.remoteFilePath) && fileOffset == other.fileOffset && chunkSize == other.chunkSize && localFilePath.equals(other.localFilePath));
        }

//        @Override
//        public int hashCode() {
//            return ("FileDownloadTask" + remoteFilePath).hashCode();
//        }

        private String remoteFilePath;
        private long fileOffset;
        private int chunkSize;
        private String localFilePath;

//        private byte[] buffer;
        private long bytesToReceive;
        private long bytesReceived;

        private String localMD5 = null;
        private String remoteMD5 = null;
        private String errMsg = null;

        private boolean canceled = false;

        private boolean callbackInvoked = false;
        private Callback callback;

        public String getRemoteFilePath() {
            return remoteFilePath;
        }

        public String getLocalFilePath() {
            return localFilePath;
        }

        public void setCallback(Callback callback) {
            this.callback = callback;
        }
    }

    public static class FileDownloadCallback implements MVCameraDownloadManger.FileDownloadTask.Callback {
        public FileDownloadCallback() {
            this(TASK_PRIORITY_HIGH, DownloadInitChunkSize, DownloadChunkSize);
        }

        public FileDownloadCallback(int priority, int initChunkSize, int normalChunkSize) {
            this.priority = priority;
            this.initChunkSize = initChunkSize;
            this.normalChunkSize = normalChunkSize;
        }

        protected DownloadChunkInfo blkChunkInfo;

        @Override
        public void onGotFileSize(long remSize, long totalSize) {
            Log.v(TAG, "FileDownloadTask.Callback : onGotFileSize(" + remSize + ", " + totalSize + ")");
            if (totalSize >= blkChunkInfo.size)
            {
                blkChunkInfo.size = totalSize;
//                    blkMedia = blkMedia.safeSave();
//                    Log.v(TAG, "FileDownloadTask.Callback : After setSize : size = " + blkChunkInfo.size + " @ " + blkMedia);
//                    sendCallbackMessage(MsgDownloadProgressUpdated, blkMedia.getDownloadedSize(), totalSize, blkMedia);
            }

//                setMediaDownloadStatus(blkMedia, MVMedia.MVMediaDownloadStatusDownloading);

            synchronized (this)
            {
                gotFileSize = true;
                if (!transferCompleted)
                    return;
            }

//                blkMedia = blkMedia.safeSave();
//                downloadTasks.remove(taskWeakRef.get());
            if (blkChunkInfo.size <= blkChunkInfo.downloadedSize)
            {
//                    setMediaDownloadStatus(blkMedia, MVMedia.MVMediaDownloadStatusFinished);
            }
            else
            {
                MVCameraDownloadManger.getInstance().addContinuousFileDownloading(blkChunkInfo, priority, initChunkSize, normalChunkSize, this);
            }
        }

        @Override
        public void onCompleted(long bytesReceived) {
            onCompletedOrCanceld(bytesReceived, false);
        }

        @Override
        public void onCanceled(long bytesReceived) {
            onCompletedOrCanceld(bytesReceived, true);
        }

        void onCompletedOrCanceld(long bytesReceived, boolean canceled) {
            Log.v(TAG, "FileDownloadTask.Callback : onCompleted(" + bytesReceived + ")");
            long downloadedSize = bytesReceived + blkChunkInfo.downloadedSize;
            if (downloadedSize > blkChunkInfo.size && blkChunkInfo.size > 0)
            {
                downloadedSize = blkChunkInfo.size;
            }
            blkChunkInfo.downloadedSize = downloadedSize;
//                Log.v(TAG, "FileDownloadTask.Callback : (downloaded/total) = (" + downloadedSize + "/" + blkChunkInfo.size + ")");
//                blkMedia = blkMedia.safeSave();

            synchronized (this)
            {
                transferCompleted = true;
                if (!gotFileSize)
                    return;
            }

//                downloadTasks.remove(taskWeakRef.get());
            if (blkChunkInfo.size <= blkChunkInfo.downloadedSize)
            {
//                    sendCallbackMessage(MsgDownloadProgressUpdated, blkChunkInfo.downloadedSize, blkChunkInfo.size, blkMedia);
//                    sendCallbackMessage(MsgDataSourceLocalUpdated, 0,0,null);
//                    setMediaDownloadStatus(blkMedia, MVMedia.MVMediaDownloadStatusFinished);
                onAllCompleted();
            }
            else if (!canceled)
            {
                MVCameraDownloadManger.getInstance().addContinuousFileDownloading(blkChunkInfo, priority, initChunkSize, normalChunkSize, this);
            }
        }

        public void onAllCompleted() {
        }

        @Override
        public void onError(String errMsg) {
            Log.e(TAG, "FileDownloadTask.Callback : onError : " + errMsg);
//                downloadTasks.remove(taskWeakRef.get());
//
//                if (MVCameraDownloadManger.FileDownloadTask.ErrorCanceled.equals(errMsg))
//                {
//                    setMediaDownloadStatus(blkMedia, MVMedia.MVMediaDownloadStatusStopped);
//                }
//                else
//                {
//                    setMediaDownloadStatus(blkMedia, MVMedia.MVMediaDownloadStatusError);
//                }
        }

        @Override
        public void onProgressUpdated(long totalBytes, long downloadedBytes) {
            Log.v(TAG, "FileDownloadTask.Callback : onProgressUpdated(" + totalBytes + ", " + downloadedBytes + ")");
//                sendCallbackMessage(MsgDownloadProgressUpdated, blkMedia.getDownloadedSize() + downloadedBytes, totalBytes, blkMedia);
        }

        private boolean gotFileSize = false;
        private boolean transferCompleted = false;

        private int priority = TASK_PRIORITY_HIGH;
        private int initChunkSize = DownloadInitChunkSize;
        private int normalChunkSize = DownloadChunkSize;
    };

    public static class DownloadChunkInfo {
        public DownloadChunkInfo(String cameraUUID, String remoteFilePath, String localFilePath, int size, int downloadedSize) {
            this.cameraUUID = cameraUUID;
            this.remoteFilePath = remoteFilePath;
            this.localFilePath = localFilePath;
            this.size = size;
            this.downloadedSize = downloadedSize;
        }

        public String localFilePathWithRemotePath() {
            String cameraUUID1 = cameraUUID;
            String remoteFilePath1 = remoteFilePath;
            if (cameraUUID1 != null)
            {
                cameraUUID1 = cameraUUID1.replace(':','_');
            }
            if (remoteFilePath1 != null)
            {
                remoteFilePath1 = remoteFilePath1.replace('/', '_');
            }
            return cameraUUID1 + remoteFilePath1;
        }

        String cameraUUID;
        String remoteFilePath;
        String localFilePath;
        long size = 0;
        long downloadedSize = 0;
    }

    public boolean addContinuousFileDownloading(DownloadChunkInfo chunkInfo) {
        return addContinuousFileDownloading(chunkInfo, TASK_PRIORITY_HIGH, null);
    }

    public boolean addContinuousFileDownloading(DownloadChunkInfo chunkInfo, int priority) {
        return addContinuousFileDownloading(chunkInfo, priority, 0, DownloadInitChunkSize, null);
    }

    public boolean addContinuousFileDownloading(DownloadChunkInfo chunkInfo, final int priority, int initChunkSize, int normalChunkSize) {
        return addContinuousFileDownloading(chunkInfo, priority, 0, DownloadInitChunkSize);
    }

    public boolean addContinuousFileDownloading(DownloadChunkInfo chunkInfo, FileDownloadCallback callback) {
        return addContinuousFileDownloading(chunkInfo, TASK_PRIORITY_HIGH, callback);
    }

    public boolean addContinuousFileDownloading(DownloadChunkInfo chunkInfo, int priority, FileDownloadCallback callback) {
        return addContinuousFileDownloading(chunkInfo, priority, 0, DownloadInitChunkSize, callback);
    }

    public boolean addContinuousFileDownloading(DownloadChunkInfo chunkInfo, final int priority, int initChunkSize, int normalChunkSize, FileDownloadCallback callback) {
        if (null == chunkInfo) return false;
        MVCameraDevice connectingDevice = MVCameraClient.getInstance().connectingCamera();
        if (connectingDevice == null || !connectingDevice.getUUID().equals(chunkInfo.cameraUUID))
        {
            return false;
        }

        long rangeStart, rangeLength;
        if (chunkInfo.size == 0)
        {
            rangeStart = 0;
            rangeLength = initChunkSize;
        }
        else
        {
            rangeStart = chunkInfo.downloadedSize;
            rangeLength = chunkInfo.size - chunkInfo.downloadedSize;
            if (rangeLength > normalChunkSize)
                rangeLength = normalChunkSize;
            else if (rangeLength == 0)
                return true;
        }

        if (chunkInfo.localFilePath == null || chunkInfo.localFilePath.isEmpty())
        {
            chunkInfo.localFilePath = Environment.getExternalStorageDirectory() + chunkInfo.localFilePathWithRemotePath();
//            media.setLocalPath(localPath);
//            media = media.safeSave();
//            Log.d(TAG, "Create local media : " + media);
//            setMediaDownloadStatus(media, MVMedia.MVMediaDownloadStatusPending);
        }

        MVCameraDownloadManger.FileDownloadTask downloadTask = new MVCameraDownloadManger.FileDownloadTask(priority, chunkInfo.remoteFilePath, rangeStart, (int)rangeLength, chunkInfo.localFilePath, null);
//        if (downloadTasks.contains(downloadTask))
//            return true;

        if (callback == null)
        {
            callback = new FileDownloadCallback(priority, initChunkSize, normalChunkSize);
        }
        callback.blkChunkInfo = chunkInfo;
        downloadTask.setCallback(callback);

//        downloadTasks.add(downloadTask);
        MVCameraDownloadManger.getInstance().addTask(downloadTask, true);

        return true;
    }
}
