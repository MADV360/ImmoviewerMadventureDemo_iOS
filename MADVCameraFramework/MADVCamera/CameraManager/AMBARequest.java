package com.madv360.madv.connection;

import com.google.gson.annotations.Expose;

import java.io.Serializable;
import java.lang.ref.WeakReference;

/**
 * Created by wang yandong on 2016/3/25.
 */
public class AMBARequest implements Serializable {
    private ResponseListener responseListener;
    private Class<? extends AMBAResponse> responseClass;

    public AMBARequest(ResponseListener responseListener, Class<? extends AMBAResponse> responseClass) {
        this.responseListener = responseListener;
        this.responseClass = responseClass;
    }

    public AMBARequest(ResponseListener responseListener) {
        this(responseListener, AMBAResponse.class);
    }

    @Expose
    private int token;

    @Expose
    private int msg_id;

    @Expose
    private String type;

    @Expose
    private String param;

    private long timestamp;

    public Class<? extends AMBAResponse> getResponseClass() {return responseClass;}

    //token的get和set
    public int getToken() {
        return token;
    }

    public void setToken(int token) {
        this.token = token;
    }

    //msg_id的get和set
    public int getMsg_id() {
        return msg_id;
    }

    public void setMsg_id(int msg_id) {
        this.msg_id = msg_id;
    }

    public String getRequestKey() {
        return Integer.toString(this.msg_id);
    }

    //type的get和set
    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    //param的get和set
    public String getParam() {
        return param;
    }

    public void setParam(String param) {
        this.param = param;
    }

    //timestamp的get和set
    public long getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }

    //weakResponseListener的get和set
    public void setResponseListener(ResponseListener responseListener) {
        this.responseListener = responseListener;
    }

    public boolean shouldWaitUntilPreviousResponded = true;

    public ResponseListener getResponseListener() {
        return this.responseListener;
    }

    public static final int ERROR_TIMEOUT = 10000;
    public static final int ERROR_EXCEPTION = 10001;

    public interface ResponseListener {
        void onResponseReceived(AMBAResponse response);

        void onResponseError(AMBARequest request, int error, String msg);
    }

    @Override
    public String toString() {
        return "AMBARequest(" + hashCode() + ") : msgID=" + msg_id + ", token=" + token + ", param=" + param;
    }
}
