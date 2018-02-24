package com.madv360.madv.connection.ambaresponse;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBAResponse;

/**
 * Created by wang yandong on 16/11/22.
 */
public class AMBAGetAllSettingParamResponse extends AMBAResponse {
    @Expose
    private int v_res;

    @Expose
    private int video_wb;

    @Expose
    private int video_ev;

    @Expose
    private int video_iso;

    @Expose
    private int video_shutter;

    @Expose
    private int loop;

    @Expose
    private int p_res;

    @Expose
    private int still_wb;

    @Expose
    private int still_ev;

    @Expose
    private int still_iso;

    @Expose
    private int still_shutter;

    @Expose
    private int buzzer;

    @Expose
    private int standby_en;

    @Expose
    private int standby_time;

    @Expose
    private int poweroff_en;

    @Expose
    private int poweroff_time;

    @Expose
    private int led;

    @Expose
    private int battery;

    @Expose
    private String product;

    @Expose
    private String sn;

    @Expose
    private String ver;

    @Expose
    private String md5;

    public int getV_res() {
        return v_res;
    }

    public void setV_res(int v_res) {
        this.v_res = v_res;
    }

    public int getVideo_wb() {
        return video_wb;
    }

    public void setVideo_wb(int video_wb) {
        this.video_wb = video_wb;
    }

    public int getVideo_ev() {
        return video_ev;
    }

    public void setVideo_ev(int video_ev) {
        this.video_ev = video_ev;
    }

    public int getVideo_iso() {
        return video_iso;
    }

    public void setVideo_iso(int video_iso) {
        this.video_iso = video_iso;
    }

    public int getVideo_shutter() {
        return video_shutter;
    }

    public void setVideo_shutter(int video_shutter) {
        this.video_shutter = video_shutter;
    }

    public int getLoop() {
        return loop;
    }

    public void setLoop(int loop) {
        this.loop = loop;
    }

    public int getP_res() {
        return p_res;
    }

    public void setP_res(int p_res) {
        this.p_res = p_res;
    }

    public int getStill_wb() {
        return still_wb;
    }

    public void setStill_wb(int still_wb) {
        this.still_wb = still_wb;
    }

    public int getStill_ev() {
        return still_ev;
    }

    public void setStill_ev(int still_ev) {
        this.still_ev = still_ev;
    }

    public int getStill_iso() {
        return still_iso;
    }

    public void setStill_iso(int still_iso) {
        this.still_iso = still_iso;
    }

    public int getStill_shutter() {
        return still_shutter;
    }

    public void setStill_shutter(int still_shutter) {
        this.still_shutter = still_shutter;
    }

    public int getBuzzer() {
        return buzzer;
    }

    public void setBuzzer(int buzzer) {
        this.buzzer = buzzer;
    }

    public int getStandby_en() {
        return standby_en;
    }

    public void setStandby_en(int standby_en) {
        this.standby_en = standby_en;
    }

    public int getStandby_time() {
        return standby_time;
    }

    public void setStandby_time(int standby_time) {
        this.standby_time = standby_time;
    }

    public int getPoweroff_en() {
        return poweroff_en;
    }

    public void setPoweroff_en(int poweroff_en) {
        this.poweroff_en = poweroff_en;
    }

    public int getPoweroff_time() {
        return poweroff_time;
    }

    public void setPoweroff_time(int poweroff_time) {
        this.poweroff_time = poweroff_time;
    }

    public int getLed() {
        return led;
    }

    public void setLed(int led) {
        this.led = led;
    }

    public int getBattery() {
        return battery;
    }

    public void setBattery(int battery) {
        this.battery = battery;
    }

    public String getProduct() {
        return product;
    }

    public void setProduct(String product) {
        this.product = product;
    }

    public String getSn() {
        return sn;
    }

    public void setSn(String sn) {
        this.sn = sn;
    }

    public String getVer() {
        return ver;
    }

    public void setVer(String ver) {
        this.ver = ver;
    }

    public String getMd5() {
        return md5;
    }

    public void setMd5(String md5) {
        this.md5 = md5;
    }
}
