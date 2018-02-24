package com.madv360.madv.connection;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.wifi.ScanResult;
import android.net.wifi.SupplicantState;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.text.TextUtils;
import android.util.Log;

import com.madv360.madv.R;
import com.madv360.madv.connection.WiFiConnectSecurities.ENUM_SECURITIES_TYPE;
import com.madv360.madv.model.MVCameraDevice;
import com.madv360.madv.utils.StringUtil;

import java.util.ArrayList;
import java.util.List;

import bootstrap.appContainer.ElephantApp;

/**
 * Created by wang yandong on 2016/3/28.
 */
public class WiFiConnectManager {
    private Context mContext;
    private WifiManager mWifiManager;
    private ConnectivityManager connectivityManager;

    private final IntentFilter mWiFiStateFilter;
    private final BroadcastReceiver mWiFiStateReceiver;
    private final IntentFilter mWifiScanFilter;
    private final BroadcastReceiver mWifiScanReceiver;
    private final IntentFilter mNetworkFilter;
    private final BroadcastReceiver mNetworkReceiver;

    private String SSIDPrefix;
    private String mConnectingSSID = null;
    private ENUM_SECURITIES_TYPE mConnectingSecuritiesType = null;
    private boolean mConnectingConfigFromOthers = false;
    private int mConnectingIndex = -1;
    private int mConnectingTimes = 0;
    private int mDisconnectTimes = 0;
    private static final int RetryConnectLimit = 2;
    private static final int DisconnectedLimit = 4;

    private static class WiFiConnectManagerHolder {
        private static final WiFiConnectManager INSTANCE = new WiFiConnectManager();
    }

    public static final WiFiConnectManager getInstance() {
        return WiFiConnectManagerHolder.INSTANCE;
    }

    private WiFiConnectManager() {
        mContext = ElephantApp.getInstance().getApplicationContext();
        SSIDPrefix = mContext.getString(R.string.camera_SSID_prefix);
        mWifiManager = (WifiManager) mContext.getSystemService(Context.WIFI_SERVICE);
        connectivityManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);

        mWiFiStateFilter = new IntentFilter();
        mWiFiStateFilter.addAction(WifiManager.WIFI_STATE_CHANGED_ACTION);
        mWiFiStateReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                handleWiFiStateBroadcast(intent);
            }
        };
        mContext.registerReceiver(mWiFiStateReceiver, mWiFiStateFilter);

        mWifiScanFilter = new IntentFilter();
        mWifiScanFilter.addAction(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION);
        mWifiScanReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                handleWiFiScanResultsBroadcast(intent);
            }
        };

        mNetworkFilter = new IntentFilter();
        mNetworkFilter.addAction(WifiManager.NETWORK_STATE_CHANGED_ACTION);
        mNetworkFilter.addAction(WifiManager.SUPPLICANT_STATE_CHANGED_ACTION);
        mNetworkReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                handleNetworkBroadcast(intent);
            }
        };
        mContext.registerReceiver(mNetworkReceiver, mNetworkFilter);
    }

    private List<WiFiActionCallBack> callBacks = new ArrayList<>();

    public void registerCallBack(WiFiActionCallBack callBack) {
        if (!this.callBacks.contains(callBack)) {
            this.callBacks.add(callBack);
        }
    }

    public void unregisterCallBack(WiFiActionCallBack callBack) {
        if (this.callBacks.contains(callBack)) {
            this.callBacks.remove(callBack);
        }
    }

    public boolean networkConnected() {
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        if (null != activeNetworkInfo && activeNetworkInfo.isConnected()) {
            if (MVCameraClient.getInstance().getState() == MVCameraClient.CameraClientStateConnected) {
                if (ConnectivityManager.TYPE_WIFI == activeNetworkInfo.getType()) {
                    //连接的是相机wifi
                    return false;
                } else {
                    return true;
                }
            } else {
                return true;
            }
        } else {
            return false;
        }
    }

    // 是否处于wifi环境下
    public boolean activeNetworkInfoIsWifi() {
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        if (null != activeNetworkInfo && activeNetworkInfo.isConnected()) {
            if (ConnectivityManager.TYPE_WIFI == activeNetworkInfo.getType()) {
                return true;
            }
        }
        return false;
    }

    // wifi是否打开
    public boolean isWiFiOpened() {
        return mWifiManager.isWifiEnabled();
    }

    //比较SSID
    public boolean isEqualsWithCurrentWiFi(String SSID) {
        WifiInfo currentWiFiInfo = mWifiManager.getConnectionInfo();
        if (isWiFiOpened()
                && !TextUtils.isEmpty(SSID)
                && null != currentWiFiInfo) {
            SupplicantState supplicantState = currentWiFiInfo.getSupplicantState();
            if (supplicantState != SupplicantState.COMPLETED) {
                return false;
            }

            String currentSSID = currentWiFiInfo.getSSID();
            if (!TextUtils.isEmpty(currentSSID)) {
                if ((currentSSID.startsWith("'") && currentSSID.endsWith("'"))
                        || (currentSSID.startsWith("\"") && currentSSID.endsWith("\""))) {
                    currentSSID = currentSSID.substring(1, currentSSID.length() - 1);
                }
            }

            if (SSID.equalsIgnoreCase(currentSSID)) {
                return true;
            }
        }
        return false;
    }

    public String getWiFiSSID() {
        WifiInfo currentWiFiInfo = mWifiManager.getConnectionInfo();
        if (null != currentWiFiInfo) {
            String SSID = currentWiFiInfo.getSSID().replace('\"', ' ').trim();
            return SSID;
        }
        return "";
    }

    // 得到本机ip地址
    public String getWiFiIP() {
        WifiInfo wifiInfo = mWifiManager.getConnectionInfo();
        if (mWifiManager.isWifiEnabled() && null != wifiInfo) {
            int ipAddress = wifiInfo.getIpAddress();
            return intToIp(ipAddress);
        }
        return "127.0.0.1";
    }

    // 打开WIFI
    public void openWiFi() {
        if (!mWifiManager.isWifiEnabled()) {
            mWifiManager.setWifiEnabled(true);
        }
    }

    // 关闭WIFI
    public void closeWiFi() {
        if (mWifiManager.isWifiEnabled()) {
            mWifiManager.setWifiEnabled(false);
        }
    }

    //扫描WiFi
    public void scanWiFi() {
        mContext.registerReceiver(mWifiScanReceiver, mWifiScanFilter);
        boolean result = mWifiManager.startScan();
        if (!result) {
            mContext.unregisterReceiver(mWifiScanReceiver);
            this.onScanResult(false, null);
        }
    }

    /**
     * Connect to a WiFi with the given ssid and password
     *
     * @param ssid
     * @param password
     */
    public boolean connectWiFi(String ssid, String password, ENUM_SECURITIES_TYPE type) {
        if (TextUtils.isEmpty(ssid) || TextUtils.isEmpty(password)) {
            return false;
        }

        // 检测热点是否已存在
        int wifiIndex = -1;
        mConnectingConfigFromOthers = false;
        WifiConfiguration customerWifiConfig = findExistConfiguration(ssid, type);
        if (customerWifiConfig != null) {
            if (ENUM_SECURITIES_TYPE.OPEN == type) {
                wifiIndex = customerWifiConfig.networkId;
            } else if (ENUM_SECURITIES_TYPE.WPA2 == type) {
                customerWifiConfig.preSharedKey = StringUtil.convertToQuotedString(password);
                wifiIndex = mWifiManager.updateNetwork(customerWifiConfig);
                mWifiManager.saveConfiguration();
                if (-1 == wifiIndex) {
                    mConnectingConfigFromOthers = true;
                    wifiIndex = customerWifiConfig.networkId;
                }
            }
        } else {
            customerWifiConfig = makeConfiguration(ssid, password, type);
            wifiIndex = mWifiManager.addNetwork(customerWifiConfig);
            mWifiManager.saveConfiguration();
        }

        boolean ret = false;
        if (-1 == wifiIndex) {
            return ret;
        }

        mWifiManager.disconnect();
        ret = mWifiManager.enableNetwork(wifiIndex, true);
        if (ret) {
            this.mConnectingSSID = ssid;
            this.mConnectingSecuritiesType = type;
            this.mConnectingIndex = wifiIndex;
        }
        return ret;
    }

    private boolean retryConnectWiFi() {
        boolean ret = false;
        if (-1 != this.mConnectingIndex) {
            ret = mWifiManager.enableNetwork(this.mConnectingIndex, true);
        }
        return ret;
    }

    private void onEnabled() {
        for (WiFiActionCallBack callBack : this.callBacks) {
            if (null != callBack) {
                callBack.onEnabled();
            }
        }
    }

    private void onDisabled() {
        for (WiFiActionCallBack callBack : this.callBacks) {
            if (null != callBack) {
                callBack.onDisabled();
            }
        }
    }

    private void onConnected(String extraInfo) {
        for (WiFiActionCallBack callBack : this.callBacks) {
            if (null != callBack) {
                callBack.onConnected(extraInfo);
            }
        }
    }

    private void onDisconnected(String extraInfo) {
        for (WiFiActionCallBack callBack : this.callBacks) {
            if (null != callBack) {
                callBack.onDisconnected(extraInfo);
            }
        }
    }

    private void onScanResult(boolean resultsUpdated, List<ScanResult> scanResults) {
        for (WiFiActionCallBack callBack : this.callBacks) {
            if (null != callBack) {
                callBack.onScanResult(resultsUpdated, scanResults);
            }
        }
    }

    private void onConnectDeviceSuccess(String deviceSSID) {
        this.mConnectingSSID = null;
        this.mConnectingSecuritiesType = null;
        this.mConnectingIndex = -1;
        this.mConnectingTimes = 0;
        this.mDisconnectTimes = 0;
        for (WiFiActionCallBack callBack : this.callBacks) {
            if (null != callBack) {
                callBack.onConnectDeviceSuccess(deviceSSID, mConnectingConfigFromOthers);
            }
        }
    }

    private void onConnectDeviceFail(String deviceSSID, boolean isAuthError, boolean isConnectOthers) {
        this.mConnectingSSID = null;
        this.mConnectingSecuritiesType = null;
        this.mConnectingIndex = -1;
        this.mConnectingTimes = 0;
        this.mDisconnectTimes = 0;
        for (WiFiActionCallBack callBack : this.callBacks) {
            if (null != callBack) {
                callBack.onConnectDeviceFail(deviceSSID, isAuthError, isConnectOthers, mConnectingConfigFromOthers);
            }
        }
    }

    private void handleWiFiStateBroadcast(Intent intent) {
        String action = intent.getAction();
        if (WifiManager.WIFI_STATE_CHANGED_ACTION.equals(action)) {
            int wifiState = intent.getIntExtra(WifiManager.EXTRA_WIFI_STATE, 0);
            switch (wifiState) {
                case WifiManager.WIFI_STATE_DISABLED:
                    this.onDisabled();
                    break;
                case WifiManager.WIFI_STATE_ENABLED:
                    this.onEnabled();
                    break;
                default:
                    break;
            }
        }
    }

    private void handleWiFiScanResultsBroadcast(Intent intent) {
        mContext.unregisterReceiver(mWifiScanReceiver);
        boolean resultsUpdated = intent.getBooleanExtra(WifiManager.EXTRA_RESULTS_UPDATED, false);
        List<ScanResult> scanResults = this.mWifiManager.getScanResults();
        this.onScanResult(resultsUpdated, scanResults);
    }

    private void handleNetworkBroadcast(Intent intent) {
        String action = intent.getAction();
        if (WifiManager.NETWORK_STATE_CHANGED_ACTION.equals(action)) {
            NetworkInfo networkInfo = intent.getParcelableExtra(WifiManager.EXTRA_NETWORK_INFO);
            if (null != networkInfo) {
                NetworkInfo.DetailedState detailedState = networkInfo.getDetailedState();
                if (NetworkInfo.DetailedState.DISCONNECTED == detailedState) {
                    String extraInfo = networkInfo.getExtraInfo();//SSID
                    this.onDisconnected(extraInfo);
                } else if (NetworkInfo.DetailedState.CONNECTED == detailedState) {
                    String extraInfo = networkInfo.getExtraInfo();//SSID
                    this.onConnected(extraInfo);
                }
            }
        } else if (WifiManager.SUPPLICANT_STATE_CHANGED_ACTION.equals(action)) {
            SupplicantState supplicantState = intent.getParcelableExtra(WifiManager.EXTRA_NEW_STATE);
            Log.d("NetworkBroadcast", "SUPPLICANT_STATE_CHANGED_ACTION : " + supplicantState.toString());
            if (SupplicantState.COMPLETED == supplicantState) {
                Log.d("NetworkBroadcast", "SUPPLICANT_STATE_CHANGED_ACTION : " + mWifiManager.getConnectionInfo().getSSID());
                if (!TextUtils.isEmpty(mConnectingSSID)) {
                    String quotedString = StringUtil.convertToQuotedString(mConnectingSSID);
                    boolean equalsWithCurrentWiFi = isEqualsWithCurrentWiFi(mConnectingSSID);
                    if (equalsWithCurrentWiFi) {
                        this.onConnectDeviceSuccess(quotedString);
                    } else {
                        this.mConnectingTimes++;
                        if (this.mConnectingTimes >= RetryConnectLimit) {
                            this.onConnectDeviceFail(quotedString, false, true);
                        } else {
                            this.retryConnectWiFi();
                        }
                    }
                }
            } else if (SupplicantState.DISCONNECTED == supplicantState) {
                if (!TextUtils.isEmpty(mConnectingSSID)) {
                    String quotedString = StringUtil.convertToQuotedString(mConnectingSSID);
                    int errorCode = intent.getIntExtra(WifiManager.EXTRA_SUPPLICANT_ERROR, 0);
                    if (errorCode == WifiManager.ERROR_AUTHENTICATING) {
                        Log.d("NetworkBroadcast", "SUPPLICANT_STATE_CHANGED_ACTION : " + "ERROR_AUTHENTICATING");
                        WifiConfiguration customerWifiConfig = findExistConfiguration(mConnectingSSID, mConnectingSecuritiesType);
                        if (null != customerWifiConfig) {
                            mWifiManager.removeNetwork(customerWifiConfig.networkId);
                            mWifiManager.saveConfiguration();
                        }
                        this.onConnectDeviceFail(quotedString, true, false);
                    } else {
                        this.mDisconnectTimes++;
                        if (this.mDisconnectTimes >= DisconnectedLimit) {
                            this.onConnectDeviceFail(quotedString, false, false);
                        }
                    }
                }
            }
        }
    }

    private WifiConfiguration makeConfiguration(String ssid, String password, ENUM_SECURITIES_TYPE type) {
        // 配置网络信息类
        WifiConfiguration customerWifiConfig = new WifiConfiguration();
        customerWifiConfig.allowedGroupCiphers.clear();
        customerWifiConfig.allowedKeyManagement.clear();
        customerWifiConfig.allowedPairwiseCiphers.clear();
        customerWifiConfig.allowedProtocols.clear();
        customerWifiConfig.allowedAuthAlgorithms.clear();

        customerWifiConfig.SSID = StringUtil.convertToQuotedString(ssid);
        if (ENUM_SECURITIES_TYPE.OPEN.value() == type.value()) {
            customerWifiConfig.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE);
        } else if (ENUM_SECURITIES_TYPE.WPA2.value() == type.value()) {
            customerWifiConfig.preSharedKey = StringUtil.convertToQuotedString(password);
            customerWifiConfig.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.TKIP);
            customerWifiConfig.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.CCMP);
            customerWifiConfig.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK);
            customerWifiConfig.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.TKIP);
            customerWifiConfig.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.CCMP);
            customerWifiConfig.allowedProtocols.set(WifiConfiguration.Protocol.RSN);
        }

        return customerWifiConfig;
    }

    public WifiConfiguration findExistConfiguration(String ssid, ENUM_SECURITIES_TYPE type) {
        if (this.mWifiManager.getConfiguredNetworks() == null || TextUtils.isEmpty(ssid)) {
            return null;
        }

        String quotedString = StringUtil.convertToQuotedString(ssid);
        List<WifiConfiguration> configuredNetworks = this.mWifiManager.getConfiguredNetworks();
        WifiConfiguration configuredNetwork = null;
        for (WifiConfiguration network : configuredNetworks) {
            ENUM_SECURITIES_TYPE netType = WiFiConnectSecurities.getWifiConfigurationSecurity(network);
            if (quotedString.equalsIgnoreCase(network.SSID)) {
                if (netType.value() == type.value()) {
                    configuredNetwork = network;
                    break;
                }
            }
        }

        return configuredNetwork;
    }

    public boolean removeExistConfiguration(String ssid, ENUM_SECURITIES_TYPE type) {
        boolean result = false;
        WifiConfiguration customerWifiConfig = findExistConfiguration(ssid, type);
        if (null != customerWifiConfig) {
            result = mWifiManager.removeNetwork(customerWifiConfig.networkId);
            mWifiManager.saveConfiguration();
        }
        return result;
    }

    public ScanResult findScanResult(String ssid) {
        if (this.mWifiManager.getScanResults() == null || TextUtils.isEmpty(ssid)) {
            return null;
        }

        List<ScanResult> scanResults = this.mWifiManager.getScanResults();
        ScanResult scanResult = null;
        for (ScanResult result : scanResults) {
            if (ssid.equalsIgnoreCase(result.SSID)) {
                scanResult = result;
                break;
            }
        }

        return scanResult;
    }

    public List<ScanResult> getScanResults() {
        return this.mWifiManager.getScanResults();
    }

    public List<ScanResult> getCameraScanResults() {
        List<ScanResult> scanResults = this.mWifiManager.getScanResults();
        List<MVCameraDevice> cameraDevices = MVCameraClient.getInstance().getAllStoredDevices();
        List<ScanResult> scanCameraResults = new ArrayList<>();
        for (ScanResult result : scanResults) {
            if (!TextUtils.isEmpty(result.SSID)
                    && result.SSID.startsWith(SSIDPrefix)) {
                boolean saved = false;
                for (MVCameraDevice cameraDevice : cameraDevices) {
                    if (result.SSID.equals(cameraDevice.getSSID())) {
                        saved = true;
                        break;
                    }
                }
                if (!saved) {
                    scanCameraResults.add(result);
                }
            }
        }
        return scanCameraResults;
    }

    private String intToIp(int i) {
        return (i & 0xFF) + "." +
                ((i >> 8) & 0xFF) + "." +
                ((i >> 16) & 0xFF) + "." +
                (i >> 24 & 0xFF);
    }

    public interface WiFiActionCallBack {

        void onEnabled();

        void onDisabled();

        void onConnected(String extraInfo);

        void onDisconnected(String extraInfo);

        void onScanResult(boolean resultsUpdated, List<ScanResult> scanResults);

        void onConnectDeviceSuccess(String deviceSSID, boolean configFromOthers);

        void onConnectDeviceFail(String deviceSSID, boolean isAuthError, boolean isConnectOthers, boolean configFromOthers);
    }
}
