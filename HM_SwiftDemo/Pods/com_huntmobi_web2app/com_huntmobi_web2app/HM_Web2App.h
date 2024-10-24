//
//  HM_Web2app.h
//  HT_Test
//
//  Created by HM on 2024/09/03.
//

#import <Foundation/Foundation.h>
#import "HM_EventInfoModel.h"
#import "HM_EventDataModel.h"
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

/// 事件数组，需要延迟上报事件可联系相关对接人使用
@property (nonatomic, strong) NSArray *eventNamesArray;

/// 唯一标识，可以是用户的也可以是设备的，不传值默认会用IDFV
@property (nonatomic, copy) NSString *UID;

+ (instancetype)sharedInstance;

-(void) attibuteWithAppname: (NSString *)appname;

-(void) eventPostWithEventInfo : (HM_EventInfoModel *) eventInfoModel;

-(void) updateUserInfo : (HM_UserInfoModel *) userInfoModel;

-(void) setLogEnabled:(BOOL) isEnable;


@end

NS_ASSUME_NONNULL_END

