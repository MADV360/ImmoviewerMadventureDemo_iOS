package com.madv360.madv.connection.ambaresponse;

import com.madv360.madv.connection.AMBAResponse;

import java.util.ArrayList;
import java.util.Map;

/**
 * Created by qiudong on 16/6/25.
 */
public class AMBAFileTransferResultResponse extends AMBAResponse {
    public String getMD5() {
        ArrayList paramArray = (ArrayList) param;
        Map md5Map = (Map) paramArray.get(1);
        String md5 = (String) md5Map.get("md5sum");
        return md5;
    }

    public long getBytesSent() {
        ArrayList paramArray = (ArrayList) param;
        Map bytesSentMap = (Map) paramArray.get(0);
        Double dBytesSent = (Double) bytesSentMap.get("bytes sent");
        double bytesSent = (null == dBytesSent ? 0 : dBytesSent);
        return (long) bytesSent;
    }

    public long getBytesReceived() {
        ArrayList paramArray = (ArrayList) param;
        Map bytesReceiveMap = (Map) paramArray.get(0);
        Double dBytesReceive = (Double) bytesReceiveMap.get("bytes received");
        double bytesReceive = (null == dBytesReceive ? 0 : dBytesReceive);
        return (long) bytesReceive;
    }
}
