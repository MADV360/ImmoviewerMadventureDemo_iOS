package com.madv360.madv.connection.ambarequest;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBARequest;
import com.madv360.madv.connection.ambaresponse.AMBAPutFileResponse;

/**
 * Created by wang yandong on 16/9/20.
 */
public class AMBAPutFileRequest extends AMBARequest {
    public AMBAPutFileRequest(ResponseListener responseListener) {
        super(responseListener, AMBAPutFileResponse.class);
    }

    @Expose
    public long offset;

    @Expose
    public long size;

    @Expose
    public String md5sum;

    @Expose
    public int fType;
}
