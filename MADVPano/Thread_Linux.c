//
//  Thread_Linux.c
//  TestCyTrackableStateNode
//
//  Created by FutureBoy on 8/23/15.
//  Copyright (c) 2015 Cyllenge. All rights reserved.
//

#include <stdio.h>
#include <sys/syscall.h>
#include <linux/unistd.h>
#include <sys/types.h>

pid_t gettid(void)
{
  return syscall(__NR_gettid);
}

long getCurrentThreadID_Linux() {
    pid_t tid = gettid();
    return (long)tid;
}

