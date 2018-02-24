package com.madv360.madv.connection.ambaresponse;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBAResponse;

/**
 * Created by qiudong on 16/6/25.
 */
public class AMBAGetFileResponse extends AMBAResponse {
    @Expose
    private long rem_size;

    public long getRemSize() {
        if (rem_size < 0)
            return (1L << 32) + rem_size;
        else
            return rem_size;
    }

    @Expose
    private int size;

    public long getSize() {
        if (size < 0)
            return (1L << 32) + size;
        else
            return size;
    }
}
