package com.madv360.madv.utils;

import java.lang.String;

public class PathTreeNode {
	public PathTreeNode(PathTreeNode parent, String pathComponent, boolean isDirectory) {
		this.pathComponent = pathComponent;
		this.isDirectory = isDirectory;
		this.parent = parent;
		this.children = null;
	}

	protected String pathComponent;
	protected boolean isDirectory;
	protected PathTreeNode parent;
	protected PathTreeNode[] children;
}

