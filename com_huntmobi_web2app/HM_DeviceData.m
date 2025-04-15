//
//  HM_DeviceData.m
//  HM
//
//  Created by HM on 2025/04/01.
//

#import "HM_DeviceData.h"
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "HM_Config.h"

@implementation HM_DeviceData

+ (instancetype)sharedManager {
    static HM_DeviceData *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[self alloc] init];
    });
    return config;
}

- (NSDictionary *) getDeviceInofWithDictionary {
    NSDictionary *deviceInfo = @{
        @"pgname": [self getAppBundleName] ?: @"",
        @"appversion": [self getAppExternalVersion] ?: @"",
        @"appver": [self getAppInternalVersion] ?: @"",
        @"osversion": [self getSystemVersion] ?: @"",
        @"model": [self getDeviceModel] ?: @"",
        @"timezone": [self getTimeZone] ?: @"",
        @"phinfo" : @"iOS",
        @"ss_w": [self getScreenWidth] ?: @"",
        @"ss_h": [self getScreenHeight] ?: @"",
        @"screensize": [self getScreenDensity] ?: @"",
        @"cpu": [self getCpuCoreCount] ?: @"",
        @"brand": [self getManufacturer] ?: @"Apple",
        @"language": [self getSystemLanguage] ?: @"",
        @"systemcountry": [self getSystemCountry] ?: @"",
        @"idfv": [self getIDFV] ?: @"",
        @"idfa": @"",
        @"advertiser_id": @"",
        @"android_id": @"",
        @"sdk" : [[HM_Config sharedManager] getSDKVer]
    };
    return deviceInfo;
}

//brand    手机品牌
//model    手机型号
//language    使用语言
//phinfo    手机操作系统类别 (如 IOS/ANDROID)
//osversion    操作系统版本
//screensize    手机屏幕分辨率
//ss_h    屏幕高度 (数字)
//ss_w    屏幕宽度 (数字)
//timezone    时区
//cpu    CPU 核心数量 (数字)
//pgname    包名
//sdk    工具包版本
//Android_ID    Android 标记
//Advertiser_ID    广告商 ID
//IDFV    iOS 标记 (ID for Vendor)
//IDFA    iOS 标记 (ID for Advertiser)
//appversion    App 包版本
//systemcountry    系统国家
- (NSArray *) getDeviceInfoWithArray {
    NSArray *array = @[
        [self getManufacturer] ?: @"Apple",
        [self getDeviceModel] ?: @"",
        [self getSystemLanguage] ?: @"",
        @"iOS",
        [self getSystemVersion] ?: @"",
        [self getScreenDensity] ?: @"",
        [self getScreenHeight] ?: @"",
        [self getScreenWidth] ?: @"",
        [self getTimeZone] ?: @"",
        [self getCpuCoreCount] ?: @"",
        [self getAppBundleName] ?: @"",
        [[HM_Config sharedManager] getSDKVer],
        @"",
        @"",
        [self getIDFV] ?: @"",
        @"",
        [self getAppExternalVersion] ?: @"",
        [self getSystemCountry] ?: @""
    ];
    return array;
}

- (NSString *)getAppBundleName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
}

- (NSString *)getAppExternalVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)getAppInternalVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)getSystemVersion {
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *)getDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

- (NSString *)getTimeZone {
    return [[NSTimeZone localTimeZone] name];
}

- (NSString *)getScreenWidth {
    return [NSString stringWithFormat:@"%.2lf", [UIScreen mainScreen].bounds.size.width];
}

- (NSString *)getScreenHeight {
    return [NSString stringWithFormat:@"%.2lf", [UIScreen mainScreen].bounds.size.height];
}

- (NSString *)getScreenDensity {
    return [NSString stringWithFormat:@"%.2lf", [UIScreen mainScreen].scale];
}

- (NSString *)getCpuCoreCount {
    return [NSString stringWithFormat:@"%lu", (unsigned long)[[NSProcessInfo processInfo] processorCount]];
}

- (NSString *)getManufacturer {
    return @"Apple";
}

- (NSString *)getSystemLanguage {
    return [[NSLocale preferredLanguages] firstObject];
}

- (NSString *)getSystemCountry {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

- (NSString *)getIDFV {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

@end
