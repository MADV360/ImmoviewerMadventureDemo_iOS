package com.madv360.madv.connection;

/**
 * Created by wang yandong on 2016/3/25.
 */
public class AMBACommands {
    //会话标识
    public static final int AMBA_SESSION_TOKEN_INIT = 0;
    public static int AMBA_SESSION_TOKEN = AMBA_SESSION_TOKEN_INIT;

    //成功标识
    public static final int AMBA_COMMAND_OK = 0;
    public static final int AMBA_NOTIFICATION_OK = 0x80;

    public static final int AMBA_RVAL_START_SESSION_DENIED = -3;

    public static final String SSID_TAG = "AP_SSID=";
    public static final String PASSWORD_TAG = "AP_PASSWD=";
    public static final String APPUBLIC_TAG = "AP_PUBLIC=";
    public static final String BACKSLASH_PATH_HEAD_TAG = "C:";
    public static final String SLASH_PATH_HEAD_TAG = "/tmp/SD0";
    //JPEG缩略图
    public static final String GET_THUMB_TYPE_THUMB = "thumb";
    //JPEG全图
    public static final String GET_THUMB_TYPE_FULLVIEW = "fullview";
    public static final String GET_STORAGE_TYPE_TOTAL = "total";
    public static final String GET_STORAGE_TYPE_FREE = "free";
    //H.264的第一帧数据
    public static final String GET_THUMB_TYPE_IDR = "idr";
    public static final String GET_FILE_COMPLETE_TYPE = "get_file_complete";
    public static final String GET_FILE_FAILED_TYPE = "get_file_fail";
    public static final String PUT_FILE_COMPLETE_TYPE = "put_file_complete";
    //实时预览流
    public static final String AMBA_CAMERA_RTSP_URL_ROOT = "rtsp://192.168.42.1";
    public static final String AMBA_CAMERA_RTSP_LIVE_URL = AMBA_CAMERA_RTSP_URL_ROOT + "/live";
    public static final String AMBA_CAMERA_HTTP_URL_ROOT = "http://192.168.42.1:50422/";
    //相机IP地址
    public static final String AMBA_CAMERA_IP = "192.168.42.1";
    //相机命令端口
    public static final int AMBA_CAMERA_COMMAND_PORT = 7878;
    //相机数据端口
    public static final int AMBA_CAMERA_DATA_PORT = 8787;
    //socket超时时间
    public static final int AMBA_CAMERA_TIMEOUT = 8 * 1000;
    //会话类型
    public static final String AMBA_SESSION_TYPE = "TCP";
    //查询会话
    public static final int AMBA_MSGID_QUERY_SESSION_HOLDER = 1793;
    //启动会话命令ID
    public static final int AMBA_MSGID_START_SESSION = 257;
    //关闭会话命令ID
    public static final int AMBA_MSGID_STOP_SESSION = 258;
    public static final int AMBA_MSGID_RESET_VF = 259;
    public static final int AMBA_MSGID_STOP_VF = 260;
    //设置客户端信息命令ID
    public static final int AMBA_MSGID_SET_CLNT_INFO = 261;
    //获取缩略图命令ID
    public static final int AMBA_MSGID_GET_THUMB = 1025;
    //获取MEDIA_INFO
    public static final int AMBA_MSGID_GET_MEDIA_INFO = 1026;
    //重启WiFi
    public static final int AMBA_MSGID_WIFI_RESTART = 1537;
    //设置WiFi信息
    public static final int AMBA_MSGID_SET_WIFI_SETTING = 1538;
    //获取WiFi设置信息
    public static final int AMBA_MSGID_GET_WIFI_SETTING = 1539;
    //关闭WiFi
    public static final int AMBA_MSGID_WIFI_STOP = 1540;
    //启动WiFi
    public static final int AMBA_MSGID_WIFI_START = 1541;
    //获取WiFi状态
    public static final int AMBA_MSGID_GET_WIFI_STATUS = 1542;
    public static final int AMBA_MSGID_SET_PHOTO_MODE = 2307;
    public static final int AMBA_MSGID_SET_VIDEO_MODE = 2308;

    //开始常规录像命令
    public static final int AMBA_MSGID_START_VIDEO_NORMAL = 513;
    //停止录像命令
    public static final int AMBA_MSGID_STOP_VIDEO = 514;
    //获取录像时间ID
    public static final int AMBA_MSGID_GET_RECORD_TIME = 515;
    //拍照命令ID
    public static final int AMBA_MSGID_TAKE_PHOTO = 769;
    //秒拍摄影设置
    public static final int AMBA_MSGID_SET_VIDEO_MICRO_PARAM = 0x120A;
    //开始秒拍摄影
    public static final int AMBA_MSGID_START_VIDEO_MICRO = 0x120C;
    //延时摄影设置
    public static final int AMBA_MSGID_SET_VIDEO_SLOW_PARAM = 0x120D;
    //开始延时摄影
    public static final int AMBA_MSGID_START_VIDEO_SLOW = 0x120F;
    //循环录制失败
    public static final int AMBA_MSGID_START_LOOP_FAIL = 0x1212;
    //定时拍照设置
    public static final int AMBA_MSGID_SET_PHOTO_TIMING_PARAM = 0x1302;
    //开始定时拍照
    public static final int AMBA_MSGID_SHOOT_PHOTO_TIMING = 0x1304;
    //常规拍照
    public static final int AMBA_MSGID_SHOOT_PHOTO_NORMAL = 0x1300;

    public static final int AMBA_MSGID_SAVE_VIDEO_DONE = 0x2000;
    public static final int AMBA_MSGID_SAVE_PHOTO_DONE = 0x2001;
    public static final int AMBA_MSGID_MP4_FILE_SPLIT_DONE = 0x2003;

    public static final int AMBA_MSGID_GET_FILE = 1285;
    public static final int AMBA_MSGID_PUT_FILE = 1286;
    public static final int AMBA_MSGID_CANCEL_FILE_TRANSFER = 1287;

    public static final int AMBA_MSGID_FILE_TRANSFER_RESULT = 7;
    public static final int AMBA_MSGID_UPDATE_HARDWARE = 8;

    public static final int AMBA_MSGID_CD = 1283;
    public static final int AMBA_MSGID_LS = 1282;

    public static final int AMBA_MSGID_RTC_SYNC = 0x1803;//6147

    public static final int AMBA_MSGID_SET_CAMERA_MODE = 0x1203;
    public static final int AMBA_PARAM_CAMERA_MODE_VIDEO = 0;
    public static final int AMBA_PARAM_CAMERA_MODE_PHOTO = 1;

    public static final int AMBA_MSGID_SET_VIDEO_FILTER = 0x1201;

    public static final int AMBA_MSGID_SET_WHITEBALANCE = 0x1401;
    public static final int AMBA_PARAM_WHITEBALANCE_AUTO = 0;
    public static final int AMBA_PARAM_WHITEBALANCE_OUTDOOR = 1;
    public static final int AMBA_PARAM_WHITEBALANCE_SHADOW = 2;
    public static final int AMBA_PARAM_WHITEBALANCE_CLOUDY = 3;
    public static final int AMBA_PARAM_WHITEBALANCE_NIGHT = 4;

    public static final int AMBA_MSGID_SET_ISO = 0x1406;

    public static final int AMBA_MSGID_SET_SHUTTER = 0x1407;

    public static final int AMBA_MSGID_FORMAT_SD = 0x4;

    public static final int AMBA_MSGID_GET_SN = 0x1001;//4097

    public static final int AMBA_MSGID_GET_VENDOR = 0x1002;

    public static final int AMBA_MSGID_GET_DEVICE_NAME = 0x1003;

    public static final int AMBA_MSGID_GET_DEVICE_VERSION = 0x1004;

    public static final int AMBA_MSGID_IS_SDCARD_MOUNTED = 0x1101;//4353
    public static final int AMBA_PARAM_SDCARD_MOUNTED_YES = 1;
    public static final int AMBA_PARAM_SDCARD_MOUNTED_NO = 0;

    public static final int AMBA_MSGID_IS_SDCARD_FULL = 0x1102;//4354
    public static final int AMBA_PARAM_SDCARD_FULL_NO = 0;
    public static final int AMBA_PARAM_SDCARD_FULL_ALMOST = 1;
    public static final int AMBA_PARAM_SDCARD_FULL_YES = 2;
    public static final int AMBA_PARAM_SDCARD_FULL_UNKNOWN = 3;

    public static final int AMBA_MSGID_SDCARD_SLOWLY_WRITE = 0x1107;
    public static final int AMBA_MSGID_IS_SDCARD_NEED_FORMAT = 0x1108;
    public static final int AMBA_PARAM_SDCARD_NEED_FORMAT_NO = 0;
    public static final int AMBA_PARAM_SDCARD_NEED_FORMAT_YES = 1;

    public static final int AMBA_MSGID_GET_BATTERY_VOLUME = 0x1109;
    public static final int AMBA_PARAM_BATTERY_PERCENT5 = 0;
    public static final int AMBA_PARAM_BATTERY_PERCENT25 = 1;
    public static final int AMBA_PARAM_BATTERY_PERCENT50 = 2;
    public static final int AMBA_PARAM_BATTERY_PERCENT75 = 3;
    public static final int AMBA_PARAM_BATTERY_PERCENT100 = 4;
    public static final int AMBA_PARAM_BATTERY_CHARGE_FULL = 0x44;

    public static final int AMBA_MSGID_GET_CAMERA_STATE = 0x110A;//4362
    public static final int AMBA_PARAM_CAMERA_STATE_IDLE = 0;//空闲
    public static final int AMBA_PARAM_CAMERA_STATE_STANDBY = 1;//待机
    public static final int AMBA_PARAM_CAMERA_STATE_STORAGE = 2;//USB存储模式
    public static final int AMBA_PARAM_CAMERA_STATE_CAPTURING = 3;//正在摄像
    public static final int AMBA_PARAM_CAMERA_STATE_CAPTURING_MICRO = 4;//正在秒拍
    public static final int AMBA_PARAM_CAMERA_STATE_CAPTURING_SLOW = 5;//正在延时摄像
    public static final int AMBA_PARAM_CAMERA_STATE_PHOTOING = 6;//正在拍照
    public static final int AMBA_PARAM_CAMERA_STATE_PHOTOING_DELAYED = 7;//正在定时拍照

    public static final int AMBA_MSGID_GET_CAMERA_ALL_PARAM = 0x110B;//4363
    public static final int AMBA_MSGID_GET_CAMERA_ALL_SETTING_PARAM = 0x110C;//4364
    public static final int AMBA_MSGID_GET_CAMERA_ALL_MODE_PARAM = 0x110D;//4365

    public static final int AMBA_MSGID_DELETE_FILE = 1281;

    public static final int AMBA_MSGID_SET_WIFI_NEW = 0x1602;

    public static final int AMBA_MSGID_RESET_DEFAULT_PARAMS = 0x1809;
    public static final int AMBA_MSGID_RESET_DEFAULT_SETTINGS = 0x1808;

    public static final int AMBA_MSGID_WAKEUP_CAMERA = 0x180A;
    public static final int AMBA_MSGID_CLOSE_CAMERA = 0x180B;
    public static final int AMBA_MSGID_CAMERA_OVERHEATED = 0x180E;
    public static final int AMBA_MSGID_RECOVERY_MEDIA_FILE = 0x1811;
    public static final int AMBA_MSGID_DELETE_FILES_DONE = 0x1812;

    public static final int AMBA_MSGID_SET_AUTO_SHUTDOWN_TIME = 0x1807;//6151

    public static final int AMBA_MSGID_BEEPER_VOLUME = 0x1801;//6145
    public static final int AMBA_PARAM_BEEPER_OFF = 0;
    public static final int AMBA_PARAM_BEEPER_VOLUME_25P = 1;
    public static final int AMBA_PARAM_BEEPER_VOLUME_50P = 2;
    public static final int AMBA_PARAM_BEEPER_VOLUME_75P = 3;
    public static final int AMBA_PARAM_BEEPER_VOLUME_100P = 4;

    public static final int AMBA_MSGID_GET_STORAGE_TOTAL_FREE = 0x5;//5
    public static final int AMBA_MSGID_GET_VIDEO_CAPACITY = 0x1104;//4356
    public static final int AMBA_MSGID_GET_PHOTO_CAPACITY = 0x1105;//4357
    public static final int AMBA_MSGID_GET_STORAGE_ALL_STATE = 0x1106;//4358

    public static final int AMBA_RVAL_ERROR_INVALID_TOKEN = -4;
    public static final int AMBA_RVAL_ERROR_INVALID_OPERATION = -14;
    public static final int AMBA_RVAL_ERROR_SDCARD_FULL = -17;
    public static final int AMBA_RVAL_ERROR_BUSY = -21;
    public static final int AMBA_RVAL_ERROR_NO_SDCARD = -50;
    public static final int AMBA_RVAL_ERROR_WRONG_MODE = -56;
    public static final int AMBA_RVAL_ERROR_NO_FIRMWARE = -57;
    public static final int AMBA_RVAL_ERROR_LOW_BATTERY = -58;
    public static final int AMBA_RVAL_ERROR_SDCARD = -59;
    public static final int AMBA_RVAL_ERROR_INVALID_FILE_PATH = -26;

    public static final int AMBA_UPLOAD_FILE_TYPE_FW = 1;
    public static final int AMBA_UPLOAD_FILE_TYPE_RW = 2;
}
