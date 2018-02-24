package com.madv360.madv.connection.ambarequest;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBARequest;
import com.madv360.madv.connection.ambaresponse.AMBAGetFileResponse;

/**
 * Created by qiudong on 16/6/25.
 */
public class AMBAGetFileRequest extends AMBARequest {
    public AMBAGetFileRequest(ResponseListener responseListener) {
        super(responseListener, AMBAGetFileResponse.class);
    }

    @Expose
    public String offset;

    @Expose
    public long fetch_size;
}
