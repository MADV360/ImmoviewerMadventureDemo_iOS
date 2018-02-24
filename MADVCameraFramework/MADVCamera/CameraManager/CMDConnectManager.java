package com.madv360.madv.connection;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkInfo;
import android.net.wifi.ScanResult;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.madv360.madv.common.Const;
import com.madv360.madv.connection.ambaresponse.AMBACancelFileTransferResponse;
import com.madv360.madv.connection.ambaresponse.AMBAFileTransferResultResponse;
import com.madv360.madv.connection.ambaresponse.AMBASaveMediaFileDoneResponse;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.ref.WeakReference;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketException;
import java.nio.charset.Charset;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;

import bootstrap.appContainer.ElephantApp;

/**
 * Created by wang yandong on 2016/3/25.
 */
public class CMDConnectManager implements WiFiConnectManager.WiFiActionCallBack {
    private static final String TAG = "QD:CMDConnect";

    // 未连接
    public static final int SOCKET_STATE_NOT_READY = 1;
    // 开始连接server
    public static final int SOCKET_STATE_CONNECTING = 2;
    // 连接成功，正常发送接收中
    public static final int SOCKET_STATE_READY = 4;
    // 开始断开server
    public static final int SOCKET_STATE_DISCONNECTING = 8;
    // 重连第1步：断开
    public static final int SOCKET_STATE_RECONNECTING_STEPO = 16;
    // 重连第2步：重连
    public static final int SOCKET_STATE_RECONNECTING_STEP1 = 32;

    // Handler Messages :

    private static final int MSG_STATE_CHANGED = 10;

    private static final int MSG_RESPONSE_RECEIVED = 11;

    private static final int MSG_RESPONSE_ERROR = 12;

    private static final int MSG_REQUEST_HEARTBEAT = 13;

    //连接重试次数
    private static final int SOCKET_RETRY_TIMES_LIMIT = 5;
    private static final int RESPONSE_TIMEOUT_LIMIT = 15 * 1000;
    private static final int BUFFER_SIZE = 64 * 1024;

    private static final long MAX_NON_MONITORED_TIME_INTERVAL_MILLS = 7000L;

    private static class CMDConnectManagerHolder {
        private static final CMDConnectManager INSTANCE = new CMDConnectManager();
    }

    public static final CMDConnectManager getInstance() {
        return CMDConnectManagerHolder.INSTANCE;
    }

    @Override
    public void finalize() {
        WiFiConnectManager.getInstance().unregisterCallBack(this);
    }

    private CMDConnectManager() {
        Looper looper = Looper.getMainLooper();
        this.mCallbackHandler = new CallbackHandler(new WeakReference(this), looper);
        this.mResponseHandler = new ResponseHandler(new WeakReference(this), looper);
        this.mContext = ElephantApp.getInstance().getApplicationContext();
        this.connectivityManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        WiFiConnectManager.getInstance().registerCallBack(this);
    }

    //待发送消息的请求队列
    private LinkedBlockingQueue<AMBARequest> waitSendRequestQueue = new LinkedBlockingQueue<>();
    //待接收响应消息的请求
    private ConcurrentHashMap<String, AMBARequest> waitResponseRequestMap = new ConcurrentHashMap<>();
    //响应消息队列
    private LinkedBlockingQueue<AMBAResponse> responseQueue = new LinkedBlockingQueue<>();
    //获取到响应消息的请求队列
    private ConcurrentHashMap<String, AMBARequest> responseReceivedRequestMap = new ConcurrentHashMap<>();
    //超时的请求队列
    private LinkedBlockingQueue<AMBARequest> timeoutRequestQueue = new LinkedBlockingQueue<>();
    //发生其它异常的请求队列
    private LinkedBlockingQueue<AMBARequest> exceptionRequestQueue = new LinkedBlockingQueue<>();

    //socket连接回调
    private final Handler mCallbackHandler;
    private final ResponseHandler mResponseHandler;

    private String serverIP = AMBACommands.AMBA_CAMERA_IP;
    private int serverPort = AMBACommands.AMBA_CAMERA_COMMAND_PORT;
    private int connTimeout = AMBACommands.AMBA_CAMERA_TIMEOUT;
    private int connState = SOCKET_STATE_NOT_READY;

    private Socket tcpSocket = null;
    private OutputStream socketOutputStream = null;
    private InputStream socketInputStream = null;
    private int msgReadBufferOffset = 0;
    private byte[] msgReadBuffer = new byte[BUFFER_SIZE];

    private Thread timeoutCheckThread = null;
    private Thread sendMsgThread = null;
    private Thread receiveMsgThread = null;
    private Context mContext;
    private ConnectivityManager connectivityManager;

    private long latestMonitoredTimeMills = -1;

    //回调对象
    private LinkedList<WeakReference<CMDConnectionObserver>> observers = new LinkedList<>();

    public interface CMDConnectionObserver {
        void onConnectionStateChanged(int newState, int oldState, Object object);

        void onReceiveCameraResponse(AMBAResponse response);

        void onHeartbeatRequired();
    }

    public synchronized void addObserver(CMDConnectionObserver observerReference) {
        this.observers.add(new WeakReference<>(observerReference));
    }

    public synchronized void removeObserver(CMDConnectionObserver observerReference) {
        int index = 0;
        for (WeakReference<CMDConnectionObserver> ref : observers) {
            if (ref.get() == observerReference) {
                break;
            }
            index++;
        }
        if (index < observers.size()) {
            observers.remove(index);
        }
    }

    public synchronized int getState() {
        return connState;
    }

    public synchronized void setState(int newState, Object object) {
        synchronized (this) {
            Log.d(TAG, "setState() from " + StringFromState(connState) + " to " + StringFromState(newState));
            int oldState = connState;
            connState = newState;
            notifyAll();
            notifyStateChanged(newState, oldState, object);
        }
    }

    public void setState(int newState) {
        setState(newState, null);
    }

    public static final String StringFromState(int state) {
        switch (state) {
            case SOCKET_STATE_CONNECTING:
                return "SOCKET_STATE_CONNECTING";
            case SOCKET_STATE_DISCONNECTING:
                return "SOCKET_STATE_DISCONNECTING";
            case SOCKET_STATE_NOT_READY:
                return "SOCKET_STATE_NOT_READY";
            case SOCKET_STATE_READY:
                return "SOCKET_STATE_READY";
            case SOCKET_STATE_RECONNECTING_STEPO:
                return "SOCKET_STATE_RECONNECTING_STEPO";
            case SOCKET_STATE_RECONNECTING_STEP1:
                return "SOCKET_STATE_RECONNECTING_STEP1";
        }
        return "N/A";
    }

    public int waitForState(int state) {
        // Exit when: (state == 0 && connState == 0) || ((state & connState) != 0)
        synchronized (this) {
            while ((state != 0 || connState != 0) && ((state & connState) == 0)) {
                try {
                    wait();
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        }
        return connState;
    }

    public void notifyStateChanged(int newState, int oldState, Object object) {
        Message msg = mCallbackHandler.obtainMessage(MSG_STATE_CHANGED);
        msg.arg1 = newState;
        msg.arg2 = oldState;
        msg.obj = object;
        mCallbackHandler.sendMessage(msg);
    }

    /**
     * 连接服务器
     */
    public void openConnection() {
        //建立socket连接
        int currentState = getState();
        if (currentState == SOCKET_STATE_CONNECTING || currentState == SOCKET_STATE_READY) {
            return;
        } else if (currentState == SOCKET_STATE_DISCONNECTING) {
            new Thread() {
                @Override
                public void run() {
                    waitForState(SOCKET_STATE_NOT_READY);
                    //重建连接
                    setState(SOCKET_STATE_CONNECTING);
                    open();
                }
            }.start();

        } else if (currentState == SOCKET_STATE_NOT_READY) {
            setState(SOCKET_STATE_CONNECTING);
            new Thread() {
                @Override
                public void run() {
                    open();
                }
            }.start();
        }
    }

    public void closeConnection(Object reason) {
        int currentState = getState();
        if (currentState == SOCKET_STATE_DISCONNECTING) {
            return;
        } else if (currentState == SOCKET_STATE_NOT_READY) {
//            setState(SOCKET_STATE_NOT_READY, reason);
            return;
        } else if (currentState == SOCKET_STATE_CONNECTING) {
            final Object blkReason = reason;
            new Thread() {
                @Override
                public void run() {
                    int state = waitForState(SOCKET_STATE_READY | SOCKET_STATE_NOT_READY);
                    if (state == SOCKET_STATE_READY) {
                        setState(SOCKET_STATE_DISCONNECTING);
                        close(SOCKET_STATE_NOT_READY, blkReason);
                    }
                }
            }.start();
        } else if (currentState == SOCKET_STATE_READY) {
            final Object blkReason = reason;
            setState(SOCKET_STATE_DISCONNECTING);
            new Thread() {
                @Override
                public void run() {
                    close(SOCKET_STATE_NOT_READY, blkReason);
                }
            }.start();
        }
    }

    public void reconnect() {
        switch (getState()) {
            case SOCKET_STATE_NOT_READY:
                setState(SOCKET_STATE_CONNECTING);
                open();
                break;
            case SOCKET_STATE_CONNECTING:
                break;
            case SOCKET_STATE_READY:
                setState(SOCKET_STATE_RECONNECTING_STEPO);
                close(SOCKET_STATE_RECONNECTING_STEP1, null);
                open();
                break;
            case SOCKET_STATE_DISCONNECTING:
                waitForState(SOCKET_STATE_NOT_READY);
                setState(SOCKET_STATE_CONNECTING);
                open();
                break;
            case SOCKET_STATE_RECONNECTING_STEPO:
                break;
            case SOCKET_STATE_RECONNECTING_STEP1:
                break;
        }
    }

    public void reconnectAsync() {
        new Thread() {
            public void run() {
                reconnect();
            }
        }.start();
    }

    /**
     * 是否已经建立了连接
     */
    public synchronized boolean isConnected() {
        return ((getState() == SOCKET_STATE_READY)
                && (null != sendMsgThread && sendMsgThread.isAlive())
                && (null != receiveMsgThread && receiveMsgThread.isAlive()));
    }

    /**
     * 重新连接服务器
     */
    private void open() {
        int retryTimes = 0;
        while (retryTimes < SOCKET_RETRY_TIMES_LIMIT
                && getState() != SOCKET_STATE_DISCONNECTING
                && getState() != SOCKET_STATE_RECONNECTING_STEPO) {
            try {
                tcpSocket = new Socket();
                if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                    Network wifiNetwork = null;
                    Network[] networks = this.connectivityManager.getAllNetworks();
                    for (Network network : networks) {
                        NetworkInfo networkInfo = this.connectivityManager.getNetworkInfo(network);
                        if (ConnectivityManager.TYPE_WIFI == networkInfo.getType()) {
                            wifiNetwork = network;
                            break;
                        }
                    }
                    if (null != wifiNetwork) {
                        wifiNetwork.bindSocket(tcpSocket);
                    }
                }
                tcpSocket.connect(new InetSocketAddress(serverIP, serverPort), connTimeout);
                socketOutputStream = tcpSocket.getOutputStream();
                socketInputStream = tcpSocket.getInputStream();

                sendMsgThread = new Thread(new SendRequestRunnable());
                receiveMsgThread = new Thread(new ReceiveResponseRunnable());
                sendMsgThread.start();
                receiveMsgThread.start();

                if (null == timeoutCheckThread) {
                    timeoutCheckThread = new Thread(new TimeoutCheckRunnable());
                    timeoutCheckThread.start();
                }

                if (getState() != SOCKET_STATE_DISCONNECTING
                        && getState() != SOCKET_STATE_RECONNECTING_STEPO) {
                    //建立socket连接成功
                    setState(SOCKET_STATE_READY);
                }
                return;
            } catch (Exception e) {
                Log.e(TAG, "open : Exception : " + e.getMessage());
                try {
                    Thread.sleep(2000);
                } catch (InterruptedException e1) {
                    e1.printStackTrace();
                }
                retryTimes++;
                continue;
            }
        }

        //建立socket连接失败
        clearOnDisconnected();
        setState(SOCKET_STATE_NOT_READY);
    }

    /**
     * 关闭当前连接
     */
    private void close(int destState, Object reason) {
        try {
            if (getState() != SOCKET_STATE_NOT_READY) {
                //关闭socket对象
                try {
                    if (null != tcpSocket) {
                        tcpSocket.close();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                } finally {
                    tcpSocket = null;
                }

                //关闭输出流对象
                try {
                    if (null != socketOutputStream) {
                        socketOutputStream.close();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                } finally {
                    socketOutputStream = null;
                }

                //关闭输入流对象
                try {
                    if (null != socketInputStream) {
                        socketInputStream.close();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                } finally {
                    socketInputStream = null;
                }

                //等待发送线程关闭
                synchronized (this) {
                    while (null != sendMsgThread) {
                        try {
                            wait();
                        } catch (Exception ex) {
                            ex.printStackTrace();
                        }
                    }

                    //等待接收线程关闭
                    while (null != receiveMsgThread) {
                        try {
                            wait();
                        } catch (Exception ex) {
                            ex.printStackTrace();
                        }
                    }
                }
//                //关闭超时检测线程
//                try {
//                    if (null != timeoutCheckThread && timeoutCheckThread.isAlive()) {
//                        timeoutCheckThread.interrupt();
//                    }
//                } catch (Exception e) {
//                    e.printStackTrace();
//                } finally {
//                    timeoutCheckThread = null;
//                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (destState == SOCKET_STATE_NOT_READY) {
                clearOnDisconnected();
            }

            setState(destState, reason);
        }
    }

    private void clearOnDisconnected() {
        synchronized (this) {
            Iterator<ConcurrentHashMap.Entry<String, AMBARequest>> iterator = waitResponseRequestMap.entrySet().iterator();
            while (iterator.hasNext()) {
                ConcurrentHashMap.Entry<String, AMBARequest> entry = iterator.next();
                AMBARequest request = entry.getValue();
                exceptionRequestQueue.add(request);
            }
            waitResponseRequestMap.clear();

            waitSendRequestQueue.clear();

            AMBARequest request;
            while ((request = waitSendRequestQueue.poll()) != null) {
                exceptionRequestQueue.add(request);
            }

            responseQueue.clear();
                /*
                Message responseTimeoutMsg = mResponseHandler.obtainMessage(MSG_RESPONSE_ERROR);
                mResponseHandler.sendMessage(responseTimeoutMsg);
                /*/
            mResponseHandler.handleMessage(MSG_RESPONSE_ERROR);

            notifyAll();
            //*/
        }
    }

    /**
     * 发送请求到服务器。当上一个请求还未响应或超时时，则返回失败
     */
    public synchronized boolean trySendRequest(AMBARequest request) {
        if (waitResponseRequestMap.size() > 0) {
            return false;
        }

        boolean ret = waitSendRequestQueue.add(request);
        if (ret) {
            notifyAll();
        }

        return ret;
    }

    /**
     * 发送请求到服务器。当上一个请求还未响应或超时时，不管不顾
     */
    public synchronized boolean sendRequest(AMBARequest request) {
        Log.d(TAG, "sendRequest : " + request);
        boolean ret = waitSendRequestQueue.add(request);
        if (ret) {
            notifyAll();
        }
        return ret;
    }

    /**
     * 取消请求
     */
    public synchronized boolean cancelRequest(AMBARequest request) {
        return waitSendRequestQueue.remove(request);
    }

    public void updateLatestMonitoredTime(long mills) {
        if (mills > latestMonitoredTimeMills) {
            latestMonitoredTimeMills = mills;
        }
    }

    /**
     * 检测请求是否超时
     */
    private class TimeoutCheckRunnable implements Runnable {
        @Override
        public void run() {
            latestMonitoredTimeMills = System.currentTimeMillis();

            while (true) {
                synchronized (CMDConnectManager.this) {
                    Iterator<ConcurrentHashMap.Entry<String, AMBARequest>> iterator = waitResponseRequestMap.entrySet().iterator();
                    while (iterator.hasNext()) {
                        ConcurrentHashMap.Entry<String, AMBARequest> entry = iterator.next();
                        AMBARequest request = entry.getValue();
                        if ((System.currentTimeMillis() - request.getTimestamp()) > RESPONSE_TIMEOUT_LIMIT) {
                            timeoutRequestQueue.add(request);
                        }
                    }

                    if (timeoutRequestQueue.size() > 0) {
                        for (AMBARequest request : timeoutRequestQueue) {
                            waitResponseRequestMap.remove(request.getRequestKey());
                        }
                        /*
                        Message responseTimeoutMsg = mResponseHandler.obtainMessage(MSG_RESPONSE_ERROR);
                        mResponseHandler.sendMessage(responseTimeoutMsg);
                        /*/
                        mResponseHandler.handleMessage(MSG_RESPONSE_ERROR);
                        //*/
                    }

                    CMDConnectManager.this.notifyAll();
                }

                if (System.currentTimeMillis() - latestMonitoredTimeMills > MAX_NON_MONITORED_TIME_INTERVAL_MILLS) {
                    mResponseHandler.handleMessage(MSG_REQUEST_HEARTBEAT);
                }

                try {
                    Thread.sleep(2000);
                } catch (InterruptedException ie) {
                    ie.printStackTrace();
                }
            }
        }
    }

    /**
     * 发送请求线程
     */
    private class SendRequestRunnable implements Runnable {
        public void run() {
            try {
                Gson gson = new GsonBuilder()
                        .excludeFieldsWithoutExposeAnnotation()
                        .disableHtmlEscaping()
                        .create();

                int state = waitForState(SOCKET_STATE_READY | SOCKET_STATE_NOT_READY | SOCKET_STATE_DISCONNECTING | SOCKET_STATE_RECONNECTING_STEPO);
                if (state != SOCKET_STATE_READY) {
                    return;
                }

                while (true) {
                    AMBARequest requestItem = null;
                    boolean shouldPending = false;
                    synchronized (CMDConnectManager.this) {
                        while (null == requestItem) {
                            while ((waitSendRequestQueue.size() == 0 || shouldPending)
                                    && (getState() != SOCKET_STATE_NOT_READY && getState() != SOCKET_STATE_DISCONNECTING && getState() != SOCKET_STATE_RECONNECTING_STEPO && null != socketOutputStream)) {
                                shouldPending = false;
                                try {
                                    CMDConnectManager.this.wait();
                                } catch (Exception ex) {
                                    ex.printStackTrace();
                                }
                            }

                            state = getState();
                            if (state == SOCKET_STATE_NOT_READY || state == SOCKET_STATE_DISCONNECTING || state == SOCKET_STATE_RECONNECTING_STEPO || null == socketOutputStream) {
                                return;
                            }

                            // Check if there is any AMBARequest in waitResponseRequestMap that has the same msg_id with it:
                            if (waitResponseRequestMap.size() > 0) {
                                for (AMBARequest requestToSend : waitSendRequestQueue) {
                                    /*
                                    if (requestToSend.shouldWaitUntilPreviousResponded)
                                    {
                                        boolean notAvailable = false;

                                        Iterator<ConcurrentHashMap.Entry<String, AMBARequest>> iterator = waitResponseRequestMap.entrySet().iterator();
                                        while (iterator.hasNext())
                                        {
                                            ConcurrentHashMap.Entry<String, AMBARequest> entry = iterator.next();
                                            AMBARequest requestPending = entry.getValue();
                                            if (null != requestPending && null != requestToSend)
                                            {
                                                if (requestPending.getMsg_id() == requestToSend.getMsg_id())
                                                {
                                                    notAvailable = true;
                                                    break;
                                                }
                                            }
                                        }

                                        if (!notAvailable)
                                        {
                                            requestItem = requestToSend;
                                            break;
                                        }
                                    }
                                    else
                                    {
                                        requestItem = requestToSend;
                                        break;
                                    }
                                    /*/
                                    if (!requestToSend.shouldWaitUntilPreviousResponded) {
                                        requestItem = requestToSend;
                                        break;
                                    }
                                    //*/
                                }
                            } else {
                                requestItem = waitSendRequestQueue.peek();
                            }

                            shouldPending = (null == requestItem);
                        }
                    }

                    String jsonString = gson.toJson(requestItem);
                    try {
                        socketOutputStream.write(jsonString.getBytes(Charset.forName("US-ASCII")));
                        socketOutputStream.flush();
                        Log.v(Const.CallbackLogTag, "request:" + jsonString + ", (" + requestItem + ")");
                        synchronized (CMDConnectManager.this) {
                            waitSendRequestQueue.remove(requestItem);
                            long timeMills = System.currentTimeMillis();
                            requestItem.setTimestamp(timeMills);
                            updateLatestMonitoredTime(timeMills);

                            if (requestItem.getResponseListener() != null || requestItem.shouldWaitUntilPreviousResponded) {
                                waitResponseRequestMap.put(requestItem.getRequestKey(), requestItem);
                            }
                        }
                    } catch (SocketException se) {
                        se.printStackTrace();
                        Log.e(TAG, "SendRequestRunnable : SocketException : " + se.getMessage());
                        if (getState() == SOCKET_STATE_READY) {
                            Log.e(TAG, "SendRequestRunnable : SocketException : reconnect");
                            reconnectAsync();
                        }

                        return;
                    } catch (Exception e) {
                        e.printStackTrace();
                        Log.e(TAG, "SendRequestRunnable : Exception : " + e.getMessage());
                        if (getState() == SOCKET_STATE_READY) {
                            Log.e(TAG, "SendRequestRunnable : Exception : reconnect");
                            reconnectAsync();
                        }
                        return;
                    }
                }
            } finally {
                synchronized (CMDConnectManager.this) {
                    sendMsgThread = null;
                    CMDConnectManager.this.notifyAll();
                }
            }
        }
    }

    /**
     * 提取json字符串
     *
     * @param str
     * @param strLen
     */
    private void extractJSONAndDispatch(byte[] str, int strLen) {
        int lastEndIndex = -1;
        int startIndex = 0;
        int leftBrackets = 0;
        boolean receivedNewResponse = false;
        Gson gson = new GsonBuilder()
                .excludeFieldsWithoutExposeAnnotation()
                .disableHtmlEscaping()
                .create();
        for (int i = 0; i < strLen; i++) {
            byte c = str[i];
            if ('{' == c) {
                if (0 == leftBrackets++) {
                    startIndex = i;
                }
            } else if ('}' == c) {
                if (leftBrackets != 0 && 0 == --leftBrackets) {
                    if (!receivedNewResponse) {
                        receivedNewResponse = true;
                    }
                    byte nextChar = str[i + 1];
                    str[i + 1] = '\0';
                    String jsonString = new String(str, startIndex, i + 1 - startIndex);
                    Log.v(Const.CallbackLogTag, "response:" + jsonString);
                    AMBAResponse baseResponse = gson.fromJson(jsonString, AMBAResponse.class);
                    synchronized (this) {
                        AMBARequest request = waitResponseRequestMap.remove(baseResponse.getRequestKey());
                        if (null != request) {
                            Log.v(TAG, "Request found:" + request + " for response:" + jsonString);
                            Class<? extends AMBAResponse> responseClass = request.getResponseClass();
                            if (null == responseClass) responseClass = AMBAResponse.class;

                            AMBAResponse response = gson.fromJson(jsonString, responseClass);
                            responseQueue.add(response);
                            responseReceivedRequestMap.put(request.getRequestKey(), request);

                            this.notifyAll();///!!! 20160818
                        } else {
                            Log.v(TAG, "No request for response:" + jsonString);
                            Class<? extends AMBAResponse> responseClass = responseClassOfMsgID(baseResponse.getMsg_id());
                            if (null == responseClass) responseClass = AMBAResponse.class;

                            AMBAResponse response = gson.fromJson(jsonString, responseClass);
                            responseQueue.add(response);
                        }
                    }
                    str[i + 1] = nextChar;
                    lastEndIndex = i;
                }
            }
        }

        if (lastEndIndex > 0) {
            System.arraycopy(msgReadBuffer, lastEndIndex + 1, msgReadBuffer, 0, BUFFER_SIZE - lastEndIndex - 1);
            msgReadBufferOffset -= (lastEndIndex + 1);
        }

        if (receivedNewResponse) {
            Log.v(TAG, "receivedNewResponse : sendMessage MSG_RESPONSE_RECEIVED");
            /*
            Message responseReceivedMsg = mResponseHandler.obtainMessage(MSG_RESPONSE_RECEIVED);
            mResponseHandler.sendMessage(responseReceivedMsg);
            /*/
            mResponseHandler.handleMessage(MSG_RESPONSE_RECEIVED);
            //*/
        }
    }

    static Map<Integer, Class<? extends AMBAResponse>> responseClassMap = null;

    private static synchronized Class<? extends AMBAResponse> responseClassOfMsgID(int msgID) {
        if (null == responseClassMap) {
            responseClassMap = new ConcurrentHashMap<>();
            responseClassMap.put(AMBACommands.AMBA_MSGID_CANCEL_FILE_TRANSFER, AMBACancelFileTransferResponse.class);
            responseClassMap.put(AMBACommands.AMBA_MSGID_FILE_TRANSFER_RESULT, AMBAFileTransferResultResponse.class);
            responseClassMap.put(AMBACommands.AMBA_MSGID_SAVE_VIDEO_DONE, AMBASaveMediaFileDoneResponse.class);
            responseClassMap.put(AMBACommands.AMBA_MSGID_SAVE_PHOTO_DONE, AMBASaveMediaFileDoneResponse.class);
        }
        Class<? extends AMBAResponse> clazz = responseClassMap.get(msgID);
        return clazz;
    }

    /**
     * 接收数据线程
     */
    private class ReceiveResponseRunnable implements Runnable {
        public void run() {
            int readSize = 0;
            try {
                int state = waitForState(SOCKET_STATE_READY | SOCKET_STATE_NOT_READY | SOCKET_STATE_DISCONNECTING | SOCKET_STATE_RECONNECTING_STEPO);
                if (state != SOCKET_STATE_READY) {
                    return;
                }

                do {
                    try {
                        if ((readSize = socketInputStream.read(msgReadBuffer, msgReadBufferOffset, BUFFER_SIZE - msgReadBufferOffset)) <= 0) {
                            break;
                        }
                    } catch (SocketException se) {
                        // 客户端主动socket.close()会调用这里
                        se.printStackTrace();
                        Log.e(TAG, "ReceiveResponseRunnable : SocketException : " + se.getMessage());
                        break;
                    } catch (Exception ex) {
                        ex.printStackTrace();
                        Log.e(TAG, "ReceiveResponseRunnable : Exception : " + ex.getMessage());
                        break;
                    }

                    updateLatestMonitoredTime(System.currentTimeMillis());

                    msgReadBuffer[msgReadBufferOffset + readSize] = '\0';
                    msgReadBufferOffset += readSize;
                    //解析JSON并通知处理
                    extractJSONAndDispatch(msgReadBuffer, msgReadBufferOffset);
                }
                while (readSize > 0);

                if (getState() == SOCKET_STATE_READY) {
                    Log.e(TAG, "ReceiveResponseRunnable : Finally reconnect , readSize = " + readSize);
                    reconnectAsync();
                }
                return;
            } finally {
                synchronized (CMDConnectManager.this) {
                    receiveMsgThread = null;
                    CMDConnectManager.this.notifyAll();
                }
            }
        }
    }

    private void onReceiveCameraResponse(AMBAResponse response) {
        //通知回调
        LinkedList<WeakReference<CMDConnectionObserver>> copiedObservers = new LinkedList<>(observers);
        for (WeakReference<CMDConnectionObserver> reference : copiedObservers) {
            CMDConnectionObserver observer = reference.get();
            if (null != observer) {
                observer.onReceiveCameraResponse(response);
            }
        }
    }

    private void onRequestHeartbeat() {
        //通知回调
        LinkedList<WeakReference<CMDConnectionObserver>> copiedObservers = new LinkedList<>(observers);
        for (WeakReference<CMDConnectionObserver> reference : copiedObservers) {
            CMDConnectionObserver observer = reference.get();
            if (null != observer) {
                observer.onHeartbeatRequired();
            }
        }
    }

    private void onResponseReceived() {
        Log.v(TAG, "Main$onResponseReceived");
        AMBAResponse responseItem = responseQueue.poll();
        while (null != responseItem) {
            Log.v(TAG, "Main$onResponseReceived : response = " + responseItem);
            AMBARequest requestItem = responseReceivedRequestMap.remove(responseItem.getRequestKey());
            Log.v(TAG, "Main$onResponseReceived : request = " + requestItem);
            if (null != requestItem) {
                if (null != requestItem.getResponseListener()) {
                    requestItem.getResponseListener().onResponseReceived(responseItem);
                }
            } else {
                //相机主动发送的消息
                onReceiveCameraResponse(responseItem);
            }
            responseItem = responseQueue.poll();
        }
        synchronized (this) {
            notifyAll();
        }
    }

    private void onResponseError() {
        if (null != timeoutRequestQueue) {
            AMBARequest requestItem = timeoutRequestQueue.poll();
            while (null != requestItem) {
                if (null != requestItem.getResponseListener()) {
                    requestItem.getResponseListener().onResponseError(requestItem, AMBARequest.ERROR_TIMEOUT, "TimeOut");
                }

                requestItem = timeoutRequestQueue.poll();
            }
        }

        if (null != exceptionRequestQueue) {
            AMBARequest requestItem = exceptionRequestQueue.poll();
            while (null != requestItem) {
                if (null != requestItem.getResponseListener()) {
                    requestItem.getResponseListener().onResponseError(requestItem, AMBARequest.ERROR_EXCEPTION, "Exception");
                }

                requestItem = exceptionRequestQueue.poll();
            }
        }
    }

    private void onStateChanged(int newState, int oldState, Object object) {
        LinkedList<WeakReference<CMDConnectionObserver>> copiedObservers = new LinkedList<>(observers);
        for (WeakReference<CMDConnectionObserver> reference : copiedObservers) {
            CMDConnectionObserver observer = reference.get();
            if (null != observer) {
                observer.onConnectionStateChanged(newState, oldState, object);
            }
        }
    }

    private static class CallbackHandler extends Handler {
        private final WeakReference<CMDConnectManager> connectionManagerWeakReference;

        public CallbackHandler(WeakReference<CMDConnectManager> connectionManager, Looper looper) {
            super(looper);
            this.connectionManagerWeakReference = connectionManager;
        }

        public void handleMessage(Message msg) {
            CMDConnectManager connectionManager = this.connectionManagerWeakReference.get();
            if (null != connectionManager) {
                try {
                    switch (msg.what) {
                        case MSG_STATE_CHANGED:
                            connectionManager.onStateChanged(msg.arg1, msg.arg2, msg.obj);
                            break;
                        default:
                            break;
                    }
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        }
    }

    private static class ResponseHandler extends Handler {
        private final WeakReference<CMDConnectManager> connectionManagerWeakReference;

        public ResponseHandler(WeakReference<CMDConnectManager> connectionManager, Looper looper) {
            super(looper);
            this.connectionManagerWeakReference = connectionManager;
        }

        public void handleMessage(Message msg) {
            /*
            CMDConnectManager connectionManager = this.connectionManagerWeakReference.get();
            if (null != connectionManager) {
                try
                {
                    switch (msg.what) {
                        case MSG_RESPONSE_RECEIVED:
                            connectionManager.onResponseReceived();
                            break;
                        case MSG_RESPONSE_ERROR:
                            connectionManager.onResponseError();
                            break;
                        default:
                            break;
                    }
                }
                catch (Exception ex)
                {
                    Log.e(TAG, "ResponseHandler:" + ex.getMessage());
                    ex.printStackTrace();
                }
            }
            else
            {
                Log.e(TAG, "null == connectionManager");
            }
            /*/
            handleMessage(msg.what);
            //*/
        }

        public void handleMessage(int what) {
            CMDConnectManager connectionManager = this.connectionManagerWeakReference.get();
            if (null != connectionManager) {
                try {
                    switch (what) {
                        case MSG_RESPONSE_RECEIVED:
                            connectionManager.onResponseReceived();
                            break;
                        case MSG_RESPONSE_ERROR:
                            connectionManager.onResponseError();
                            break;
                        case MSG_REQUEST_HEARTBEAT:
                            connectionManager.onRequestHeartbeat();
                            break;
                        default:
                            break;
                    }
                } catch (Exception ex) {
                    Log.e(TAG, "ResponseHandler:" + ex.getMessage());
                    ex.printStackTrace();
                }
            } else {
                Log.e(TAG, "null == connectionManager");
            }
        }
    }

    @Override
    public void onEnabled() {

    }

    @Override
    public void onDisabled() {

    }

    @Override
    public void onConnected(String extraInfo) {

    }

    @Override
    public void onDisconnected(String extraInfo) {
        if (null != tcpSocket) {
            try {
                tcpSocket.close();
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
    }

    @Override
    public void onScanResult(boolean resultsUpdated, List<ScanResult> scanResults) {

    }

    @Override
    public void onConnectDeviceSuccess(String deviceSSID, boolean configFromOthers) {

    }

    @Override
    public void onConnectDeviceFail(String deviceSSID, boolean isAuthError, boolean isConnectOthers, boolean configFromOthers) {

    }
}
