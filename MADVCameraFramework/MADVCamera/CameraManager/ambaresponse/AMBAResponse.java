package com.madv360.madv.connection;

import com.google.gson.annotations.Expose;

import java.io.Serializable;
import java.util.List;
import java.util.Map;

/**
 * Created by wang yandong on 2016/3/25.
 */
public class AMBAResponse implements Serializable {
    public AMBAResponse() {

    }

    @Expose
    protected int token;

    @Expose
    protected int rval;

    @Expose
    protected int msg_id;

    @Expose
    protected String type;

    @Expose
    protected Object param;

    //token的get和set
    public int getToken() {
        return token;
    }

    public void setToken(int token) {
        this.token = token;
    }

    //rval的get和set
    public int getRval() {
        return rval;
    }

    public void setRval(int rval) {
        this.rval = rval;
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
    public Object getParam() {
        return param;
    }

    public void setParam(Object param) {
        this.param = param;
    }

    public boolean isRvalOK() {
        return rval == AMBACommands.AMBA_COMMAND_OK || rval == AMBACommands.AMBA_NOTIFICATION_OK;
    }

    @Override
    public String toString() {
        return "AMBAResponse(" + hashCode() + ") : rval=" + rval + ", msgID=" + msg_id + ", param=" + param + ", type=" + type + ", token=" + token;
    }
}
