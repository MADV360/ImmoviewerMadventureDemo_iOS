package com.madv360.madv.media;

import android.graphics.Bitmap;
import android.text.TextUtils;

import java.util.List;

import bootstrap.appContainer.EnviromentConfig;

/** 媒体库管理器（包括相机和本地）*/
public abstract class MVMediaManager {
	/** 媒体列表数据源监听者 */
	public interface MediaDataSourceListener {
		/**
		 * 相机媒体列表有更新
		 * @param medias : 当replacingOnly为false时，表示整个相机媒体列表；否则表示需要”就地“更新的媒体列表
		 * @param replacingOnly : 为true时，表示无需更新整个相机媒体列表，而只是将原列表中与medias里相同的项目作”就地“替换
		 * 详细可参见CameraVideoItemView中的处理
         */
		void didCameraMediasReloaded(List<MVMedia> medias, boolean replacingOnly);

		/**
		 * 本地媒体列表有更新
		 * @param medias
         */
		void didLocalMediasReloaded(List<MVMedia> medias, boolean replacingOnly);

		/** 异步获取媒体缩略图的回调
		 * media: 需要获取缩略图的媒体对象对象
		 * image: 缩略图
		 */
		void didFetchThumbnailImage(MVMedia media, Bitmap image);

		/**
		 * 异步获取媒体信息的回调
		 * @param media 获取到媒体信息的媒体对象，可以从其中用get方法读取视频时长等信息
         */
		void didFetchMediaInfo(MVMedia media);

		/**
		 * 获取到相机中最新一个媒体文件的缩略图
		 * @param media
		 * @param image
         */
		void didFetchRecentMediaThumbnail(MVMedia media, Bitmap image);
	}

	/** 媒体对象下载状态监听者 */
	public interface MediaDownloadStatusListener {
		/** 下载状态发生变化
		 * 注意：当某一项已下载完成变成DownloadStatusFinished状态时，该项会被从下载队列列表中移动到本地媒体列表中，因此这两处UI此时都应更新
		 * media: 发生下载状态变化的媒体对象
		 * downloadStatus: 当前该媒体对象的下载状态，是MVMedia对象中定义的枚举值
		 * errorMessage: 发生错误时的错误提示信息
		 */
		void didDownloadStatusChange(MVMedia media, int downloadStatus, String errorMessage);

		/** 下载进度通知回调
		 * media: 发生下载进度变化的媒体对象
		 */
		void didDownloadProgressChange(MVMedia media, long downloadedBytes, long totalBytes);
	}

	public abstract void addMediaDataSourceListener(MediaDataSourceListener listener);

	public abstract void removeMediaDataSourceListener(MediaDataSourceListener listener);

	public abstract void addMediaDownloadStatusListener(MediaDownloadStatusListener listener);

	public abstract void removeMediaDownloadStatusListener(MediaDownloadStatusListener listener);

	/** 相机媒体库是否可以访问。亦即当前是否有连接的相机 */
	public abstract boolean isCameraMediaLibraryAvailable();

	/** 同步或异步获取当前U盘连接的相机上所有媒体对象 */
	public abstract List<MVMedia> getCameraMediasOnUDiskMode(boolean forceRefresh);

	public abstract void cameraDisconnectFromUDiskMode();

	/** 同步或异步获取当前连接相机上的所有媒体对象，以MVMedia对象数组的形式给出
	 * forceRefresh: 是否强制更新
	 * @return: 当直接返回非空数组时，表示相机媒体列表无需刷新，直接使用返回数组即可，
	 * 否则若返回null，表示需刷新，随后会通过回调MediaDataSourceListener的didCameraMediasReloaded方法给出最新列表
	 * */
	public abstract List<MVMedia> getCameraMedias(boolean forceRefresh);

	public final List<MVMedia> getCameraMedias() {
		return getCameraMedias(true);
	}

	/** 同步或异步获取当前手机本地的所有媒体对象，以MVMedia对象数组的形式给出
	 * forceRefresh: 是否强制更新
	 * @return: 当直接返回非空数组时，表示本地媒体列表无需刷新，直接使用返回数组即可，
	 * 否则若返回null，表示需刷新，随后会通过回调MediaDataSourceListener的didLocalMediasReloaded方法给出最新列表
	 * */
	public abstract List<MVMedia> getLocalMedias(boolean forceRefresh);

	public final List<MVMedia> getLocalMedias() {
		return getLocalMedias(true);
	}

	/** 获取指定媒体对象的缩略图，如果缓存里有则直接返回Bitmap，否则异步回调给所有注册的MediaDataSourceListener */
	public abstract Bitmap getThumbnailImageAsync(MVMedia media);

	/** 获取指定媒体对象的缩略图的本地路径，如果缓存里有则直接返回，否则异步回调给所有注册的MediaDataSourceListener*/
	public String getThumbnailLocalPathAsync(MVMedia media) {return null;}

	/** 获取指定媒体对象的媒体信息，包括视频时长等等。
	 * @return: 如果MVMedia对象中已经可以get到正确结果，则返回true；否则返回false，在MediaDataSourceListener的didFetchMediaInfo()回调中返回结果
	 * */
	public abstract boolean getMediaInfoAsync(MVMedia media);

	/** 删除相机上的媒体文件 */
	public abstract void deleteCameraMedias(List<MVMedia> medias);

	/** 删除本地的媒体文件 */
	public abstract void deleteLocalMedias(List<MVMedia> medias);

	/** 将媒体对象添加到下载队列，返回媒体对象，其localPath被用实际的本地下载路径赋值（为null则不成功，原因是当前未连接到对应相机） */
	public abstract MVMedia addDownloading(MVMedia media);

	/** 从下载队列中移除媒体对象 */
	public abstract void removeDownloading(MVMedia media);

	/** 继续下载（断点续传），返回是否成功（不成功原因就是当前未连接到对应相机） */
	public abstract boolean restartDownloading(MVMedia media);

	/** 停止（暂停）下载 */
	public abstract void stopDownloading(MVMedia media);

	/** 获取当前下载队列中的所有媒体对象
	 * 当上述addDownloading或removeDownloading方法
	 * 被调用，使得下载队列发生变化时，应该通过getMediasInDownloader获得下载队列列表，
	 * 给显示下载列表的ListView更新数据源。
	 * 而下载列表中某一项的下载状态发生变化时，则是通过回调MediaDownloadStatusListener接口的方式进行通知
	 */
	public abstract List<MVMedia> getMediasInDownloader();

	public void importMedias(List<String> paths, boolean isVideo) {

	}

	public void invalidateCameraMedias(boolean refresh) {

	}

	public void addNewCameraMedia(MVMedia media) {

	}

	/** 在App被关闭或切到后台时调用此方法。它会将需要持久化存储的数据（如下载队列）保存 */	
	public abstract void save();

	/** 在App被启动或切到前台时调用此方法。它会将需要持久化存储的数据（如下载队列）加载 */	
	public abstract void load();

	public MVMedia obtainCameraMedia(String cameraUUID, String remotePath, boolean willRefreshCameraMediasSoon) {
		List<MVMedia> medias = MVMedia.querySavedMedias(cameraUUID, remotePath, null);
		if (null == medias || medias.size() == 0)
		{
			MVMedia media = MVMedia.create(cameraUUID, remotePath);
			media.save();
			return media;
		}
		else
		{
			MVMedia localMedia = medias.get(0);
			if (TextUtils.isEmpty(localMedia.getLocalPath()) || localMedia.getDownloadedSize() < localMedia.getSize())
			{
				return localMedia;
			}
			else
			{
				MVMedia media = MVMedia.create(localMedia.getCameraUUID(), localMedia.getRemotePath());
				media.copyCommonFields(localMedia);
				media.save();
				return media;
			}
		}
	}

	static MVMediaManager s_sharedInstance = null;

	public static synchronized MVMediaManager sharedInstance() {
		if (null == s_sharedInstance)
		{
			if(EnviromentConfig.environment() == EnviromentConfig.ENVIRONMENT_DEVELOPMENT){
				s_sharedInstance = new MVMediaManagerMock();
			}
			else {
				s_sharedInstance = MVMediaManagerImpl.sharedInstance();
			}
		}
		return s_sharedInstance;
	}

	public static final int ThumbnailWidth = 720;
	public static final int ThumbnailHeight = 360;
}

