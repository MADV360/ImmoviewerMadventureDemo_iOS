//
//  Thread_Apple.c
//  TestCyTrackableStateNode
//
//  Created by FutureBoy on 8/23/15.
//  Copyright (c) 2015 Cyllenge. All rights reserved.
//

#include <stdio.h>
#include <pthread.h>
#include "TargetConditionals.h"

#if (defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0) || (defined(TARGET_OS_OSX) && TARGET_OS_OSX != 0)

long getCurrentThreadID_Apple() {
    pthread_t currentThread = pthread_self();
    __uint64_t tid = 0;
    pthread_threadid_np(currentThread, &tid);
    return (long)tid;
}

#endif
