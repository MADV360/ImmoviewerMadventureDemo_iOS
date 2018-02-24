//
//  DarwinUtils.cpp
//  libvplayer
//
//  Created by videbo-pengyu on 15/6/11.
//  Copyright (c) 2015年 videbo-pengyu. All rights reserved.
//
#if defined(TARGET_DARWIN_IOS)
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach/mach_host.h>
#import <sys/sysctl.h>
#else
#import <Cocoa/Cocoa.h>
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>
#endif

#import "DarwinUtils.h"

enum iosPlatform
{
    iDeviceUnknown = -1,
    iPhone2G,
    iPhone3G,
    iPhone3GS,
    iPodTouch1G,
    iPodTouch2G,
    iPodTouch3G,
    iPad,
    iPad3G,
    iPad2WIFI,
    iPad2CDMA,
    iPad2,
    iPadMini,
    iPadMiniGSMCDMA,
    iPadMiniWIFI,
    AppleTV2,
    iPhone4,            //from here on list devices with retina support (e.x. mainscreen scale == 2.0)
    iPhone4CDMA,
    iPhone4S,
    iPhone5,
    iPhone5GSMCDMA,
    iPhone5CGSM,
    iPhone5CGlobal,
    iPhone5SGSM,
    iPhone5SGlobal,
    iPodTouch4G,
    iPodTouch5G,
    iPad3WIFI,
    iPad3GSMCDMA,
    iPad3,
    iPad4WIFI,
    iPad4,
    iPad4GSMCDMA,
    iPadAirWifi,
    iPadAirCellular,
    iPadMini2Wifi,
    iPadMini2Cellular,
    iPhone6,
    iPadAir2Wifi,
    iPadAir2Cellular,
    iPadMini3Wifi,
    iPadMini3Cellular,
    iPhone6Plus,        //from here on list devices with retina support which have scale == 3.0
};

// platform strings are based on http://theiphonewiki.com/wiki/Models
const char* getIosPlatformString(void)
{
    static std::string iOSPlatformString;
    if (iOSPlatformString.empty())
    {
#if defined(TARGET_DARWIN_IOS)
        // Gets a string with the device model
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = new char[size];
        if (sysctlbyname("hw.machine", machine, &size, NULL, 0) == 0 && machine[0])
            iOSPlatformString.assign(machine, size -1);
        else
#endif
            iOSPlatformString = "unknown0,0";
        
#if defined(TARGET_DARWIN_IOS)
        delete [] machine;
#endif
    }
    
    return iOSPlatformString.c_str();
}

enum iosPlatform getIosPlatform()
{
    static enum iosPlatform eDev = iDeviceUnknown;
#if defined(TARGET_DARWIN_IOS)
    if (eDev == iDeviceUnknown)
    {
        std::string devStr(getIosPlatformString());
        if (devStr == "iPhone1,1") eDev = iPhone2G;
            else if (devStr == "iPhone1,2") eDev = iPhone3G;
                else if (devStr == "iPhone2,1") eDev = iPhone3GS;
                    else if (devStr == "iPhone3,1") eDev = iPhone4;
                        else if (devStr == "iPhone3,2") eDev = iPhone4;
                            else if (devStr == "iPhone3,3") eDev = iPhone4CDMA;
                                else if (devStr == "iPhone4,1") eDev = iPhone4S;
                                    else if (devStr == "iPhone5,1") eDev = iPhone5;
                                        else if (devStr == "iPhone5,2") eDev = iPhone5GSMCDMA;
                                            else if (devStr == "iPhone5,3") eDev = iPhone5CGSM;
                                                else if (devStr == "iPhone5,4") eDev = iPhone5CGlobal;
                                                    else if (devStr == "iPhone6,1") eDev = iPhone5SGSM;
                                                        else if (devStr == "iPhone6,2") eDev = iPhone5SGlobal;
                                                            else if (devStr == "iPhone7,1") eDev = iPhone6Plus;
                                                                else if (devStr == "iPhone7,2") eDev = iPhone6;
                                                                    else if (devStr == "iPod1,1") eDev = iPodTouch1G;
                                                                        else if (devStr == "iPod2,1") eDev = iPodTouch2G;
                                                                            else if (devStr == "iPod3,1") eDev = iPodTouch3G;
                                                                                else if (devStr == "iPod4,1") eDev = iPodTouch4G;
                                                                                    else if (devStr == "iPod5,1") eDev = iPodTouch5G;
                                                                                        else if (devStr == "iPad1,1") eDev = iPad;
                                                                                            else if (devStr == "iPad1,2") eDev = iPad;
                                                                                                else if (devStr == "iPad2,1") eDev = iPad2WIFI;
                                                                                                    else if (devStr == "iPad2,2") eDev = iPad2;
                                                                                                        else if (devStr == "iPad2,3") eDev = iPad2CDMA;
                                                                                                            else if (devStr == "iPad2,4") eDev = iPad2;
                                                                                                                else if (devStr == "iPad2,5") eDev = iPadMiniWIFI;
                                                                                                                    else if (devStr == "iPad2,6") eDev = iPadMini;
                                                                                                                        else if (devStr == "iPad2,7") eDev = iPadMiniGSMCDMA;
                                                                                                                            else if (devStr == "iPad3,1") eDev = iPad3WIFI;
                                                                                                                                else if (devStr == "iPad3,2") eDev = iPad3GSMCDMA;
                                                                                                                                    else if (devStr == "iPad3,3") eDev = iPad3;
                                                                                                                                        else if (devStr == "iPad3,4") eDev = iPad4WIFI;
                                                                                                                                            else if (devStr == "iPad3,5") eDev = iPad4;
                                                                                                                                                else if (devStr == "iPad3,6") eDev = iPad4GSMCDMA;
                                                                                                                                                    else if (devStr == "iPad4,1") eDev = iPadAirWifi;
                                                                                                                                                        else if (devStr == "iPad4,2") eDev = iPadAirCellular;
                                                                                                                                                            else if (devStr == "iPad4,4") eDev = iPadMini2Wifi;
                                                                                                                                                                else if (devStr == "iPad4,5") eDev = iPadMini2Cellular;
                                                                                                                                                                    else if (devStr == "iPad4,7") eDev = iPadMini3Wifi;
                                                                                                                                                                        else if (devStr == "iPad4,8") eDev = iPadMini3Cellular;
                                                                                                                                                                            else if (devStr == "iPad4,9") eDev = iPadMini3Cellular;
                                                                                                                                                                                else if (devStr == "iPad5,3") eDev = iPadAir2Wifi;
                                                                                                                                                                                    else if (devStr == "iPad5,4") eDev = iPadAir2Cellular;
                                                                                                                                                                                        else if (devStr == "AppleTV2,1") eDev = AppleTV2;
                                                                                                                                                                                            }
#endif
    return eDev;
    
}

bool SysctlMatches(std::string key, std::string searchValue)
{
    int result = -1;
#if defined(TARGET_DARWIN_IOS)
    char        buffer[512];
    size_t      len = 512;
    result = 0;
    
    if (sysctlbyname(key.c_str(), &buffer, &len, NULL, 0) == 0)
        key = buffer;
    
    if (key.find(searchValue) != std::string::npos)
        result = 1;
#endif
    return result;
}



float GetIOSVersion(void)
{
    float version;
#if defined(TARGET_DARWIN_IOS)
    version = [[[UIDevice currentDevice] systemVersion] floatValue];
#else
    version = 0.0f;
#endif
    
    return(version);
}

bool DarwinIsIPad3(void)
{
    static int result = -1;
#if defined(TARGET_DARWIN_IOS)
    if( result == -1 )
    {
        //valid ipad3 identifiers - iPad3,1 iPad3,2 and iPad3,3
        //taken from http://stackoverflow.com/questions/9638970/ios-the-new-ipad-uidevicehardware-hw-machine-codename
        result = SysctlMatches("hw.machine", "iPad3");
    }
#endif
    return (result == 1);
}

bool DeviceHasRetina(double &scale)
{
    static enum iosPlatform platform = iDeviceUnknown;
    
#if defined(TARGET_DARWIN_IOS)
    if( platform == iDeviceUnknown )
    {
        platform = getIosPlatform();
    }
#endif
    scale = 1.0; //no retina
    
    // see http://www.paintcodeapp.com/news/iphone-6-screens-demystified
    if (platform >= iPhone4 && platform < iPhone6Plus)
    {
        scale = 2.0; // 2x render retina
    }
    
    if (platform >= iPhone6Plus)
    {
        scale = 3.0; //3x render retina + downscale
    }
    
    return (platform >= iPhone4);
}
