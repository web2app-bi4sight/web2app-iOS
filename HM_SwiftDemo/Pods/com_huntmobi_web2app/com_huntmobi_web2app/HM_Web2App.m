//
//  HM_Web2app.m
//  HT_Test
//
//  Created by HM on 2024/09/03.
//

#import "HM_Web2App.h"
#import "HM_NetWork.h"
#import "HM_Config.h"
#import "HM_Event.h"
#import "HM_WebView.h"
#import "HM_DeviceData.h"

@interface HM_Web2App ()

@property (nonatomic, copy) NSString *atcString;
@property (nonatomic, copy) NSString *cbcString;
@property (nonatomic, assign) BOOL isAddRequest;
@property (nonatomic, copy) NSString *appname;

@end

@implementation HM_Web2App

+ (instancetype)sharedInstance {
    static HM_Web2App *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.isAddRequest = false;
        sharedInstance.cbcString = @"";
        sharedInstance.atcString = @"";
        sharedInstance.deviceTrackID = @"";
        sharedInstance.appname = @"";
        sharedInstance.UID = @"";
        [[HM_DeviceData sharedManager] saveWADeviceInfo];
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance
                                                     selector:@selector(applicationDidBecomeActive:)
                                                         name:UIApplicationDidBecomeActiveNotification
                                                       object:nil];
        
    });
    return sharedInstance;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
//    NSLog(@"$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");
    if (self.isAddRequest) return;
    [self attibute];
}

-(void) attibuteWithAppname: (NSString *)appname {
    self.appname = appname;
    [[HM_DeviceData sharedManager] saveWADeviceInfo];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *key = @"HM_W2AISFIRSTINSTALL";
    BOOL isFirst = ![userDefaults objectForKey:key] || [userDefaults boolForKey:key];
    if (isFirst) {// 是新用户
        self.isAddRequest = true;
        [userDefaults setBool:NO forKey:key];
            [self handleNewUser];
    } else {
        if (self.isAddRequest) return;
        self.isAddRequest = true;
        [self handleExistingUser];
    }
}

//MARK: 获取网关指纹
-(void) getWebViewInfo {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[HM_WebView shared] HMWebUABlock:^(NSString * _Nonnull uaString) {
            [self attibute];
        }];
        [[HM_WebView shared] creatSLWebView];
    });
}

//MARK: 新装逻辑
-(void)handleNewUser {
    // 新用户逻辑处理
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
    if (copyString.length > 0) { //剪切板处理
        if([[HM_Config sharedManager] isW2ADataString:copyString]) {//判断剪切板内容是否是web2app的内容
            self.cbcString = copyString;
        }
    }
    self.atcString = @"add";
//    HMLog(@"111111111111111111111111");
    [self getWebViewInfo];
}

//MARK: 非新装逻辑
-(void)handleExistingUser {
    // 非新用户逻辑处理
    self.atcString = @"launch";
    [self attibute];
}


//MARK: 归因
-(void) attibute {
//    HMLog(@"222222222222222222222222222");
    NSDictionary *dic = [self setRequestInfo];
    self.cbcString = @"";
    [[HM_Event sharedInstance] WAEvent:@"CompleteRegistration" withValues:dic andBlock:^(NSDictionary * _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isAddRequest = false;
            NSString *code = [responseObject[@"code"] stringValue];
            NSDictionary *data = responseObject[@"data"] ?: @{};
            if ([code isEqual: @"0"]) {
                NSString *w2akey = [data objectForKey:@"w2akey"];
                NSString *dtid = [data objectForKey:@"dtid"] ?: @"";
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                if (w2akey != nil && w2akey.length > 0) {
                    [userDefaults setObject:w2akey forKey:@"HM_W2a_Data"];
                    [userDefaults setObject:dtid forKey:@"HM_WEB2APP_DTID"];
                    NSString *click_time = [data objectForKey:@"click_time"];
                    [userDefaults setObject:click_time forKey:@"HM_CLICK_TIME"];
                }
                [userDefaults synchronize];
            }
            NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:data];
            NSString *w2akey = [data objectForKey:@"w2akey"] ?: @"";
            BOOL value = NO;
            if (w2akey.length > 0) {
                value = YES;
            }
            [mdic setObject:[NSNumber numberWithBool:value] forKey:@"isAttribution"];
            [self.delegate didReceiveHMData:[NSDictionary dictionaryWithDictionary:mdic]];
        });
    }];

}

-(void) eventPostWithEventInfo : (HM_EventInfoModel *) eventInfoModel {
    NSDictionary *data = [self setEventRequestInfo:[eventInfoModel toDictionary]];
    [[HM_Event sharedInstance] WAEvent:@"EventPost" withValues:data andBlock:^(NSDictionary * _Nonnull responseObject) {
        
    }];
}

-(void) updateUserInfo : (HM_UserInfoModel *) userInfoModel {
    NSDictionary *data = [self setUserRequestInfo:[userInfoModel toDictionary]];
    [[HM_Event sharedInstance] WAEvent:@"UpDateUserInfo" withValues:data andBlock:^(NSDictionary * _Nonnull responseObject) {
        
    }];
}

-(void) setLogEnabled:(BOOL)isEnable {
    [[HM_NetWork shareInstance] setLogEnabled:isEnable];
}

- (void) setUID:(NSString *)UID {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceId = UID;
    if (deviceId.length > 50) {
        deviceId = [deviceId substringToIndex:50];
    } else if (UID.length == 0) {
        deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    [userDefaults setObject:deviceId forKey:@"__hm_uuid__"];
    [userDefaults synchronize];
}

- (NSDictionary *)setRequestInfo {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *ua = [userDefaults objectForKey:@"HM_WebView_UA"];
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    long timestampAsLong = (long)currentTimestamp;
    NSNumber *timestampAsNumber = [NSNumber numberWithLong:timestampAsLong];

    NSString *guid = [[HM_Config sharedManager] getGUID];
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_WADevice_Data"];
    NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"];
    NSString *dtid = [userDefaults objectForKey:@"HM_WEB2APP_DTID"];
    w2akey = w2akey != nil ? w2akey : @"";
    [mDic setObject:self.cbcString forKey:@"cbc"];
    if (ua.length > 0) {
        [mDic setObject:ua forKey:@"ua"];
    }
    [mDic setObject:timestampAsNumber forKey:@"ts"];
    [mDic setObject:self.atcString forKey:@"option"];
    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:guid forKey:@"eid"];
    [mDic setObject:@"attribute" forKey:@"action"];
    [mDic setObject:self.appname forKey:@"app_name"];
    if (![[HM_Config sharedManager] isW2AKeyString:w2akey]) {
        [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2a_data_encrypt"];
        w2akey = @"";
    }
    [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2akey"];
    [mDic setObject:[self.atcString isEqualToString:@"add"] ? self.deviceTrackID : (dtid != nil ? dtid : @"") forKey:@"dt_id"];
    return [NSDictionary dictionaryWithDictionary:mDic];
}

-(NSDictionary *) setEventRequestInfo : (NSDictionary *) dic {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_WADevice_Data"];
    NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"];

    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:self.appname forKey:@"app_name"];
    [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2akey"];
    [mDic setObject:[self getGUID] forKey:@"eid"];
    return [NSDictionary dictionaryWithDictionary:mDic];
}

-(NSDictionary *) setUserRequestInfo : (NSDictionary *) dic {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_WADevice_Data"];
    NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"];

    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:self.appname forKey:@"app_name"];
    [mDic setObject:w2akey != nil ? w2akey : @"" forKey:@"w2akey"];
    [mDic setObject:[self getGUID] forKey:@"eid"];
    return [NSDictionary dictionaryWithDictionary:mDic];
}

-(NSString *)getGUID{
    NSUUID *uuid = [NSUUID UUID];
    NSString *uuidString = [uuid UUIDString];
    return uuidString;
}

@end
