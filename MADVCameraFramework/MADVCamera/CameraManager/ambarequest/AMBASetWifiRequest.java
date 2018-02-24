package com.madv360.madv.connection.ambarequest;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBARequest;
import com.madv360.madv.connection.AMBAResponse;

/**
 * Created by qiudong on 16/7/11.
 */
public class AMBASetWifiRequest extends AMBARequest {
    public AMBASetWifiRequest(ResponseListener responseListener) {
        super(responseListener, AMBAResponse.class);
    }

    @Expose
    public String ssid;

    @Expose
    public String passwd;
}
