package com.madv360.madv.connection.ambaresponse;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBAResponse;

/**
 * Created by qiudong on 16/7/7.
 */
public class AMBAGetMediaInfoResponse extends AMBAResponse {
    @Expose
    public int duration;

    @Expose
    private long size;

    public long getSize() {
        if (size < 0)
            return (1L << 32) + size;
        else
            return size;
    }
}
