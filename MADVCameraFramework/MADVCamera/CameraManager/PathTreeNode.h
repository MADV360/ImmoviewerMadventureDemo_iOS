//
//  PathTreeNode.h
//  Madv360_v1
//
//  Created by QiuDong on 16/5/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PATH_SEPARATOR "/"

typedef BOOL(^PathTreeIteratorCallback)(NSString* fullPath, BOOL isDirectory, BOOL hasMore);

typedef void(^PathTreeIteratorFeedContentsBlock)(NSArray<NSString* >* files);

@interface PathTreeNode : NSObject

@property (nonatomic, copy) NSString* pathComponent;
@property (nonatomic, assign) BOOL isDirectory;
@property (nonatomic, weak) PathTreeNode* parent;
@property (nonatomic, strong) NSArray<PathTreeNode*>* children;

- (instancetype) initWithParent:(PathTreeNode*)parent pathComponent:(NSString*)pathComponent isDirectory:(BOOL)isDirectory;

@end

@class PathTreeIterator;

@protocol PathTreeIteratorDelegate<NSObject>

@required

- (void) pathTreeIteratorFetchContentsInFullPath:(NSString*)fullPath feedContentsBlock:(PathTreeIteratorFeedContentsBlock)feedContentsBlock callback:(PathTreeIteratorCallback)callback;

@optional

- (BOOL) pathTreeIteratorIsDirectory:(NSString*)path file:(NSString*)file;

- (BOOL) pathTreeIteratorShouldPassFilter:(NSString*)fullPath isDirectory:(BOOL)isDirectory;

- (BOOL) pathTreeIteratorShouldStop;

- (void) pathTreeIteratorFinished:(BOOL)isStopped;

@end

@interface PathTreeIterator : NSObject

@property (nonatomic, assign) BOOL hasNext;
@property (nonatomic, weak) id<PathTreeIteratorDelegate> delegate;
@property (nonatomic, strong) PathTreeIteratorCallback callback;

+ (PathTreeIterator*) beginFileTraverse:(NSString*)rootDirectory delegate:(id<PathTreeIteratorDelegate>)delegate;

- (instancetype) initWithRootNode:(PathTreeNode*)rootNode delegate:(id<PathTreeIteratorDelegate>)delegate;

- (void) next:(PathTreeIteratorCallback)callback;

- (void) next;

@end

