package com.madv360.madv.connection.ambaresponse;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBAResponse;

import java.util.Map;

/**
 * Created by qiudong on 16/6/16.
 */
public class AMBAGetWiFiStatusResponse extends AMBAResponse {
    public String MAC() {
        Map resultMap = (Map)param;
        return (String) resultMap.get("MAC");
    }

    public String SSID() {
        Map resultMap = (Map)param;
        return (String) resultMap.get("SSID");
    }
}
