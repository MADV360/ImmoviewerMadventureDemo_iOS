package com.madv360.madv.connection.ambaresponse;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBAResponse;

/**
 * Created by wang yandong on 16/9/20.
 */
public class AMBASaveMediaFileDoneResponse extends AMBAResponse {
    @Expose
    private int remain_video;

    @Expose
    private int remain_jpg;

    @Expose
    private int sd_total;

    @Expose
    private int sd_free;

    @Expose
    private int sd_full;

    public int getRemain_video() {
        return remain_video;
    }

    public void setRemain_video(int remain_video) {
        this.remain_video = remain_video;
    }

    public int getRemain_jpg() {
        return remain_jpg;
    }

    public void setRemain_jpg(int remain_jpg) {
        this.remain_jpg = remain_jpg;
    }

    public int getSd_total() {
        return sd_total;
    }

    public void setSd_total(int sd_total) {
        this.sd_total = sd_total;
    }

    public int getSd_free() {
        return sd_free;
    }

    public void setSd_free(int sd_free) {
        this.sd_free = sd_free;
    }

    public int getSd_full() {
        return sd_full;
    }

    public void setSd_full(int sd_full) {
        this.sd_full = sd_full;
    }
}
