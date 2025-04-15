//
//  HM_Web2App.h
//  HM
//
//  Created by HM on 2025/04/01.
//

#import <Foundation/Foundation.h>
#import "HM_EventDataModel.h"
#import "HM_EventInfoModel.h"
#import "HM_UserInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HM_Web2AppDelegate <NSObject>

- (void)didReceiveHMData:(NSDictionary *)data;

@end

@interface HM_Web2App : NSObject

/// 初始化代理
@property (nonatomic, weak) id<HM_Web2AppDelegate> delegate;

/// 设备唯一标识，首次安装传空值
@property (nonatomic, copy) NSString *deviceTrackID;

///// 事件数组，需要延迟上报事件可联系相关对接人使用
//@property (nonatomic, strong) NSArray *eventNamesArray;

/// 唯一标识，可以是用户的也可以是设备的，不传值默认会用IDFV
@property (nonatomic, copy) NSString *UID;

/// app读取剪切板的值
@property (nonatomic, copy) NSString *pasteboardString;

/// 通过deeplink启动时，是否需要SDK再次读取剪切板数据，默认为false不读取。
@property (nonatomic, assign) BOOL isLaunchReadCut;

@property (nonatomic, copy) NSString *appname;

+ (instancetype)sharedInstance;

-(void) attibuteWithAppname: (NSString *)appname;

- (void)continueUserActivity:(NSUserActivity * _Nullable)userActivity;

-(void) eventPostWithEventInfo : (HM_EventInfoModel *) eventInfoModel;

-(void) updateUserInfo : (HM_UserInfoModel *) userInfoModel;

-(void) setLogEnabled:(BOOL) isEnable;

@end

NS_ASSUME_NONNULL_END
