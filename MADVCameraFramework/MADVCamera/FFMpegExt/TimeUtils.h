//
//  TimeUtils.h
//  HLSStreamingEngine
//
//  Created by videbo-pengyu on 15/3/10.
//  Copyright (c) 2015年 pengyu-mac. All rights reserved.
//

#ifndef HLSStreamingEngine_TimeUtils_h
#define HLSStreamingEngine_TimeUtils_h

#if defined(TARGET_DARWIN)
#include <CoreVideo/CVHostTime.h>
#else
#include <time.h>
#endif

unsigned int SystemClockMillisCustom();
int64_t CurrentHostCounter(void);
int64_t CurrentHostFrequency(void);

void Sleep(unsigned int dwMilliSeconds);

#endif
