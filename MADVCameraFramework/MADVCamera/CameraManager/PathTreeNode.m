//
//  PathTreeNode.m
//  Madv360_v1
//
//  Created by QiuDong on 16/5/16.
//  Copyright © 2016年 Cyllenge. All rights reserved.
//

#import "PathTreeNode.h"
#import "NSRecursiveCondition.h"

@implementation PathTreeNode

- (instancetype) initWithParent:(PathTreeNode*)parent pathComponent:(NSString*)pathComponent isDirectory:(BOOL)isDirectory {
    if (self = [super init])
    {
        self.pathComponent = pathComponent;
        self.isDirectory = isDirectory;
        self.parent = parent;
        self.children = nil;
    }
    return self;
}

@end

@interface PathTreeIterator ()
{
    NSMutableArray<NSNumber* >* _indices;
    PathTreeNode* _currentNode;
    NSMutableString* _pwd;
    PathTreeNode* _rootNode;
    
    BOOL _hasNext;
    
    NSRecursiveCondition* _cond;
    BOOL _isLocked;
}

@property (nonatomic, strong) NSMutableArray<NSNumber* >* indices;
@property (nonatomic, strong) PathTreeNode* currentNode;
@property (nonatomic, strong) NSMutableString* pwd;
@property (nonatomic, strong) PathTreeNode* rootNode;

@end

@implementation PathTreeIterator

@synthesize indices = _indices;
@synthesize currentNode = _currentNode;
@synthesize pwd = _pwd;
@synthesize rootNode = _rootNode;
@synthesize hasNext = _hasNext;
@synthesize callback;

+ (PathTreeIterator*) beginFileTraverse:(NSString*)rootDirectory delegate:(id<PathTreeIteratorDelegate>)delegate {
    PathTreeNode* rootNode = [[PathTreeNode alloc] initWithParent:nil pathComponent:rootDirectory isDirectory:YES];
    PathTreeIterator* iter = [[PathTreeIterator alloc] initWithRootNode:rootNode delegate:delegate];
    return iter;
}

- (void) lock {
    [_cond lock];
    {
        while (_isLocked)
        {
            [_cond wait];
        }
        _isLocked = YES;
    }
    [_cond unlock];
}

- (void) unlock {
    [_cond lock];
    {
        _isLocked = NO;
        [_cond broadcast];
    }
    [_cond unlock];
}

- (BOOL) hasNext {
    [_cond lock];
    {
        while (_isLocked)
        {
            [_cond wait];
        }
    }
    [_cond unlock];
    return _hasNext;
}

- (instancetype) initWithRootNode:(PathTreeNode*)rootNode delegate:(id<PathTreeIteratorDelegate>)delegate {
    if (self = [super init])
    {
        _cond = [[NSRecursiveCondition alloc] init];
        _isLocked = NO;
        
        _hasNext = YES;
        
        _rootNode = rootNode;
        _currentNode = rootNode;
        _pwd = [rootNode.pathComponent mutableCopy];
        _indices = [[NSMutableArray alloc] init];
        self.delegate = delegate;
        
        if (!_pwd || _pwd.length == 0)
        {
            _pwd = [@PATH_SEPARATOR mutableCopy];
        }
        else if (delegate && [delegate respondsToSelector:@selector(pathTreeIteratorIsDirectory:file:)])
        {
            if ([delegate pathTreeIteratorIsDirectory:_pwd file:@""])
            {
                if (![_pwd hasSuffix:@PATH_SEPARATOR])
                {
                    [_pwd appendString:@PATH_SEPARATOR];
                }
            }
            else if ([_pwd hasSuffix:@PATH_SEPARATOR])
            {
                [_pwd deleteCharactersInRange:NSMakeRange(_pwd.length-1, 1)];
            }
        }
        _rootNode.pathComponent = [NSString stringWithString:_pwd];
    }
    return self;
}

- (void) next {
    if (self.callback)
    {
        [self next:self.callback];
    }
}

- (void) next:(PathTreeIteratorCallback)callback {
    [self lock];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(pathTreeIteratorShouldStop)])
    {
        if ([self.delegate pathTreeIteratorShouldStop])
        {
            if ([self.delegate respondsToSelector:@selector(pathTreeIteratorFinished:)])
            {
                [self.delegate pathTreeIteratorFinished:YES];
            }
            
            [self unlock];
            return;
        }
    }
    
    if (_currentNode.children)
    {
        NSInteger currentIndex = [[_indices lastObject] integerValue];
        if (currentIndex < _currentNode.children.count)
        {
            PathTreeNode* child = _currentNode.children[currentIndex];
            if (child.isDirectory)
            {
                _currentNode = child;
                [_pwd appendString:child.pathComponent];
                
                if (callback)
                {
                    callback(_pwd, YES, YES);
                }
                
                [self unlock];
            }
            else
            {
                [_indices removeLastObject];
                [_indices addObject:@(++currentIndex)];
                
                if (callback)
                {
                    callback([_pwd stringByAppendingString:child.pathComponent], NO, YES);
                }
                
                [self unlock];
            }
        }
        else
        {
            [_pwd deleteCharactersInRange:NSMakeRange(_pwd.length - _currentNode.pathComponent.length, _currentNode.pathComponent.length)];
            
            if (nil == (_currentNode = _currentNode.parent))
            {
                _hasNext = NO;
                if (callback)
                {
                    callback(nil, NO, NO);
                }
                
                [self unlock];
            }
            else
            {
                [_indices removeLastObject];
                int parentIndex = [[_indices lastObject] intValue];
                [_indices removeLastObject];
                [_indices addObject:@(++parentIndex)];
                
                [self unlock];
            }
        }
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(pathTreeIteratorFetchContentsInFullPath:feedContentsBlock:callback:)])
        {
            __weak __typeof(self) wSelf = self;
            PathTreeIteratorFeedContentsBlock handler = ^(NSArray<NSString* >* files) {
                __strong __typeof(self) pSelf = wSelf;
                if (!files)
                {
                    [pSelf.pwd deleteCharactersInRange:NSMakeRange(pSelf.pwd.length - pSelf.currentNode.pathComponent.length, pSelf.currentNode.pathComponent.length)];
                    
                    if (nil == (pSelf.currentNode = pSelf.currentNode.parent))
                    {
                        pSelf.hasNext = NO;
                        if (callback)
                        {
                            callback(nil, NO, NO);
                        }
                        
                        if (pSelf.delegate && [pSelf.delegate respondsToSelector:@selector(pathTreeIteratorFinished:)])
                        {
                            [pSelf.delegate pathTreeIteratorFinished:NO];
                        }
                        
                        [pSelf unlock];
                    }
                    else
                    {
                        int parentIndex = [[pSelf.indices lastObject] intValue];
                        [pSelf.indices removeLastObject];
                        [pSelf.indices addObject:@(++parentIndex)];
                        
                        [pSelf unlock];
                    }
                }
                else
                {
                    NSMutableArray<PathTreeNode* >* children = [[NSMutableArray alloc] init];
                    for (NSString* f in files)
                    {
                        NSString* file = f;
                        BOOL childIsDirectory;
                        if (pSelf.delegate && [pSelf.delegate respondsToSelector:@selector(pathTreeIteratorIsDirectory:file:)])
                        {
                            childIsDirectory = [pSelf.delegate pathTreeIteratorIsDirectory:pSelf.pwd file:file];
                            if (childIsDirectory)
                            {
                                if (![file hasSuffix:@PATH_SEPARATOR])
                                {
                                    file = [file stringByAppendingString:@PATH_SEPARATOR];
                                }
                            }
                            else if ([file hasSuffix:@PATH_SEPARATOR])
                            {
                                file = [file substringToIndex:file.length-1];
                            }
                        }
                        else
                        {
                            childIsDirectory = [file hasSuffix:@PATH_SEPARATOR];
                        }
                        
                        if (pSelf.delegate && [pSelf.delegate respondsToSelector:@selector(pathTreeIteratorShouldPassFilter:isDirectory:)])
                        {
                            if (![pSelf.delegate pathTreeIteratorShouldPassFilter:[pSelf.pwd stringByAppendingString:file] isDirectory:childIsDirectory])
                            {
                                continue;
                            }
                        }
                        
                        PathTreeNode* child = [[PathTreeNode alloc] initWithParent:pSelf.currentNode pathComponent:file isDirectory:childIsDirectory];
                        [children addObject:child];
                    }
                    
                    [pSelf.indices addObject:@(0)];
                    pSelf.currentNode.children = children;
                    
                    [pSelf unlock];
                }
            };
            [self.delegate pathTreeIteratorFetchContentsInFullPath:_pwd feedContentsBlock:handler callback:callback];
        }
        else
        {
            _currentNode.children = [[NSMutableArray alloc] init];
            [_indices addObject:@(0)];
            
            [self unlock];
        }
    }
}

@end
