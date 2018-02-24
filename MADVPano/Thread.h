//
//  Thread.h
//  TestCyTrackableStateNode
//
//  Created by FutureBoy on 8/23/15.
//  Copyright (c) 2015 Cyllenge. All rights reserved.
//

#ifndef TestCyTrackableStateNode_Thread_h
#define TestCyTrackableStateNode_Thread_h

#include "TargetConditionals.h"

#if (defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0) || (defined(TARGET_OS_OSX) && TARGET_OS_OSX != 0)
#define getCurrentThreadID getCurrentThreadID_Apple
#elif  defined(TARGET_OS_LINUX) && TARGET_OS_LINUX != 0
#define getCurrentThreadID getCurrentThreadID_Linux
#elif defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
#define getCurrentThreadID getCurrentThreadID_Windows
#endif

#ifdef __cplusplus
extern "C" {
#endif

    long getCurrentThreadID_Apple();
    long getCurrentThreadID_Linux();
	long getCurrentThreadID_Windows();

#ifdef __cplusplus
}
#endif

#endif
