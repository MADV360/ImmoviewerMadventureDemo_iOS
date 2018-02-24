//
//  Header.h
//  libvplayer
//
//  Created by videbo-pengyu on 15/6/11.
//  Copyright (c) 2015年 videbo-pengyu. All rights reserved.
//

#ifndef _DARWIN_UTILS_H_
#define _DARWIN_UTILS_H_

#include <string>

#ifdef __cplusplus
extern "C"
{
#endif
    float       GetIOSVersion(void);
    bool        DarwinIsIPad3(void);
    bool DeviceHasRetina(double &scale);
#ifdef __cplusplus
}
#endif


#endif
