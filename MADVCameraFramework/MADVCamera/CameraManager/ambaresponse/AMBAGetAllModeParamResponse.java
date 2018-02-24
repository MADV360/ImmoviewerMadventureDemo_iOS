package com.madv360.madv.connection.ambaresponse;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBAResponse;

/**
 * Created by wang yandong on 16/9/20.
 */
public class AMBAGetAllModeParamResponse extends AMBAResponse {
    @Expose
    private int status;

    @Expose
    private int mode;

    @Expose
    private int rec_time;

    @Expose
    private int second;

    @Expose
    private int lapse;

    @Expose
    private int timing;

    @Expose
    private int timing_c;

    public int getStatus() {
        return status;
    }

    public void setStatus(int status) {
        this.status = status;
    }

    public int getMode() {
        return mode;
    }

    public void setMode(int mode) {
        this.mode = mode;
    }

    public int getRec_time() {
        return rec_time;
    }

    public void setRec_time(int rec_time) {
        this.rec_time = rec_time;
    }

    public int getSecond() {
        return second;
    }

    public void setSecond(int second) {
        this.second = second;
    }

    public int getLapse() {
        return lapse;
    }

    public void setLapse(int lapse) {
        this.lapse = lapse;
    }

    public int getTiming() {
        return timing;
    }

    public void setTiming(int timing) {
        this.timing = timing;
    }

    public int getTiming_c() {
        return timing_c;
    }

    public void setTiming_c(int timing_c) {
        this.timing_c = timing_c;
    }
}
