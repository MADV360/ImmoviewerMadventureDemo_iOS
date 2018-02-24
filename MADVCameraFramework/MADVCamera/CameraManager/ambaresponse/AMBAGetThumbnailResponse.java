package com.madv360.madv.connection.ambaresponse;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBAResponse;

/**
 * Created by qiudong on 16/6/30.
 */
public class AMBAGetThumbnailResponse extends AMBAResponse {
    @Expose
    public String md5sum;

    @Expose
    public int size;
}
