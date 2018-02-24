//
//  TimeUtils.cpp
//  HLSStreamingEngine
//
//  Created by videbo-pengyu on 15/4/2.
//  Copyright (c) 2015年 pengyu-mac. All rights reserved.
//
#include <unistd.h>
#if defined(TARGET_DARWIN)
#include <pthread/sched.h>
#else
#include <sched.h>
#endif

#include "TimeUtils.h"

unsigned int SystemClockMillisCustom()
{
#if defined(TARGET_DARWIN)
    uint64_t now_time;
    now_time = CVGetCurrentHostTime() *  1000 / CVGetHostClockFrequency();
#else
    uint64_t now_time;
    struct timespec ts = {};
    clock_gettime(CLOCK_MONOTONIC, &ts);
    now_time = (ts.tv_sec * 1000) + (ts.tv_nsec / 1000000);
#endif
    return (unsigned int)now_time;
}

int64_t CurrentHostCounter(void)
{
#if   defined(TARGET_DARWIN)
    return((int64_t)CVGetCurrentHostTime());
#else
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return(((int64_t)now.tv_sec * 1000000000L) + now.tv_nsec);
#endif
}

int64_t CurrentHostFrequency(void)
{
#if defined(TARGET_DARWIN)    
    return((int64_t)CVGetHostClockFrequency());
#else
    return((int64_t)1000000000L);
#endif
}

void Sleep(unsigned int dwMilliSeconds)
{
#if _POSIX_PRIORITY_SCHEDULING
    if (dwMilliSeconds == 0)
    {
        sched_yield();
        return;
    }
#endif
    
    usleep(dwMilliSeconds * 1000);
}