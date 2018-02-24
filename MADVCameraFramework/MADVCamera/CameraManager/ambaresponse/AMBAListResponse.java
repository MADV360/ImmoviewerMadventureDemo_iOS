package com.madv360.madv.connection.ambaresponse;

import com.google.gson.annotations.Expose;
import com.madv360.madv.connection.AMBAResponse;

import java.util.List;
import java.util.Map;

/**
 * Created by qiudong on 16/6/28.
 */
public class AMBAListResponse extends AMBAResponse {
    @Expose
    public List<Map<String, String> > listing;
}
