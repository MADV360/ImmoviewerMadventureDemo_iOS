package com.madv360.madv.connection;

import android.text.TextUtils;
import android.util.Log;

import com.madv360.madv.common.Const;
import com.madv360.madv.connection.ambarequest.AMBAPutFileRequest;
import com.madv360.madv.connection.ambaresponse.AMBAFileTransferResultResponse;
import com.madv360.madv.connection.ambaresponse.AMBAPutFileResponse;
import com.madv360.madv.utils.MD5Util;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.lang.ref.WeakReference;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import bootstrap.appContainer.UserAppConst;

import com.madv360.madv.common.UiThreadExecutor;

/**
 * Created by wang yandong on 2016/9/20.
 */
public class MVCameraUploadManager {
    private static final int BUFFER_SIZE = 1024 * 1024;
    private static final int PROGRESS_MIN_STEP = 3;

    private static final ExecutorService worker = Executors.newSingleThreadExecutor();

    private static class MVCameraUploadManagerHolder {
        private static final MVCameraUploadManager INSTANCE = new MVCameraUploadManager();
    }

    public static final MVCameraUploadManager getInstance() {
        return MVCameraUploadManagerHolder.INSTANCE;
    }

    public void updateHardwareVersion(UpdateHardwareTask updateHardwareTask) {
        worker.execute(updateHardwareTask);
    }

    public void updateRemoterVersion(UpdateRemoterTask updateRemoterTask) {
        worker.execute(updateRemoterTask);
    }

    public static abstract class UploadTask implements Runnable {
        public String localPath;
        public String remotePath;

        public UploadTask(String localPath, String remotePath) {
            this.localPath = localPath;
            this.remotePath = remotePath;
        }

        public abstract void cancel();
    }

    public static class UpdateHardwareTask extends UploadTask implements CMDConnectManager.CMDConnectionObserver {
        private WeakReference<Callback> callbackRef;
        private boolean cancelUpdate = false;
        private int curProgress = 0;
        private AMBARequest.ResponseListener putFileListener = new AMBARequest.ResponseListener() {
            @Override
            public void onResponseReceived(AMBAResponse response) {
                AMBAPutFileResponse putFileResponse = (AMBAPutFileResponse) response;
                if (null != putFileResponse && putFileResponse.isRvalOK()) {
                    putFileToRemote();
                } else {
                    failCallback(putFileResponse.getRval());
                }
            }

            @Override
            public void onResponseError(AMBARequest request, int error, String msg) {
                failCallback(error);
            }
        };

        public UpdateHardwareTask(String localPath, String remotePath, Callback callback) {
            super(localPath, remotePath);
            this.callbackRef = new WeakReference<>(callback);
        }

        protected AMBAPutFileRequest putFileRequest = new AMBAPutFileRequest(putFileListener);

        private void putFileToRemote() {
            worker.execute(new Runnable() {
                public void run() {
                    OutputStream outputStream = DATAConnectManager.getInstance().getSocketOutputStream();
                    putFileToStream(localPath, outputStream);
                }
            });
        }

        private void putFileToStream(String srcPath, OutputStream outputStream) {
            long total = 0;
            long prev = 0;

            try {
                byte[] buffer = new byte[BUFFER_SIZE];
                File file = new File(srcPath);
                FileInputStream in = new FileInputStream(file);
                final long size = file.length();

                while (!cancelUpdate) {
                    int read = in.read(buffer);
                    if (read <= 0) {
                        break;
                    }

                    outputStream.write(buffer, 0, read);
                    total += read;
                    curProgress = (int) ((total * 100) / size);
                    if ((curProgress == 100) || (curProgress - prev >= PROGRESS_MIN_STEP)) {
                        progressCallback();
                        prev = curProgress;
                    }
                }
                in.close();

                if (cancelUpdate) {
                    AMBARequest cancelRequest = new AMBARequest(null);
                    cancelRequest.setMsg_id(AMBACommands.AMBA_MSGID_CANCEL_FILE_TRANSFER);
                    cancelRequest.setToken(MVCameraClient.getInstance().getToken());
                    cancelRequest.setParam(UserAppConst.HARDWARE_UPDATE_PATH);
                    CMDConnectManager.getInstance().sendRequest(cancelRequest);
                    cancelCallback();
                }
            } catch (Exception e) {
                e.printStackTrace();
                failCallback(-1);
            }
        }

        protected void completeCallback() {
            Log.d(Const.CallbackLogTag, "completeCallback");
            CMDConnectManager.getInstance().removeObserver(UpdateHardwareTask.this);
            UiThreadExecutor.runTask("UpdateHardwareTask", new Runnable() {
                @Override
                public void run() {
                    if (null != callbackRef && null != callbackRef.get()) {
                        callbackRef.get().onCompleted();
                    }
                }
            }, 0L);
        }

        protected void cancelCallback() {
            Log.d(Const.CallbackLogTag, "cancelCallback");
            CMDConnectManager.getInstance().removeObserver(UpdateHardwareTask.this);
            UiThreadExecutor.runTask("UpdateHardwareTask", new Runnable() {
                @Override
                public void run() {
                    if (null != callbackRef && null != callbackRef.get()) {
                        callbackRef.get().onCancel();
                    }
                }
            }, 0L);
        }

        protected void failCallback(final int errorCode) {
            Log.d(Const.CallbackLogTag, "failCallback");
            CMDConnectManager.getInstance().removeObserver(UpdateHardwareTask.this);
            UiThreadExecutor.runTask("UpdateHardwareTask", new Runnable() {
                @Override
                public void run() {
                    if (null != callbackRef && null != callbackRef.get()) {
                        callbackRef.get().onFailed(errorCode);
                    }
                }
            }, 0L);
        }

        protected void progressCallback() {
            Log.d(Const.CallbackLogTag, "progressCallback : " + curProgress);
            UiThreadExecutor.runTask("UpdateHardwareTask", new Runnable() {
                @Override
                public void run() {
                    if (null != callbackRef && null != callbackRef.get()) {
                        callbackRef.get().onProgress(curProgress);
                    }
                }
            }, 0L);
        }

        @Override
        public void run() {
            if (TextUtils.isEmpty(localPath) || TextUtils.isEmpty(remotePath)) {
                return;
            }

            File localFile = new File(localPath);
            if (!localFile.exists()) {
                return;
            }

            CMDConnectManager.getInstance().addObserver(this);

            putFileRequest.setMsg_id(AMBACommands.AMBA_MSGID_PUT_FILE);
            putFileRequest.setToken(MVCameraClient.getInstance().getToken());
            putFileRequest.setParam(remotePath);
            putFileRequest.offset = 0;
            putFileRequest.size = localFile.length();
            putFileRequest.md5sum = MD5Util.getMD5ForFile(localPath);
            putFileRequest.fType = AMBACommands.AMBA_UPLOAD_FILE_TYPE_FW;
            CMDConnectManager.getInstance().sendRequest(putFileRequest);
        }

        @Override
        public void cancel() {
            this.cancelUpdate = true;
        }

        @Override
        public void onConnectionStateChanged(int newState, int oldState, Object object) {

        }

        @Override
        public void onHeartbeatRequired() {

        }

        @Override
        public void onReceiveCameraResponse(AMBAResponse response) {
            if (response instanceof AMBAFileTransferResultResponse) {
                AMBAFileTransferResultResponse resultResponse = (AMBAFileTransferResultResponse) response;
                if (response.type.equals(AMBACommands.PUT_FILE_COMPLETE_TYPE)) {
                    long bytesReceived = resultResponse.getBytesReceived();
                    String md5sum = resultResponse.getMD5();
                    if (putFileRequest.size == bytesReceived
                            && putFileRequest.md5sum.equals(md5sum)) {
                        //update hardware
                        AMBARequest updateRequest = new AMBARequest(new AMBARequest.ResponseListener() {
                            @Override
                            public void onResponseReceived(AMBAResponse response) {
                                if (response.isRvalOK()) {
                                    completeCallback();
                                } else {
                                    failCallback(response.getRval());
                                }
                            }

                            @Override
                            public void onResponseError(AMBARequest request, int error, String msg) {
                                failCallback(error);
                            }
                        });
                        updateRequest.setMsg_id(AMBACommands.AMBA_MSGID_UPDATE_HARDWARE);
                        updateRequest.setToken(MVCameraClient.getInstance().getToken());
                        CMDConnectManager.getInstance().sendRequest(updateRequest);
                    } else {
                        failCallback(-1);
                    }
                }
            }
        }

        public interface Callback {
            void onCompleted();

            void onCancel();

            void onFailed(int errorCode);

            void onProgress(int progress);
        }
    }

    public static class UpdateRemoterTask extends UpdateHardwareTask {

        public UpdateRemoterTask(String localPath, String remotePath, Callback callback) {
            super(localPath, remotePath, callback);
        }

        @Override
        public void run() {
            if (TextUtils.isEmpty(localPath) || TextUtils.isEmpty(remotePath)) {
                return;
            }

            File localFile = new File(localPath);
            if (!localFile.exists()) {
                return;
            }

            CMDConnectManager.getInstance().addObserver(this);

            putFileRequest.setMsg_id(AMBACommands.AMBA_MSGID_PUT_FILE);
            putFileRequest.setToken(MVCameraClient.getInstance().getToken());
            putFileRequest.setParam(remotePath);
            putFileRequest.offset = 0;
            putFileRequest.size = localFile.length();
            putFileRequest.md5sum = MD5Util.getMD5ForFile(localPath);
            putFileRequest.fType = AMBACommands.AMBA_UPLOAD_FILE_TYPE_RW;
            CMDConnectManager.getInstance().sendRequest(putFileRequest);
        }

        @Override
        public void onReceiveCameraResponse(AMBAResponse response) {
            if (response instanceof AMBAFileTransferResultResponse) {
                AMBAFileTransferResultResponse resultResponse = (AMBAFileTransferResultResponse) response;
                if (response.type.equals(AMBACommands.PUT_FILE_COMPLETE_TYPE)) {
                    long bytesReceived = resultResponse.getBytesReceived();
                    String md5sum = resultResponse.getMD5();
                    if (putFileRequest.size == bytesReceived
                            && putFileRequest.md5sum.equals(md5sum)) {
                        completeCallback();
                    } else {
                        failCallback(-1);
                    }
                }
            }
        }
    }
}
