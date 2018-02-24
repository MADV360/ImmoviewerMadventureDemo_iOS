package com.madv360.madv.connection.ambaresponse;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBAResponse;

import java.util.ArrayList;
import java.util.Map;

/**
 * Created by qiudong on 16/6/25.
 */
public class AMBACancelFileTransferResponse extends AMBAResponse {
    @Expose
    protected int transferred_size;

    public String getMD5() {
//        ArrayList paramArray = (ArrayList) param;
//        Map md5Map = (Map) paramArray.get(1);
//        String md5 = (String) md5Map.get("md5sum");
//        return md5;
        return "N/A";
    }

    public int getBytesSent() {
//        ArrayList paramArray = (ArrayList) param;
//        Map bytesSentMap = (Map) paramArray.get(0);
//        double bytesSent = (Double) bytesSentMap.get("transferred_size");
//        return (int)bytesSent;
        return transferred_size;
    }
}
