package com.madv360.madv.media;

import android.text.TextUtils;

import com.madv360.madv.utils.DateUtil;

import java.io.File;
import java.io.Serializable;
import java.util.Date;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import bootstrap.appContainer.AppStorageManager;
import bootstrap.appContainer.EnviromentConfig;
import foundation.activeandroid.Model;
import foundation.activeandroid.query.Select;

/**
 * 媒体文件对象
 */
public abstract class MVMedia extends Model implements Serializable {
    public static String remotePathPrefix = "/tmp/SD0/";
    public static String udiskPathPrefix = "/storage/8765-4321/";
    public static String albumRootPath = "DCIM/";
    public static String ABFileType = "AB.MP4";
    public static String AAFileType = "AA.MP4";

    // 下载状态枚举值：
    public static final int DownloadStatusNone = 0;//不在下载队列中
    public static final int DownloadStatusDownloading = 1;//正在下载
    public static final int DownloadStatusPending = 2;//排队中未下载
    public static final int DownloadStatusStopped = 3;//停止
    public static final int DownloadStatusFinished = 4;//已下载完成
    public static final int DownloadStatusError = 5;//发生错误而中止

    public static final String StringOfDownloadStatus(int status) {
        switch (status) {
            case DownloadStatusDownloading:
                return "DownloadStatusDownloading";
            case DownloadStatusNone:
                return "DownloadStatusNone";
            case DownloadStatusPending:
                return "DownloadStatusPending";
            case DownloadStatusStopped:
                return "DownloadStatusStopped";
            case DownloadStatusFinished:
                return "DownloadStatusFinished";
            case DownloadStatusError:
                return "DownloadStatusError";
        }
        return "N/A";
    }

    public static final int MediaTypePhoto = 0;//照片
    public static final int MediaTypeVideo = 1;//视频

    public static final String DB_KEY_MEDIATYPE = "mediaType";
    public static final String DB_KEY_CAMERAUUID = "cameraUUID";
    public static final String DB_KEY_REMOTEPATH = "remotePath";
    public static final String DB_KEY_LOCALPATH = "localPath";
    public static final String DB_KEY_THUMBNAILPATH = "thumbnailPath";
    public static final String DB_KEY_CREATEDATE = "createDate";
    public static final String DB_KEY_MODIFYDATE = "modifyDate";
    public static final String DB_KEY_SIZE = "size";
    public static final String DB_KEY_DOWNLOADEDSIZE = "downloadedSize";
    public static final String DB_KEY_VIDEODURATION = "videoDuration";
    public static final String DB_KEY_FILTERID = "filterID";

    /**
     * 获得该媒体文件的下载状态
     */
    public abstract int getDownloadStatus();

    public abstract void setDownloadStatus(int downloadStatus);

    /**
     * 获得该媒体文件的类型
     */
    public abstract int getMediaType();

    public abstract void setMediaType(int mediaType);

    /**
     * 如果该媒体文件来自相机，则返回该相机的唯一ID；否则若该媒体纯粹来自手机本地，则返回null
     */
    public abstract String getCameraUUID();

    public abstract void setCameraUUID(String cameraUUID);

    /**
     * 如果该媒体文件来自相机，则返回其在相机上的相对路径（相对于存储卡根目录）；否则若该媒体纯粹来自手机本地，则返回null
     */
    public abstract String getRemotePath();

    public abstract void setRemotePath(String remotePath);

    /**
     * 若该媒体纯粹来自手机本地，返回自本地存储根目录的相对路径
     */
    public abstract String getLocalPath();

    public abstract void setLocalPath(String localPath);

    /**
     * 返回该媒体文件的缩略图文件的本地路径（.png格式）
     */
    public abstract String getThumbnailImagePath();

    public abstract void setThumbnailImagePath(String thumbnailImagePath);

    /**
     * 获得该媒体文件的创建日期
     */
    public abstract Date getCreateDate();

    public abstract void setCreateDate(Date createDate);

    /**
     * 获得该媒体文件的最后修改日期
     */
    public abstract Date getModifyDate();

    public abstract void setModifyDate(Date modifyDate);

    /**
     * 获得该媒体文件的总大小（字节数）
     */
    public abstract long getSize();

    public abstract void setSize(long size);

    /**
     * 获得该媒体文件已下载到本地的大小（字节数）
     */
    public abstract long getDownloadedSize();

    public abstract void setDownloadedSize(long downloadedSize);

    /**
     * 获得视频时长
     */
    public abstract int getVideoDuration();

    public abstract void setVideoDuration(int videoDuration);

    /**
     * 获得该媒体文件所应用的图像滤镜ID（目前仅针对图片）
     */
    public abstract int getFilterID();

    public abstract void setFilterID(int filterID);

    //是否正在执行操作，这几个状态是不能进行删除的
    public boolean isInProcessing() {
        int status = getDownloadStatus();
        return status == DownloadStatusDownloading
                || status == DownloadStatusPending
                || status == DownloadStatusStopped;
    }

    public static String storageKey(String cameraUUID, String remotePath, String localPath) {
        StringBuilder sb = new StringBuilder();
        if (cameraUUID != null && !cameraUUID.isEmpty())
            sb.append(cameraUUID);
        if (remotePath != null && !remotePath.isEmpty())
            sb.append(remotePath);
        String name = sb.toString();
        if (null == name || name.isEmpty()) {
            name = "__" + localPath;
        }
        name = name.replace('/', '_');
        name = name.replace(':', '_');
        name = name.replace(' ', '_');
        return name;
    }

    public String storageKey() {
        return storageKey(getCameraUUID(), getRemotePath(), getLocalPath());
    }

    public static String getRemotePathFromUDiskPath(String udiskPath) {
        if (!TextUtils.isEmpty(udiskPath)) {
            if (udiskPath.startsWith(udiskPathPrefix)) {
                udiskPath = udiskPath.replace(udiskPathPrefix, remotePathPrefix);
                return udiskPath;
            }
        }
        return null;
    }

    public static String getUDiskPathFromRemotePath(String remotePath) {
        if (!TextUtils.isEmpty(remotePath)) {
            if (remotePath.startsWith(remotePathPrefix)) {
                remotePath = remotePath.replace(remotePathPrefix, udiskPathPrefix);
                return remotePath;
            }
        }
        return null;
    }

    public static String uniqueLocalPath(String cameraUUID, String remotePath) {
        String baseName = remotePath;
        String[] pathComponents = remotePath.split("/");
        if (pathComponents != null && pathComponents.length > 0) {
            baseName = pathComponents[pathComponents.length - 1];
        }

        String localDirectory = AppStorageManager.getAlbumDir();
        String localFilePath = localDirectory + baseName;
        int prefix = 0;
        while (true) {
            List<MVMedia> exists = new Select().from(MVMediaImpl.class).where(DB_KEY_LOCALPATH + " = '" + localFilePath + "'").execute();
            if (null != exists && exists.size() > 0) {
                localFilePath = localDirectory + prefix + baseName;
                prefix++;
                continue;
            }

            File file = new File(localFilePath);
            if (file.exists()) {
                localFilePath = localDirectory + prefix + baseName;
                prefix++;
                continue;
            }

            break;
        }
        return localFilePath;
    }

    public boolean isEqualRemoteMedia(MVMedia other) {
        if (null == other) return false;

        if (EnviromentConfig.environment() == EnviromentConfig.ENVIRONMENT_DEVELOPMENT) {
            if (0 == getLocalPath().compareTo(other.getLocalPath())) {
                return true;
            } else {
                return false;
            }
        } else {
            return (TextUtils.equals(getCameraUUID(), other.getCameraUUID()) && TextUtils.equals(getRemotePath(), other.getRemotePath()));
        }
    }

    public static MVMedia create() {
        if (EnviromentConfig.environment() == EnviromentConfig.ENVIRONMENT_DEVELOPMENT) {
            return new MVMediaMock();
        } else {
            return new MVMediaImpl();
        }
    }

    public static Date dateFromFileName(String lowerFileName) {
        String extension = lowerFileName.substring(lowerFileName.lastIndexOf('.') + 1);
        String patternString = "[^0-9]+([0-9]{4})([0-9]{2})([0-9]{2})(_)([0-9]{2})([0-9]{2})([0-9]{2}).*\\." + extension + "$";
        Pattern pattern = Pattern.compile(patternString);
        Matcher matcher = pattern.matcher(lowerFileName);
        if (matcher.find()) {
            String dateString = matcher.group(1) + matcher.group(2) + matcher.group(3) + matcher.group(5) + matcher.group(6) + matcher.group(7);
            Date date = DateUtil.parseDate(dateString, "yyyyMMddHHmmss");
            return date;
        } else {
            patternString = "([0-9]{2})([0-9]{2})([0-9]{2}).*_([0-9]{2})([0-9]{2})([0-9]{2}).*\\." + extension + "$";
            pattern = Pattern.compile(patternString);
            matcher = pattern.matcher(lowerFileName);
            if (matcher.find()) {
                String dateString = "20" + matcher.group(1) + matcher.group(2) + matcher.group(3) + matcher.group(4) + matcher.group(5) + matcher.group(6);
                Date date = DateUtil.parseDate(dateString, "yyyyMMddHHmmss");
                return date;
            } else {
               return null;
            }
        }
    }

    public static MVMedia create(String cameraUUID, String remoteFullPath) {
        MVMedia media = MVMedia.create();
        media.setRemotePath(remoteFullPath);
        media.setCameraUUID(cameraUUID);

        media.setSize(0);
        media.setDownloadedSize(0);

        String lowerFullPath = remoteFullPath.toLowerCase();
        if (lowerFullPath.endsWith(".mp4")) {
            media.setMediaType(MVMedia.MediaTypeVideo);
        } else if (lowerFullPath.endsWith(".jpg")
                || lowerFullPath.endsWith(".bmp")
                || lowerFullPath.endsWith(".png")) {
            media.setMediaType(MVMedia.MediaTypePhoto);
        }

        Date createDate = dateFromFileName(lowerFullPath);
        if (createDate != null) {
            media.setCreateDate(createDate);
        }
        else {
            media.setCreateDate(new Date());
        }
        media.setModifyDate(media.getCreateDate());
        return media;
    }

    /**
     * 根据指定的(cameraUUID, remotePath, localPath)三元组查询MVMedia
     */
    public static MVMedia querySavedMedia(String cameraUUID, String remotePath, String localPath) {
        MVMedia localMedia;
        if (remotePath != null && !remotePath.isEmpty()) {
            String query = DB_KEY_CAMERAUUID + " = '" + cameraUUID + "' AND " + DB_KEY_REMOTEPATH + " = '" + remotePath + "'";
            if (localPath != null && !localPath.isEmpty()) {
                query += (" AND " + DB_KEY_LOCALPATH + " = '" + localPath + "'");
            } else {
                query += (" AND " + DB_KEY_LOCALPATH + " is NULL");
            }
            localMedia = new Select().from(MVMediaImpl.class).where(query).executeSingle();
        } else {
            localMedia = new Select().from(MVMediaImpl.class).where(DB_KEY_LOCALPATH + " = '" + localPath + "'").executeSingle();
        }
        return localMedia;
    }

    /**
     * 查询包含指定的(cameraUUID, remotePath)二元组的所有MVMedia。
     * 如果没有(cameraUUID, remotePath)二元组，表示是纯本地媒体，则只按localPath查询
     *
     * @param cameraUUID
     * @param remotePath
     * @param localPath
     * @return
     */
    public static List<MVMedia> querySavedMedias(String cameraUUID, String remotePath, String localPath) {
        List<MVMedia> localMedias;
        if (remotePath != null && !remotePath.isEmpty()) {
            localMedias = new Select().from(MVMediaImpl.class).where(DB_KEY_CAMERAUUID + " = '" + cameraUUID + "' AND " + DB_KEY_REMOTEPATH + " = '" + remotePath + "' ORDER BY " + DB_KEY_DOWNLOADEDSIZE).execute();
        } else {
            localMedias = new Select().from(MVMediaImpl.class).where(DB_KEY_LOCALPATH + " = '" + localPath + "'").execute();
        }
        return localMedias;
    }

    public static List<MVMedia> queryDownloadedMedias() {
        return new Select().from(MVMediaImpl.class).where(MVMedia.DB_KEY_DOWNLOADEDSIZE + " >= " + MVMedia.DB_KEY_SIZE + " AND " + MVMedia.DB_KEY_SIZE + " > 0").execute();
    }

    public static MVMedia obtainDownloadedMedia(MVMedia media) {
        List<MVMedia> localMedias = querySavedMedias(media.getCameraUUID(), media.getRemotePath(), media.getLocalPath());
        if (null == localMedias || 0 == localMedias.size())
            return null;
        else {
            for (int i = localMedias.size() - 1; i >= 0; --i) {
                MVMedia localMedia = localMedias.get(i);
                if (!TextUtils.isEmpty(localMedia.getLocalPath())
                        && localMedia.getDownloadedSize() >= localMedia.getSize()
                        && localMedia.getSize() > 0) {
                    File file = new File(localMedia.getLocalPath());
                    if (file.exists()) {
                        return localMedia;
                    } else {
                        localMedia.delete();
                    }
                }
            }

            return null;
        }
    }

    public MVMedia obtainDownloadedOrThisMedia() {
        MVMedia downloaded = obtainDownloadedMedia(this);
        if (null != downloaded)
            return downloaded;
        else
            return this;
    }

    public void saveCommonFields() {
        List<MVMedia> savedMedias = querySavedMedias(getCameraUUID(), getRemotePath(), getLocalPath());
        for (MVMedia savedMedia : savedMedias) {
            savedMedia.copyCommonFields(this);
            savedMedia.save();
        }
        save();
    }

    public void copyCommonFields(MVMedia other) {
        if (other == null) return;
        setMediaType(other.getMediaType());
        if (getThumbnailImagePath() == null || getThumbnailImagePath().isEmpty())
            setThumbnailImagePath(other.getThumbnailImagePath());
        if (getRemotePath() == null || getRemotePath().isEmpty())
            setRemotePath(other.getRemotePath());
        if (getCameraUUID() == null || getCameraUUID().isEmpty())
            setCameraUUID(other.getCameraUUID());
        if (getSize() < other.getSize())
            setSize(other.getSize());
        if (getCreateDate() == null)
            setCreateDate(other.getCreateDate());
        if (getVideoDuration() < other.getVideoDuration())
            setVideoDuration(other.getVideoDuration());
        if (getFilterID() <= 0)
            setFilterID(other.getFilterID());
    }

    public void copy(MVMedia other) {
        if (other == null) return;

        copyCommonFields(other);

        if (getDownloadedSize() < other.getDownloadedSize())
            setDownloadedSize(other.getDownloadedSize());
        if (getLocalPath() == null || getLocalPath().isEmpty())
            setLocalPath(other.getLocalPath());
        if (getModifyDate() == null)
            setModifyDate(other.getModifyDate());
    }

    @Override
    public int hashCode() {
        String remotePath = getRemotePath();
        String cameraUUID = getCameraUUID();
        String localPath = getLocalPath();
        if (remotePath != null && !remotePath.isEmpty()) {
            if (localPath != null && !localPath.isEmpty())
                return (cameraUUID + remotePath + localPath).hashCode();
            else
                return (cameraUUID + remotePath).hashCode();
        } else if (localPath != null) {
            return localPath.hashCode();
        } else {
            return super.hashCode();
        }
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof MVMedia)) return false;

        MVMedia other = (MVMedia) obj;

        String remotePath = getRemotePath();
        String cameraUUID = getCameraUUID();
        String localPath = getLocalPath();

        if (remotePath != null && !remotePath.isEmpty()) {
            if (!remotePath.equals(other.getRemotePath()))
                return false;
        } else if (other.getRemotePath() != null && !other.getRemotePath().isEmpty())
            return false;

        if (cameraUUID != null && !cameraUUID.isEmpty()) {
            if (!cameraUUID.equals(other.getCameraUUID()))
                return false;
        } else if (other.getCameraUUID() != null && !other.getCameraUUID().isEmpty())
            return false;

        if (localPath != null && !localPath.isEmpty()) {
            if (!localPath.equals(other.getLocalPath()))
                return false;
        } else if (other.getLocalPath() != null && !other.getLocalPath().isEmpty())
            return false;

        return true;
    }

    @Override
    public String toString() {
        String remotePath = getRemotePath();
        String cameraUUID = getCameraUUID();
        String localPath = getLocalPath();
        String thumbnailPath = getThumbnailImagePath();
        int mediaType = getMediaType();
        long size = getSize();
        long downloadedSize = getDownloadedSize();
        Date createDate = getCreateDate();
        Date modifyDate = getModifyDate();
        int filterID = getFilterID();
        return "\nMVMedia(" + getId() + ", " + hashCode() + "):\n        filterID=" + filterID + ", type=" + mediaType
                + ", duration=" + getVideoDuration()
                + "\n,        remotePath=" + remotePath + "\n,        localPath=" + localPath + "\n,        thumbnailPath=" + thumbnailPath
                + ", size=" + size + ", downloadedSize=" + downloadedSize
                + "\n,        uuid=" + cameraUUID
                + "):\n        modifyDate=" + modifyDate
                + "\n,        createDate=" + createDate;
    }
}

