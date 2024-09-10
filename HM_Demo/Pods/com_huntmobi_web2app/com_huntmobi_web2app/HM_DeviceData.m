//
//  HM_DeviceData.m
//  web2app
//
//  Created by HM on 2024/07/26.
//

#import "HM_DeviceData.h"
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

@implementation HM_DeviceData

+ (instancetype)sharedManager {
    static HM_DeviceData *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[self alloc] init];
    });
    return config;
}

- (void)saveDeviceInfo {
    NSDictionary *deviceInfo = @{
        @"pgname": [self getAppBundleName] ?: @"",
        @"appversion": [self getAppExternalVersion] ?: @"",
        @"appver": [self getAppInternalVersion] ?: @"",
        @"osversion": [self getSystemVersion] ?: @"",
        @"model": [self getDeviceModel] ?: @"",
        @"timezoon": [self getTimeZone] ?: @"",
        @"ss_w": [self getScreenWidth] ?: @"",
        @"ss_h": [self getScreenHeight] ?: @"",
        @"screensize": [self getScreenDensity] ?: @"",
        @"cpu": [self getCpuCoreCount] ?: @"",
        @"manufacturername": [self getManufacturer] ?: @"Apple",
        @"networkconnectionstatus": @"",
        @"networktype": @"",
        @"systemlanguage": [self getSystemLanguage] ?: @"",
        @"systemcountry": [self getSystemCountry] ?: @"",
        @"idfv": [self getIDFV] ?: @"",
        @"advertiser_id": @"",
        @"android_id": @""
    };
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:deviceInfo forKey:@"HM_Device_Data"];
    [userDefaults synchronize];
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
