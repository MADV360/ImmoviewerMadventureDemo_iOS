package com.madv360.madv.utils;

import java.util.LinkedList;
import java.lang.String;

import android.util.Log;

public class PathTreeIterator {
	public interface Callback {
		/**
		 *
		 * @param fullPath
		 * @param isDirectory
		 * @param notReachEnd
         * @return If finished
         */
		boolean onGotNextFile(String fullPath, boolean isDirectory, boolean notReachEnd);
	}

	public interface FetchContentsHandler {
		void onDirectoryContentsFetched(String[] files, Callback callback);
	}

	public interface Delegate {
		void fetchContents(String fullPath, FetchContentsHandler handler, Callback callback);

		boolean isDirectory(String fullPath);

		boolean shouldPassFilter(String fullPath, boolean isDirectory);

		boolean shouldStop();

		void onFinished(boolean isStopped);
	}

	public static PathTreeIterator beginFileTraverse(String rootDirectory, PathTreeIterator.Delegate delegate) {
		PathTreeNode rootNode = new PathTreeNode(null, rootDirectory, true);
		PathTreeIterator iter = new PathTreeIterator(rootNode, delegate);
		return iter;
	}

	public static final String PATH_SEPARATOR = "/";

	public PathTreeIterator(PathTreeNode rootNode, Delegate delegate) {
		this.rootNode = rootNode;
		this.currentNode = rootNode;
		this.indices = new LinkedList<Integer>();
		this.delegate = delegate;

		this.isLocked = false;

		this.pwd = new StringBuilder(rootNode.pathComponent);
		if (pwd.length() == 0)
		{
			pwd.append(PATH_SEPARATOR);
		}
		else if (delegate != null)
		{
			if (delegate.isDirectory(pwd.toString()))
			{
				if (!pwd.toString().endsWith(PATH_SEPARATOR))
				{
					pwd.append(PATH_SEPARATOR);
				}
			}
			else if (pwd.toString().endsWith(PATH_SEPARATOR))
			{
				pwd.deleteCharAt(pwd.length() - 1);
			}
		}
		rootNode.pathComponent = pwd.toString();
	}

	public synchronized void lock() {
//		Log.v(TAG, "lock");
		while (isLocked)
		{
			try
			{
//				Log.v(TAG, "lock : Before wait");
				this.wait();
			}
			catch(Exception ex)
			{
				ex.printStackTrace();
			}
		}
//		Log.v(TAG, "lock : After wait");
		isLocked = true;
	}

	public synchronized boolean tryLock() {
//		Log.v(TAG, "tryLock : isLocked = " + isLocked);
		if (isLocked)
		{
			return false;
		}

		isLocked = true;
		return true;
	}

	public synchronized void unlock() {
//		Log.v(TAG, "unlock");
		isLocked = false;
		try
		{
			this.notifyAll();
		}
		catch(Exception ex)
		{
			ex.printStackTrace();
		}
	}

	public synchronized boolean hasNext() {
//		Log.v(TAG, "hasNext");
		while (isLocked)
		{
			try
			{
//				Log.v(TAG, "hasNext : Before wait");
				wait();
			}
			catch (Exception ex)
			{
				ex.printStackTrace();
			}
		}
//		Log.v(TAG, "hasNext : After wait");
		return this.hasNext;
	}

	public void next(Callback callback) {
//		if (!tryLock())
//			return;
		lock();

		if (delegate != null)
		{
			if (delegate.shouldStop())
			{
				delegate.onFinished(true);

				unlock();
				return;
			}
		}

		if (currentNode.children != null)
		{
			int currentIndex = indices.getLast();
			if (currentIndex < currentNode.children.length)
			{
				PathTreeNode child = currentNode.children[currentIndex];
				if (child.isDirectory)
				{
					currentNode = child;
					pwd.append(child.pathComponent);

					if (callback != null)
					{
						callback.onGotNextFile(pwd.toString(), true, true);
					}

					unlock();
				}
				else
				{
					indices.removeLast();
					indices.add(++currentIndex);

					if (callback != null)
					{
						pwd.append(child.pathComponent);
						callback.onGotNextFile(pwd.toString(), false, true);
						pwd.delete(pwd.length() - child.pathComponent.length(), pwd.length());
					}

					unlock();
				}
			}
			else
			{
				pwd.delete(pwd.length() - currentNode.pathComponent.length(), pwd.length());

				if (null == (currentNode = currentNode.parent))
				{
					hasNext = false;
					if (callback != null)
					{
						callback.onGotNextFile(null, false, false);
					}

					unlock();
				}
				else
				{
					indices.removeLast();
					int parentIndex = indices.getLast();
					indices.removeLast();
					indices.add(++parentIndex);

					unlock();

//					next(callback);
				}
			}
		}
		else
		{
			if (delegate != null)
			{
				delegate.fetchContents(pwd.toString(), handler, callback);
			}
			else
			{
				currentNode.children = new PathTreeNode[0];
				indices.add(0);

				unlock();

//				next(callback);
			}
		}
	}

	FetchContentsHandler handler = new FetchContentsHandler() {
		@Override
		public void onDirectoryContentsFetched(String[] files, Callback callback) {
			if (files == null)
			{// Fetching contents in directory failed, return to upper:
				pwd.delete(pwd.length() - currentNode.pathComponent.length(), pwd.length());

				if (null == (currentNode = currentNode.parent))
				{
					hasNext = false;
					if (callback != null)
					{
						callback.onGotNextFile(null, false, false);
					}

					if (delegate != null)
					{
						delegate.onFinished(false);
					}

					unlock();
				}
				else
				{
					int parentIndex = indices.getLast();
					indices.removeLast();
					indices.add(++parentIndex);

					unlock();

//					next(callback);
				}
			}
			else
			{
				LinkedList<PathTreeNode> children = new LinkedList<PathTreeNode>();
				for (String file : files)
				{
					boolean childIsDirectory;
					if (delegate != null)
					{
						childIsDirectory = delegate.isDirectory(pwd.toString() + file);
						if (childIsDirectory)
						{
							if (!file.substring(file.length() - 1).equals(PATH_SEPARATOR))
							{
								file += PATH_SEPARATOR;
							}
						}
						else if (file.substring(file.length() - 1).equals(PATH_SEPARATOR))
						{
							file = file.substring(0, file.length() - 1);
						}
					}
					else
					{
						childIsDirectory = file.substring(file.length() - 1).equals(PATH_SEPARATOR);
					}

					if (delegate != null)
					{
						if (!delegate.shouldPassFilter(pwd.toString() + file, childIsDirectory))
						{
							continue;
						}
					}

					PathTreeNode child = new PathTreeNode(currentNode, file, childIsDirectory);
					children.add(child);
				}

				indices.add(0);
				currentNode.children = new PathTreeNode[children.size()];
				children.toArray(currentNode.children);

				unlock();

//				next(callback);
			}
		}
	};

	protected LinkedList<Integer> indices;
	protected PathTreeNode currentNode;
	protected StringBuilder pwd;
	private PathTreeNode rootNode;

	private boolean isLocked;

	private boolean hasNext = true;

	protected Delegate delegate;
	
	private String TAG = "QD:PathTreeIterator";
}

