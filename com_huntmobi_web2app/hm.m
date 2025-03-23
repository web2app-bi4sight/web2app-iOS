//
//  HM.m
//  HM
//
//  Created by CCC on 2022/12/2.
//

#import "hm.h"
#import "HM_NetWork.h"
#import "HM_Config.h"
#import "HM_WebView.h"
#import "HM_DeviceData.h"
#import "HM_Event.h"

@implementation hm

static W2ABlock w2aBlock;

+ (void)init:(NSString *)Gateway InstallEventName:(NSString *)InstallEventName IsNewUser:(BOOL)IsNewUser AppName:(NSString *)AppName success : (void(^)(NSArray * array))successBlock {
    [[HM_DeviceData sharedManager] saveWADeviceInfo];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:AppName forKey:@"HM_AppName"];

    NSString *key = @"HM_isFirstInsert";
    NSString *isFirst = [userDefaults objectForKey:@"HM_isFirstInsert"] ?: @"0";
    
    NSString *atcString = @"launch";
    NSString *cbcString = @"";
    NSString *deviceTrackID = @"";
    if ([isFirst isEqualToString:@"0"]) {// w2a判断新用户
        [userDefaults setObject:@"1" forKey:key];
        if (IsNewUser) { // app传入新用户
            atcString = @"add";
            NSString *copyString = @"";
            if (@available(iOS 10.0, *)) {
                BOOL isHasString = [[UIPasteboard generalPasteboard] hasStrings];
                if (isHasString) {
                    copyString = [[UIPasteboard generalPasteboard] string];
                    [UIPasteboard generalPasteboard].string = nil;
                }
            } else {
                copyString = [[UIPasteboard generalPasteboard] string];
            }
            if (copyString && copyString.length > 0) { //剪切板处理q
                if([[HM_Config sharedManager] isW2ADataString:copyString]) {//判断剪切板内容是否是web2app的内容
                    cbcString = copyString;
                }
            }
            atcString = @"add";
//            HMLog(@"······························");
        } else {
            atcString = @"launch";
            deviceTrackID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];;
        }
    } else {
        atcString = @"launch";
        deviceTrackID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];;
    }
    
    NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
    NSString *ua = [userDefaults objectForKey:@"HM_WebView_UA"];
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    long timestampAsLong = (long)currentTimestamp;
    NSNumber *timestampAsNumber = [NSNumber numberWithLong:timestampAsLong];

    NSString *guid = [hm getGUID];
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_WADevice_Data"];
    NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"];
    NSString *dtid = [userDefaults objectForKey:@"HM_WEB2APP_DTID"];
    w2akey = w2akey != nil ? w2akey : @"";
    [mDic setObject:cbcString forKey:@"cbc"];
    if (ua && ua.length > 0) {
        [mDic setObject:ua forKey:@"ua"];
    }
    [mDic setObject:timestampAsNumber forKey:@"ts"];
    [mDic setObject:atcString forKey:@"option"];
    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:guid forKey:@"eid"];
    [mDic setObject:@"attribute" forKey:@"action"];
    [mDic setObject:AppName forKey:@"app_name"];
    if (![[HM_Config sharedManager] isW2AKeyString:w2akey]) {
        [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2a_data_encrypt"];
        w2akey = @"";
    }
    [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2akey"];
    [mDic setObject:[atcString isEqualToString:@"add"] ? deviceTrackID : (dtid != nil ? dtid : @"") forKey:@"dt_id"];
    
    if ([atcString isEqualToString:@"add"]) {
        [hm getWebViewInfo:[NSDictionary dictionaryWithDictionary:mDic] andBlock:^(NSArray *array) {
            successBlock(array);
        }];
    } else {
        [hm attibute:[NSDictionary dictionaryWithDictionary:mDic] andBlock:^(NSArray *array) {
            successBlock(array);
        }];
    }
}

+(void)getWebViewInfo : (NSDictionary *)dic andBlock : (void(^)(NSArray * array))block  {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[HM_WebView shared] HMWebUABlock:^(NSString * _Nonnull uaString) {
            [hm attibute:dic andBlock:^(NSArray *array) {
                block(array);
            }];
        }];
        [[HM_WebView shared] creatSLWebView];
    });
}

+(void) attibute : (NSDictionary *)dic andBlock : (void(^)(NSArray * array))block {
    [[HM_Event sharedInstance] WAEvent:@"CompleteRegistration" withValues:dic andBlock:^(NSDictionary * _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *code = [responseObject[@"code"] stringValue];
            NSDictionary *data = responseObject[@"data"] ?: @{};
            if ([code isEqual: @"0"]) {
                NSString *w2akey = [data objectForKey:@"w2akey"] ?: @"";
                NSString *dtid = [data objectForKey:@"dtid"] ?: @"";
                NSString *click_time = [data objectForKey:@"click_time"];
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:dtid forKey:@"HM_WEB2APP_DTID"];
                [userDefaults setObject:click_time forKey:@"HM_CLICK_TIME"];
                [userDefaults setObject:w2akey forKey:@"HM_W2a_Data"];
                [userDefaults synchronize];
            }
            NSArray *dataArray = [data objectForKey:@"adv_data"] ?: @[];
            block(dataArray);
        });
    }];
}

+ (void)GetPageData:(void (^)(NSArray *))block {
    [[HM_DeviceData sharedManager] saveWADeviceInfo];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];

    NSString *appname = [userDefaults objectForKey:@"HM_AppName"] ?: @"";
    NSString *atcString = @"launch";
    NSString *cbcString = @"";
    NSString *deviceTrackID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
    NSString *ua = [userDefaults objectForKey:@"HM_WebView_UA"];
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    long timestampAsLong = (long)currentTimestamp;
    NSNumber *timestampAsNumber = [NSNumber numberWithLong:timestampAsLong];

    NSString *guid = [hm getGUID];
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_WADevice_Data"];
    NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"];
    NSString *dtid = [userDefaults objectForKey:@"HM_WEB2APP_DTID"];
    w2akey = w2akey != nil ? w2akey : @"";
    [mDic setObject:cbcString forKey:@"cbc"];
    if (ua && ua.length > 0) {
        [mDic setObject:ua forKey:@"ua"];
    }
    [mDic setObject:timestampAsNumber forKey:@"ts"];
    [mDic setObject:atcString forKey:@"option"];
    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:guid forKey:@"eid"];
    [mDic setObject:@"attribute" forKey:@"action"];
    [mDic setObject:appname forKey:@"app_name"];
    if (![[HM_Config sharedManager] isW2AKeyString:w2akey]) {
        [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2a_data_encrypt"];
        w2akey = @"";
    }
    [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2akey"];
    [mDic setObject:[atcString isEqualToString:@"add"] ? deviceTrackID : (dtid != nil ? dtid : @"") forKey:@"dt_id"];
    
    [hm attibute:[NSDictionary dictionaryWithDictionary:mDic] andBlock:^(NSArray *array) {
        block(array);
    }];
}

+(void) SetDeviceID:(NSString *) string{
    if (string && string.length > 0) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *deviceId = string;
        if (deviceId.length > 50) {
            deviceId = [deviceId substringToIndex:50];
        }
        [userDefaults setObject:deviceId forKey:@"__hm_uuid__"];
        [userDefaults synchronize];
    }
}

+ (void)UserDataUpdateEvent:(NSString *) emStr Fb_login_id : (NSString *) fbStr Phone : (NSString *) phStr Zipcode : (NSString *) zipcodeStr City : (NSString *) cityStr State : (NSString *) stateStr Gender : (NSString *) genderStr Fn : (NSString *) fnStr Ln : (NSString *) lnStr DateBirth : (NSString *) dateBirthStr Country : (NSString *) countryStr success:(nonnull void (^)(void))block {
    NSDictionary *dic = @{
                          @"em" : emStr,
                          @"fb_login_id" : fbStr,
                          @"ph" : phStr,
                          @"zp" : zipcodeStr,
                          @"ct" : cityStr,
                          @"st" : stateStr,
                          @"ge" : genderStr,
                          @"fn" : fnStr,
                          @"ln" : lnStr,
                          @"db" : dateBirthStr,
                          @"country" : countryStr,
    };
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *appname = [userDefaults objectForKey:@"HM_AppName"] ?: @"";
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_WADevice_Data"];
    NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"];
    
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:appname forKey:@"app_name"];
    [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2akey"];
    [mDic setObject:[hm getGUID] forKey:@"eid"];
    
    [[HM_Event sharedInstance] WAEvent:@"UpDateUserInfo" withValues:[NSDictionary dictionaryWithDictionary:mDic] andBlock:^(NSDictionary * _Nonnull responseObject) {
        block();
    }];
}


+(void) EventKey:(NSString *)eventID {
    NSDictionary *dic = @{
        @"event_data" : @{
            @"po_id": @"",
//            @"event_id": [hm getGUID],
            @"event_name": @"",
            @"currency": @"",
            @"value": @"",
            @"content_type": @"",
            @"content_ids": @[],
            @"event_time" : [[HM_Config sharedManager] currentUTCTimestamp]
        }
    };
    
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *appname = [userDefaults objectForKey:@"HM_AppName"] ?: @"";
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_WADevice_Data"];
    NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"];

    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:appname forKey:@"app_name"];
    [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2akey"];
    [mDic setObject:[hm getGUID] forKey:@"eid"];
    [mDic setObject:@(YES) forKey:@"is_event"];
    [mDic setObject:@(NO) forKey:@"is_delay"];

    [[HM_Event sharedInstance] WAEvent:@"EventPost" withValues:[NSDictionary dictionaryWithDictionary:mDic] andBlock:^(NSDictionary * _Nonnull responseObject) {
        
    }];
}


//MARK: 调用【网关购物API】，上报&由网关转发购物事件
+ (void)Purchase:(NSString *) nameStr Currency : (NSString *) usdStr Value : (NSString *) valueStr ContentType : (NSString *) typeStr ContentIds : (NSString *) idsStr Po_Id:(NSString *)po_id{
    NSDictionary *dic = @{
        @"event_data" : @{
            @"po_id": po_id,
//            @"event_id": [hm getGUID],
            @"event_name": nameStr,
            @"currency": usdStr,
            @"value": valueStr,
            @"content_type": typeStr,
            @"content_ids": [idsStr componentsSeparatedByString:@","],
            @"event_time" : [[HM_Config sharedManager] currentUTCTimestamp]
        }
    };
    
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *appname = [userDefaults objectForKey:@"HM_AppName"] ?: @"";
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_WADevice_Data"];
    NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"];

    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:appname forKey:@"app_name"];
    [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2akey"];
    [mDic setObject:[hm getGUID] forKey:@"eid"];
    [mDic setObject:@(NO) forKey:@"is_event"];
    [mDic setObject:@(NO) forKey:@"is_delay"];

    [[HM_Event sharedInstance] WAEvent:@"EventPost" withValues:[NSDictionary dictionaryWithDictionary:mDic] andBlock:^(NSDictionary * _Nonnull responseObject) {
        
    }];
}

//MARK: 调用网关【EventPost（转发API）】，上报&由网关转发自定义事件
+(void) EventPost:(NSString *)eventID EventName : (NSString *) eventName Currency : (NSString *) currency Value : (NSString *) value ContentType : (NSString *) contentType ContentIds : (NSString *) contentIds{
    NSDictionary *dic = @{
        @"event_data" : @{
//            @"event_id": eventID,
            @"event_name": eventName,
            @"currency": currency,
            @"value": value,
            @"content_type": contentType,
            @"content_ids": [contentIds componentsSeparatedByString:@","],
            @"event_time" : [[HM_Config sharedManager] currentUTCTimestamp]
        }
    };
    
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *appname = [userDefaults objectForKey:@"HM_AppName"] ?: @"";
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_WADevice_Data"];
    NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"];

    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:appname forKey:@"app_name"];
    [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2akey"];
    [mDic setObject:[hm getGUID] forKey:@"eid"];
    [mDic setObject:@(NO) forKey:@"is_event"];
    [mDic setObject:@(NO) forKey:@"is_delay"];

    [[HM_Event sharedInstance] WAEvent:@"EventPost" withValues:[NSDictionary dictionaryWithDictionary:mDic] andBlock:^(NSDictionary * _Nonnull responseObject) {
        
    }];
}

+(void)setLogEnabled:(BOOL)isEnable {
    [[HM_NetWork shareInstance] setLogEnabled:isEnable];
}

+(NSString *) GetW2AEncrypt {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *HM_W2a_Data = [userDefaults objectForKey:@"HM_W2a_Data"];
    return  HM_W2a_Data;
}


+(void) GetAttributionInfo:(void (^)(BOOL, NSString *, NSString *, NSString *))block{
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *external_id = [userDefaults objectForKey:@"HM_External_Id"];
    NSString *attribution_type = [userDefaults objectForKey:@"HM_Attribution_Type"];
    BOOL IsAttribution = [userDefaults boolForKey:@"HM_IsAttribution"];
    NSString *user_type = [userDefaults objectForKey:@"HM_User_Type"];
    if (IsAttribution) {
        block(IsAttribution, attribution_type, external_id, user_type);
    } else {// IsAttribution 为False 传入null
        block(IsAttribution,  @"", external_id, user_type);
    }
}

+(NSString *)getGUID{
    NSUUID *uuid = [NSUUID UUID];
    NSString *uuidString = [uuid UUIDString];
    return uuidString;
}

+ (void)init:(NSString *)Gateway InstallEventName:(NSString *)InstallEventName IsNewUser:(BOOL)IsNewUser AppName:(NSString *)AppName ClipboardData:(NSString *)ClipboardData success : (void(^)(NSArray * array))successBlock {
    
    [[HM_DeviceData sharedManager] saveWADeviceInfo];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *key = @"HM_isFirstInsert";
    NSString *isFirst = [userDefaults objectForKey:@"HM_isFirstInsert"] ?: @"0";
    
    NSString *atcString = @"launch";
    NSString *cbcString = @"";
    NSString *deviceTrackID = @"";
    if ([isFirst isEqualToString:@"0"]) {// w2a判断新用户
        [userDefaults setObject:@"1" forKey:key];
        if (IsNewUser) { // app传入新用户
            atcString = @"add";
            if (ClipboardData.length > 0) { //客户端传入剪切板内容处理
                if([[HM_Config sharedManager] isW2ADataString:ClipboardData]) {//判断内容是否是web2app的内容
                    cbcString = ClipboardData;
                }
            }
            atcString = @"add";
        } else {
            atcString = @"launch";
            deviceTrackID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];;
        }
    } else {
        atcString = @"launch";
        deviceTrackID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];;
    }
    
    NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
    NSString *ua = [userDefaults objectForKey:@"HM_WebView_UA"];
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    long timestampAsLong = (long)currentTimestamp;
    NSNumber *timestampAsNumber = [NSNumber numberWithLong:timestampAsLong];

    NSString *guid = [hm getGUID];
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_WADevice_Data"];
    NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"];
    NSString *dtid = [userDefaults objectForKey:@"HM_WEB2APP_DTID"];
    w2akey = w2akey != nil ? w2akey : @"";
    [mDic setObject:cbcString forKey:@"cbc"];
    if (ua.length > 0) {
        [mDic setObject:ua forKey:@"ua"];
    }
    [mDic setObject:timestampAsNumber forKey:@"ts"];
    [mDic setObject:atcString forKey:@"option"];
    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:guid forKey:@"eid"];
    [mDic setObject:@"attribute" forKey:@"action"];
    [mDic setObject:AppName forKey:@"app_name"];
    if (![[HM_Config sharedManager] isW2AKeyString:w2akey]) {
        [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2a_data_encrypt"];
        w2akey = @"";
    }
    [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2akey"];
    [mDic setObject:[atcString isEqualToString:@"add"] ? deviceTrackID : (dtid != nil ? dtid : @"") forKey:@"dt_id"];
    
    if ([atcString isEqualToString:@"add"]) {
        [hm getWebViewInfo:[NSDictionary dictionaryWithDictionary:mDic] andBlock:^(NSArray *array) {
            successBlock(array);
        }];
    } else {
        [hm attibute:[NSDictionary dictionaryWithDictionary:mDic] andBlock:^(NSArray *array) {
            successBlock(array);
        }];
    }
}

@end
