package com.madv360.madv.media;

import java.util.Date;
import java.util.concurrent.ConcurrentHashMap;

import foundation.activeandroid.annotation.Column;
import foundation.activeandroid.annotation.Table;

/**
 * Created by qiudong on 16/6/27.
 */
@Table(name = "LocalMedias")
public class MVMediaImpl extends MVMedia {
    @Column(name = DB_KEY_MEDIATYPE)
    protected int mediaType = MediaTypeVideo;

    @Column(name = DB_KEY_CAMERAUUID)
    protected String cameraUUID;

    @Column(name = DB_KEY_REMOTEPATH)
    protected String remotePath;

    @Column(name = DB_KEY_LOCALPATH)
    protected String localPath;

    @Column(name = DB_KEY_THUMBNAILPATH)
    protected String thumbnailPath;

    @Column(name = DB_KEY_CREATEDATE)
    protected Date createDate;

    @Column(name = DB_KEY_MODIFYDATE)
    protected Date modifyDate;

    @Column(name = DB_KEY_SIZE)
    protected long size = 0;

    @Column(name = DB_KEY_DOWNLOADEDSIZE)
    protected long downloadedSize = 0;

    @Column(name = DB_KEY_VIDEODURATION)
    protected int videoDuration = 0;

    @Column(name = DB_KEY_FILTERID)
    protected int filterID = 0;

    @Override
    public int getMediaType() {
        return mediaType;
    }

    @Override
    public String getCameraUUID() {
        return cameraUUID;
    }

    @Override
    public String getRemotePath() {
        return remotePath;
    }

    @Override
    public String getLocalPath() {
        return localPath;
    }

    @Override
    public String getThumbnailImagePath() {
        return thumbnailPath;
    }

    @Override
    public Date getCreateDate() {
        return createDate;
    }

    @Override
    public Date getModifyDate() {
        return modifyDate;
    }

    @Override
    public long getSize() {
        return size;
    }

    @Override
    public long getDownloadedSize() {
        return downloadedSize;
    }

    @Override
    public int getVideoDuration() {
        return videoDuration;
    }

    @Override
    public int getDownloadStatus() {
        synchronized (downloadStatusOfMediaRemoteHash)
        {
            Integer downloadStatus = downloadStatusOfMediaRemoteHash.get(storageKey());
            if (null == downloadStatus)
            {
                return DownloadStatusNone;
            }
            else
            {
                return downloadStatus;
            }
        }
    }

    @Override
    public void setDownloadStatus(int downloadStatus) {
        synchronized (downloadStatusOfMediaRemoteHash)
        {
//            Log.v("QD:MVMedia", "setDownloadStatus(" + StringOfDownloadStatus(downloadStatus) + ") : MVMedia(" + hashCodeOfCommonFields() + ") = " + this);
            downloadStatusOfMediaRemoteHash.put(storageKey(), downloadStatus);
        }
    }

    @Override
    public void setMediaType(int mediaType) {
        this.mediaType = mediaType;
    }

    @Override
    public void setCameraUUID(String cameraUUID) {
        this.cameraUUID = cameraUUID;
    }

    @Override
    public void setRemotePath(String remotePath) {
        this.remotePath = remotePath;
    }

    @Override
    public void setLocalPath(String localPath) {
        this.localPath = localPath;
    }

    @Override
    public void setThumbnailImagePath(String thumbnailImagePath) {
        this.thumbnailPath = thumbnailImagePath;
    }

    @Override
    public int getFilterID() {
        return filterID;
    }

    @Override
    public void setFilterID(int filterID) {
        this.filterID = filterID;
    }

    @Override
    public void setCreateDate(Date createDate) {
        this.createDate = createDate;
    }

    @Override
    public void setModifyDate(Date modifyDate) {
        this.modifyDate = modifyDate;
    }

    @Override
    public void setSize(long size) {
        this.size = size;
    }

    @Override
    public void setDownloadedSize(long downloadedSize) {
        this.downloadedSize = downloadedSize;
    }

    @Override
    public void setVideoDuration(int videoDuration) {
        this.videoDuration = videoDuration;
    }

    private static ConcurrentHashMap<String, Integer> downloadStatusOfMediaRemoteHash = new ConcurrentHashMap<String, Integer>();
}
