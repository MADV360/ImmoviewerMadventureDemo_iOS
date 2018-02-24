package com.madv360.madv.connection;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.ref.WeakReference;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketException;
import java.util.LinkedList;

import bootstrap.appContainer.ElephantApp;

/**
 * Created by wang yandong on 2016/5/24.
 */
public class DATAConnectManager {
    public static abstract class DataReceiver {
        protected abstract int onDataReceived(byte[] data, int offset, int length);

        protected abstract boolean isFinished();

        protected abstract void onError(int error, String errMsg);

        public void finish() {
            DATAConnectManager.getInstance().removeDataReceiver(this);
        }

        public DataReceiver() {
            recentReceiveTime = -1;
        }

        private long recentReceiveTime = -1;

        private int didReceiveData(byte[] data, int offset, int length) {
            recentReceiveTime = System.currentTimeMillis();
            return onDataReceived(data, offset, length);
        }
    }

    private static final String TAG = "QD:DataConnect";

    // 未连接
    public static final int SOCKET_STATE_NOT_READY = 1;
    // 开始连接server
    public static final int SOCKET_STATE_CONNECTING = 2;
    // 连接成功，正常发送接收中
    public static final int SOCKET_STATE_READY = 4;
    // 开始断开server
    public static final int SOCKET_STATE_DISCONNECTING = 8;

    public static final int ERROR_SOCKET_EXCEPTION = 1;
    public static final int ERROR_RECEIVING_TIMEOUT = 2;

    // Handler Messages :
    private static final int MSG_STATE_CHANGED = 10;
    private static final int MSG_RECEIVE_ERROR = 12;
    private static final int MSG_RECEIVE_TIMEOUT = 13;
    private static final int MSG_RECEIVER_EMPTIED = 14;

    //连接重试次数
    private static final int SOCKET_RETRY_TIMES_LIMIT = 5;
    private static final int RECEIVE_TIMEOUT_LIMIT = 15 * 1000;
    private static final int BUFFER_SIZE = 1024 * 1024;

    private static class DATAConnectManagerHolder {
        private static final DATAConnectManager INSTANCE = new DATAConnectManager();
    }

    public static final DATAConnectManager getInstance() {
        return DATAConnectManagerHolder.INSTANCE;
    }

    private DATAConnectManager() {
        Looper looper = Looper.getMainLooper();
        this.mCallbackHandler = new CallbackHandler(new WeakReference(this), looper);
        this.mContext = ElephantApp.getInstance().getApplicationContext();
        this.connectivityManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
    }

    private DataReceiver currentDataReceiver = null;

    //socket连接回调
    private final Handler mCallbackHandler;

    private String serverIP = AMBACommands.AMBA_CAMERA_IP;
    private int serverPort = AMBACommands.AMBA_CAMERA_DATA_PORT;
    private int connTimeout = AMBACommands.AMBA_CAMERA_TIMEOUT;

    private int connState = SOCKET_STATE_NOT_READY;

    private Socket tcpSocket = null;
    private InputStream socketInputStream = null;
    private OutputStream socketOutputStream = null;
    private byte[] receiveBuffer = new byte[BUFFER_SIZE];

    private Thread timeoutCheckThread = null;
    private Thread receiveDataThread = null;
    private Context mContext;
    private ConnectivityManager connectivityManager;

    //回调对象
    private LinkedList<WeakReference<DataConnectionObserver>> observers = new LinkedList<>();

    public interface DataConnectionObserver {
        void onDataConnectionStateChanged(int newState, int oldState, Object object);

        void onReceiverEmptied();
    }

    public void addObserver(DataConnectionObserver observerReference) {
        this.observers.add(new WeakReference<>(observerReference));
    }

    public void removeObserver(DataConnectionObserver observerReference) {
        int index = 0;
        for (WeakReference<DataConnectionObserver> ref : observers) {
            if (ref.get() == observerReference) {
                break;
            }
            index++;
        }
        if (index < observers.size()) {
            observers.remove(index);
        }
    }

    public int getState() {
        return connState;
    }

    public void setState(int newState) {
        synchronized (this) {
            Log.d(TAG, "setState() from " + StringFromState(connState) + " to " + StringFromState(newState));
            int oldState = connState;
            connState = newState;
            notifyAll();

            notifyStateChanged(newState, oldState, this);
        }
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
        }
        return "N/A";
    }

    public int waitForState(int state) {
        // Exit when: (state == 0 && connState == 0) || ((state & connState) !=
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

    public DataReceiver removeDataReceiver() {
        return removeDataReceiver(currentDataReceiver);
    }

    public DataReceiver removeDataReceiver(DataReceiver receiver) {
        DataReceiver ret = null;
        synchronized (this) {
            if (currentDataReceiver == receiver) {
                ret = currentDataReceiver;
                currentDataReceiver = null;
                notifyAll();

                Message msg = mCallbackHandler.obtainMessage(MSG_RECEIVER_EMPTIED);
                mCallbackHandler.sendMessage(msg);
            }
        }
        return ret;
    }

    public void setDataReceiver(DataReceiver receiver) {
        synchronized (this) {
            receiver.recentReceiveTime = System.currentTimeMillis();
            Log.e(TAG, "setDataReceiver(" + receiver + "): recentReceiveTime = " + receiver.recentReceiveTime);
            currentDataReceiver = receiver;
            notifyAll();
        }
    }

    public DataReceiver getDataReceiver() {
        return currentDataReceiver;
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

    public void closeConnection() {
        int currentState = getState();
        if (currentState == SOCKET_STATE_DISCONNECTING || currentState == SOCKET_STATE_NOT_READY) {
            return;
        } else if (currentState == SOCKET_STATE_CONNECTING) {
            new Thread() {
                @Override
                public void run() {
                    waitForState(SOCKET_STATE_READY);
                    setState(SOCKET_STATE_DISCONNECTING);
                    close(SOCKET_STATE_NOT_READY);
                }
            }.start();
        } else if (currentState == SOCKET_STATE_READY) {
            setState(SOCKET_STATE_DISCONNECTING);
            new Thread() {
                @Override
                public void run() {
                    close(SOCKET_STATE_NOT_READY);
                }
            }.start();
        }
    }

    /**
     * 是否已经建立了连接
     */
    public boolean isConnected() {
        return ((getState() == SOCKET_STATE_READY)
                && (null != receiveDataThread && receiveDataThread.isAlive()));
    }

    /**
     * 重新连接服务器
     */
    private void open() {
        int retryTimes = 0;
        while (retryTimes < SOCKET_RETRY_TIMES_LIMIT
                && getState() != SOCKET_STATE_DISCONNECTING) {
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
                socketInputStream = tcpSocket.getInputStream();
                socketOutputStream = tcpSocket.getOutputStream();

                receiveDataThread = new Thread(new ReceiveDataRunnable());
                receiveDataThread.start();

                if (null == timeoutCheckThread) {
                    timeoutCheckThread = new Thread(new TimeoutCheckRunnable());
                    timeoutCheckThread.start();
                }

                if (getState() != SOCKET_STATE_DISCONNECTING) {
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

        if (getState() != SOCKET_STATE_DISCONNECTING) {
            //建立socket连接失败
            setState(SOCKET_STATE_NOT_READY);
        }
    }

    /**
     * 关闭当前连接
     */
    private void close(int destState) {
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

//                //等待发送线程关闭
//                while (null != sendDataThread)
//                {
//                    try {
//                        wait();
//                    }
//                    catch (Exception ex) {
//                        ex.printStackTrace();
//                    }
//                }
                Log.v(TAG, "Before synchronized #0 @ DATAConnectManager$close");
                synchronized (this) {
                    Log.v(TAG, "Enter synchronized #0 @ DATAConnectManager$close");
                    //等待接收线程关闭
                    while (null != receiveDataThread) {
                        try {
                            wait();
                        } catch (Exception ex) {
                            ex.printStackTrace();
                        }
                    }

                    //等待超时检测线程关闭
                    while (null != timeoutCheckThread) {
                        try {
                            wait();
                        } catch (Exception ex) {
                            ex.printStackTrace();
                        }
                    }
                }
                Log.v(TAG, "After synchronized #0 @ DATAConnectManager$close");
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            setState(destState);
            removeDataReceiver();
        }
    }

    /**
     * 检测请求是否超时
     */
    private class TimeoutCheckRunnable implements Runnable {
        @Override
        public void run() {
            try {
                int state = waitForState(SOCKET_STATE_NOT_READY | SOCKET_STATE_READY);
                if (state != SOCKET_STATE_READY) {
                    return;
                }

                while (true) {
                    Log.v(TAG, "BEFORE synchronized @ TimeoutCheckRunnable#0");
                    synchronized (DATAConnectManager.this) {
                        Log.v(TAG, "ENTER synchronized @ TimeoutCheckRunnable#0");
                        while (currentDataReceiver == null && getState() == SOCKET_STATE_READY) {
                            try {
                                Log.e(TAG, "TimeoutCheckRunnable : Before wait");
                                DATAConnectManager.this.wait();
                            } catch (Exception ex) {
                                Log.e(TAG, "TimeoutCheckRunnable : Exception#0");
                                ex.printStackTrace();
                            }
                        }
                        Log.e(TAG, "TimeoutCheckRunnable : After wait");

                        if (getState() != SOCKET_STATE_READY) {
                            Log.e(TAG, "TimeoutCheckRunnable : Exit#0");
                            return;
                        }

                        if (currentDataReceiver.recentReceiveTime > 0 && System.currentTimeMillis() - currentDataReceiver.recentReceiveTime > RECEIVE_TIMEOUT_LIMIT) {
                            Log.e(TAG, "TimeoutCheckRunnable : Timeout on " + currentDataReceiver);
                            //closeConnection();

                            Message msg = mCallbackHandler.obtainMessage(MSG_RECEIVE_TIMEOUT, currentDataReceiver);
                            mCallbackHandler.sendMessage(msg);

                            currentDataReceiver = null;
                            msg = mCallbackHandler.obtainMessage(MSG_RECEIVER_EMPTIED);//Same effect as removeDataReceiver()
                            mCallbackHandler.sendMessage(msg);
                            Log.e(TAG, "TimeoutCheckRunnable : Exit#1");
                            return;
                        }
                    }
                    Log.v(TAG, "AFTER synchronized @ TimeoutCheckRunnable#0");
                    try {
                        Thread.sleep(5 * 1000);
                    } catch (InterruptedException ie) {
                        Log.e(TAG, "TimeoutCheckRunnable : Exception#1");
                        ie.printStackTrace();
                    }
                }
            } finally {
                Log.e(TAG, "TimeoutCheckRunnable : Finally");
                Log.v(TAG, "BEFORE synchronized @ TimeoutCheckRunnable#1");
                synchronized (DATAConnectManager.this) {
                    Log.v(TAG, "ENTER synchronized @ TimeoutCheckRunnable#1");
                    timeoutCheckThread = null;
                    DATAConnectManager.this.notifyAll();
                }
                Log.v(TAG, "AFTER synchronized @ TimeoutCheckRunnable#1");
            }
        }
    }

    public OutputStream getSocketOutputStream() {
        openConnection();
        if (DATAConnectManager.SOCKET_STATE_READY == waitForState(DATAConnectManager.SOCKET_STATE_READY))
            return socketOutputStream;
        else
            return null;
    }

    /**
     * 接收数据线程
     */
    private class ReceiveDataRunnable implements Runnable {
        public void run() {
            int readSize = 0;
            try {
                Log.d(TAG, "ReceiveDataRunnable : Before waitForState");
                int state = waitForState(SOCKET_STATE_READY | SOCKET_STATE_DISCONNECTING | SOCKET_STATE_NOT_READY);
                Log.d(TAG, "ReceiveDataRunnable : After waitForState");
                if (state != SOCKET_STATE_READY) {
                    Log.d(TAG, "ReceiveDataRunnable : Exit#0");
                    return;
                }

                do {
                    try {
                        if ((readSize = socketInputStream.read(receiveBuffer, 0, BUFFER_SIZE)) <= 0) {
                            break;
                        }
                    } catch (SocketException se) {
                        // 客户端主动socket.close()会调用这里
                        Log.d(TAG, "ReceiveDataRunnable : Exception#0 " + se.getMessage());
                        se.printStackTrace();
                        break;
                    } catch (IOException e) {
                        Log.d(TAG, "ReceiveDataRunnable : Exception#1 " + e.getMessage());
                        e.printStackTrace();
                        break;
                    } catch (Exception ex) {
                        Log.d(TAG, "ReceiveDataRunnable : Exception#2 " + ex.getMessage());
                        ex.printStackTrace();
                        break;
                    }

                    Log.v(TAG, "ReceiveDataRunnable : Socket read = " + readSize);
                    Log.v(TAG, "BEFORE synchronized @ ReceiveDataRunnable#0");
                    synchronized (DATAConnectManager.this) {
                        Log.v(TAG, "ENTER synchronized @ ReceiveDataRunnable#0");
                        if (null != currentDataReceiver) {
                            currentDataReceiver.didReceiveData(receiveBuffer, 0, readSize);

                            if (currentDataReceiver != null && currentDataReceiver.isFinished()) {
                                removeDataReceiver();///!!!Not Right!
                            }
                        }
                    }
                    Log.v(TAG, "AFTER synchronized @ ReceiveDataRunnable#0");
                }
                while (readSize > 0);

                Log.d(TAG, "ReceiveDataRunnable : finally#0 : readSize = " + readSize);
                closeConnection();
                DataReceiver receiver = removeDataReceiver();
                Message msg = mCallbackHandler.obtainMessage(MSG_RECEIVE_ERROR, receiver);
                mCallbackHandler.sendMessage(msg);
            } catch (Exception ex) {
                Log.d(TAG, "ReceiveDataRunnable : Exception#3 " + ex.getMessage());
                ex.printStackTrace();
            } finally {
                Log.d(TAG, "ReceiveDataRunnable : finally#1 ");
                Log.v(TAG, "BEFORE synchronized @ ReceiveDataRunnable#1");
                synchronized (DATAConnectManager.this) {
                    Log.d(TAG, "ENTER synchronized @ ReceiveDataRunnable#1");
                    receiveDataThread = null;
                    DATAConnectManager.this.notifyAll();
                }
                Log.v(TAG, "AFTER synchronized @ ReceiveDataRunnable#1");
            }
        }
    }

    private void onStateChanged(int newState, int oldState, Object object) {
        for (WeakReference<DataConnectionObserver> reference : observers) {
            DataConnectionObserver observer = reference.get();
            if (null != observer) {
                observer.onDataConnectionStateChanged(newState, oldState, object);
            }
        }
    }

    private void onReceiverEmptied() {
        for (WeakReference<DataConnectionObserver> reference : observers) {
            DataConnectionObserver observer = reference.get();
            if (null != observer) {
                observer.onReceiverEmptied();
            }
        }
    }

    private static class CallbackHandler extends Handler {
        private final WeakReference<DATAConnectManager> connectionManagerWeakReference;

        public CallbackHandler(WeakReference<DATAConnectManager> connectionManager, Looper looper) {
            super(looper);
            this.connectionManagerWeakReference = connectionManager;
        }

        public void handleMessage(Message msg) {
            DATAConnectManager connectionManager = this.connectionManagerWeakReference.get();
            if (null != connectionManager) {
                try {
                    switch (msg.what) {
                        case MSG_STATE_CHANGED:
                            connectionManager.onStateChanged(msg.arg1, msg.arg2, msg.obj);
                            break;
                        case MSG_RECEIVE_ERROR:
                            if (msg.obj != null) {
                                DataReceiver receiver = (DataReceiver) msg.obj;
                                receiver.onError(ERROR_SOCKET_EXCEPTION, "SocketError");
                            }
                            break;
                        case MSG_RECEIVE_TIMEOUT:
                            if (msg.obj != null) {
                                DataReceiver receiver = (DataReceiver) msg.obj;
                                receiver.onError(ERROR_RECEIVING_TIMEOUT, "ReceivingTimeOut");
                            }
                            break;
                        case MSG_RECEIVER_EMPTIED:
                            connectionManager.onReceiverEmptied();
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
}
