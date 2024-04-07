//
//  HM_Config.m
//  HM
//
//  Created by CCC on 2022/12/2.
//

#import "HM_Config.h"
//#import <AppTrackingTransparency/AppTrackingTransparency.h>
//#import <AdSupport/ASIdentifierManager.h>
#import <sys/utsname.h>
#import <objc/runtime.h>

@implementation HM_Config

+ (instancetype)sharedManager {
    static HM_Config *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [HM_Config new];
    });
    return config;
}

- (CGFloat)returnSDKVersion {
    return 2.4;
}

- (NSString *)currentUTCTimestamp {
    NSDate *currentDate = [NSDate date];
    NSTimeInterval utcTimestamp = [currentDate timeIntervalSince1970];
    return [NSString stringWithFormat:@"%d", (int)utcTimestamp];
}

//  去掉idfa获取
-(void) saveDeviceID {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{@"idfa" : @""}];
    NSString *string = @"";
    if (idfv.length > 0) {
        string = idfv;
    }
    [dic setObject:string forKey:@"idfv"];
    [userDefaults setObject:[NSDictionary dictionaryWithDictionary:dic] forKey:@"HM_Device_Id"];
    [userDefaults synchronize];

//    // 判断在设置-隐私里用户是否打开了广告跟踪
//    if (@available(iOS 14, *)) {
//        // iOS14及以上版本需要先请求权限
//        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
//            // 获取到权限后，依然使用老方法获取idfa
//            if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
//                NSString *idfa = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
//                NSDictionary *d = @{@"idfv" : idfv, @"idfa" : idfa};
//                [userDefaults setObject:d forKey:@"HM_Device_Id"];
//                [userDefaults synchronize];
//            } else {
//                NSDictionary *d = @{@"idfv" : idfv, @"idfa" : @""};
//                [userDefaults setObject:d forKey:@"HM_Device_Id"];
//                [userDefaults synchronize];
////                    NSLog(@"请在设置-隐私-跟踪中允许App请求跟踪");
//            }
//        }];
//    } else {
//        // iOS14以下版本依然使用老方法
//        // 判断在设置-隐私里用户是否打开了广告跟踪
//        if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
//            NSString *idfa = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
//            NSDictionary *d = @{@"idfv" : idfv, @"idfa" : idfa};
//            [userDefaults setObject:d forKey:@"HM_Device_Id"];
//            [userDefaults synchronize];
//        } else {
//            NSDictionary *d = @{@"idfv" : idfv, @"idfa" : @""};
//            [userDefaults setObject:d forKey:@"HM_Device_Id"];
//            [userDefaults synchronize];
////                NSLog(@"请在设置-隐私-广告中打开广告跟踪功能");
//        }
//    }
}

-(void) saveBaseInfo {
    NSString *brand = @"苹果";
    NSString *model = [self judgeIphoneType];
    NSString *languageCode = [NSLocale preferredLanguages][0];// 返回的也是国际通用语言Code+国际通用国家地区代码
    NSString *countryCode = [NSString stringWithFormat:@"-%@", [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]];
    if (languageCode) {
        languageCode = [languageCode stringByReplacingOccurrencesOfString:countryCode withString:@""];
    }
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];


    NSString *phinfo = @"IOS";
    
    CGFloat screenScale = [UIScreen mainScreen].scale;
    NSString *screenString = [NSString stringWithFormat:@"%.2lf", screenScale];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    NSString *ss_h = [NSString stringWithFormat:@"%d", (int)screenSize.height];
    NSString *ss_w = [NSString stringWithFormat:@"%d", (int)screenSize.width];

    // 获取当前设备的时区
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    // 获取时区标识符
    NSString *timezone = [currentTimeZone name];
    
    NSUInteger processorCount = [[NSProcessInfo processInfo] processorCount];
    NSString *cpu = [NSString stringWithFormat:@"%lu", (unsigned long)processorCount];
    
    NSString *pgname = [[NSBundle mainBundle] bundleIdentifier];

    
    
    NSDictionary *dic = @{@"brand" : brand,
                          @"model" : model,
                          @"language" : languageCode,
                          @"phinfo" : phinfo,
                          @"osVersion" : osVersion,
                          @"screenSize" : screenString,
                          @"ss_h" : ss_h,
                          @"ss_w" : ss_w,
                          @"timezone" : timezone,
                          @"cpu" : cpu,
                          @"pgname" : pgname
    };
    
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:dic forKey:@"HM_Device_Info"];
    [userDefaults synchronize];
}

- (NSString *)judgeIphoneType {
    
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString * phoneType = [NSString stringWithCString: systemInfo.machine encoding:NSASCIIStringEncoding];
    
    //  常用机型  不需要的可自行删除
    
    if([phoneType  isEqualToString:@"iPhone1,1"])  return @"iPhone 2G";
    
    if([phoneType  isEqualToString:@"iPhone1,2"])  return @"iPhone 3G";
    
    if([phoneType  isEqualToString:@"iPhone2,1"])  return @"iPhone 3GS";
    
    if([phoneType  isEqualToString:@"iPhone3,1"])  return @"iPhone 4";
    
    if([phoneType  isEqualToString:@"iPhone3,2"])  return @"iPhone 4";
    
    if([phoneType  isEqualToString:@"iPhone3,3"])  return @"iPhone 4";
    
    if([phoneType  isEqualToString:@"iPhone4,1"])  return @"iPhone 4S";
    
    if([phoneType  isEqualToString:@"iPhone5,1"])  return @"iPhone 5";
    
    if([phoneType  isEqualToString:@"iPhone5,2"])  return @"iPhone 5";
    
    if([phoneType  isEqualToString:@"iPhone5,3"])  return @"iPhone 5c";
    
    if([phoneType  isEqualToString:@"iPhone5,4"])  return @"iPhone 5c";
    
    if([phoneType  isEqualToString:@"iPhone6,1"])  return @"iPhone 5s";
    
    if([phoneType  isEqualToString:@"iPhone6,2"])  return @"iPhone 5s";
    
    if([phoneType  isEqualToString:@"iPhone7,1"])  return @"iPhone 6 Plus";
    
    if([phoneType  isEqualToString:@"iPhone7,2"])  return @"iPhone 6";
    
    if([phoneType  isEqualToString:@"iPhone8,1"])  return @"iPhone 6s";
    
    if([phoneType  isEqualToString:@"iPhone8,2"])  return @"iPhone 6s Plus";
    
    if([phoneType  isEqualToString:@"iPhone8,4"])  return @"iPhone SE";
    
    if([phoneType  isEqualToString:@"iPhone9,1"])  return @"iPhone 7";
    
    if([phoneType  isEqualToString:@"iPhone9,2"])  return @"iPhone 7 Plus";
    
    if([phoneType  isEqualToString:@"iPhone9,4"])  return @"iPhone 7 Plus";
    
    if([phoneType  isEqualToString:@"iPhone10,1"]) return @"iPhone 8";
    
    if([phoneType  isEqualToString:@"iPhone10,4"]) return @"iPhone 8";
    
    if([phoneType  isEqualToString:@"iPhone10,2"]) return @"iPhone 8 Plus";
    
    if([phoneType  isEqualToString:@"iPhone10,5"]) return @"iPhone 8 Plus";
    
    if([phoneType  isEqualToString:@"iPhone10,3"]) return @"iPhone X";
    
    if([phoneType  isEqualToString:@"iPhone10,6"]) return @"iPhone X";
    
    if([phoneType  isEqualToString:@"iPhone11,8"]) return @"iPhone XR";
    
    if([phoneType  isEqualToString:@"iPhone11,2"]) return @"iPhone XS";
    
    if([phoneType  isEqualToString:@"iPhone11,4"]) return @"iPhone XS Max";
    
    if([phoneType  isEqualToString:@"iPhone11,6"]) return @"iPhone XS Max";
    
    if([phoneType  isEqualToString:@"iPhone12,1"])  return @"iPhone 11";
    
    if ([phoneType isEqualToString:@"iPhone12,3"])  return @"iPhone 11 Pro";
    
    if ([phoneType isEqualToString:@"iPhone12,5"])   return @"iPhone 11 Pro Max";
    
    if ([phoneType isEqualToString:@"iPhone12,8"])   return @"iPhone SE2";
    
    if ([phoneType isEqualToString:@"iPhone13,1"])    return @"iPhone 12 mini";
    if ([phoneType isEqualToString:@"iPhone13,2"])    return @"iPhone 12";
    if ([phoneType isEqualToString:@"iPhone13,3"])    return @"iPhone 12 Pro";
    if ([phoneType isEqualToString:@"iPhone13,4"])    return @"iPhone 12 Pro Max";
    
    if ([phoneType isEqualToString:@"iPhone14,4"])    return @"iPhone 13 mini";
    if ([phoneType isEqualToString:@"iPhone14,5"])    return @"iPhone 13";
    if ([phoneType isEqualToString:@"iPhone14,2"])    return @"iPhone 13 Pro";
    if ([phoneType isEqualToString:@"iPhone14,3"])    return @"iPhone 13 Pro Max";
    
    if ([phoneType isEqualToString:@"iPhone14,6"])    return @"iPhone SE"; //(2nd generation)
    if ([phoneType isEqualToString:@"iPhone14,7"])    return @"iPhone 14";
    if ([phoneType isEqualToString:@"iPhone14,8"])    return @"iPhone 14 Plus";
    if ([phoneType isEqualToString:@"iPhone15,2"])    return @"iPhone 14 Pro";
    if ([phoneType isEqualToString:@"iPhone15,3"])    return @"iPhone 14 Pro Max";
    
    if ([phoneType isEqualToString:@"iPhone15,4"])    return @"iPhone 15";
    if ([phoneType isEqualToString:@"iPhone15,5"])    return @"iPhone 15 Plus";
    if ([phoneType isEqualToString:@"iPhone16,1"])    return @"iPhone 15 Pro";
    if ([phoneType isEqualToString:@"iPhone16,2"])    return @"iPhone 15 Pro Max";
    
    //iPad
    if ([phoneType isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([phoneType isEqualToString:@"iPad1,2"])      return @"iPad 3G";
    
    if ([phoneType isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([phoneType isEqualToString:@"iPad2,2"])      return @"iPad 2";
    if ([phoneType isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([phoneType isEqualToString:@"iPad2,4"])      return @"iPad 2";
    if ([phoneType isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([phoneType isEqualToString:@"iPad2,6"])      return @"iPad Mini";
    if ([phoneType isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    
    if ([phoneType isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([phoneType isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([phoneType isEqualToString:@"iPad3,3"])      return @"iPad 3";
    if ([phoneType isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([phoneType isEqualToString:@"iPad3,5"])      return @"iPad 4";
    if ([phoneType isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    
    if ([phoneType isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([phoneType isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([phoneType isEqualToString:@"iPad4,3"])      return @"iPad Air";
    
    if ([phoneType isEqualToString:@"iPad4,4"])      return @"iPad Mini 2 (WiFi)";
    if ([phoneType isEqualToString:@"iPad4,5"])      return @"iPad Mini 2 (Cellular)";
    if ([phoneType isEqualToString:@"iPad4,6"])      return @"iPad Mini 2";
    
    if ([phoneType isEqualToString:@"iPad4,7"])      return @"iPad Mini 3";
    if ([phoneType isEqualToString:@"iPad4,8"])      return @"iPad Mini 3";
    if ([phoneType isEqualToString:@"iPad4,9"])      return @"iPad Mini 3";
    
    if ([phoneType isEqualToString:@"iPad5,1"])      return @"iPad Mini 4 (WiFi)";
    if ([phoneType isEqualToString:@"iPad5,2"])      return @"iPad Mini 4 (LTE)";
    if ([phoneType isEqualToString:@"iPad5,3"])      return @"iPad Air 2";
    if ([phoneType isEqualToString:@"iPad5,4"])      return @"iPad Air 2";
    
    if ([phoneType isEqualToString:@"iPad6,3"])      return @"iPad Pro 9.7";
    if ([phoneType isEqualToString:@"iPad6,4"])      return @"iPad Pro 9.7";
    if ([phoneType isEqualToString:@"iPad6,7"])      return @"iPad Pro 12.9";
    if ([phoneType isEqualToString:@"iPad6,8"])      return @"iPad Pro 12.9";
    
    if ([phoneType isEqualToString:@"iPad6,11"])     return @"iPad 5th";
    if ([phoneType isEqualToString:@"iPad6,12"])     return @"iPad 5th";
    
    if ([phoneType isEqualToString:@"iPad7,1"])      return @"iPad Pro 12.9 2nd";
    if ([phoneType isEqualToString:@"iPad7,2"])      return @"iPad Pro 12.9 2nd";
    if ([phoneType isEqualToString:@"iPad7,3"])      return @"iPad Pro 10.5";
    if ([phoneType isEqualToString:@"iPad7,4"])      return @"iPad Pro 10.5";
    
    if ([phoneType isEqualToString:@"iPad7,5"])      return @"iPad 6th";
    if ([phoneType isEqualToString:@"iPad7,6"])      return @"iPad 6th";
    
    if ([phoneType isEqualToString:@"iPad8,1"])      return @"iPad Pro 11";
    if ([phoneType isEqualToString:@"iPad8,2"])      return @"iPad Pro 11";
    if ([phoneType isEqualToString:@"iPad8,3"])      return @"iPad Pro 11";
    if ([phoneType isEqualToString:@"iPad8,4"])      return @"iPad Pro 11";
    
    if ([phoneType isEqualToString:@"iPad8,5"])      return @"iPad Pro 12.9 3rd";
    if ([phoneType isEqualToString:@"iPad8,6"])      return @"iPad Pro 12.9 3rd";
    if ([phoneType isEqualToString:@"iPad8,7"])      return @"iPad Pro 12.9 3rd";
    if ([phoneType isEqualToString:@"iPad8,8"])      return @"iPad Pro 12.9 3rd";
    
    if ([phoneType isEqualToString:@"iPad11,1"])      return @"iPad mini 5th";
    if ([phoneType isEqualToString:@"iPad11,2"])      return @"iPad mini 5th";
    if ([phoneType isEqualToString:@"iPad11,3"])      return @"iPad Air 3rd";
    if ([phoneType isEqualToString:@"iPad11,4"])      return @"iPad Air 3rd";
    
    if ([phoneType isEqualToString:@"iPad11,6"])      return @"iPad 8th";
    if ([phoneType isEqualToString:@"iPad11,7"])      return @"iPad 8th";
    
    if ([phoneType isEqualToString:@"iPad12,1"])      return @"iPad 9th";
    if ([phoneType isEqualToString:@"iPad12,2"])      return @"iPad 9th";
    
    if ([phoneType isEqualToString:@"iPad13,1"])      return @"iPad Air 4";
    if ([phoneType isEqualToString:@"iPad13,2"])      return @"iPad Air 4";
    if ([phoneType isEqualToString:@"iPad13,4"])      return @"iPad Pro 11-inch 3nd gen";
    if ([phoneType isEqualToString:@"iPad13,5"])      return @"iPad Pro 11-inch 3nd gen";
    if ([phoneType isEqualToString:@"iPad13,6"])      return @"iPad Pro 11-inch 3nd gen";
    if ([phoneType isEqualToString:@"iPad13,7"])      return @"iPad Pro 11-inch 3nd gen";
    if ([phoneType isEqualToString:@"iPad13,8"])      return @"iPad Pro 12.9-inch 5th gen";
    if ([phoneType isEqualToString:@"iPad13,9"])      return @"iPad Pro 12.9-inch 5th gen";
    if ([phoneType isEqualToString:@"iPad13,10"])      return @"iPad Pro 12.9-inch 5th gen";
    if ([phoneType isEqualToString:@"iPad13,11"])      return @"iPad Pro 12.9-inch 5th gen";
    if ([phoneType isEqualToString:@"iPad13,16"])      return @"iPad Air 5";
    if ([phoneType isEqualToString:@"iPad13,17"])      return @"iPad Air 5";
    if ([phoneType isEqualToString:@"iPad13,18"])      return @"iPad 10";
    if ([phoneType isEqualToString:@"iPad13,19"])      return @"iPad 10";
    
    if ([phoneType isEqualToString:@"iPad14,1"])      return @"iPad mini 6th";
    if ([phoneType isEqualToString:@"iPad14,2"])      return @"iPad mini 6th";
    if ([phoneType isEqualToString:@"iPad14,3"])      return @"iPad Pro 11-inch 4th gen";
    if ([phoneType isEqualToString:@"iPad14,4"])      return @"iPad Pro 11-inch 4th gen";
    if ([phoneType isEqualToString:@"iPad14,5"])      return @"iPad Pro 12.9-inch 6th gen";
    if ([phoneType isEqualToString:@"iPad14,6"])      return @"iPad Pro 12.9-inch 6th gen";
    
    //iPod
    if ([phoneType isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([phoneType isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([phoneType isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([phoneType isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([phoneType isEqualToString:@"iPod5,1"])      return @"iPod Touch (5 Gen)";
    if ([phoneType isEqualToString:@"iPod7,1"])      return @"iPod Touch (6 Gen)";
    if ([phoneType isEqualToString:@"iPod9,1"])      return @"iPod Touch (7 Gen)";
    
    if ([phoneType isEqualToString:@"i386"])         return @"Simulator";
    if ([phoneType isEqualToString:@"x86_64"])       return @"Simulator";
    
    return phoneType;
}

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
     return nil;
    }

    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                       options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
//        NSString *log = [NSString stringWithFormat:@"%d, %s | json解析失败：%@", __LINE__, __func__, err];
        return nil;
    }
    return dic;
}

@end
