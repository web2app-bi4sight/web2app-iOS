//
//  hm.m
//  web2app
//
//  Created by HM on 2024/06/19.
//

#import "HM_SmartLink.h"
#import "HM_NetWork.h"
#import "HM_Config.h"
#import "HM_Event.h"
#import "HM_WebView.h"
#import "HM_DeviceData.h"

@interface HM_SmartLink ()

@property (nonatomic, copy) NSString *atcString;
@property (nonatomic, copy) NSString *cbcString;
@property (nonatomic, assign) BOOL isAddRequest;

@end


@implementation HM_SmartLink

+ (instancetype)sharedInstance {
    static HM_SmartLink *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[HM_DeviceData sharedManager] saveDeviceInfo];
        sharedInstance = [[self alloc] init];
        sharedInstance.codeString = @"";
        sharedInstance.fromString = @"";
        sharedInstance.atcString = @"";
        sharedInstance.cbcString = @"";
        sharedInstance.codesArray = @[];
        sharedInstance.deviceTrackID = @"";
        sharedInstance.isAddRequest = false;
    });
    return sharedInstance;
}

-(void) setSCodes:(NSArray *)sCodes {
    self.codesArray = sCodes;
}

//MARK: smartlink归因 ———— 兼容web2app
-(void) attibuteBlock : (void(^)(NSDictionary * dic))block {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *key = @"HM_ISFIRSTINSTALL";
    BOOL isFirst = ![userDefaults objectForKey:key] || [userDefaults boolForKey:key];
    if (isFirst) {// 是新用户
        self.isAddRequest = true;
        [userDefaults setBool:NO forKey:key];
        [userDefaults setObject:self.codeString forKey:@"HM_SMARTLINK_SCODE"];
            [self handleNewUser:^(NSDictionary *dic) {
                block(dic);
            }];
    } else {
        if (self.isAddRequest) return;
        self.isAddRequest = true;
        [self handleExistingUser:^(NSDictionary *dic) {
            block(dic);
        }];
    }
}

//MARK: smartlink归因
-(void) attibute : (NSDictionary *)dic andBlock : (void(^)(NSDictionary * dic))block {
    self.codeString = [dic objectForKey:@"scode"];
    self.fromString = [dic objectForKey:@"from"];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *key = @"HM_ISFIRSTINSTALL";
    BOOL isFirst = NO;
    if ([userDefaults objectForKey:key] != nil) {
        isFirst = [userDefaults boolForKey:key];
    } else {
        isFirst = YES;
    }
    if (isFirst && [[HM_Config sharedManager] isNewUser]) {// 是新用户
        isFirst = NO;
        [userDefaults setBool:isFirst forKey:@"HM_ISFIRSTINSTALL"];
        [userDefaults setObject:self.codeString forKey:@"HM_SMARTLINK_SCODE"];
            [self handleNewUser:^(NSDictionary *dic) {
                block(dic);
            }];
    } else {
        [self handleExistingUser:^(NSDictionary *dic) {
            block(dic);
        }];
    }
}


//MARK: 获取网关指纹
-(void) getWebViewInfo : (void(^)(NSDictionary * dic))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[HM_WebView shared] HMWebUABlock:^(NSString * _Nonnull uaString) {
            [self slAttibuteWithBlock:^(NSDictionary *dic) {
                block(dic);
            }];
        }];
        [[HM_WebView shared] creatSLWebView];
    });
}

//MARK: 新装逻辑
-(void)handleNewUser : (void(^)(NSDictionary * dic))block {
    // 新用户逻辑处理
    NSString *copyString = [[UIPasteboard generalPasteboard] string];
    if (copyString != nil) { //剪切板处理
        NSArray *correctArray = [[HM_Config sharedManager] matchesInString:copyString];
        if(correctArray.count > 0) {
            self.cbcString = [correctArray componentsJoinedByString:@""];
        }
    }
    self.atcString = @"add";
    [self getWebViewInfo:block];
}

//MARK: 非新装逻辑
-(void)handleExistingUser : (void(^)(NSDictionary * dic))block {
    // 非新用户逻辑处理
    self.atcString = @"launch";
    [self slAttibuteWithBlock:^(NSDictionary *dic) {
        block(dic);
    }];
}

- (NSDictionary *)setRequestInfo {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *ua = [userDefaults objectForKey:@"HM_WebView_UA"];
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    long timestampAsLong = (long)currentTimestamp;
    NSNumber *timestampAsNumber = [NSNumber numberWithLong:timestampAsLong];

    NSString *guid = [[HM_Config sharedManager] getGUID];
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_Device_Data"];
    NSString *aid = [userDefaults objectForKey:@"HM_SMART_AID"];
    NSString *dtid = [userDefaults objectForKey:@"HM_SMART_DTID"];
    NSNumber *ats = [userDefaults objectForKey:@"HM_SMART_ATS"];

    [mDic setObject:self.cbcString forKey:@"cbc"];
    [mDic setObject:self.codeString forKey:@"scode"];
    if (ua.length > 0) {
        [mDic setObject:ua forKey:@"ua"];
    }
    [mDic setObject:timestampAsNumber forKey:@"ts"];
    [mDic setObject:self.atcString forKey:@"atc"];
    [mDic setObject:device_info forKey:@"device"];
    [mDic setObject:self.fromString forKey:@"from"];
    [mDic setObject:guid forKey:@"eid"];
    [mDic setObject:self.codesArray forKey:@"scodes"];
    [mDic setObject:aid != nil ? aid : @"" forKey:@"aid"];
    [mDic setObject:[self.atcString isEqualToString:@"add"] ? self.deviceTrackID : (dtid != nil ? dtid : @"") forKey:@"dtid"];
    [mDic setObject:ats != nil ? ats : [NSNumber numberWithLong:0] forKey:@"ats"];
    return [NSDictionary dictionaryWithDictionary:mDic];
}


//MARK: 归因
-(void) slAttibuteWithBlock : (void(^)(NSDictionary * dic))block {
    NSDictionary *dic = [self setRequestInfo];
    self.cbcString = @"";
    self.fromString = @"";
    [[HM_Event sharedInstance] event:@"CompleteRegistration" withValues:dic andBlock:^(NSDictionary * _Nonnull responseObject) {
        self.isAddRequest = false;
        NSString *code = [responseObject[@"code"] stringValue];
        NSDictionary *data = responseObject[@"data"];
        if ([code isEqual: @"0"]) {
            NSString *aid = [data objectForKey:@"aid"];
            NSString *dtid = [data objectForKey:@"dtid"];
            NSNumber *ats = [data objectForKey:@"ats"];
            NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
            if (aid != nil && aid.length > 0 ) {
                [userDefaults setObject:aid forKey:@"HM_SMART_AID"];
                [userDefaults setObject:dtid forKey:@"HM_SMART_DTID"];
                [userDefaults setObject:ats forKey:@"HM_SMART_ATS"];
            }
            [userDefaults synchronize];
        }
        block(data);
    }];
}


- (void)continueUserActivity:(NSUserActivity * _Nullable)userActivity {
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = userActivity.webpageURL;
        if (url) {
            self.fromString = url.absoluteString;
        }
    }
}

@end
