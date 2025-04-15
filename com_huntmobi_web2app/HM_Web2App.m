//
//  HM_Web2App.m
//  HM
//
//  Created by HM on 2025/04/01.
//

#import "HM_Web2App.h"
#import "HM_UserAgentUtil.h"
#import "HM_Config.h"
#import "HM_NetWork.h"
#import "HM_Event.h"
#import "HM_DeviceData.h"

@interface HM_Web2App ()

@property (nonatomic, copy) NSString *cbcString;
//@property (nonatomic, copy) NSString *appname;
@property (nonatomic, copy) NSString *UAString;
@property (nonatomic, copy) NSString *fromString;

@end

@implementation HM_Web2App

+ (instancetype)sharedInstance {
     static HM_Web2App *sharedInstance = nil;
     static dispatch_once_t onceToken;
     dispatch_once(&onceToken, ^{
          sharedInstance = [[self alloc] init];
          sharedInstance.cbcString = @"";
          sharedInstance.deviceTrackID = @"";
          sharedInstance.appname = @"";
          sharedInstance.UID = @"";
          sharedInstance.pasteboardString = @"";
          sharedInstance.fromString = @"";
     });
     return sharedInstance;
}

-(void) attibuteWithAppname: (NSString *)appname {
     self.appname = appname;
     NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
     [userDefaults setObject:appname forKey:@"HM_AppName"];
     [self session];// 日活
     NSString *key = @"HM_W2AISFIRSTINSTALL";
     BOOL isFirst = ![userDefaults objectForKey:key] || [userDefaults boolForKey:key];
     if (isFirst) {// 是新用户
          [userDefaults setBool:NO forKey:key];
          [self getWebviewUA];
     } else {//非新增用户，正常启动不做处理
          self.pasteboardString = @"";
     }
}

//MARK: 非新装逻辑——通过deeplink启动
- (void)continueUserActivity:(NSUserActivity * _Nullable)userActivity {
     if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
          NSURL *url = userActivity.webpageURL;
          if (url) {
               NSString *s = url.absoluteString;
               if([[HM_Config sharedManager] isW2ADataString:url.absoluteString]) {
                    self.fromString = url.absoluteString;
               }
          }
     }
     NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
     NSString *key = @"HM_W2AISFIRSTINSTALL";
     BOOL isFirst = ![userDefaults objectForKey:key] || [userDefaults boolForKey:key];
     if (isFirst) {// 首次打开判断有没APPname，没有不做归因
          if (self.appname.length > 0) {
               [userDefaults setBool:NO forKey:key];
               [userDefaults setObject:self.appname forKey:@"HM_AppName"];
               [self getWebviewUA];
          }
     } else {
          if (self.pasteboardString.length > 0) {// app向SDK传入剪切板的值
               if([[HM_Config sharedManager] isW2ADataString:self.pasteboardString]) {
                    self.cbcString = self.pasteboardString;
                    self.pasteboardString = @"";
               }
               if (self.fromString.length > 0 || self.cbcString.length > 0) {
                    [self launch];
               }
          } else if (self.isLaunchReadCut) {// app没传剪切板的值，但是需要SDK读取一次
               [self checkClipboardForURLWithCompletion:^(NSString *urlString) {
                    if([[HM_Config sharedManager] isW2ADataString:urlString]) {
                         self.cbcString = urlString;
                         [UIPasteboard generalPasteboard].string = nil;
                    }
                    if (self.fromString.length > 0 || self.cbcString.length > 0) {
                         [self launch];
                    }
               }];
          } else {// 不需要再次获取剪切板的值
               self.cbcString = @"";
               if (self.fromString.length > 0) {
                    [self launch];
               }
          }
     }
}

-(void)getWebviewUA{
     [HM_UserAgentUtil getUserAgentWithCompletion:^(NSString * _Nonnull userAgent) {
          self.UAString = userAgent;
          [self handleNewUser];
     }];
}

//MARK: 新装逻辑
-(void)handleNewUser {
     // 新用户逻辑处理
     NSString *copyString = @"";
     if (self.pasteboardString.length > 0) {// 外部传入剪切板数据，不读取剪切板内容
          copyString = self.pasteboardString;
          self.pasteboardString = @"";
     } else {//读剪切板
          if (@available(iOS 10.0, *)) {
               BOOL isHasString = [[UIPasteboard generalPasteboard] hasStrings];
               if (isHasString) {
                    copyString = [[UIPasteboard generalPasteboard] string];
                    [UIPasteboard generalPasteboard].string = nil;
               }
          } else {
               copyString = [[UIPasteboard generalPasteboard] string];
          }
     }
     if (copyString.length > 0) {
          if([[HM_Config sharedManager] isW2ADataString:copyString]) {//判断剪切板内容是否是web2app的内容
               self.cbcString = copyString;
          }
     }
     [self attibute];
}

//MARK: 首次归因
-(void) attibute {
     NSDictionary *dic = [self setAttibuteRequestInfo];
     self.cbcString = @"";
     self.pasteboardString = @"";
     self.fromString = @"";
     __weak typeof(self) weakSelf = self;
     [[HM_Event sharedInstance] event:@"CompleteRegistration" withValues:dic andBlock:^(NSDictionary * _Nonnull responseObject) {
          dispatch_async(dispatch_get_main_queue(), ^{
               [weakSelf callbackData:responseObject];
          });
     }];
}

//MARK: 再归因
-(void) launch {
     NSDictionary *dic = [self setRequestInfo:@[self.cbcString, self.fromString]];
     self.cbcString = @"";
     self.fromString = @"";
     self.pasteboardString = @"";
     __weak typeof(self) weakSelf = self;
     [[HM_Event sharedInstance] event:@"Launch" withValues:dic andBlock:^(NSDictionary * _Nonnull responseObject) {
          dispatch_async(dispatch_get_main_queue(), ^{
               [weakSelf callbackData:responseObject];
          });
     }];
}

//MARK: 留存
-(void) session {
     if ([[HM_Config sharedManager] shouldReportTodayAndUpdate]) {//每天只报1次，UTC0时区
          NSDictionary *dic = [self setRequestInfo:@[]];
          [[HM_Event sharedInstance] event:@"OnSession" withValues:dic andBlock:^(NSDictionary * _Nonnull responseObject) {
               
          }];
     }
}

//MARK: 上报设备信息
-(void) uploadDeviceInfo {
     NSDictionary *dic = [self setRequestInfo:[[HM_DeviceData sharedManager] getDeviceInfoWithArray]];
     [[HM_Event sharedInstance] event:@"UploadDeviceInfo" withValues:dic andBlock:^(NSDictionary * _Nonnull responseObject) {
          
     }];
}

//MARK: 上报事件
-(void) eventPostWithEventInfo : (HM_EventInfoModel *) eventInfoModel {
     NSDictionary *data = [self setRequestInfo:[eventInfoModel toArray]];
     NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:data];
     [dic setObject:eventInfoModel.eventData.eventName forKey:@"event_name"];
     [[HM_Event sharedInstance] event:eventInfoModel.eventData.eventName withValues:[NSDictionary dictionaryWithDictionary:dic] andBlock:^(NSDictionary * _Nonnull responseObject) {
          
     }];
}

//MARK: 上报用户信息
-(void) updateUserInfo : (HM_UserInfoModel *) userInfoModel {
     NSDictionary *data = [self setRequestInfo:[userInfoModel toArray]];
     [[HM_Event sharedInstance] event:@"UpDateUserInfo" withValues:data andBlock:^(NSDictionary * _Nonnull responseObject) {
          
     }];
}

//MARK: 返回归因数据给app
-(void) callbackData : (NSDictionary *)responseObject {
     NSString *code = [responseObject[@"code"] stringValue];
     NSDictionary *data = responseObject[@"data"] ?: @{};
     if ([code isEqual: @"0"]) {
          NSString *w2akey = [data objectForKey:@"w2akey"] ?: @"";
          NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
          NSString *localW2akey = [userDefaults objectForKey:@"w2akey"] ?: @"";
          if (w2akey.length > 0 && ![localW2akey isEqualToString:w2akey]) {
               [userDefaults setObject:w2akey forKey:@"HM_W2a_Data"];
               NSString *click_time = [data objectForKey:@"click_time"];
               [userDefaults setObject:click_time forKey:@"HM_CLICK_TIME"];
               [userDefaults synchronize];
               [self uploadDeviceInfo];
          }
     }
     [self.delegate didReceiveHMData:[NSDictionary dictionaryWithDictionary:data]];
}

- (void) setUID:(NSString *)UID {
     NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
     [userDefaults setObject: UID.length > 0 ? UID : @"" forKey:@"__hm_uuid__"];
     [userDefaults synchronize];
}

- (void)checkClipboardForURLWithCompletion:(void (^)(NSString *urlString))completion {
     UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
     if (@available(iOS 14.0, *)) {
          NSSet *patterns = [NSSet setWithObject:UIPasteboardDetectionPatternProbableWebURL];
          [pasteboard detectPatternsForPatterns:patterns completionHandler:^(NSSet<UIPasteboardDetectionPattern> * _Nullable detectedPatterns, NSError * _Nullable error) {
               if (error) {
                    completion(@"");
                    return;
               }
               NSString *urlString = @"";
               if ([detectedPatterns containsObject:UIPasteboardDetectionPatternProbableWebURL]) {
                    urlString = pasteboard.string;
               }
               completion(urlString);
          }];
     } else {
          completion(@"");
     }
}

-(void) setLogEnabled:(BOOL)isEnable{
     [[HM_Config sharedManager] setLogEnabled:isEnable];
}

//MARK: 数据处理
- (NSDictionary *)setAttibuteRequestInfo {// 首次归因参数
     NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
     NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
     NSString *eid = [[HM_Config sharedManager] getGUID];
     NSString *an = [userDefaults stringForKey:@"HM_AppName"] ?: self.appname;
     NSString *ua = self.UAString ?: @"";
     NSString *dtid = [userDefaults objectForKey:@"HM_WEB2APP_DTID"] ?: self.deviceTrackID;
     NSArray *array = @[eid, an, self.cbcString, ua, dtid, self.fromString];
     [mDic setObject:eid forKey:@"eid"];
     [mDic setObject:array forKey:@"dataArray"];
     return [NSDictionary dictionaryWithDictionary:mDic];
}

-(NSDictionary *) setRequestInfo : (NSArray *) array {
     NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
     NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
     NSString *eid = [[HM_Config sharedManager] getGUID];
     NSString *an = [userDefaults stringForKey:@"HM_AppName"] ?: self.appname;
     NSString *w2akey = [userDefaults objectForKey:@"HM_W2a_Data"] ?: @"";
     NSMutableArray *mArr = [NSMutableArray arrayWithArray:@[eid, an, w2akey]];
     [mArr addObjectsFromArray:array];
     [mDic setObject:eid forKey:@"eid"];
     [mDic setObject:mArr forKey:@"dataArray"];
     return [NSDictionary dictionaryWithDictionary:mDic];
}

@end

